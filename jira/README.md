[sniper](sniper.sh) and [spotter](spotter.sh) need some story-telling. As Employer's Atlassian infrastucture grew, product management engaged Java developers to write plugins without consulting with the Jira admins; which led to plugins being developed on a much-newer verion of JIRA than the one deployed to production. This resulting plugin relied on a different verion of Jetty than the one deployed to prod, and if the called too-frequently it would cause JIRA to unceremoniously crash. 


An indicator of an impending crash was "com.sun.jersey.api.client.filter.HTTPBasicAuthFilter" messages in the JIRA log. [spotter](spotter.sh) was cron-ned to run every 60 seconds checking for jersey messages in the log, and if more than 3 appeared within the last 90 seconds the plugin would be disabled by [sniper](sniper.sh) disabling it in the UPM with a REST call.

------------


[jira_attachment_move.sh](https://github.com/lbonanomi/scripts/blob/master/jira/jira_attachment_move.sh) a 10 minute knock-up to move attachments to a new instance. 


[violet](https://github.com/lbonanomi/scripts/blob/master/jira/violet.php): Violet was the tool for recreating Agile boards and sprint data from a legacy JIRA-6 instance to a fleet of JIRA-7 instances. This tooling subsumes previous tools "red" and "blue", hence the name.
