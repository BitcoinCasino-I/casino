# casino  
  
## Server Requirements  
* python3
* python3-dev
* python3-virtualenv
* pip3
* apache2
* libapache2-mod-wsgi-py3
* libmysqlclient-dev
  
## Python Virtual Environment  
Start from /CasinoApp/CasinoApp to install all modules from the requirements.txt:  
  
```
python3 -m venv Casino_vEnv  
source Casino_vEnv/bin/activate  
python3 -m pip install -r .\requirements.txt  
deactivate
```
  
## Example apache vhost
```
<VirtualHost *:80>
                ServerName casino.reshade.io
                ServerAdmin casino@reshade.io
                Redirect permanent / https://casino.reshade.io/
</VirtualHost>

<VirtualHost *:443>
                ServerName casino.reshade.io
                
                SSLEngine On
                SSLCertificateFile /etc/letsencrypt/live/casino.reshade.io/fullchain.pem
                SSLCertificateKeyFile /etc/letsencrypt/live/casino.reshade.io/privkey.pem
                Header always set Strict-Transport-Security "max-age=31536000; includeSubDomain"

                ErrorLog ${APACHE_LOG_DIR}/error.log
                LogLevel warn
                CustomLog ${APACHE_LOG_DIR}/access.log combined
                
                # Include /etc/apache2/le_http_01_challenge_pre.conf

                WSGIScriptAlias / /var/www/html/casino/CasinoApp/casinoapp.wsgi
                <Directory /var/www/html/casino/CasinoApp/CasinoApp/>
                                Order allow,deny
                                Allow from all
                </Directory>
                
                Alias /static /var/www/html/casino/CasinoApp/CasinoApp/static
                <Directory /var/www/html/casino/CasinoApp/CasinoApp/static/>
                                Order allow,deny
                                Allow from all
                </Directory>
                
                <Directory /var/www/html/casino/CasinoApp/CasinoApp/static/uploads/profileimages/>
                                Order allow,deny
                                Allow from all
                </Directory>
                
                # Include /etc/apache2/le_http_01_challenge_post.conf
                
                SSLCertificateFile /etc/letsencrypt/live/casino.reshade.io/fullchain.pem
                SSLCertificateKeyFile /etc/letsencrypt/live/casino.reshade.io/privkey.pem
                Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
```
