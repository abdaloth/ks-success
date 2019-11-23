# load libraries
rm(list=ls())
library(ggplot2)
library(gridExtra)
library(data.table)
library(dplyr)
library(anytime)
library(corrplot)


### DATA PREP ###
df = read.csv('processed_data/KSData.csv')
df = as.data.table(df)

og_df = df # keep original version

# group countries
df$country_group = as.character(df$country)
df$country_group[df$country%in% c('AT', 'BE', 'CH', 'DE', 
                                  'ES', 'DK', 'FR', 'IE', 
                                  'IT', 'LU', 'NL', 'NO', 'SE')] = 'Europe'

df$country_group[df$country%in% c('US', 'CA', 'MX')] = 'North_America'
df$country_group[df$country%in% c('AU', 'NZ')] = 'Oceania'
df$country_group[df$country%in% c('HK', 'SG', 'JP')] = 'Asia'
df$country_group = as.factor(df$country_group)

df$avg_pledge = df$usd_pledged/(df$backers_count+1)
df$ttl_days = (df$deadline - df$launched_at)/86400

df$launched_at = anydate(df$launched_at)

df$launch_year = as.POSIXlt(df$launched_at)$year + 1900
df$launch_month = as.POSIXlt(df$launched_at)$mon + 1
df$launch_day = as.POSIXlt(df$launched_at)$mday
df$launch_wday = as.POSIXlt(df$launched_at)$wday

df = subset(df, selection=-c('location_id', 'state_changed_at', 'country', 
                             'backers_count', 'usd_pledged', 'deadline',
                             'launched_at'))



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

grouped_bars(df, c('country_group', 'main_category'), c('Primary Categories', 'Category Percentage per Country'))
grouped_bars(df, c('main_category', 'state'), c('Primary Categories', 'Category Percentage per Country'), F)
grouped_bars(df, c('country_group', 'state'), c('Primary Categories', 'Category Percentage per Country'), F)
grouped_bars(df, c('launch_wday', 'state'), c('Primary Categories', 'Category Percentage per Country'), F)

ggplot(df)+
  geom_bar(aes(x=country_group, y = (..count..)/sum(..count..)*100, fill=country_group), width=.2)+
  theme(
    legend.position = "None",
    axis.title.x = element_text(size = 10),
    axis.title.y = element_text(size = 10)
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
  ylab("Percentage of Projects per Category")

ggplot(df)+
  geom_bar(aes(x=as.factor(launch_year), y = (..count..)), width=.2)+
  theme(
    legend.position = "None",
    axis.title.x = element_text(size = 10),
    axis.title.y = element_text(size = 10)
  )+
  xlab('Primary Categories')+
  ylab("Percentage of Projects per Category")

ggplot(df)+
  geom_density(aes(x=(usd_goal)^(1/2), fill=state), alpha=.3)
