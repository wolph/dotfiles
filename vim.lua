-- Modern neovim layer, luafile'd from ~/.vimrc on nvim >= 0.11 only.
-- Native LSP (no nvim-lspconfig plugin): pyright for navigation/hover/
-- rename, ruff for diagnostics, formatting and import organizing.

vim.lsp.config('pyright', {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg',
                   'requirements.txt', '.git' },
  settings = {
    pyright = {
      -- ruff owns import organizing
      disableOrganizeImports = true,
    },
    python = {
      -- ruff owns linting; pyright only serves navigation/hover/rename
      analysis = { ignore = { '*' } },
    },
  },
})

vim.lsp.config('ruff', {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
})

-- Missing binaries degrade to plain editing instead of startup errors.
if vim.fn.executable('pyright-langserver') == 1 then
  vim.lsp.enable('pyright')
end
if vim.fn.executable('ruff') == 1 then
  vim.lsp.enable('ruff')
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('modern_lsp_attach', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end
    -- pyright owns hover (K); stop ruff from answering it
    if client.name == 'ruff' then
      client.server_capabilities.hoverProvider = false
    end

    -- completion flows through the existing supertab omni path
    -- (<Tab> -> <c-x><c-o>), keeping old-system muscle memory identical
    vim.bo[args.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- jedi-era keymaps, buffer-local like jedi's were (so \g still runs
    -- :GFiles outside python buffers). pyright exposes no separate
    -- declaration/assignment target, so \d and \g both go to definition.
    local opts = { buffer = args.buf }
    vim.keymap.set('n', '<leader>d', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<leader>g', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<leader>n', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, opts)
    -- \i replaces the old :Isort mapping, via ruff
    vim.keymap.set('n', '<leader>i', function()
      vim.lsp.buf.code_action({
        context = { only = { 'source.organizeImports' }, diagnostics = {} },
        apply = true,
      })
    end, opts)
  end,
})

vim.api.nvim_create_user_command('Format', function()
  vim.lsp.buf.format({ async = false })
end, { desc = 'Format buffer via LSP (ruff for python)' })

-- Treesitter highlighting; the plugin is registered in the vimrc behind an
-- nvim version guard (main branch on 0.12+, frozen master branch on 0.11).
-- require() failing just means PlugInstall has not run yet.
local ts_ok, ts = pcall(require, 'nvim-treesitter')
if ts_ok then
  local langs = { 'python', 'lua', 'vim', 'vimdoc', 'json', 'yaml', 'bash',
                  'javascript', 'typescript' }
  local configs_ok, configs = pcall(require, 'nvim-treesitter.configs')
  if configs_ok then
    -- master branch (nvim 0.11): setup handles parser install + highlight
    -- pcall: a future nvim-0.12-vs-master API incompatibility should degrade
    -- silently instead of erroring at startup.
    pcall(configs.setup, { ensure_installed = langs, highlight = { enable = true } })
  else
    -- main branch (nvim 0.12+): explicit install + per-filetype start
    ts.install(langs)
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('modern_treesitter', { clear = true }),
      pattern = langs,
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end
end
