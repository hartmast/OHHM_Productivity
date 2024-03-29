library(tidyverse)
library(patchwork)
library(zipfR)
library(pbapply)

# CQP query: 
# cwb-scan-corpus CLMET lemma text_period >  "clmet_lemma_period.txt"

# read data: full CLMET frequency list
d <- read_delim("clmet_lemma_period.txt", delim = "\t", quote = "",
                col_names = c("Freq", "lemma", "period"))


# omit punctuation:
# we replace all instances where the string consísts only
# of punctuation
d <- d[-grep("^[[:punct:]]+", d$lemma),]


# find hapaxes

# frequency list per period
d_tbl <- d %>% group_by(lemma, period) %>% summarise(
  n = sum(Freq)
)


# frequency list for the entire corpus
d_tbl2 <- d %>% group_by(lemma) %>% summarise(
  n_all = sum(Freq)
)

# combine both tables
d_tbl <- left_join(d_tbl, d_tbl2)

# add hapax column
d_tbl <- mutate(d_tbl, hapax = ifelse(n_all == 1, TRUE, FALSE))

# count hapaxes in -hood per period,
# divide by sum total of tokens in hood
# in each period

# find tokens ending in -hood
d_tbl <- mutate(as.data.frame(d_tbl), hood = grepl(".+hood", d_tbl$lemma))

productivity <- d_tbl %>% group_by(period) %>% summarise(
  types_hood = length(which(hood==TRUE)),
  types_all = n(),
  tokens_hood = sum(n[hood == TRUE]),
  tokens_all = sum(n),
  hapaxes_hood = length(which(hood == TRUE & hapax == TRUE)),
  hapaxes_all = length(which(hapax == TRUE)),
  pot_prod = hapaxes_hood / tokens_hood,
  real_prod = types_hood / tokens_all,
  expand_prod = hapaxes_hood / hapaxes_all
)


# plot productivity

(p1 <- ggplot(productivity, aes(x = period, y = pot_prod, group = 1)) +
  geom_point(size=2, col = "blue") + geom_line(lwd = 1.5, col = "grey20") + ylab("Potential Productivity") +
  xlab("Period") + ggtitle(expression(paste(italic("hood"), ", CLMET"))) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) + 
  theme(axis.text = element_text(size = 18)) +
  theme(axis.title = element_text(size = 18)) +
  theme(strip.text = element_text(size = 18)) +
  theme(legend.text = element_text(size = 18)) +
  theme(legend.title = element_text(size = 18, face = "bold")) +
  theme(text = element_text(size = 18)) +
  theme(plot.margin = margin(0,0,18,0)) + ylim(c(0,0.025)) )

(p2 <- ggplot(productivity, aes(x = period, y = real_prod, group = 1)) +
  geom_point(size=2, col = "blue") + geom_line(lwd = 1.5, col = "grey20") + ylab("Realized Productivity") +
  xlab("Period") + ggtitle(expression(paste(italic("hood"), ", CLMET"))) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) + 
  theme(axis.text = element_text(size = 18)) +
  theme(axis.title = element_text(size = 18)) +
  theme(strip.text = element_text(size = 18)) +
  theme(legend.text = element_text(size = 18)) +
  theme(legend.title = element_text(size = 18, face = "bold")) +
  theme(text = element_text(size = 18)) +
    theme(plot.margin = margin(0,5,18,0)) + ylim(c(0,8e-06)))

(p3 <- ggplot(productivity, aes(x = period, y = expand_prod, group = 1)) +
  geom_point(size=2, col = "blue") + geom_line(lwd=1.5, col = "grey20") + ylab("Expanding Productivity") +
  xlab("Period") + ggtitle(expression(paste(italic("hood"), ", CLMET"))) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) + 
  theme(axis.text = element_text(size = 18)) +
  theme(axis.title = element_text(size = 18)) +
  theme(strip.text = element_text(size = 18)) +
  theme(legend.text = element_text(size = 18)) +
  theme(legend.title = element_text(size = 18, face = "bold")) +
  theme(text = element_text(size = 18)) + ylim(c(0,2e-03)) )

