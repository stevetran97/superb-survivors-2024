require "04_Group.SuperSurvivorManager";

-- Testing
require "TimedActions/ISBaseTimedAction"
ISSitOnGround = ISBaseTimedAction:derive("ISSitOnGround")
-- Testing

FollowTask = {}
FollowTask.__index = FollowTask

local isLocalLoggingEnabled = false;

-- This strategy wont work because what if you only get some of your group to follow
function createSingleFileLine(superSurvivor, leaderSS) 
	CreateLogLine('createSingleFileLine', isLocalLoggingEnabled, tostring(superSurvivor:getName()) .. ' creating congo line...')

	local attempts = 0
	while attempts < Limit_Npcs_Global + 10 do 
		if attempts > Limit_Npcs_Global + 10 then return end
		-- 
		local SSFollowing = SSM:Get(leaderSS.player:getModData().FollowedByCharId)
		if not SSFollowing or 
			SSFollowing.player:getModData().ID == superSurvivor.player:getModData().ID or -- Following Char is themselves
			SSFollowing.player:getModData().ID == 0 -- Following Char is player
		then 
			superSurvivor.player:getModData().FollowCharId = leaderSS.player:getModData().ID -- leaderId 
			leaderSS.player:getModData().FollowedByCharId = superSurvivor.player:getModData().ID
			superSurvivor:Speak('I\'m with ' .. tostring(leaderSS:getName()) .. '!' )
			return leaderSS:Get()
		else
			CreateLogLine('createSingleFileLine', isLocalLoggingEnabled, tostring(superSurvivor:getName()) .. ' Recursing deeper on ...' .. tostring(SSFollowing:getName()))

			attempts = attempts + 1
			return createSingleFileLine(superSurvivor, SSFollowing)
		end
		-- 
	end
	CreateLogLine('Error', true, tostring(superSurvivor:getName()) .. ' Failed to generate single file line')
end

function getFollowChar(superSurvivor, FollowMeplayer) 
	if not FollowMeplayer then
		if superSurvivor.player:getModData().FollowCharID then
			local SS = SSM:Get(superSurvivor.player:getModData().FollowCharID)
			if SS then
				return SS:Get()
			end
		end
	else
		superSurvivor.player:getModData().FollowCharID = FollowMeplayer:getModData().ID -- save last follow obj id to mod data so can be reused on load
		
		return FollowMeplayer -- type IsoPlayer
	end
end

-- superSurvivor - current Survivor
-- FollowMePlayer - Guessing this is just the main player?
function FollowTask:new(superSurvivor, FollowMeplayer, followMode)
	CreateLogLine("FollowTask", isLocalLoggingEnabled, "function: Follow Task:new() called");

	local o = {}
	setmetatable(o, self)
	self.__index = self

	local FollowChar = getFollowChar(superSurvivor, FollowMeplayer)
	local FollowSS = SSM:Get(FollowChar:getModData().ID)
	local group = FollowSS:getGroup()

	-- Reset follow orders
	superSurvivor.player:getModData().FollowCharId = nil 
	superSurvivor.player:getModData().FollowedByCharId = nil

	-- CreateLogLine('createSingleFileLine', true, tostring(superSurvivor:getName()) .. ' reset followed by...' .. tostring(superSurvivor.player:getModData().FollowCharId))
	-- CreateLogLine('createSingleFileLine', true, tostring(superSurvivor:getName()) .. ' reset followed by...' .. tostring(superSurvivor.player:getModData().FollowedByCharId))

	if followMode == SINGLEFILELINE then 
		if FollowSS then 
			o.FollowChar = createSingleFileLine(superSurvivor, FollowSS)
		else 
			CreateLogLine('Error', true, tostring(superSurvivor:getName()) ..  'cannot create congo line due to nonexisting FollowSS')
			superSurvivor:Speak('I\'m with ' .. tostring(FollowSS:getName()) .. '!' )
			o.FollowChar = FollowChar
		end
	else 
		-- No group case
		o.FollowChar = FollowChar
	end

	-- o.InBaseAtStart = superSurvivor:isInBase() -- Phase out 
	o.parent = superSurvivor
	o.Name = "Follow"
	-- o.OnGoing = true // Never used - Why is this here
	-- o.LastDistance = 0 // Never used - Why is this even here
	o.Complete = false
	o.MySeat = -1
	o.MyDoor = -1
	-- This is literally always 0 wherever it is used
	o.FollowDistanceOffset = 0
	if group then
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
	if not self.FollowChar then
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
	if not self:isValid() then return false end

	local distance = GetXYDistanceBetween(self.parent.player, self.FollowChar)

	self.parent:setSneaking(self.FollowChar:isSneaking()) -- sneaking if person you follow is

	-- CreateLogLine("FollowTaskSit", true, "self.FollowChar = " .. tostring(self.FollowChar));

	-- WIP Sitting when players sit
	-- if self.FollowChar:isSitOnGround() then 
	-- 	CreateLogLine("FollowTaskSit", true, "Follow Char is SITTING on ground");
	-- 	self.parent:setSitOnGround(true) 

	-- 	-- Need them to actually animate		
	-- 	ISTimedActionQueue.add(ISSitOnGround:new(self.parent.player)) -- Cant figure this out - Batmane - Line isnt working

	-- 	return
	-- else
	-- 	CreateLogLine("FollowTaskSit", true, "Follow Char STANDING");
	-- 	self.parent:setSitOnGround(false)
	-- 	-- ISTimedActionQueue.clear(self.parent.player)
	-- end
	-- 

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


	if distance > (GFollowDistance + self.FollowDistanceOffset + 7)
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

		return
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
		end
		CreateLogLine("FollowTask", isLocalLoggingEnabled, "no rope square");
	end
	-- Rope Climbing Logic End
	-- General Path finding start
	if ropeSquare then return end
	-- Handle Getting in Players car if player is in a care
	if self.FollowChar:getVehicle() and not self.parent:Get():getVehicle() then
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

		if self.MySeat ~= -1 then
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

		return
		--elseif (self.FollowChar:getVehicle() ~= nil) and (self.parent:Get():getVehicle() ~= nil) then
		--ISTimedActionQueue.add(ISSwitchVehicleSeat:new(self.parent:Get(), self.MySeat))
	-- Handle getting out of car when player is not in car
	elseif not self.FollowChar:getVehicle() and self.parent:Get():getVehicle() then
		self.MySeat = -1
		ISTimedActionQueue.add(ISExitVehicle:new(self.parent:Get()))
		self.parent:Wait(1)

		return
	end

	if distance > (GFollowDistance + self.FollowDistanceOffset) 
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
	end
	-- else
	-- 	--self.parent.player:Say("waiting for non-action "..tostring(self.parent.player:getCharacterActions())..","..tostring(self.parent.player:getModData().bWalking))
	-- end

	-- self.LastDistance = distance
end
