local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local ObstacleConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ObstacleConfig"))
local WorldBuilder = require(script.Parent.Parent.WorldGen.WorldBuilder)
local CheckpointService = require(script.Parent.CheckpointService)
local Maid = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("Maid"))
local RunStateService = require(script.Parent.RunStateService)
local RemoteContracts = require(ReplicatedStorage:WaitForChild("Network"):WaitForChild("RemoteContracts"))
local AnalyticsService = require(script.Parent.AnalyticsService)

local function resolveDirection(part)
  local axisAttr = part:GetAttribute("Axis") or part:GetAttribute("Direction")
  if typeof(axisAttr) == "Vector3" and axisAttr.Magnitude > 0 then
    return axisAttr.Unit
  elseif typeof(axisAttr) == "string" then
    local axis = string.lower(axisAttr)
    if axis == "x" then
      return Vector3.new(1, 0, 0)
    elseif axis == "y" then
      return Vector3.new(0, 1, 0)
    elseif axis == "-x" then
      return Vector3.new(-1, 0, 0)
    elseif axis == "-y" then
      return Vector3.new(0, -1, 0)
    elseif axis == "-z" then
      return Vector3.new(0, 0, -1)
    end
  end
  -- Default keeps backward-compatible motion along local Z
  return Vector3.new(0, 0, 1)
end

local ObbyService = {}
ObbyService.__index = ObbyService

local function countKeys(profile)
  local count = 0
  for _ in pairs(profile.collectedKeys) do
    count += 1
  end
  return count
end

local function getChapterPresentation(stages, stageIndex)
  local stage = stages[stageIndex]
  if not stage or not stage.model then
    return {}
  end
  return {
    chapterId = stage.stageId,
    chapterName = stage.model:GetAttribute("ChapterName"),
    mechanic = stage.model:GetAttribute("PrimaryMechanic"),
    flavor = stage.model:GetAttribute("ChapterFlavor"),
  }
end

local function getLivePlayerRoot(hit)
  local character = hit.Parent
  local player = character and Players:GetPlayerFromCharacter(character)
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  local root = character and character:FindFirstChild("HumanoidRootPart")
  if player and humanoid and humanoid.Health > 0 and root then
    return root
  end
  return nil
end

local function hasNearbyPlayer(position, radius)
  local radiusSquared = radius * radius
  for _, player in ipairs(Players:GetPlayers()) do
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") and (root.Position - position).Magnitude ^ 2 <= radiusSquared then
      return true
    end
  end
  return false
end

local function bindSettings(self)
  local events = ReplicatedStorage:FindFirstChild("SharedEvents")
  local event = events and events:FindFirstChild(RemoteContracts.SetSettings.name)
  if not event then
    return
  end
  local lastCall = {}
  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    lastCall[player] = nil
  end))
  local allowed = {
    reducedMotion = true,
    reduceFlashes = true,
    highContrast = true,
    largeText = true,
    lowParticles = true,
    showTimer = true,
    masterVolume = "volume",
    musicVolume = "volume",
    sfxVolume = "volume",
    uiScale = "scale",
  }
  self.maid:Give(event.OnServerEvent:Connect(function(player, key, enabled)
    if type(key) ~= "string" or not allowed[key] then
      return
    end
    if allowed[key] == true and type(enabled) ~= "boolean" then
      return
    end
    local minimum = allowed[key] == "scale" and 0.8 or 0
    local maximum = allowed[key] == "scale" and 1.5 or 1
    if
      (allowed[key] == "volume" or allowed[key] == "scale")
      and (type(enabled) ~= "number" or enabled ~= enabled or enabled < minimum or enabled > maximum)
    then
      return
    end
    if not self.checkpoints:isLoaded(player) then
      return
    end
    local now = os.clock()
    if now - (lastCall[player] or 0) < 0.2 then
      return
    end
    lastCall[player] = now
    local profile = self.checkpoints:getProfile(player)
    profile.settings[key] = enabled
  end))
end

