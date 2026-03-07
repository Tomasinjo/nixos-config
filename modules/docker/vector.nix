{ config, pkgs, ... }:

{
  users.users.vector = {
    isSystemUser = true;
    group = "vector";
    extraGroups = [ 
      "docker"  # To read /var/run/docker.sock
      "adm"     # To read system logs/journal
      "users"   # to read files
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
      	      "/home/tom/apps/ha/appdaemon/logs/appdaemon.log"
      	      "/home/tom/apps/ha/appdaemon/logs/error.log"
	  ];
        };

        vector_metrics.type = "internal_metrics";
      };


      transforms = {
	# Remove logs from journald that are already captured by the docker source
	filter_docker_from_journal = {
	  type = "filter";
	  inputs = [ "journald" ];
	  condition = ''!includes(["docker", "dockerd"], .container_name) && ._SYSTEMD_UNIT != "docker.service"'';
	};
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
