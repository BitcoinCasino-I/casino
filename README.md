# casino  
  
## Server Requirements  
* python3
* python3-dev
* virtualenv
* pip3
* apache2
* libapache2-mod-wsgi-py3
* libmysqlclient-dev
  
## Update app on server  
The webapp is automatically updates if there is a new version tag in this repo.
To update the app on the server from this repo manually, execute the following on the server:  
```
bash /var/www/html/clone_permissions_venv.sh
```
* ALWAYS EXECUTE THE SCRIPT AS USER "DUMMY"
* USE "BASH" AND NOT "SH"
