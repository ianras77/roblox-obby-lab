local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Theme"))
local RemoteContracts = require(ReplicatedStorage:WaitForChild("Network"):WaitForChild("RemoteContracts"))

local UIController = {}
UIController.__index = UIController

function UIController.new()
  local self = setmetatable({}, UIController)
  self.player = Players.LocalPlayer
  self.settings = {
    reducedMotion = false,
    reduceFlashes = false,
    highContrast = false,
    largeText = false,
    lowParticles = false,
  }
  self.originalHazardColors = {}
  self.originalHazardMaterials = {}
  self.gui = self:createGui()
  self.progressEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(GameConfig.ProgressRemote)
  self.keyEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(GameConfig.KeyRemote)
  self.stateFunction = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild("GetObbyState")
  self.settingsEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(RemoteContracts.SetSettings.name)
  self.modeEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(RemoteContracts.SetMode.name)
  self.practiceEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(RemoteContracts.PracticeStage.name)
  self.highestChapter = 0
  self:bind()
  self:syncInitialState()
  return self
end

function UIController:syncInitialState()
  local ok, payload = pcall(function()
    return self.stateFunction:InvokeServer()
  end)
  if ok and payload then
    self.highestChapter = payload.highestChapter or 0
    self:updateProgress(payload.stage or 0, payload.total or 1)
    self:updateKeys(payload.keys or 0, payload.totalKeys or 0)
    for key, enabled in pairs(payload.settings or {}) do
      if self.settings[key] ~= nil and type(enabled) == "boolean" then
        self.settings[key] = enabled
        self.player:SetAttribute("Accessibility_" .. key, enabled)
      end
    end
    local scale = self.gui:FindFirstChild("AccessibilityScale")
    if scale then
      scale.Scale = self.settings.largeText and 1.15 or 1
    end
    self:applyAccessibility()
  end
end

function UIController:applyAccessibility()
  for _, part in ipairs(CollectionService:GetTagged("KillBrick")) do
    if part:IsA("BasePart") then
      self.originalHazardColors[part] = self.originalHazardColors[part] or part.Color
      self.originalHazardMaterials[part] = self.originalHazardMaterials[part] or part.Material
      part.Color = self.settings.highContrast and Color3.fromRGB(255, 255, 255) or self.originalHazardColors[part]
      part.Material = self.settings.highContrast and Enum.Material.Neon or self.originalHazardMaterials[part]
    end
  end
  for _, emitter in ipairs(workspace:GetDescendants()) do
    if emitter:IsA("ParticleEmitter") and emitter:GetAttribute("GameplayCritical") ~= true then
      emitter.Enabled = not self.settings.lowParticles
    end
  end
end

