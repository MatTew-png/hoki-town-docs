--!strict
-- /// <summary>Binds workspace vault ProximityPrompts and routes validated client messages.</summary>
local HttpService = game:GetService("HttpService")

local VaultServerGateway = {}
VaultServerGateway.__index = VaultServerGateway

local function getPartPosition(target: Instance): Vector3?
	if target:IsA("BasePart") then
		return target.Position
	elseif target:IsA("Model") then
		return target:GetPivot().Position
	end
	return nil
end

function VaultServerGateway.new(parameters)
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
	}, VaultServerGateway)
end

function VaultServerGateway:bindPrompt(prompt: ProximityPrompt, vaultId: string, anchor: Instance)
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
			self.Anchors[player.UserId] = { Anchor = anchor, SessionId = sessionId, VaultId = vaultId }
			self.Commands:Enqueue(table.freeze({
				Name = self.Names.Open,
				UserId = player.UserId,
				VaultId = vaultId,
				SessionId = sessionId,
			}))
		end)
	)
end

function VaultServerGateway:scanWorkspace()
	for _, inst in ipairs(self.Workspace:GetDescendants()) do
		local vaultId = inst:GetAttribute("VaultId")
		if type(vaultId) == "string" and self.Config.Vaults[vaultId] then
			local prompt = inst:FindFirstChildOfClass("ProximityPrompt") or inst:FindFirstChild("ProximityPrompt", true)
			if prompt and prompt:IsA("ProximityPrompt") then
				self:bindPrompt(prompt, vaultId, inst)
			end
		end
	end
end

function VaultServerGateway:Init()
	self:scanWorkspace()
	local names = self.Names

	for _, eventName in ipairs({ names.Opened, names.Closed, names.StateChanged, names.TransferResult }) do
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

			if message.Name == names.Deposit or message.Name == names.Withdraw then
				if type(message.ItemId) ~= "string" or type(message.Amount) ~= "number" then
					return
				end
				self.Commands:Enqueue(table.freeze({
					Name = message.Name,
					UserId = player.UserId,
					SessionId = active.SessionId,
					ItemId = message.ItemId,
					Amount = math.floor(message.Amount),
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

function VaultServerGateway:Dispose()
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

return VaultServerGateway
