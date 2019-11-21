import pandas as pd
from tqdm import tqdm
from glob import glob

path_list = glob('filtered_data/*.csv')
data_list = []

for p in tqdm(path_list):
    tmp = pd.read_csv(p, low_memory=False)
    tmp['src'] = p.split('\\')[-1][:-4] # keep track of the source file of each record
    data_list.append(tmp)

df = pd.concat(data_list, ignore_index=True, sort=False)
del data_list

df = df[df.state != 'live'].copy() # we will not consider live projects

# sort to keep most recent update of the same project on top
df = df.sort_values(by=['id', 'state_changed_at', 'src'], ascending=False)
# drop older duplicated records
df = df.drop_duplicates(subset=['project_id'], keep='first')


df['staff_pick'].fillna(False, inplace=True) # 2015 did not have official staff pick badge

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

# consider all non success as failure
df['state'] = df['state'].apply(lambda s: s if s=='successful' else 'failed')

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
df.to_csv('processed_data/KSData.csv', index=False)
