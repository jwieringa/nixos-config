{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;

    withPython3 = true;
    # No plugin here needs the Ruby provider; this is the new default and
    # setting it explicitly silences the home-manager 26.05 warning.
    withRuby = false;

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
      -- Treesitter
      --
      -- nvim-treesitter (main branch) no longer configures highlighting or
      -- indentation itself. Highlighting is Neovim core, indentation is the
      -- plugin's indentexpr, and every parser and query comes from the Nix
      -- package (withAllGrammars), so nothing is installed at runtime.
      vim.api.nvim_create_autocmd('FileType', {
        pattern = '*',
        callback = function(args)
          if not pcall(vim.treesitter.start, args.buf) then return end
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      ---------------------------------------------------------------------
      -- Treesitter text objects
      require('nvim-treesitter-textobjects').setup {
        select = { lookahead = false },
        move = { set_jumps = true },
      }

      local select = function(capture)
        return function()
          require('nvim-treesitter-textobjects.select').select_textobject(capture, 'textobjects')
        end
      end
      local move = function(fn, capture)
        return function()
          require('nvim-treesitter-textobjects.move')[fn](capture, 'textobjects')
        end
      end

      vim.keymap.set({ 'x', 'o' }, 'af', select('@function.outer'))
      vim.keymap.set({ 'x', 'o' }, 'if', select('@function.inner'))
      vim.keymap.set({ 'x', 'o' }, 'ac', select('@class.outer'))
      vim.keymap.set({ 'x', 'o' }, 'ic', select('@class.inner'))

      vim.keymap.set({ 'n', 'x', 'o' }, ']m', move('goto_next_start', '@function.outer'))
      vim.keymap.set({ 'n', 'x', 'o' }, ']]', move('goto_next_start', '@class.outer'))
      vim.keymap.set({ 'n', 'x', 'o' }, ']M', move('goto_next_end', '@function.outer'))
      vim.keymap.set({ 'n', 'x', 'o' }, '][', move('goto_next_end', '@class.outer'))
      vim.keymap.set({ 'n', 'x', 'o' }, '[m', move('goto_previous_start', '@function.outer'))
      vim.keymap.set({ 'n', 'x', 'o' }, '[[', move('goto_previous_start', '@class.outer'))
      vim.keymap.set({ 'n', 'x', 'o' }, '[M', move('goto_previous_end', '@function.outer'))
      vim.keymap.set({ 'n', 'x', 'o' }, '[]', move('goto_previous_end', '@class.outer'))

      ---------------------------------------------------------------------
      -- Conform
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
