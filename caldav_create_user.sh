#!/bin/bash
# Parameters : USER PASSWORD 
# example : rc_create_user.sh mark xxxx
#
#------------ parameters    start --------------------------------
if [ $# -lt 2 ] ; then
    echo "ERROR - Number of parameters is wrong. Example: caldav_create_user.sh user password"
    exit 1
fi

username=$1;
password=$2;
# optionally, we could use "full name" from roundcube here
fullname=$3
#------------ parameters    end   --------------------------------

#------------ configuration start --------------------------------
server="ldap://localhost:389";
suffix="dc=hostname,dc=tld";
rootdn="cn=admin,$suffix";

abook_name="rcabook";

subdir_public="public";
subdir_private="private";

base_dn="ou=$subdir_private,ou=$abook_name,$suffix";
#base_dn="ou=$abook_name,$suffix";
bind_dn="cn=$abook_user,$base_dn";
bind_pass="$abook_pass";
#------------ configuration end --------------------------------

#echo "
#dn: $bind_dn
#cn: $abook_user
#userPassword: `slappasswd -s $abook_pass`
#objectClass: organizationalRole
#objectClass: simpleSecurityObject
#" | ldapadd -v -x -c -H $server -D $rootdn -W 2> /dev/null ||
#  { echo "ERROR-unable to create user!"; exit 1; };

locale="en"
dateformat="E"
# does not work ATM, but is European by default anyway:
# --dateformat "E" 
/usr/bin/davical-cmdlnutl -v --user "$username" --create --fullname "$username" --email "$username" --principaltype "Person" --password "$password" --locale "$locale" || { echo "ERROR-unable to create user!"; exit 1; };

# add default collections
# http://wiki.davical.org/w/Configuration/settings/default_collections
calendar="home"
addressbook="addressbook"
davical-cmdlnutl -v --user "$username" --create --collectiontype "calendar" --collection "$calendar" --label "Calendar"
davical-cmdlnutl -v --user "$username" --create --collectiontype "addressbook" --collection "$addressbook" --label "Addressbook"
