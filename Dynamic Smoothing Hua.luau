--!strict

local RunService = game:GetService("RunService")
local Signal = require("./Signal/Signal")

local DSG = {}
DSG.__index = DSG

local EPSILON = 0.001 -- snap to the target once this close

-- A smoother takes where we are, where we want to be, and the frame time,
-- and returns the next value.
export type Smoother = (current: number, target: number, dt: number) -> number

export type DSGProduct = typeof(setmetatable({} :: {
	Current: number,
	Target: number,
	ValueChanged: typeof(Signal.new()),
	_smoother: Smoother?,
	_conn: RBXScriptConnection?,
}, DSG))

function DSG.new(initial: number?): DSGProduct
	local start = initial or 0
	return setmetatable({
		Current = start,
		Target = start,
		ValueChanged = Signal.new(),
		_smoother = nil :: Smoother?,
		_conn = nil :: RBXScriptConnection?,
	}, DSG)
end

-- Ready-made smoother: eases toward the target. Higher speed = faster (try 8 to 15).
function DSG.Exponential(speed: number): Smoother
	return function(current: number, target: number, dt: number): number
		local alpha = 1 - math.exp(-speed * dt)
		return current + (target - current) * alpha
	end
end

-- Sets Current directly and fires ValueChanged if it actually changed
function DSG._apply(self: DSGProduct, value: number)
	local old = self.Current
	if value == old then return end

	self.Current = value
	self.ValueChanged:Fire(value, old)
end

function DSG._stopStepping(self: DSGProduct)
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
end

function DSG._step(self: DSGProduct, dt: number)
	local smoother = self._smoother
	if not smoother then
		self:_stopStepping()
		return
	end

	local nextValue = smoother(self.Current, self.Target, dt)
	if math.abs(self.Target - nextValue) < EPSILON then
		nextValue = self.Target
	end

	self:_apply(nextValue)

	if nextValue == self.Target then
		self:_stopStepping()
	end
end

-- Pass nil to turn smoothing off (values then jump instantly)
function DSG.SetSmoothing(self: DSGProduct, smoother: Smoother?)
	self._smoother = smoother
	if not smoother then
		self:_stopStepping()
		self:_apply(self.Target)
	end
end

-- Sets the target. With a smoother the value glides there over time, firing
-- ValueChanged every step; without one (or with instant = true) it jumps.
function DSG.SetValue(self: DSGProduct, newValue: number, instant: boolean?)
	self.Target = newValue

	if not self._smoother or instant then
		self:_stopStepping()
		self:_apply(newValue)
		return
	end

	if not self._conn then
		self._conn = RunService.Heartbeat:Connect(function(dt: number)
			self:_step(dt)
		end)
	end
end

function DSG.Destroy(self: DSGProduct)
	self:_stopStepping()
end

return DSG