function UIController:createGui()
  local gui = Instance.new("ScreenGui")
  gui.Name = "ObbyHUD"
  gui.ResetOnSpawn = false
  gui.Parent = self.player:WaitForChild("PlayerGui")
  local uiScale = Instance.new("UIScale")
  uiScale.Name = "AccessibilityScale"
  uiScale.Scale = 1
  uiScale.Parent = gui

  local title = Instance.new("TextLabel")
  title.Name = "Title"
  title.Size = UDim2.fromScale(0.44, 0.05)
  title.Position = UDim2.fromScale(0.28, 0.005)
  title.BackgroundTransparency = 0.1
  title.BackgroundColor3 = Color3.fromRGB(35, 45, 80)
  title.BorderSizePixel = 0
  title.Text = GameConfig.Title
  title.Font = Enum.Font.GothamBlack
  title.TextScaled = true
  title.TextColor3 = Color3.fromRGB(255, 235, 160)
  title.Parent = gui

  local bar = Instance.new("Frame")
  bar.Name = "ProgressBar"
  bar.Size = UDim2.fromScale(0.4, 0.05)
  bar.Position = UDim2.fromScale(0.3, 0.06)
  bar.BackgroundColor3 = Color3.fromRGB(35, 60, 95)
  bar.BorderSizePixel = 0
  bar.Parent = gui

  local fill = Instance.new("Frame")
  fill.Name = "Fill"
  fill.Size = UDim2.fromScale(0, 1)
  fill.BackgroundColor3 = Color3.fromRGB(120, 235, 195)
  fill.BorderSizePixel = 0
  fill.Parent = bar

  local label = Instance.new("TextLabel")
  label.Name = "Label"
  label.Size = UDim2.fromScale(1, 1)
  label.BackgroundTransparency = 1
  label.Text = "Stage 0/0"
  label.Font = Enum.Font.GothamBold
  label.TextScaled = true
  label.TextColor3 = Color3.new(1, 1, 1)
  label.Parent = bar

  local reset = Instance.new("TextButton")
  reset.Name = "ResetButton"
  reset.Size = UDim2.fromOffset(Theme.MinimumTouchSize + 76, Theme.MinimumTouchSize)
  reset.Position = UDim2.fromScale(0.02, 0.12)
  reset.BackgroundColor3 = Color3.fromRGB(240, 150, 110)
  reset.TextColor3 = Color3.new(1, 1, 1)
  reset.Font = Enum.Font.GothamBold
  reset.TextScaled = true
  reset.Text = "Reset"
  reset.Parent = gui

  local settings = Instance.new("TextButton")
  settings.Name = "SettingsButton"
  settings.Size = UDim2.fromOffset(Theme.MinimumTouchSize, Theme.MinimumTouchSize)
  settings.Position = UDim2.fromScale(0.02, 0.18)
  settings.BackgroundColor3 = Theme.Ink
  settings.TextColor3 = Theme.Parchment
  settings.Font = Enum.Font.GothamBold
  settings.TextScaled = true
  settings.Text = "⚙"
  settings.Parent = gui

  local panel = Instance.new("ScrollingFrame")
  panel.Name = "SettingsPanel"
  panel.Visible = false
  panel.Size = UDim2.fromScale(0.34, 0.34)
  panel.Position = UDim2.fromScale(0.02, 0.25)
  panel.BackgroundColor3 = Theme.Ink
  panel.BorderSizePixel = 0
  panel.CanvasSize = UDim2.fromScale(0, 0)
  panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
  panel.ScrollBarThickness = 8
  panel.Parent = gui
  local panelConstraint = Instance.new("UISizeConstraint")
  panelConstraint.MinSize = Vector2.new(220, 190)
  panelConstraint.MaxSize = Vector2.new(420, 360)
  panelConstraint.Parent = panel
  local list = Instance.new("UIListLayout")
  list.Padding = UDim.new(0, Theme.Spacing)
  list.SortOrder = Enum.SortOrder.LayoutOrder
  list.Parent = panel
  local padding = Instance.new("UIPadding")
  padding.PaddingTop = UDim.new(0, Theme.Spacing)
  padding.PaddingBottom = UDim.new(0, Theme.Spacing)
  padding.PaddingLeft = UDim.new(0, Theme.Spacing)
  padding.PaddingRight = UDim.new(0, Theme.Spacing)
  padding.Parent = panel
  local heading = Instance.new("TextLabel")
  heading.Size = UDim2.new(1, 0, 0, 28)
  heading.BackgroundTransparency = 1
  heading.Text = "Travel Settings"
  heading.TextColor3 = Theme.Parchment
  heading.Font = Enum.Font.GothamBold
  heading.TextScaled = true
  heading.Parent = panel
  for _, mode in ipairs({ "Adventure", "TimeTrial", "Practice" }) do
    local button = Instance.new("TextButton")
    button.Name = "Mode_" .. mode
    button.Size = UDim2.new(1, 0, 0, 28)
    button.BackgroundColor3 = Theme.Brass
    button.TextColor3 = Theme.Ink
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.Text = "Play " .. mode
    button:SetAttribute("RunMode", mode)
    button.Parent = panel
  end
  local practice = Instance.new("ScrollingFrame")
  practice.Name = "PracticeSelector"
  practice.Visible = false
  practice.Size = UDim2.fromScale(0.42, 0.28)
  practice.Position = UDim2.fromScale(0.54, 0.25)
  practice.BackgroundColor3 = Theme.Ink
  practice.BorderSizePixel = 0
  practice.CanvasSize = UDim2.fromScale(0, 0)
  practice.AutomaticCanvasSize = Enum.AutomaticSize.Y
  practice.Parent = gui
  local grid = Instance.new("UIGridLayout")
  grid.CellSize = UDim2.fromOffset(58, 36)
  grid.CellPadding = UDim2.fromOffset(6, 6)
  grid.Parent = practice
  for stage = 1, GameConfig.Zones * GameConfig.StagesPerZone do
    local button = Instance.new("TextButton")
    button.Name = "Stage_" .. stage
    button.Text = "Chapter " .. stage
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.BackgroundColor3 = Theme.Brass
    button.TextColor3 = Theme.Ink
    button:SetAttribute("PracticeStage", stage)
    button.Parent = practice
  end
  for key, labelText in pairs({
    reducedMotion = "Reduced motion",
    reduceFlashes = "Reduce flashes",
    highContrast = "High contrast hazards",
    largeText = "Larger text",
    lowParticles = "Lower particles",
  }) do
    local toggle = Instance.new("TextButton")
    toggle.Name = key
    toggle:SetAttribute("SettingKey", key)
    toggle.Size = UDim2.new(1, 0, 0, 28)
    toggle.BackgroundColor3 = Color3.fromRGB(62, 75, 95)
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.Font = Enum.Font.Gotham
    toggle.TextScaled = true
    toggle.Text = labelText .. ": OFF"
    toggle.Parent = panel
  end

  local skip = Instance.new("TextButton")
  skip.Name = "SkipButton"
  skip.Size = UDim2.fromOffset(120, 40)
  skip.Position = UDim2.fromScale(0.16, 0.12)
  skip.BackgroundColor3 = Color3.fromRGB(110, 130, 170)
  skip.TextColor3 = Color3.new(1, 1, 1)
  skip.Font = Enum.Font.GothamBold
  skip.TextScaled = true
  skip.Text = "Skip (off)"
  skip.Active = false
  skip.AutoButtonColor = false
  skip.Parent = gui

  local keyHud = Instance.new("TextLabel")
  keyHud.Name = "KeyCounter"
  keyHud.Size = UDim2.fromScale(0.18, 0.05)
  keyHud.Position = UDim2.fromScale(0.8, 0.06)
  keyHud.BackgroundTransparency = 0.1
  keyHud.BackgroundColor3 = Color3.fromRGB(140, 170, 240)
  keyHud.TextColor3 = Color3.fromRGB(20, 35, 60)
  keyHud.Font = Enum.Font.GothamBold
  keyHud.TextScaled = true
  keyHud.Text = "Keys 0/0"
  keyHud.Parent = gui

  return gui
