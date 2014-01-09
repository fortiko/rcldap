0a) initialize ldap server by running
/usr/local/sbin/rc_abook_setup.sh

vi /etc/ldap/slapd.conf
include         /etc/ldap/schema/inetorgperson.schema
include         /etc/ldap/schema/evolutionperson.schema

0b) prepeare davical
http://sourceforge.net/projects/davical-cmdlnut/?source=dlp

cd /usr/local/src
wget "http://downloads.sourceforge.net/project/davical-cmdlnut/1.2.0/davical-cmdlnut_1.2.0_all.deb?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fdavical-cmdlnut%2Ffiles%2F1.2.0%2F&ts=1358557825&use_mirror=ignum"

apt-get install python-egenix-mxdatetime python-egenix-mxtools python-pygresql
dpkg -i davical-cmdlnut_1.2.0_all.deb


1) /usr/local/sbin/ldap_create_user.sh

2) /usr/local/sbin/caldav_create_user.sh 
