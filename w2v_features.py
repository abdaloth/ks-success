"""
The goal is to find how semantically similar the name/blurb of a project 
to the average name/blurb of projects in the same category
"""

import re
import numpy as np
import pandas as pd

from gensim.models import fasttext
from scipy.spatial.distance import cdist

from tqdm import tqdm
tqdm.pandas()

w2v = fasttext.load_facebook_vectors('ignore/cc.en.300.bin.gz')
df = pd.read_csv('processed_data/KSData_191204.csv')
df = df.fillna('')

def get_vect(text, w2v_model):
    text = text.lower()
    text = re.sub(r'[\W]', ' ', text) # remove non-alphanumeric
    vectors = [w2v_model[w] for w in text.split()]
    if(len(vectors)>0):
        return np.mean(vectors, axis=0)
    return np.zeros(300)

def normalize_vect(vector):
    return (vector - np.min(vector))/(np.max(vector)-np.min(vector))


df['name_vect'] = df['name'].progress_apply(lambda x: get_vect(x, w2v))
df['blurb_vect'] = df['blurb'].progress_apply(lambda x: get_vect(x, w2v))

categories = list(df.main_category.unique())
mean_category_blurb_vect = {}
mean_category_name_vect = {}

df['blurb_uniqueness'] = np.inf
df['name_uniqueness'] = np.inf

for cat in categories:
    blurb_vects = np.stack(df[df.main_category == cat]['blurb_vect'].values)
    name_vects = np.stack(df[df.main_category == cat]['name_vect'].values)
    
    mean_category_blurb_vect[cat] = np.mean(blurb_vects, axis=0).reshape(1,300)
    mean_category_name_vect[cat] = np.mean(name_vects, axis=0).reshape(1,300)

    blurb_similarities = cdist(mean_category_blurb_vect[cat], blurb_vects, 'cosine')
    # blurb_similarities = normalize_vect(blurb_similarities)

    name_similarities = cdist(mean_category_name_vect[cat], name_vects, 'cosine')
    # name_similarities = normalize_vect(name_similarities)

    similarities = np.vstack([blurb_similarities, name_similarities]).transpose()
    
    df.loc[df.main_category == cat,('blurb_uniqueness', 'name_uniqueness')] = similarities

# greater than 1 means the vectors are so different they are pointing in opposite directions
df[['blurb_uniqueness','name_uniqueness']] = df[['blurb_uniqueness','name_uniqueness']].clip(0,1)

del df['name_vect']
del df['blurb_vect']

df.to_csv('processed_data/KSData_191205.csv', index=False)