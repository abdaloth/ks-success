from glob import glob
import gzip

import pandas as pd
import numpy as np
from tqdm import tqdm
tqdm.pandas()

gzip_list = glob('original_data/*.gz')


def filter_df(json_df, fname=None):
    drop_cols = ['urls',
                 'profile',
                 'photo',
                 'category',
                 'creator',
                 'slug',
                 'location']

    dict_features = ['creator', 'profile', 'category', 'location']
    t = pd.DataFrame.from_records(json_df['data'])
    
    for feature in dict_features:
        if not feature in t.columns:
            t[feature] = {}
            pass
        pass
    
    t.loc[:,dict_features] = t[dict_features].applymap(lambda x: {} if np.all(pd.isnull(x)) else x)
    t = t.applymap(lambda x: '' if np.all(pd.isnull(x)) else x)
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

    t = t.drop(columns=drop_cols)

    if(fname):
        t.to_csv(fname, index=False)
    else:
        return t


if __name__ == '__main__':
    done_files = glob('filtered_data/*.csv')
    done_files = [p.split('\\')[1] for p in done_files]
    for path in tqdm(gzip_list):
        with gzip.open(path) as gzip_file:
            fname = f"filtered_data/KS_{path.split('_')[2].split('.')[0]}.csv"
            if fname.split('/')[1] in done_files:
                continue
            try:
                df = pd.read_json(gzip_file, orient='records', lines=True)
                filter_df(df, fname)
                pass
            except Exception as e:
                print(e)
                with open('errorlog', 'a') as f:
                    f.write(path+'\n')
                    pass
        pass


