require "04_Group.SuperSurvivorManager";

FollowTask = {}
FollowTask.__index = FollowTask

local isLocalLoggingEnabled = false;

function FollowTask:new(superSurvivor, FollowMeplayer)
	CreateLogLine("FollowTask", isLocalLoggingEnabled, "function: FollowTask:new() called");

	local o = {}
	setmetatable(o, self)
	self.__index = self

	if (FollowMeplayer == nil) then
		if (superSurvivor.player:getModData().FollowCharID ~= nil) then
			local SS = SSM:Get(superSurvivor.player:getModData().FollowCharID)
			if (SS ~= nil) then
				o.FollowChar = SS:Get()
			else
				return false
			end
		end
	else
		o.FollowChar = FollowMeplayer
		superSurvivor.player:getModData().FollowCharID = FollowMeplayer:getModData().ID -- save last follow obj id to mod data so can be reused on load
	end

	o.followSS = SSM:Get(o.FollowChar:getModData().ID)
	o.group = o.followSS:getGroup()
	-- o.InBaseAtStart = superSurvivor:isInBase() -- Phase out 
	o.parent = superSurvivor
	o.Name = "Follow"
	o.OnGoing = true
	o.LastDistance = 0
	o.Complete = false
	o.MySeat = -1
	o.MyDoor = -1
	-- This is literally always 0 wherever it is used
	o.FollowDistanceOffset = 0

	if (o.group ~= nil) then
		o.FollowDistanceOffset = 0
	end

	return o
end

function FollowTask:ForceComplete()
	self.Complete = true
end

function FollowTask:isComplete()
	return self.Complete
end

function FollowTask:isValid()
	if not self.parent or not self.FollowChar then
		return false
	else
		return true
	end
end

function FollowTask:needToFollow()
	if self.Complete == true or self.parent == nil or self.FollowChar == nil or self.FollowChar:getCurrentSquare() == nil then return false end

	local distance = GetXYDistanceBetween(self.parent.player, self.FollowChar)
	if distance > GFollowDistance + self.FollowDistanceOffset 
		or self.FollowChar:getZ() ~= self.parent.player:getZ()
		or self.parent:getBuilding() ~= self.FollowChar:getCurrentSquare():getBuilding() -- Why just being in a vehicle was a standlone condition for needing to follow makes no sense to me
		or (self.parent:Get():getVehicle() and self.FollowChar:getVehicle() ~= self.parent:Get():getVehicle())
	then
		-- self.parent:NPC_ERW_AroundMainPlayer(GFollowDistance)
		return true
	else
		return false
	end
end

function FollowTask:RemoveDoorClaimed(tempDoor)
	if tempDoor == nil then return false end
	tempDoor:getSquare():getModData().doorclaimed = false
end

function FollowTask:ClaimDoor(tempDoor)
	if tempDoor == nil then return false end
	tempDoor:getSquare():getModData().doorclaimed = true
end

function FollowTask:isDoorClaimed(tempDoor)
	if tempDoor == nil then return false end
	if tempDoor:getSquare():getModData().doorclaimed == true then
		return true
	else
		return false;
	end
end

-- Batmane Notes: 
-- NPCs do not climb up ropes into building when there are blocked stairs. They just hang out at the rope
-- NPCs do not climb down fence ropes
-- NPCs can only climb up/down ropes on windows. There is no other way to do this. PZ does not give you a way to identify instances of fences.
-- This dont always work - Sometimes they get stuck and you need to bait them away from the rope. Maybe introduce a finite while

