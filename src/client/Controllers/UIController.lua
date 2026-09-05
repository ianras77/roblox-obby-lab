local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Theme"))
local RemoteContracts = require(ReplicatedStorage:WaitForChild("Network"):WaitForChild("RemoteContracts"))
local SoundGroups = require(ReplicatedStorage:WaitForChild("Util"):WaitForChild("SoundGroups"))

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Definitions = require(ReplicatedStorage.Config.StageDefinitions)
local Strings = require(ReplicatedStorage.Config.Strings)
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
    showTimer = true,
    masterVolume = 1,
    musicVolume = 1,
    sfxVolume = 1,
    uiScale = 1,
  }
  self.originalHazardColors = setmetatable({}, { __mode = "k" })
  self.originalHazardMaterials = setmetatable({}, { __mode = "k" })
  self.hazardHighlights = setmetatable({}, { __mode = "k" })
  self.collectedKeys = {}
  self.gui = self:createGui()
  local events = ReplicatedStorage:WaitForChild("SharedEvents")
  self.progressEvent = events:WaitForChild(RemoteContracts.Progress.name)
  self.keyEvent = events:WaitForChild(RemoteContracts.Keys.name)
  self.stateFunction = events:WaitForChild(RemoteContracts.State.name)
  self.settingsEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(RemoteContracts.SetSettings.name)
  self.modeEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(RemoteContracts.SetMode.name)
  self.practiceEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(RemoteContracts.PracticeStage.name)
  self.highestChapter = 0
  self.timerStartedAt = nil
  self:bind()
  if RunService:IsStudio() then
    self:bindPseudolocalization()
  end
  task.spawn(function()
    for _ = 1, 20 do
      if self:syncInitialState() then
        return
      end
      task.wait(0.5)
    end
  end)
  return self
end

-- Development-only expansion mode exercises every dynamic label and newly opened panel.
function UIController:bindPseudolocalization()
  local entries = setmetatable({}, { __mode = "k" })
  local function attach(label)
    if not (label:IsA("TextLabel") or label:IsA("TextButton")) or entries[label] then
      return
    end
    local entry = { source = label.Text, busy = false }
    entries[label] = entry
    local function apply()
      entry.busy = true
      entry.rendered = self.player:GetAttribute("PseudoLocalization") and ("[" .. entry.source .. " ~ extended text ~]")
        or entry.source
      label.Text = entry.rendered
      entry.busy = false
    end
    label:GetPropertyChangedSignal("Text"):Connect(function()
      if not entry.busy and label.Text ~= entry.rendered then
        entry.source = label.Text
        apply()
      end
    end)
    entry.apply = apply
    apply()
  end
  for _, label in ipairs(self.gui:GetDescendants()) do
    attach(label)
  end
  self.gui.DescendantAdded:Connect(attach)
  self.player:GetAttributeChangedSignal("PseudoLocalization"):Connect(function()
    for _, entry in pairs(entries) do
      entry.apply()
    end
  end)
end

function UIController:syncInitialState()
  local ok, payload = pcall(function()
    return self.stateFunction:InvokeServer()
  end)
  if ok and payload and payload.ready ~= false then
    self.highestChapter = payload.highestChapter or 0
    if type(payload.chapter) == "table" then
      self.currentChapter = payload.chapter
    end
    for key, enabled in pairs(payload.settings or {}) do
      if self.settings[key] ~= nil and (type(enabled) == "boolean" or type(enabled) == "number") then
        self.settings[key] = enabled
        self.player:SetAttribute("Accessibility_" .. key, enabled)
      end
    end
    self:updateTimerState(payload)
    self:updateProgress(payload.stage or 0, payload.total or 1)
    self:updateKeys(payload.keys or 0, payload.totalKeys or 0)
    self:applyCollectedKeys(payload.collectedKeys)
    self:applyUIScale()
    self:applyAccessibility()
    self:applyAudioVolumes()
    self:refreshVolumeLabels()
    return true
  end
  return false
end

function UIController:applyAudioVolumes()
  local master = self.settings.masterVolume or 1
  SoundGroups.ensure("Music", 0.45 * master * (self.settings.musicVolume or 1))
  SoundGroups.ensure("Ambience", 0.35 * master)
  SoundGroups.ensure("SFX", 0.8 * master * (self.settings.sfxVolume or 1))
  SoundGroups.ensure("UI", 0.8 * master * (self.settings.sfxVolume or 1))
end

