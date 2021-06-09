view.protter <- function(
	proteinID = 'P42866', # UniProtKB protein identifier.
	peptideSequence = c(), # List of peptide sequences to be colored, e.g c('QPWADPEETSEEK','HPTITDEER','ETIELTEDGKPLEVPEK').
	proteinSequence = '(%5CS+)', # Entire protein sequence if want to color it a different color. Default: regexp for all amino acids.
	proteinColor = '282828', # Background color of amino acids in protein sequence. Gray default. Can also use HEX, no #.
	picType = 'svg', # protter export type: 'svg' or 'png'
	transmembraneLabelColor = 'yellow', # Color of the text indicating the transmembrane number. Can also use HEX, no #.
	aminoAcidInterestColor = 'red', # Default color for peptides of interest. List of available colors at http://wlab.ethz.ch/protter/help/#colors. Can also use HEX, no #.
	aminoAcidInterestTextColor = 'white', # Default text color for peptides of interest. List of available colors at http://wlab.ethz.ch/protter/help/#colors.
	displayType = 'ggplot2', # Use magick (vector), 'ggplot' (high res raster) or 'ggimage' (usually lower res raster) for displaying protter SVG as a graph
	dispPlot = TRUE, # TRUE = automatically display, FALSE, do not display and return plot object.
	dispPlotBackground = 'black', # Background of the plot: 'black' or 'white'.
	removeTmpFile = TRUE, # TRUE = remove temporary file, FALSE = keep temporary file
	svgLoadWidth = 500, # width to use when loading SVG, sets quality to a degree. Above 1000 can lead to long processing times.
	svgColorList = view.svg.colors(), # List of colors to draw from when coloring each peptide. Takes precedent over aminoAcidInterestColor.
	...){

	# Grab protein sequence image from protter (http://wlab.ethz.ch/protter) and either display or return a graphics object for use in downstream display functions. Also will color by peptide sequence.
	# Biafra Ahanonu
	# Started: 2021.04.27 [17:00:55]
	# Input
		# proteinID - only required input, UniProtKB protein identifier.
	# Output
		# Output is a list containing names:
			# protterProteinPlot - graphics object, e.g. for use with cowplot::plot_grid.
			# tmpFileHandle - path to temporary file containing protter graphic.
	# Changelog
		# 2021.04.28 [20:52:52] - Add additional color support.
		# 2021.04.29 [11:36:07] - Updated so that each peptide obtains it's own color
		# 2021.05.31 [12:26:26] - Updated to remove newline and tab characters from protter URL request, caused issues.
		# 2021.06.08 [08:59:30] - Finished adding each peptide own color
	# To-do
		# List out different.
		# Integrate additional options to change the protter graph colors, etc.
		# Allow input of gene name, etc.

	# =====================
	# Load necessary packages and install if not available.
	# Currently there are some extra packages...
	packagesFileList <- c(
		"reshape2",
		"ggplot2",
		"stringr",
		"grid",
		"gridExtra",
		"ggthemes",
		"png",
		"grImport2",
		"rsvg",
		"gridSVG",
		"svglite",
		"ggimage",
		"magick",
		'cowplot'
	)
	# 'devtools',"MASS"
	lapply(packagesFileList,FUN=function(file){
		if(!require(file,character.only = TRUE)){
			install.packages(file,dep=TRUE)
		}
	})

	# =====================
	# Remove PTM and other annotations along with underscores
	if(length(peptideSequence)!=0){
		peptideSequence <- stringr::str_replace_all(stringr::str_replace_all(peptideSequence,'\\[.*\\]',''),'_','')
		uniquePeptideList <- unique(peptideSequence)
	}else{
		uniquePeptideList <- c()
	}

	uniquePeptideList <- uniquePeptideList[order(uniquePeptideList)]

	# =====================
	# Add protein sequence to color list to change background color of all amino acids, e.g. to dim relative to found peptides
	if(length(proteinSequence)!=0){
		uniquePeptideList <- c(proteinSequence,uniquePeptideList)
		svgColorList <- c(proteinColor,svgColorList)
	}

	# =====================
	# Create different colors for each amino acid
	peptideLabelStr <- c()

	peptideRequestStr <- 'n:%s,s:diamond,fc:%s,cc:%s,bc:%s=%s'
	nPeptides = length(uniquePeptideList)
	for (peptideNo in c(1:nPeptides)) {
		peptideName <- uniquePeptideList[peptideNo]
		# Remove # if present since protter wants raw hex value
		aaColor <- stringr::str_replace_all(svgColorList[peptideNo],'#','')
		aaTextColor <- aminoAcidInterestTextColor
		tmpStr <- sprintf(peptideRequestStr,
			peptideName,
			aaColor,
			aaTextColor,
			aaColor,
			peptideName)
		peptideLabelStr <- c(peptideLabelStr,tmpStr)
	}

	peptideLabelStr <- paste0(peptideLabelStr,collapse='&')

	# =====================
	# Create protter request
	# &n:BA06,s:diamond,fc:%s,cc:%s,bc:%s=%s
	protterRequestStr <- "http://wlab.ethz.ch/protter/create?
	up=%s
	&lc=%s
	&%s
	&format=%s
	&tm=auto
	&mc=lightsalmon
	&tml=numcount
	&cutAt=peptidecutter.Tryps
	&n:signal%%20peptide,fc:red,bc:red=UP.SIGNAL
	&n:disulfide%%20bonds,s:box,fc:greenyellow,bc:greenyellow=UP.DISULFID
	&n:variants,s:diamond,fc:orange,bc:orange=UP.VARIANT
	&n:PTMs,s:box,fc:forestgreen,bc:forestgreen=UP.CARBOHYD,UP.MOD_RES
	&legend
	"
	protterRequestStr <- stringr::str_replace_all(protterRequestStr,'[\r\n\t]','')

	protterUrl <- sprintf(protterRequestStr,
		proteinID,
		transmembraneLabelColor,
		peptideLabelStr,
		# aminoAcidInterestColor,
		# aminoAcidInterestTextColor,
		# aminoAcidInterestColor,
		# paste0(uniquePeptideList,collapse=','),
		picType)

	# =====================
	# Download image and save to a temporary file
	print('Downloading URL:')
	print(protterUrl)
	tmpFileHandle <- tempfile(fileext='.svg')
	# utils::download.file(protterUrl,tmpFileHandle,mode="wb",method='curl',quiet =TRUE)
	utils::download.file(protterUrl,tmpFileHandle,mode="wb",method='auto',quiet =TRUE)

	# =====================
	# Display the plot
	if(displayType=='magick'){
		tmpImg1 <- magick::image_read_svg(tmpFileHandle, width = svgLoadWidth)
		print(tmpImg1)
		protterProteinPlot = c()
	}else if(displayType=='ggimage'){
		# Plot SVG as background of ggplot plot
		dummyFrame <- data.frame(x = 0, y = 0, image=tmpFileHandle)
		protterProteinPlot <- ggplot2::ggplot(dummyFrame, ggplot2::aes(x,y, image=image))+
		ggimage::geom_bgimage(tmpFileHandle)
	}else if(displayType=='ggplot2'){
		# Load SVG and plot
		tmpImg1 <- magick::image_read_svg(tmpFileHandle, width = svgLoadWidth)
		imgWidth = magick::image_info(tmpImg1)$width
		imgHeight = magick::image_info(tmpImg1)$height

		# protterProteinPlot <- ggplot2::ggplot()+
		# ggplot2::annotation_custom(
		# 	grid::rasterGrob(
		# 		tmpImg1,
		# 		width=1,
		# 		height=imgHeight/imgWidth
		# 		# width=ggplot2::unit(1*(imgHeight/imgWidth),"npc"),
		# 		# height=ggplot2::unit(1,"npc")
		# 		),
		# 		# xmin=1, xmax=1+imgWidth, ymin=1, ymax=1+imgHeight/imgWidth
		# 		-Inf, Inf, -Inf, Inf
		# 		)
		# # ggplot2::coord_fixed(ratio = imgWidth/imgHeight)

		protterProteinPlot <- cowplot::ggdraw()+
		cowplot::draw_image(tmpImg1, scale = 1.0)
	}

	if(displayType!='magick'){
		protterProteinPlot <- protterProteinPlot+ggplot2::ggtitle(sprintf('%s | red peptide sequences are those used to identify protein across all runs',proteinID))+

		if(dispPlotBackground=='black'){
			ggplot2::theme(
				plot.title = ggplot2::element_text(vjust=1.4, colour = 'white'),
				line = ggplot2::element_blank(),
				panel.border = ggplot2::element_blank(),
				panel.grid.major = ggplot2::element_blank(),
				panel.grid.minor = ggplot2::element_blank(),
				axis.line = ggplot2::element_line(colour = "black"),
				panel.background = ggplot2::element_rect(fill = 'black', colour = NA),
				plot.background = ggplot2::element_rect(size=1,linetype="solid",color='black', fill = 'black')
			)
		}else if(dispPlotBackground=='white'){
			ggplot2::theme(
				plot.title = ggplot2::element_text(vjust=1.4, colour = 'black'),
				line = ggplot2::element_blank(),
				panel.border = ggplot2::element_blank(),
				panel.grid.major = ggplot2::element_blank(),
				panel.grid.minor = ggplot2::element_blank(),
				axis.line = ggplot2::element_line(colour = "white"),
				panel.background = ggplot2::element_rect(fill = 'white', colour = NA),
				plot.background = ggplot2::element_rect(size=1,linetype="solid",color='white', fill = 'white')
			)
		}
		# theme_void()

		# Whether to display the plot
		if(dispPlot==TRUE){
			print('Plotting protter output')
			print(protterProteinPlot)
		}else{
			print('Do not plot protter output')
		}
	}

	# Remove temporary file if requested
	if(removeTmpFile==TRUE){
		print(sprintf('Removing temp file: %s',tmpFileHandle))
		file.remove(tmpFileHandle)
	}else{
		print(sprintf('Temp file: %s',tmpFileHandle))
	}

	fxnOutput <- list(protterProteinPlot,tmpFileHandle)

	return(fxnOutput)
}