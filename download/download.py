import requests
import os
from urllib.parse import unquote

with open ('./url.txt', 'r') as f:
    lines = f.readlines()
    url_list = []
    for line in lines:
        url_list.append(line.strip('\n'))
    for url in url_list:
        name = unquote(os.path.basename(url))
        r = requests.get(url).content
        with open(name, 'wb') as f1:
            f1.write(r)
