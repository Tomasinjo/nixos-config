{ config, pkgs, ... }:
{
  wayland.waybar = {
    extraModules = {
      temperature = {
	align = 0;
	justify = "left";
	hwmon-path = "/sys/devices/platform/coretemp.0/hwmon/hwmon1/temp1_input";
	format = " {temperatureC}°C";
	format-critical = " {temperatureC}°C";
	interval = 5;
	critical-threshold = 65;
      };
    };
  };
}
