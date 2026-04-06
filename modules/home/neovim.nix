{ pkgs, inputs, ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;

    withPython3 = true;

    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      nvim-treesitter-textobjects
      conform-nvim
      gitsigns-nvim
      lualine-nvim
    ];

    extraConfig = ''
      lua <<EOF
      ---------------------------------------------------------------------
      -- Add our custom treesitter parsers
      local parser_config = require "nvim-treesitter.parsers".get_parser_configs()

      parser_config.proto = {
        install_info = {
          url = "${inputs.tree-sitter-proto}",
          files = {"src/parser.c"}
        },
        filetype = "proto",
      }

      parser_config.hcl = {
        install_info = {
          url = "${inputs.tree-sitter-hcl}",
          files = {"src/parser.c"},
        },
        filetype = "hcl",
      }

      parser_config.terraform = {
        install_info = {
          url = "${inputs.tree-sitter-hcl}",
          files = {"src/parser.c"},
        },
        filetype = "terraform",
      }

      ---------------------------------------------------------------------
      -- Configure treesitter
      require'nvim-treesitter.configs'.setup {
        -- Don't try to install parsers in NixOS - they're provided by the Nix package
        auto_install = false,

        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },

        indent = {
          enable = true,
        },
        textobjects = {
          select = {
            enable = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },

          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]]"] = "@class.outer",
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[["] = "@class.outer",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[]"] = "@class.outer",
            },
          },
        },
      }

      require("conform").setup({
        formatters_by_ft = {
          cpp = { "clang_format" },
          terraform = { "terraform_fmt" },
          hcl = { "terraform_fmt" },
        },

        format_on_save = {
          lsp_fallback = true,
        },
      })

      ---------------------------------------------------------------------
      -- Gitsigns

      require('gitsigns').setup()

      ---------------------------------------------------------------------
      -- Lualine

      require('lualine').setup({
        sections = {
          lualine_c = {
            { 'filename', path = 1 },
          },
        },
      })

      vim.opt.termsync = false

      EOF
    '';
  };
}