(p4 <- ggplot(productivity, aes(x = pot_prod, y = real_prod, group = 1)) +
  geom_point(size=2, col = "blue") + geom_line(lwd=1.5, col = "grey20") + ylab("Realized productivity") +
  xlab("Potential productivity") + ggtitle(expression(paste(italic("hood"), ", CLMET"))) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) + 
  theme(axis.text = element_text(size = 18)) +
  theme(axis.title = element_text(size = 18)) +
  theme(strip.text = element_text(size = 18)) +
  theme(legend.text = element_text(size = 18)) +
  theme(legend.title = element_text(size = 18, face = "bold")) +
  theme(text = element_text(size = 18)) +
  theme(axis.text.x = element_text(angle=45, hjust=.9, size=12)) +
    ylim(c(0, 7.2e-06)))

x <- tibble(a = 1,
            b = 1)

# insets for "numbering" the plots:
p1a <- ggplot(x, aes(x = a, y = b, label = "A")) + geom_text(size = 12) + 
  theme_void() + theme(panel.background = element_rect(fill = "white", color = "white"))
p1b <- ggplot(x, aes(x = a, y = b, label = "B")) + geom_text(size = 12) + 
  theme_void() + theme(panel.background = element_rect(fill = "white", color = "white"))
p1c <- ggplot(x, aes(x = a, y = b, label = "C")) + geom_text(size = 12) + 
  theme_void() + theme(panel.background = element_rect(fill = "white", color = "white"))
p1d <- ggplot(x, aes(x = a, y = b, label = "D")) + geom_text(size = 12) + 
  theme_void() + theme(panel.background = element_rect(fill = "white", color = "white"))


# 2x2 array:
(p2 + inset_element(p1a, left = 0, bottom = 0.9, right = .1, top = 1) | 
    p1 + inset_element(p1b, left = 1, bottom = 0.9, right = 0.9, top = 1) ) /
(p3 + inset_element(p1c, left = 0, bottom = 0.9, right = .1, top = 1) | 
   p4 + inset_element(p1d, left = 1, bottom = 0.9, right = 0.9, top = 1) )

# ggsave("productivities_baayen.png", width = 13, height = 13)


d %>% filter(period == levels(factor(d$period))[1]) %>% 
  select(lemma) %>% unlist %>% unname



# new hood nouns vs new ness nouns ----------------------------------------

# lemmas for each period
lp01 <- filter(d, period == "1710-1780")$lemma %>% unique
lp0102 <- filter(d, period %in% c("1710-1780", "1780-1850"))$lemma %>% unique
lp02 <- filter(d, period == "1780-1850")$lemma %>% unique
lp03 <- filter(d, period == "1850-1920")$lemma %>% unique

# which -hood nouns in previous period
setdiff(grep(".+hood$", lp02, value = T), grep(".+hood$", lp01, value = T))
setdiff(grep(".+ness$", lp02, value = T), grep(".+ness$", lp01, value = T))
setdiff(grep(".+hood$", lp03, value = T), grep(".+hood$", lp0102, value = T))
setdiff(grep(".+ness$", lp03, value = T), grep(".+ness$", lp0102, value = T))


# Zipf-Mandelbrot model ---------------------------------------------------


# frequency spectra - spc files

# period 1
filter(d, period == levels(factor(d$period))[1])$Freq %>% 
  table %>% 
  as_tibble() %>% 
  setNames(c("m", "Vm")) %>% write.table("clmet_hood_period01.spc", row.names=F, quote=F, sep="\t")

# period 2
filter(d, period == levels(factor(d$period))[2])$Freq %>% 
  table %>% 
  as_tibble() %>% 
  setNames(c("m", "Vm")) %>% write.table("clmet_hood_period02.spc", row.names=F, quote=F, sep="\t")

# period 3
filter(d, period == levels(factor(d$period))[3])$Freq %>% 
  table %>% 
  as_tibble() %>% 
  setNames(c("m", "Vm")) %>% write.table("clmet_hood_period03.spc", row.names=F, quote=F, sep="\t")


# read spc files
hood_spc01 <- read.spc("clmet_hood_period01.spc")
hood_spc02 <- read.spc("clmet_hood_period02.spc")
hood_spc03 <- read.spc("clmet_hood_period03.spc")


