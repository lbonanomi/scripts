#!/bin/python

# Thank you vpekar, wherever you might be tonight.
#
# https://stackoverflow.com/questions/15173225/how-to-calculate-cosine-similarity-given-2-sentence-strings-python
#

from collections import Counter
import ConfigParser
import itertools
import math
import os
import sys

import time

similarity_pct_threshold = 80

def get_cosine(vec1, vec2):
    intersection = set(vec1.keys()) & set(vec2.keys())
    numerator = sum([vec1[x] * vec2[x] for x in intersection])

    sum1 = sum([vec1[x]**2 for x in vec1.keys()])
    sum2 = sum([vec2[x]**2 for x in vec2.keys()])
    denominator = math.sqrt(sum1) * math.sqrt(sum2)

    if not denominator:
        return 0.0
    else:
        return float(numerator) / denominator


def weighting(config_file):
    keywords = []
    weights = {}

    config = ConfigParser.ConfigParser()
    config.read(config_file)


    for section in config.sections():
        keyword = config.items(section)[0][1]
        weight = config.items(section)[1][1]

        keywords.append(keyword)

        weights[keyword] = weight

    return (keywords, weights)


if os.path.isfile("sanguine_weights"):
    keywords, keyword_weights = weighting("sanguine_weights")
else:
    keywords = []
    keyword_weights = []


bullpen = {}
cycled = []

for a, b in itertools.permutations(sys.argv[1:], 2):
    try:
        os.path.isfile(a) and os.path.isfile(b)
    except Exception:
        print  sys.argv[0] + " file_1 file_2..."
        sys.exit(1)


    if a not in cycled:

        text1 = []
        for line in open(a).readlines():
            for word in line.strip().split():
                text1.append(word)

                if word in keywords:
                    for x in range(0, int(keyword_weights[word])):
                        text1.append(word)
        cycled.append(a)
    if b not in cycled:
        text2 = []
        for line in open(b).readlines():
            for word in line.strip().split():
                text2.append(word)

                if word in keywords:                                    # Weighting
                    for x in range(0, int(keyword_weights[word])):      #
                        text2.append(word)                              #

        similarity = int(get_cosine(Counter(text1), Counter(text2)) * 100)

        if similarity > similarity_pct_threshold:
            bullpen[a + b] = [a, b]



# associate 2-value tuples into sets

final = []

fish = {}


for thing in bullpen.values():
    pack = []

    for small in thing:
        for tupled in bullpen.values():
            if small == tupled[0]:
                if not tupled[0] in pack:
                    pack.append(tupled[0])

                if not tupled[1] in pack:
                    pack.append(tupled[1])

					
    passflag = 1


    for stored in fish.values():
        if set(pack).issubset(set(stored)) and len(pack) < len(stored):         # Already packed in a larger set
            passflag =0

        if set(stored).issubset(set(pack)) and len(stored) < len(pack):         # This set supercedes a packed set
            passflag =0
            del fish[ str(stored) ]



    if passflag == 1:
        fish[ str(pack) ] = pack


final = sorted(list(fish.values()))

for soda in final:
    print " ".join(soda)
