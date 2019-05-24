Balena-digi manifest
====================

This repository contains the manifest files for the balenaOS distribution for [Digi's Embedded modules](https://www.digi.com/products/embedded-systems).

Installing balena-digi
----------------------

To download balena-digi, you need the repo tool.

Follow these steps to install BalenaOS:

1. Download repo to a directory within your path and add execution permissions.

```
$ sudo curl -o /usr/local/bin/repo http://commondatastorage.googleapis.com/git-repo-downloads/repo
$ sudo chmod a+x /usr/local/bin/repo
```

2. Create an installation folder with user write permissions; for example, /usr/local/balena-digi. Navigate to that folder:

```
$ sudo install -o <your-user> -g <your-group> -d /usr/local/balena-digi
$ cd /usr/local/balena-digi
```

Note: You can get your primary user and group using the id command.

3. Use repo to download balena-digi.

```
$ repo init -u https://github.com/alexgg/balena-digi-manifest.git -b master
$ repo sync -j8 --no-repo-verify
```

4. Build

```
$ ./balena-yocto-scripts/build/barys
```
