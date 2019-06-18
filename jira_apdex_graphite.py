#!/usr/bin/python

import re
import sys
import time

if not re.search('atlassian-jira-apdex.log', sys.argv[1]):
    sys.exit(1)

with open(sys.argv[1]) as apdex_log:
    for line in apdex_log.readlines():
        parsed = re.search('(20[0-9][0-9]-[0-1][0-9]-[0-3][0-9] [0-2][0-9]:[0-9][0-9]:[0-9][0-9]),.*: (.+), apdex: {apdexScore=(.+), satisfiedCount=(.+), toleratingCount=(.+), frustratedCount=(.+)}', line)

        date = time.mktime(time.strptime(parsed.group(1), '%Y-%m-%d %H:%M:%S'))

        print parsed.group(2) + '.apdex' + ' ' + parsed.group(3) + ' ' + str(int(date))
        print parsed.group(2) + '.satisfiedCount' + ' ' + parsed.group(4) + ' ' + str(int(date))
        print parsed.group(2) + '.toleratingCount' + ' ' + parsed.group(5) + ' ' + str(int(date))
        print parsed.group(2) + '.frustratedCount' + ' ' + parsed.group(6) + ' ' + str(int(date))
