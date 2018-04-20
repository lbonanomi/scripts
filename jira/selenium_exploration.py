#!/bin/python

import os
import sys

import re
import time

from datetime import date, timedelta

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import Select


chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-proxy-server")

chrome_options.binary_location = '/usr/bin/chromium-browser'


driver = webdriver.Chrome(executable_path=os.path.abspath("chromedriver"),   chrome_options=chrome_options)


username = ""	Fill these in.
password = ""

url = sys.argv[1]

try:
        url
except Exception:
        print sys.argv[0] + " URL"
        sys.exit(2)

login_page = url + "/login.jsp"
dashboard_page = url + "/secure/Dashboard.jspa"

def login(url, username, password):
        driver.get(login_page)

        username_field = driver.find_element_by_id("login-form-username")

        #print "Found login field at: " + str(time.time())

        if username_field.is_displayed():
                username_field = driver.find_element_by_id("login-form-username")
                username_field.clear()
                username_field.send_keys(username)

                password_field = driver.find_element_by_id("login-form-password")
                password_field.clear()
                password_field.send_keys(password)

                login_button = driver.find_element_by_id("login-form-submit")
                login_button.click()

                return(0)


def scrape_dash():
                driver.get(dashboard_page)

                activity_gadget = driver.find_element_by_id("gadget-10003")   # This may not stand...

                if activity_gadget.is_displayed():
                        print "I see the activity stream for user " + username + "!"
                        sys.exit(0)
                else:
                        print "No activity stream visible!"
                        sys.exit(1)


def check_dir_sync():
        dire = url + '/secure/admin/user/UserBrowser.jspa'

        driver.get(dire)

        sudo_password_field = driver.find_element_by_id("login-form-authenticatePassword")

        sudo_password_field.clear()
        sudo_password_field.send_keys(password)

        sudo_button = driver.find_element_by_id("login-form-submit")
        sudo_button.click()

        dire = url + '/plugins/servlet/embedded-crowd/directories/list'
        driver.get(dire)


        for piglet in driver.find_element_by_id("directory-list").find_elements_by_tag_name("td"):
                if re.search('synchronised', piglet.text):
                        piglet_text_arr = piglet.text.split()

                        for piggy in piglet_text_arr:
                                if re.search(':', piggy) or re.search('/', piggy):

                                        if re.search('/', piggy):
                                                print "This is a date."
                                                pigdays = piggy.split('/')
                                                pigdatestamp = date(int(pigdays[0]), int(pigdays[1]), int(pigdays[2])) #.strftime('%s')

                                                print pigdatestamp


                                        print "PIGGY: " + piggy

                        if piglet_text_arr.pop() == "successfully.":
                                print "Directory sync good."
                        else:
                                print "Directory sync failed"


def progress_issue(key):
        print

def search(key):
        proj_url =  url + '/projects/' + key + '/issues/?jql=project%20%3D%20_$PROJECT-NAME-HERE_AND%20creator%20%3D%20_$ADMIN-USER_%20ORDER%20BY%20created%20DESC'

        driver.get(proj_url)

        #print driver.get_network_conditions()

        polaroid = driver.get_screenshot_as_png()
        with open("/var/tmp/polaroid3.png", 'w') as screencap:
                screencap.write(polaroid)

        # Grab the first issue to be seen
        #

        for dc in driver.find_elements_by_class_name("issue-list"):
                issues = dc.text.split()
                print issues[0]


def create_issue():
        create_url = url + '/secure/CreateIssue!default.jspa'
        driver.get(create_url)

        project_field = driver.find_element_by_id("project-field")
        project_field.send_keys("$PROJECT")


        type_field = driver.find_element_by_id("issuetype-field")
        type_field.send_keys("Task\n")


        ## WINNER
        ##
        project_field.send_keys(Keys.ALT, 's')

        summary_field = driver.find_element_by_id("summary")
        summary_field.send_keys("Summary Text")


        summary_field.send_keys(Keys.ALT, 's')

        polaroid = driver.get_screenshot_as_png()
        with open("/var/tmp/polaroid3.png", 'w') as screencap:
                screencap.write(polaroid)

login(url, username, password)

#create_issue()

search('RDSISRE')

driver.quit()