local function bindRunModes(self)
  local events = ReplicatedStorage:FindFirstChild("SharedEvents")
  local event = events and events:FindFirstChild(RemoteContracts.SetMode.name)
  if not event then
    return
  end
  local lastCall = {}
  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    lastCall[player] = nil
  end))
  self.maid:Give(event.OnServerEvent:Connect(function(player, mode)
    if type(mode) ~= "string" then
      return
    end
    -- Practice requires a separately authorized chapter selection below; it
    -- must never be entered through the generic mode remote.
    if mode == "Practice" then
      return
    end
    if not self.checkpoints:isLoaded(player) then
      return
    end
    if mode == "TimeTrial" and self.checkpoints:getProfile(player).completionCount < 1 then
      return
    end
    local now = os.clock()
    if now - (lastCall[player] or 0) < 1 then
      return
    end
    lastCall[player] = now
    if not self.runState:setMode(player, mode) then
      return
    end
    if mode == "TimeTrial" then
      self.checkpoints:resetForTimeTrial(player)
      if self.world.startGate then
        self.checkpoints:teleportToCFrame(player, self.world.startGate.CFrame * CFrame.new(-8, 0, 0))
      end
    elseif mode == "Adventure" then
      self.checkpoints:resetForAdventure(player)
      if self.world.startGate then
        self.checkpoints:teleportToCFrame(player, self.world.startGate.CFrame * CFrame.new(-8, 0, 0))
      end
    end
    self.world.progressEvent:FireClient(player, {
      stage = player:GetAttribute("Checkpoint") or 0,
      total = self.world.totalStages,
      highestChapter = self.checkpoints and self.checkpoints:getProfile(player).highestChapter or 0,
      mode = mode,
      runStarted = mode ~= "TimeTrial",
      elapsedMs = 0,
    })
  end))
end

local function bindPracticeStage(self)
  local events = ReplicatedStorage:FindFirstChild("SharedEvents")
  local event = events and events:FindFirstChild(RemoteContracts.PracticeStage.name)
  if not event then
    return
  end
  local lastCall = {}
  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    lastCall[player] = nil
  end))
  self.maid:Give(event.OnServerEvent:Connect(function(player, stage)
    if type(stage) ~= "number" or stage % 1 ~= 0 or stage < 1 or stage > self.world.totalStages then
      return
    end
    if os.clock() - (lastCall[player] or 0) < 1 then
      return
    end
    if not self.checkpoints:isLoaded(player) then
      return
    end
    local profile = self.checkpoints:getProfile(player)
    if profile.highestChapter < stage then
      return
    end
    lastCall[player] = os.clock()
    self.runState:setMode(player, "Practice")
    if not self.checkpoints:setPracticeCheckpoint(player, stage) then
      return
    end
    self.checkpoints:teleportToStage(player, stage)
    self.world.progressEvent:FireClient(player, {
      stage = stage,
      total = self.world.totalStages,
      highestChapter = self.checkpoints and self.checkpoints:getProfile(player).highestChapter or 0,
      mode = "Practice",
    })
  end))
end

