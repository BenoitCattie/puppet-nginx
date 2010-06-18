# Class: nginx::fcgi
#
# Manage nginx fcgi configuration.
# Provide nginx::fcgi::site 
#
# Templates :
#	* nginx/includes/fastcgi_params.erb
#
class nginx::fcgi inherits nginx {

	nginx::site_include{"fastcgi_params": 
		content => template("nginx/includes/fastcgi_params.erb"),
	}

	# Define: nginx::fcgi::site
	#
	# Create a fcgi site config from template using parameters.
	# You can use my php5-fpm class to manage fastcgi servers.
	#
	# Parameters :
	# 	* ensure: typically set to "present" or "absent". Defaults to "present"
	# 	* root: document root (Required)
	#	* fastcgi_pass : port or socket on which the FastCGI-server is listening (Required)
	#	* server_name : server_name directive (could be an array)
	#	* listen : address/port the server listen to. Defaults to 80
	#	* access_log : custom acces logs. Defaults to /var/log/nginx/$name_access.log
	#	* include : custom include for the site (could be an array). Include files must exists 
	#	   to avoid nginx reload errors. Use with nginx::site_include  
	#   See http://wiki.nginx.org for details.
	#
	# Templates :
	#	* nginx/fcgi_site.erb
	#
	# Sample Usage :
	#
	# nginx::fcgi::site {"default":
	# 	root		=> "/var/www/nginx-default",
	#	fastcgi_pass	=> "127.0.0.1:9000",
	# }
	define site ( $ensure = 'present', $root, $fastcgi_pass, $include = '', $listen = '80', $server_name = '', $access_log = '') { 
		$real_server_name = $server_name ? { 
			'' => "${name}",
            		default => $server_name,
          	}

		$real_access_log = $access_log ? { 
			'' => "/var/log/nginx/${name}_access.log",
            		default => $access_log,
          	}

		nginx::site {"${name}":
			ensure	=> $ensure,
			content	=> template("nginx/fcgi_site.erb"),
		}
		
	}

}
