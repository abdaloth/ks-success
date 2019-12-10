# load libraries
rm(list=ls())
library(ggplot2)
library(gridExtra)
library(data.table)
library(dplyr)

df = read.csv('processed_data/KSData.csv')

grouped_bars = function(data, groups, labels, flip=T) {
  
  gdf = df[, .(count = .N), groups]
  gdf = gdf %>% group_by(get(groups[1])) %>% mutate(percent = count/sum(count))
  
  p = ggplot(gdf)+
    geom_bar(aes(x=get(groups[2]), 
                 fill=get(groups[2]), 
                 y=percent*100), 
             stat='identity', 
             width=.2)+
    facet_grid(~get(groups[1]))+
    geom_text(data = gdf, 
              aes(x=get(groups[2]), 
                  y=percent*100, 
                  label=scales::percent(round(percent, 4))), 
              vjust=-.3)+
    theme(
      axis.text.x = element_blank(),
      legend.position = "None",
      axis.title.x = element_text(size = 10),
      axis.title.y = element_text(size = 10)
    )+
    xlab(labels[1])+
    ylab(labels[2])
  if(flip){
    p = p + coord_flip()}
  
  return(p)
}

percentage_bars = function(data, group, labels, flip=T) {
  
  gdf = df[, .(count = .N), group]
  gdf = gdf %>% group_by(get(group)) %>% mutate(percent = count/sum(gdf$count))
  
  p = ggplot(gdf)+
    geom_bar(aes(x=get(group), 
                 fill=get(group), 
                 y=percent*100), 
             stat='identity', 
             width=.2)+
    geom_text(data = gdf, 
              aes(x=get(group), 
                  y=percent*100, 
                  label=scales::percent(round(percent, 4))), 
              hjust=-.3)+
    theme(
      axis.text.x = element_blank(),
      legend.position = "None",
      axis.title.x = element_text(size = 10),
      axis.title.y = element_text(size = 10)
    )+
    xlab(labels[1])+
    ylab(labels[2])
  if(flip){
    p = p + coord_flip()}
  
  return(p)
}

grouped_bars(df, c('main_category', 'state'), c('Primary Categories', 'Percentage of Success Rates'), F)
grouped_bars(df, c('country_group', 'state'), c('Country Groups', 'Percentage of Success Rates'), F)

# grouped_bars(df, c('binned_goal', 'state'), c('Primary Categories', 'Category Percentage per Country'), F)

percentage_bars(df,'main_category', c('Primary Categories', 'Percentage of Projects per Category'), T)
percentage_bars(df,'country_group', c('Country Group', 'Percentage of Projects per Group'), T)
percentage_bars(df,'staff_pick', c('Primary Categories', 'Percentage of Projects per Country'), T)

ggplot(df)+
  geom_bar(aes(x=country_group, y = (..count..)/sum(..count..)*100, fill=country_group), width=.3)+
  theme(
    legend.position = "None",
    axis.title.x = element_text(size = 20),
    axis.title.y = element_text(size = 20)
  )+
  xlab('Country')+
  ylab("Percentage of Projects per Country")


ggplot(df)+
  geom_bar(aes(x=main_category, y = (..count..)/sum(..count..)*100, fill=main_category), width=.2)+
  theme(
    legend.position = "None",
    axis.title.x = element_text(size = 10),
    axis.title.y = element_text(size = 10)
  )+
  xlab('Primary Categories')+
  ylab("Percentage of Projects per Category")+
  coord_flip()

ggplot(df)+
  geom_boxplot(aes(x=state, y=ttl_days, fill=state))