function ObbyService.new()
  if ObbyService._instance then
    return ObbyService._instance
  end
  local self = setmetatable({}, ObbyService)
  self.maid = Maid.new()
  self.behaviors = {}
  self.clock = 0
  self.cosmeticClock = 0
  self.analytics = AnalyticsService.new(GameConfig.EnableAnalytics)
  self.queryClock = 0
  self.riderQueryClock = 0
  self.world = WorldBuilder.buildWorld(GameConfig.Seed)
  self.world.stateFunction.OnServerInvoke = function(player)
    local run = self.runState and self.runState:get(player)
    local stage = player:GetAttribute("Checkpoint") or 0
    return {
      stage = stage,
      total = self.world.totalStages,
      mode = player:GetAttribute("RunMode") or "Adventure",
      highestChapter = self.checkpoints and self.checkpoints:getProfile(player).highestChapter or 0,
      keys = countKeys(self.checkpoints and self.checkpoints:getProfile(player) or { collectedKeys = {} }),
      totalKeys = self.totalKeys,
      collectedKeys = self.checkpoints and self.checkpoints:getProfile(player).collectedKeys or {},
      settings = self.checkpoints and self.checkpoints:getProfile(player).settings or {},
      runStarted = run and run.running or false,
      elapsedMs = self.runState and math.floor(self.runState:getElapsed(player) * 1000) or 0,
      chapter = getChapterPresentation(self.world.stages, stage),
    }
  end
  self.runState = RunStateService.new(self.world.totalStages, GameConfig.MinimumTimeTrialSeconds)
  -- Count authored collectibles before CheckpointService can emit the first
  -- initialized state to a player-loading task.
  self.totalKeys = #CollectionService:GetTagged("KeyCollectible")
  self.checkpoints = CheckpointService.new(
    self.world.stages,
    self.world.progressEvent,
    self.runState,
    self.analytics,
    function()
      return self.totalKeys
    end
  )
  self.checkpoints:bindCheckpoints()
  self.keyProgress = {}
  self.collectedKeys = {}
  bindSettings(self)
  bindRunModes(self)
  bindPracticeStage(self)
  self:scanBehaviors()
  self:hookCommands()
  self:startHeartbeat()
  ObbyService._instance = self
  workspace:SetAttribute("ObbyServiceReady", true)
  return self
end

function ObbyService:hookCommands()
  local function isAllowed(player)
    if RunService:IsStudio() then
      return true
    end
    for _, id in ipairs(GameConfig.AllowlistUserIds) do
      if id == player.UserId then
        return true
      end
    end
    return false
  end

  local lastCommand = {}
  local function dispatch(player, msg)
    if not GameConfig.DevCommandsEnabled or not isAllowed(player) then
      return
    end
    local now = os.clock()
    if now - (lastCommand[player] or 0) < GameConfig.DevCommandCooldownSeconds then
      return
    end
    local command, arg = string.match(msg, "^/(%w+)%s*(.-)%s*$")
    if command == "rebuild" then
      lastCommand[player] = now
      self:rebuild(self.world.seed)
    elseif command == "reseed" then
      local newSeed = math.floor(tonumber(arg) or os.time())
      if newSeed < 0 or newSeed > GameConfig.MaxDevSeed then
        return
      end
      lastCommand[player] = now
      self:rebuild(newSeed)
    elseif command == "stage" then
      local target = tonumber(arg)
      local maxStage = math.min(GameConfig.MaxDevStage, #self.world.stages)
      if target and target % 1 == 0 and target >= 1 and target <= maxStage then
        lastCommand[player] = now
        self.checkpoints:teleportToStage(player, target)
      end
    end
  end

  local modernCommands = typeof(TextChatService) == "Instance"
  if modernCommands then
    for _, definition in ipairs({
      { name = "ToadsRebuildCommand", alias = "/rebuild" },
      { name = "ToadsReseedCommand", alias = "/reseed" },
      { name = "ToadsStageCommand", alias = "/stage" },
    }) do
      local command = TextChatService:FindFirstChild(definition.name)
      if not command then
        command = Instance.new("TextChatCommand")
        command.Name = definition.name
        command.PrimaryAlias = definition.alias
        command.Parent = TextChatService
      end
      self.maid:Give(command.Triggered:Connect(function(textSource, unfilteredText)
        local player = Players:GetPlayerByUserId(textSource.UserId)
        if player then
          dispatch(player, unfilteredText)
        end
      end))
    end
  else
    for _, player in ipairs(Players:GetPlayers()) do
      self.maid:Give(player.Chatted:Connect(function(msg)
        dispatch(player, msg)
      end))
    end
    self.maid:Give(Players.PlayerAdded:Connect(function(player)
      self.maid:Give(player.Chatted:Connect(function(msg)
        dispatch(player, msg)
      end))
    end))
  end
  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    lastCommand[player] = nil
  end))
  self.maid:Give(Players.PlayerRemoving:Connect(function(player)
    self.keyProgress[player] = nil
    self.collectedKeys[player] = nil
  end))
