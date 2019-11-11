#!/bin/bash

# Set token data here. Because requests want a token in the URL,
# a .netrc file can't be used to store credentials
#
IPSTACK_TOKEN=""
MAPBOX_TOKEN=""

# Get a timestamp of 24 hours ago in epoch seconds
#
STANDOFF=$(date -d "24 hours ago" +%s)

# Capture failed logins with a timestamp < 24-hours-ago to a buffer file
#
sudo lastb -i | awk '{ print $3,$5,$6,$7 }' | while read ip datum
do
  [[ "$(date -d "$datum" +%s)" -gt "$STANDOFF" ]] && echo -e "$ip"
done > /tmp/LASTB_IP_BUFFER

# Get the top 150 IPs by connection count
sort /tmp/LASTB_IP_BUFFER | uniq -c | sort -rnk1 | awk '{ print $2,$1 }' | head -150 | while read IP time
do
    # Get Lat/Long data
    curl -s "http://api.ipstack.com/$IP?access_key=$IPSTACK_TOKEN&fields=longitude,latitude" | python -m json.tool | awk '/longitude|latitude/ { printf $NF" " }' | tr -d "," | awk '$1 != "null" { print "pin-s+0FF("$2","$1")," }'

# Smush all coordinates into a string to make a single call to Mapbox.io
done | tr -d "\n" | sed -e 's/,$//g' > /tmp/coords

curl -s "https://api.mapbox.com/styles/v1/mapbox/dark-v10/static/"$(cat /tmp/coords)"/0,40,1.35,0/1280x1024?access_token=$MAPBOX_TOKEN" > worms.png

rm /tmp/LASTB_IP_BUFFER /tmp/coords
