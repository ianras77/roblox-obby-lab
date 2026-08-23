--!strict

-- One place for network names and the authority behind each message.
local RemoteContracts = {
  Progress = {
    name = "ObbyProgress",
    direction = "server_to_client",
    payload = "{ stage: number, total: number, mode: string, highestChapter: number?, chapterId: string?, chapterName: string?, mechanic: string?, flavor: string?, initialized: boolean?, runStarted: boolean?, elapsedMs: number? }",
  },
  Keys = {
    name = "KeyProgress",
    direction = "server_to_client",
    payload = "{ found: number, total: number, keyId: string }",
  },
  Finale = {
    name = "FinaleSpotlight",
    direction = "server_to_client",
    payload = "{ stage: number, mode: string, elapsedMs: number?, bestRunMs: number?, deaths: number, keys: number, totalKeys: number?, bestChapterMs: table }",
  },
  SetSettings = {
    name = "SetAccessibilitySettings",
    direction = "client_to_server",
    payload = "{ key: string, enabled: boolean | number }",
    rateLimitSeconds = 0.2,
  },
  SetMode = {
    name = "SetRunMode",
    direction = "client_to_server",
    payload = "{ mode: Adventure | TimeTrial | Practice }",
    rateLimitSeconds = 1,
  },
  PracticeStage = {
    name = "SetPracticeStage",
    direction = "client_to_server",
    payload = "{ stage: integer }",
    rateLimitSeconds = 1,
  },
  State = {
    name = "GetObbyState",
    direction = "client_to_server_function",
    payload = "{ stage: number, total: number, mode: string, highestChapter: number, keys: number, totalKeys: number, collectedKeys: table, settings: table, runStarted: boolean, elapsedMs: number, chapter: table }",
  },
}

return RemoteContracts