function UIController:applyUIScale()
  local scale = self.gui:FindFirstChild("AccessibilityScale")
  if scale then
    scale.Scale = 1
    for _, label in ipairs(self.gui:GetDescendants()) do
      if label:IsA("TextLabel") or label:IsA("TextButton") then
        local bounds = label:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
        bounds.MinTextSize = 12
        bounds.MaxTextSize = math.floor((self.settings.largeText and 28 or 24) * (self.settings.uiScale or 1))
        bounds.Parent = label
        label.TextWrapped = true
      end
    end
  end
end

function UIController:refreshVolumeLabels()
  for _, child in ipairs(self.gui:FindFirstChild("SettingsPanel"):GetChildren()) do
    local key = child:GetAttribute("VolumeKey")
    if child:IsA("TextButton") and key then
      child.Text = string.format("%s: %d%%", child:GetAttribute("VolumeLabel"), (self.settings[key] or 1) * 100)
    end
  end
end

function UIController:applyAccessibility()
  for _, part in ipairs(CollectionService:GetTagged("KillBrick")) do
    self:applyAccessibilityToHazard(part)
  end
  for _, emitter in ipairs(workspace:GetDescendants()) do
    if emitter:IsA("ParticleEmitter") and emitter:GetAttribute("GameplayCritical") ~= true then
      emitter.Enabled = not self.settings.lowParticles
    end
  end
end

function UIController:applyAccessibilityToHazard(part)
  if not part:IsA("BasePart") then
    return
  end
  self.originalHazardColors[part] = self.originalHazardColors[part] or part.Color
  self.originalHazardMaterials[part] = self.originalHazardMaterials[part] or part.Material
  -- Preserve semantic phase colors; contrast uses outlines.
  -- Material remains authored; outlines carry the additional contrast cue.
  local highlight = self.hazardHighlights[part]
  if not highlight then
    highlight = Instance.new("Highlight")
    highlight.Name = "HazardContrastOutline"
    highlight.Adornee = part
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(20, 20, 20)
    highlight.Parent = part
    self.hazardHighlights[part] = highlight
  end
  highlight.Enabled = self.settings.highContrast
  highlight.OutlineTransparency = self.settings.highContrast and 0 or 1
end

function UIController:hideCollectedKey(keyId)
  if type(keyId) ~= "string" then
    return
  end
  for _, key in ipairs(CollectionService:GetTagged("KeyCollectible")) do
    if key:GetAttribute("KeyId") == keyId and key:IsA("BasePart") then
      key.LocalTransparencyModifier = 1
      key.CanQuery = false
    end
  end
end

function UIController:applyCollectedKeys(collectedKeys)
  if type(collectedKeys) ~= "table" then
    return
  end
  for keyId, collected in pairs(collectedKeys) do
    if collected == true then
      self.collectedKeys[keyId] = true
      self:hideCollectedKey(keyId)
    end
  end
end

