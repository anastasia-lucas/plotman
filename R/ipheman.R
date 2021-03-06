#' ipheman
#'
#' Create Interactive Manhattan plots for PheWAS
#' @param d data frame, must contain PHE, SNP, CHR, POS pvalue, columns, optional Shape
#' @param phegroup optional grouping file for phenotypes, must contain PHE and Group columns
#' @param line optional pvalue threshold to draw red line at
#' @param log10 plot -log10() of pvalue column, boolean
#' @param yaxis label for y-axis, automatically set if log10=TRUE
#' @param ymax set the upper limit for the y-axis if not automatically scaled
#' @param opacity opacity of points, from 0 to 1, useful for dense plots
#' @param title optional string for plot title
#' @param chrcolor1 first alternating color for chromosome
#' @param chrcolor2 second alternating color for chromosome
#' @param highlight_snp vector of SNPs to highlight
#' @param highlight_p pvalue threshold to highlight
#' @param highlighter color to highlight
#' @param groupcolors named vector of colors for data in 'Color' column
#' @param db choose database to connect to ("dbSNP", "GWASCatalog", or enter your own search address)
#' @param moreinfo includes more information on hover, refers to Info column
#' @param chrblocks boolean, turns on x-axis chromosome marker blocks
#' @param background variegated or white
#' @param file file name of saved image
#' @param hgt height of plot in inches
#' @param wi width of plot in inches
#' @param bigrender can set to TRUE for big plots (~50000 rows) that produce huge input lookup error
#' @import ggplot2
#' @return html file
#' @export
#' @family PheWAS functions
#' @family interactive plotting functions
#' @seealso \code{\link{pheman}}, \code{\link{apheman}}, \code{\link{igman}}, \code{\link{ieman}}
#' @examples
#' #In this case we'd like to also see the p-value when we hover over a point,
#' #so we'll add an 'Info' column to the data
#' #We'd also like to search dbSNP when we click on a point
#' data(phewas)
#' phewas$Info <- paste0("p-value:", signif(phewas$pvalue, digits=3))
#' ipheman(d=phewas, moreinfo = TRUE, db="dbSNP", line=0.001, title="PheWAS Example")

