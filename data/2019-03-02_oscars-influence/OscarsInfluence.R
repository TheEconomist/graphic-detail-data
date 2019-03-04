library(ggplot2)
library(data.table)

setwd("/Users/imac/Documents/Oscars2019/R/")

moviecounts  <- fread('movie-counts.csv', header = T, stringsAsFactors = F)

ggplot(moviecounts[year_rank <=100]) + 
  xlim(2016,1927)+
  scale_fill_manual(values = c("#ffffff", "#afd0df", "#f6a100"))+
  geom_col(aes(fill=result, y=annual_share, x=oscars_year,group = count), colour="#eeeeee")+
  coord_flip()+
  theme_minimal()
