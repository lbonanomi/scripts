#!/bin/python

import os
import sys
from collections import Counter
from os.path import getsize
from metaphone import doublemetaphone

try:
        os.path.isdir(sys.argv[1])
        target = sys.argv[1]
except Exception as e:
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

largest_files = sorted(bullpen.itervalues(), reverse=True)[:10]

for (phone, count) in Counter(phones).iteritems():
        if bullpen[phone] in largest_files:
                pct = (bullpen[phone] * 100) / fssize

                size = bullpen[phone] / 1048576

                if pct > 1:
                        print str(count) + " files like " + phonebook[phone] + "\t" + str(size) + " MB " + str(pct) + "% of disk"
                elif size > 1:
                        print str(count) + " files like " + phonebook[phone] + "\t" + str(size) + " MB "
