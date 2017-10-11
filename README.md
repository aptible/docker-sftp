# ![](https://gravatar.com/avatar/11d3bc4c3163e3d238d558d5c9d98efe?s=64) aptible/sftp

[![Docker Repository on Quay.io](https://quay.io/repository/aptible/sftp/status)](https://quay.io/repository/aptible/sftp)

OpenSSH-based SFTP on Docker.

## Installation

    docker pull quay.io/aptible/sftp

This is an image conforming to the [Aptible database specification](https://support.aptible.com/topics/paas/deploy-custom-database/). To run a server for development purposes, execute

    docker create --name data quay.io/aptible/sftp
    docker run --volumes-from data -e USERNAME=aptible -e PASSPHRASE=pass quay.io/aptible/sftp --initialize
    docker run --volumes-from data -P quay.io/aptible/sftp

The first command sets up a data container named `data` which will hold the configuration and data for the database. The second command creates an SFTP instance with an administrator username and passphrase of your choice. The third command starts the database server.

## Usage

The service is designed to run with an initial, password-protected admin user. Additional users can be provisioned at any time by calling `add-sftp-user` with a username and SSH public key.

For example, given the admin user `aptible`, one might run:

    ssh -p <docker-port> aptible@<docker-host>
    sudo add-sftp-user regular-user <ssh-pubkey>

## Available Tags

* `latest`: Currently OpenSSH 6.6.1p1

## Tests

Tests are run as part of the `Dockerfile` build. To execute them separately within a container, run:

    bats test

## Deploying Images To Quay

To push the Docker image to Quay, run the following command:

    make release

## Copyright and License

MIT License, see [LICENSE](LICENSE.md) for details.

Copyright (c) 2015 [Aptible](https://www.aptible.com) and contributors.

[<img src="https://s.gravatar.com/avatar/f7790b867ae619ae0496460aa28c5861?s=60" style="border-radius: 50%;" alt="@fancyremarker" />](https://github.com/fancyremarker)
