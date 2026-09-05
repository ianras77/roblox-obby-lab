-- selene: allow(incorrect_standard_library_use)
-- selene: allow(shadowing)
-- Headless adapters, not a Roblox engine. Native Lune Instances/CFrames/Vector3s;
-- explicit virtual scheduler, signals, remotes and oriented-box ray intersections.
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Environment = {}
local V, CF = roblox.Vector3, roblox.CFrame

function Environment.new(placePath)
  local self = {
    time = 100,
    tasks = {},
    messages = {},
    warnings = {},
    players = {},
    analytics = {},
    stores = {},
    budget = 100,
    studio = true,
  }
  local methodOverrides, propertyOverrides, wrappers = {}, {}, {}
  local function methods(class, name, callback)
    methodOverrides[name] = methodOverrides[name] or {}
    table.insert(methodOverrides[name], { class = class, callback = callback })
  end
  local function props(class, name, getter, setter)
    propertyOverrides[name] = propertyOverrides[name] or {}
    table.insert(propertyOverrides[name], { class = class, get = getter, set = setter })
  end
  local function unwrap(value)
    return type(value) == "table" and rawget(value, "_native") or value
  end
  local wrap
  local function convert(value)
    if typeof(value) == "Instance" then
      return wrap(value)
    end
    if type(value) == "table" then
      local converted = {}
      for key, item in pairs(value) do
        converted[key] = convert(item)
      end
      return converted
    end
    return value
  end
  wrap = function(native)
    if wrappers[native] then
      return wrappers[native]
    end
    local proxy = { _native = native, __type = "Instance" }
    wrappers[native] = proxy
    setmetatable(proxy, {
      __index = function(instance, key)
        for _, override in ipairs(propertyOverrides[key] or {}) do
          if native:IsA(override.class) then
            return override.get(instance)
          end
        end
        for _, override in ipairs(methodOverrides[key] or {}) do
          if native:IsA(override.class) then
            return override.callback
          end
        end
        local value = native[key]
        if type(value) == "function" then
          return function(_, ...)
            local args = table.pack(...)
            for i = 1, args.n do
              args[i] = unwrap(args[i])
            end
            local results = table.pack(value(native, table.unpack(args, 1, args.n)))
            for i = 1, results.n do
              results[i] = convert(results[i])
            end
            return table.unpack(results, 1, results.n)
          end
        end
        return convert(value)
      end,
      __newindex = function(instance, key, value)
        for _, override in ipairs(propertyOverrides[key] or {}) do
          if native:IsA(override.class) then
            assert(override.set, "read-only adapter property " .. key)
            override.set(instance, value)
            return
          end
        end
        native[key] = unwrap(value)
      end,
    })
    return proxy
  end
  self.instance = {
    new = function(class)
      return wrap(roblox.Instance.new(class))
    end,
  }
  self.game = wrap(roblox.deserializePlace(fs.readFile(placePath)))
  self.workspace = self.game:GetService("Workspace")
  self.roblox = roblox
  local signals, values = {}, {}
  function self:resume(thread, ...)
    local ok, delay = coroutine.resume(thread, ...)
    assert(ok, tostring(delay) .. "\n" .. debug.traceback(thread))
    if coroutine.status(thread) ~= "dead" then
      table.insert(self.tasks, { thread = thread, due = self.time + (tonumber(delay) or 0) })
    end
  end
  self.task = {}
  function self.task.spawn(callback, ...)
    local thread = type(callback) == "thread" and callback or coroutine.create(callback)
    self:resume(thread, ...)
    return thread
  end
  function self.task.wait(seconds)
    return coroutine.yield(seconds or 0.03)
  end
  function self.task.delay(seconds, callback, ...)
    local args = table.pack(...)
    return self.task.spawn(function()
      self.task.wait(seconds)
      callback(table.unpack(args, 1, args.n))
    end)
  end
  self.task.defer = function(callback, ...)
    return self.task.delay(0, callback, ...)
  end
  function self:signal(instance, name)
    signals[instance] = signals[instance] or {}
    if not signals[instance][name] then
      local signal = { connections = {} }
      function signal:Connect(callback)
        if name == "Touched" then
          assert(instance.CanTouch, "Touched cannot connect while CanTouch=false")
        end
        local connection = { Connected = true, callback = callback, __type = "RBXScriptConnection" }
        function connection:Disconnect()
          self.Connected = false
        end
        table.insert(self.connections, connection)
        return connection
      end
      function signal:Fire(...)
        for _, connection in ipairs(table.clone(self.connections)) do
          if connection.Connected then
            self._env.task.spawn(connection.callback, ...)
          end
        end
      end
      function signal:Wait()
        error("Unexpected signal Wait in headless adapter: " .. name)
      end
      signal._env = self
      signals[instance][name] = signal
    end
    return signals[instance][name]
  end
  function self:advance(seconds, step, heartbeat)
    step = step or 0.05
    local target = self.time + seconds
    while self.time < target - 0.000001 do
      local dt = math.min(step, target - self.time)
      self.time += dt
      local ready = {}
      for index = #self.tasks, 1, -1 do
        if self.tasks[index].due <= self.time + 0.000001 then
          table.insert(ready, table.remove(self.tasks, index))
        end
      end
      for _, entry in ipairs(ready) do
        self:resume(entry.thread, dt)
      end
      if heartbeat ~= false then
        self:signal(self.game:GetService("RunService"), "Heartbeat"):Fire(dt)
      end
    end
  end
  local function stored(class, name, default)
    props(class, name, function(inst)
      return values[inst] and values[inst][name] or default
    end, function(inst, value)
      values[inst] = values[inst] or {}
      values[inst][name] = value
      self:signal(inst, "property:" .. name):Fire()
    end)
  end
  for _, definition in ipairs({
    { "RunService", "Heartbeat" },
    { "Players", "PlayerAdded" },
    { "Players", "PlayerRemoving" },
    { "Player", "CharacterAdded" },
    { "Player", "CharacterRemoving" },
    { "Player", "Chatted" },
    { "Instance", "DescendantAdded" },
    { "Humanoid", "Died" },
    { "BasePart", "Touched" },
    { "RemoteEvent", "OnServerEvent" },
    { "RemoteEvent", "OnClientEvent" },
    { "TextChatCommand", "Triggered" },
  }) do
    props(definition[1], definition[2], function(inst)
      return self:signal(inst, definition[2])
    end)
  end
  stored("Player", "Character", nil)
  stored("RemoteFunction", "OnServerInvoke", nil)
  stored("Humanoid", "MoveDirection", V.zero)
  stored("Humanoid", "Health", 100)
  stored("Humanoid", "FloorMaterial", roblox.Enum.Material.Plastic)
  stored("Seat", "Occupant", nil)
  stored("BasePart", "AssemblyLinearVelocity", V.zero)
  stored("BasePart", "AssemblyAngularVelocity", V.zero)
  props("BasePart", "Position", function(part)
    return part.CFrame.Position
  end, function(part, value)
    part.CFrame = CF.new(value) * part.CFrame.Rotation
  end)
  methods("BasePart", "SetNetworkOwner", function(part, owner)
    values[part] = values[part] or {}
    values[part].owner = owner or "server"
  end)
  methods("Instance", "WaitForChild", function(instance, name, timeout)
    local child = instance:FindFirstChild(name)
    local deadline = self.time + (timeout or 5)
    while not child and self.time < deadline do
      self.task.wait(0.05)
      child = instance:FindFirstChild(name)
    end
    return child
  end)
  methods("Instance", "GetPropertyChangedSignal", function(inst, name)
    return self:signal(inst, "property:" .. name)
  end)
  methods("Instance", "GetAttributeChangedSignal", function(inst, name)
    return self:signal(inst, "attribute:" .. name)
  end)
  methods("RunService", "IsStudio", function()
    return self.studio
  end)
  methods("RunService", "IsServer", function()
    return true
  end)
  methods("Players", "GetPlayers", function()
    return table.clone(self.players)
  end)
  methods("Players", "GetPlayerFromCharacter", function(_, character)
    for _, player in ipairs(self.players) do
      if player.Character == character then
        return player
      end
    end
  end)
  methods("Players", "GetPlayerByUserId", function(_, id)
    for _, player in ipairs(self.players) do
      if player.UserId == id then
        return player
      end
    end
  end)
  local tags = {}
  self.collection = {
    AddTag = function(_, part, tag)
      tags[tag] = tags[tag] or {}
      tags[tag][part] = true
    end,
    RemoveTag = function(_, part, tag)
      if tags[tag] then
        tags[tag][part] = nil
      end
    end,
    HasTag = function(_, part, tag)
      return tags[tag] and tags[tag][part] == true or false
    end,
    GetTagged = function(_, tag)
      local found = {}
      for part in pairs(tags[tag] or {}) do
        if part.Parent then
          table.insert(found, part)
        end
      end
      return found
    end,
  }
  local gameProxy = setmetatable({
    GetService = function(_, name)
      if name == "CollectionService" then
        return self.collection
      end
      return self.game:GetService(name)
    end,
  }, {
    __index = function(_, key)
      return self.game[key]
    end,
  })
  methods("CollectionService", "AddTag", function(_, part, tag)
    tags[tag] = tags[tag] or {}
    tags[tag][part] = true
  end)
  methods("CollectionService", "RemoveTag", function(_, part, tag)
    if tags[tag] then
      tags[tag][part] = nil
    end
  end)
  methods("CollectionService", "HasTag", function(_, part, tag)
    return tags[tag] and tags[tag][part] == true or false
  end)
  methods("CollectionService", "GetTagged", function(_, tag)
    local found = {}
    for part in pairs(tags[tag] or {}) do
      if part.Parent then
        table.insert(found, part)
      end
    end
    return found
  end)
  for _, name in ipairs({ "RegisterCollisionGroup", "CollisionGroupSetCollidable" }) do
    methods("PhysicsService", name, function() end)
  end
  methods("Sound", "Play", function() end)
  methods("ParticleEmitter", "Emit", function() end)
  methods("ContentProvider", "PreloadAsync", function() end)
  methods("RemoteEvent", "FireClient", function(remote, player, payload)
    table.insert(self.messages, { name = remote.Name, player = player, payload = payload, time = self.time })
  end)
  methods("RemoteEvent", "FireAllClients", function()
    error("Broadcast forbidden in headless contract")
  end)
  methods("DataModel", "BindToClose", function(_, callback)
    self.close = callback
  end)
  methods("Model", "MoveTo", function(model, position)
    local cf = model:GetBoundingBox()
    local delta = position - cf.Position
    for _, part in ipairs(model:GetDescendants()) do
      if part:IsA("BasePart") then
        part.CFrame += delta
      end
    end
  end)
  methods("Model", "GetBoundingBox", function(model)
    local lo, hi = V.new(math.huge, math.huge, math.huge), V.new(-math.huge, -math.huge, -math.huge)
    for _, part in ipairs(model:GetDescendants()) do
      if part:IsA("BasePart") then
        for _, x in ipairs({ -0.5, 0.5 }) do
          for _, y in ipairs({ -0.5, 0.5 }) do
            for _, z in ipairs({ -0.5, 0.5 }) do
              local pos = part.CFrame:PointToWorldSpace(part.Size * V.new(x, y, z))
              lo = V.new(math.min(lo.X, pos.X), math.min(lo.Y, pos.Y), math.min(lo.Z, pos.Z))
              hi = V.new(math.max(hi.X, pos.X), math.max(hi.Y, pos.Y), math.max(hi.Z, pos.Z))
            end
          end
        end
      end
    end
    if lo.X == math.huge then
      return CF.identity, V.zero
    end
    return CF.new((lo + hi) / 2), hi - lo
  end)
  -- Segment/OBB slab intersection. Engine contacts, terrain and swept collision are NOT simulated.
  local rayCache = {}
  self.invalidateGeometry = function()
    table.clear(rayCache)
  end
  methods("Workspace", "Raycast", function(_, origin, direction, params)
    local best, result = math.huge, nil
    for _, root in ipairs(params.FilterDescendantsInstances) do
      if not rayCache[root] then
        rayCache[root] = {}
        for _, part in ipairs(root:GetDescendants()) do
          if part:IsA("BasePart") and part.CanCollide then
            table.insert(rayCache[root], part)
          end
        end
      end
      for _, part in ipairs(rayCache[root]) do
        if not part.Parent or not part.CanCollide then
          continue
        end
        local radius = part.Size.Magnitude / 2 + direction.Magnitude
        if (origin - part.Position).Magnitude > radius then
          continue
        end
        local o, d = part.CFrame:PointToObjectSpace(origin), part.CFrame:VectorToObjectSpace(direction)
        local lo, hi = 0, 1
        for _, axis in ipairs({ "X", "Y", "Z" }) do
          local half = part.Size[axis] / 2
          if math.abs(d[axis]) < 0.000001 then
            if math.abs(o[axis]) > half then
              hi = -1
              break
            end
          else
            local a, b = (-half - o[axis]) / d[axis], (half - o[axis]) / d[axis]
            lo = math.max(lo, math.min(a, b))
            hi = math.min(hi, math.max(a, b))
          end
        end
        if lo <= hi and lo < best then
          best = lo
          result = { Instance = part, Position = origin + direction * lo, Distance = direction.Magnitude * lo }
        end
      end
    end
    return result
  end)
  methods("DataStoreService", "GetRequestBudgetForRequestType", function()
    return self.budget
  end)
  methods("DataStoreService", "GetDataStore", function(_, name)
    self.stores[name] = self.stores[name] or {}
    local store = self.stores[name]
    return {
      GetAsync = function(_, key)
        self.reads = (self.reads or 0) + 1
        if self.readDelay then
          self.task.wait(self.readDelay)
        end
        if self.failReads then
          error("injected datastore read failure")
        end
        return store[key]
      end,
      UpdateAsync = function(_, key, transform)
        self.writes = (self.writes or 0) + 1
        if self.failWrites then
          error("injected datastore write failure")
        end
        store[key] = transform(store[key])
        return store[key]
      end,
    }
  end)
  for _, name in ipairs({ "LogCustomEvent", "LogOnboardingFunnelStepEvent", "LogProgressionEvent" }) do
    methods("AnalyticsService", name, function(_, ...)
      if self.failAnalytics then
        error("injected analytics delivery failure")
      end
      table.insert(self.analytics, { method = name, args = table.pack(...) })
    end)
  end
  local cache = {}
  function self:require(module)
    assert(module.__type == "Instance" and module:IsA("ModuleScript"), "Only Rojo ModuleScripts may be loaded")
    if cache[module] ~= nil then
      return cache[module]
    end
    local env = table.clone(roblox)
    env.Instance = self.instance
    env.game = gameProxy
    env.workspace = self.workspace
    env.script = module
    env.require = function(target)
      return self:require(target)
    end
    env.task = self.task
    env.os = table.clone(os)
    env.os.clock = function()
      return self.time
    end
    env.tick = function()
      return self.time
    end
    env.typeof = function(value)
      return type(value) == "table" and value.__type or typeof(value)
    end
    env.warn = function(...)
      table.insert(self.warnings, table.concat({ ... }, " "))
    end
    env.RaycastParams = {
      new = function()
        return {}
      end,
    }
    env.Random = {
      new = function(seed)
        local value = seed
        local function nextValue()
          value = (value * 48271) % 2147483647
          return value / 2147483647
        end
        return {
          NextNumber = function(_, a, b)
            return a + (b - a) * nextValue()
          end,
          NextInteger = function(_, a, b)
            return math.floor(a + (b - a + 1) * nextValue())
          end,
        }
      end,
    }
    cache[module] = luau.load(module.Source, { environment = env, debugName = module:GetFullName() })()
    return cache[module]
  end
  function self:addPlayer(id, delayRoot)
    local player = self.instance.new("Player")
    player.Name = "TestPlayer" .. id
    player.UserId = id
    player.Parent = self.game:GetService("Players")
    table.insert(self.players, player)
    self:spawnCharacter(player, delayRoot)
    self:signal(player.Parent, "PlayerAdded"):Fire(player)
    return player
  end
  function self:spawnCharacter(player, delayRoot)
    if player.Character then
      self:signal(player, "CharacterRemoving"):Fire(player.Character)
      player.Character:Destroy()
    end
    local character = self.instance.new("Model")
    character.Name = player.Name
    character.Parent = self.workspace
    local humanoid = self.instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.Parent = character
    player.Character = character
    local function addRoot()
      local root = self.instance.new("Part")
      root.Name = "HumanoidRootPart"
      root.Size = V.new(2, 2, 1)
      root.CFrame = CF.new(0, 9, -20)
      root.Parent = character
      self:signal(character, "DescendantAdded"):Fire(root)
    end
    if delayRoot then
      self.task.delay(delayRoot, addRoot)
    else
      addRoot()
    end
    self:signal(player, "CharacterAdded"):Fire(character)
    return character
  end
  function self:removePlayer(player)
    self:signal(self.game:GetService("Players"), "PlayerRemoving"):Fire(player)
    for i, existing in ipairs(self.players) do
      if existing == player then
        table.remove(self.players, i)
        break
      end
    end
    if player.Character then
      player.Character:Destroy()
    end
    player.Parent = nil
  end
  function self:call(remote, player, ...)
    self:signal(remote, "OnServerEvent"):Fire(player, ...)
  end
  function self:messageCount(name, player)
    local count = 0
    for _, message in ipairs(self.messages) do
      if message.name == name and (not player or message.player == player) then
        count += 1
      end
    end
    return count
  end
  return self
end
return Environment
