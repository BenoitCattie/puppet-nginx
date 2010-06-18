# Class: nginx
#
# Install nginx.
# Create config directories :
#	* /etc/nginx/conf.d for http config snippet
#	* /etc/nginx/includes for sites includes
#
# Provide 3 definitions : 
#	* nginx::config (http config snippet)
#	* nginx::site (http site)
#	* nginx::site_include (site includes)
#
# Templates:
# 	- nginx.conf.erb => /etc/nginx/nginx.conf
#
$nginx_includes = "/etc/nginx/includes"
$nginx_conf = "/etc/nginx/conf.d"

class nginx {


	package { nginx: ensure => installed }

	service { nginx:
        	ensure => running,
        	enable => true,
		hasrestart => true,
		require => File["/etc/nginx/nginx.conf"],
	}

        file { "/etc/nginx/nginx.conf":
		ensure 	=> present,
		mode 	=> 644,
		owner 	=> root,
		group 	=> root,
		content => template("nginx/nginx.conf.erb"),
		notify 	=> Exec["reload-nginx"],
		require => Package["nginx"],
        }

	# using checksum => mtime and notify ensures that any changes to this dir 
	# will result in an apache reload
	file { $nginx_conf:
		ensure => directory,
		mode => 644, 
		owner => root, 
		group => root,
		require => Package["nginx"],
	}

	# as above
	file { $nginx_includes:
		ensure => directory,
		mode => 644, 
		owner => root, 
		group => root,
		require => Package["nginx"],
	}

	#Nuke default files
	file { "/etc/nginx/fastcgi_params":
		ensure => absent,
	}


	exec { "reload-nginx":
		command => "/etc/init.d/nginx reload",
                refreshonly => true,
        }

	# Define: nginx::config
	#
	# Define a nginx config snippet. Places all config snippets into
	# /etc/nginx/conf.d, where they will be automatically loaded by http module
	#
	#
	# Parameters :
	# * ensure: typically set to "present" or "absent". Defaults to "present"
	# * content: set the content of the config snipppet. Defaults to 'template("nginx/${name}.conf.erb")'
	# * order: specifies the load order for this config snippet. Defaults to "500"
	#
        define config ( $ensure = 'present', $content = '', $order="500") {
          $real_content = $content ? { '' => template("nginx/${name}.conf.erb"),
            default => $content,
          }

          file { "${nginx_conf}/${order}-${name}.conf":
		ensure => $ensure,
		content => $real_content,
		mode => 644,
		owner => root,
		group => root,
		notify => Exec["reload-nginx"],
    		}
        }

	# Define: nginx::site
	#
	# Install a nginx site in /etc/nginx/sites-available (and symlink in /etc/nginx/sites-enabled). 
	#
	#
	# Parameters :
	# * ensure: typically set to "present" or "absent". Defaults to "present"
	# * content: site definition (should be a template).
	#
	define site ( $ensure = 'present', $content = '' ) {
		case $ensure {
			'present' : {
				nginx::install_site { $name:
		  			content => $content
				}
			}
			'absent' : {
				exec { "rm -f /etc/nginx/conf-enabled/$name":
					onlyif => "/bin/sh -c '[ -L /etc/nginx/sites-enabled/$name ] \\
							&& [ $/etc/nginx/sites-enabled/$name -ef /etc/nginx/sites-available/$name ]'",
					notify => Exec["reload-nginx"],
					require => Package["nginx"],
				}
			}
			default: { err ( "Unknown ensure value: '$ensure'" ) }
		}
	}

	# Define: install_site
	#
	# Install nginx vhost
	# This definition is private, not intended to be called directly
	#
	define install_site ($content = '' ) {
	  # first, make sure the site config exists
		case $content {
			'': {
				file { "/etc/nginx/sites-available/${name}":
					mode => 644,
					owner => root,
					group => root,
					ensure => present,
					alias => "sites-$name",
				  	require => Package["nginx"],
				  	notify => Exec["reload-nginx"],
				}
			}

			default: {
				  file { "/etc/nginx/sites-available/${name}":
				  	content => $content,
				  	mode => 644,
				  	owner => root,
				  	group => root,
				      	ensure => present,
				      	alias => "sites-$name",
				  	require => Package["nginx"],
				  	notify => Exec["reload-nginx"],
				}
			}
		}

	  # now, enable it.
		exec { "ln -s /etc/nginx/sites-available/${name} /etc/nginx/sites-enabled/${name}":
			unless => "/bin/sh -c '[ -L /etc/nginx/sites-enabled/$name ] \\
                                                                && [ /etc/nginx/sites-enabled/$name -ef /etc/nginx/sites-available/$name ]'",
			notify => Exec["reload-nginx"],
			require => File["sites-$name"],
		}
	}

	# Define: site_include
	#
	# Define a site config include in /etc/nginx/includes
	#
	# Parameters :
	# * ensure: typically set to "present" or "absent". Defaults to "present"
	# * content: include definition (should be a template).
	#
	define site_include ( $ensure = 'present', $content = '' ) {
		file { "${nginx_includes}/${name}.inc":
			content => $content,
			mode => 644,
			owner => root,
			group => root,
			ensure => $ensure,
			require => File["${nginx_includes}"],
			notify => Exec["reload-nginx"],
		}    
	}


}
