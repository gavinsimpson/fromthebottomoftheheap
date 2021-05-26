## Fit MGM & CRF to Abernethy Forest data set

## Packages
library('readr')
library('mgm')
library('qgraph')
library('analogue')
library('MRFcov')

## Load data
aber <- read_rds('abernethy-count-data.rds')
## or:
aber <- read_rds(url('http://bit.ly/abercount'))
## take a subset of spp
take <- c("BETULA", "PINUS_SYLVESTRIS", "ULMUS", "QUERCUS", "ALNUS_GLUTINOSA",
          "CORYLUS_MYRICA", "SALIX", "JUNIPERUS_COMMUNIS", "CALLUNA_VULGARIS",
          "EMPETRUM", "GRAMINEAE", "CYPERACEAE", "SOLIDAGO_TYPE",
          "COMPOSITAE_LIGULIFLORAE", "ARTEMISIA", "CARYOPHYLLACEAE_UNDIFFERENTIATED",
          "SAGINA", "SILENE_CF_S_ACAULIS", "CHENOPODIACEAE", "EPILOBIUM_TYPE",
          "PAPILIONACEAE_UNDIFFERENTIATED", "ANTHYLLIS_VULNERARIA",
          "ASTRAGALUS_ALPINUS", "ONONIS_TYPE", "ROSACEAE_UNDIFFERENTIATED",
          "RUBIACEAE", "RANUNCULACEAE_UNDIFFERENTIATED", "THALICTRUM",
          "RUMEX_ACETOSA_TYPE", "OXYRIA_TYPE", "PARNASSIA_PALUSTRIS",
          "SAXIFRAGA_GRANULATA", "SAXIFRAGA_HIRCULUS_TYPE", "SAXIFRAGA_NIVALIS",
          "SAXIFRAGA_OPPOSITIFOLIA", "SAXIFRAGA_UNDIFFERENTIATED", "SEDUM",
          "URTICA", "VERONICA")
##take <- c(1,2,3,4,6,10,11,12,14,15,39,40,41,42,43,46,49,50,53,54,57,58,59,60,67,
##          69,70,72,74,75,83,85,86)
aber <- aber[, take]
## are any columns now all zeroes?
allMissing <- unname(vapply(aber, function(x) all(is.na(x)), logical(1)))
## drop those with all NA
aber <- aber[, !allMissing]
## change all the NA to 0s
aber <- tran(aber, method = "missing")
## check that all remaining values are numeric
stopifnot(all(vapply(aber, data.class, character(1), USE.NAMES = FALSE) == "numeric"))
## check all columns still have at least 1 positive count
cs <- colSums(aber) > 0L
aber <- aber[, cs]
names(aber) <- tolower(names(aber))
## aber ages
aberAge <- read_rds('abernethy-sample-age.rds')
## or:
aberAge <- read_rds(url('http://bit.ly/aberage'))


## stationary MGM
timer <- Sys.time()
stat_mgm <- mgm(data = aber,
                type = rep('p', ncol(aber)),
                k = 2,
                lambdaSel = 'EBIC', # "CV"
                alphaSel = 'EBIC',
                lambdaFolds = 5,
                ruleReg = 'AND')
Sys.time() - timer

## predictions
pred_mgm <- predict(stat_mgm,
                    data = aber,
                    errorCon = c('RMSE', 'R2'))

qgraph(stat_mgm$pairwise$wadj,
       edge.color = stat_mgm$pairwise$edgecolor,
       pie = pred_mgm$errors[, 'R2'],
       pieColor = 'tomato',
       labels = colnames(aber),
       label.cex = 0.8,
       legend = FALSE,
       layout = 'circle',
       filetype = "R", #'pdf',
       filename = 'static-mgm-spring-layout')

qgraph(stat_mgm$pairwise$wadj,
       edge.color = stat_mgm$pairwise$edgecolor,
       pie = pred_mgm$errors[, 'R2'],
       pieColor = 'tomato',
       labels = colnames(aber),
       label.cex = 0.7,
       legend = FALSE,
       filetype = 'R',
       filename = 'static-mgm-circle-layout',
       vsize = 3)

## time-varying MGM
## bandwidth selection
timer <- Sys.time()
set.seed(1)
bw_tvm <- bwSelect(data = aber,
                   type = rep('p', ncol(aber)),
                   level = rep(1, ncol(aber)),
                   k = 2,
                   bwSeq = seq(0.1, 1, by = 0.2),
                   bwFolds = 1, bwFoldsize = 2,
                   timepoints = aberAge$Age,
                   modeltype = 'mgm',
                   threshold = 'none', ruleReg = 'AND',
                   pbar = TRUE)
Sys.time() - timer

round(bw_tvm$meanError, 3)

## Run the model fit for the selected bandwith - 10 mins!
## NO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
timer <- Sys.time()
set.seed(1)
tvm <- tvmgm(data = aber,
             type = rep('p', ncol(aber)),
             level = rep(1, ncol(aber)),
             k = 2,
             lambdaSel = 'EBIC',
             alphaSel = 'EBIC',
             bandwidth = 0.5,
             timepoints = aberAge$Age,
             modeltype = 'mgm',
             threshold = 'none', ruleReg = 'AND',
             estpoints = seq(0, 1, length = 50))
Sys.time() - timer
write_rds(tvm, file = "time-varying-mgm.rds")
## 

tvm <- read_rds("time-varying-mgm.rds")

## get wadj
wadj <- tvm$pairwise$wadj
adj <- wadj
adj[adj!=0] <- 1
## number of edges across estimation points
n_edges <- apply(adj, 3, sum)/2 # divide by two as edge goes both ways

## pull out age for ease
ybp <- aberAge$Age
ybpseq <- seq(min(ybp), max(ybp), length = 50)

## build data frame for plotting in ggplot
df <- data.frame(n_edges = n_edges, yearbp = ybpseq)

ggplot(df, aes(x = yearbp, y = n_edges)) +
    geom_point() +
    geom_line() +
    labs(y = 'Number of edges', x = 'Years BP') +
    scale_x_reverse()

## Plot the estimated networks for some time points
## which samples to select? Remember time is backward to reverse
E_select <- rev(c(3, 17, 25, 35, 45))
# Color shade for Nodes
wDegree <- list()
for (i in 1:50) {
    wDegree[[i]] <- colSums(adj[,,i]) + 1
    wDegree[[i]][wDegree[[i]]>30]<-30
}
## how many colours
n_color <- max(unlist(wDegree))
node_cols <- RColorBrewer::brewer.pal(n_color, 'Blues')
## split the device into 5 plots
layout(matrix(1:5, ncol = 5))
## plot netowkrs in a loop
for(i in E_select) {
    qgraph(adj[,,i], layout = 'circle',
           labels = TRUE,
           edge.color = tvm$pairwise$edgecolor[,,i],
           color = node_cols[wDegree[[i]]],
           mar = c(6, 6, 6, 6),
           label.cex = 2,
           node.width = 1.2, node.height = 1.2)
}
layout(1)


library('MRFcov')
mrf <- MRFcov(data = aber, n_nodes = ncol(aber), n_cores = 2,
              family = 'poisson')
              
plotMRF_hm(mrf)

## To get a network diagram from the MRF, you can extract the adjacency matrix
## and convert it to an igraph object...
net <- igraph::graph.adjacency(mrf$graph, weighted = TRUE, mode = "undirected")
## ... then plot with igraphs plot method
igraph::plot.igraph(net, layout = igraph::layout.circle,
                    edge.width = abs(igraph::E(net)$weight),
                    edge.color = ifelse(igraph::E(net)$weight < 0, 'blue', 'red'))