end

function ObbyService:registerKey(part)
  local keyId = part:GetAttribute("KeyId")
  if type(keyId) ~= "string" or #keyId == 0 or #keyId > 80 then
    warn("[Keys] collectible missing stable KeyId", part:GetFullName())
    return
  end
  self.totalKeys = self.totalKeys + 1
  self.maid:Give(part.Touched:Connect(function(hit)
    local player = Players:GetPlayerFromCharacter(hit.Parent)
    if not player or not part.Parent or not self.checkpoints:isLoaded(player) then
      return
    end
    local root = hit.Parent:FindFirstChild("HumanoidRootPart")
    local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 or (root.Position - part.Position).Magnitude > 18 then
      return
    end
    self.collectedKeys[player] = self.collectedKeys[player] or {}
    if self.collectedKeys[player][keyId] or not self.checkpoints:markKey(player, keyId) then
      return
    end
    self.collectedKeys[player][keyId] = true
    self.analytics:track(player, "golden_key_discovered", { chapter = part:GetAttribute("StageIndex") })
    self.keyProgress[player] = 0
    for _ in pairs(self.checkpoints:getProfile(player).collectedKeys) do
      self.keyProgress[player] += 1
    end
    local sound = part:FindFirstChildOfClass("Sound")
    if sound then
      sound:Play()
    end
    if self.world.keyEvent then
      self.world.keyEvent:FireClient(player, {
        found = self.keyProgress[player],
        total = self.totalKeys,
        keyId = keyId,
      })
    end
  end))
end

