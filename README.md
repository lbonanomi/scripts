[add_me_to_crowd.rb](https://github.com/lbonanomi/scripts/blob/master/add_me_to_crowd.rb): "Business" users did not feature in the correct OU of employer's Active Directory and Windows Admin said we shouldn't rearrange things. This microservice queries an Active Directory instance and creates a corresponding user in an Atlassian Crowd internal user dir. Users who *do* feature in Active Directory are routed to an independent password reset function. 


[natural.php](https://github.com/lbonanomi/scripts/blob/master/natural.php): Employer's legacy framework uses a logging scheme that rolls files over after they hit ~30MB, appending some variation of timestamp to the old filename. This can lead to very-full directories without any single file being over-large, preventing chats about log management with any particular development group. This script trolls a directory building a database of metaphone3 values and sizes for all file names and presents them in a report as virtual files.

```
$ ~/natural

FILES LIKE a_service_name_2018-04-14T00:00:21.log: 6 files consuming 10.45 GB (4.74% of /logs)
FILES LIKE b_service_name.log.20180418_130954: 274 files consuming 8.34 GB (3.78% of /logs)
FILES LIKE c_service_name.20171016: 189 files consuming 7.86 GB (3.57% of /logs)
FILES LIKE d_service_name.txt: 1 files consuming 7.25 GB (3.29% of /logs)
FILES LIKE e_service_name.log.20180214_074502-191631: 90 files consuming 4.79 GB (2.18% of /logs)
```


[jira_attachment_move.sh](https://github.com/lbonanomi/scripts/blob/master/jira_attachment_move.sh): A 20-minute knock-up for moving JIRA attachments between datacenters


[AGNES](https://github.com/lbonanomi/scripts/blob/master/AGNES.rb): This script is the functional part of the AGNES password-handling system, which scraped Employer's tickting system looking for password reset requests from folks who didn;t bring their biometric token to work. If they hadn't set an Active Directory password in the last 89 days AGNES would generate a weakly-random password for them. This script worked in-concert with scripts useless outside of Employer's devlab which would handle both ticket scraping and email. The name is a callback to the original mailer sign-off "From Agnes, with love"


[git_cat_tree](https://github.com/lbonanomi/scripts/blob/master/git_cat_tree.rb): Documentation in Github Enterprise is a great idea! Git runbooks just-in GHE is a *terrible idea*. This is a convenience script for picking docco off of a GHE instance. Why not use a git clone? Because babeld can fail independently.



[a link](https://github.com/user/repo/blob/branch/other_file.md)
