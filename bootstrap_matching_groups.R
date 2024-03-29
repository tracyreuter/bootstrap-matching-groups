rm(list=ls(all=T))
setwd("~/Dropbox/Portfolio/bootstrap_matching_groups")
# install.packages("devtools")
# devtools::install_github("tjmahr/bootmatch")
library(readxl)
library(dplyr)
library(bootmatch)
library(data.table)
library(kableExtra)
library(knitr)
sublog <- readxl::read_xlsx("subjectlog.xlsx")
sublog <- dplyr::select(sublog, subject, group, sex, age, PLS.AC.Raw, PLS.AC.AE, PLS.EC.Raw, PLS.EC.AE, Mul.VR.Raw, Mul.VR.AE, Mul.Ratio.IQ)
sublog <- sublog %>% mutate_at(c(4:11), as.numeric)
foo <- dplyr::select(sublog, group, subject, PLS.AC.Raw)
boo <- boot_match_univariate(data = foo, y = group, x = PLS.AC.Raw, id = subject, caliper = 5, boot = 100)
sublog <- sublog %>% filter(subject %in% unique(boo$Matching_MatchID))
x <- colnames(sublog[4:11])
# compare clinical assessment measures across matched groups
compare.measures <- function(x) {
  desc <- data.frame(1:length(x))
  desc$X1.length.x. <- unique(x)
  colnames(desc)[1:1] <- c('Score')
  for (i in 1:length(x)) {
    test.scores <- dplyr::select(sublog, group, x[i])
    test.scores <- na.omit(test.scores)
    ASD.scores <- data.table(test.scores[test.scores$group=="ASD",])
    TD.scores <- data.table(test.scores[test.scores$group=="TD",])
    desc$ASD.n[i] <- c(nrow(ASD.scores))
    desc$ASD.mean[i] <- c(round(mean(ASD.scores[[2]])),2)
    desc$ASD.sd[i] <- c(round(sd(ASD.scores[[2]])),2)
    desc$ASD.min[i] <- c(round(min(ASD.scores[[2]])),2)
    desc$ASD.max[i] <- c(round(max(ASD.scores[[2]])),2)
    desc$TD.n[i] <- c(nrow(TD.scores))
    desc$TD.mean[i] <- c(round(mean(TD.scores[[2]])),2)
    desc$TD.sd[i] <- c(round(sd(TD.scores[[2]])),2)
    desc$TD.min[i] <- c(round(min(TD.scores[[2]])),2)
    desc$TD.max[i] <- c(round(max(TD.scores[[2]])),2)
    # calculate effect size (cohen's d)
    d <- effsize::cohen.d(ASD.scores[[2]],TD.scores[[2]],paired=F)
    desc$d[i] <- abs(round(d$estimate, digits=2))
    # calculate variance ratio
    desc$v[i] <- round(var(ASD.scores[[2]])/var(TD.scores[[2]]), digits=2)
    test1 <- try(shapiro.test(as.numeric(ASD.scores[[2]])), silent=T)
    test2 <- try(shapiro.test(as.numeric(TD.scores[[2]])), silent=T)
    # if either distribution is non-normal, use a wilcox test, else use a t-test
    if(test1$p.value<0.05 | test2$p.value<0.05) {
      test <- try(wilcox.test(ASD.scores[[2]], TD.scores[[2]], paired=F), silent=T)
      desc$p[i] <- ifelse(is(test,"try-error"),NA, round(as.numeric(test$p.value),3))
    } else {
      test <- try(t.test(ASD.scores[[2]], TD.scores[[2]], paired=F), silent=T)
      desc$p[i] <- ifelse(is(test,"try-error"),NA, round(as.numeric(test$p.value),3))
    }
  }
  desc <- na.omit(desc)
  row.names(desc) <- NULL
  desc$p <- ifelse(desc$p<0.001, "< 0.001", desc$p)
  colnames(desc)[1:14] <- c("Measure","N","Mean","SD","Min","Max","N","Mean","SD","Min","Max","Cohen's d","Var Ratio","p-value")
  kable(desc, format = "latex", booktabs = T) %>%
    add_header_above(c(" " = 1, "ASD Group" = 5, "NT Group" = 5, "Group Differences" = 3))
}
compare.measures(x)