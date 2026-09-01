# git-file-history.nvim

Browse complete historical versions of the current file without opening a diff.

The plugin is currently developed locally as part of this Neovim configuration.

## Usage

- `<leader>gh` opens the newest committed version beside the current file.
- `<leader>gH` opens a Telescope picker listing commits with a file preview.
- `[h` moves to an older committed version.
- `]h` moves to a newer committed version.
- `q` closes the history window.

File renames are followed across history. The history window is a read-only
scratch buffer and preserves the source buffer's filetype.

The Telescope picker is a separate, optional interface. It lists the abbreviated
commit hash and subject on the left and previews the selected historical version
on the right. Filtering matches both the hash and commit subject.

## Configuration

```lua
require("git-file-history").setup({
  split = "right", -- right, left, above, below, or false
  keymaps = {
    older = "[h",
    newer = "]h",
    close = "q",
  },
})
```

Setting `split = false` replaces the current window's buffer, allowing callers
to create and arrange their own split before calling `open()`.
