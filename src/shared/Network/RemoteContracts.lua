--!strict

-- One place for network names and the authority behind each message.
local RemoteContracts = {
  Progress = {
    name = "ObbyProgress",
    direction = "server_to_client",
    payload = "{ stage: number, total: number, initialized: boolean? }",
  },
  Keys = {
    name = "KeyProgress",
    direction = "server_to_client",
    payload = "{ found: number, total: number, keyId: string? }",
  },
  Finale = {
    name = "FinaleSpotlight",
    direction = "server_to_client",
    payload = "{ stage: number }",
  },
  SetSettings = {
    name = "SetAccessibilitySettings",
    direction = "client_to_server",
    payload = "{ key: string, enabled: boolean }",
    rateLimitSeconds = 0.2,
  },
  SetMode = {
    name = "SetRunMode",
    direction = "client_to_server",
    payload = "{ mode: Adventure | TimeTrial | Practice }",
    rateLimitSeconds = 1,
  },
}

return RemoteContracts
