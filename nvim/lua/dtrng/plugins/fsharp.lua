return {
  'ionide/Ionide-vim',
  ft = { 'fsharp', 'fsharp_project' },
  config = function()
    -- Force Ionide to use the global dotnet tool, not Mason
    vim.g['fsharp#fsautocomplete_command'] = {
      'fsautocomplete',
    }

     -- Disable analyzers
    vim.g['fsharp#unused_opens_analyzer'] = 0
    vim.g['fsharp#unused_declarations_analyzer'] = 0
    vim.g['fsharp#simplify_name_analyzer'] = 0
    vim.g['fsharp#resolve_namespaces'] = 0

    -- Disable background services
    vim.g['fsharp#enable_background_services'] = 0
    vim.g['fsharp#external_autocomplete'] = 0

    -- Disable codelens
    vim.g['fsharp#enable_reference_code_lens'] = 0

    -- Limit project discovery
    vim.g['fsharp#workspace_mode_peek_deepness'] = 0
    vim.g['fsharp#automatic_workspace_init'] = 0

    -- Exclude noise dirs
    vim.g['fsharp#exclude_project_directories'] = { 'bin', 'obj', '.git' }
  end,
}
