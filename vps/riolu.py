import requests

url = "https://1o.riolu.ink/api/?action=login&email=zhiwen_liang%40foxmail.com&password=8xSrMk3N8bDfhz"

payload={}
headers = {
   'User-Agent': 'Apifox/1.0.0 (https://apifox.com)'
}

response = requests.request("GET", url, headers=headers, data=payload)

auth=response.json()['data']
print(auth)


url = "https://1o.riolu.ink/skyapi/?action=checkin"

payload={}
headers = {
   'Cookie': 'auth=' + auth,
   'User-Agent': 'Apifox/1.0.0 (https://apifox.com)'
}

response = requests.request("GET", url, headers=headers, data=payload)

print(response.text)
