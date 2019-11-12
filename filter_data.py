from glob import glob
import gzip

import pandas as pd
import numpy as np
from tqdm import tqdm
tqdm.pandas()

gzip_list = glob('original_data/*.gz')

def preprocess(json_df, fname):
    df_list = []

    t = pd.DataFrame.from_records(json_df['data'])

    for feature in ['creator', 'profile', 'category', 'location']:
        if not feature in t.columns:
            t[feature] = {}
            pass
        pass
    
    t = t.applymap(lambda x: {} if pd.isnull(x) else x)

    t['creator_id'] = t['creator'].apply(lambda c: c.get('id', None))
    t['creator_name'] = t['creator'].apply(lambda c: c.get('name', None))
    
    t['profile_id'] = t['profile'].apply(lambda c: c.get('id', None))
    t['project_id'] = t['profile'].apply(lambda c: c.get('project_id', None))
    t['profile_state'] = t['profile'].apply(lambda c: c.get('state', None))

    t['category_id'] = t['category'].apply(lambda c: c.get('id', None))
    t['category_slug'] = t['category'].apply(lambda c: c.get('slug', None))

    t['location_id'] = t['location'].apply(lambda c: c.get('id', None))
    t['location_slug'] = t['location'].apply(lambda c: c.get('slug', None))
    t['location_type'] = t['location'].apply(lambda c: c.get('type', None))
    t['location_country'] = t['location'].apply(lambda c: c.get('country', None))

    t = t.drop(columns=['urls', 'profile', 'photo', 'category', 'creator', 'slug', 'location'])
    df_list.append(t)
    pass

    pd.concat(df_list, sort=False, ignore_index=True).to_csv(fname, index=False)
    return


done_files = glob('processed_data/*.csv')

for path in tqdm(gzip_list[1:]):
    with gzip.open(path) as gzip_file:
        fname = f"processed_data\\KS_{path.split('_')[2].split('.')[0]}.csv"
        if fname in done_files:
            continue
        try:
            preprocess(pd.read_json(gzip_file, orient='records', lines=True), fname)
            pass
        except:
            with open('errorlog', 'a') as f:
                f.write(path+'\n')
                pass
    pass




# df = df.drop_duplicates(subset=['id'])
# df.shape
# df.isna().sum()
