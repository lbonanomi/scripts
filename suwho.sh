#!/bin/bash

#
# Add to /etc/profile to find out what users are su-doing to role accounts. Us operator-types don't get access to su logs
#

AWK=$(( which gawk | grep "gawk$" ) || ( which nawk | grep "nawk$" ))
UNAME=$(uname);
ID=$(id | $AWK '{gsub(/[\(-\)]/," ")} { print $2 }');

if [[ "$UNAME" == "Linux" ]] || [[ "$UNAME" == "AIX" ]]
then
        who -Xm &>/dev/null || WHO=$(who -m | awk '{ print $1 }');
        who -Xm &>/dev/null && WHO=$(who -Xm | awk '{ print $5 }');

        [[ "$ID" == "$WHO" ]] || echo "su-ed ($WHO)";
        [[ "$ID" == "$WHO" ]] && echo "plain";

else
        FRM=$(ptree $$ | awk '$2 ~ /sh/ && $2 !~ /ssh/ { print $1 }' | while read pid
        do
                ls /proc/$pid &>/dev/null || ls -ld /proc/$pid | awk '{ print $3 }'
        done | sort | uniq)

        [[ -z "$FRM" ]] || echo "su-ed ($FRM)";
        [[ -z "$FRM" ]] && echo "plain";
fi
