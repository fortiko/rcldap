#!/bin/bash
# Parameters : USER PASSWORD 
# example : rc_create_user.sh mark xxxx
#
#------------ parameters    start --------------------------------
if [ $# -lt 2 ] ; then
    echo "ERROR - Number of parameters is wrong. Example: rc_create_user.sh user password"
    exit 1
fi

abook_user=$1;
abook_pass=$2;
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

echo "
dn: $bind_dn
cn: $abook_user
userPassword: `slappasswd -s $abook_pass`
objectClass: organizationalRole
objectClass: simpleSecurityObject
" | ldapadd -v -x -c -H $server -D $rootdn -y /root/ldap_masterpass 2> /dev/null ||
  { echo "ERROR-unable to create user!"; exit 1; };
