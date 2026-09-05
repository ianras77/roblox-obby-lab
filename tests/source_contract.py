"""Small wiring checks complement executable Luau math and Studio integration.
These do not claim to execute Roblox physics or networking.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def read(name): return (root/name).read_text()
server=read("src/server/Services/ObbyService.lua")
movement=read("src/server/Services/MovementService.lua")
checkpoint=read("src/server/Services/CheckpointService.lua")
world=read("src/server/WorldGen/WorldBuilder.lua")
zone=read("src/server/WorldGen/ZoneBuilder.lua")
assert "GetTouchingParts" not in movement
assert "local carried, influenced, bounced" in movement
assert 'part.CanTouch = state == "active"' in movement
assert 'part.CanCollide = tag ~= "Laser"' in movement
assert "Math.influence" in movement and "Math.omega" in movement
assert "Math.hazardActive" in movement
assert "Touched:Connect" not in movement
assert "part.CFrame.LookVector" not in movement
assert "self:registerKey(part)" in server and "part:Destroy()" not in server
assert "self.collectedKeys[player][keyId]" in server
assert "ProgressionRules.canAdvance" in checkpoint
assert "exportSessions()" in server and "self.retained[player]" in checkpoint
assert "CharacterAdded:Connect" in checkpoint and 'WaitForChild("HumanoidRootPart", 5)' in checkpoint
assert "FireAllClients" not in checkpoint and "evt:FireClient(player" in checkpoint
assert "RouteValidator.assertWorld" in world
assert "RouteBuilder.connect" in world and "RouteBuilder.connect" in zone
assert zone.count("GameConfig.StageSpacing.X")==1
assert world.count("GameConfig.StageSpacing.X")==1 # alternate ownership at zone transition, not both on same edge
assert "Experimental" not in read("src/server/WorldGen/Templates/StageTemplates.lua")
assert "LegacyStageTemplates" not in read("default.project.json")
boots=[p for p in (root/"src").rglob("*.server.lua") if "ObbyService.new()" in p.read_text()]
assert len(boots)==1,boots
assert "Skip (off)" not in read("src/client/Controllers/UIController.lua")
assert "CoreUISafeInsets" in read("src/client/Controllers/UIController.lua")
assert 'storeName .. "_" .. GameConfig.Environment' in read("src/server/Services/DataStoreServiceWrapper.lua")
assert "UpdateAsync" in read("src/server/Services/DataStoreServiceWrapper.lua")
assert "BindToClose" in checkpoint
print("source wiring: route, one startup, player ownership, rebuild, state, persistence and UI passed")
