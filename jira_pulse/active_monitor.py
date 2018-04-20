#!/bin/python

import random
from random import randint

import re
import requests
from requests.auth import HTTPBasicAuth
import time

import datetime

import os
import sys

import signal


# Snag config values from config-file
#

import robota_config as cfg
import robota_credentials as creds


plain_username = cfg.config['plain_user_username']
plain_password = cfg.config['plain_user_password']

ldap_username = cfg.config['ldap_user_username']
ldap_password = cfg.config['ldap_user_password']

sms_username = creds.secure_config['sms_user_username']
sms_password = creds.secure_config['sms_user_password']

plain_user = HTTPBasicAuth(plain_username, plain_password)
ldap_user = HTTPBasicAuth(ldap_username, ldap_password)
sms_user = HTTPBasicAuth(sms_username, sms_password)


#
# exec() timeout
#

# Define timeout handler
def handler(signum, frame):
        raise Exception("exec_timeout")


# Associate timeout handler with SIGALRM
signal.signal(signal.SIGALRM, handler)


def getter(url, timeout_value=3.0, **kwargs):
        signal.alarm(int(timeout_value))

        start_time = time.time()

        if kwargs['auth']:
                try:
                        views = requests.get(url, auth=kwargs['auth'], verify=False, timeout=timeout_value)

                except Exception as e:
                        if (re.search('Connection refused', str(e))):
                                raise Exception("connection_refused")
                        elif (re.search('Read timed out', str(e))):
                                raise Exception("net_timeout")
                        elif (re.search('exec_timeout', str(e))):
                                raise Exception("exec_timeout")
                        else:
                                print "IDUNNO: " + str(e)
                                return([ e ], 777, 777)

        else:
                try:
                        views = requests.get(url, verify=False, timeout=timeout_value)

                except Exception as e:
                        if (re.search('Connection refused', str(e))):
                                raise Exception("connection_refused")
                        elif (re.search('Read timed out', str(e))):
                                raise Exception("timeout")
                        elif e == "exec_timeout":
                                raise Exception("exec_timeout")
                        else:
                                print "IDUNNO: " + str(e)
                                return([ e ], 777, 777)

        end_time = time.time()

        # Stats
        #
        request_time = end_time - start_time
        status = views.status_code

        return (views.json(), request_time, status)


def alerting(mechanism, message):
        if  mechanism == "mail":
                for address in cfg.config['mail_getters']:
                        mail_cmd = '/bin/mail -s "' + message + '" ' + address + ' </dev/null'
                        os.system(mail_cmd)

        if  mechanism == "sms":
                for mobile in cfg.config['call_getters']:
                        twilio_url = 'https://api.twilio.com/2010-04-01/Accounts/' + sms_username + '/Messages.json'
                        payload={'To': mobile, 'From': '+1$TWILIO_NUMBER', 'Body': message}
                        send_sms = requests.post(twilio_url , auth=sms_user, data=payload, verify="INTERMEDIATE_SSL.cer")

        return()



# Shake-and-bake
#

