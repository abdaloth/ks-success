# ks-success

Kickstarter is one of the famous crowdfunding online-platforms that connects project 
creators with potential customers that may be interested in the project. 
Project creators would set a funding goal of the amount of money the project would need to become a reality and a deadline to reach that goal. 
“Backers” would then pledge money towards that project to help fund it. 
Kickstarter operates on an “all-or-nothing” funding philosophy: if the funding goal is not met before the deadline, the backers are not charged, the project 
creator does not receive any of the funding and the project fails.

This study explores the possible factors that lead to a project’s chances of success and attempts to quantify their effects.

## Data and Preprocessing
 
The data used in this paper has been collected through Kickstarter’s own web API by webrobots.io [2].
After obtaining the original data, additional preprocessing and filtering of the records is required. 
The data records include inner JSON objects with information that is not relevant to the research questions, such as webpage properties, photo dimensions, and related URLs.
The data also has duplicated records of the same project scraped at different times. 
We created a script that keeps only the latest record of each project, and extracts the relevant fields from the JSON record.

Kickstarter has no public documented API and therefore there is no official data dictionary. 
Some of the columns are named sufficiently and others have been identified through 3rd parties [3]. 
Because the API changed across the years , with features being added or removed, we only kept the columns that were shared across all records. 
Except for the case of the `staff_pick` column (a true or false value that determines whether a project has the "projects we love" badge) since there was no official badge on projects that were launched before 2016, we filled the missing values for old projects with `False`.

Since Kickstarter is an open platform, we needed a way to filter outlier projects. An outlier project is a project that meets either of the following conditions:

- A funding goal less than $50, this goal does not warrant a fundraising campaign.

- A funding goal greater than $100,000 with less than 10 backers. We believe these creators were not seriously attempting to fund their projects, since securing less than 10 backers portrays a lackluster marketing effort for such an ambitious funding goal.

Filtering the outliers removes less than 2% of the data, with the final processed data containing 303858 unique projects. All the monetary amounts were converted to USD for consistency and all continous variables have been mean centred.


## Feature Engineering
The timing of when a project's fundraising campaign starts could be an important factor in whether or not a somone chooses to "back" the project. 
Using the Unix time of the project's launch and deadline that was provided in the original dataset, additional datetime features were created. 
The year, month, day, weekday of the launch, and The number of days between the launch date and the deadline were all considered as potential predictors.

A creator's record could be important to a prospective "Backer", so a boolean value of whether a project creator has had a previously successful/failed project in their history was added as a predictor.
Given the belief in the importance of a project's name, I created a metric to calculate its uniqueness respective to others in its category. 
This was done by using word embeddings. 
Word embeddings are a way of representing words in vector-space where words that are semanticaly similar appear closer to each other. 
The cosine distance between each project's name vector and the average category vector gives us our value.


## Model

To answer the main research question of what factors affect a project's chances of success, we set that as the model's response variable. All the base predictors were included with the addition of the engineered features and interactions such as the interaction between the funding goal and the campaign length. Stepwise AIC is then preformed to optimize that selection. The final selected model's formula is:

![Model Formula](https://media.discordapp.net/attachments/666704012904628226/759537408294387732/unknown.png)

The model has an AUC of 0.8, an Accuracy of 72% and a Sensitivity of 68%

Checking the VIF of the model shows that there is no collinearity between our predictors. However, inspecting the binned diagnostic plots (Available in the Appendix) we see some anomalies. The residuals are highest around lower probabilities and seem to follow a slight sinusoidal shape. No amount of transformation or binning has fixed. We will proceed to the inference with caution.



## Results & Conclusion

From the final model, we can say with reasonable confidence that compared to the baseline 
(an Art project based in Asia by a first-time creator with an average funding goal of $12450, 
an average name within its categoray, a ttl of 33 days that launched on a Friday on April 2009).

- A creator that has successfully funded a project is 6.4 times more likely to successfully fund subsequent projects
- A creator that has previously failed at funding a project is 53% less likely to successfully fund subsequent projects
- Projects based in Europe are 44% less likely to succeed
- Staff pick increases the odds ratio by a factor of 9.6
- the categories most likely to succeed are Design (6.37), Theater (3.86) then Comics (53% more likely)
- projects that have names which are semantically different than projects in their category are less likely to succeed ( 8% less likely per .1 cosine distance)
- March projects are 7% more likely to succeed and July projects are 20% less likely to succeed
- Projects launched on a Tuesday are 20% more likely to succeed
- Launching a project on the first day of the month is at least 13% more likely to succeed than a similar project that launches on any other day
- The likelihood of a project's success decreases by 2% for every additional day they add to the average fundraising campaign length (33 days).
- The likelihood of a project's success decreases by (2e-5)% for every additional dollar they add to the average funding goal ($12450).


it should be noted that this model has some limitations, The binned residual plot has some abnormalities as mentioned previously. 
The data is also missing some highly relevant information that would be useful for future work, such as the reward tiers of the project, 
the promotional video attached to the project and the popularity of creator prior to their project.
