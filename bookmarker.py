#!/usr/bin/python3

"""
Microservice to record received URLs as Github gists

Mix-with bookmarklet: javascript:(function(){var e="http://$HOST:8000/"+document.location.href;xhr=new XMLHttpRequest,xhr.open("GET",encodeURI(e)),xhr.send()})();
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import requests
from requests.auth import HTTPBasicAuth

def doit(url):
        plain_user = HTTPBasicAuth('', '$TOKEN_HERE')
        payload = {"files":{"sfile":{"content":url}}}
        requests.post('https://api.github.com/gists', auth=plain_user, data=json.dumps(payload), verify=False)

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
        def do_GET(self):
                bookmark = self.requestline.split(' ')[1]
                clean_bookmark = '/'.join(bookmark.split('/')[1:])
                doit(clean_bookmark)

                self.send_response(200)
                self.end_headers()

httpd = HTTPServer(('0.0.0.0', 8000), SimpleHTTPRequestHandler)
httpd.serve_forever()