ipheman <- function(d, phegroup, line, log10=TRUE, yaxis, ymax, opacity=1, highlight_snp, highlight_p, highlighter="red", title=NULL, chrcolor1="#AAAAAA", chrcolor2="#4D4D4D", groupcolors, background="variegated", chrblocks=TRUE, db, moreinfo=FALSE, bigrender=FALSE, file="ipheman", hgt=7, wi=12){
  if (!requireNamespace(c("ggiraph"), quietly = TRUE)==TRUE) {
    stop("Please install ggiraph to create interactive visualizations.", call. = FALSE)
  }

  #Sort data
  d$CHR <- factor(d$CHR, levels = c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "X", "Y"))
  if(!missing(phegroup)){
    print("Only phenotypes with grouping information will be plotted")
    d_phe <- merge(phegroup, d, by="PHE")
    names(d_phe)[names(d_phe)=="Group"] <- "Color"

  } else {
    d_phe <- d
    names(d_phe)[names(d_phe)=="PHE"] <- "Color"
  }
  d_order <- d_phe[order(d_phe$CHR, d_phe$POS), ]
  d_order$pos_index <- seq.int(nrow(d_order))
  d_order_sub <- d_order[colnames(d_order) %in% c("SNP", "CHR", "POS", "pvalue", "pos_index")]

  #Set up dataframe with color and position info
  maxRows <- by(d_order_sub, d_order_sub$CHR, function(x) x[which.max(x$pos_index),])
  minRows <- by(d_order_sub, d_order_sub$CHR, function(x) x[which.min(x$pos_index),])
  milimits <- do.call(rbind, minRows)
  malimits <- do.call(rbind, maxRows)
  lims <- merge(milimits, malimits, by="CHR")
  names(lims) <- c("Color", "snpx", "px", "posx", "posmin", "snpy", "py", "posy", "posmax")
  lims$av <- (lims$posmin + lims$posmax)/2
  lims <- lims[order(lims$Color),]
  lims$shademap <- rep(c("shade_ffffff","shade_ebebeb"), length.out=nrow(lims), each=1)

  #Set up tooltip
  ###See what info would be useful here i.e. SNP or something else
  if(!missing(phegroup)){
    d_order$tooltip <- if (moreinfo==TRUE) c(paste0(d_order$PHE, ":", d_order$SNP, "\n ", d_order$Info, sep="")) else paste(d_order$PHE, d_order$SNP, sep=":")
  } else {
    d_order$tooltip <- if (moreinfo==TRUE) c(paste0(d_order$Color, ":", d_order$SNP, "\n ", d_order$Info, sep="")) else paste(d_order$Color, d_order$SNP, sep=":")
  }

  #Set up onclick
  if(!missing(db)){
    if(db=="GWASCatalog"){
      d_order$onclick <- sprintf("window.open(\"%s%s\")","https://www.ebi.ac.uk/gwas/search?query=", as.character(d_order$SNP))
    } else if(db=="dbSNP"){
      d_order$onclick <- sprintf("window.open(\"%s%s\")","https://www.ncbi.nlm.nih.gov/SNP/snp_ref.cgi?searchType=adhoc_search&type=rs&rs=", as.character(d_order$SNP))
    } else {
      d_order$onclick <- sprintf("window.open(\"%s%s\")", db, as.character(d_order$SNP))
    }
  } else {
    d_order$onclick <- NA
  }

  #Set up colors
  nchrcolors <- nlevels(factor(lims$Color))
  if(!missing(groupcolors)){
    dcols <- c(rep(x=c(chrcolor1, chrcolor2), length.out=nchrcolors, each=1), "#FFFFFF", "#EBEBEB")
    names(dcols) <-c(levels(factor(lims$Color)), "shade_ffffff", "shade_ebebeb")
    newcols <- c(dcols, groupcolors)
  } else {
    ngroupcolors <- nlevels(factor(d_order$Color))
    if(ngroupcolors > 15){
      if (!requireNamespace(c("RColorBrewer"), quietly = TRUE)==TRUE) {
        stop("Please install RColorBrewer to add color attribute for more than 15 colors.", call. = FALSE)
      } else {
        getPalette = grDevices::colorRampPalette(RColorBrewer::brewer.pal(11, "Spectral"))
        newcols <- c(rep(x=c(chrcolor1, chrcolor2), length.out=nchrcolors, each=1), getPalette(ngroupcolors), "#FFFFFF", "#EBEBEB")
      }
    } else {
      pal <- pal <- c("#009292", "#920000", "#490092", "#db6d00", "#24ff24",
                      "#ffff6d", "#000000", "#006ddb", "#004949","#924900",
                      "#ff6db6", "#6db6ff","#b66dff", "#ffb6db","#b6dbff")
      newcols <- c(rep(x=c(chrcolor1, chrcolor2), length.out=nchrcolors, each=1), pal[1:ngroupcolors], "#FFFFFF", "#EBEBEB")
    }
    names(newcols) <-c(levels(factor(lims$Color)), levels(factor(d_order$Color)), "shade_ffffff", "shade_ebebeb")
  }

  #Info for y-axis
  if(log10==TRUE){
    d_order$pval <- -log10(d_order$pvalue)
    yaxislab <- expression(paste("-log"[10], "(p-value)", sep=""))
    if(!missing(line)) {redline <- -log10(line)}
  } else {
    d_order$pval <- d_order$pvalue
    yaxislab <- yaxis
    if(!missing(line)) {redline <- line}
  }

  #Allow more than 6 shapes
  #3, 4 and 7 to 14 are composite symbols- incompatible with ggiraph
  if("Shape" %in% names(d)){
    allshapes <- c(16,15,17,18,0:2,5:6,19:25,33:127)
    shapevector <- allshapes[1:nlevels(as.factor(d$Shape))]
  }

  #Theme options
  yaxismin <- min(d_order$pval)
  backpanel <- ifelse(background=="white", "NULL", "geom_rect(data = lims, aes(xmin = posmin-.5, xmax = posmax+.5, ymin = yaxismin, ymax = Inf, fill=factor(shademap)), alpha = 0.5)" )

  #Start plotting
  p <- ggplot() + eval(parse(text=backpanel))
  #Add shape info if available
  if("Shape" %in% names(d)){
    p <- p + ggiraph::geom_point_interactive(data=d_order, aes(x=pos_index, y=pval, tooltip=tooltip, onclick=onclick, color=factor(Color), shape=factor(Shape)), alpha=opacity) + scale_shape_manual(values=shapevector)
  } else {
    p <- p + ggiraph::geom_point_interactive(data=d_order, aes(x=pos_index, y=pval, tooltip=tooltip, onclick=onclick, color=factor(Color)), alpha=opacity)
  }
  p <- p + scale_x_continuous(breaks=lims$av, labels=lims$Color, expand=c(0,0))
  if(chrblocks==TRUE){p <- p + geom_rect(data = lims, aes(xmin = posmin-.5, xmax = posmax+.5, ymin = -Inf, ymax = min(d_order$pval), fill=as.factor(Color)), alpha = 1)}
  #Add legend
  p <- p + scale_colour_manual(name = "Color", values = newcols) + scale_fill_manual(name = "Color",values = newcols, guides(alpha=FALSE))
  p <- p + theme(axis.text.x=element_text(angle=90), panel.grid.minor.x = element_blank(), panel.grid.major.x=element_blank(), axis.title.x=element_blank(), legend.position="bottom", legend.title=element_blank())
  #Highlight if given
  if(!missing(highlight_snp)){
    if("Shape" %in% names(d)){
      p <- p + ggiraph::geom_point_interactive(data=d_order[d_order$SNP %in% highlight_snp, ], aes(x=pos_index, y=pval, shape=Shape, tooltip=tooltip, onclick=onclick), colour=highlighter) + scale_shape_manual(values=shapevector)
      p <- p + guides(shape = guide_legend(override.aes = list(colour = "black")))
    } else {
      p <- p + ggiraph::geom_point_interactive(data=d_order[d_order$SNP %in% highlight_snp, ], aes(x=pos_index, y=pval, tooltip=SNP, onclick=onclick), colour=highlighter)
    }
  }
  if(!missing(highlight_p)){
    if("Shape" %in% names(d)){
      p <- p + ggiraph::geom_point_interactive(data=d_order[d_order$pvalue < highlight_p, ], aes(x=pos_index, y=pval, shape=Shape, tooltip=tooltip, onclick=onclick), colour=highlighter) + scale_shape_manual(values=shapevector)
      p <- p + guides(shape = guide_legend(override.aes = list(colour = "black")))
    } else {
      p <- p + ggiraph::geom_point_interactive(data=d_order[d_order$pvalue < highlight_p, ], aes(x=pos_index, y=pval, tooltip=tooltip, onclick=onclick), colour=highlighter)
    }
  }
  #Add title and y axis title
  p <- p + ggtitle(title) + ylab(yaxislab)
  #Add pvalue threshold line
  if(!missing(line)){
    p <- p + geom_hline(yintercept = redline, colour="red")
  }
  #Theme
  if(!missing(ymax)){
    yaxismax <- ymax
  } else {
    yaxismax <- max(d_order$pval)
  }
  if(chrblocks==TRUE){
    p <- p+ylim(c(yaxismin,yaxismax))
  } else {
    p <- p+scale_y_continuous(limits=c(yaxismin, yaxismax), expand=expand_scale(mult=c(0,0.1)))
  }
  if(background=="white"){p <- p + theme(panel.background = element_rect(fill="white"))}

  #Save
  print(paste("Saving plot to ", file, ".html", sep=""))
  tooltip_css <- "background-color:black;color:white;padding:6px;border-radius:15px 15px 15px 15px;"
  if(bigrender==TRUE){
    print(paste("WARNING: Attempting to render ", nrow(d_order), " rows. Plot may be slow to render or load.", sep=""))
    ip <- ggiraph::ggiraph(code=print(p), tooltip_extra_css = tooltip_css, tooltip_opacity = 0.75, zoom_max = 6, width_svg=wi, height_svg=hgt, xml_reader_options = list(options="HUGE"))
    htmlwidgets::saveWidget(widget=ip, file=paste(file, ".html", sep=""))
    return(p)
  } else {
    ip <- ggiraph::ggiraph(code=print(p), tooltip_extra_css = tooltip_css, tooltip_opacity = 0.75, zoom_max = 6, width_svg=wi, height_svg=hgt)
    htmlwidgets::saveWidget(widget=ip, file=paste(file, ".html", sep=""))
    return(ip)
  }


}
