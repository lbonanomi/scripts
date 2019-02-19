#!/bin/python

# pylint: disable=C0103

"""Simple sanity checks for Chef-driven Jenkins configs"""

import base64
from collections import Counter
import time
import simplejson as json
import requests
from requests.auth import HTTPBasicAuth
from flask import Flask, request

plain_user = HTTPBasicAuth('', 'ADD_TOKEN_HERE')

app = Flask(__name__)
@app.route("/", methods=['POST'])
def verify():
    """Run validations"""
    data = request.get_json()

    if data['action'] == "opened":
        status_url = data['pull_request']['head']['repo']['url'] + '/statuses/' + data['pull_request']['head']['sha']

        pr_url = data['pull_request']['url'] + '/files'

        pr_detail = requests.get(pr_url, auth=plain_user, verify=False)

        for deet in pr_detail.json():
            requests.post(status_url, auth=plain_user, json={"context":"JSON", "state":"pending", "description":"JSON validation pending"})
            time.sleep(1)

            contents = requests.get(deet['contents_url'], auth=plain_user, verify=False)

            encoded = contents.json()['content']
            decoded = base64.b64decode(encoded)

            try:
                json.loads(decoded)
            except Exception:
                requests.post(status_url, auth=plain_user, json={"context":"JSON", "state":"failure", "description":"JSON validation failed"})
                return "Malformed JSON"

            requests.post(status_url, auth=plain_user, json={"context":"JSON", "state":"success", "description":"JSON validated"})

            backup = []
            name = []
            primary = []

            json_arr = json.loads(decoded)

            for cluster_details in json_arr['jaas-cluster']:
                for value in ["backup", "name", "primary"]:
                    try:
                        pvalue = cluster_details[value]
                        packer = value + '.append("' + pvalue + '")'
                        eval(packer)

                    except Exception:
                        continue

            for backup_value in backup:
                if backup.count(backup_value) > 1:
                    requests.post(status_url, auth=plain_user, json={"context":"Content", "state":"failure", "description":"Duplicate Backup Values"})

            for name_value in name:
                if name.count(name_value) > 1:
                    requests.post(status_url, auth=plain_user, json={"context":"Content", "state":"failure", "description":"Duplicate Name Values"})

            for primary_value in primary:
                if primary.count(primary_value) > 1:
                    requests.post(status_url, auth=plain_user, json={"context":"Content", "state":"failure", "description":"Duplicate Primary Values"})

    return "Validation Ran"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8296)
