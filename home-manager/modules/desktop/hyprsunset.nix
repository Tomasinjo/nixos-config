{
  services.hyprsunset = {
    enable = true;

    extraArgs = [
      "--identity"
    ];

    settings = {
      profile = [
        {
          time = "7:00";
	        temperature = 6500;
        }
        {
          time = "20:15";
	        temperature = 3500;
        }
        {
          time = "23:15";
	        temperature = 2500;
        }
      ];
    };
  };
}