function ObbyService:scanBehaviors()
  self.behaviors = {
    movingPlatforms = {},
    rotators = {},
    timedTiles = {},
    conveyors = {},
    bouncePads = {},
    windZones = {},
    lasers = {},
    lava = {},
    beacons = {},
    carts = {},
    pads = {},
    gates = {},
    bossGavels = {},
    fallingPlatforms = {},
  }
  self.gateTimers = {}

  local function add(tag, handler)
    for _, inst in ipairs(CollectionService:GetTagged(tag)) do
      if self.world and self.world.model and inst:IsDescendantOf(self.world.model) then
        handler(inst)
      end
    end
  end

  add("MovingPlatform", function(part)
    local amplitude = part:GetAttribute("Amplitude")
    if amplitude == nil then
      amplitude = 10
    end
    amplitude = math.abs(amplitude)
    table.insert(self.behaviors.movingPlatforms, {
      part = part,
      origin = part.CFrame,
      amplitude = amplitude,
      speed = part:GetAttribute("Speed") or ObstacleConfig.MovingPlatformSpeed,
      direction = resolveDirection(part),
      phase = part:GetAttribute("Phase") or 0,
      carryPlayers = part:GetAttribute("CarryPlayers") ~= false,
      lastPos = part.Position,
      riders = {},
    })
  end)

  add("Rotator", function(part)
    table.insert(self.behaviors.rotators, {
      part = part,
      speed = part:GetAttribute("RotSpeed") or ObstacleConfig.RotatorSpeed,
    })
  end)

  add("BossGavel", function(part)
    table.insert(self.behaviors.bossGavels, {
      part = part,
      origin = part.CFrame,
      speed = part:GetAttribute("SlamSpeed") or 2.5,
      angle = part:GetAttribute("SlamAngle") or math.rad(65),
    })
  end)

  add("TimedTile", function(part)
    table.insert(self.behaviors.timedTiles, {
      part = part,
      cycle = part:GetAttribute("Cycle") or ObstacleConfig.TimedTileInterval,
      t = 0,
    })
  end)

  add("Conveyor", function(part)
    table.insert(self.behaviors.conveyors, {
      part = part,
      speed = part:GetAttribute("Speed") or ObstacleConfig.ConveyorSpeed,
    })
    self.maid:Give(part.Touched:Connect(function(hit)
      local humanoidRoot = getLivePlayerRoot(hit)
      if humanoidRoot then
        local vel = humanoidRoot.AssemblyLinearVelocity
        local direction = part.CFrame.LookVector * (part:GetAttribute("Speed") or ObstacleConfig.ConveyorSpeed)
        humanoidRoot.AssemblyLinearVelocity = Vector3.new(direction.X, vel.Y, direction.Z)
      end
    end))
  end)

  add("BouncePad", function(part)
    local power = part:GetAttribute("Power") or ObstacleConfig.BouncePower
    self.maid:Give(part.Touched:Connect(function(hit)
      local humanoidRoot = getLivePlayerRoot(hit)
      if humanoidRoot then
        humanoidRoot.AssemblyLinearVelocity =
          Vector3.new(humanoidRoot.AssemblyLinearVelocity.X, power, humanoidRoot.AssemblyLinearVelocity.Z)
      end
    end))
    table.insert(self.behaviors.bouncePads, part)
  end)

  add("WindZone", function(part)
    table.insert(self.behaviors.windZones, {
      part = part,
      force = part:GetAttribute("Force") or ObstacleConfig.WindForce,
    })
  end)

  add("Laser", function(part)
    table.insert(self.behaviors.lasers, {
      part = part,
      cycle = part:GetAttribute("Cycle") or ObstacleConfig.LaserCycleTime,
      phase = part:GetAttribute("Phase") or 1,
    })
  end)

  add("Lava", function(part)
    table.insert(self.behaviors.lava, {
      part = part,
      speed = part:GetAttribute("RiseSpeed") or ObstacleConfig.LavaRiseSpeed,
      floorY = part:GetAttribute("FloorY") or part.Position.Y,
    })
  end)

  add("Beacon", function(part)
    local gameplayTags = {
      MovingPlatform = true,
      BouncePad = true,
      FallingPlatform = true,
      Conveyor = true,
      TimedTile = true,
      Laser = true,
      KillBrick = true,
      WindZone = true,
      PressurePad = true,
      Gate = true,
      Cart = true,
    }
    for tag in pairs(gameplayTags) do
      if CollectionService:HasTag(part, tag) or part:GetAttribute("PhysicsDecor") == true then
        return
      end
    end
    table.insert(self.behaviors.beacons, {
      part = part,
      origin = part.CFrame,
    })
  end)

  add("Cart", function(part)
    part:SetNetworkOwner(nil)
    table.insert(self.behaviors.carts, {
      base = part,
      seat = part.Parent:FindFirstChild("Seat"),
      force = part:FindFirstChildOfClass("LinearVelocity"),
      origin = part.CFrame,
      elapsed = 0,
      emptyTime = 0,
    })
  end)

  add("Gate", function(part)
    local id = part:GetAttribute("GateId") or part:GetFullName()
    self.behaviors.gates[id] = part
    self.gateTimers[id] = 0
  end)

  add("PressurePad", function(part)
    table.insert(self.behaviors.pads, {
      part = part,
      gateId = part:GetAttribute("GateId"),
      active = false,
    })
  end)

  add("KeyCollectible", function(part)
    self:registerKey(part)
  end)

  add("RunStartGate", function(part)
    self.maid:Give(part.Touched:Connect(function(hit)
      local player = Players:GetPlayerFromCharacter(hit.Parent)
      local state = player and self.runState:get(player)
      if
        player
        and self.checkpoints:isLoaded(player)
        and state.mode == "TimeTrial"
        and not state.running
        and self.runState:startAtGate(player, part)
      then
        self.checkpoints:resetForTimeTrial(player)
        self.world.progressEvent:FireClient(player, {
          stage = player:GetAttribute("Checkpoint") or 0,
          total = self.world.totalStages,
          mode = "TimeTrial",
          runStarted = true,
          elapsedMs = 0,
        })
      end
    end))
  end)

  add("KillBrick", function(part)
    -- Humanoids are instance keys so defeated/removed characters do not keep
    -- a permanent entry in the debounce table.
    local lastHit = setmetatable({}, { __mode = "k" })
    self.maid:Give(part.Touched:Connect(function(hit)
      local character = hit.Parent
      local player = character and Players:GetPlayerFromCharacter(character)
      local humanoid = character and character:FindFirstChildOfClass("Humanoid")
      local root = character and character:FindFirstChild("HumanoidRootPart")
      if player and humanoid and root and humanoid.Health > 0 then
        local now = os.clock()
        if now - (lastHit[humanoid] or 0) < 0.25 then
          return
        end
        lastHit[humanoid] = now
        humanoid.Health = 0
      end
    end))
  end)

  add("FallingPlatform", function(part)
    local entry = {
      part = part,
      origin = part.CFrame,
      dropDelay = part:GetAttribute("DropDelay") or ObstacleConfig.FallingPlatformDelay,
      respawnTime = part:GetAttribute("RespawnTime") or ObstacleConfig.FallingPlatformRespawn,
      state = "ready",
      timer = 0,
    }
    table.insert(self.behaviors.fallingPlatforms, entry)
    self.maid:Give(part.Touched:Connect(function(hit)
      local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
      if humanoid and humanoid.Health > 0 and entry.state == "ready" then
        entry.state = "arming"
        entry.timer = 0
      end
    end))
  end)

  self.totalKeys = #CollectionService:GetTagged("KeyCollectible")
