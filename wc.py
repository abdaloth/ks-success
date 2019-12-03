import re
from nltk.corpus import stopwords
import numpy as np
import pandas as pd
from wordcloud import WordCloud
from os import path
from PIL import Image

data = pd.read_csv('processed_data/KSData_191201.csv')

def create_masked_cloud(title, text, mask_path, sw_set):
    print('\ngenerating wordcloud...')
    cloud_mask = np.array(Image.open(mask_path))
    wc = WordCloud(background_color="white",
                   max_words=3000, mask=cloud_mask, stopwords=sw_set)
    wc.generate(text)
    d = path.dirname('__file__')
    wc.to_file(path.join(d, "wordclouds/{}_cloud.png".format(title)))

stop_words = stopwords.words('english')
stop_words.append('canceled')
stop_words.append('project')
stop_words = set(stop_words)

def clean_text(text):
    text = text.lower()
    text = re.sub(r'[^a-z0-9]',' ', text)
    return text


s_blurb = '\n'.join(data[data.state == 'successful']['blurb'])
f_blurb = '\n'.join(data[data.state == 'failed']['blurb'].apply(lambda x: str(x)))

s_name = '\n'.join(data[data.state == 'successful']['name'])
f_name = '\n'.join(data[data.state == 'failed']['name'].apply(lambda x: str(x)))

all_blurb = '\n'.join(data['blurb'].apply(lambda x: str(x)))
all_name = '\n'.join(data['name'].apply(lambda x: str(x)))


create_masked_cloud('successful_blurb', clean_text(s_blurb), 'cloud_stencil.jpg', stop_words)
create_masked_cloud('failed_blurb', clean_text(f_blurb), 'cloud_stencil.jpg', stop_words)

create_masked_cloud('successful_name', clean_text(s_name), 'cloud_stencil.jpg', stop_words)
create_masked_cloud('failed_name', clean_text(f_name), 'cloud_stencil.jpg', stop_words)

create_masked_cloud('all_blurb', clean_text(all_blurb), 'cloud_stencil.jpg', stop_words)
create_masked_cloud('all_name', clean_text(all_name), 'cloud_stencil.jpg', stop_words)

