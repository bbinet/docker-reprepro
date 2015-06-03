#!/bin/bash

set -m

export GNUPGHOME="/data/.gnupg"

if [ -f "/config/reprepro_sec.gpg" ]
then
    perms=$(stat -c %a /config/reprepro_sec.gpg)
    if [ "${perms: -1}" != "0" ]
    then
        echo "/config/reprepro_sec.gpg gnupg private key should not be readable by others..."
        echo "=> Aborting!"
        exit 1
    fi
fi
if [ -d "${GNUPGHOME}" ]
then
    echo "=> /data/.gnupg directory already exists:"
    echo "   So gnupg seems to be already configured, nothing to do..."
else
    echo "=> /data/.gnupg directory does not exist:"
    echo "   Configuring gnupg for reprepro user..."
    gpg --import /config/reprepro_pub.gpg
    if [ $? -ne 0 ]; then
        echo "=> Failed to import gnupg public key for reprepro..."
        echo "=> Aborting!"
        exit 1
    fi
    gpg --allow-secret-key-import --import /config/reprepro_sec.gpg
    if [ $? -ne 0 ]; then
        echo "=> Failed to import gnupg private key for reprepro..."
        echo "=> Aborting!"
        exit 1
    fi
    chown -R reprepro:reprepro ${GNUPGHOME}
fi

if [ -d "/data/debian" ]
then
    echo "=> /data/debian directory already exists:"
    echo "   So reprepro seems to be already configured, nothing to do..."
else
    echo "=> /data/debian directory does not exist:"
    echo "   Configuring a default debian repository with reprepro..."

    keyid=$(gpg --dry-run /config/reprepro_pub.gpg | grep "^pub " | sed "s/.*\/\([^ ]*\).*/\1/")
    if [ -z "$keyid" ]
    then
        echo "=> Please provide /config/reprepro_pub.gpg file to guess the key id to use for reprepro to sign pakages..."
        echo "=> Aborting!"
        exit 1
    fi

    mkdir -p /data/debian/{tmp,incoming,conf}

    cat << EOF > /data/debian/conf/options
verbose
basedir /data/debian
gnupghome ${GNUPGHOME}
ask-passphrase
EOF

    for dist in $(echo ${RPP_DISTRIBUTIONS} | tr ";" "\n"); do
        dcodename_var="RPP_CODENAME_${dist}"
        darchs_var="RPP_ARCHITECTURES_${dist}"
        dcomps_var="RPP_COMPONENTS_${dist}"
        dcodename="${!dcodename_var}"
        if [ -z "${dcodename}" ]; then
            echo "=> No codename supplied for distribution ${dist}: falling back to ${dist} codename"
            dcodename=${dist}
        fi
        cat << EOF >> /data/debian/conf/distributions
Origin: ${REPREPRO_DEFAULT_NAME}
Label: ${REPREPRO_DEFAULT_NAME}
Codename: ${dcodename}
Architectures: ${!darchs_var:-"i386 amd64 armhf source"}
Components: ${!dcomps_var:-"main"}
Description: ${REPREPRO_DEFAULT_NAME} debian repository
DebOverride: override.${dist}
DscOverride: override.${dist}
SignWith: ${keyid}

EOF
        touch /data/debian/conf/override.${dist}
    done

    for incoming in $(echo ${RPP_INCOMINGS} | tr ";" "\n"); do
        iallow_var="RPP_ALLOW_${incoming}"
        mkdir -p /data/debian/incoming/${incoming} /data/debian/tmp/${incoming}
        cat << EOF >> /data/debian/conf/incoming
Name: ${incoming}
IncomingDir: /data/debian/incoming/${incoming}
TempDir: /data/debian/tmp/${incoming}
Allow: ${!iallow_var}
Cleanup: on_deny on_error

EOF
    done
    chown -R reprepro:reprepro /data/debian
fi

echo "=> Starting SSH server..."
exec /usr/sbin/sshd -f /sshd_config -D -e

