local M = {}

local defaults = {
	split = "right",
	keymaps = {
		older = "[h",
		newer = "]h",
		close = "q",
	},
}

local config = vim.deepcopy(defaults)
local states = {}

local function notify(message, level)
	vim.notify("git-file-history: " .. message, level or vim.log.levels.INFO)
end

local function run_git(root, args)
	local command = { "git", "-C", root }
	vim.list_extend(command, args)
	local result = vim.system(command, { text = true }):wait()

	if result.code ~= 0 then
		local message = vim.trim(result.stderr or "")
		return nil, message ~= "" and message or "git exited with code " .. result.code
	end

	return result.stdout or ""
end

local function git_root(path)
	local directory = vim.fs.dirname(path)
	local output, err = run_git(directory, { "rev-parse", "--show-toplevel" })
	if not output then
		return nil, err
	end
	return vim.trim(output)
end

local function relative_path(root, path)
	local relative = vim.fs.relpath(root, path)
	if not relative then
		return nil
	end
	return relative:gsub("\\", "/")
end

-- Each record starts with an ASCII record separator. The path stored on an
-- entry is the name the file had at that commit; when a rename is encountered,
-- older entries continue with the old name.
local function parse_history(output, initial_path)
	local entries = {}
	local path = initial_path

	for record in output:gmatch("\30([^\30]+)") do
		local header, changes = record:match("^([^\n]*)\n?(.*)$")
		local hash, short_hash, subject = header:match("^([^\31]+)\31([^\31]+)\31(.*)$")

		if hash then
			entries[#entries + 1] = {
				hash = hash,
				short_hash = short_hash,
				subject = subject,
				path = path,
			}

			for line in changes:gmatch("[^\n]+") do
				local status, old_path, new_path = line:match("^(R%d*)\t([^\t]+)\t(.+)$")
				if status and new_path == path then
					path = old_path
					break
				end
			end
		end
	end

	return entries
end

local function get_history(root, path)
	local output, err = run_git(root, {
		"log",
		"--follow",
		"--format=%x1e%H%x1f%h%x1f%s",
		"--name-status",
		"--",
		path,
	})
	if not output then
		return nil, err
	end
	return parse_history(output, path)
end

local function history_context()
	local source_buf = vim.api.nvim_get_current_buf()
	local source_path = vim.api.nvim_buf_get_name(source_buf)
	if source_path == "" or vim.bo[source_buf].buftype ~= "" then
		return nil, "the current buffer is not a file", vim.log.levels.WARN
	end
	source_path = vim.fs.normalize(source_path)

	local root, root_err = git_root(source_path)
	if not root then
		return nil, root_err, vim.log.levels.ERROR
	end
	local path = relative_path(root, source_path)
	if not path then
		return nil, "the current file is outside the Git repository", vim.log.levels.ERROR
	end

	local entries, history_err = get_history(root, path)
	if not entries then
		return nil, history_err, vim.log.levels.ERROR
	end
	if #entries == 0 then
		return nil, "the file has no committed history", vim.log.levels.WARN
	end

	return {
		source_buf = source_buf,
		source_path = source_path,
		filetype = vim.bo[source_buf].filetype,
		root = root,
		path = path,
		entries = entries,
	}
end