function UIController:createGui()
  local gui = Instance.new("ScreenGui")
  gui.Name = "ObbyHUD"
  gui.ResetOnSpawn = false
  gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
  gui.ClipToDeviceSafeArea = true
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
  label.Text = "Chapter 1/18 • Riverbank Welcome"
  label.Font = Enum.Font.GothamBold
  label.TextScaled = true
  label.TextColor3 = Color3.new(1, 1, 1)
  label.Parent = bar

  local reset = Instance.new("TextButton")
  reset.Name = "ResetButton"
  reset.Selectable = true
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
  settings.Selectable = true
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
  panel.Size = UDim2.fromScale(0.42, 0.42)
  panel.Position = UDim2.fromScale(0.02, 0.25)
  panel.BackgroundColor3 = Theme.Ink
  panel.BorderSizePixel = 0
  panel.CanvasSize = UDim2.fromScale(0, 0)
  panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
  panel.ScrollBarThickness = 8
  panel.Parent = gui
  local panelConstraint = Instance.new("UISizeConstraint")
  panelConstraint.MinSize = Vector2.new(180, 100)
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
  heading.Size = UDim2.new(1, 0, 0, Theme.MinimumTouchSize)
  heading.BackgroundTransparency = 1
  heading.Text = "Travel Settings"
  heading.TextColor3 = Theme.Parchment
  heading.Font = Enum.Font.GothamBold
  heading.TextScaled = true
  heading.Parent = panel
  for _, mode in ipairs({ "Adventure", "TimeTrial", "Practice" }) do
    local button = Instance.new("TextButton")
    button.Name = "Mode_" .. mode
    button.Selectable = true
    button.Size = UDim2.new(1, 0, 0, Theme.MinimumTouchSize)
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
  grid.CellSize = UDim2.fromOffset(64, Theme.MinimumTouchSize)
  grid.CellPadding = UDim2.fromOffset(6, 6)
  grid.Parent = practice
  for stage = 1, GameConfig.Zones * GameConfig.StagesPerZone do
    local button = Instance.new("TextButton")
    button.Name = "Stage_" .. stage
    button.Selectable = true
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
    showTimer = "Show Time Trial timer",
  }) do
    local toggle = Instance.new("TextButton")
    toggle.Name = key
    toggle.Selectable = true
    toggle:SetAttribute("SettingKey", key)
    toggle.Size = UDim2.new(1, 0, 0, Theme.MinimumTouchSize)
    toggle.BackgroundColor3 = Color3.fromRGB(62, 75, 95)
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.Font = Enum.Font.Gotham
    toggle.TextScaled = true
    toggle.Text = labelText .. ": OFF"
    toggle.Parent = panel
  end
  for _, definition in ipairs({
    { key = "masterVolume", label = "Master volume" },
    { key = "musicVolume", label = "Music volume" },
    { key = "sfxVolume", label = "Effects volume" },
    { key = "uiScale", label = "UI scale" },
  }) do
    local volume = Instance.new("TextButton")
    volume.Name = definition.key
    volume.Selectable = true
    volume:SetAttribute("VolumeKey", definition.key)
    volume:SetAttribute("VolumeLabel", definition.label)
    volume.Size = UDim2.new(1, 0, 0, Theme.MinimumTouchSize)
    volume.BackgroundColor3 = Color3.fromRGB(62, 75, 95)
    volume.TextColor3 = Color3.new(1, 1, 1)
    volume.Font = Enum.Font.Gotham
    volume.TextScaled = true
    volume.Text = definition.label .. ": 100%"
    volume.Parent = panel
  end

  local skip = Instance.new("TextButton")
  skip.Name = "HelpButton"
  skip.Size = UDim2.fromOffset(120, Theme.MinimumTouchSize)
  skip.Position = UDim2.fromScale(0.16, 0.12)
  skip.BackgroundColor3 = Color3.fromRGB(110, 130, 170)
  skip.TextColor3 = Color3.new(1, 1, 1)
  skip.Font = Enum.Font.GothamBold
  skip.TextScaled = true
  skip.Text = Strings.help
  skip.Active = true
  skip.Selectable = true
  skip.Visible = false
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
  keyHud.Text = "Keys 0/18"
  keyHud.Parent = gui

  local timer = Instance.new("TextLabel")
  timer.Name = "Timer"
  timer.Size = UDim2.fromScale(0.16, 0.05)
  timer.Position = UDim2.fromScale(0.62, 0.06)
  timer.BackgroundColor3 = Theme.Ink
  timer.TextColor3 = Theme.Parchment
  timer.Font = Enum.Font.GothamBold
  timer.TextScaled = true
  timer.Text = "Time 00:00.00"
  timer.Visible = false
  timer.Parent = gui

  return gui
end

function UIController:layout()
  local camera = workspace.CurrentCamera
  local size = camera and camera.ViewportSize or Vector2.new(800, 600)
  local narrow = size.X < 600
  local gui = self.gui
  gui.Title.Size = UDim2.new(1, -24, 0, 30)
  gui.Title.Position = UDim2.fromOffset(12, 0)
  gui.ProgressBar.Size = UDim2.new(1, -24, 0, 38)
  gui.ProgressBar.Position = UDim2.fromOffset(12, 34)
  gui.ResetButton.Size = UDim2.fromOffset(96, 48)
  gui.ResetButton.Position = UDim2.fromOffset(12, 78)
  gui.SettingsButton.Position = UDim2.fromOffset(114, 78)
  gui.SettingsButton.Size = UDim2.fromOffset(48, 48)
  gui.HelpButton.Size = UDim2.fromOffset(148, 48)
  gui.HelpButton.Position = UDim2.fromOffset(168, 78)
  gui.KeyCounter.Size = UDim2.fromOffset(120, 28)
  gui.KeyCounter.Position = UDim2.new(1, -132, 0, 130)
  gui.Timer.Size = UDim2.fromOffset(150, 28)
  gui.Timer.Position = UDim2.fromOffset(12, 130)
  gui.SettingsPanel.Size = UDim2.new(narrow and 1 or 0.55, narrow and -24 or 0, 0, math.max(100, size.Y - 190))
  gui.SettingsPanel.Position = UDim2.fromOffset(12, 170)
  gui.Hint.Size = UDim2.new(1, -24, 0, 42)
  gui.Hint.Position = UDim2.fromOffset(12, 162)
end

