--!strict
--[[
    VehicleColorService.luau
    HOKI TOWN - Vehicle Customization
    Universal 6-Zone Vehicle Color Service (shared between Server and Client)
]]

export type VehiclePalette = {
	Body_Main: Color3,
	Aero_Trim: Color3,
	Wheels_Rims: Color3,
	Brake_Calipers: Color3,
	Lights_DRL: Color3,
	Canopy_Glass: Color3,
}

type ZoneRule = {
	parts: { string },
	material: Enum.Material?,
	transparency: number?,
}

local ZONE_RULES: { [string]: ZoneRule? } = {
	Body_Main = {
		parts = { "Body_Paint" },
	},
	Aero_Trim = {
		parts = { "Body_Secondary_Carbon", "Spoiler" },
	},
	Wheels_Rims = {
		parts = { "Wheel_FL", "Wheel_FR", "Wheel_RL", "Wheel_RR" },
	},
	Brake_Calipers = {
		parts = { "Caliper_FL", "Caliper_FR", "Caliper_RL", "Caliper_RR" },
	},
	Lights_DRL = {
		parts = { "Headlights_Bulbs", "Taillights" },
		material = Enum.Material.Neon,
	},
	Canopy_Glass = {
		parts = { "Body_Glass" },
		material = Enum.Material.Glass,
		transparency = 0.5,
	},
}

local VehicleColorService = {}

local function serializeColor(color: Color3): { number }
	return { color.R, color.G, color.B }
end

local function deserializeColor(rgb: { number }?, fallback: Color3): Color3
	if rgb ~= nil and #rgb >= 3 then
		return Color3.new(rgb[1], rgb[2], rgb[3])
	end
	return fallback
end

function VehicleColorService.GetDefaultPalette(): VehiclePalette
	return {
		Body_Main = Color3.fromRGB(200, 20, 20),
		Aero_Trim = Color3.fromRGB(25, 27, 30),
		Wheels_Rims = Color3.fromRGB(165, 170, 175),
		Brake_Calipers = Color3.fromRGB(215, 40, 40),
		Lights_DRL = Color3.fromRGB(255, 255, 255),
		Canopy_Glass = Color3.fromRGB(35, 45, 52),
	}
end

function VehicleColorService.ApplyZoneColor(carModel: Model, zoneName: string, color: Color3): boolean
	local rule = ZONE_RULES[zoneName]
	if rule == nil then
		warn(string.format("[VehicleColorService] Unknown zone '%s'", tostring(zoneName)))
		return false
	end

	local material = rule.material
	local transparency = rule.transparency
	local applied = false

	for _, partName in ipairs(rule.parts) do
		local part = carModel:FindFirstChild(partName, true)
		if part ~= nil and part:IsA("BasePart") then
			part.Color = color
			if material ~= nil then
				part.Material = material
			end
			if transparency ~= nil then
				part.Transparency = transparency
			end
			applied = true
		end
	end

	return applied
end

function VehicleColorService.ApplyFullPalette(carModel: Model, palette: VehiclePalette): boolean
	local ok = true
	ok = VehicleColorService.ApplyZoneColor(carModel, "Body_Main", palette.Body_Main) and ok
	ok = VehicleColorService.ApplyZoneColor(carModel, "Aero_Trim", palette.Aero_Trim) and ok
	ok = VehicleColorService.ApplyZoneColor(carModel, "Wheels_Rims", palette.Wheels_Rims) and ok
	ok = VehicleColorService.ApplyZoneColor(carModel, "Brake_Calipers", palette.Brake_Calipers) and ok
	ok = VehicleColorService.ApplyZoneColor(carModel, "Lights_DRL", palette.Lights_DRL) and ok
	ok = VehicleColorService.ApplyZoneColor(carModel, "Canopy_Glass", palette.Canopy_Glass) and ok
	return ok
end

function VehicleColorService.SerializePalette(palette: VehiclePalette): { [string]: { number } }
	return {
		Body_Main = serializeColor(palette.Body_Main),
		Aero_Trim = serializeColor(palette.Aero_Trim),
		Wheels_Rims = serializeColor(palette.Wheels_Rims),
		Brake_Calipers = serializeColor(palette.Brake_Calipers),
		Lights_DRL = serializeColor(palette.Lights_DRL),
		Canopy_Glass = serializeColor(palette.Canopy_Glass),
	}
end

function VehicleColorService.DeserializePalette(data: { [string]: { number } }): VehiclePalette
	local defaults = VehicleColorService.GetDefaultPalette()
	return {
		Body_Main = deserializeColor(data.Body_Main, defaults.Body_Main),
		Aero_Trim = deserializeColor(data.Aero_Trim, defaults.Aero_Trim),
		Wheels_Rims = deserializeColor(data.Wheels_Rims, defaults.Wheels_Rims),
		Brake_Calipers = deserializeColor(data.Brake_Calipers, defaults.Brake_Calipers),
		Lights_DRL = deserializeColor(data.Lights_DRL, defaults.Lights_DRL),
		Canopy_Glass = deserializeColor(data.Canopy_Glass, defaults.Canopy_Glass),
	}
end

return VehicleColorService
