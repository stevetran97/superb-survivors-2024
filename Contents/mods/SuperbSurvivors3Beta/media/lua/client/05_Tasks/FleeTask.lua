FleeTask = {}
FleeTask.__index = FleeTask

isFleeCallLogged = false

function FleeTask:new(superSurvivor, shouldRun, distanceToGo)
	if shouldRun == nil then
        shouldRun = true
    end
	if distanceToGo == nil then
        distanceToGo = 5
    end

	local o = {}
	setmetatable(o, self)
	self.__index = self
	superSurvivor:setRunning(shouldRun)
	o.parent = superSurvivor
	o.Name = "Flee"
	o.OnGoing = false
	o.shouldRun = shouldRun
	o.distanceToGo = distanceToGo

	if o.parent.TargetBuilding ~= nil then o.parent:MarkAttemptedBuildingExplored(o.parent.TargetBuilding) end -- otherwise he just keeps running back to the building though the threat likely lingers there

	return o
end

function FleeTask:isComplete()
	if self.parent:getEnemiesOnMe() == 0 or self.parent:needToFollow() then
		self.parent:StopWalk()
		CreateLogLine("SuperSurvivor", isFleeCallLogged, tostring(self.parent:getName()) .. " has completed flee task ");
		return true
	else
		return false
	end
end

function FleeTask:isValid()
	if not self.parent or self:isComplete() or not self.parent.LastEnemySeen then
		return false
	else
		return true
	end
end

function FleeTask:update()
	if self.shouldRun then
		self.parent:setRunning(self.shouldRun)
	else
		self.parent:setRunning(false)
	end

	if not self:isValid() then return false end

	if 
		-- self.parent.player and -- Batmane - if player doesnt exist while task is running, you got bigger problems
		self.parent.LastEnemySeen 
	then
		self.parent:setSneaking(false);
		CreateLogLine("SuperSurvivor", isFleeCallLogged, tostring(self.parent:getName()) .. " is actually fleeing to distance (Flee Task) " .. tostring(self.distanceToGo));
		
		-- Old Flee function
		-- self.parent:walkTo(GetFleeSquare(self.parent.player, self.parent.LastEnemySeen, self.distanceToGo))
		
		-- Batmanes: New Flee Function Start
		local targetSquareToTravelTo = getXYSq2FromSq1ToVector(self.parent.player, self.parent.escapeVector, self.distanceToGo)

		if not targetSquareToTravelTo
			or not targetSquareToTravelTo.x
			or not targetSquareToTravelTo.y 
		then
			CreateLogLine('Errors', enableLogErrors, 'FleeTask:update(): Cannot find a target square to travel to')
			return
		end

		local fleeTargetRange = math.ceil(self.distanceToGo/2)
		-- local fleeTargetRange = 0

		targetSquareToTravelTo.x = math.ceil(targetSquareToTravelTo.x + ZombRand(-fleeTargetRange, fleeTargetRange))
		targetSquareToTravelTo.y = math.ceil(targetSquareToTravelTo.y + ZombRand(-fleeTargetRange, fleeTargetRange))

		self.parent:walkTo(self.parent.player:getCell():getGridSquare(targetSquareToTravelTo.x, targetSquareToTravelTo.y, self.parent.player:getZ()))
		-- New Flee Function End
	end
end
