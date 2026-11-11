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
		material = Enum.Material.SmoothPlastic,
	},
	Aero_Trim = {
		parts = {
			"Aero_Trim",
			"Body_Secondary_Carbon",
			"Spoiler",
			"Rear_Diffuser_Aero",
			"Chassis_Underbody",
			"Headlights_Housing",
		},
		material = Enum.Material.SmoothPlastic,
	},
	Wheels_Rims = {
		parts = { "Wheel_FL", "Wheel_FR", "Wheel_RL", "Wheel_RR" },
		material = Enum.Material.Metal,
	},
	Brake_Rotors = {
		parts = { "Brake_Rotor_FL", "Brake_Rotor_FR", "Brake_Rotor_RL", "Brake_Rotor_RR" },
		material = Enum.Material.Metal,
	},
	Brake_Calipers = {
		parts = { "Caliper_FL", "Caliper_FR", "Caliper_RL", "Caliper_RR" },
		material = Enum.Material.SmoothPlastic,
	},
	Tires = {
		parts = { "Tire_FL", "Tire_FR", "Tire_RL", "Tire_RR" },
		material = Enum.Material.Rubber,
	},
	Interior = {
		parts = { "Interior" },
		material = Enum.Material.Leather,
	},
	Lights_DRL = {
		parts = { "Headlights_Bulbs" },
		material = Enum.Material.Neon,
	},
	Lights_Tail = {
		parts = { "Taillights" },
		material = Enum.Material.Neon,
	},
	Canopy_Glass = {
		parts = { "Body_Glass" },
		material = Enum.Material.Glass,
		transparency = 0.55,
	},
	License_Plate = {
		parts = { "License_Plate" },
		material = Enum.Material.SmoothPlastic,
		transparency = 0,
	},
}

local STATIC_ZONE_DEFAULTS: { [string]: Color3 } = {
	Brake_Rotors = Color3.fromRGB(180, 185, 190),
	Tires = Color3.fromRGB(35, 35, 37),
	Interior = Color3.fromRGB(245, 245, 245),
	Lights_Tail = Color3.fromRGB(255, 60, 60),
	License_Plate = Color3.fromRGB(240, 240, 240),
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
		Body_Main = Color3.fromRGB(159, 161, 172), -- #9FA1AC Nardo Grey
		Aero_Trim = Color3.fromRGB(17, 17, 17), -- Deep Carbon Black
		Wheels_Rims = Color3.fromRGB(163, 162, 165), -- Silver Metallic
		Brake_Calipers = Color3.fromRGB(220, 30, 30), -- Brembo Racing Red
		Lights_DRL = Color3.fromRGB(180, 210, 228), -- Ice Blue Laser
		Canopy_Glass = Color3.fromRGB(25, 28, 35), -- Smoke Tint
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
	local appliedZones: { [string]: boolean } = {}

	for zoneName, color in pairs(palette) do
		appliedZones[zoneName] = true
		ok = VehicleColorService.ApplyZoneColor(carModel, zoneName, color) and ok
	end

	for zoneName, defaultColor in pairs(STATIC_ZONE_DEFAULTS) do
		if not appliedZones[zoneName] then
			ok = VehicleColorService.ApplyZoneColor(carModel, zoneName, defaultColor) and ok
		end
	end

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
