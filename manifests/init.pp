# == Class: nodejs
#
# Full description of class nodejs here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { nodejs:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#

class nodejs ($nodejsversion = "v0.10.26", $nodecleanup = "true") {
  case $::operatingsystem {
    'Ubuntu' : {
      $requiredpackages = ["build-essentials", "python", "libssl-dev", "git", "python-software-properties"]

      # Initial quick-n-dirty version was for Ubuntu, the code below should work with the packages above.
      # Please clone, copy-n-paste, test and send a pull request if it works.
    }
    'CentOS' : {
      $requiredpackages = ["kernel-devel", "kernel-headers", "python", "openssl-devel", "git", "gcc-c++"]

      package {$requiredpackages:
        ensure => present,
      }

      Package<||> -> Exec["wget-nodejs"]

      exec { "wget-nodejs":
        command => "wget http://nodejs.org/dist/${nodejsversion}/node-${nodejsversion}.tar.gz",
        cwd     =>"/tmp",
        path    => ["/usr/bin", "/usr/sbin"],
        creates => "/usr/local/bin/node",
      } ->

      exec { "extract-nodejs":
        command => "tar -xvzf node-${nodejsversion}.tar.gz",
        cwd     =>"/tmp",
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
        creates => "/usr/local/bin/node",
      } ->

      notify { "Build & Install Node.js": } ->

      exec { "compile-nodejs":
        command => "/tmp/node-${nodejsversion}/configure && sudo make && sudo make install",
        cwd     => "/tmp/node-${nodejsversion}/",
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
        timeout => 0,
        creates => "/usr/local/bin/node"
      }

      if $nodecleanup == 'true' {
        Exec["compile-nodejs"] -> File["cleanup-nodejs-tmp-dir"] -> File["cleanup-nodejs-tmp-file"]

        file {
          "cleanup-nodejs-tmp-dir":
          path => "/tmp/node-${nodejsversion}/",
          ensure => absent,
          recurse => true,
          force => true;
          "cleanup-nodejs-tmp-file":
          path => "/tmp/node-${nodejsversion}.tar.gz",
          ensure => absent,
          recurse => true,
          force => true;
        } ->

        # to remove a lingering "node-[version].tar.gz.1"
        exec {"rm -f /tmp/node-${nodejsversion}*":
          path => ["/bin"],
        }
      }
    } # end CentOS

    default : {
      fail("Operating system is unsupported.")
    }
  } # end case
}
