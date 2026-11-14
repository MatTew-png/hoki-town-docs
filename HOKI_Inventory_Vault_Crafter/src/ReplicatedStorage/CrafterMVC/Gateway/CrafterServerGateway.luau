--!strict
-- /// <summary>Binds workspace Crafter ProximityPrompts and routes validated client crafting messages.</summary>
local HttpService = game:GetService("HttpService")

local CrafterServerGateway = {}
CrafterServerGateway.__index = CrafterServerGateway

local function getPartPosition(target: Instance): Vector3?
	if target:IsA("BasePart") then
		return target.Position
	elseif target:IsA("Model") then
		return target:GetPivot().Position
	end
	return nil
end

function CrafterServerGateway.new(parameters)
	return setmetatable({
		Workspace = parameters.Workspace,
		Players = parameters.Players,
		Channel = parameters.Channel,
		Commands = parameters.Commands,
		Events = parameters.Events,
		Names = parameters.Names,
		Config = parameters.Config,
		Anchors = {},
		Connections = {},
		Subscriptions = {},
		Disposed = false,
	}, CrafterServerGateway)
end

function CrafterServerGateway:bindPrompt(prompt: ProximityPrompt, stationId: string, anchor: Instance)
	table.insert(
		self.Connections,
		prompt.Triggered:Connect(function(player)
			if self.Disposed or not player.Parent then
				return
			end
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local anchorPos = getPartPosition(anchor)
			if not humanoid or humanoid.Health <= 0 or not root or not anchorPos then
				return
			end
			if (root.Position - anchorPos).Magnitude > self.Config.OpenDistanceStuds + 4 then
				return
			end
			local sessionId = HttpService:GenerateGUID(false)
			self.Anchors[player.UserId] = { Anchor = anchor, SessionId = sessionId, StationId = stationId }
			self.Commands:Enqueue(table.freeze({
				Name = self.Names.Open,
				UserId = player.UserId,
				StationId = stationId,
				SessionId = sessionId,
			}))
		end)
	)
end

function CrafterServerGateway:scanWorkspace()
	for _, inst in ipairs(self.Workspace:GetDescendants()) do
		local stationId = inst:GetAttribute("CrafterId")
		if type(stationId) == "string" and self.Config.Stations[stationId] then
			local prompt = inst:FindFirstChildOfClass("ProximityPrompt") or inst:FindFirstChild("ProximityPrompt", true)
			if prompt and prompt:IsA("ProximityPrompt") then
				self:bindPrompt(prompt, stationId, inst)
			end
		end
	end
end

function CrafterServerGateway:Init()
	self:scanWorkspace()
	local names = self.Names

	for _, eventName in ipairs({ names.Opened, names.Closed, names.StateChanged, names.CraftResult }) do
		table.insert(
			self.Subscriptions,
			self.Events:Subscribe(eventName, function(payload)
				local player = self.Players:GetPlayerByUserId(payload.UserId)
				if player then
					self.Channel:FireClient(player, {
						Name = eventName,
						Payload = payload,
					})
				end
			end)
		)
	end

	table.insert(
		self.Connections,
		self.Channel.OnServerEvent:Connect(function(player, message)
			if self.Disposed or type(message) ~= "table" then
				return
			end
			local active = self.Anchors[player.UserId]
			if message.Name == names.Close then
				self.Anchors[player.UserId] = nil
				self.Commands:Enqueue(table.freeze({
					Name = names.Close,
					UserId = player.UserId,
					SessionId = active and active.SessionId or nil,
				}))
				return
			end
			if not active then
				return
			end
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local anchorPos = getPartPosition(active.Anchor)
			if
				not humanoid
				or humanoid.Health <= 0
				or not root
				or not anchorPos
				or (root.Position - anchorPos).Magnitude > self.Config.CloseDistanceStuds + 4
			then
				self.Anchors[player.UserId] = nil
				self.Commands:Enqueue(table.freeze({
					Name = names.Close,
					UserId = player.UserId,
					SessionId = active.SessionId,
				}))
				return
			end

			if message.Name == names.Craft then
				if type(message.RecipeId) ~= "string" or type(message.Quantity) ~= "number" then
					return
				end
				self.Commands:Enqueue(table.freeze({
					Name = names.Craft,
					UserId = player.UserId,
					SessionId = active.SessionId,
					RecipeId = message.RecipeId,
					Quantity = math.floor(message.Quantity),
				}))
			elseif message.Name == names.Refresh then
				self.Commands:Enqueue(table.freeze({
					Name = names.Refresh,
					UserId = player.UserId,
					SessionId = active.SessionId,
				}))
			end
		end)
	)

	table.insert(
		self.Connections,
		self.Players.PlayerRemoving:Connect(function(player)
			self.Anchors[player.UserId] = nil
			self.Commands:Enqueue(table.freeze({
				Name = names.Close,
				UserId = player.UserId,
			}))
		end)
	)
end

function CrafterServerGateway:Dispose()
	if self.Disposed then
		return
	end
	self.Disposed = true
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	for _, unsub in ipairs(self.Subscriptions) do
		unsub()
	end
	table.clear(self.Connections)
	table.clear(self.Subscriptions)
	table.clear(self.Anchors)
end

return CrafterServerGateway
