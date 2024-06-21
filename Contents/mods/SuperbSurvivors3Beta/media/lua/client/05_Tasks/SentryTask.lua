-- Batmane WIP Sentry Task

SentryTask = {}
SentryTask.__index = SentryTask

isSentryCallLogged = false

function SentryTask:new(superSurvivor, square)
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o.parent = superSurvivor
	o.Name = "Sentry"
	o.sentrySquare = square
	o.distanceToSentrySquare = nil
	o.Complete = false
	
	return o
end

function SentryTask:isComplete()
	return false
end

function SentryTask:isValid()
	if self:isComplete() then
		return false
	else
		return true
	end
end


function SentryTask:update()
	if not self:isValid() then return false end


	if not self.distanceToSentrySquare or self.parent.Reducer % (globalBaseUpdateDelayTicks * 4) then 
		self.distanceToSentrySquare = GetCheap3DDistanceBetween(self.parent.player, self.sentrySquare)
	end
	if self.distanceToSentrySquare > 0 then
		self.parent:walkTo(self.sentrySquare)
	end
end
