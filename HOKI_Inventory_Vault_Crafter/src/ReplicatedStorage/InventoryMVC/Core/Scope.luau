--[[ <summary>Owns lazy recipes and nested lifetimes, disposing dependents before dependencies.</summary> ]]
local Scope = {}
Scope.__index = Scope

function Scope.new(parameters)
	return setmetatable({
		Kind = parameters.Kind,
		Context = parameters.Context,
		Token = { IsCancelled = false },
		_parent = parameters.Parent,
		_recipes = parameters.Recipes or {},
		_reportError = parameters.ReportError,
		_updates = parameters.Updates,
		_removeUpdates = {},
		_instances = {},
		_order = {},
		_building = {},
		_children = {},
		_disposed = false,
	}, Scope)
end

function Scope:Register(name, kind, factory)
	assert(not self._recipes[name], "Duplicate recipe: " .. name)
	self._recipes[name] = { Kind = kind, Factory = factory }
end

function Scope:CreateChild(kind, context)
	assert(not self._disposed and kind > self.Kind, "Invalid child scope")
	local child = Scope.new({
		Kind = kind,
		Context = context,
		Parent = self,
		Recipes = self._recipes,
		ReportError = self._reportError,
		Updates = self._updates,
	})
	table.insert(self._children, child)
	return child
end

function Scope:Get(name)
	assert(not self._disposed, "Scope disposed")
	local recipe = assert(self._recipes[name], "Missing recipe: " .. name)
	local owner = self
	while owner and owner.Kind ~= recipe.Kind do
		owner = owner._parent
	end
	assert(owner and not owner._disposed, "Captive dependency: " .. name)
	if owner._instances[name] then
		return owner._instances[name]
	end
	assert(not owner._building[name], "Dependency cycle: " .. name)
	owner._building[name] = true
	local instance
	local success, message = pcall(function()
		instance = recipe.Factory(owner)
		if instance.Init then
			assert(instance.Dispose, "Init requires Dispose: " .. name)
			instance:Init()
		end
		assert(not owner._disposed, "Scope ended during initialization: " .. name)
	end)
	owner._building[name] = nil
	if not success then
		if instance and instance.Dispose then
			local cleaned, cleanupError = pcall(instance.Dispose, instance)
			if not cleaned then
				owner._reportError(tostring(cleanupError))
			end
		end
		error(name .. ": " .. tostring(message))
	end
	owner._instances[name] = instance
	table.insert(owner._order, instance)
	if instance.UpdateLogic then
		owner._removeUpdates[instance] = owner._updates:Add(instance)
	end
	return instance
end

function Scope:Dispose()
	if self._disposed then
		return
	end
	self._disposed = true
	self.Token.IsCancelled = true
	for _, removeUpdate in pairs(self._removeUpdates) do
		removeUpdate()
	end
	table.clear(self._removeUpdates)
	for index = #self._children, 1, -1 do
		self._children[index]:Dispose()
	end
	for index = #self._order, 1, -1 do
		local instance = self._order[index]
		if instance.Dispose then
			local success, message = pcall(instance.Dispose, instance)
			if not success then
				self._reportError(tostring(message))
			end
		end
	end
	table.clear(self._children)
	table.clear(self._order)
	table.clear(self._instances)
	if self._parent and not self._parent._disposed then
		local index = table.find(self._parent._children, self)
		if index then
			table.remove(self._parent._children, index)
		end
	end
	self._parent = nil
	self.Context = nil
end

return Scope
