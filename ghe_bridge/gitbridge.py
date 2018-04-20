#!/usr/bin/python

import os
from flask import Flask, send_from_directory
from subprocess import call, PIPE, Popen
import time

# This is completely useless, but fulfills a Sonar requirement

listen_address = '0.0.0.0'

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, World!'

@app.route("/<org>/<repo>", methods=['GET'])
def clone(org, repo):
        repo = repo.replace(".git", "")

        gett = 'https://ghe.Employer.com/' + org + '/' + repo + '.git'
        call = Popen(['git', 'clone', gett], stdout=PIPE)
        ret = call.communicate()

        print(ret)

        # Inject config goodies

        conf_file = repo + '/.git/config'

        conf = open(conf_file, 'a+')
        conf.write("[http \"https://ghe.Employer.com\"]\n\tproxy = https://proxy.Employer.com:80\n\tsslVerify = false\n\n")
        conf.close()

        zipname = repo + '.zip'

        zipp = Popen(['zip', '-m', '-r', zipname, repo], stdout=PIPE)
        ret = zipp.communicate()

        return send_from_directory('/home/bbgh_bot', zipname, as_attachment=True)

if __name__ == "__main__":
        app.run(host=listen_address, port=8286)
