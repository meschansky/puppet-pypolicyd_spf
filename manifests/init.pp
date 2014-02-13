# == Class: pypolicyd_spf
#
# Install and configures pypolicyd_spf (http://www.openspf.org/Software).
#
# === Parameters
#
# [*ensure*]
#   Present or absent
#
# [*version*]
#   Specify version to install. Default: 1.2.
#
# [*debuglevel*]
#   Controls the amount of information logged by the policy server. Value: 0-5
#
# [*defaultseedonly*]
#   The policy server can operate in a test only mode.  To enable it, set = 0.
#
# [*helo_reject*]
#   HELO check rejection policy. Values: SPF_Not_Pass (default), Softfail, Fail,
#   Null, False or No_Check.
#
# [*mail_from_reject*]
#   Mail From rejection policy. Values: SPF_Not_Pass (default), Softfail, Fail,
#   Null, False or No_Check.
#
# [*permerror_reject*]
#   Policy for rejecting due to SPF PermError. Value: true or false.
#
# [*temperror_defer*]
#   Policy for deferring messages due to SPF TempError. Value: true or false.
#
# [*skip_addresses*]
#   A comma separated CIDR Notation list of IP addresses to skip SPF checks.
#
# === Examples
#
#  See tests folder
#
# === Authors
#
# Scott Barr <gsbarr@gmail.com>
#
class pypolicyd_spf (
	$ensure           = 'present',
  $version          = '1.2',
	$debuglevel 	    = 1,
	$defaultseedonly  = 1,
	$helo_reject	    = 'SPF_Not_Pass',
	$mail_from_reject = 'Fail',
	$permerror_reject = false,
	$temperror_defer  = false,
	$skip_addresses   = '127.0.0.0/8,::ffff:127.0.0.0//104,::1//128'
) {
  include pypolicyd_spf::params

  validate_re($ensure, '^(present|absent)$',
  'ensure parameter must have a value of: present or absent')

  validate_re($version, '^([0-9]+\.?){1,3}$',
  'version should be a number')

  validate_re($debuglevel, '^[0-5]$',
  'debuglevel should be a number between 0 and 5')

  validate_re($defaultseedonly, '^[0-1]$',
  'debuglevel should be zero or one')

  validate_re($helo_reject, '^(SPF_Not_Pass|Softfail|Fail|Null|False|No_Check)$',
  'helo_reject parameter value validation failed. Please check documentation.')

  validate_re($mail_from_reject, '^(SPF_Not_Pass|Softfail|Fail|Null|False|No_Check)$',
  'mail_from_reject parameter value validation failed. Please check documentation.')

  validate_bool($permerror_reject)
  validate_bool($temperror_defer)

  $version_numbers = split($version, '[.]')

  if count($version_numbers) > 2 {
    $series  = "${version_numbers[0]}.${version_numbers[1]}"
    $release = "${series}.${version_numbers[2]}"

    $download_url = "${pypolicyd_spf::params::project_url}/${series}/${release}/+download/pypolicyd-spf-${version}.tar.gz"
  } else {
    $download_url = "${pypolicyd_spf::params::project_url}/${version}/${version}/+download/pypolicyd-spf-${version}.tar.gz"
  }

  package { $pypolicyd_spf::params::dependencies:
    ensure => 'installed',
  }

  Exec {
    path => ['/bin', '/usr/bin', '/usr/sbin'],
  }

  if $ensure == 'present' {
    exec { 'pypolicyd_spf_download':
      command => "wget --no-verbose --output-document=${pypolicyd_spf::params::tarball_path} ${download_url}",
      timeout => 0,
      unless  => "test -s ${pypolicyd_spf::params::tarball_path} && 
                  test \"\$(wget -qO - ${download_url}/+md5 | awk '{print \$1}')\" = \"\$(md5sum ${pypolicyd_spf::params::tarball_path} | awk '{print \$1}')\"",
    }
    exec { 'pypolicyd_spf_extract':
      command     => "[ -d \"${pypolicyd_spf::params::install_path}\" ] && rm -rf \"${pypolicyd_spf::params::install_path}\";
   tar zxf ${pypolicyd_spf::params::tarball_path} -C ${pypolicyd_spf::params::source_path} &&
   mv `find ${pypolicyd_spf::params::source_path} -mindepth 1 -maxdepth 1 -type d | grep -i pypolicyd-spf` ${pypolicyd_spf::params::install_path}",
      creates     => $pypolicyd_spf::params::install_path,
      before      => File[$pypolicyd_spf::params::install_path],
      subscribe   => Exec['pypolicyd_spf_download'],
      refreshonly => true,
    }
    exec { 'pypolicyd_spf_build':
      cwd         => $pypolicyd_spf::params::install_path,
      command     => 'python setup.py build',
      creates     => "${pypolicyd_spf::params::install_path}/build",
      subscribe   => Exec['pypolicyd_spf_extract'],
      refreshonly => true,
      require     => Package[$pypolicyd_spf::params::dependencies],
    }
    exec { 'pypolicyd_spf_install':
      cwd         => $pypolicyd_spf::params::install_path,
      command     => "python setup.py install --prefix=/usr --record ${$pypolicyd_spf::params::source_path}/pypolicyd_spf_files.txt",
      creates     => '/usr/bin/policyd-spf',
      subscribe   => Exec['pypolicyd_spf_build'],
      refreshonly => true,
      before      => File["${pypolicyd_spf::params::confdir}/policyd-spf.conf"],
    }  
  }
  else {
    exec { 'pypolicyd_spf_remove':
      cwd     => $pypolicyd_spf::params::source_path,
      command => "cat pypolicyd_spf_files.txt | xargs rm -rf",
      onlyif  => "test -s ${$pypolicyd_spf::params::source_path}/pypolicyd_spf_files.txt",
    }
    exec { 'pypolicyd_spf_remove_filelist':
      command => "rm ${$pypolicyd_spf::params::source_path}/pypolicyd_spf_files.txt",
      onlyif  => "test -s ${$pypolicyd_spf::params::source_path}/pypolicyd_spf_files.txt",
    }
  }
  
  $purge = $ensure ? {
    absent  => true,
    default => false,
  }

  $directory_ensure = $ensure ? {
    present => directory,
    default => $ensure,
  }

  file { $pypolicyd_spf::params::install_path:
    ensure  => $directory_ensure,
    recurse => true,
    purge   => $purge,
    force   => $purge,
  }
  file { $pypolicyd_spf::params::confdir:
    ensure  => $directory_ensure,
    recurse => true,
    purge   => $purge,
    force   => $purge,
  }
  file { "${pypolicyd_spf::params::confdir}/policyd-spf.conf" :
    ensure    => $ensure,
    mode      => '0644',
    content   => template('pypolicyd_spf/config.erb'),
    subscribe => Exec['pypolicyd_spf_install'],
  }
}
