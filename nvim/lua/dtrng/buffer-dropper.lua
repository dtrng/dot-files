-- buf_lru.lua
-- Evicts hidden buffers (LRU) once more than `max_hidden` are not displayed
-- in any window. Protects modified buffers and non-file buffers (terminal,
-- quickfix, nofile, etc.).
--
-- Usage in init.lua / lazy.nvim:
--   require("buf_lru").setup({ max_hidden = 10 })

local M = {}

local lru = {}       -- ordered list of buffer handles; newest at the back
local cfg = {
  max_hidden = 10,   -- how many invisible file-buffers to keep alive
}

--- Returns true if buf is a regular file buffer we should track.
local function is_managed(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return false end
  -- Skip special buffer types (terminal, quickfix, nofile, prompt …)
  if vim.bo[buf].buftype ~= "" then return false end
  -- Skip unnamed scratch buffers
  if vim.api.nvim_buf_get_name(buf) == "" then return false end
  return true
end

--- Returns true if buf is currently shown in at least one window.
local function is_visible(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then return true end
  end
  return false
end

--- Move buf to the most-recently-used (back) position.
local function touch(buf)
  for i, b in ipairs(lru) do
    if b == buf then table.remove(lru, i); break end
  end
  table.insert(lru, buf)
end

--- Remove stale / invalid entries from the LRU list.
local function prune_lru()
  local clean = {}
  for _, buf in ipairs(lru) do
    if vim.api.nvim_buf_is_valid(buf) then
      table.insert(clean, buf)
    end
  end
  lru = clean
end

--- Close the oldest invisible managed buffers until we're within the limit.
local function evict()
  prune_lru()

  -- Build an ordered list of hidden managed buffers (oldest first).
  local hidden = {}
  for _, buf in ipairs(lru) do
    if is_managed(buf) and not is_visible(buf) then
      table.insert(hidden, buf)
    end
  end

  -- Drop from the front (LRU end) until we're within the limit.
  while #hidden > cfg.max_hidden do
    local victim = table.remove(hidden, 1)
    -- Never close a modified buffer silently.
    if not vim.bo[victim].modified then
      -- Remove from lru first so a BufDelete autocmd doesn't double-fire.
      for i, b in ipairs(lru) do
        if b == victim then table.remove(lru, i); break end
      end
      -- force=false: honours 'hidden', won't error on a visible buffer.
      pcall(vim.api.nvim_buf_delete, victim, { force = false })
    end
  end
end

--- Optional: show current LRU state (for debugging).
function M.status()
  prune_lru()
  local lines = { string.format("max_hidden = %d", cfg.max_hidden), "" }
  for i, buf in ipairs(lru) do
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")
    local visible = is_visible(buf) and " [visible]" or ""
    local modified = vim.bo[buf].modified and " [+]" or ""
    table.insert(lines, string.format("  %2d. buf#%d%s%s  %s", i, buf, visible, modified, name))
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "buf_lru" })
end

--- Seed the LRU list with buffers that already exist at setup time.
--- Visible buffers are placed at the MRU end; hidden ones at the LRU end.
--- Also exposed as M.init so it can be called manually or via a user command.
local function init_existing_buffers()
  local visible, hidden = {}, {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_managed(buf) then
      if is_visible(buf) then
        table.insert(visible, buf)
      else
        table.insert(hidden, buf)
      end
    end
  end
  -- Hidden buffers go in first (oldest), visible ones last (newest).
  for _, buf in ipairs(hidden)  do table.insert(lru, buf) end
  for _, buf in ipairs(visible) do table.insert(lru, buf) end
  vim.schedule(evict)
end

M.init = init_existing_buffers

function M.setup(opts)
  cfg = vim.tbl_deep_extend("force", cfg, opts or {})

  local group = vim.api.nvim_create_augroup("BufLRU", { clear = true })

  vim.api.nvim_create_user_command("BufLruInit",   M.init,   { desc = "Re-seed buf_lru with all current buffers" })
  vim.api.nvim_create_user_command("BufLruStatus", M.status, { desc = "Show buf_lru LRU state" })

  -- Track every buffer we enter; evict after each access.
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      if is_managed(ev.buf) then
        touch(ev.buf)
        -- Schedule so the buffer is fully entered before we attempt deletion.
        vim.schedule(evict)
      end
    end,
  })

  -- Keep lru clean when buffers are deleted by other means.
  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(ev)
      for i, b in ipairs(lru) do
        if b == ev.buf then table.remove(lru, i); break end
      end
    end,
  })
end

return M