end

function UIController:bind()
  local reset = self.gui:FindFirstChild("ResetButton")
  reset.Activated:Connect(function()
    local character = self.player.Character or self.player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
      humanoid.Health = 0
    end
  end)

  local settingsButton = self.gui:FindFirstChild("SettingsButton")
  local panel = self.gui:FindFirstChild("SettingsPanel")
  settingsButton.Activated:Connect(function()
    panel.Visible = not panel.Visible
  end)
  for _, toggle in ipairs(panel:GetChildren()) do
    if toggle:IsA("TextButton") and toggle:GetAttribute("SettingKey") then
      toggle.Activated:Connect(function()
        local key = toggle:GetAttribute("SettingKey")
        self.settings[key] = not self.settings[key]
        self.player:SetAttribute("Accessibility_" .. key, self.settings[key])
        self.settingsEvent:FireServer(key, self.settings[key])
        if key == "largeText" then
          local scale = self.gui:FindFirstChild("AccessibilityScale")
          if scale then
            scale.Scale = self.settings[key] and 1.15 or 1
          end
        end
        if key == "highContrast" or key == "lowParticles" then
          self:applyAccessibility()
        end
        toggle.Text = string.gsub(toggle.Text, ": %u+", ": " .. (self.settings[key] and "ON" or "OFF"))
      end)
    end
    if toggle:IsA("TextButton") and toggle:GetAttribute("RunMode") then
      toggle.Activated:Connect(function()
        local mode = toggle:GetAttribute("RunMode")
        if mode == "Practice" then
          self:showPracticeSelector()
        else
          self.modeEvent:FireServer(mode)
          panel.Visible = false
        end
      end)
    end
  end

  local selector = self.gui:FindFirstChild("PracticeSelector")
  if selector then
    for _, button in ipairs(selector:GetChildren()) do
      if button:IsA("TextButton") then
        button.Activated:Connect(function()
          local stage = button:GetAttribute("PracticeStage")
          if stage and stage <= self.highestChapter then
            self.practiceEvent:FireServer(stage)
            selector.Visible = false
            panel.Visible = false
          end
        end)
      end
    end
  end

  self.progressEvent.OnClientEvent:Connect(function(payload)
    local stage = payload.stage or 0
    local total = payload.total or 1
    self.highestChapter = math.max(self.highestChapter, stage)
    self.currentChapter = {
      name = payload.chapterName,
      mechanic = payload.mechanic,
      flavor = payload.flavor,
    }
    self:updateProgress(stage, total)
    self:guideToStage(stage + 1)
    self:flashMilestone(stage, total)
  end)

  self.keyEvent.OnClientEvent:Connect(function(payload)
    self:updateKeys(payload.found or 0, payload.total or 0)
  end)

  local finaleEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(GameConfig.FinaleRemote)
  finaleEvent.OnClientEvent:Connect(function(payload)
    self:showResults(payload)
  end)
end

function UIController:showPracticeSelector()
  local selector = self.gui:FindFirstChild("PracticeSelector")
  if not selector then
    return
  end
  for _, child in ipairs(selector:GetChildren()) do
    if child:IsA("TextButton") then
      local stage = child:GetAttribute("PracticeStage")
      child.Visible = stage <= self.highestChapter
      child.Text = child.Visible and ("Chapter " .. stage) or ("Locked " .. stage)
    end
  end
  selector.Visible = true
end

