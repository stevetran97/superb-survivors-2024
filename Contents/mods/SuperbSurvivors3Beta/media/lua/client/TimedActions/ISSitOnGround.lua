require "TimedActions/ISBaseTimedAction"

-- No clue how to enact this 
ISSitOnGround = ISBaseTimedAction:derive("ISSitOnGround")

function ISSitOnGround:isValid()
	return true
end

function ISSitOnGround:update()
    if not self.character then return nil end
end

function ISSitOnGround:start()
	return true
end

function ISSitOnGround:stop()
    ISBaseTimedAction.stop(self)
end

function ISSitOnGround:perform()
	ISBaseTimedAction.perform(self)
end

function ISSitOnGround:new(character)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
	o.maxTime = -1;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    return o;
end