#!/usr/bin/env bash -e

HOST=$(echo "$1" | sed -E -e 's/https?:\/\///' -e 's/\/.*//')

if [[ "$HOST" =~ .*\..* ]]; then
    echo "Adding certificate for $HOST"
    echo -n | openssl s_client -connect $HOST:443 -servername $HOST \
        | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' \
        | tee "/tmp/$HOST.cert"
    sudo security add-trusted-cert -d -r trustRoot \
        -k "/Library/Keychains/System.keychain" "/tmp/$HOST.cert"
    rm -v "/tmp/$HOST.cert"
else
    echo "Usage: $0 www.site.name"
    echo "http:// and such will be stripped automatically"
fi

