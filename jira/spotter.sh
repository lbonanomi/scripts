#!/bin/bash

window=$(date -d "90 seconds ago" +%s)

rm /tmp/counter

grep -B25 com.sun.jersey.api.client.filter.HTTPBasicAuthFilter /jira-logs/jira/atlassian-jira.log | awk '/ERROR/ { print $2,$3 }' | tr ',' ' ' | awk '{ print $1,$3 }' | while read time session
do
        thisone=$(date -d "$time" +%s)

        if (( $thisone >= $window ))
        then
                echo "$session" >> /tmp/counter
        fi

        if [[ -f /tmp/counter ]]
        then
                if (( $(sort /tmp/counter | uniq | wc -l) >= 3 ))
                then
                        echo "Firing for $(sort /tmp/counter | uniq | wc -l) sessions in-window"
                        grep -B25 com.sun.jersey.api.client.filter.HTTPBasicAuthFilter.handle /jira-logs/jira/atlassian-jira.log | awk -F"," '/ERROR/ { print $0 }' | mailx -s "SNIPER FIRE" $ADMIN'S_EMAIL
                        /jira/sniper
                        exit
                fi
        fi
done
