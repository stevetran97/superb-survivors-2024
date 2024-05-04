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
	o.Complete = false
	
	-- o.targetSquareToTravelTo = getXYSq2FromSq1ToVector(o.parent.player, convertToUnitVector(o.parent.escapeVector), o.distanceToGo)
	-- CreateLogLine("DebugFlee", true, tostring(o.parent:getName()) .. " setting initial flee square " .. tostring(o.targetSquareToTravelTo));
	-- local testTarget = o.parent.player:getCell():getGridSquare(o.targetSquareToTravelTo.x, o.targetSquareToTravelTo.y, o.parent.player:getZ())
	-- local distToTravelSquare = GetXYDistanceBetween(o.parent.player, testTarget)
	-- CreateLogLine("DebugFlee", true, tostring(o.parent:getName()) .. " has set initial distance to travel " .. tostring(distToTravelSquare));

	-- We only instantiate running once and allow it to be controlled dynamically
	if shouldRun then
		o.parent:setRunning(shouldRun)
	else
		o.parent:setRunning(false)
	end

	if o.parent.TargetBuilding ~= nil then o.parent:MarkAttemptedBuildingExplored(o.parent.TargetBuilding) end -- otherwise he just keeps running back to the building though the threat likely lingers there

	return o
end

function FleeTask:isComplete()
	if 
		self.Complete or
		self.parent:getEnemiesOnMe() == 0 or
		self.parent:needToFollow() 
	then
		self.parent:StopWalk()
		CreateLogLine("SuperSurvivor", isFleeCallLogged, tostring(self.parent:getName()) .. " has completed flee task ");
		return true
	else
		return false
	end
end

function FleeTask:isValid()
	if not self.parent or self:isComplete() then
		return false
	else
		return true
	end
end

function FleeTask:update()
	if not self:isValid() then return false end

	self.parent:setSneaking(false);
	CreateLogLine("DebugFlee", isFleeCallLogged, tostring(self.parent:getName()) .. " is actually fleeing to distance (Flee Task) " .. tostring(self.distanceToGo));
	
	-- Batmanes: New Flee Function Start
	local targetSquareToTravelTo = getXYSq2FromSq1ToVector(self.parent.player, convertToUnitVector(self.parent.escapeVector), self.distanceToGo)
	-- local targetSquareToTravelTo = self.targetSquareToTravelTo
	-- CreateLogLine("DebugFlee", true, tostring(self.parent:getName()) .. " is actually fleeing to SQUARE " .. tostring(targetSquareToTravelTo));

	-- local fleeTargetRange = math.ceil(self.distanceToGo/2)

	-- targetSquareToTravelTo.x = math.ceil(targetSquareToTravelTo.x + ZombRand(-fleeTargetRange, fleeTargetRange))
	-- targetSquareToTravelTo.y = math.ceil(targetSquareToTravelTo.y + ZombRand(-fleeTargetRange, fleeTargetRange))

	if not targetSquareToTravelTo or
		not targetSquareToTravelTo.x or
		not targetSquareToTravelTo.y
	then
		CreateLogLine('Flee Errors', enableLogErrors, 'FleeTask:update(): Cannot calculate a target to travel to')
		self.Complete = true
		return
	end

	local targetSquareObj = self.parent.player:getCell():getGridSquare(targetSquareToTravelTo.x, targetSquareToTravelTo.y, self.parent.player:getZ())

	if not targetSquareObj
	then
		CreateLogLine('Flee Errors', enableLogErrors, 'FleeTask:update(): Cannot find a target square to travel to')
		self.Complete = true
		return
	end

	local distToTravelSquare = GetXYDistanceBetween(self.parent.player, targetSquareObj)
	-- CreateLogLine("DebugFlee", true, tostring(self.parent:getName()) .. " has distance to flee to of " .. tostring(distToTravelSquare));

	if distToTravelSquare < 1 then 
		self.Complete = true
		return
	end

	-- Dynamically switch run mode while task is active
	if self.parent.EnemiesOnMe >= 2 then
		self.parent:setRunning(true)
	else
		self.parent:setRunning(false)
	end

	-- Need to add function here that checks if it is even possible to go to that square
	self.parent:walkTo(targetSquareObj)
end
