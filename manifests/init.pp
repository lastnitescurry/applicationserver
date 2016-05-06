# == Class: appserver
#
# Deploy documentum applications on a provisioned tomcat instance
#
class applicationserver (
  $http_port     = "8080",
  $catalina_root = "/u01/app/apache-tomcat"
  )  {
  $catalina_home = "${catalina_root}/apache-tomcat-7.0.65"
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
  tomcat::instance { 'apache-tomcat-7.0.65':
    catalina_base  => $catalina_home,
    catalina_home  => $catalina_home,
    source_url     => '/opt/software/Apache/Tomcat/apache-tomcat-7.0.65.tar.gz',
  }
  # Configuration files for Documentum Applications
  file { 'catalina.properties':
    path    => "${catalina_home}/conf/catalina.properties",
    source  => 'puppet:///modules/applicationserver/catalina.properties',
    require => Tomcat::Instance['apache-tomcat-7.0.65'],
  }
  file { 'context.xml':
    path    => "${catalina_home}/conf/context.xml",
    source  => 'puppet:///modules/applicationserver/context.xml',
    require => Tomcat::Instance['apache-tomcat-7.0.65'],
  }
  file { 'web.xml':
    path    => "${catalina_home}/conf/web.xml",
    source  => 'puppet:///modules/applicationserver/web.xml',
    require => Tomcat::Instance['apache-tomcat-7.0.65'],
  }
  file { 'server.xml':
    ensure    => file,
    path    => "${catalina_home}/conf/server.xml",
    content   => template('applicationserver/server.xml.erb'),
    require => Tomcat::Instance['apache-tomcat-7.0.65'],
  }

  file { 'setenv.sh':
    path    => "${catalina_home}/bin/setenv.sh",
    source  => 'puppet:///modules/applicationserver/setenv.sh',
    require => Tomcat::Instance['apache-tomcat-7.0.65'],
  }

  applicationserver::wdkwar { 'da':
    war_source  => '/opt/software/Documentum/D71/da.war',
    webapps_dir => "${catalina_home}/webapps",
    require => Tomcat::Instance['apache-tomcat-7.0.65'],
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
