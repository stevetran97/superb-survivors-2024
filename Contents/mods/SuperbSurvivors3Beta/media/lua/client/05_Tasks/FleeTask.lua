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
	if self:isComplete() then
		return false
	else
		return true
	end
end

local angleCheckRange = 360
local angleDivisions = 4 -- increments of 90deg
local angleCheckIncrement = angleCheckRange / angleDivisions

-- Test Trimmed Flee Function
function FleeTask:update()
	if not self:isValid() then return false end

	self.parent:setSneaking(false);
	CreateLogLine("DebugFlee", isFleeCallLogged, tostring(self.parent:getName()) .. " is actually fleeing to distance (Flee Task) " .. tostring(self.distanceToGo));
	
	-- Note this scanning system doesnt properly assess if a square is not accessible to the player and they still think blocked water squares can are valid escape route
	local attemptIdx = 0
	local targetSquareObj
	while attemptIdx <= angleDivisions do 
		local angleDeg = attemptIdx * angleCheckIncrement
		local angleRad = math.rad(angleDeg)
		local fleeVector
		if attemptIdx ~= 0 then 
			fleeVector = {
				x= self.parent.escapeVector.x * math.cos(angleRad) - self.parent.escapeVector.y * math.sin(angleRad),
				y= self.parent.escapeVector.x * math.sin(angleRad) + self.parent.escapeVector.y * math.cos(angleRad)
			}
		else
			fleeVector = self.parent.escapeVector
		end
		CreateLogLine('DebugFlee', isFleeCallLogged, tostring(self.parent:getName()) .. 'fleeVector.x = ' .. tostring(fleeVector.x))
		CreateLogLine('DebugFlee', isFleeCallLogged, tostring(self.parent:getName()) .. 'fleeVector.y = ' .. tostring(fleeVector.y))

		-- Batmanes: New Flee Function Start
		local targetSquareToTravelTo = getXYSq2FromSq1ToVector(self.parent.player, convertToUnitVector(fleeVector), self.distanceToGo)

		if attemptIdx > angleDivisions - 1 then
			if not targetSquareToTravelTo or
				not targetSquareToTravelTo.x or
				not targetSquareToTravelTo.y
			then
				CreateLogLine('Flee Errors', enableLogErrors, 'FleeTask:update(): Cannot calculate a target to travel to')
				self.Complete = true
				return
			end
		end

		-- Randomize target square
		-- local fleeTargetRange = math.ceil(self.distanceToGo/2)
		-- local fleeTargetRange = (self.parent:getBuilding() ~= nil and 3) or 5
		local fleeTargetRange = math.max(self.distanceToGo/2, 2)
		targetSquareToTravelTo.x = math.ceil(targetSquareToTravelTo.x + ZombRand(-fleeTargetRange, fleeTargetRange))
		targetSquareToTravelTo.y = math.ceil(targetSquareToTravelTo.y + ZombRand(-fleeTargetRange, fleeTargetRange))

		targetSquareObj = self.parent.player:getCell():getGridSquare(targetSquareToTravelTo.x, targetSquareToTravelTo.y, self.parent.player:getZ())

		if targetSquareObj and not targetSquareObj:isBlockedTo(self.parent.player:getCurrentSquare()) then 
			CreateLogLine('DebugFlee', isFleeCallLogged, tostring(self.parent:getName()) .. 'Found a flee square!')
			break 
		end
		
		attemptIdx = attemptIdx + 1

		if attemptIdx > angleDivisions - 1 then
			if not targetSquareObj
			then
				CreateLogLine('Flee Errors', true, tostring(self.parent:getName()) .. ' FleeTask:update(): Cannot find a target square to travel to')
				self.Complete = true
				return
			end
		end

		if attemptIdx > angleDivisions - 1 then break end
	end


	local distToTravelSquare = GetXYDistanceBetween(self.parent.player, targetSquareObj)
	CreateLogLine("DebugFlee", isFleeCallLogged, tostring(self.parent:getName()) .. " has distance to flee to of " .. tostring(distToTravelSquare));
	CreateLogLine("DebugFlee", isFleeCallLogged, tostring(self.parent:getName()) .. " isMoving " .. tostring(self.parent.player:isMoving()));
	CreateLogLine("DebugFlee", isFleeCallLogged, tostring(self.parent:getName()) .. " isPlayerMoving " .. tostring(self.parent.player:isPlayerMoving()));
	CreateLogLine("DebugFlee", isFleeCallLogged, tostring(self.parent:getName()) .. " getPath2 " .. tostring(self.parent.player:getPath2()));


	if distToTravelSquare < 1 then 
		self.Complete = true
		return
	end

	-- Dynamically switch run mode while task is active
	if self.parent.EnemiesOnMe >= 2 then
		self.parent:setRunning(true)
	-- else
	-- 	self.parent:setRunning(false)
	end

	-- Need to add function here that checks if it is even possible to go to that square
	self.parent:walkTo(targetSquareObj)
end


-- Heavy Flee Task - More cases considered
-- function FleeTask:update()
-- 	if not self:isValid() then return false end

