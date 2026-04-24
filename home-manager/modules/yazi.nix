{ config, pkgs, inputs, ... }:

{
  home.packages = [ pkgs.exiftool ];
  programs.yazi = {
    enable = true;
    package = inputs.yazi.packages.${pkgs.system}.default.override {
      _7zz = pkgs._7zz-rar; 
    };
    enableZshIntegration = true;

    settings = {
      mgr = {
        linemode = "size_and_mtime";
        sort_by = "mtime";
        sort_reverse = true;
        sort_dir_first = false;
      };

      opener = {
        appimage = [
          { run = ''hyprctl dispatch exec -- "$1"''; orphan = true; desc = "Run"; }
        ];

        executable = [  
          { run = ''hyprctl dispatch exec -- kitty "$1"''; orphan = true; desc = "Run in Kitty"; }
        ];

        edit = [
          { run = ''nvim "$@"''; block = true; desc = "nvim"; }
        ];

        VScode = [
          { run = ''code "$@"''; orphan = true; desc = "VScode"; }
        ];

        imv = [
          { run = ''imv "%s" "%d"''; orphan = true; desc = "imv"; }
        ];

        gimp = [
          { run = ''gimp "$@"''; orphan = true; desc = "gimp"; }
        ];

        vlc = [
          { run = ''vlc "$@"''; orphan = true; desc = "vlc"; }
        ];

        okular = [
          { run = ''okular "$@"''; orphan = true; desc = "Okular"; }
        ];

        office = [
          { run = ''onlyoffice-desktopeditors "$@"''; orphan = true; desc = "onlyoffice"; }
        ];

        firefox = [
          { run = ''firefox "$@"''; orphan = true; desc = "firefox"; }
        ];
      };

      open = {
        prepend_rules = [
	        { mime = "application/x-*"; use = [ "executable" ]; }
          { mime = "image/*"; use = [ "imv" "gimp" ]; }
          { mime = "video/*"; use = [ "vlc" ]; }
          { mime = "application/json"; use = [ "edit" "VScode" ]; }
          { mime = "application/pdf"; use = [ "okular" ]; }
          { mime = "text/csv"; use = [ "office" "edit" "VScode" ]; }
          { url = "*.csv"; use = [ "office" "edit" "VScode" ]; }
          { url = "*.html"; use = [ "firefox" "edit" "VScode" ]; }
          { url = "*.htm"; use = [ "firefox" "edit" "VScode" ]; }
          { mime = "text/*"; use = [ "edit" "VScode" ]; }
        ];
	      append_rules = [
          { url = "*.AppImage"; use = [ "appimage" ]; }
          { url = "*.appimage"; use = [ "appimage" ]; }
	      ];
      };
    };

    initLua = /* lua */ ''
      function Linemode:size_and_mtime()
      	local time = math.floor(self._file.cha.mtime or 0)
      	if time == 0 then
      		time = ""
      	elseif os.date("%Y", time) == os.date("%Y") then
      		time = os.date("%b %d %H:%M", time)
      	else
      		time = os.date("%b %d  %Y", time)
      	end

      	local size = self._file:size()
      	return string.format("%s %s", size and ya.readable_size(size) or "-", time)
      end
    '';
  };
}
