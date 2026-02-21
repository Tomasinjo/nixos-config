{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };

    settings = {
      # Transparency
      #background_opacity = "0.8";
      #dynamic_background_opacity = "yes";
      #dim_opacity = "0.75";

      # Window appearance
      window_padding_width = "10";
      window_margin_width = "5";
      single_window_margin_width = "-1";
      placement_strategy = "center";
      hide_window_decorations = "titlebar-only";

      # Tab bar
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "angled";
      tab_title_template = "{index}: {title}";
      active_tab_font_style = "bold";
      inactive_tab_font_style = "normal";

      # Scrollback
      scrollback_lines = "10000";
      scrollback_pager = "less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER";

      # Cursor
      cursor_shape = "block";
      cursor_blink_interval = "0.5";
      cursor_stop_blinking_after = "15.0";

      # Bell
      enable_audio_bell = "no";
      visual_bell_duration = "0.0";
      window_alert_on_bell = "yes";

      # Performance
      repaint_delay = "10";
      input_delay = "3";
      sync_to_monitor = "yes";

      # Shell integration
      shell_integration = "enabled";

      # Advanced
      confirm_os_window_close = "0";
      update_check_interval = "0";

      # Color scheme - Catppuccin Mocha
      foreground = "#cdd6f4";
      background = "#1e1e2e";
      background_blur = "30";

      # Cursor colors
      cursor = "#f5e0dc";
      cursor_text_color = "#1e1e2e";

      # Selection colors
      selection_foreground = "#1e1e2e";
      selection_background = "#f5e0dc";

      # URL style
      url_color = "#89b4fa";

      # Tab bar colors
      active_tab_foreground = "#1e1e2e";
      active_tab_background = "#cba6f7";
      inactive_tab_foreground = "#cdd6f4";
      inactive_tab_background = "#45475a";
      tab_bar_background = "#181825";

      # Normal colors
      color0 = "#45475a";   # black
      color1 = "#f38ba8";   # red
      color2 = "#a6e3a1";   # green
      color3 = "#f9e2af";   # yellow
      color4 = "#89b4fa";   # blue
      color5 = "#f5c2e7";   # magenta
      color6 = "#94e2d5";   # cyan
      color7 = "#bac2de";   # white

      # Bright colors
      color8 = "#585b70";   # bright black
      color9 = "#eba0ac";   # bright red
      color10 = "#94e2d5";  # bright green
      color11 = "#fbd9b6";  # bright yellow
      color12 = "#b4befe";  # bright blue
      color13 = "#f5c2e7";  # bright magenta
      color14 = "#89dceb";  # bright cyan
      color15 = "#a6adc8";  # bright white
    };

    keybindings = {
      # Clipboard
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+s" = "paste_from_selection";
      "ctrl+shift+c" = "copy_to_clipboard";
      "shift+insert" = "paste_from_selection";

      # Scrolling
      "ctrl+shift+up" = "scroll_line_up";
      "ctrl+shift+down" = "scroll_line_down";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";
      "ctrl+shift+h" = "show_scrollback";

      # Window management
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+n" = "new_os_window";
      "ctrl+shift+w" = "close_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+[" = "previous_window";
      "ctrl+shift+f" = "move_window_forward";
      "ctrl+shift+b" = "move_window_backward";
      "ctrl+shift+`" = "move_window_to_top";
      "ctrl+shift+1" = "first_window";
      "ctrl+shift+2" = "second_window";
      "ctrl+shift+3" = "third_window";
      "ctrl+shift+4" = "fourth_window";
      "ctrl+shift+5" = "fifth_window";
      "ctrl+shift+6" = "sixth_window";
      "ctrl+shift+7" = "seventh_window";
      "ctrl+shift+8" = "eighth_window";
      "ctrl+shift+9" = "ninth_window";
      "ctrl+shift+0" = "tenth_window";

      # Tab management
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+q" = "close_tab";
      "ctrl+shift+l" = "next_layout";
      "ctrl+shift+." = "move_tab_forward";
      "ctrl+shift+," = "move_tab_backward";

      # Layout management
      "ctrl+shift+equal" = "change_font_size all +2.0";
      "ctrl+shift+minus" = "change_font_size all -2.0";
      "ctrl+shift+backspace" = "change_font_size all 0";
    };
  };
}
