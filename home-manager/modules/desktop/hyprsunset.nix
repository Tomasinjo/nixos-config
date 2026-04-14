{
  services.hyprsunset = {
    enable = true;

    extraArgs = [
      "--identity"
    ];

    transitions = {
      sunrise = {
        calendar = "*-*-* 07:00:00";
        requests = [
          [ "temperature" "6500" ]
        ];
      };

      sunset = {
        calendar = "*-*-* 20:15:00";
        requests = [
          [ "temperature" "3500" ]
        ];
      };

      night = {
        calendar = "*-*-* 23:00:00";
        requests = [
          [ "temperature" "2500" ]
        ];
      };
    };
  };
}