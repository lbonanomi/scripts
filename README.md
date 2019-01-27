### Active Directory Things

[AGNES](https://github.com/lbonanomi/scripts/blob/master/AGNES.rb): This script is the functional part of the AGNES password-handling system, which scraped Employer's tickting system looking for password reset requests from folks who didn't bring their biometric token to work. If they hadn't set an Active Directory password in the last 89 days AGNES would generate a weakly-random password for them. This script worked in-concert with scripts useless outside of Employer's devlab which would handle both ticket scraping and email. The name is a callback to the original mailer sign-off "From Agnes, with love"


### Atlassian (Jira/Crowd) Things

[add_me_to_crowd.rb](https://github.com/lbonanomi/scripts/blob/master/add_me_to_crowd.rb): "Business" users did not feature in the correct OU of employer's Active Directory and Windows Admin said we shouldn't rearrange things. This microservice queries an Active Directory instance and creates a corresponding user in an Atlassian Crowd internal user dir. Users who *do* feature in Active Directory are routed to an independent password reset function. 


### Git & GitHub Things

[ghe_bridge](https://github.com/lbonanomi/scripts/tree/master/ghe_bridge): So Employer pushes an "everyone in the pool" model for GHE, including non-engineering staff who may not be comfortable on a Linux commandline and have trouble with navigating a .gitconfig file. This microservice and bookmarklet combo allows for more business-oriented folks to push a button and get a fixed .gitconfig and a repository zipfile for GH Desktop. 

[git_cat_tree](https://github.com/lbonanomi/scripts/blob/master/git_cat_tree.rb): Documentation in Github Enterprise is a great idea! Git runbooks just-in GHE is a *terrible idea*. This is a convenience script for picking docco off of a GHE instance. Why not use a git clone? Because babeld can fail independently.

[scripto.sh](https://github.com/lbonanomi/scripts/blob/master/scripto.sh): Function to automatically save local typescripts as gist-files on GitHub.com.


### Linux/Unix Things

[cosanguine.py](https://github.com/lbonanomi/scripts/blob/master/cosanguine.py): Calculate cosine text-similarity of files listed in ARGV, mixes well with a little shell glue and [polarizer](https://github.com/lbonanomi/polarizer).  

Thank you to vpekar @ StackOverflow for the math function!

[grouper.py](https://github.com/lbonanomi/scripts/blob/master/grouper.py): Calculate (potentially weighted) cosine text-similarity of files listed in ARGV like [cosanguine.py](https://github.com/lbonanomi/scripts/blob/master/cosanguine.py), but group files together on STDOUT line.

[jaccard.py](https://github.com/lbonanomi/scripts/blob/master/jaccard.py): A debt collection tool that compares the similarity of files from ARGV using jaccard indices. This proved super-handy for checking ```rpm -qa``` lists between notionally sibling hosts.

[natural.php](https://github.com/lbonanomi/scripts/blob/master/natural.php): Employer's legacy framework uses a logging scheme that rolls files over after they hit ~30MB, appending some variation of a timestamp to the old filename. This can lead to very-full directories without any single file being over-large, preventing chats about log management with any particular development group. This script trolls a directory building a database of metaphone3 values and sizes for all file names and presents them in a report as virtual files. A less featureful (but less snarled) [python](https://github.com/lbonanomi/scripts/blob/master/natural.py) port is available, too.

```
$ ~/natural

FILES LIKE a_service_name_2018-04-14T00:00:21.log: 6 files consuming 10.45 GB (4.74% of /logs)
FILES LIKE b_service_name.log.20180418_130954: 274 files consuming 8.34 GB (3.78% of /logs)
FILES LIKE c_service_name.20171016: 189 files consuming 7.86 GB (3.57% of /logs)
FILES LIKE d_service_name.txt: 1 files consuming 7.25 GB (3.29% of /logs)
FILES LIKE e_service_name.log.20180214_074502-191631: 90 files consuming 4.79 GB (2.18% of /logs)
```

[suwho.sh](https://github.com/lbonanomi/scripts/blob/master/suwho.sh): Record-keeping at Employer wasn't always what it is now and security remains a distinct silo, so there are application LDAP accounts with no clear line of ownership. This script is jammed into the /etc/skel profile to help find active sudo calls to application accounts.  


[braille_chart.sh](https://github.com/lbonanomi/scripts/blob/master/braille_chart.sh): I <3 the idea of [sparklines](https://github.com/holman/spark) and [Grafana's](https://grafana.com) handsome line charts together in terminal. To try and keep things compact while still-showing discrete counts, values are displayed in 8-dot braille. *Please note:* this script is fun and the expense of efficiency and sanity. 

```
     ⠐ ⠐ ⠐ ⠐ ⡆ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ 
     ⠐ ⠐ ⠐ ⠐ ⡇ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ 
     ⠐ ⠐ ⠐ ⠐ ⡇ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ 
60   ⠐ ⠐ ⠐ ⠐ ⡇ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ ⠐ 
     ⠐ ⠐ ⠐ ⠐ ⡇ ⠐ ⠐ ⡇ ⠐ ⠐ ⠐ ⠐ ⠐ 
     ⠐ ⠐ ⠐ ⠐ ⡇ ⠐ ⠐ ⡇ ⠐ ⠐ ⠐ ⠐ ⠐ 
     ⠐ ⠐ ⠐ ⠐ ⡇ ⠐ ⠐ ⡇ ⠐ ⠐ ⠐ ⠐ ⠐ 
     ⠐ ⠐ ⠐ ⠐ ⡇ ⠐ ⠐ ⡇ ⠐ ⠐ ⠐ ⠐ ⠐ 
40   ⠐ ⠐ ⠐ ⠐ ⡇ ⠐ ⡆ ⡇ ⠐ ⠐ ⠐ ⠐ ⠐ 
     ⠐ ⠐ ⠐ ⠐ ⡇ ⠐ ⡇ ⡇ ⠐ ⠐ ⠐ ⠐ ⠐ 
     ⠐ ⠐ ⠐ ⠐ ⡇ ⠐ ⡇ ⡇ ⠐ ⡀ ⡄ ⠐ ⠐ 
     ⠐ ⠐ ⠐ ⠐ ⡇ ⠐ ⡇ ⡇ ⠐ ⡇ ⡇ ⠐ ⠐ 
     ⠐ ⡀ ⠐ ⠐ ⡇ ⠐ ⡇ ⡇ ⠐ ⡇ ⡇ ⠐ ⡇ 
20   ⠐ ⡇ ⠐ ⠐ ⡇ ⠐ ⡇ ⡇ ⠐ ⡇ ⡇ ⠐ ⡇ 
     ⠐ ⡇ ⠐ ⠐ ⡇ ⠐ ⡇ ⡇ ⠐ ⡇ ⡇ ⠐ ⡇ 
     ⡄ ⡇ ⡇ ⠐ ⡇ ⡆ ⡇ ⡇ ⠐ ⡇ ⡇ ⠐ ⡇ 
     ⡇ ⡇ ⡇ ⡀ ⡇ ⡇ ⡇ ⡇ ⠐ ⡇ ⡇ ⠐ ⡇ 
     ⡇ ⡇ ⡇ ⡇ ⡇ ⡇ ⡇ ⡇ ⡆ ⡇ ⡇ ⡄ ⡇ 
0             |         |    
          06:05     06:10   
```
