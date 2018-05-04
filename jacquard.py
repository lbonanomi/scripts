#!/bin/python

from collections import Counter
import itertools
import os
import sys

for file_a, file_b in itertools.combinations(sys.argv[1:], 2):
    if os.path.isfile(file_a) and os.path.isfile(file_b):
        a_file = open(file_a).readlines()
        b_file = open(file_b).readlines()

        both_files = a_file + b_file

        set = Counter(both_files)

        union = len(set.items())

        intersection = []

        for X in set.iteritems():
            if (X[1] == 2):
                intersection.append(X[0])

        cof = (len(intersection) / float(union))
        cof = str(round(cof,3))

        print file_a,file_b,cof
