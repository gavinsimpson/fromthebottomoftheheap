dgev <- function(x, mu = 0, sigma = 1, xi = 0, log = FALSE,
                 no.support = 0) {
    xi[abs(xi) < 1e-8] <- 1e-8 ## approximate xi=0, by small xi
    tx <- (1 + xi * ((x - mu) / sigma))^-(1 / xi)
    pdf <- (1 / sigma) * tx^(xi + 1) * exp(-tx)

    lim <- mu - sigma / xi
    pdf[(xi > 0 & x < lim) | (xi < 0 & x > lim)] <- no.support
    pdf
}

## gev_dens <- crossing(x = seq(-4, 4, by = 0.01), mu = 0,
##                      sigma = 1, xi = c(-0.5, 0, 0.5)) %>%
##     mutate(density = dgev(x, mu, sigma, xi))
## ggplot(gev_dens,
##        aes(x = x, y = density, colour = factor(xi))) +
##     geom_line() +
##     labs(title = 'Generalised Extreme Value Density',
##          y = 'Density', colour = expression(xi))

qgev <- function(p, mu, sigma, xi) {
    ## GEV inverse cdf
    xi[abs(xi) < 1e-8] <- 1e-8 ## approximate xi=0, by small xi
    mu + ((-log(p))^-xi - 1) * sigma / xi
}

rgev <- function(n, mu, sigma, xi) {
    if (!all(xi > -1L & xi < 0.5)) {
        stop("xi must be in interval -1 < xi < 1/2", call. = FALSE)
    }
    qgev(runif(n), mu, sigma, xi)
}

expected_gev <- function(model, newdata = NULL) {
    Predict <- function(model, newdata = NULL) {
        if (is.null(newdata)) {
            predict(model, type = "response")
        } else {
            predict(model, newdata = newdata, type = "response")
        }
    }
    p <- unname(Predict(model, newdata = newdata))
    colnames(p) <- c("mu", "rho", "xi")
    p[, "mu"] + exp(p[, "rho"]) * (gamma(1 - p[, "xi"]) - 1) / p[, "xi"]
}

expected_gev2 <- function(mu, sigma, xi) {
    if (!all(xi > -1L & xi < 0.5)) {
        stop("xi must be in interval -1 < xi < 1/2", call. = FALSE)
    }
    mu + sigma * (gamma(1 - xi) - 1) / xi
}

##' importFrom mvnfast rmvn
fitted_draws_gev_gam <- function(model, nsim = 1, seed = NULL, newdata = NULL,
                                 freq = FALSE, unconditional = FALSE, ncores = 1,
                                 minima = FALSE, ...) {
    if (!exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        runif(1)
    }
    if (is.null(seed)) {
        RNGstate <- get(".Random.seed", envir = .GlobalEnv)
    } else {
        R.seed <- get(".Random.seed", envir = .GlobalEnv)
        set.seed(seed)
        RNGstate <- structure(seed, kind = as.list(RNGkind()))
        on.exit(assign(".Random.seed", R.seed, envir = .GlobalEnv))
    }
    
    if (missing(newdata) || is.null(newdata)) {
        newdata <- model[["model"]]
    }

    V <- gratia:::get_vcov(model, frequentist = freq, unconditional = unconditional)

    betas <- mvnfast::rmvn(n = nsim, mu = coef(model), sigma = V,
                           ncores = ncores)

    Xp <- predict(model, newdata = newdata, type = "lpmatrix")
    lpi <- attr(Xp, "lpi")

    ## inverse link functions
    mu_ilink    <- inverse_link_gev(model, "mu")
    sigma_ilink <- inverse_link_gev(model, "sigma")
    xi_ilink    <- inverse_link_gev(model, "xi")
    
    mu_sims    <- mu_ilink(Xp[, lpi[[1L]], drop = FALSE] %*%
                           t(betas[, lpi[[1L]], drop = FALSE]))
    sigma_sims <- sigma_ilink(Xp[, lpi[[2L]], drop = FALSE] %*%
                              t(betas[, lpi[[2L]], drop = FALSE]))
    xi_sims    <- xi_ilink(Xp[, lpi[[3L]], drop = FALSE] %*%
                           t(betas[, lpi[[3L]], drop = FALSE]))

    sims <- expected_gev2(mu = mu_sims, sigma = sigma_sims, xi = xi_sims)
    if (minima) {
        sims <- -sims
    }
    colnames(sims) <- paste0("s", seq_len(nsim))
    sims <- as_tibble(sims)
    
    attr(sims, "seed") <- RNGstate
    sims
}

inverse_link_gev <- function(model, parameter = c("mu", "sigma", "xi", "rho")) {
    ## rho == log(sigma)
    ## if want sigma then we need to exp(rho), hence take inverse link from
    ## the poisson() family
    parameter <- match.arg(parameter)
    fam <- family(model)
    switch(parameter,
           mu = fam[["linfo"]][[1L]][["linkinv"]],
           sigma = poisson()[["linkinv"]],
           xi = fam[["linfo"]][[3L]][["linkinv"]],
           rho = fam[["linfo"]][[2L]][["linkinv"]])
}
