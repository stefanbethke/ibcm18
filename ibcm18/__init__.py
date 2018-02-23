#
from __future__ import print_function

import json
import os
import requests
import sys
from datetime import time
from hashlib import sha256
from urlparse import urljoin

class UpdateContent:

    def __init__(self, url, authtoken=None):
        self.url = url
        self.jsonfile = 'content.json'
        self.etags = {}
        self.timestamps = {}
        self.authtoken = authtoken

    def loadJson(self):
        try:
            with open(self.jsonfile, 'r') as f:
                jf = json.loads(f.read())
        except IOError:
            return None
        return jf

    def update(self):
        updated = False
        h = {}
        if self.authtoken:
            h['CloudCAEAccessToken'] = self.authtoken
        r = requests.get(self.url, headers=h)
        r.raise_for_status()
        try:
            j = r.json()
        except ValueError as e:
            print("Error parsing content.json: {}".format(e), file=sys.stderr)
            j = self.loadJson()
        print("SERVICE loaded content metadata", file=sys.stderr)
        for u in j['pages']:
            u['image_url'] = urljoin(self.url, u['image_url'])
            (f, x) = os.path.splitext(u['image_url'])
            h = sha256(u['image_url'].encode('utf-8')).hexdigest()
            u['image_name'] = 'content-{}'.format(h[:12])
            u['image_file'] = '{}{}'.format(u['image_name'], x)
        j["loaded"] = True

        jf = self.loadJson()

        if json.dumps(j, sort_keys=True) != json.dumps(jf, sort_keys=True):
            updated = True
        if updated:
            print("SERVICE updating {}".format(self.jsonfile), file=sys.stderr)
            with open(self.jsonfile, 'w') as f:
                json.dump(j, f, sort_keys=True, indent=4)
        else:
            print("SERVICE metadata not changed", file=sys.stderr)
        for u in j['pages']:
            h = {}
            if self.authtoken:
                h['CloudCAEAccessToken'] = self.authtoken
            if os.path.isfile(u['image_file']):
                if u['image_file'] in self.timestamps:
                    h['if-modified-since'] = self.timestamps[u['image_file']]
                if u['image_file'] in self.etags:
                    h['if-none-match'] = self.etags[u['image_file']]
            r = requests.get(u['image_url'], headers=h)
            if r.status_code == 304:
                print("SERVICE {}: not modified".format(u['image_url']), file=sys.stderr)
                continue
            print("SERVICE {}: saving".format(u['image_url']), file=sys.stderr)
            if 'last-modified' in r.headers:
                self.timestamps[u['image_file']] = r.headers['last-modified']
            with open(u['image_file'], 'wb') as f:
                f.write(r.content)
            updated = True
        return updated


if __name__ == "__main__":
    uc = UpdateContent("https://preview.development.cms.tractorsupply-proxy.coremedia.com/blueprint/servlet/aurora/6786-6786?view=fragmentPreview&p13n_test=true&p13n_testcontext=0&userVariant=406", "ibcm18pa")
    uc.update()
    uc.update()
