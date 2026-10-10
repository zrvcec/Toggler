# Toggler
A lightweight, reusable Luau module for managing states intended for scaling purposes

These small basic systems come with:
    + Dynamic Toggling with numbers
    + State Toggling with Booleans
    + Debounce handling
    + Extra arguments
    + returns if actions succeeded by type of result: boolean

# Cleanup
    To clean up old state handlers, simply set the reference holding their data to nil and let Lua’s garbage collector handle the rest.


# Example on use case

local shouldDebounce = true
local function fn(STATE: boolean, otherPassedArguments)
    print(STATE, otherPassedArguments)
end

TogglingObject = referencetoscipt.new(shouldDebounce)
TogglingObject:SetTogglerHandler(fn)

TogglingObject:SetStateTrue(...)


Bypass shouldDebounce on certain circumstances use:
TogglingObject:Reload()
