# == Class: pypolicyd_spf::params
#
# Params class for pypolicyd_spf.
#
# === Authors
#
# Scott Barr <gsbarr@gmail.com>
#
class pypolicyd_spf::params 
{
  $project_url   = 'https://launchpad.net/pypolicyd-spf'
  $source_path   = '/usr/local/src'
  $tarball_path  = "${source_path}/pypolicyd-spf.tar.gz"
  $install_path  = "${source_path}/pypolicyd-spf"
  $confdir       = '/etc/python-policyd-spf'

  case $::osfamily {
      "Debian": {
      	$dependencies = ['python-ipaddr', 'spf-tools-python']
      }
      "Redhat": {
      	$dependencies = ['python-ipaddr','python-pyspf']
      }
      default: {
         fail("${::operatingsystem} is not supported.")
      }
  }
}