# Mochi Spack Buildcache

This repository is a mirror of pre-built Mochi spack packages.
To use this mirror, use the following command with spack.

```
$ spack mirror add mochi oci://ghcr.io/mochi-hpc/mochi-spack-buildcache
```

When using a build cache, you will need to use `--no-check-signature`
when calling `spack install`.
