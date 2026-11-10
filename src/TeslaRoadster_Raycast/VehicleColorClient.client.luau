--!strict
--[[
    VehicleColorClient.client.luau
    HOKI TOWN - Vehicle Customization
    Client-side 6-Zone Color Applicator for the Tesla Roadster Raycast Master 2026
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local car = script.Parent :: Model

local VehicleColorService = require(ReplicatedStorage:WaitForChild("VehicleColorService"))

local ZONE_NAMES = {
	"Body_Main",
	"Aero_Trim",
	"Wheels_Rims",
	"Brake_Calipers",
	"Lights_DRL",
	"Canopy_Glass",
}

local function applyZoneFromAttribute(zoneName: string)
	local attribute = car:GetAttribute("PaletteColor_" .. zoneName)
	if typeof(attribute) == "Color3" then
		VehicleColorService.ApplyZoneColor(car, zoneName, attribute :: Color3)
	end
end

-- Apply the factory default palette immediately so the vehicle never renders uncolored.
VehicleColorService.ApplyFullPalette(car, VehicleColorService.GetDefaultPalette())

-- Networked overrides: the server publishes each zone as a Color3 attribute
-- (PaletteColor_<ZoneName>); re-apply the zone whenever its attribute changes.
for _, zoneName in ipairs(ZONE_NAMES) do
	local zone = zoneName
	applyZoneFromAttribute(zone)
	car:GetAttributeChangedSignal("PaletteColor_" .. zone):Connect(function()
		applyZoneFromAttribute(zone)
	end)
end

print("[VehicleColorClient] 6-Zone Color Service attached to " .. car.Name)
