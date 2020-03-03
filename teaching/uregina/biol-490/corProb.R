## correlation function
## based on post by Bill Venables on R-Help
## Date: Tue, 04 Jan 2000 15:05:39 +1000
## https://stat.ethz.ch/pipermail/r-help/2000-January/009758.html
## modified by G L Simpson, Sep 2003
##
## Last modified: 10th July 2006
##
## version 0.3: added extra functionality following R-Help
##              query. Can now work with F or T statistics,
##              allows alternative hypotheses for the
##              t-tests, and allows use of "use" argument.
## version 0.2: added print.cor.prob
##              added class statement to cor.prob
## version 0.1: original function of Bill Venables
corProb <- function(X, dfr = nrow(X) - 2,
                    use = c("all.obs", "complete.obs",
                      "pairwise.complete.obs"),
                    alternative = c("two.sided", "less",
                      "greater"),
                    type = c("F", "t"),
                    pval = TRUE) {
  USE <- match.arg(use)
  ALTERNATIVE <- match.arg(alternative)
  R <- cor(X, use = USE)
  above <- row(R) < col(R)
  r2 <- R[above]^2
  TYPE <- match.arg(type)
  if(TYPE == "t") {
    Tstat <- sqrt(dfr) * R[above]/sqrt(1 - r2)
    if(pval) {
      p <- pt(Tstat, dfr)
      R[above] <- switch(ALTERNATIVE, less = p,
                         greater = 1 - p, 
                         two.sided = 2 * min(p, 1 - p))
    }
    else
      R[above] <- Tstat
  }
  else {
    Fstat <- r2 * dfr / (1 - r2)
    if(pval)
      R[above] <- 1 - pf(Fstat, 1, dfr)
    else
      R[above] <- Fstat
  }
  class(R) <- "corProb"
  attr(R, "type") <- TYPE
  attr(R, "pval") <- pval
  attr(R, "hypoth") <- ALTERNATIVE
  R
}

print.corProb <- function(x, digits = getOption("digits"),
                          quote = FALSE, na.print = "",
                          justify = "none", ...) {
  xx <- format(unclass(round(x, digits = 4)), digits = digits,
               justify = justify)
  if (any(ina <- is.na(x)))
    xx[ina] <- na.print
  cat("\nCorrelations are shown below the diagonal\n")
  if(attr(x, "pval"))
     cat(paste("P-values of the ", attr(x, "type"),
               "-statistics are shown above the diagonal\n\n",
               sep = ""))
  else
     cat(paste(attr(x, "type"),
               "-values are shown above the diagonal\n\n",
               sep = ""))
  if(attr(x, "type") == "t") {
    hypoth <- switch(attr(x, "hypoth"),
                     less = "less than 0",
                     greater = "greater than 0",
                     two.sided = "not equal to 0")
    cat(paste("alternative hypothesis: true correlation is",
              hypoth, "\n\n"))
  }
  print.default(xx, quote = quote, ...)
  invisible(x)
}
