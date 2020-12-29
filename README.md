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
To update the app on the server from this repo, execute the following on the server:  
```
sh /var/www/html/clone_permissions_venv.sh
```
  
## Apache enabled mods
```
Loaded Modules:
 core_module (static)
 so_module (static)
 watchdog_module (static)
 http_module (static)
 log_config_module (static)
 logio_module (static)
 version_module (static)
 unixd_module (static)
 access_compat_module (shared)
 alias_module (shared)
 auth_basic_module (shared)
 authn_core_module (shared)
 authn_file_module (shared)
 authz_core_module (shared)
 authz_host_module (shared)
 authz_user_module (shared)
 autoindex_module (shared)
 cgid_module (shared)
 deflate_module (shared)
 dir_module (shared)
 env_module (shared)
 filter_module (shared)
 headers_module (shared)
 mime_module (shared)
 mpm_prefork_module (shared)
 negotiation_module (shared)
 php7_module (shared)
 reqtimeout_module (shared)
 rewrite_module (shared)
 setenvif_module (shared)
 socache_shmcb_module (shared)
 ssl_module (shared)
 status_module (shared)
 wsgi_module (shared)
```
