#Tern plot script
path <- "yourpath"
setwd(path)

libs <- c("tidyverse", "ggtern") 
lapply(libs, require, character.only=T)
#Documentation: http://www.ggtern.com/

#read in data
dat <- read_csv("brexit_profiles.csv")

#write function to determine which is max prediction
brexit.pref <- function(x) { 
  pref <- apply(X = x[, 12:14], 1, function(x) which.max(x)) 
  x <- colnames(x)[11+pref] %>% gsub("pred_", "", .) }
dat$pred_choice <- brexit.pref(dat)

#Plot data
dat %>% 
  ggtern(data=., aes(pred_no_deal, pred_deal, pred_remain)) + 
  geom_point(aes(colour=pred_choice, alpha=.01)) + 
  ggtitle("Hypothetical Brexit choices based on modelled population") + 
  theme(legend.position = "top") +
  theme_rotate(degrees = 180) -> tern.plot
print(tern.plot)
ggsave(last_plot(), file="tern.plot.png")

