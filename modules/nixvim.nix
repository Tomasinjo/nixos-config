{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ 
    ripgrep # required for Telescope live_grep
  ];
  
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = false;
        integrations = {
          cmp = true;
          gitsigns = true;
          telescope = true;
          treesitter = true;
          which_key = true;
        };
      };
    };

    opts = {
      number = true;         # Line numbers
      relativenumber = true; # Relative numbers for jumping
      shiftwidth = 2;        # Tab width
      tabstop = 2;           # Number of spaces tab counts for
      expandtab = true;      # Use spaces instead of tabs
      smartindent = true;
      ignorecase = true;
      smartcase = true;      # Case-sensitive when uppercase present
      breakindent = true;
      cursorline = true;     # Highlight current line
      scrolloff = 8;         # Keep 8 lines above/below cursor
      clipboard = "unnamedplus";
      wrap = false;          # Don't wrap long lines
      signcolumn = "yes";    # Always show signcolumn (for git signs)
      updatetime = 300;      # Faster completion (default 4000)
      termguicolors = true;  # True color support
      undofile = true;       # Persistent undo
      backup = false;        # Don't create backup files
      writebackup = false;   # Don't write backup files
    };

    globals.mapleader = " ";
    
    keymaps = [
      # File navigation
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; options = { desc = "Find files"; }; }
      { mode = "n"; key = "<leader>fr"; action = "<cmd>Telescope oldfiles<CR>"; options = { desc = "Recent files"; }; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<CR>"; options = { desc = "Find buffers"; }; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope help_tags<CR>"; options = { desc = "Help tags"; }; }
      
      # File explorer
      { mode = "n"; key = "<leader>e"; action = "<cmd>Oil<CR>"; options = { desc = "Open file explorer"; }; }
      
      # Search
      {
        mode = "n";
        key = "<leader>fg";
        action.__raw = ''
          function()
            local path
            local ok, oil = pcall(require, "oil")

            -- Try to get path from Oil
            if ok and vim.bo.filetype == "oil" then
              path = oil.get_current_dir()
            else
              -- Try to get directory of current file
              path = vim.fn.expand("%:p:h")
            end

            -- Fallback to CWD if path is empty or invalid (e.g. empty buffer)
            if path == "" or path == "." then
              path = vim.fn.getcwd()
            end

            require("telescope.builtin").live_grep({
              cwd = path,
            })
          end
        '';
        options = { desc = "Grep recursively in current directory"; };
      }
      { mode = "n"; key = "<leader>fw"; action = "<cmd>Telescope grep_string<CR>"; options = { desc = "Grep word under cursor"; }; }
      
      # Window navigation
      { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options = { desc = "Move to left window"; }; }
      { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options = { desc = "Move to bottom window"; }; }
      { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options = { desc = "Move to top window"; }; }
      { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options = { desc = "Move to right window"; }; }
      
      # Buffer management
      { mode = "n"; key = "<leader>bd"; action = "<cmd>bdelete<CR>"; options = { desc = "Delete buffer"; }; }
      { mode = "n"; key = "<leader>bn"; action = "<cmd>bnext<CR>"; options = { desc = "Next buffer"; }; }
      { mode = "n"; key = "<leader>bp"; action = "<cmd>bprevious<CR>"; options = { desc = "Previous buffer"; }; }
      
      # Quick save/quit
      { mode = "n"; key = "<leader>w"; action = "<cmd>w<CR>"; options = { desc = "Save"; }; }
      { mode = "n"; key = "<leader>q"; action = "<cmd>q<CR>"; options = { desc = "Quit"; }; }
      
      # Toggle options
      { mode = "n"; key = "<leader>tn"; action = "<cmd>set nu!<CR>"; options = { desc = "Toggle line numbers"; }; }
      { mode = "n"; key = "<leader>tr"; action = "<cmd>set rnu!<CR>"; options = { desc = "Toggle relative numbers"; }; }
    ];

    # Plugins
    plugins = {
      # File icons
      web-devicons.enable = true;
      
      # Status bar
      lightline.enable = true;
      
      # Fuzzy finder
      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
        };
        settings = {
          defaults = {
            file_ignore_patterns = [ "node_modules" ".git/" "dist/" "target/" ".venv/" "__pycache__/" ];
            layout_config = {
              horizontal = {
                prompt_position = "top";
              };
            };
          };
        };
      };
      
      # Syntax highlighting
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          ensureInstalled = [
            "nix" "lua" "python" "bash" "markdown" "markdown_inline"
            "json" "yaml" "toml" "dockerfile" "javascript" "typescript"
            "rust" "c" "cpp" "go" "html" "css" "sql"
          ];
        };
      };
      
      # File management
      oil = {
        enable = true;
        settings = {
          default_file_explorer = true;
          delete_to_trash = true;
          skip_confirm_for_simple_edits = true;
          view_options = {
            show_hidden = true;
          };
          columns = [
            "icon"
            "permissions"
            "size"
            "mtime"
          ];
        };
      };
      
      # Git integration
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          current_line_blame_opts = {
            virt_text_pos = "right_align";
            delay = 1000;
          };
          signcolumn = true;
          numhl = false;
          linehl = false;
        };
      };
      
      # Auto-close brackets/quotes
      nvim-autopairs.enable = true;
      
      # Comment with gcc/gc
      comment = {
        enable = true;
        settings = {
          toggler = {
            line = "gcc";
            block = "gbc";
          };
          opleader = {
            line = "gc";
            block = "gb";
          };
        };
      };
      
      # Snippet engine
      luasnip = {
        enable = true;
      };
      
      # Auto-completion
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "buffer"; }
            { name = "luasnip"; }
          ];
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-e>" = "cmp.mapping.abort()";
          };
          snippet.expand = "luasnip";
        };
      };

      # LSP (Language Servers)
      lsp = {
        enable = true;
        keymaps = {
          silent = true;
          diagnostic = {
            "<leader>k" = "open_float";
            "[d" = "goto_next";
            "]d" = "goto_prev";
          };
          lspBuf = {
            "gd" = "definition";
            "gD" = "declaration";
            "gr" = "references";
            "gi" = "implementation";
            "K" = "hover";
            "<C-k>" = "signature_help";
            "<leader>ca" = "code_action";
            "<leader>rn" = "rename";
            "<leader>f" = "format";
          };
        };
        servers = {
          nil_ls = {
            enable = true;
            settings = {
              nix = {
                flake = {
                  autoArchive = true;
                };
              };
            };
          };
          lua_ls.enable = true;   # Lua
          pyright.enable = true;  # Python
          bashls.enable = true;   # Bash
          ts_ls.enable = true;    # TypeScript/JavaScript
          rust_analyzer = {
            enable = true;
            installRustc = true;
            installCargo = true;
          };
          clangd.enable = true;   # C/C++
          jsonls.enable = true;   # JSON
          yamlls.enable = true;   # YAML
        };
      };
      
      # Keymap documentation
      which-key = {
        enable = true;
        settings = {
          spec = [
            {
              __unkeyed-1 = "<leader>f";
              group = "Find";
            }
            {
              __unkeyed-1 = "<leader>e";
              group = "Explorer";
            }
            {
              __unkeyed-1 = "<leader>b";
              group = "Buffer";
            }
            {
              __unkeyed-1 = "<leader>t";
              group = "Toggle";
            }
          ];
        };
      };
      
      # Better surround
      vim-surround.enable = true;
      
      # Indent guides
      indent-blankline = {
        enable = true;
        settings = {
          indent = {
            char = "│";
            tab_char = "│";
          };
          scope = {
            enabled = true;
            show_start = true;
            show_end = true;
          };
          exclude = {
            filetypes = [ "help" "alpha" "dashboard" "neo-tree" "Trouble" "lazy" "mason" "notify" "toggleterm" "lazyterm" ];
          };
        };
      };
    };
    
    extraConfigLua = ''
      -- OSC 52 clipboard support for SSH
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

      -- Make line numbers brighter
      vim.cmd('highlight LineNr guifg=#9399b2 guibg=NONE')
      vim.cmd('highlight CursorLineNr guifg=#f5c2e7 guibg=NONE')

      -- Auto-create directories when saving
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*",
        callback = function()
          local dir = vim.fn.expand("<afile>:p:h")
          if dir ~= "" and vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
          end
        end,
      })

      -- Highlight yanked text
      vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
          vim.highlight.on_yank({ higroup = "Visual", timeout = 200 })
        end,
      })

      -- Auto close some filetypes with q
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "qf", "help", "man", "lspinfo", "spectre_panel", "lir" },
        callback = function(event)
          vim.bo[event.buf].buflisted = false
          vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
        end,
      })

      -- Fix conceallevel for markdown files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "markdown_inline" },
        callback = function()
          vim.opt_local.conceallevel = 0
        end,
      })
    '';
  };
}
