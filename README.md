# Mochi Spack Buildcache

This repository is a mirror of pre-built Mochi spack packages.

## How to use

To use this mirror, you may use the following command with spack to
make the mirror available globally to all your spack environments.

```
$ spack mirror add --unsigned mochi oci://ghcr.io/mochi-hpc/mochi-spack-buildcache
```

Alternatively, you can also add the following in a spack.yaml
file for an environment. This will make the mirror visible to that
environment only.

```
spack:
  ...
  mirror:
    mochi:
      url: oci://ghcr.io/mochi-hpc/mochi-spack-buildcache
      signed: false
```

## Contributing

### From another Mochi repository

To allow another repository inside the [mochi-hpc](https://github.com/mochi-hpc)
organization to push specs to the buildcache from a github action,
follow the steps hereafter.

First, navigate to the buildcache's
[settings](https://github.com/orgs/mochi-hpc/packages/container/mochi-spack-buildcache/settings)
and on the right of Manage Actions access, click the Add Repository button. Select the
repository to add, and once it appears on the list bellow, change its role to "Write".

Then, in your project's github repository, write a `spack.yaml` file to be used
for building your project's dependencies. Here is an example to start from:

```
spack:
    specs:
    - mochi-margo
    - mercury~checksum~boostsys ^libfabric fabrics=tcp,rxm
    concretizer:
      unify: true
      reuse: true
    modules:
      prefix_inspections:
        lib: [LD_LIBRARY_PATH]
        lib64: [LD_LIBRARY_PATH]
    mirrors:
      mochi:
        url: oci://ghcr.io/mochi-hpc/mochi-spack-buildcache
        signed: false
    config:
      install_tree:
        padded_length: 128
```

Make sure the mochi mirror is listed and `config:install_tree:padded_length` is set to 128.
Add any specs you may need. This environment file will allow github actions that use it to
rely on the buildcache to pull dependencies.

Finally, here is an example of a github action that installs an environment
from the spack.yaml file (which is assumed to live in a `tests` folder, but
you can change that in via the `ENVNAME` environment variable at the beginning
of the file) and pushes its installed specs to the cache.

```
name: Build

env:
  ENVNAME: tests

on:
  workflow_dispatch: {}
  push:
    branches:
    - main
  pull_request:
    branches:
    - main

jobs:
  build:
    runs-on: ubuntu-22.04
    permissions:
      packages: write
    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Setup spack
      uses: spack/setup-spack@v2.1.1
      with:
        ref: develop
        color: true
        path: spack

    - name: Add mochi-spack-packages
      run: |
        git clone https://github.com/mochi-hpc/mochi-spack-packages
        spack -e $ENVNAME repo add mochi-spack-packages

    - name: Install spack environment
      run: |
        spack -e $ENVNAME install

    - name: Show spack-installed packages for debugging
      run: |
        spack -e $ENVNAME find -dlv

    - name: Extra steps
      run: |
        echo "Put more steps here such as building/testing your code"

    - name: Push packages to buildcache and update index
      if: ${{ !cancelled() }}
      run: |
        spack -e $ENVNAME mirror set --push \
          --oci-username ${{ github.actor }} \
          --oci-password "${{ secrets.GITHUB_TOKEN }}" mochi
        spack -e $ENVNAME buildcache push --base-image ubuntu:22.04 \
          --unsigned --update-index mochi
```

### Manually

You may sometimes want to manually push some specs to the cache, for
instance if these specs have been build on a supercomputer and you want
to cache them. To do so, follow the steps hereafter.

First, you need to be a member of the
[mochi-buildcache-maintainers](https://github.com/orgs/mochi-hpc/teams/mochi-buildcache-maintainers)
team. If you are not, request to be added by posting an issue on this repository.

Second, in your [Developer Settings](https://github.com/settings/apps),
click "Personal access tokens" on the left, then "Tokens (classic)".
Click "Generate new token" > "Generate new token (classic)".
Call your token `MOCHI_BUILDCACHE_TOKEN`, set an appropriate expiration,
then select `write:packages` as scope. Click the "Generate token" button at
the bottom of the page, then copy your token.

Warning: tokens are like passwords that, combined with your username,
will allow anyone who has it to perform the operations it was given the scope for.
Hence, make sure not to publish your token anywhere public and if you do by mistake,
revoke the token immediately by going back to the above page and deleting it.

Now that you have your token, create an environment from a `spack.yaml` file
(see above for an example, make sure you have the `mirrors` entry and the
 `config:install_tree:padded_length` set to 128). Activate your environment
and install the specs that it defines.

Still with the environment activated, you can now add the token to your mirror
setup as follows (replacing `<username>` and `<token>` with your github username
and your generated token).

```
$ spack mirror set --push --oci-username <username> --oci-password <token> mochi
```

This will add the token (in clear) in a file in the currently activated
environment, hence remember the warning above and make sure that your spack
installation (or wherever your environment lives) is correctly protected.

You can now push push specs into the buildcache.

```
$ spack buildcache push --update-index --unsigned mochi <specs...>
```

Ommitting the specs will push all the specs from the environment.

For a more details about the way buildcache work, please refer to
the [spack documentation](https://spack.readthedocs.io/en/latest/binary_caches.html).
