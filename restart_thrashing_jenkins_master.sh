#!/usr/bin/bash

#
# 6-or-more Null Pointers in Jenkins log in the last 3 minutes? Restart Jenkins.
#
# Cron me to run */2 * * * *
#


DATESTAMP=$(date +"%b %d");
THRESHOLD=$(($(date +%s)-180)); 
egrep -A1 -B1 SEVERE /var/log/jenkins/jenkins.log | awk 'BEGIN { RS="--" } /'"$DATESTAMP"'/ && /NullPointerException/ { print $1,$2,$3,$4,$5 }' | tail -20 | while read full;
do 
  THEN=$(date -d "$full" +%s); 
  [[ "$THEN" -ge "$THRESHOLD" ]] && echo "CURRENT_ALARM"; 
done | [[ $(grep -c "CURRENT_ALARM") -ge 6 ]] && sudo /usr/sbin/service jenkins restart
