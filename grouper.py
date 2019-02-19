#!/bin/python3.6

# pylint: disable=C0103

"""print "Groupings" of files based on cosire similarity"""

# Thank you vpekar, wherever you might be tonight.
#
# https://stackoverflow.com/questions/15173225/how-to-calculate-cosine-similarity-given-2-sentence-strings-python
#

from collections import Counter
import configparser
import itertools
import math
import os
import sys

threshold = 80

def get_cosine(vec1, vec2):
    """Get similarity of 2 strings"""
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

def weighting(config_file):
    """Get keyword weight values from configuration file"""

    wkeywords = []
    weights = {}

    config = configparser.ConfigParser()
    config.read(config_file)


    for section in config.sections():
        keyword = config.items(section)[0][1]
        weight = config.items(section)[1][1]

        wkeywords.append(keyword)

        weights[keyword] = weight

    return (wkeywords, weights)


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
    except FileNotFoundError:
        print(sys.argv[0] + " file_1 file_2...")
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

        print(a, b, similarity)

        if similarity > threshold:
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
        # Already packed in a larger set
        if set(pack).issubset(set(stored)) and len(pack) < len(stored):
            passflag = 0

        # This set supercedes a packed set
        if set(stored).issubset(set(pack)) and len(stored) < len(pack):
            passflag = 0
            del fish[str(stored)]

    if passflag == 1:
        fish[str(pack)] = pack

final = sorted(list(fish.values()))

for soda in final:
    print(" ".join(soda))
