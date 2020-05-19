#!/bin/python3.6

# pylint: disable=C0103

"""Get last Active Directory password reset time"""

# ldap.conf as-below:
#
# [LDAP]
# cn = CN=admin,OU=Enabled Accounts,DC=Active_Directory,DC=Company,DC=com
# password = password
# basedb = DC=Active_Directory,DC=Company,DC=com

import configparser
from datetime import timedelta
from ldap3 import Server, Connection, ALL

# Simple config
#
config = configparser.ConfigParser()
config.read("ldap.conf")

ldap_user = config.get("LDAP", "cn")
ldap_password = config.get("LDAP", "password")

server = Server('$LDAP_SERVER', get_info=ALL)
conn = Connection(server, ldap_user, ldap_password, auto_bind=True)

conn.search(ldap_user, '(objectClass=*)', attributes=['pwdLastSet'])

response = conn.response

last_reset = response[0]['raw_attributes']['pwdLastSet'][0].decode("utf-8")

if int(last_reset) > 0:
    epoch = (int(last_reset) / 10000000) - timedelta(days=(1970 - 1601) * 365 + 89).total_seconds()
    print(int(epoch))
else:
    print("Never-set")
