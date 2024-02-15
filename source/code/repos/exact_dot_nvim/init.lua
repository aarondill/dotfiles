local fname = vim.api.nvim_buf_get_name(0)

if vim.endswith(fname, "/install.sh") then vim.b.autoformat = false end