local function split_lines(text)
	if text == "" then
		return {}
	end
	local lines = vim.split(text, "\n", { plain = true })
	if lines[#lines] == "" then
		table.remove(lines)
	end
	return lines
end

local function render(buf, index)
	local state = states[buf]
	if not state then
		return
	end

	local entry = state.entries[index]
	local content, err = run_git(state.root, { "show", entry.hash .. ":" .. entry.path })
	if not content then
		notify(err, vim.log.levels.ERROR)
		return
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, split_lines(content))
	vim.bo[buf].modifiable = false
	state.index = index

	local display_name = ("git-history://%s@%s"):format(entry.path, entry.short_hash)
	vim.api.nvim_buf_set_name(buf, display_name)
	vim.b[buf].git_file_history = {
		root = state.root,
		path = entry.path,
		hash = entry.hash,
		index = index,
		count = #state.entries,
	}

	notify(("%d/%d  %s  %s"):format(index, #state.entries, entry.short_hash, entry.subject))
end

local function current_state()
	local buf = vim.api.nvim_get_current_buf()
	return buf, states[buf]
end

function M.older()
	local buf, state = current_state()
	if not state then
		notify("the current buffer is not a history buffer", vim.log.levels.WARN)
		return
	end
	if state.index == #state.entries then
		notify("already at the oldest version")
		return
	end
	render(buf, state.index + 1)
end

function M.newer()
	local buf, state = current_state()
	if not state then
		notify("the current buffer is not a history buffer", vim.log.levels.WARN)
		return
	end
	if state.index == 1 then
		notify("already at the newest committed version")
		return
	end
	render(buf, state.index - 1)
end

function M.close()
	local buf, state = current_state()
	if not state then
		return
	end
	vim.api.nvim_win_close(0, true)
end

local function open_window()
	if config.split == false then
		return
	end

	local commands = {
		right = "rightbelow vsplit",
		left = "leftabove vsplit",
		above = "leftabove split",
		below = "rightbelow split",
	}
	local command = commands[config.split]
	if not command then
		error("git-file-history: split must be right, left, above, below, or false")
	end
	vim.cmd(command)
end

function M.open()
	local context, err, level = history_context()
	if not context then
		notify(err, level)
		return
	end

	open_window()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(0, buf)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = context.filetype
	vim.bo[buf].undolevels = -1

	states[buf] = {
		root = context.root,
		entries = context.entries,
		index = 1,
	}

	local keymap_options = { buffer = buf, silent = true, nowait = true }
	if config.keymaps.older then
		vim.keymap.set(
			"n",
			config.keymaps.older,
			M.older,
			vim.tbl_extend("force", keymap_options, { desc = "Older file version" })
		)
	end
	if config.keymaps.newer then
		vim.keymap.set(
			"n",
			config.keymaps.newer,
			M.newer,
			vim.tbl_extend("force", keymap_options, { desc = "Newer file version" })
		)
	end
	if config.keymaps.close then
		vim.keymap.set(
			"n",
			config.keymaps.close,
			M.close,
			vim.tbl_extend("force", keymap_options, { desc = "Close file history" })
		)
	end

	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once = true,
		callback = function()
			states[buf] = nil
		end,
	})

	render(buf, 1)
end

function M.telescope(opts)
	local ok, pickers = pcall(require, "telescope.pickers")
	if not ok then
		notify("Telescope is required for the history picker", vim.log.levels.ERROR)
		return
	end

	local context, err, level = history_context()
	if not context then
		notify(err, level)
		return
	end

	local finders = require("telescope.finders")
	local previewers = require("telescope.previewers")
	local conf = require("telescope.config").values
	local entry_display = require("telescope.pickers.entry_display")
	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 8 },
			{ remaining = true },
		},
	})

	opts = vim.tbl_deep_extend("force", {
		layout_strategy = "horizontal",
		layout_config = { horizontal = { preview_width = 0.65 } },
		sorting_strategy = "ascending",
		prompt_title = "File history: " .. context.path,
		preview_title = "Committed file",
	}, opts or {})

	pickers.new(opts, {
		finder = finders.new_table({
			results = context.entries,
			entry_maker = function(entry)
				return {
					value = entry,
					ordinal = entry.short_hash .. " " .. entry.subject,
					display = function(item)
						return displayer({
							{ item.value.short_hash, "TelescopeResultsIdentifier" },
							item.value.subject,
						})
					end,
				}
			end,
		}),
		previewer = previewers.new_buffer_previewer({
			define_preview = function(self, entry)
				local item = entry.value
				local content, show_err = run_git(context.root, { "show", item.hash .. ":" .. item.path })
				if not content then
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { show_err })
					return
				end
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, split_lines(content))
				vim.bo[self.state.bufnr].filetype = context.filetype
			end,
		}),
		sorter = conf.generic_sorter(opts),
	}):find()
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

return M
