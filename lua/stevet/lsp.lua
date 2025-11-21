
-- ~/.config/nvim/lua/stevet/lsp.lua

-- 1. Get the main modules (These MUST be at the top)
local lspconfig = require('lspconfig')
local mason = require('mason')
local mason_lspconfig = require('mason-lspconfig')

-- This function will use the "legacy setup" on older Neovim version.
-- The new api is only available on Neovim v0.11 or greater.
local function lsp_setup(server, opts)
  if vim.fn.has('nvim-0.11') == 0 then
    require('lspconfig')[server].setup(opts)
    return
  end

  if not vim.tbl_isempty(opts) then
    vim.lsp.config(server, opts)
  end

  vim.lsp.enable(server)
end

-- 2. Autocompletion
require('mini.snippets').setup({})
require('mini.completion').setup({})

---
-- 3. Language Server Configuration and Handlers
---

local on_attach = function(client, bufnr)
    -- Disable semantic tokens for C/C++ clangd as it can sometimes conflict with Tree-sitter
    if client.name == 'clangd' then
        client.server_capabilities.semanticTokensProvider = nil
    end

    -- Setup keymaps only in the buffer where the LSP is attached
    local buf_opts = { noremap = true, silent = true, buffer = bufnr }
    local keymap = vim.keymap.set

    -- General LSP commands
    keymap('n', 'gd', vim.lsp.buf.definition, buf_opts)        -- Go to Definition
    keymap('n', 'gD', vim.lsp.buf.declaration, buf_opts)       -- Go to Declaration
    keymap('n', 'gi', vim.lsp.buf.implementation, buf_opts)    -- Go to Implementation
    keymap('n', 'gr', vim.lsp.buf.references, buf_opts)        -- Show References
    keymap('n', '<leader>rn', vim.lsp.buf.rename, buf_opts)    -- Rename
    keymap('n', '<leader>ca', vim.lsp.buf.code_action, buf_opts) -- Code Action
    keymap('n', 'K', vim.lsp.buf.hover, buf_opts)             -- Show Documentation/Hover

    -- Diagnostics (Errors/Warnings)
    keymap('n', '[d', vim.diagnostic.goto_prev, buf_opts)      -- Previous diagnostic
    keymap('n', ']d', vim.diagnostic.goto_next, buf_opts)      -- Next diagnostic

    -- Formatting on Save (Optional, uncomment if desired)
    -- if client.server_capabilities.documentFormattingProvider then
    --     vim.cmd('autocmd BufWritePre <buffer> lua vim.lsp.buf.format()')
    -- end
end

-- 4. Keymaps (Global - for diagnostics)
if vim.fn.has('nvim-0.11') == 0 then
    vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')
    vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')
    vim.keymap.set('n', '<C-w>d', '<cmd>lua vim.diagnostic.open_float()<cr>')
    vim.keymap.set('n', '<C-w><C-d>', '<cmd>lua vim.diagnostic.open_float()<cr>')
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local bufmap = function(mode, rhs, lhs)
      vim.keymap.set(mode, rhs, lhs, {buffer = event.buf})
    end

    -- These keymaps are the defaults in Neovim v0.11
    bufmap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>')
    bufmap('n', 'grr', '<cmd>lua vim.lsp.buf.references()<cr>')
    bufmap('n', 'gri', '<cmd>lua vim.lsp.buf.implementation()<cr>')
    bufmap('n', 'grn', '<cmd>lua vim.lsp.buf.rename()<cr>')
    bufmap('n', 'gra', '<cmd>lua vim.lsp.buf.code_action()<cr>')
    bufmap('n', 'gO', '<cmd>lua vim.lsp.buf.document_symbol()<cr>')
    bufmap({'i', 's'}, '<C-s>', '<cmd>lua vim.lsp.buf.signature_help()<cr>')
  end,
})

-- 5. Mason Setup
mason.setup()

mason_lspconfig.setup({
    -- The language servers you want Mason to ensure are installed.
    -- Disable automatic features that rely on nvim v0.11+ APIs.
    -- We use the setup_handlers function below instead.

    -- The language servers you want Mason to ensure are installed.
    ensure_installed = {
        "gopls",        -- For Go
        "clangd",       -- For C/C++
        "lua_ls",       -- Essential for Neovim config (Lua/LuaJIT)
    },
    -- NOTE: These options are critical for NVIM v0.10.4
    automatic_installation = false, -- Disable automatic features (optional, but safe)
    automatic_enable = false,       -- Avoids the v0.11-only `vim.lsp.enable()` call

    -- NEW: Pass the handlers directly into the 'handlers' key
    handlers = {
        -- This default handler is called for ALL LSPs installed by Mason.
        function(server_name)
            lspconfig[server_name].setup({
                on_attach = on_attach, -- Use the on_attach function defined earlier
            })
        end,

        -- You can override the setup for specific servers here:
        gopls = function()
            lspconfig.gopls.setup({
                on_attach = on_attach,
                settings = {
                    gopls = {
                        gofumpt = true,
                        analyses = {
                            unusedparams = true,
                        },
                        staticcheck = true,
                    },
                },
            })
        end,

        clangd = function()
            lspconfig.clangd.setup({
                on_attach = on_attach,
                -- Add custom settings for clangd here if needed
            })
        end,
    }, -- END handlers table
})


