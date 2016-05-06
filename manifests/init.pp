# == Class: appserver
#
# Deploy documentum applications on a provisioned tomcat instance
#
class applicationserver (
  $http_port     = "8080",
  $catalina_root = "/u01/app/apache-tomcat"
  )  {
  $catalina_version = "apache-tomcat-7.0.68"
  $catalina_home    = "${catalina_root}/${catalina_version}"
  # set defaults for file ownership/permissions
  File {
    owner   => 'tomcat',
    group   => 'tomcat',
    mode    => '0644',
  }
  
  class { 'tomcat':
    catalina_home  => $catalina_home,
    manage_user    => false,
    manage_group   => false,
  }~>
  tomcat::instance { $catalina_version:
    catalina_base  => $catalina_home,
    catalina_home  => $catalina_home,
    source_url     => "/opt/software/Apache/Tomcat/${catalina_version}.tar.gz",
  }
  # Configuration files for Documentum Applications
  file { 'catalina.properties':
    path    => "${catalina_home}/conf/catalina.properties",
    source  => 'puppet:///modules/applicationserver/catalina.properties',
    require => Tomcat::Instance[$catalina_version],
  }
  file { 'context.xml':
    path    => "${catalina_home}/conf/context.xml",
    source  => 'puppet:///modules/applicationserver/context.xml',
    require => Tomcat::Instance[$catalina_version],
  }
  file { 'web.xml':
    path    => "${catalina_home}/conf/web.xml",
    source  => 'puppet:///modules/applicationserver/web.xml',
    require => Tomcat::Instance[$catalina_version],
  }
  file { 'server.xml':
    ensure    => file,
    path    => "${catalina_home}/conf/server.xml",
    content   => template('applicationserver/server.xml.erb'),
    require => Tomcat::Instance[$catalina_version],
  }

  file { 'setenv.sh':
    path    => "${catalina_home}/bin/setenv.sh",
    source  => 'puppet:///modules/applicationserver/setenv.sh',
    require => Tomcat::Instance[$catalina_version],
  }

  applicationserver::wdkwar { 'da':
    war_source  => '/opt/software/Documentum/D71/da.war',
    webapps_dir => "${catalina_home}/webapps",
    require => Tomcat::Instance[$catalina_version],
  }
  tomcat::service { 'default':
    catalina_base => $catalina_home,
    require         => [
      File [ 'catalina.properties'],
      File [ 'context.xml'],
      File [ 'web.xml'],
      File [ 'server.xml'],
      Applicationserver::Wdkwar[da],
    ]
  }
}
