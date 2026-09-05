local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Math = require(game:GetService("ReplicatedStorage").Util.MovementMath)
local MovementService = {}
function MovementService.start(world, maid, fail)
  local items = {}
  local clock, queryClock = 0, 0
  local tags = {
    "MovingPlatform",
    "Conveyor",
    "WindZone",
    "Laser",
    "TimedTile",
    "Rotator",
    "BouncePad",
    "Cart",
    "FallingPlatform",
    "KillBrick",
  }
  for _, tag in ipairs(tags) do
    for _, part in ipairs(CollectionService:GetTagged(tag)) do
      if part:IsDescendantOf(world.model) and part:IsA("BasePart") then
        if
          tag == "KillBrick"
          and (CollectionService:HasTag(part, "Laser") or CollectionService:HasTag(part, "TimedTile"))
        then
          continue
        end
        local entry = { part = part, tag = tag, origin = part.CFrame, time = 0, state = "ready", color = part.Color }
        if tag == "Cart" then
          part:SetNetworkOwner(nil)
        end
        table.insert(items, entry)
      end
    end
  end
  local lastBounce = setmetatable({}, { __mode = "k" })
  maid:Give(RunService.Heartbeat:Connect(function(dt)
    clock += dt
    queryClock += dt
    local query = queryClock >= 0.05
    local queryDt = math.min(queryClock, 0.25)
    if query then
      queryClock = 0
    end
    -- A single root list is bounded by connected players, never limbs or scenery.
    local roots = {}
    for _, player in ipairs(Players:GetPlayers()) do
      local character = player.Character
      local root = character and character:FindFirstChild("HumanoidRootPart")
      local humanoid = character and character:FindFirstChildOfClass("Humanoid")
      if root and humanoid and humanoid.Health > 0 then
        table.insert(roots, { root = root, player = player, humanoid = humanoid })
      end
    end
    local carried, influenced, bounced = {}, {}, {}
    local failed = {}
    for _, item in ipairs(items) do
      local part, tag = item.part, item.tag
      if not part.Parent then
        continue
      end
      local before = part.CFrame
      if tag == "MovingPlatform" then
        local period = part:GetAttribute("PeriodSeconds") or 5
        local amplitude = math.min(part:GetAttribute("Amplitude") or 4, 8)
        part.CFrame = item.origin * CFrame.new(math.sin(clock * Math.omega(period)) * amplitude, 0, 0)
      elseif tag == "Rotator" then
        part.CFrame = item.origin * CFrame.Angles(0, clock * (part:GetAttribute("RotSpeed") or 0.5), 0)
      elseif tag == "Laser" or tag == "TimedTile" then
        local state = Math.phase(clock, part:GetAttribute("Cycle") or 6, part:GetAttribute("WarningSeconds") or 0.9)
        part:SetAttribute("HazardState", state)
        part.CanTouch = state == "active"
        part.CanCollide = tag ~= "Laser" and state == "active"
        part.CanQuery = state == "active"
        part.Transparency = state == "active" and 0 or (state == "warning" and 0.35 or 0.9)
        part.Color = state == "active" and Color3.fromRGB(230, 70, 70) or Color3.fromRGB(250, 205, 80)
        local display = part:FindFirstChild("PhaseDisplay")
        if not display then
          display = Instance.new("BillboardGui")
          display.Name = "PhaseDisplay"
          display.Size = UDim2.fromOffset(160, 48)
          display.StudsOffset = Vector3.new(0, 5, 0)
          display.Parent = part
          local label = Instance.new("TextLabel")
          label.Size = UDim2.fromScale(1, 1)
          label.TextScaled = true
          label.Parent = display
        end
        display.TextLabel.Text = state == "active" and "X WAIT" or state == "warning" and "! WARNING" or "O CROSS"
      elseif tag == "Cart" then
        local force = part:FindFirstChildOfClass("LinearVelocity")
        local seat = part.Parent:FindFirstChild("Seat")
        if force then
          force.VectorVelocity = seat and seat.Occupant and item.origin.RightVector * 8 or Vector3.zero
        end
        if
          (part.Position - item.origin.Position).Magnitude > (part:GetAttribute("RideMaxDistance") or 48)
          or part.Position.Y < item.origin.Y - 10
        then
          if seat and seat.Occupant then
            seat.Occupant.Sit = false
          end
          part.CFrame = item.origin
          part.AssemblyLinearVelocity = Vector3.zero
          part.AssemblyAngularVelocity = Vector3.zero
        end
      elseif tag == "FallingPlatform" then
        if item.state == "arming" then
          item.time += dt
          part.Color = Color3.fromRGB(255, 180, 60)
          if item.time >= math.max(1.25, part:GetAttribute("DropDelay") or 1.5) then
            item.state = "fallen"
            item.time = 0
            part.CanCollide = false
            part.CanTouch = false
            part.Transparency = 0.85
          end
        elseif item.state == "fallen" then
          item.time += dt
          if item.time > 3 then
            -- Remain anchored; reset does not sweep a falling body through players.
            part.CFrame = item.origin
            part.CanCollide = true
            part.CanTouch = true
            part.Transparency = 0
            part.Color = item.color
            item.state = "ready"
          end
        end
      end
      for _, occupant in ipairs(roots) do
        local root = occupant.root
        local pos = before:PointToObjectSpace(root.Position)
        if
          query
          and not failed[root]
          and CollectionService:HasTag(part, "KillBrick")
          and Math.hazardActive(part:GetAttribute("HazardState"), part.CanTouch)
          and math.abs(pos.X) <= part.Size.X / 2 + 1.5
          and math.abs(pos.Z) <= part.Size.Z / 2 + 1.5
          and math.abs(pos.Y) <= part.Size.Y / 2 + 2
        then
          failed[root] = true
          fail(occupant.player, "hazard")
        end
        local onTop = math.abs(pos.X) <= part.Size.X / 2 + 1
          and math.abs(pos.Z) <= part.Size.Z / 2 + 1
          and pos.Y >= part.Size.Y / 2
          and pos.Y <= part.Size.Y / 2 + 4.5
        if
          tag == "MovingPlatform"
          and onTop
          and not carried[root]
          and occupant.humanoid.FloorMaterial ~= Enum.Material.Air
        then
          carried[root] = true
          local delta = part.Position - before.Position
          if delta.Magnitude <= 12 * math.min(dt, 0.1) + 0.1 then
            root.CFrame += delta
          end
        elseif query and onTop and tag == "Conveyor" and not influenced[root] then
          influenced[root] = true
          local direction = item.origin.RightVector
          if part:GetAttribute("Direction") == "Backward" then
            direction = -direction
          end
          local velocity = root.AssemblyLinearVelocity
          root.AssemblyLinearVelocity = Vector3.new(
            Math.influence(
              velocity.X,
              velocity.Y,
              velocity.Z,
              direction.X,
              direction.Z,
              math.clamp(part:GetAttribute("Speed") or 8, 0, 10),
              queryDt
            )
          )
        elseif
          query
          and tag == "WindZone"
          and not influenced[root]
          and math.abs(pos.X) <= part.Size.X / 2
          and math.abs(pos.Y) <= part.Size.Y / 2
          and math.abs(pos.Z) <= part.Size.Z / 2
        then
          influenced[root] = true
          local velocity = root.AssemblyLinearVelocity
          root.AssemblyLinearVelocity = Vector3.new(
            Math.influence(
              velocity.X,
              velocity.Y,
              velocity.Z,
              1,
              0,
              math.clamp(part:GetAttribute("Force") or 6, 0, 8),
              queryDt
            )
          )
        elseif
          query
          and onTop
          and tag == "BouncePad"
          and not bounced[root]
          and clock - (lastBounce[root] or -1) > 0.8
        then
          bounced[root] = true
          lastBounce[root] = clock
          local velocity = root.AssemblyLinearVelocity
          root.AssemblyLinearVelocity =
            Vector3.new(velocity.X, math.clamp(part:GetAttribute("Power") or 34, 20, 42), velocity.Z)
        elseif onTop and tag == "FallingPlatform" and item.state == "ready" then
          item.state = "arming"
          item.time = 0
        end
      end
    end
    if query then
      for _, occupant in ipairs(roots) do
        local completed = occupant.player:GetAttribute("Checkpoint") or 0
        local stage = world.stages[math.min(completed + 1, #world.stages)]
        if occupant.root.Position.Y < stage.entrance.Y - 12 then
          fail(occupant.player, "fall")
        end
      end
    end
  end))
end
return MovementService
