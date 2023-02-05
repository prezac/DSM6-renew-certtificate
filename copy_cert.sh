#!/bin/bash
prefix='notAfter='
DOMAIN='www.mydomain.net'
DESTDIR='/mnt/mydestdir'
expirecount=30

SCRIPTDIR1=$(readlink -f /etc/letsencrypt/live/$DOMAIN/cert.pem)
SCRIPTDIR2=$(readlink -f /etc/letsencrypt/live/$DOMAIN/chain.pem)
SCRIPTDIR3=$(readlink -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem)
SCRIPTDIR4=$(readlink -f /etc/letsencrypt/live/$DOMAIN/privkey.pem)
expirecmd=$(openssl x509 -in $SCRIPTDIR1 -dates -noout)
readarray -t lines <<<"$expirecmd"
expire=$(echo "${lines[1]}" | sed -e "s/^$prefix//")
#echo $expire
datnow=$(date '+%Y-%m-%d')
datexpire=$(date -d "$expire" +'%Y-%m-%d')
#echo $datnow
#echo $datexpire
daysexpire=$(( ($(date -d "$expire" +%s) - $(date +%s)) / (60*60*24) ))
#echo $daysexpire
if [ "$daysexpire" -lt $expirecount ]; then
	cp $SCRIPTDIR1 $DESTDIR/cert.pem
	cp $SCRIPTDIR2 $DESTDIR/chain.pem
	cp $SCRIPTDIR3 $DESTDIR/fullchain.pem
	cp $SCRIPTDIR4 $DESTDIR/privkey.pem
fi
