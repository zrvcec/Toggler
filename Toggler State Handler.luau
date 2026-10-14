--!strict
--!nolint LocalShadow

local Toggle = {}
Toggle.__index = Toggle

-- Toggles between true and false states. Can be used to handle toggling events, such as opening and closing a menu.
-- @param ShouldDebounce: If true, the toggler will not allow the same state to be set twice in a row. Default is false.
function Toggle.new(ShouldDebounce:boolean?)
	local self = setmetatable({}, Toggle)
	
	self.Toggled = nil :: boolean?
	self.ToggleHandler = nil :: ((Toggled:boolean, ...any) -> ())?
	self.ShouldDebounce = ShouldDebounce or false
	self.LastTuple = table.pack()
	self.TMode = "STATE"

	return self
end


export type Toggler = typeof(Toggle.new())


-- Sets the handler function for the toggler.
-- @param fn: The function to be called when the toggler state changes.
function Toggle:SetTogglerHandler(fn :(Toggled:boolean, ...any)->())
	local self = self :: Toggler
	
	if typeof(fn) ~= "function" then
		print("SetTogglerHandler received something that was not a function.")
		return false
	end
	
	self.ToggleHandler = fn
	
	return true
end


-- Sets the state of the toggler to the specified value.
-- @param setNewStateTo: The new state to set the toggler to. True for toggled on, false for toggled off.
function Toggle:SetState(setNewStateTo:boolean, ...:any)
	local self = self :: Toggler
	local handle = self.ToggleHandler
    
	if not handle then
		print("Hanlde is missing for toggling")
		return false
	end

	if self.ShouldDebounce and self.Toggled == setNewStateTo then
		return false
	end

	local success: boolean, result:any = pcall(handle, setNewStateTo, ...)
	if not success then
		warn(result)
		return false
	end

	self.LastTuple = table.pack(...)
	self.Toggled = setNewStateTo
	return true
end

-- Reloads the toggler to the last state it was set to. If no previous state has been set, it will return false.
-- Will re run the handler function with previous arguments passed to it.
function Toggle:Reload()
	local self = self :: Toggler
	local CurrentState = self.Toggled
	local setNewStateTo = CurrentState
	
	if setNewStateTo == nil then
		warn("Reloading failed. No previous state has been set.")
		return false
	end
	
	return self:SetState(setNewStateTo, table.unpack(self.LastTuple, 1, self.LastTuple.n))
end

function Toggle:SetStateTrue(...:any)
	local self = self :: Toggler
	return self:SetState(true, ...)
end

function Toggle:SetStateFalse(...:any)
	local self = self :: Toggler
	return self:SetState(false, ...)
end

-- Returns the current state of the toggler. If no state has been set, it will return nil.
function Toggle:GetCurrentState()
	local self = self :: Toggler
	return self.Toggled
end


return Toggle