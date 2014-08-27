docker-reprepro
===============
Reprepro (Debian packages repository) docker container.



Build
-----

To create the image `bbinet/reprepro`, execute the following command in the
`docker-reprepro` folder:

    docker build -t bbinet/reprepro .

You can now push the new image to the public registry:
    
    docker push bbinet/reprepro


Run
---

Then, when starting your reprepro container, you will want to bind ports `22`
from the reprepro container to a host external port.
The reprepro container will create the debian repository to a volume in
`/data`, so you need to bind this data volume to a host directory or a data
container.
If the `debian/` directory doesn't already exist in the `/data/` volume,
docker-reprepro will generate a debian repository with some default
configuration. If you want to customize the reprepro configuration, feel free
to provide your own debian reprepro setup in `/data/debian/`.

You also need to provide a read-only `/config` volume that should contain:
  - the `/config/authorized_keys` file that will be use to allow both users
    "reprepro" and "apt" to ssh to this container based on their public ssh
    key.
  - the `/config/reprepro_pub.gpg` and `/config/reprepro_sec.gpg` gpg public
    and private keys that will be use to sign debian packages.

For example:

    $ docker pull bbinet/reprepro

    $ docker run --name reprepro \
        -v /home/reprepro/data:/data \
        -v /home/reprepro/config:/config \
        -p 22:22 \
        bbinet/reprepro
