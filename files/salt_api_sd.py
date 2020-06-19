#!/usr/bin/env python
import requests
import json

SALT_API = '{{ config.api_url }}'
USERNAME = '{{ config.user }}'
PASSWORD = '{{ config.pass }}'
FILENAME = '{{ config.output_file }}'
PORT = '{{ config.node_exporter_port }}'

session = requests.Session()
session.post(SALT_API + '/login', json={'eauth': 'pam', 'username': USERNAME, 'password': PASSWORD}, verify=False)
r = session.post(SALT_API, json={'client': 'wheel', 'fun': 'key.list', 'match': 'accepted'}, verify=False)

minions = r.json()['return'][0]['data']['return']['minions']
targets = []

for minion in minions:
    targets.append('{0}:{1}'.format(minion, PORT))

f = open(FILENAME, 'w')
f.write(json.dumps([{'targets': targets, 'labels':{}}] , sort_keys=True, indent=4))
