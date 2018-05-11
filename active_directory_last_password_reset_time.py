#!/bin/python

import ConfigParser
from datetime import datetime
import ldap
import sys

# Simple config
#
config = ConfigParser.ConfigParser()
config.read("~/.ssh/ldap_creds.py")   # Obviously a gloss.

ldap_user = config.get("configuration","cn")
ldap_password = config.get("configuration","password")

ldap.set_option(ldap.OPT_REFERRALS, 0)

basedn = "DC=activedirectory,DC=company,DC=com"
searchFilter = "sAMAccountName=" + sys.argv[1]
searchAttribute = ["pwdLastSet"]

conn = ldap.initialize('ldap://activedirectory.company.com:389')
conn.simple_bind_s(ldap_user, ldap_password)

ldap_rez_id = conn.search(basedn, ldap.SCOPE_SUBTREE, searchFilter, searchAttribute)

(lbl, data) = conn.result(ldap_rez_id, 0)
(lbl, data) = data[0]

last_reset = data['pwdLastSet'][0]

#
# Thank you, Robert de Bock:
# http://meinit.nl/convert-active-directory-lastlogon-time-to-unix-readable-time
#

last_reset_epoch = (int(last_reset) / 10000000) - 11676009600 # 11676009600 seconds from 1601-01-01 to 1970-01-01

print last_reset_epoch

conn.unbind_s()
