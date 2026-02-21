{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = true;
      };
    };

    opts = {
      number = true;         # Line numbers
      relativenumber = true; # Relative numbers for jumping
      shiftwidth = 2;        # Tab width
      smartindent = true;
      ignorecase = true;
      breakindent = true;
      cursorline = true;     # Highlight current line
      scrolloff = 8;         # Keep 8 lines above/below cursor
      clipboard = "unnamedplus";
    };

    globals.mapleader = " ";
    keymaps = [
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<CR>"; }
      { mode = "n"; key = "<leader>e";  action = "<cmd>Oil<CR>"; } # file explorer
    ];

    # Plugins
    plugins = {
      web-devicons.enable = true; # File icons
      lightline.enable = true; # Status bar
      telescope.enable = true; # Search
      treesitter.enable = true; # Highlighting
      oil.enable = true;       # File management
      
      # Auto-completion
      cmp = {
        enable = true;
        settings.sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
      };

      # LSP (Language Servers)
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;    # Nix
          lua_ls.enable = true;   # Lua
          pyright.enable = true;  # Python
          bashls.enable = true;   # Bash
        };
      };
    };
    extraConfigLua = ''
      if vim.env.SSH_TTY then
        vim.g.clipboard = {
          name = 'OSC 52',
          copy = {
            ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
            ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
          },
          paste = {
            ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
            ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
          },
        }
      end

      -- Set opacity to 0.85
      vim.cmd('highlight Normal guibg=NONE')
      vim.cmd('highlight NormalNC guibg=NONE')
      vim.cmd('highlight NonText guibg=NONE')
      vim.cmd('highlight SignColumn guibg=NONE')
      vim.cmd('highlight FoldColumn guibg=NONE')
      vim.cmd('highlight EndOfBuffer guibg=NONE')

      -- Make line numbers brighter
      vim.cmd('highlight LineNr guifg=#9399b2 guibg=NONE')
      vim.cmd('highlight CursorLineNr guifg=#f5c2e7 guibg=NONE')
    '';
  };
}
