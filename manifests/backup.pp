class mongodb::backup ($backup_hash = '3fbe30') {

  $backup_host  = hiera('mongo_backup_host', 'localhost')
  $backup_email = hiera('mongo_backup_email', 'root@localhost')
  $backup_user  = hiera('mongo_backup_user', 'false')
  $backup_pass  = hiera('mongo_backup_pass', 'false')
  $backup_dest  = hiera('mongo_backup_dest', '/tmp')

  file { $backup_dest:
    ensure => directory,
    owner => root,
    group => admin,
    mode => 755,
  }

  file { "/etc/automongobackup":
    ensure => directory,
    owner => root,
    group => root,
    mode => 755,
  }

  file { "/etc/default/automongobackup":
    owner   => root,
    group   => root,
    mode    => 644,
    content => template("mongodb/automongobackup.erb"),
  }

  exec { "/etc/automongobackup/automongobackup-${backup_hash}.sh":
    path    => "/bin:/usr/bin:/usr/local/bin",
    cwd     => "/etc/automongobackup",
    command => "wget -q https://github.com/micahwedemeyer/automongobackup/raw/${backup_hash}/src/automongobackup.sh -O automongobackup-${backup_hash}.sh",
    creates => "/etc/automongobackup/automongobackup-${backup_hash}.sh",
    require => File["/etc/automysqlbackup"],
  }

  file { "/etc/automongobackup/automongobackup-${backup_hash}.sh":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => 755,
    require => Exec["/etc/automongobackup/automongobackup-${backup_hash}.sh"],
  }

  file { "/usr/local/bin/automongobackup.sh":
    ensure  => link,
    target  => "/etc/automongobackup/automongobackup-${backup_hash}.sh",
    require => File["/etc/automongobackup/automongobackup-${backup_hash}.sh"],
  }

}

class mongodb::backup::daily {

  include mongodb::backup

  cron { "mongodb-backup-daily":
    ensure   => present,
    command  => "/usr/local/bin/automongobackup.sh > /dev/null 2>&1",
    user     => "root",
    hour     => 3,
    minute   => 30,
    require  => File["/usr/local/bin/automongobackup.sh"],
  }

}