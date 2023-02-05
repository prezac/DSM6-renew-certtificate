#!/bin/bash
#
# *** For DSM v6.x ***
#

prefix='notAfter='
SRCDIR='/volume1'
expirecount=10

expirecmd=$(openssl x509 -in /usr/syno/etc/certificate/system/default/cert.pem -dates -noout)
readarray -t lines <<<"$expirecmd"
expire=$(echo "${lines[1]}" | sed -e "s/^$prefix//")
#echo $expire
datnow=$(date '+%Y-%m-%d')
datexpire=$(date -d "$expire" +'%Y-%m-%d')
#echo $datnow
echo $datexpire
daysexpire=$(( ($(date -d "$expire" +%s) - $(date +%s)) / (60*60*24) ))
echo $daysexpire

if [ "$daysexpire" -lt $expirecount ]; then
	REVERSE_PROXY=/usr/syno/etc/certificate/ReverseProxy
	SMBFTP=/usr/syno/etc/certificate/smbftpd/ftpd
	FQDN_DIR=/usr/syno/etc/certificate/system/FQDN
	DEFAULT_DIR=
	DEFAULT_DIR_NAME=$(cat /usr/syno/etc/certificate/_archive/DEFAULT)
	if [ "DEFAULT_DIR_NAME" != "" ]; then
	    DEFAULT_DIR="/usr/syno/etc/certificate/_archive/${DEFAULT_DIR_NAME}"
	fi

	mv $SRCDIR/{privkey,chain,fullchain,cert}.pem /usr/syno/etc/certificate/system/default/
	if [ "$?" != 0 ]; then
	    echo "Halting because of error moving files"
	    exit 1
	fi
	chown root:root /usr/syno/etc/certificate/system/default/{privkey,chain,fullchain,cert}.pem
	if [ "$?" != 0 ]; then
	    echo "Halting because of error chowning files"
	    exit 1
	fi
	echo "Certs moved from $SRCDIR & chowned."

	if [ -d "${FQDN_DIR}/" ]; then
	    echo "Found FQDN directory, copying certificates to 'certificate/system/FQDN' as well..."
	    cp /usr/syno/etc/certificate/system/default/{privkey,chain,fullchain,cert}.pem "${FQDN_DIR}/"
	    chown root:root "${FQDN_DIR}/"{privkey,chain,fullchain,cert}.pem
	fi

	if [ -d "$DEFAULT_DIR" ]; then
	    echo "Found upload dir (used for Application Portal): $DEFAULT_DIR_NAME, copying certs to: $DEFAULT_DIR"
	    cp /usr/syno/etc/certificate/system/default/{privkey,chain,fullchain,cert}.pem "$DEFAULT_DIR/"
	    chown root:root "$DEFAULT_DIR/"{privkey,chain,fullchain,cert}.pem
	else
	    echo "Did not find upload dir (Application Portal): $DEFAULT_DIR_NAME"
	fi

	if [ -d "$SMBFTP" ]; then
	    echo "Found upload dir (used for smbftpd): $SMBFTP, copying certs to: $SMBFTP"
	    cp /usr/syno/etc/certificate/system/default/{privkey,chain,fullchain,cert}.pem "$SMBFTP/"
	    chown root:root "$DEFAULT_DIR/"{privkey,chain,fullchain,cert}.pem
	else
	    echo "Did not find upload dir (SMBFTP): $SMBFTP"
	fi

	if [ -d "$REVERSE_PROXY" ]; then
	    echo "Found reverse proxy certs, replacing those:"
	    for proxy in $(ls "$REVERSE_PROXY"); do
	        echo "Replacing $REVERSE_PROXY/$proxy"
        	cp /usr/syno/etc/certificate/system/default/{privkey,chain,fullchain,cert}.pem "$REVERSE_PROXY/$proxy"
	        chown root:root "$REVERSE_PROXY/$proxy/"{privkey,chain,fullchain,cert}.pem
	    done
	else
	    echo "No reverse proxy directory found"
	fi

	echo -n "Rebooting all the things..."
	/usr/syno/sbin/synoservice --restart nginx
	/usr/syno/sbin/synoservice --restart nmbd
	/usr/syno/sbin/synoservice --restart avahi
	/usr/syno/sbin/synoservice --restart ldap-server
	echo " done"
fi