def shake_and_bake(host, timeout_value=3.0):
        # 'Randomly' select a board from the queue, fish an item out of the backlog and load it.
        #

        #print "ADOBO: " + host

        pub = MetricPublisher()

        ############################
        # Get a dump of all boards #
        ############################

        ################
        # Do routing #
        ################

        if datetime.datetime.now().isoweekday() in range(1, 6):
                metric = host + '.active.BoardDump'
                status_route = host + '.active.http_status'
        else:
                metric = host + '.weekend.active.BoardDump'
                status_route = host + '.weekend.active.http_status'


        agile_endpoint = 'https://' + host + '.Employer.com/rest/agile/1.0/board?type=scrum&startAt=' + str(randint(0, 9))                # coin-toss

        try:
                (board_list, board_time, status) = getter(agile_endpoint, auth=plain_user, username=plain_username, json=True, timeout_value=4.0)

                if sys.stdout.isatty():
                        print "PUSHING MEANINGFUL STATUS: " + str(status)
                #$PROPRIETARY_MAGIC_FOR_PUBLISHING_TO_METRICTANK

        except Exception as e:
                # Push a value '0' in case of failure

                #$PROPRIETARY_MAGIC_FOR_PUBLISHING_TO_METRICTANK

                print "PUSHING 555 TO " + status_route
                #$PROPRIETARY_MAGIC_FOR_PUBLISHING_TO_METRICTANK

                if str(e) == "net_timeout":
                        print "Network timeout getting board list"
                        alerting('mail', "JIRA SERVER " + host + " TIMED-OUT")
                elif str(e) == "exec_timeout":
                        print "Execution timeout getting board list"
                        alerting('mail', "JIRA SERVER " + host + " TIMED-OUT")
                elif str(e) == "connection_refused":
                        print "Connection Refused"
                        alerting('mail', "JIRA SERVER " + host + " REFUSED. APPLICATION IS DOWN")
                else:
                        # Escalate to coders
                        print "E: " + str(e) + " FOR " + agile_endpoint
                return()

        # Push success
        #$PROPRIETARY_MAGIC_FOR_PUBLISHING_TO_METRICTANK

        if sys.stdout.isatty():
                print "Rapid Boards listed in : " + str(board_time) + " seconds"


        ####################################
        # Pick a random board, get backlog #
        ####################################

        ###########
        # routing #
        ###########

        if datetime.datetime.now().isoweekday() in range(1, 6):
                metric = host + '.active.BacklogDump'
                status_route = host + '.active.http_status'
        else:
                metric = host + '.weekend.active.BacklogDump'
                status_route = host + '.weekend.active.http_status'


        random_board_id = random.choice(board_list['values'])['id']
        board = "https://" + host + ".prod.bloomberg.com/rest/greenhopper/1.0/xboard/plan/backlog/data.json?rapidViewId=" + str(random_board_id)

        try:
                (backlog_contents, backlog_time, status) = getter(board, auth=plain_user, username=plain_username, json=True, timeout_value=timeout_value)
                #$PROPRIETARY_MAGIC_FOR_PUBLISHING_TO_METRICTANK

        except Exception as e:
                # Push a value '0' in case of failure
                #$PROPRIETARY_MAGIC_FOR_PUBLISHING_TO_METRICTANK

                if str(e) == "net_timeout":
                        print "Network timeout getting backlog. " + str(timeout_value) + "-second timeout loading " + board
                elif str(e) == "exec_timeout":
                        print "Execution timeout getting backlog. " + str(timeout_value) + "-second timeout loading " + board
                else:
                        # Escalate to coders
                        print "E: " + str(e) + " FOR " + agile_endpoint
                return()


        ##################################
        # Pick a random issue, time-load #
        ##################################

        ###########
        # routing #
        ###########

        if datetime.datetime.now().isoweekday() in range(1, 6):
                metric = host + '.active.IssueLoad'
                status_route = host + '.active.http_status'
        else:
                metric = host + '.weekend.active.IssueLoad'
                status_route = host + '.weekend.active.http_status'

        try:
                backlog_issues = backlog_contents['issues']
        except Exception:
                print "Choked on a backlog for " + board

        if backlog_issues:
                if sys.stdout.isatty():
                        print "Backlog from " + board + " loaded in " + str(backlog_time) + " seconds"

                random_issue = random.choice(backlog_issues)['key']

                issue_endpoint = 'https://' + host + '.prod.bloomberg.com/rest/api/2/issue/' + random_issue

                try:
                        (code, issue_time, status) = getter(issue_endpoint, auth=plain_user, username=plain_username, json=True, timeout_value=timeout_value)

                except Exception as e:
                        # Push a value '0' in case of failure
                        #$PROPRIETARY_MAGIC_FOR_PUBLISHING_TO_METRICTANK

                        if str(e) == "net_timeout":
                                print "Network timeout getting backlog issues"
                        elif str(e) == "exec_timeout":
                                print "Execution timeout getting backlog issues"
                        else:
                                # Escalate to coders
                                print "E: " + str(e) + " FOR " + agile_endpoint
                        return()

                # Push success
                #$PROPRIETARY_MAGIC_FOR_PUBLISHING_TO_METRICTANK

                if sys.stdout.isatty():
                        print issue_endpoint + " loaded successfully in " + str(issue_time) + " seconds"

        else:
                if len(backlog_issues) == 0:
                        if sys.stdout.isatty():
                                print "Nothing in the backlog, pushing coded dummy value to " + metric
                        #$PROPRIETARY_MAGIC_FOR_PUBLISHING_TO_METRICTANK


              # Retry for an LDAP user
              #

              (code, timing) = getter(issue_endpoint, auth=ldap_user, username=ldap_username, code=True, json=False, timeout_value=3.0)

              if (code == 666):
                  if sys.stdout.isatty():
                      alerting('sms', "LDAP USER CAN NOT LOG-IN TO JIRA SERVER " + host + ", RECEIVED CODE " + code)

              if (code > 200):
                  alerting('mail', "JIRA SERVER " + url + " RETURNED AN ERROR LOADING " + random_issue)

        except Exception:
            return()
