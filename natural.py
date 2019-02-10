#!/bin/python3

"""Aggregate directory file sizes for cleanup"""

import sys
from collections import Counter
import os
from os.path import getsize
from metaphone import doublemetaphone

try:
    if os.path.isdir(sys.argv[1]):
        target = sys.argv[1]
except Exception:
    target = '.'

##
fsstat = os.statvfs(target)
fssize = (fsstat.f_blocks * fsstat.f_frsize)
##

phones = []
phonebook = dict()
bullpen = dict()

for log in os.listdir(target):
    log = target + '/' + log
    if os.path.isfile(log):
        (phone, b) = doublemetaphone(log)

        phonebook[phone] = log

        phones.append(phone)

        if phone in bullpen.keys():
            holder = bullpen[phone] + os.path.getsize(log)
        else:
            holder = os.path.getsize(log)

        bullpen[phone] = holder

largest_files = sorted(bullpen.values(), reverse=True)[:10]

for (phone, count) in Counter(phones).items():
    if bullpen[phone] in largest_files:
        pct = round((bullpen[phone] * 100.0) / fssize, 2)

        size = round(bullpen[phone] / 1048576, 2)

        sys.stdout.write(str(count) + " files like " + phonebook[phone] + "\t" + str(size) + " MB ")

        if pct > 1:
            print(str(pct), "% of disk")
        else:
            print()
