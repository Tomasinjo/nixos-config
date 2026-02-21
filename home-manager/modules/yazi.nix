{ config, pkgs, ... }:

{
  programs.yazi = {
    enable = true;
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
          { run = "nvim \"$@\""; block = true; desc = "nvim"; }
        ];

        VScode = [
          { run = "hyprctl dispatch exec code \"$@\""; block = false; desc = "VScode"; }
        ];

        imv = [
          { run = "hyprctl dispatch exec imv %s %d"; block = false; desc = "imv"; }
        ];

        gimp = [
          { run = "hyprctl dispatch exec gimp \"$@\""; block = false; desc = "gimp"; }
        ];

        vlc = [
          { run = "hyprctl dispatch exec vlc \"$@\""; block = false; desc = "vlc"; }
        ];

        okular = [
          { run = "okular \"$@\""; block = false; desc = "Okular"; }
        ];
      };

      open = {
        prepend_rules = [
	        { mime = "application/x-*"; use = [ "executable" ]; }
          { mime = "image/*"; use = [ "imv" "gimp" ]; }
          { mime = "video/*"; use = [ "vlc" ]; }
          { mime = "text/*"; use = [ "edit" "VScode" ]; }
          { mime = "application/pdf"; use = [ "okular" ]; }
        ];
	      append_rules = [
          { name = "*.AppImage"; use = [ "appimage" ]; }
          { name = "*.appimage"; use = [ "appimage" ]; }
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
