# load libraries
rm(list=ls())
library(data.table)
library(dplyr)
library(arm)
library(pROC)
library(e1071)
library(caret)
library(car)

### FUNCTIONS ###
mevaluation = function(model, target){
  roc(target,fitted(model),plot=T,print.thres="best",legacy.axes=T,
      print.auc =T,col="red3")
  
  Conf_mat <- confusionMatrix(as.factor(ifelse(fitted(model) >= mean(target), "1","0")),
                              as.factor(target),positive = "1")
  
  print(Conf_mat$overall["Accuracy"])
  print(Conf_mat$byClass[c("Sensitivity","Specificity")])
  
}

### DATA PREP ###
df = read.csv('processed_data/KSData_191205.csv')
df = as.data.table(df)

og_df = df # keep original version

# df = og_df
df = sample_frac(og_df, .2)

df$ttl_weeks = round(df$ttl_days/7)
df$ttld_c = df$ttl_days - mean(df$ttl_days)
df$response = (as.numeric(df$state)-1)
df$goal_c = df$usd_goal - mean(df$usd_goal)
df$bk_c = round(df$backers_count - mean(df$backers_count))

df = subset(df, select=-c(location_id, state_changed_at, country, 
                             backers_count, usd_pledged, deadline,
                             launched_at))
df = df[complete.cases(df),]

# model = glm(formula = response ~ goal_c + ttld_c + goal_c:ttld_c +
#               main_category + 
#               name_uniqueness + blurb_uniqueness +
#               previously_successful +  previously_failed +
#               country_group + staff_pick +
#               as.factor(launch_year) + launch_month + as.factor(launch_day) + launch_wday,
#             family = binomial, data = df)


model = glm(formula = response ~ goal_c + ttld_c + goal_c:ttld_c +
              main_category + staff_pick + 
              previously_successful + previously_failed +
              as.factor(launch_year) +
              name_uniqueness + blurb_uniqueness, 
            family = binomial, data = df)

binnedplot(x=fitted(model),y=residuals(model,"resp"),xlab="Pred. probabilities",
           col.int="red4",ylab="Avg. residuals",main="Binned residual plot",col.pts="navy")

binnedplot(x=df$ttl_weeks,y=residuals(model,"resp"),xlab="predictor",
           col.int="red4",ylab="Avg. residuals",main="Binned residual plot",col.pts="navy")

summary(model)
vif(model)
mevaluation(model, df$response)
upper_lim = as.formula("response ~ goal_c + ttld_c + goal_c:ttld_c +
              main_category + 
              name_uniqueness + blurb_uniqueness +
              previously_successful +  previously_failed +
              country_group + staff_pick +
              as.factor(launch_year) + launch_month + as.factor(launch_day) + launch_wday")

stepped_model = step(glm(response~1,data=df,family=binomial),scope=upper_lim,direction="both")
summary(stepped_model)
vif(stepped_model)

mevaluation(stepped_model, df$response)
library(sjPlot)
library(sjlabelled)
library(sjmisc)

jtools::plot_coefs(stepped_model)
knitr::kable(summary(model))
tab_model(model, sort.est = TRUE)

summary(df$sub_category)
