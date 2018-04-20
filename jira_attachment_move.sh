#/bin/bash

#
# This script will move attachments from IPM to a JIRAP instance *IF* you change the values below according to the comments.
#
# Call as attachment_mover.sh $SOURCE_PROHECT 
#

PROJECT=$1
LEADER="RDFA"       # This is the prefix of the instance you will move to.

[[ -z "$PROJECT" ]] && exit 4

find "/jira/data/attachments/$PROJECT" -type d -maxdepth 1 | while read hostIssue
do
        ISSUE=$(basename "$hostIssue")
        NEWISSUE=$LEADER""$ISSUE

        NEWISSUE=$(echo "$NEWISSUE" | sed -e 's/CGOV/GI/g')   # If the key is NOT $LEADER$OLD_KEY change this 

        find "$hostIssue" -type f | sort | uniq | while read ATTACHMENT_PATH
        do
                if [[ -n $(echo "$NEWISSUE" | grep "[0-9]") ]]
                then

                        ATTACHMENT=$(basename $ATTACHMENT_PATH)

                        NAME=$(curl -s -k -u $OLD_USERNAME:$OLD_PASSWORD https://old.jira.com/jira/rest/api/2/attachment/$ATTACHMENT | awk -F"," '{ print $2 }' | awk -F'"' '{ print $4 }')

                        echo "ISSUE: $ISSUE HOSTS $ATTACHMENT AS $NAME. PUSH-TO $NEWISSUE"

                        echo "cp $ATTACHMENT_PATH /tmp/$NAME"
                        cp "$ATTACHMENT_PATH" "/tmp/$NAME"

                        if [[ -f "/tmp/$NAME" ]]
                        then
                                ## SET THE INSTANCE NAME ON BELOW LINES!
                                (curl -D - -k -u $NEW_USER:$NEW_PASS -X POST -H "X-Atlassian-Token: no-check" -F "file=@/tmp/$NAME"  --tlsv1  https://new.jira.com/rest/api/2/issue/$NEWISSUE/attachments)
                        fi
                fi
        done
done
