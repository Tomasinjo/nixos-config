{ config, pkgs, vars, ... }:

{
  users.users.vector = {
    isSystemUser = true;
    group = "vector";
    extraGroups = [ 
      "docker"  # To read /var/run/docker.sock
      "adm"     # To read system logs/journal
      "users"   # to read files
      "docker-user"
    ];
  };
  users.groups.vector = {}; # Create the group

  services.vector = {
    enable = true;
    journaldAccess = true;
    settings = {
      sources = {
        # Local system logs
        journald = {
          type = "journald";
        };

        # Docker container logs
        docker_containers = {
          type = "docker_logs";
        };

        # Tailing specific local files
        local_files = {
          type = "file";
          include = [ 
      	      "${vars.dir.nixos_config}/apps/ha/appdaemon/app-data/logs/appdaemon.log"
      	      "${vars.dir.nixos_config}/apps/ha/appdaemon/app-data/logs/error.log"
<<<<<<< HEAD
	  ];
=======
	        ];
>>>>>>> d77319e9b9a8b8dc87a973320b35076d0602b5dc
        };

        vector_metrics.type = "internal_metrics";
      };


      transforms = {
<<<<<<< HEAD
	# Remove logs from journald that are already captured by the docker source
	filter_docker_from_journal = {
	  type = "filter";
	  inputs = [ "journald" ];
	  condition = ''!includes(["docker", "dockerd"], .container_name) && ._SYSTEMD_UNIT != "docker.service"'';
	};
=======
	      # Remove logs from journald that are already captured by the docker source (start with "docker-", but don't exclude docker-update sincce it is a backup script)
	      filter_docker_from_journal = {
	        type = "filter";
	        inputs = [ "journald" ];
	        condition = ''!starts_with(string(._SYSTEMD_UNIT) ?? "", "docker-") || starts_with(string(._SYSTEMD_UNIT) ?? "", "docker-update")'';
	      };
>>>>>>> d77319e9b9a8b8dc87a973320b35076d0602b5dc
      };

      sinks = {
        victorialogs = {
          type = "http";
          inputs = [ "filter_docker_from_journal" "docker_containers" "local_files" ];
          uri = "http://localhost:9428/insert/jsonline?_stream_fields=host,container_name,source_type&_msg_field=message&_time_field=timestamp";
          compression = "gzip";
          encoding.codec = "json";
          framing.method = "newline_delimited";
          healthcheck.enabled = false;
        };
      };
    };
  };
}
