puppet-pypolicyd_spf
====================

Install and configures pypolicyd_spf (http://www.openspf.org/Software).

## Description

The module will fetch a versioned tar.gz file from the launchpad project site, build it and install it. It also supports the installation of different versions as found on the project download page (https://launchpad.net/pypolicyd-spf/+download) and configuration of the various directives found in the config file.


## Usage

class { 'pypolicyd_spf':
}

This will install version 1.2 with the default configuration settings. See the tests folder for more options/examples.

## Limitations

* This module has been tested on Debian Wheezy and Centos 6.4.
* Module relies on the locally installed wget binary, which is not managed.
* On Redhat systems the dependency 'python-pyspf' is found in EPEL, which is not managed by this module. See https://forge.puppetlabs.com/stahnma/epel.