# Zipf-Mandelbrot model
fzm01 <- lnre("fzm", hood_spc01, m.max=1)
fzm02 <- lnre("fzm", hood_spc02, m.max=1)
fzm03 <- lnre("fzm", hood_spc03, m.max=1)

# lnre.spc
fzm.spc01 <-  lnre.spc(fzm01, N(fzm01))
fzm.spc02 <-  lnre.spc(fzm02, N(fzm02))
fzm.spc03 <-  lnre.spc(fzm03, N(fzm03))


plot(hood_spc01, fzm.spc01, legend = c("observed", "fZM"))
plot(hood_spc02, fzm.spc02, legend = c("observed", "fZM"))
plot(hood_spc03, fzm.spc03, legend = c("observed", "fZM"))

# goodness of fit:
summary(fzm01)
summary(fzm02)
summary(fzm03)

# extrapolated vocbulary growth curves
period01.vgc <- lnre.vgc(fzm01, 1:1e07, m.max = 1)
period02.vgc <- lnre.vgc(fzm02, 1:1e07, m.max = 1)
period03.vgc <- lnre.vgc(fzm03, 1:1e07, m.max = 1)



# get empirical vocabulary growth
p01 <- readLines("clmet_hood_period01.txt")
p01 <- gsub(".*<|>", "", p01)

p02 <- readLines("clmet_hood_period02.txt")
p02 <- gsub(".*<|>", "", p02)

p03 <- readLines("clmet_hood_period03.txt")
p03 <- gsub(".*<|>", "", p03)


# get emp.vgc

emp.vgc <- function(x) {
  seqs <- seq(0, length(x), 100)
  seqs <- seqs[2:length(seqs)]
  
  for(i in 1:length(seqs)) {
    x_tbl <- x[1:seqs[i]] %>% table %>% as_tibble() %>% setNames(c("lemma", "n"))
    
    cur <- tibble(
      N = seqs[i],
      V = nrow(x_tbl),
      V1 = length(which(x_tbl$n==1))
    )
    
    if(i == 1) {
      emp.vgc <- cur
    } else {
      emp.vgc <- rbind(emp.vgc, cur)
    }
    
    
    
    
  }
  
  return(emp.vgc)
  
}


period01.emp.vgc <- emp.vgc(p01)
period02.emp.vgc <- emp.vgc(p02)
period03.emp.vgc <- emp.vgc(p03)



# plot growth curves ------------------------------------------------------



# empirical vocabulary growth for -hood
plot(period01.emp.vgc$N, period01.emp.vgc$V1, type = "l", 
     lty = 1, lwd = 2, ylim = c(0, 10000), xlim = c(0, 100000))

lines(period01.vgc$N, period01.vgc$V1 / period01.vgc$N, type = "l", lty = 2, 
       lwd = 2)

# plot vocabulary growth curve
 png("growthcurves_bw.png", width = 13, height = 5, un = "in", res = 300)
 par(mfrow = c(1,2))

# png("vocgrowthcurve_bw.png", width = 6.5, height = 5, un = "in", res = 300)
plot(period01.vgc$N, period01.vgc$V, type="l", lty = 1, col="grey10",
     lwd=2, main="Vocabulary Growth Curve",
     ylab="Extrapolated number of types", xlab="N", ylim = c(0,2e05))
points(period01.emp.vgc$N, period01.emp.vgc$V1, pch=10, col="grey10",
       cex=0.5)
lines(period02.vgc$N, period02.vgc$V, type="l", col="grey50", lty=2)
points(period02.emp.vgc$N, period02.emp.vgc$V1, pch=10, col="grey50", cex=0.5)
lines(period03.vgc$N, period03.vgc$V, type="l", col="grey80", lty=3)
points(period03.emp.vgc$N, period03.emp.vgc$V1, pch=10, col="grey80", cex=0.5)
legend("topleft", 
       inset=c(0.01,0.01), 
       lty=c(1,2,3), 
       col=c("grey10", "grey50", "grey80"), 
       legend=c(levels(factor(d$period))[1],
                levels(factor(d$period))[2],
                levels(factor(d$period))[3]), cex=0.6)
# dev.off()


