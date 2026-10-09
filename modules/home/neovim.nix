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
      -- nvim-treesitter-textobjects no longer attaches itself either, so its
      -- mappings are set from the same autocommand, buffer by buffer.
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

      -- Highlighting needs a parser and nothing more, but the indentexpr and
      -- the text objects each read a query of their own, and roughly half of
      -- the bundled query sets ship neither. Where the indents query is
      -- missing the plugin's indentexpr silently returns zero for every line,
      -- which would replace working built-in indent scripts such as the ones
      -- for make and vim, and where the textobjects query is missing the move
      -- functions raise E5108 instead of moving the cursor. Each feature is
      -- therefore gated on the query it actually reads.
      vim.api.nvim_create_autocmd('FileType', {
        pattern = '*',
        callback = function(args)
          if not pcall(vim.treesitter.start, args.buf) then return end

          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if not lang then return end

          if vim.treesitter.query.get(lang, 'indents') then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end

          if vim.treesitter.query.get(lang, 'textobjects') then
            local opts = { buffer = args.buf }

            vim.keymap.set({ 'x', 'o' }, 'af', select('@function.outer'), opts)
            vim.keymap.set({ 'x', 'o' }, 'if', select('@function.inner'), opts)
            vim.keymap.set({ 'x', 'o' }, 'ac', select('@class.outer'), opts)
            vim.keymap.set({ 'x', 'o' }, 'ic', select('@class.inner'), opts)

            vim.keymap.set({ 'n', 'x', 'o' }, ']m', move('goto_next_start', '@function.outer'), opts)
            vim.keymap.set({ 'n', 'x', 'o' }, ']]', move('goto_next_start', '@class.outer'), opts)
            vim.keymap.set({ 'n', 'x', 'o' }, ']M', move('goto_next_end', '@function.outer'), opts)
            vim.keymap.set({ 'n', 'x', 'o' }, '][', move('goto_next_end', '@class.outer'), opts)
            vim.keymap.set({ 'n', 'x', 'o' }, '[m', move('goto_previous_start', '@function.outer'), opts)
            vim.keymap.set({ 'n', 'x', 'o' }, '[[', move('goto_previous_start', '@class.outer'), opts)
            vim.keymap.set({ 'n', 'x', 'o' }, '[M', move('goto_previous_end', '@function.outer'), opts)
            vim.keymap.set({ 'n', 'x', 'o' }, '[]', move('goto_previous_end', '@class.outer'), opts)
          end
        end,
      })

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
