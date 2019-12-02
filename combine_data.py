import pandas as pd
import numpy as np
from tqdm import tqdm
from glob import glob
from datetime import datetime

path_list = glob('filtered_data/*.csv')
data_list = []

for p in tqdm(path_list):
    tmp = pd.read_csv(p, low_memory=False)
    # keep track of the source file of each record
    tmp['src'] = p.split('\\')[-1][:-4]
    data_list.append(tmp)

df = pd.concat(data_list, ignore_index=True, sort=False)
del data_list

df = df[df.state != 'live'].copy()  # we will not consider live projects

# sort to keep most recent update of the same project on top
df = df.sort_values(by=['id', 'state_changed_at', 'src'], ascending=False)
# drop older duplicated records
df = df.drop_duplicates(subset=['project_id'], keep='first')


# 2015 did not have official staff pick badge
df['staff_pick'].fillna(False, inplace=True)

nan_limit = 0.05 * len(df)

bad_cols = [col for col in df.columns if df[col].isna().sum() > nan_limit]

print('columns with too many missing values:')
for c in bad_cols:
    print(c)

df = df.drop(columns=bad_cols)

# unify currency
df['usd_goal'] = df['goal'] * df['static_usd_rate']

# identify categories
df['main_category'] = df['category_slug'].apply(lambda c: c.split('/')[0])
df['sub_category'] = df['category_slug'].apply(lambda c: c.split('/')[-1])

# group country variable
euro_set = set(['AT', 'BE', 'CH', 'DE',
               'ES', 'DK', 'FR', 'IE',
               'IT', 'LU', 'NL', 'NO', 'SE'])

north_america_set = set(['US', 'CA', 'MX'])
oceania_set = set(['AU', 'NZ'])
asia_set = set(['HK', 'SG', 'JP'])

df['country_group'] = df['country'].apply(lambda c: 'Europe' if c in euro_set 
                                                    else 'North_America' if c in north_america_set
                                                    else 'Oceania' if c in oceania_set
                                                    else 'Asia' if c in asia_set
                                                    else c) # GB is already grouped

# datetime variables
df['ttl_days'] = round((df['deadline'] - df['launched_at'])/86400)
df['launch_year'] = df['launched_at'].apply(lambda t: datetime.fromtimestamp(t).strftime('%Y'))
df['launch_month'] = df['launched_at'].apply(lambda t: datetime.fromtimestamp(t).strftime('%B'))
df['launch_day'] = df['launched_at'].apply(lambda t: datetime.fromtimestamp(t).strftime('%d'))
df['launch_wday'] = df['launched_at'].apply(lambda t: datetime.fromtimestamp(t).strftime('%a'))

# consider all non success as failure
df['state'] = df['state'].apply(lambda s: s if s == 'successful' else 'failed')

# creator variables
def creator_history(record, state, hist):
    # if no previous project exists, return placeholder
    creator_hist = hist.get((record['creator_id'], state), 
                            {'launched_at':np.inf})
    # if this is the earliest project, the creator has no history                        
    if(record['launched_at']>creator_hist['launched_at']):
        return 1
    return 0

creator_group = df[['creator_id','state', 'launched_at']]\
                    .groupby(['creator_id', 'state']).min()
creator_dict = creator_group.to_dict('index')

tqdm.pandas()
# whether the creator has launched a previously successful project
df['previously_successful'] = df.progress_apply(creator_history, 
                                                axis=1, 
                                                args=('successful', creator_dict))

# whether the creator has launched a previously failed project
df['previously_failed'] = df.progress_apply(creator_history, 
                                            axis=1, 
                                            args=('failed', creator_dict))

# do not contain useful information
redundant_cols = ['id',
                  'currency',
                  'currency_symbol',
                  'currency_trailing_code',
                  'disable_communication',
                  'spotlight',
                  'pledged',
                  'goal',
                  'static_usd_rate',
                  'profile_state',
                  'category_id',
                  'category_slug',
                  'profile_id']


df = df.drop(columns=redundant_cols)
df.to_csv('processed_data/KSData_1912901.csv', index=False)