function UIController:bind()
  local reset = self.gui:FindFirstChild("ResetButton")
  local assistance = ReplicatedStorage.SharedEvents:WaitForChild("Assistance")
  reset.Activated:Connect(function()
    assistance:FireServer("Reset")
  end)
  self.gui.HelpButton.Activated:Connect(function()
    assistance:FireServer("Help")
  end)
  assistance.OnClientEvent:Connect(function(state)
    self.gui.HelpButton.Visible = state.help == true
    self.gui.Hint.Text = string.format("Try %d • %s", state.attempts or 1, state.hint or "Follow >>")
    if state.failures and state.failures >= 2 then
      self:guideToStage(state.stage)
    end
  end)
  local hint = Instance.new("TextLabel")
  hint.Name = "Hint"
  hint.Text = Strings.routeHint
  hint.TextWrapped = true
  hint.TextScaled = true
  hint.BackgroundTransparency = 0.2
  hint.Parent = self.gui
  local function inputHint()
    local input = UserInputService:GetLastInputType()
    reset.Text = Strings.retry
    hint.Text = input == Enum.UserInputType.Touch and Strings.touchHint
      or string.find(input.Name, "Gamepad") and Strings.gamepadHint
      or Strings.keyboardHint
  end
  UserInputService.LastInputTypeChanged:Connect(inputHint)
  inputHint()
  self:layout()
  if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
      self:layout()
    end)
  end

  local settingsButton = self.gui:FindFirstChild("SettingsButton")
  local panel = self.gui:FindFirstChild("SettingsPanel")
  settingsButton.Activated:Connect(function()
    panel.Visible = not panel.Visible
    hint.Visible = not panel.Visible
    if panel.Visible and UserInputService.GamepadEnabled then
      GuiService.SelectedObject = panel:FindFirstChildWhichIsA("TextButton")
    end
  end)
  for _, toggle in ipairs(panel:GetChildren()) do
    if toggle:IsA("TextButton") and toggle:GetAttribute("SettingKey") then
      toggle.Activated:Connect(function()
        local key = toggle:GetAttribute("SettingKey")
        self.settings[key] = not self.settings[key]
        self.player:SetAttribute("Accessibility_" .. key, self.settings[key])
        self.settingsEvent:FireServer(key, self.settings[key])
        if key == "largeText" then
          self:applyUIScale()
        end
        if key == "highContrast" or key == "lowParticles" then
          self:applyAccessibility()
        end
        if key == "showTimer" then
          local timer = self.gui:FindFirstChild("Timer")
          if timer and self.timerStartedAt then
            timer.Visible = self.settings.showTimer
          end
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
    if toggle:IsA("TextButton") and toggle:GetAttribute("VolumeKey") then
      toggle.Activated:Connect(function()
        local key = toggle:GetAttribute("VolumeKey")
        local currentValue = self.settings[key] or 1
        local nextValue
        if key == "uiScale" then
          nextValue = currentValue + 0.1
          if nextValue > 1.5 then
            nextValue = 0.8
          end
        else
          nextValue = (currentValue - 0.25) % 1.25
        end
        self.settings[key] = nextValue
        self.settingsEvent:FireServer(key, nextValue)
        if key == "uiScale" then
          self:applyUIScale()
        else
          self:applyAudioVolumes()
        end
        self:refreshVolumeLabels()
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
    self.lastProgressPayload = payload
    if payload.initialized then
      self.highestChapter = payload.highestChapter or self.highestChapter
      self:updateKeys(payload.keys or 0, payload.totalKeys or 0)
      self:applyCollectedKeys(payload.collectedKeys)
      for key, enabled in pairs(payload.settings or {}) do
        if self.settings[key] ~= nil and (type(enabled) == "boolean" or type(enabled) == "number") then
          self.settings[key] = enabled
          self.player:SetAttribute("Accessibility_" .. key, enabled)
        end
      end
      self:applyUIScale()
      self:applyAccessibility()
      self:applyAudioVolumes()
      self:refreshVolumeLabels()
    end
    local stage = payload.stage or 0
    local total = payload.total or 1
    self:updateTimerState(payload)
    self.highestChapter = math.max(self.highestChapter, stage)
    self.currentChapter = {
      id = payload.chapterId,
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
    if type(payload.keyId) == "string" then
      self.collectedKeys[payload.keyId] = true
      self:hideCollectedKey(payload.keyId)
    end
  end)

  CollectionService:GetInstanceAddedSignal("KeyCollectible"):Connect(function(key)
    local keyId = key:GetAttribute("KeyId")
    if self.collectedKeys[keyId] then
      self:hideCollectedKey(keyId)
    end
  end)

  CollectionService:GetInstanceAddedSignal("KillBrick"):Connect(function(part)
    self:applyAccessibilityToHazard(part)
  end)

  workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("ParticleEmitter") and instance:GetAttribute("GameplayCritical") ~= true then
      instance.Enabled = not self.settings.lowParticles
    end
  end)

  local finaleEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(RemoteContracts.Finale.name)
  finaleEvent.OnClientEvent:Connect(function(payload)
    self:showResults(payload)
  end)
end

function UIController:updateTimerState(payload)
  local timer = self.gui:FindFirstChild("Timer")
  if not timer then
    return
  end
  if payload.mode == "TimeTrial" and payload.runStarted then
    local elapsed = (payload.elapsedMs or 0) / 1000
    self.timerStartedAt = os.clock() - elapsed
    timer.Visible = self.settings.showTimer ~= false
  elseif payload.mode then
    self.timerStartedAt = nil
    timer.Visible = false
  end
  if self.timerConnection then
    return
  end
  self.timerConnection = RunService.RenderStepped:Connect(function()
    if self.timerStartedAt and timer.Visible then
      local elapsed = math.max(0, os.clock() - self.timerStartedAt)
      timer.Text = string.format("Time %02d:%05.2f", math.floor(elapsed / 60), elapsed % 60)
    end
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
  local cardConstraint = Instance.new("UISizeConstraint")
  cardConstraint.MinSize = Vector2.new(280, 220)
  cardConstraint.MaxSize = Vector2.new(720, 360)
  cardConstraint.Parent = card

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
  local deaths = payload and payload.deaths and string.format("\nRetries: %d", payload.deaths) or ""
  local keys = payload
      and payload.keys
      and payload.totalKeys
      and string.format("\nGolden Keys: %d/%d", payload.keys, payload.totalKeys)
    or ""
  local exploration = ""
  if payload and payload.keys and payload.totalKeys and payload.totalKeys > 0 then
    exploration = string.format("\nExploration: %d%%", math.floor(payload.keys / payload.totalKeys * 100))
  end
  local medals = ""
  if payload and payload.medals then
    local counts = { Story = 0, Explorer = 0, Toad = 0 }
    for key, earned in pairs(payload.medals) do
      if earned then
        for kind in pairs(counts) do
          if string.sub(key, 1, #kind) == kind then
            counts[kind] += 1
          end
        end
      end
    end
    medals =
      string.format("\nMedals • Story %d • Explorer %d • Toad %d", counts.Story, counts.Explorer, counts.Toad)
    if payload.assisted then
      medals ..= "\nYou and your helpers made it home!"
    end
  end
  result.Text = string.format(
    "Toad Hall reached!\n%s run complete%s%s%s%s%s%s\nRoute completion: 100%%",
    mode,
    elapsed,
    best,
    deaths,
    keys,
    exploration,
    medals
  )
  local function addAction(name, text, actionMode, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Selectable = true
    button.Size = UDim2.fromScale(0.29, 0.18)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(218, 166, 72)
    button.TextColor3 = Color3.fromRGB(35, 25, 20)
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.Text = text
    button.Parent = card
    local buttonConstraint = Instance.new("UISizeConstraint")
    buttonConstraint.MinSize = Vector2.new(84, 44)
    buttonConstraint.Parent = button
    button.Activated:Connect(function()
      card:Destroy()
      if actionMode == "Practice" then
        self:showPracticeSelector()
      else
        self.modeEvent:FireServer(actionMode)
      end
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
  if self.settings.reducedMotion then
    fill.Size = UDim2.fromScale(pct, 1)
  else
    fill:TweenSize(UDim2.fromScale(pct, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
  end
  local nextIndex = math.clamp(stage + 1, 1, #Definitions)
  label.Text = string.format(Strings.progress, nextIndex, total, Definitions[nextIndex].displayName)
end

function UIController:updateKeys(found, total)
  local keyHud = self.gui:FindFirstChild("KeyCounter")
  if not keyHud then
    return
  end
  keyHud.Text = string.format(Strings.keys, found, total)
end

function UIController:guideToStage(nextStage)
  local obby = workspace:FindFirstChild("GeneratedObby")
  if self.routeHighlight then
    self.routeHighlight:Destroy()
    self.routeHighlight = nil
  end
  if not obby then
    return
  end
  for _, model in ipairs(obby:GetDescendants()) do
    if model:IsA("Model") and model:GetAttribute("StageIndex") == nextStage then
      local highlight = Instance.new("Highlight")
      highlight.Name = "PersonalRouteHelp"
      highlight.Adornee = model
      highlight.FillTransparency = 1
      highlight.OutlineColor = Color3.fromRGB(255, 240, 160)
      highlight.Parent = self.gui
      self.routeHighlight = highlight
      return
    end
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