function UIController:showResults(payload)
  local previous = self.gui:FindFirstChild("Results")
  if previous then
    previous:Destroy()
  end
  local card = Instance.new("Frame")
  card.Name = "Results"
  card.Size = UDim2.fromScale(0.72, 0.34)
  card.Position = UDim2.fromScale(0.14, 0.33)
  card.BackgroundColor3 = Color3.fromRGB(35, 45, 60)
  card.BorderSizePixel = 0
  card.Parent = self.gui

  local result = Instance.new("TextLabel")
  result.Name = "Summary"
  result.Size = UDim2.fromScale(0.92, 0.62)
  result.Position = UDim2.fromScale(0.04, 0.05)
  result.BackgroundTransparency = 1
  result.TextColor3 = Color3.fromRGB(255, 236, 182)
  result.Font = Enum.Font.GothamBlack
  result.TextScaled = true
  result.TextWrapped = true
  local mode = payload and payload.mode or self.player:GetAttribute("RunMode") or "Adventure"
  local elapsed = payload and payload.elapsedMs and string.format("\nTime: %.2fs", payload.elapsedMs / 1000) or ""
  local best = payload and payload.bestRunMs and string.format("\nPersonal best: %.2fs", payload.bestRunMs / 1000) or ""
  local deaths = payload and payload.deaths and string.format("\nDeaths: %d", payload.deaths) or ""
  local keys = payload
      and payload.keys
      and payload.totalKeys
      and string.format("\nGolden Keys: %d/%d", payload.keys, payload.totalKeys)
    or ""
  result.Text =
    string.format("Toad Hall reached!\n%s run complete%s%s%s%s\nCompletion: 100%%", mode, elapsed, best, deaths, keys)
  local function addAction(name, text, actionMode, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.fromScale(0.29, 0.18)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(218, 166, 72)
    button.TextColor3 = Color3.fromRGB(35, 25, 20)
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.Text = text
    button.Parent = card
    button.Activated:Connect(function()
      self.modeEvent:FireServer(actionMode)
      card:Destroy()
    end)
  end
  addAction("AdventureButton", "Replay", "Adventure", UDim2.fromScale(0.04, 0.77))
  addAction("TimeTrialButton", "Time Trial", "TimeTrial", UDim2.fromScale(0.355, 0.77))
  addAction("PracticeButton", "Practice", "Practice", UDim2.fromScale(0.67, 0.77))
end

function UIController:updateProgress(stage, total)
  local bar = self.gui:FindFirstChild("ProgressBar")
  if not bar then
    return
  end
  local fill = bar:FindFirstChild("Fill")
  local label = bar:FindFirstChild("Label")
  local pct = total > 0 and stage / total or 0
  fill:TweenSize(UDim2.fromScale(pct, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
  label.Text = string.format("Stage %d/%d", stage, total)
end

function UIController:updateKeys(found, total)
  local keyHud = self.gui:FindFirstChild("KeyCounter")
  if not keyHud then
    return
  end
  keyHud.Text = string.format("Keys %d/%d", found, total)
end

function UIController:guideToStage(nextStage)
  local obby = workspace:FindFirstChild("GeneratedObby")
  if not obby then
    return
  end
  local label = self.gui:FindFirstChild("ArrowHint")
  if label then
    label:Destroy()
  end
  local nextName = string.format("CP_%03d", nextStage)
  local target = obby:FindFirstChild(nextName, true)
  if target and target:IsA("BasePart") then
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ArrowHint"
    billboard.Adornee = target
    billboard.Size = UDim2.fromOffset(80, 80)
    billboard.StudsOffset = Vector3.new(0, 6, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = self.gui

    local arrow = Instance.new("TextLabel")
    arrow.BackgroundTransparency = 1
    arrow.Text = "^"
    arrow.TextScaled = true
    arrow.Font = Enum.Font.GothamBold
    arrow.TextColor3 = Color3.fromRGB(255, 255, 0)
    arrow.Parent = billboard
  end
end

function UIController:flashMilestone(stage, total)
  if stage == 0 then
    return
  end
  local gui = Instance.new("TextLabel")
  gui.Size = UDim2.fromScale(1, 0.08)
  gui.Position = UDim2.fromScale(0, 0.14)
  gui.BackgroundTransparency = 0.1
  gui.BackgroundColor3 = Color3.fromRGB(40, 60, 90)
  gui.TextColor3 = Color3.fromRGB(255, 230, 180)
  gui.Font = Enum.Font.GothamBlack
  gui.TextScaled = true
  local current = self.currentChapter or {}
  gui.Text = string.format(
    "Chapter %d / %d: %s\n%s",
    stage,
    total,
    current.name or "New chapter",
    current.mechanic or "Keep moving forward!"
  )
  gui.Parent = self.gui
  game:GetService("Debris"):AddItem(gui, 1.2)
end

return UIController
