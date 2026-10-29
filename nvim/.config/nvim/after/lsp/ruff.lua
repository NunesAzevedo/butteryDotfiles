-- ruff (Python): linting only; formatting runs through conform (lua/configs/conform.lua).
return {
  on_attach = function(client)
    -- Let basedpyright answer hover requests (ruff's hover only explains lint codes)
    client.server_capabilities.hoverProvider = false
  end,
}