function FollowTask:update()
	CreateLogLine("FollowTask", isLocalLoggingEnabled, "function: FollowTask:update() called");
	if (not self:isValid()) then return false end

	local distance = GetXYDistanceBetween(self.parent.player, self.FollowChar)

	self.parent:setSneaking(self.FollowChar:isSneaking()) -- sneaking if person you follow is

	-- self.parent.player:NPCSetAiming(self.FollowChar:isAiming()) -- Batmane - Aim if person you follow is - WIP not workign ATM  -- NPC cant move while aiming wtf 
	-- self.parent.player:setIsAiming(self.FollowChar:isAiming()) -- Batmane - Aim if person you follow is - Doesnt do anything
	-- self.parent.player:setForceAim(self.FollowChar:isAiming()) -- Batmane - Aim if person you follow is - Doesnt do anything

	-- if self.FollowChar:isAiming()
	-- then 
	-- 	self.parent.player:NPCSetAiming(self.FollowChar:isAiming()) -- Batmane - Aim if person you follow is - WIP not workign ATM
	-- 	self.parent.player:setAutoWalk(true)
	-- 	self.parent.player:setAutoWalkDirection(
	-- 		Vector2(1, 1)
	-- 	)
	-- end
	-- Experimentation


	-- they keep talking
	if ZombRand(70) == 0 and not CanIdleChat then
		self.parent:Speak(Get_SS_DialogueSpeech("IdleChatter"))
	end

	-- if true then -- self.parent:isInAction() == false) then -- for some reason this is true when they doing nothing sometimes...

	-- Batmane -- 
	-- This is such a redundant check that happens only once in a game but costs computation every single update...
	-- Just disable it 
	-- if self.InBaseAtStart == true and not self.parent:isInBase() then
	-- 	if ZombRand(2) == 0 then
	-- 		self.parent:Speak(Get_SS_Dialogue("WeLooting"))
	-- 	end
	-- 	self.InBaseAtStart = false
	-- end

	if self.FollowChar:getVehicle() and self.FollowChar:getVehicle() == self.parent:Get():getVehicle() then
		self.Complete = true
		return -- We do not need to process further if NPC is in the same car as player
	end

	-- if 
	-- 	-- not self.InBaseAtStart and -- Redundant phase out completely
	-- 	self.parent:isInBase() and -- Maybe should phase this out -- Kinda annoying to get them to refollow
	-- 	not self.parent:Get():getVehicle()
	-- then			
	-- 	self.Complete = true

	-- 	self.parent:Speak(Get_SS_UIActionText("WeBackToBase"))
	-- 	return -- We do not need to process further if we are done
	-- end


	if distance > GFollowDistance + self.FollowDistanceOffset + 5 
		-- or self.FollowChar:getVehicle() ~= self.parent:Get():getVehicle() -- Not needed, this clause can generally be true
	then
		self.parent:setRunning(true)
	else
		self.parent:setRunning(false)
	end

	-- Rope Climbing Logic Start
	local ropeSquare = nil
	-- Going Up
	if self.FollowChar:getZ() > self.parent.player:getZ()
		and self.parent:isInSameBuilding(self.FollowChar) == false
	then
		ropeSquare = self.parent:findNearestSheetRopeSquare(false)
		if ropeSquare then
			ISTimedActionQueue.add(ISWalkToTimedAction:new(self.parent.player, ropeSquare))
			ISTimedActionQueue.add(ISClimbSheetRopeAction:new(self.parent.player, false))
			-- self.parent:Wait(4)
		else
			CreateLogLine("FollowTask", isLocalLoggingEnabled, "no rope square");
		end
	-- Going Down
	elseif self.FollowChar:getZ() < self.parent.player:getZ() and 
		self.parent:isInSameBuilding(self.FollowChar) == false 
	then
		ropeSquare = self.parent:findNearestSheetRopeSquare(true)
		if ropeSquare then
			-- Climb out Window
			-- local window = GetSquaresNearWindow(ropeSquare)
			local window = GetResourceFromSquaresAroundAccessPoint(ropeSquare, getSquaresWindow) -- Batmane replace above dupe code
			if window then
				self.parent:StopWalk()
				local indoorSquare = window:getIndoorSquare()
				ISTimedActionQueue.add(ISWalkToTimedAction:new(self.parent.player, indoorSquare))
				ISTimedActionQueue.add(ISClimbThroughWindow:new(self.parent.player, window, 20))
				return
			end
			-- Batmane Apr 24 - 2024 - Hop fences with rope
			local hoppable = GetResourceFromSquaresAroundAccessPoint(ropeSquare, getHoppable)
			if hoppable then 
				local squareToClimb = hoppable:getSquare()
				if luautils.walkAdjWindowOrDoor(self.parent.player, squareToClimb, hoppable) then
					ISTimedActionQueue.add(ISClimbOverFence:new(self.parent.player, hoppable))
				end
				return
			end
		else
			CreateLogLine("FollowTask", isLocalLoggingEnabled, "no rope square");
		end
	end
	-- Rope Climbing Logic End
	-- General Path finding start
	if not ropeSquare then
		if distance > (GFollowDistance + self.FollowDistanceOffset) 
			-- and not self.parent:Get():getVehicle() -- Already handled above -- Means ai is not in a vehicle
		then
			local gotosquare = self.FollowChar:getCurrentSquare()
			if gotosquare then
				if gotosquare:getRoom() and gotosquare:getRoom():getBuilding() then
					self.parent.TargetBuilding = gotosquare:getRoom():getBuilding()
				else
					self.parent.TargetBuilding = nil
				end
				self.parent:walkTo(gotosquare)
			end
		-- Handle Getting in Players car if player is in a car
		elseif self.FollowChar:getVehicle() and not self.parent:Get():getVehicle() then
			local car = self.FollowChar:getVehicle()
			self.MySeat = -1
			local doorseat = -1
			local lastgoodDoor = nil
			local lastgoodDoorDistance = 999
			local tempDoor = nil
			local numOfSeats = car:getScript():getPassengerCount()
			
			for seat = numOfSeats - 1, 1, -1 do
				tempDoor = car:getPassengerDoor(seat)
				if not tempDoor then tempDoor = car:getPassengerDoor2(seat) end

				if tempDoor then
					if not lastgoodDoor or ZombRand(2) == 1 then
						lastgoodDoor = tempDoor
						--car.lol()
						local tempdistance = GetXYDistanceBetween(tempDoor, self.parent.player)
						lastgoodDoorDistance = tempdistance
					end
					if car:isSeatOccupied(seat) == false then doorseat = seat end
				end
				if self.MySeat == -1 and car:isSeatOccupied(seat) == false then
					self.MySeat = seat
				end
				if doorseat ~= -1 and self.MySeat ~= -1 then break end
			end

			if (self.MySeat ~= -1) then
				local doorsquare

				doorsquare = lastgoodDoor

				if (doorsquare ~= nil) then
					self.parent:StopWalk()
					local distance = GetXYDistanceBetween(self.parent.player, doorsquare)

					if (distance > 3) then
						ISTimedActionQueue.add(ISWalkToTimedAction:new(self.parent:Get(), doorsquare))
					else
						self.parent:StopWalk()
						ISTimedActionQueue.add(ISEnterVehicle:new(self.parent:Get(), self.FollowChar:getVehicle(), 1))
						if (self.MySeat ~= 1) then
							ISTimedActionQueue.add(ISSwitchVehicleSeat:new(self.parent:Get(),
								self.MySeat))
						end
					end
					--ISTimedActionQueue.add(ISEnterVehicle:new(self.parent:Get(), self.FollowChar:getVehicle(), doorseat))
					--
					-- local waittime = ZombRand(1, 3)
					-- self.parent:Wait(waittime)
				end
			end
			--elseif (self.FollowChar:getVehicle() ~= nil) and (self.parent:Get():getVehicle() ~= nil) then
			--ISTimedActionQueue.add(ISSwitchVehicleSeat:new(self.parent:Get(), self.MySeat))
		elseif (self.FollowChar:getVehicle() == nil) and (self.parent:Get():getVehicle() ~= nil) then
			self.MySeat = -1
			ISTimedActionQueue.add(ISExitVehicle:new(self.parent:Get()))
			self.parent:Wait(1)
		else
			--self.parent:Speak("ELSE")
		end
	end
	-- else
	-- 	--self.parent.player:Say("waiting for non-action "..tostring(self.parent.player:getCharacterActions())..","..tostring(self.parent.player:getModData().bWalking))
	-- end

	self.LastDistance = distance
end
