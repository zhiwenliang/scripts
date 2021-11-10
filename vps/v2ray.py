# todo function
# Get account info
# Create instance
# Destroy instance
# Install v2ray
# Check info
# Get billing info

import requests
import json
import time

from requests.models import Response

# common_header of request
api_key = ""
header = {"Authorization": "Bearer " + api_key}
header_post = {
    "Authorization": "Bearer " + api_key,
    "Content-Type": "application/json"
}
# url
url_base = "https://api.vultr.com/v2"
url_account_info = url_base + "/account"
url_instances = url_base + "/instances"
url_regions = url_base + "/regions"
url_plans = url_base + "/plans"
url_os = url_base + "/os"


# make json pretty
def pretty_json(json_text):
    return json.dumps(json.loads(json_text), indent=4)


# Get Account Info
def account_info():
    result = requests.get(url_account_info, headers=header)
    json_text = pretty_json(result.text)
    return json_text


# list instances
def list_instances():
    result = requests.get(url_instances, headers=header)
    json_text = pretty_json(result.text)
    return json_text


# list plans
# Type: all(All available plan types),vc2(Cloud Compute),vhf(High Frequency Compute),vdc(Dedicated Cloud)
def list_plans(type):
    params = {"type": type}
    result = requests.get(url_plans, headers=header, params=params)
    json_text = pretty_json(result.text)
    return json_text


# list regions
def list_regions():
    result = requests.get(url_regions, headers=header)
    json_text = pretty_json(result.text)
    return json_text


# list os
def list_os():
    result = requests.get(url_os, headers=header)
    json_text = pretty_json(result.text)
    return json_text


# Create a instance
def create_instance(region, plan, enable_ipv6, os_id):
    params = {
        "region": region,
        "plan": plan,
        "enable_ipv6": enable_ipv6,
        "os_id": os_id,
    }
    result = requests.post(url_instances, headers=header_post, params=params)
    json_text = pretty_json(result.text)
    return json_text


def destroy_instance(instance_id):
    delete_url = url_instances + "/" + instance_id
    requests.delete(delete_url, headers=header)

# Install v2ray

# print(create_instance("nrt", "vc2-1c-1gb", True, 477))
# print(list_os())