end

-- Move any players riding on a platform by the same translation vector so they don't get left behind.
function ObbyService:carryRiders(touching, translation, dt)
  if #touching == 0 then
    return
  end

  local velocity = translation / math.max(dt, 1 / 60)
  local movedCharacters = {}
  for _, part in ipairs(touching) do
    local character = part.Parent
    if character and not movedCharacters[character] then
      local humanoid = character:FindFirstChildOfClass("Humanoid")
      local hrp = character:FindFirstChild("HumanoidRootPart")
      if humanoid and humanoid.Health > 0 and hrp then
        movedCharacters[character] = true
        hrp.CFrame = hrp.CFrame + translation
        local currentVelocity = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, currentVelocity.Y, velocity.Z)
      end
    end
  end
end

function ObbyService:startHeartbeat()
  self.maid:Give(RunService.Heartbeat:Connect(function(dt)
    self.clock = self.clock + dt
    self.cosmeticClock = self.cosmeticClock + dt
    self.queryClock = self.queryClock + dt
    self.riderQueryClock = self.riderQueryClock + dt
    local tickNow = self.clock
    if self.riderQueryClock >= 0.05 then
      self.riderQueryClock = 0
      for _, item in ipairs(self.behaviors.movingPlatforms) do
        if item.part and item.part.Parent and hasNearbyPlayer(item.part.Position, GameConfig.ActiveMechanicRadius) then
          item.riders = item.part:GetTouchingParts()
        else
          item.riders = {}
        end
      end
    end
    for _, item in ipairs(self.behaviors.movingPlatforms) do
      if item.part and item.part.Parent and hasNearbyPlayer(item.part.Position, GameConfig.ActiveMechanicRadius) then
        local offsetScalar = math.sin(tickNow * item.speed + item.phase) * item.amplitude
        local offset = item.direction * offsetScalar
        local cf = item.origin * CFrame.new(offset)
        local lastPos = item.lastPos or item.part.Position
        item.part.CFrame = cf
        item.lastPos = cf.Position

        local translation = item.lastPos - lastPos
        if item.carryPlayers and translation.Magnitude > 0.01 then
          self:carryRiders(item.riders, translation, dt)
        end
      end
    end

    if self.cosmeticClock >= 1 / 30 then
      local cosmeticDt = self.cosmeticClock
      self.cosmeticClock = 0
      for _, item in ipairs(self.behaviors.rotators) do
        if item.part and item.part.Parent and hasNearbyPlayer(item.part.Position, 180) then
          item.part.CFrame = item.part.CFrame * CFrame.Angles(0, item.speed * cosmeticDt, 0)
        end
      end

      for _, item in ipairs(self.behaviors.bossGavels) do
        if item.part and item.part.Parent and hasNearbyPlayer(item.part.Position, 180) then
          local t = math.sin(tickNow * item.speed)
          local pitch = t * item.angle
          item.part.CFrame = item.origin * CFrame.Angles(pitch, 0, 0)
        end
      end

      for _, item in ipairs(self.behaviors.timedTiles) do
        if item.part and item.part.Parent then
          item.t = item.t + cosmeticDt
          if hasNearbyPlayer(item.part.Position, 180) then
            local on = (item.t % item.cycle) > (item.cycle / 2)
            item.part.Transparency = on and 0 or 0.8
            item.part.CanCollide = on
          end
        end
      end
    end

    if self.queryClock >= 0.1 then
      local queryDt = self.queryClock
      self.queryClock = 0
      for _, item in ipairs(self.behaviors.windZones) do
        if item.part and item.part.Parent and hasNearbyPlayer(item.part.Position, GameConfig.ActiveMechanicRadius) then
          for _, touch in ipairs(item.part:GetTouchingParts()) do
            local hrp = touch.Parent and touch.Parent:FindFirstChild("HumanoidRootPart")
            if hrp then
              hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity
                + item.part.CFrame.RightVector * item.force * queryDt
            end
          end
        end
      end
      local gateActiveCount = {}
      for _, pad in ipairs(self.behaviors.pads) do
        if pad.part and pad.part.Parent and hasNearbyPlayer(pad.part.Position, GameConfig.ActiveMechanicRadius) then
          pad.active = false
          for _, p in ipairs(pad.part:GetTouchingParts()) do
            if p.Parent and p.Parent:FindFirstChild("HumanoidRootPart") then
              pad.active = true
              break
            end
          end
          if pad.active and pad.gateId then
            gateActiveCount[pad.gateId] = (gateActiveCount[pad.gateId] or 0) + 1
          end
        end
      end
      local playerCount = #Players:GetPlayers()
      for gateId, gate in pairs(self.behaviors.gates) do
        if gate and gate.Parent then
          local hits = gateActiveCount[gateId] or 0
          if hits >= 2 then
            self.gateTimers[gateId] = 0
            gate.Transparency = 0.9
            gate.CanCollide = false
            gate.Color = Color3.fromRGB(120, 255, 120)
          else
            if hits >= 1 and playerCount <= 1 then
              self.gateTimers[gateId] = (self.gateTimers[gateId] or 0) + queryDt
            else
              self.gateTimers[gateId] = 0
            end
            local soloOpen = (self.gateTimers[gateId] or 0) >= 6
            gate.Transparency = soloOpen and 0.9 or 0
            gate.CanCollide = not soloOpen
            gate.Color = soloOpen and Color3.fromRGB(200, 255, 200) or Color3.fromRGB(255, 120, 120)
          end
        end
      end
    end

    for _, item in ipairs(self.behaviors.lasers) do
      if item.part and item.part.Parent then
        local active = (tickNow + item.phase) % item.cycle < (item.cycle / 2)
        item.part.Transparency = active and 0 or 1
        item.part.CanTouch = active
        item.part.CanCollide = active
        local emitter = item.part:FindFirstChildOfClass("ParticleEmitter")
        if emitter then
          emitter.Enabled = active
        end
      end
    end

    for _, item in ipairs(self.behaviors.lava) do
      if item.part and item.part.Parent then
        local pos = item.part.Position
        local y = item.floorY - 8 + math.abs(math.sin(tickNow * (item.speed / 6))) * 12
        item.part.Position = Vector3.new(pos.X, y, pos.Z)
      end
    end

    for _, item in ipairs(self.behaviors.beacons) do
      if item.part and item.part.Parent and hasNearbyPlayer(item.part.Position, 180) then
        local bob = math.sin(tickNow * 1.5) * 0.5
        item.part.CFrame = item.origin * CFrame.new(0, bob, 0) * CFrame.Angles(0, dt * 1.2, 0)
      end
    end

    for _, item in ipairs(self.behaviors.carts) do
      if item.base and item.base.Parent and item.force then
        local occupied = item.seat and item.seat.Occupant ~= nil
        if occupied then
          item.emptyTime = 0
          item.elapsed += dt
          item.force.VectorVelocity = item.base.CFrame.LookVector * 40
        else
          item.emptyTime += dt
          item.force.VectorVelocity = Vector3.new()
        end
        local fellAway = item.base.Position.Y < item.origin.Position.Y - 30
        local timedOut = item.elapsed > 45
        local abandoned = item.elapsed > 0 and item.emptyTime > 5
        if fellAway or timedOut or abandoned then
          local occupant = item.seat and item.seat.Occupant
          if occupant then
            occupant.Sit = false
            local character = occupant.Parent
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
              root.CFrame = item.origin * CFrame.new(-6, 3, 0)
              root.AssemblyLinearVelocity = Vector3.new()
              root.AssemblyAngularVelocity = Vector3.new()
            end
          end
          item.base.AssemblyLinearVelocity = Vector3.new()
          item.base.AssemblyAngularVelocity = Vector3.new()
          item.base.CFrame = item.origin
          item.elapsed = 0
          item.emptyTime = 0
        end
      end
    end

    for _, item in ipairs(self.behaviors.fallingPlatforms) do
      local part = item.part
      if part and part.Parent then
        if item.state == "arming" then
          item.timer = item.timer + dt
          if item.timer >= item.dropDelay then
            part.Anchored = false
            item.state = "fallen"
            item.timer = 0
          end
        elseif item.state == "fallen" then
          item.timer = item.timer + dt
          if item.respawnTime > 0 and item.timer >= item.respawnTime then
            part.AssemblyLinearVelocity = Vector3.new()
            part.AssemblyAngularVelocity = Vector3.new()
            part.CFrame = item.origin
            part.Anchored = true
            item.state = "ready"
            item.timer = 0
          end
        end
      end
    end
  end))
