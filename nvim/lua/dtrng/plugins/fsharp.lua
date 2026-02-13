return {
  'ionide/Ionide-vim',
  ft = { 'fsharp', 'fsharp_project' },
  config = function()
    -- Force Ionide to use the global dotnet tool, not Mason
    vim.g['fsharp#fsautocomplete_command'] = {
      'fsautocomplete',
    }
  end,
}
