class credis {
  #$source_package = 'credis-0.2.3.tar.gz'
  $source_package = 'trunk'
  $source_package_url = "https://credis.googlecode.com/files/${source_package}"
  $source_trunk_url = "http://credis.googlecode.com/svn/trunk/"
  $libname = 'libcredis'
  $incdir = '/usr/include'

  case $::osfamily {
    'Debian': {
      $libdir = '/usr/lib'
      $download_command  = 'wget'
    }
    'Redhat': {
      $download_command  = 'curl -O -L'
      if $::hardwaremodel == 'x86_64' {
        $libdir = '/usr/lib64'
      }
      else {
        $libdir = '/usr/lib'
      }
    }
  }

  if $source_package == 'trunk' {
    exec { 'download credis source':
      command => "svn checkout ${source_trunk_url} /tmp/credis_src",
      cwd     => '/tmp',
      unless  => "test -f ${libdir}/$libname.a && test -f ${libdir}/$libname.so",
      notify  => Exec['build credis'],
    }

  } else {
    exec { 'download credis source':
      command => "${download_command} $source_package_url",
      cwd     => '/tmp',
      creates => "/tmp/${source_package}",
      unless  => "test -f ${libdir}/$libname.a && test -f ${libdir}/$libname.so",
      notify  => Exec['extract credis source'],
    }

    exec { 'extract credis source':
      command     => "rm -rf credis_src && mkdir credis_src && tar -C credis_src --strip-components=1 -xzf ${source_package}",
      cwd         => '/tmp',
      refreshonly => true,
      unless      => "test -f ${libdir}/$libname.a && test -f ${libdir}/$libname.so",
      notify      => Exec['build credis'],
    }
  }

  exec { 'build credis':
    command     => "make all",
    cwd         => '/tmp/credis_src',
    refreshonly => true,
    notify      => Exec['copy credis files']
  }
  ->
  exec { 'copy credis files':
    command     => "cp -f /tmp/credis_src/${libname}.* ${libdir} && cp -f /tmp/credis_src/credis.h ${incdir}",
    refreshonly => true,
    notify      => Exec['cleanup credis source']
  }
  ->
  exec { 'cleanup credis source':
    command     => "rm -rf /tmp/credis_src",
    refreshonly => true,
  }
  ->
  file { 'libcredis.a':
    ensure => present,
    path   => "${libdir}/$libname.a",
  }
  ->
  file { 'libcredis.so':
    ensure => present,
    path   => "${libdir}/$libname.so",
  }
}