end

function ObbyService:rebuild(seed)
  self.maid:DoCleaning()
  if self.checkpoints then
    self.checkpoints:destroy()
  end
  if self.runState then
    self.runState:destroy()
  end
  if self.world and self.world.model then
    self.world.model:Destroy()
  end
  self.clock = 0
  self.cosmeticClock = 0
  self.queryClock = 0
  self.riderQueryClock = 0
  self.world = WorldBuilder.buildWorld(seed)
  self.world.stateFunction.OnServerInvoke = function(player)
    local run = self.runState and self.runState:get(player)
    local stage = player:GetAttribute("Checkpoint") or 0
    return {
      stage = stage,
      total = self.world.totalStages,
      mode = player:GetAttribute("RunMode") or "Adventure",
      highestChapter = self.checkpoints and self.checkpoints:getProfile(player).highestChapter or 0,
      keys = countKeys(self.checkpoints and self.checkpoints:getProfile(player) or { collectedKeys = {} }),
      totalKeys = self.totalKeys,
      collectedKeys = self.checkpoints and self.checkpoints:getProfile(player).collectedKeys or {},
      settings = self.checkpoints and self.checkpoints:getProfile(player).settings or {},
      runStarted = run and run.running or false,
      elapsedMs = self.runState and math.floor(self.runState:getElapsed(player) * 1000) or 0,
      chapter = getChapterPresentation(self.world.stages, stage),
    }
  end
  self.runState = RunStateService.new(self.world.totalStages, GameConfig.MinimumTimeTrialSeconds)
  self.totalKeys = #CollectionService:GetTagged("KeyCollectible")
  self.checkpoints = CheckpointService.new(
    self.world.stages,
    self.world.progressEvent,
    self.runState,
    self.analytics,
    function()
      return self.totalKeys
    end
  )
  self.checkpoints:bindCheckpoints()
  self.keyProgress = {}
  bindSettings(self)
  bindRunModes(self)
  bindPracticeStage(self)
  self:scanBehaviors()
  self:hookCommands()
  self:startHeartbeat()
end

return ObbyService
