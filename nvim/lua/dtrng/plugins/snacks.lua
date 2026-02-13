return {
  {
    'folke/snacks.nvim',
    ---@type snacks.Config
    opts = {
      explorer = {},
    },
    config = function()
      vim.keymap.set('n', '<leader>e', function()
        require('snacks').explorer()
      end, { desc = 'Show file explorer' })
    end,
  },
}