# hapax growth curve
#png("growthcurve.png", width = 6.5, height = 5, un = "in", res = 300)
plot(period01.vgc$N, period01.vgc$V1, type="l", col="grey10", 
     lwd=2, main="Hapax Growth Curve",
     ylab="Extrapolated number of hapaxes", xlab="N")
lines(period02.vgc$N, period02.vgc$V1, type="l", col="grey50", lty=2)
lines(period03.vgc$N, period03.vgc$V1, type="l", col="grey80", lty=3)

legend("topleft", 
       inset=c(0.01,0.01), 
       lty=c(1,2,3), 
       col=c("grey10", "grey50", "grey80"), 
       legend=c(levels(factor(d$period))[1],
                levels(factor(d$period))[2],
                levels(factor(d$period))[3]), cex=0.6)

dev.off()
par(mfrow = c(1,1))




# Bootstrapping type growth à la Säily ------------------------------------


# CQP query: 
# cwb-scan-corpus CLMET lemma text_file text_period >  "clmet_lemma_id_period.txt"

# read data
d <- read_delim("clmet_lemma_id_period.txt", delim = "\t",
                quote = "", col_names = c("Freq", "Lemma", "text", "Period"))


# find -hood types
d$hood <- grepl(".+hood$", d$Lemma)


# set seed to make results reproducible
set.seed(1985)

# container for results
container <- list()

# steps of 1000
seqs <- seq(0, nrow(d), 10000)

for(i in 1:5000) {
  # randomly shuffle texts
  d$text <- factor(d$text, levels = sample(unique(d$text), length(unique(d$text))))
  d <- d %>% arrange(text)
  
  
  # add duplicate column so that only first instances
  # (types) are considered
  d$duplicated <- duplicated(d$Lemma)
  
  # add column with counter
  d$counter <- NA
  d[which(d$duplicated == FALSE & d$hood == TRUE),]$counter <- 1:nrow(d[which(d$duplicated == FALSE & d$hood == TRUE),])
  d <- fill(d, counter) # fill downwards
  container[[i]] <- d[seqs,]$counter
  
  # # add duplicate column so that only first instances
  # # (types) are considered
  # d$duplicated <- duplicated(d$Lemma)
  # 
  # 
  # 
  # # add index, then only keep -hood instances
  # d$index <- 1:nrow(d)
  # d1 <- filter(d, hood == TRUE & duplicated == FALSE)
  # 
  # # for each step, get number of types
  # container[[i]] <- sapply(1:length(seqs), function(j) nrow(d1[which(d1$index<seqs[j]),]))
  # 
  print(i)
}

# and now the same but for individual time slices

# container for results
container1 <- list()
container2 <- list()
container3 <- list()

# new seqs based on the smallest time period
seqs <- seq(0, 468975, 10000)

# set seed
set.seed(1985)

for(i in 1:5000) {
  # randomly shuffle texts
  d$text <- factor(d$text, levels = sample(unique(d$text), length(unique(d$text))))
  d <- d %>% arrange(text)
  
  d1 <- filter(d, Period == "1710-1780")
  d2 <- filter(d, Period == "1780-1850")
  d3 <- filter(d, Period == "1850-1920")
  
  # add duplicate column so that only first instances
  # (types) are considered
  d1$duplicated <- duplicated(d1$Lemma)
  d2$duplicated <- duplicated(d2$Lemma)
  d3$duplicated <- duplicated(d3$Lemma)
  
  # add column with counter
  d1$counter <- NA
  d1[which(d1$duplicated == FALSE & d1$hood == TRUE),]$counter <- 1:nrow(d1[which(d1$duplicated == FALSE & d1$hood == TRUE),])
  d1 <- fill(d1, counter) # fill downwards
  container1[[i]] <- d1[seqs,]$counter
  
  d2$counter <- NA
  d2[which(d2$duplicated == FALSE & d2$hood == TRUE),]$counter <- 1:nrow(d2[which(d2$duplicated == FALSE & d2$hood == TRUE),])
  d2 <- fill(d2, counter) # fill downwards
  container2[[i]] <- d2[seqs,]$counter
  
  d3$counter <- NA
  d3[which(d3$duplicated == FALSE & d3$hood == TRUE),]$counter <- 1:nrow(d3[which(d3$duplicated == FALSE & d3$hood == TRUE),])
  d3 <- fill(d3, counter) # fill downwards
  container3[[i]] <- d3[seqs,]$counter
  
  # # add duplicate column so that only first instances
  # # (types) are considered
  # d$duplicated <- duplicated(d$Lemma)
  # 
  # 
  # 
  # # add index, then only keep -hood instances
  # d$index <- 1:nrow(d)
  # d1 <- filter(d, hood == TRUE & duplicated == FALSE)
  # 
  # # for each step, get number of types
  # container[[i]] <- sapply(1:length(seqs), function(j) nrow(d1[which(d1$index<seqs[j]),]))
  # 
  print(i)
}



