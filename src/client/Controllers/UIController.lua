local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))

local UIController = {}
UIController.__index = UIController

function UIController.new()
  local self = setmetatable({}, UIController)
  self.player = Players.LocalPlayer
  self.gui = self:createGui()
  self.progressEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(GameConfig.ProgressRemote)
  self.keyEvent = ReplicatedStorage:WaitForChild("SharedEvents"):WaitForChild(GameConfig.KeyRemote)
  self:bind()
  return self
end

function UIController:createGui()
  local gui = Instance.new("ScreenGui")
  gui.Name = "ObbyHUD"
  gui.ResetOnSpawn = false
  gui.Parent = self.player:WaitForChild("PlayerGui")

  local bar = Instance.new("Frame")
  bar.Name = "ProgressBar"
  bar.Size = UDim2.fromScale(0.4, 0.05)
  bar.Position = UDim2.fromScale(0.3, 0.05)
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
  reset.Size = UDim2.fromOffset(120, 40)
  reset.Position = UDim2.fromScale(0.02, 0.12)
  reset.BackgroundColor3 = Color3.fromRGB(240, 150, 110)
  reset.TextColor3 = Color3.new(1, 1, 1)
  reset.Font = Enum.Font.GothamBold
  reset.TextScaled = true
  reset.Text = "Reset"
  reset.Parent = gui

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
  keyHud.Position = UDim2.fromScale(0.8, 0.05)
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
  reset.MouseButton1Click:Connect(function()
    local character = self.player.Character or self.player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
      humanoid.Health = 0
    end
  end)

  self.progressEvent.OnClientEvent:Connect(function(payload)
    local stage = payload.stage or 0
    local total = payload.total or 1
    self:updateProgress(stage, total)
    self:guideToStage(stage + 1)
    self:flashMilestone(stage, total)
  end)

  self.keyEvent.OnClientEvent:Connect(function(payload)
    self:updateKeys(payload.found or 0, payload.total or 0)
  end)
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
  local obby = workspace:FindFirstChild("Obby")
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
    arrow.Text = "⬆"
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
  gui.Text = string.format("Stage %d / %d — keep charging forward!", stage, total)
  gui.Parent = self.gui
  game:GetService("Debris"):AddItem(gui, 1.2)
end

return UIController
