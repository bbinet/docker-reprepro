docker-reprepro
===============
Reprepro (Debian packages repository) docker container.

Here is a good reference documentation to setup a full reprepro environment:
http://vincent.bernat.im/en/blog/2014-local-apt-repositories.html


Build
-----

To create the image `bbinet/reprepro`, execute the following command in the
`docker-reprepro` folder:

    docker build -t bbinet/reprepro .

You can now push the new image to the public registry:
    
    docker push bbinet/reprepro


Run
---

To configure your reprepro container, you need to provide a read-only `/config`
volume that should contain 4 files:

  - `/config/apt-authorized_keys`: ssh authorized_keys file for the apt user
    which should be used when running `apt-get` commands.
    Should be chown root:root and chmod 644.
  - `/config/reprepro-authorized_keys`: ssh authorized_keys file for the
    reprepro user which should be used to upload debian packages with the
    `dput` command.
    Should be chown root:root and chmod 644.
  - `/config/reprepro_pub.gpg`: gpg public key to be used to sign debian
    packages.
    Should be chown 600:root and chmod 600.
  - `/config/reprepro_sec.gpg`: gpg private key to be used to sign debian
    packages.
    Should be chown 600:root and chmod 600.

You also need to provide a read-write `/data` volume, which will be used to
write the debian packages reprepro database, and the `.gnupg/` directory for
imported gpg keys.

If the `debian/` directory doesn't already exist in the `/data/` volume,
docker-reprepro will setup a reprepro repository based on configuration
available through environment variables (see `docker run` example below).

If you want to further customize the reprepro configuration, feel free to
provide your own debian reprepro setup in `/data/debian/`.

Then, when starting your reprepro container, you will want to bind ports `22`
from the reprepro container to a host external port, so that it is accessible
from `dput` (upload packages) and `apt-get` (download packages) through ssh.

For example:

    $ docker pull bbinet/reprepro

    $ docker run --name reprepro \
        -v /home/reprepro/data:/data \
        -v /home/reprepro/config:/config:ro \
        -e RPP_DISTRIBUTIONS="wdev;wprod;jdev;jprod" \
        -e RPP_CODENAME_wdev="wheezy-dev" \
        -e RPP_CODENAME_wprod="wheezy-prod" \
        -e RPP_CODENAME_jdev="jessie-dev" \
        -e RPP_CODENAME_jprod="jessie-prod" \
        -e RPP_ARCHITECTURES_wdev="amd64 armhf source" \
        -e RPP_ARCHITECTURES_wprod="amd64 armhf source" \
        -e RPP_ARCHITECTURES_jdev="amd64 armhf source" \
        -e RPP_ARCHITECTURES_jprod="amd64 armhf source" \
        -e RPP_INCOMINGS="in_wheezy;in_jessie" \
        -e RPP_ALLOW_in_wheezy="stable>wheezy-dev" \
        -e RPP_ALLOW_in_jessie="stable>jessie-dev" \
        -p 22:22 \
        bbinet/reprepro

Usage
-----

Here is how .dput.cf and sources.list can look like:

.dput.cf:
```
[in_wheezy]
fqdn = <reprepro_ip_address>
incoming = /data/debian/incoming/in_wheezy
method = scp
login = reprepro
allow_unsigned_uploads = 0
allowed_distributions = stable
post_upload_command = ssh %(login)s@%(fqdn)s reprepro processincoming in_wheezy
```

sources.list:
```
deb ssh://apt@<reprepro_ip_address>/data/debian wheezy main
```