-- 	self.parent:setSneaking(false);
-- 	CreateLogLine("DebugFlee", isFleeCallLogged, tostring(self.parent:getName()) .. " is actually fleeing to distance (Flee Task) " .. tostring(self.distanceToGo));
	
-- 	-- Note this scanning system doesnt properly assess if a square is not accessible to the player and they still think blocked water squares can are valid escape route
-- 	local attemptIdx = 0
-- 	local targetSquareObj
-- 	while attemptIdx <= angleDivisions do 
-- 		CreateLogLine('DebugFlee', true, tostring(self.parent:getName()) .. 'attemptIdx = ' .. tostring(attemptIdx))

-- 		local angleDeg = attemptIdx * angleCheckIncrement
-- 		local angleRad = math.rad(angleDeg)
-- 		CreateLogLine('DebugFlee', isFleeCallLogged, tostring(self.parent:getName()) .. 'angleDeg = ' .. tostring(angleDeg))
-- 		CreateLogLine('DebugFlee', isFleeCallLogged, tostring(self.parent:getName()) .. 'angleRad = ' .. tostring(angleRad))

-- 		local fleeVector
-- 		if attemptIdx ~= 0 then 
-- 			fleeVector = {
-- 				x= self.parent.escapeVector.x * math.cos(angleRad) - self.parent.escapeVector.y * math.sin(angleRad),
-- 				y= self.parent.escapeVector.x * math.sin(angleRad) + self.parent.escapeVector.y * math.cos(angleRad)
-- 			}
-- 		else
-- 			fleeVector = self.parent.escapeVector
-- 		end
-- 		CreateLogLine('DebugFlee', isFleeCallLogged, tostring(self.parent:getName()) .. 'fleeVector.x = ' .. tostring(fleeVector.x))
-- 		CreateLogLine('DebugFlee', isFleeCallLogged, tostring(self.parent:getName()) .. 'fleeVector.y = ' .. tostring(fleeVector.y))

-- 		-- Batmanes: New Flee Function Start
-- 		local targetSquareToTravelTo = getXYSq2FromSq1ToVector(self.parent.player, convertToUnitVector(fleeVector), self.distanceToGo)
-- 		CreateLogLine("DebugFlee", isFleeCallLogged, tostring(self.parent:getName()) .. " is actually fleeing to SQUARE " .. tostring(targetSquareToTravelTo));

-- 		if attemptIdx > angleDivisions then
-- 			if not targetSquareToTravelTo or
-- 				not targetSquareToTravelTo.x or
-- 				not targetSquareToTravelTo.y
-- 			then
-- 				CreateLogLine('Flee Errors', enableLogErrors, 'FleeTask:update(): Cannot calculate a target to travel to')
-- 				self.Complete = true
-- 				return
-- 			end
-- 		end

-- 		-- Randomize target square
-- 		-- local fleeTargetRange = math.ceil(self.distanceToGo/2)
-- 		-- targetSquareToTravelTo.x = math.ceil(targetSquareToTravelTo.x + ZombRand(-fleeTargetRange, fleeTargetRange))
-- 		-- targetSquareToTravelTo.y = math.ceil(targetSquareToTravelTo.y + ZombRand(-fleeTargetRange, fleeTargetRange))

-- 		targetSquareObj = self.parent.player:getCell():getGridSquare(targetSquareToTravelTo.x, targetSquareToTravelTo.y, self.parent.player:getZ())

-- 		CreateLogLine('DebugFlee', isFleeCallLogged, tostring(self.parent:getName()) .. ' targetSquareObj = ' .. tostring(targetSquareObj))
-- 		CreateLogLine('DebugFlee', isFleeCallLogged, tostring(self.parent:getName()) .. ' self.parent.player:getCurrentSquare() = ' .. tostring(self.parent.player:getCurrentSquare()))

-- 		if targetSquareObj and not targetSquareObj:isBlockedTo(self.parent.player:getCurrentSquare()) then 
-- 			CreateLogLine('DebugFlee', isFleeCallLogged, tostring(self.parent:getName()) .. 'Found a flee square!')
-- 			break 
-- 		end
		
-- 		attemptIdx = attemptIdx + 1

-- 		if attemptIdx > angleDivisions then
-- 			if not targetSquareObj
-- 			then
-- 				CreateLogLine('Flee Errors', enableLogErrors, 'FleeTask:update(): Cannot find a target square to travel to')
-- 				self.Complete = true
-- 				return
-- 			end
-- 		end

-- 		if attemptIdx > angleDivisions then break end
-- 	end


-- 	local distToTravelSquare = GetXYDistanceBetween(self.parent.player, targetSquareObj)
-- 	CreateLogLine("DebugFlee", isFleeCallLogged, tostring(self.parent:getName()) .. " has distance to flee to of " .. tostring(distToTravelSquare));

-- 	if distToTravelSquare < 1 then 
-- 		self.Complete = true
-- 		return
-- 	end

-- 	-- Dynamically switch run mode while task is active
-- 	if self.parent.EnemiesOnMe >= 2 then
-- 		self.parent:setRunning(true)
-- 	else
-- 		self.parent:setRunning(false)
-- 	end

-- 	-- Need to add function here that checks if it is even possible to go to that square
-- 	self.parent:walkTo(targetSquareObj)
-- end
