#' apheman
#'
#' Create Manhattan plots for PheWAS
#' @param d data frame, must contain PHE, SNP, CHR, POS, pvalue, Frame columns, optional Shape
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
#' @param annotate_snp vector of SNPs to annotate
#' @param annotate_p pvalue threshold to annotate
#' @param highlighter color to highlight
#' @param groupcolors named vector of colors for data in 'Color' column
#' @param chrblocks boolean, turns on x-axis chromosome marker blocks
#' @param background variegated or white
#' @param file file name of saved image
#' @param ext file type to save, "gif" or "mp4"
#' @param hgt height of plot in pixels
#' @param wi width of plot in pixels
#' @return .gif or .mp4 file
#' @import ggplot2
#' @export
#' @family PheWAS functions
#' @family animated plotting functions
#' @seealso \code{\link{pheman}}, \code{\link{ipheman}}, \code{\link{agman}}, \code{\link{aeman}}
#' @examples
#' #We can duplicate the PHE column so that each
#' #phenotype will be a frame
#' data(phewas)
#' phewas$Frame <- phewas$PHE
#' apheman(phewas, line=0.001, title="PheWAS Example:")

apheman <- function(d, phegroup, line, log10=TRUE, yaxis, ymax, opacity=1, annotate_snp, annotate_p, highlight_snp, highlight_p, highlighter="red", title=NULL, chrcolor1="#AAAAAA", chrcolor2="#4D4D4D", groupcolors, background="variegated", chrblocks=TRUE, file="apheman", ext="gif", hgt=800, wi=1300){
  if (!requireNamespace(c("gganimate"), quietly = TRUE)==TRUE) {
    stop("Please install gganimate to create animated visualizations.", call. = FALSE)
  }

  #Check that frame is present
  if(!("Frame" %in% names(d))){stop("Please add 'Frame' column for animation attribute")}

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
  lims$shademap <- rep(c("shade_ffffff", "shade_ebebeb"), length.out=nrow(lims), each=1)

  #Frame must be a factor
  d_order$Frame <- factor(d_order$Frame)

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
  if("Shape" %in% names(d)){
    allshapes <- c(16,15,17,3,7,8,0:2,4:6,9:14,18:25,33:127)
    shapevector <- allshapes[1:nlevels(as.factor(d$Shape))]
  }

  #Theme options
  yaxismin <- min(d_order$pval)
  backpanel <- ifelse(background=="white", "NULL", "geom_rect(data = lims, aes(xmin = posmin-.5, xmax = posmax+.5, ymin = yaxismin, ymax = Inf, fill=factor(shademap)), alpha = 0.5)" )

  #Start plotting
  p <- ggplot() + eval(parse(text=backpanel))
  #Add shape info if available
  if("Shape" %in% names(d)){
    p <- p + geom_point(data=d_order, aes(x=pos_index, y=pval, color=factor(Color), shape=factor(Shape), frame=Frame), alpha=opacity) + scale_shape_manual(values=shapevector)
  } else {
    p <- p + geom_point(data=d_order, aes(x=pos_index, y=pval, color=factor(Color), frame=Frame), alpha=opacity)
  }
  p <- p + scale_x_continuous(breaks=lims$av, labels=lims$Color, expand=c(0,0))
  if(chrblocks==TRUE){p <- p + geom_rect(data = lims, aes(xmin = posmin-.5, xmax = posmax+.5, ymin = -Inf, ymax = min(d_order$pval), fill=as.factor(Color)), alpha = 1)}
  #Add legend
  p <- p + scale_colour_manual(name = "Color", values = newcols) + scale_fill_manual(name = "Color", values = newcols, guides(alpha=FALSE))
  p <- p + theme(axis.text.x=element_text(angle=90), panel.grid.minor.x = element_blank(), panel.grid.major.x=element_blank(), axis.title.x=element_blank(), legend.position="bottom", legend.title=element_blank())
  #Highlight if given
  if(!missing(highlight_snp)){
    if("Shape" %in% names(d)){
      p <- p + geom_point(data=d_order[d_order$SNP %in% highlight_snp, ], aes(x=pos_index, y=pval, shape=Shape, frame=Frame), colour=highlighter) + scale_shape_manual(values=shapevector)
      p <- p + guides(shape = guide_legend(override.aes = list(colour = "black")))
    } else {
      p <- p + geom_point(data=d_order[d_order$SNP %in% highlight_snp, ], aes(x=pos_index, y=pval), colour=highlighter)
    }
  }
  if(!missing(highlight_p)){
    if("Shape" %in% names(d)){
      p <- p + geom_point(data=d_order[d_order$pvalue < highlight_p, ], aes(x=pos_index, y=pval, shape=Shape, frame=Frame), colour=highlighter) + scale_shape_manual(values=shapevector)
      p <- p + guides(shape = guide_legend(override.aes = list(colour = "black")))
    } else {
      p <- p + geom_point(data=d_order[d_order$pvalue < highlight_p, ], aes(x=pos_index, y=pval), colour=highlighter)
    }
  }
  if(!missing(annotate_p)){
    if (!requireNamespace(c("ggrepel"), quietly = TRUE)==TRUE) {
      print("Consider installing 'ggrepel' for improved text annotation")
      p <- p + geom_text(data=d_order[d_order$pvalue < annotate_p,], aes(pos_index,pval,label=SNP,frame=Frame))
    } else {
      p <- p + ggrepel::geom_text_repel(data=d_order[d_order$pvalue < annotate_p,], aes(pos_index,pval,label=SNP,frame=Frame))
    }
  }
  if(!missing(annotate_snp)){
    if (!requireNamespace(c("ggrepel"), quietly = TRUE)==TRUE){
      print("Consider installing 'ggrepel' for improved text annotation")
      p <- p + geom_text(data=d_order[d_order$SNP %in% annotate_snp,], aes(pos_index,pval,label=SNP,frame=Frame))
    } else {
      p <- p + ggrepel::geom_text_repel(data=d_order[d_order$SNP %in% annotate_snp,], aes(pos_index,pval,label=SNP,frame=Frame))
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

  #Animate and save
  print(paste("Saving plot to ", file, ".", ext, sep=""))
  ap <- gganimate::gganimate(p)
  gganimate::gganimate_save(ap, filename=paste(file, ".", ext, sep=""), ani.height=hgt, ani.width=wi)
  return(ap)
}
