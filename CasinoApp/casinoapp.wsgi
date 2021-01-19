#!/usr/bin/env python3
import sys
import logging
logging.basicConfig(stream=sys.stderr)
sys.path.insert(0,"/var/www/html/")
sys.path.insert(0,"/usr/local/lib/python3.7/dist-packages")
sys.path.insert(0,"/var/www/html/CasinoApp/venv/lib/python3.7/site-packages")
from CasinoApp import app as application
application.secret_key = 'APPLICATIONSECRET'