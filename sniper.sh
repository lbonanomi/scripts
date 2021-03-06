#!/bin/bash

# Get plugin, twiddle enabled flag and dump to file /tmp/killer
curl -s -k -u $SNIPER_USER:$SNIPER_PASSWORD https://jira.host.com/rest/plugins/1.0/$PLUGIN_KEY | sed -e 's/"enabled":true/"enabled":false/' > /tmp/killer;
curl -s -k -u $SNIPER_USER:$SNIPER_PASSWORD -X PUT -H "Content-Type: application/vnd.atl.plugins.plugin+json" --data @/tmp/killer  https://jira.host.com/rest/plugins/1.0/$PLUGIN_KEY