# export bootstrapping results
# write_rds(d1, "d1.Rds")
# write_rds(d2, "d2.Rds")
# write_rds(d3, "d3.Rds")

write_rds(container1, "container1.Rds")
write_rds(container2, "container2.Rds")
write_rds(container3, "container3.Rds")


png("säily_triptychon.png", width = 15, height = 5, un = "in", res = 300)
par(mfrow = c(1,3))
plot(seqs[1:length(container[[1]])], container[[1]], type = "n", 
     ylab = "Types", xlab = "Running words", xlim = c(0,4e05))
sapply(1:length(container1), function(i) 
  lines(seqs[1:length(container1[[1]])], 
        container1[[i]], 
        col = rgb(red = 0, blue = 1, green = 0, alpha = .009)))
lines(seqs[1:length(container1[[1]])], 
      sapply(1:length(container1[[1]]), 
             function(j) mean(sapply(1:length(container1), 
                                     function(i) container1[[i]][j]))),
      col = "blue", lwd = 2)
title(levels(factor(d$Period))[1])

plot(seqs[1:length(container[[1]])], container[[1]], type = "n", 
     ylab = "Types", xlab = "Running words", xlim = c(0,4e05))
sapply(1:length(container2), function(i) 
  lines(seqs[1:length(container2[[1]])], container2[[i]], col = rgb(red = 1, blue = 0, green = 0, alpha = .009)))
lines(seqs[1:length(container2[[1]])], 
      sapply(1:length(container2[[1]]), 
             function(j) mean(sapply(1:length(container2), 
                                     function(i) container2[[i]][j]))),
      col = "red", lwd = 2)
title(levels(factor(d$Period))[2])

plot(seqs[1:length(container[[1]])], container[[1]], type = "n", 
     ylab = "Types", xlab = "Running words", xlim = c(0,4e05))
sapply(1:length(container3), function(i) 
  lines(seqs[1:length(container3[[1]])], container3[[i]], col = rgb(red = 0, blue = 0, green = 1, alpha = .009)))
lines(seqs[1:length(container3[[1]])], 
      sapply(1:length(container3[[1]]), 
             function(j) mean(sapply(1:length(container3), 
                                     function(i) container3[[i]][j]))),
      col = "darkgreen", lwd = 3)
title(levels(factor(d$Period))[3])
# legend("topleft", 
#        inset=c(0.01,0.01), 
#        col=c("blue", "red", "green"), lty = 1, lwd = 2,
#        legend=c(levels(factor(d$Period))[1],
#                 levels(factor(d$Period))[2],
#                 levels(factor(d$Period))[3]), cex=0.6)

dev.off()
par(mfrow = c(1,1))

# randomly shuffle texts
text_ids <- unique(d$text)
d$text <- factor(d$text, levels = sample(text_ids, length(text_ids)))
d <- d %>% arrange(text)

# add duplicate column so that only first instances
# (types) are considered
d$duplicated <- duplicated(d$Lemma)

# find new -hood types
d$hood <- grepl(".+hood$", d$Lemma)

# steps of 1000
seqs <- seq(0, nrow(d), 1000)

# add index, then only keep -hood instances
d$index <- 1:nrow(d)
d1 <- filter(d, hood == TRUE & duplicated == FALSE)

# for each step, get number of types
sapply(1:length(seqs), function(i) nrow(d1[which(d1$index<seqs[i]),]))




# Yang's productivity measure ---------------------------------------------


