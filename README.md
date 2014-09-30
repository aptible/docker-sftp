# ![](https://gravatar.com/avatar/11d3bc4c3163e3d238d558d5c9d98efe?s=64) aptible/sftp

[![Docker Repository on Quay.io](https://quay.io/repository/aptible/sftp/status)](https://quay.io/repository/aptible/sftp)

OpenSSH-based SFTP on Docker.

## Installation and Usage

    docker pull quay.io/aptible/sftp
    docker run quay.io/aptible/sftp

### Specifying a user/password at runtime

    docker run -e USERNAME=aptible PASSWORD=foobar docker run quay.io/aptible/sftp

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

Copyright (c) 2014 [Aptible](https://www.aptible.com), [Frank Macreery](https://github.com/fancyremarker), and contributors.
