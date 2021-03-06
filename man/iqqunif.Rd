% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/iqqunif.R
\name{iqqunif}
\alias{iqqunif}
\title{iqqunif}
\usage{
iqqunif(d, CI = 0.95, opacity = 1, groupcolors, splitby = NULL,
  moreinfo = TRUE, db, highlight_p, highlight_name, annotate_p, annotate_name,
  highlighter = "red", line, background, title, bigrender = FALSE,
  file = "iqqunif", wi = 7, hgt = 7, res = 300)
}
\arguments{
\item{d}{dataframe with at least two columns, p-value and Name; Color, Shape, Info optional}

\item{CI}{two-sided confidence interval, default 0.95}

\item{opacity}{point opacity, default 1}

\item{groupcolors}{named vector of colors corresponding to data in Group column}

\item{splitby}{if data contains Color and/or Shape, indicate variable(s) by which the data should be subsetted for calculating CIs}

\item{moreinfo}{includes more information on hover, refers to Info column}

\item{db}{choose database to connect to ("dbSNP", "GWASCatalog", or enter your own search address)}

\item{highlight_p}{p-value threshold to highlight}

\item{highlight_name}{vector of names to highlight, dataframe must include a Name column}

\item{annotate_p}{p-value threshold to annotate, dataframe must include a Name column}

\item{annotate_name}{vector of names to annotate, dataframe must include a Name column}

\item{highlighter}{highlighter color}

\item{line}{draw a red line at pvalue threshold (observed)}

\item{background}{can change to "white"}

\item{title}{plot title}

\item{bigrender}{can set to TRUE for big plots (~50000 rows) that produce huge input lookup error}

\item{file}{filename}

\item{wi}{width of plot}

\item{hgt}{height of plot}

\item{res}{resolution of plot}
}
\value{
html file
}
\description{
Create interactive qqplots with an assumed uniform distribution
}
\examples{
data(gwas)
qqdat <- data.frame(pvalue=gwas$pvalue, Color=gwas$Frame, Name=gwas$Frame)
iqqunif(d=qqdat, splitby="Color", db="https://www.google.com/search?q=")
}
