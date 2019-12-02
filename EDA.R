# load libraries
rm(list=ls())
library(ggplot2)
library(gridExtra)
library(data.table)
library(dplyr)
library(anytime)
library(corrplot)
library(arm)
library(pROC)
library(e1071)
library(caret)


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



df$ttl_days = round((df$deadline - df$launched_at)/86400)

df$launched_at = anydate(df$launched_at)

df$launch_year = as.factor(as.POSIXlt(df$launched_at)$year + 1900)
df$launch_month = as.factor(as.POSIXlt(df$launched_at)$mon + 1)
df$launch_day = as.factor(as.POSIXlt(df$launched_at)$mday)
df$launch_wday = as.factor(as.POSIXlt(df$launched_at)$wday)

df$binned_goal = rep(0, nrow(df))

df$binned_goal[df$usd_goal> 1700] = 1
df$binned_goal[df$usd_goal> 5000] = 2
df$binned_goal[df$usd_goal> 14500] = 3
df$binned_goal = as.factor(df$binned_goal)
levels(df$binned_goal) = c('less Than $1700', 'between $1700 and $5000', 
                           'between $5000 and $14500', 'over $14500')

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
# grouped_bars(df, c('staff_pick', 'state'), c('Primary Categories', 'Category Percentage per Country'), F)
# grouped_bars(df, c('main_category', 'staff_pick'), c('Primary Categories', 'Category Percentage per Country'), F)

grouped_bars(df, c('binned_goal', 'state'), c('Primary Categories', 'Category Percentage per Country'), F)

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


df$response = (as.numeric(df$state)-1)
df$goal_c = df$usd_goal - mean(df$usd_goal)
df$bk_c = df$backers_count - mean(df$backers_count)
df$ttld_c = df$ttl_days - mean(df$ttl_days)

model = glm(formula = response ~ binned_goal + ttl_days +
              main_category + country_group + staff_pick +
              launch_year + launch_month + launch_wday,
            family = binomial, data = df)

summary(model)
binnedplot(x=fitted(model),y=residuals(model,"resp"),xlab="Pred. probabilities",
           col.int="red4",ylab="Avg. residuals",main="Binned residual plot",col.pts="navy")

binnedplot(x=df$ttld_c,y=residuals(model,"resp"),xlab="Pred. probabilities",
           col.int="red4",ylab="Avg. residuals",main="Binned residual plot",col.pts="navy")

# step(glm(response~1,data=df,family=binomial),scope=formula(model),direction="both")
roc(df$response,fitted(model),plot=T,print.thres="best",legacy.axes=T,
    print.auc =T,col="red3")

Conf_mat <- confusionMatrix(as.factor(ifelse(fitted(model) >= 0.502, "1","0")),
                            as.factor(df$response),positive = "1")
Conf_mat$table
Conf_mat$overall["Accuracy"];
Conf_mat$byClass[c("Sensitivity","Specificity")]

library(sjPlot)
library(sjlabelled)
library(sjmisc)

jtools::summ(model, exp = F)
knitr::kable(summary(model))
tab_model(model, sort.est = TRUE)
