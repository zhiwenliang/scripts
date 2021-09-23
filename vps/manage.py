import requests
import json

api_key = ""
get_headers = {"Authorization": "Bearer " + api_key}
post_headers = {
    "Authorization": "Bearer " + api_key,
    "Content-Type": "application/json"
}
api_url_pre = "https://api.vultr.com/v2/"


def pretty_print_json(json_text):
    return json.dumps(json.loads(json_text), indent=4)


def list_targets(target, params=None):
    url = api_url_pre + target
    response = requests.get(url, headers=get_headers, params=params)
    return pretty_print_json(response.text)


def create_instance():
    url = api_url_pre + "instances"
    data = {
        "region": "ewr",
        "plan": "vc2-1c-1gb",
        "label": "hah",
        "os_id": 477,
        "enable_ipv6": True,
        "sshkey_id": "6504ef21-cf98-4212-b526-754c78630cfd"
    }
    response = requests.post(url, headers=post_headers, data=data)
    return pretty_print_json(response.text)


def write_file(file_path, text):
    with open(file_path, 'w+') as f:
        f.write(text)


# print(list_targets("regions"))
# print(list_targets("ssh-keys"))
# print(list_targets("plans"))
# write_file("./plans.txt", list_targets("plans"))
# print(list_targets("os"))
# print(list_targets("instances"))
# print(create_instance())