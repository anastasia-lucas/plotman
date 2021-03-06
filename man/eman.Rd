% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/eman.R
\name{eman}
\alias{eman}
\title{eman}
\usage{
eman(d, line, log10 = TRUE, yaxis, ymax, opacity = 1, title = NULL,
  annotate_var, annotate_p, highlight_var, highlight_p, highlighter = "red",
  color1 = "#AAAAAA", color2 = "#4D4D4D", groupcolors,
  background = "variegated", grpblocks = FALSE, file = "eman", hgt = 7,
  wi = 12, res = 300)
}
\arguments{
\item{d}{data frame, columns are Variable, pvalue, and Group; Shape and Color optional}

\item{line}{optional pvalue threshold to draw red line at}

\item{log10}{plot -log10() of pvalue column, boolean}

\item{yaxis}{label for y-axis, automatically set if log10=TRUE}

\item{ymax}{set the upper limit for the y-axis if not automatically scaled}

\item{opacity}{opacity of points, from 0 to 1, useful for dense plots}

\item{title}{optional string for plot title}

\item{annotate_var}{vector of variables to annotate}

\item{annotate_p}{pvalue threshold to annotate}

\item{highlight_var}{vector of variables to highlight}

\item{highlight_p}{pvalue threshold to highlight}

\item{highlighter}{color to highlight}

\item{color1}{first alternating color}

\item{color2}{second alternating color}

\item{groupcolors}{named vector of colors for data in 'Color' column}

\item{background}{variegated or white}

\item{grpblocks}{boolean, turns on x-axis group marker blocks}

\item{file}{file name of saved image}

\item{hgt}{height of plot in inches}

\item{wi}{width of plot in inches}

\item{res}{resolution of plot in pixels per inch}
}
\value{
png image(s)
}
\description{
Create Manhattan plots for EWAS
}
\examples{
data(ewas)
eman(d=ewas, title="EWAS", line=0.001, annotate_p=0.001, color1="#A23B72", color2="#2A84AA",
highlight_p=0.001, highlighter="green")
}
\seealso{
\code{\link{ieman}}, \code{\link{aeman}}, \code{\link{gman}}, \code{\link{pheman}}

Other EWAS functions: \code{\link{aeman}},
  \code{\link{ieman}}

Other static plotting functions: \code{\link{gman}},
  \code{\link{pheman}}
}
