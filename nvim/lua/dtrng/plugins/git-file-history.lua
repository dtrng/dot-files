return {
	{
		dir = vim.fn.stdpath("config") .. "/local-plugins/git-file-history",
		name = "git-file-history",
		dependencies = { "nvim-telescope/telescope.nvim" },
		keys = {
			{
				"<leader>gh",
				function()
					require("git-file-history").open()
				end,
				desc = "Open file history",
			},
			{
				"<leader>gH",
				function()
					require("git-file-history").telescope()
				end,
				desc = "Search file history",
			},
		},
		opts = {
			split = "right",
			keymaps = {
				older = "[h",
				newer = "]h",
				close = "q",
			},
		},
	},
}
