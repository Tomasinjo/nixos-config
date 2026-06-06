{
  services.hyprsunset = {
    enable = true;

    extraArgs = [
      "--identity"
    ];

    settings = {
      sunrise = {
        time = "7:00";
	temperature = 6500;
      };

      sunset= {
        time = "20:15";
	temperature = 3500;
      };

      night = {
        time = "20:15";
	temperature = 2500;
      };
    };
  };
}
