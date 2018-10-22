#!/bin/bash
echo "==================================================================================="
echo "==== Kerberos KDC and Kadmin ======================================================"
echo "==================================================================================="
KADMIN_PRINCIPAL_FULL=$KADMIN_PRINCIPAL@$REALM

echo "REALM: $REALM"
echo "KADMIN_PRINCIPAL_FULL: $KADMIN_PRINCIPAL_FULL"
echo "KADMIN_PASSWORD: $KADMIN_PASSWORD"
echo ""

echo "==================================================================================="
echo "==== /etc/krb5.conf ==============================================================="
echo "==================================================================================="
KDC_KADMIN_SERVER=$(hostname -f)
tee /etc/krb5.conf <<EOF
includedir /etc/krb5.conf.d/

[libdefaults]
  renew_lifetime = 7d
  forwardable = true
  default_realm = $REALM
  ticket_lifetime = 24h
  dns_lookup_realm = false
  dns_lookup_kdc = false
  default_ccache_name = /tmp/krb5cc_%{uid}
  #default_tgs_enctypes = aes des3-cbc-sha1 rc4 des-cbc-md5
  #default_tkt_enctypes = aes des3-cbc-sha1 rc4 des-cbc-md5

[logging]
  default = FILE:/var/log/krb5kdc.log
  admin_server = FILE:/var/log/kadmind.log
  kdc = FILE:/var/log/krb5kdc.log

[domain_realm]
  $KDC_DOMAIN = $REALM
  .${KDC_DOMAIN} = $REALM

[realms]
  $REALM = {
    kdc = ${MASTER_KDC}.${KDC_DOMAIN}
    kdc = ${SLAVE_KDC}.${KDC_DOMAIN}
    admin_server = ${KDC_KADMIN_SERVER}
  }
EOF
echo ""

echo "==================================================================================="
echo "==== /var/kerberos/krb5kdc/kadm5.acl =============================================="
echo "==================================================================================="
tee /var/kerberos/krb5kdc/kadm5.acl <<EOF
*/admin@${REALM}    *
EOF
echo ""

echo "==================================================================================="
echo "==== /var/kerberos/krb5kdc/kdc.conf ==============================================="
echo "==================================================================================="
tee /var/kerberos/krb5kdc/kdc.conf <<EOF
[kdcdefaults]
  kdc_ports = 88
  kdc_tcp_ports = 88

[realms]
	$REALM = {
		#master_key_type = aes256-cts
		acl_file = /var/kerberos/krb5kdc/kadm5.acl
		dict_file = /usr/share/dict/words
		admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
		supported_enctypes = $SUPPORTED_ENCRYPTION_TYPES
 	}
EOF
echo ""

echo "==================================================================================="
echo "==== /var/kerberos/krb5kdc/kpropd.acl ============================================="
echo "==================================================================================="
tee /var/kerberos/krb5kdc/kpropd.acl <<EOF
host/${MASTER_KDC}.${KDC_DOMAIN}@${REALM}
host/${SLAVE_KDC}.${KDC_DOMAIN}@${REALM}
EOF
echo ""

echo "==================================================================================="
echo "==== Creating realm ==============================================================="
echo "==================================================================================="
#MASTER_PASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)
# This command also starts the krb5-kdc and krb5-admin-server services
#krb5_newrealm <<EOF
#$MASTER_PASSWORD
#$MASTER_PASSWORD
#EOF
kdb5_util create -s -P $KADMIN_PASSWORD
echo ""


echo "==================================================================================="
echo "==== Create the principals in the acl ============================================="
echo "==================================================================================="
echo "Adding $KADMIN_PRINCIPAL principal"
kadmin.local -q "delete_principal -force $KADMIN_PRINCIPAL_FULL"
echo ""
kadmin.local -q "addprinc -pw $KADMIN_PASSWORD $KADMIN_PRINCIPAL_FULL"
echo ""

echo "==================================================================================="
echo "==== Run the services ============================================================="
echo "==================================================================================="
# We want the container to keep running until we explicitly kill it.
# So the last command cannot immediately exit. See
#   https://docs.docker.com/engine/reference/run/#detached-vs-foreground
# for a better explanation.

systemctl enable krb5kdc
systemctl start krb5kdc
systemctl enable kadmin
systemctl start kadmin

krb5kdc
kadmind -nofork