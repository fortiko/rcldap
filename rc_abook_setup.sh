#!/bin/bash
#------------configuration--------------------------------

# the url of the openldap server
server="ldap://localhost:389";

# the static config file of openldap
config="/etc/ldap/slapd.conf";

# the LDAP base suffix and admin rootdn
# -> this must correspond with /etc/ldap/slapd.conf
suffix="dc=hostname,dc=tld";
rootdn="cn=admin,$suffix";
organisation="Qustodium LDAP Addressbook Server";

# the addressbook base directory, bind user and password
# -> the base/bind_* fields must correspond with config/main.inc.php
abook_name="rcabook";
abook_user="rcuser";
abook_pass="rcpass";
base_dn="ou=$abook_name,$suffix";
bind_dn="cn=$abook_user,$base_dn";
bind_pass="$abook_pass";

subdir_public="public";
subdir_private="private";


#------------execution------------------------------------
echo "This script prepares an openLDAP server for a simple
addressbook, working \"out of the box\" with Roundcube:

  server: $server
  org   : $organisation
  config: $config
  suffix: $suffix
  rootdn: $rootdn
";

# test if the user has read access to the config file
slapacl -f $config -D $rootdn -b $suffix ou/write 2>&1 |
grep -q "Permission denied" &&
{
  echo "ERROR-you have no read access to the config file: $config
please try to run with \"sudo\" or even as root!
";
  exit 1;
}

# test if the openLDAP root suffix exists
slapacl -f $config -D $rootdn -b $suffix ou/write 2>&1 |
grep -q -E "ALLOWED|DENIED" || 
{
  echo -n "-create the openLDAP base directory: $suffix
  (as LDAP administator: $rootdn)
  ";
  suffix_short=${suffix%,*};
  echo "
dn: $suffix
objectClass: top
objectClass: dcObject
objectClass: organization
${suffix_short%=*}: ${suffix_short#*=}
o: $organisation
" | ldapadd -x -c -H $server -D $rootdn -W 2> /dev/null ||
  { echo "ERROR-unable to create suffix!"; exit 1; };
}

# test if the openLDAP admin has write permissions
slapacl -f $config -D $rootdn -b $suffix ou/write 2>&1 |
grep -q "ALLOWED" || 
{
  echo "ERROR-the administrator \"$rootdn\" has no
write permissions in the base of \"$suffix\"!
Please check the rootdn and suffix, they must correspond
with the openLDAP coniguration file, usually /etc/ldap/slapd.conf
";
  exit 1;
}

# test if the addressbook directory exist
slapacl -f $config -D $rootdn -b $base_dn ou/write 2>&1 |
grep -q "ALLOWED" ||
{
  echo -n "-create addressbook base directory: $base_dn
  (as LDAP administator: $rootdn)
  ";
  echo "
dn: $base_dn
ou: $abook_name
objectClass: top
objectClass: organizationalUnit
" | ldapadd -x -c -H $server -D $rootdn -W 2> /dev/null ||
  { echo "ERROR-unable to create base!"; exit 1; };
}

# test if the addressbook user exist
slapacl -f $config -D $rootdn -b $bind_dn cn/write 2>&1 |
grep -q "ALLOWED" ||
{
  echo -n "-create the addressbook user: $bind_dn
  (as LDAP administator: $rootdn)
  ";
  echo "
dn: $bind_dn
cn: $abook_user
userPassword: `slappasswd -s $abook_pass`
objectClass: organizationalRole
objectClass: simpleSecurityObject
" | ldapadd -x -c -H $server -D $rootdn -W 2> /dev/null ||
  { echo "ERROR-unable to create user!"; exit 1; };
}

# test if the addressbook user has write permissions
slapacl -f $config -D $bind_dn -b $base_dn ou/write 2>&1 |
grep -q "ALLOWED" ||
{ 
  echo "ERROR-the addressbook user \"$bind_dn\"
has no write permissions to \"$base_dn\"!
Please check the ACL in the coniguration file,
usually /etc/ldap/slapd.conf.
Do not forget to restart the server afterwards!
";
  exit 1;
}

# create subdirectory for public contacts
slapacl -f $config -D $bind_dn -b "ou=$subdir_public,$base_dn" ou/write 2>&1 |
grep -q "ALLOWED" ||
{ 
  echo "-create subdirectory for public contacts: ou=$subdir_public,$base_dn
  (as Roundcube user: $bind_dn)";
  echo "
dn: ou=$subdir_public,$base_dn
ou: $subdir_public
objectClass: top
objectClass: organizationalUnit
" | ldapadd -x -H $server -D $bind_dn -w $bind_pass 2> /dev/null ||
  { echo "ERROR-unable to create subdirectory!"; exit 1; };
}

# create subdirectory for private addressbooks
slapacl -f $config -D $bind_dn -b "ou=$subdir_private,$base_dn" ou/write 2>&1 |
grep -q "ALLOWED" ||
{ 
  echo "-create subdirectory for private addressbooks: ou=$subdir_private,$base_dn
  (as Roundcube user: $bind_dn)";
  echo "
dn: ou=$subdir_private,$base_dn
ou: $subdir_private
objectClass: top
objectClass: organizationalUnit
" | ldapadd -x -H $server -D $bind_dn -w $bind_pass 2> /dev/null ||
  { echo "ERROR-unable to create subdirectory!"; exit 1; };
}

# finally 
echo "The LDAP addressbook is ready now for using:
  base_dn: $base_dn
  bind_dn: $bind_dn
  
Use the following command for reading and checking your setup:
  ldapsearch -xLLL -H $server -D $bind_dn -w $bind_pass -b $base_dn";
