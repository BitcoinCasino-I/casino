#!/usr/bin/env python3
import sys
import logging
logging.basicConfig(stream=sys.stderr)
sys.path.insert(0,"/var/www/html/CasinoApp/")
sys.path.insert(0,"/var/www/html/CasinoApp/CasinoApp/Casino_vEnv/lib/python3.8/site-packages/")

from CasinoApp import app as application
application.secret_key = 'mcjwillbeatu4ever'
