#!/bin/python3.6

# pylint: disable=C0103

"""Calculate unweighted cosine-similarity of files from ARGV"""

# --> Thank you vpekar from https://stackoverflow.com/questions/15173225 <--
#

import itertools
import math
import os
import sys
from collections import Counter

similarity_pct_threshold = 80

def get_cosine(vec1, vec2):
    """Calculate unweighted similarity"""

    intersection = set(vec1.keys()) & set(vec2.keys())
    numerator = sum([vec1[x] * vec2[x] for x in intersection])

    sum1 = sum([vec1[x]**2 for x in vec1.keys()])
    sum2 = sum([vec2[x]**2 for x in vec2.keys()])
    denominator = math.sqrt(sum1) * math.sqrt(sum2)

    if not denominator:
        returnval = 0.0
    else:
        returnval = float(numerator) / denominator

    return returnval

for a, b in itertools.combinations(sys.argv[1:], 2):
    try:
        os.path.isfile(a) and os.path.isfile(b)
    except Exception:
        print(sys.argv[0] + " file_1 file_2")
        sys.exit(1)

    text1 = []

    for line in open(a).readlines():
        for word in line.strip().split():
            text1.append(word)

    text2 = []

    for line in open(b).readlines():
        for word in line.strip().split():
            text2.append(word)

    similarity = int(get_cosine(Counter(text1), Counter(text2)) * 100)

    if similarity > similarity_pct_threshold:
        print(str(similarity) + "% similatiry between " + a + " and " + b)
