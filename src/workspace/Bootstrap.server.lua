local ServerScriptService = game:GetService("ServerScriptService")

local function startObbyService()
  local ok, err = pcall(function()
    local ObbyService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("ObbyService"))
    ObbyService.new()
  end)
  if not ok then
    warn("[Bootstrap] Failed to start ObbyService", err)
  end
end

-- If the main server script already ran, this becomes a no-op due to the singleton guard.
if not workspace:GetAttribute("ObbyServiceReady") then
  startObbyService()
end
