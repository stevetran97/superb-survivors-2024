require "04_Group.SuperSurvivorManager";

--- Cows: I'll regret working on this but I need the NPCs to stop shitting themselves when enemies are only at the edge of their attack range.
--- Cows: Also need Companion NPCs to actually FOLLOW over any other tasks at hand.

-- Bug: companions are pursing a target without they returning to the player when out of range
local isLocalLoggingEnabled = false;

function checkAiTaskIs(AiTmi, TaskName)
	return AiTmi:getCurrentTask() == TaskName
end

function checkAiTaskIsNot(TaskMangerIn, TaskName)
	return TaskMangerIn:getCurrentTask() ~= TaskName
end

function AiNPC_Job_Is(currentNPC, JobName)
	return currentNPC:getGroupRole() == JobName
end



function AIEssentialTasks(TaskMangerIn) 
	local currentNPC = TaskMangerIn.parent;

	-- -- Logging Block
	-- CreateLogLine("AIEssentialTasks", true, tostring(currentNPC:getName()) .. " has current task: " .. tostring(TaskMangerIn:getCurrentTask()));
	-- CreateLogLine("AIEssentialTasks", true, tostring(currentNPC:getName()) .. " has wait ticks: " .. tostring(currentNPC.WaitTicks));
	-- CreateLogLine("AIEssentialTasks", true, tostring(currentNPC:getName()) .. " has group role: " .. tostring(currentNPC:getGroupRole()));
	-- CreateLogLine("AIEssentialTasks", true, tostring(currentNPC:getName()) .. " task list start -------- ");
	-- for i, Task in pairs(TaskMangerIn.Tasks) do
	-- 	CreateLogLine("AIEssentialTasks", true, tostring(currentNPC:getName()) .. " has queued task: " .. tostring(Task.Name));
	-- end
	-- CreateLogLine("AIEssentialTasks", true, tostring(currentNPC:getName()) .. " task list end -------- ");
	-- local actionQueue = ISTimedActionQueue.getTimedActionQueue(npc)
	-- CreateLogLine("AIEssentialTasks", true, tostring(currentNPC:getName()) .. " has this action queue -------- " .. tostring(actionQueue));
	-- CreateLogLine("AIEssentialTasks", true, tostring(currentNPC:getName()) .. " has this AI MODE -------- " .. tostring(currentNPC:getAIMode()));
	-- -- Logging Block

	-- Variable Block
	local npcBravery = currentNPC:getBravePoints();
	local distance_AnyEnemy = currentNPC.LastEnemySeenDistance -- local distance_AnyEnemy = surveyRange;
	if not currentNPC.LastEnemySeenDistance and currentNPC.LastEnemySeen then
		distance_AnyEnemy = GetCheap3DDistanceBetween(currentNPC.LastEnemySeen, currentNPC:Get());
	end

	local distanceBetweenMainPlayer = currentNPC.distanceToPlayer0;
	if not currentNPC.distanceToPlayer0 then 
		distanceBetweenMainPlayer = GetXYDistanceBetween(getSpecificPlayer(0), currentNPC:Get());
	end

	local isEnemySurvivor = instanceof(currentNPC.LastEnemySeen, "IsoPlayer");
	local enemySurvivor = nil;
	if isEnemySurvivor then
		local id = currentNPC.LastEnemySeen:getModData().ID;
		enemySurvivor = SSM:Get(id);
	end
	-- 
	
	-- Force NPC to slowdown near player - Need this to run every time task tick runs
	currentNPC:NPC_EnforceWalkNearMainPlayer();

	-- Flee Task
	-- Injured and need to Heal
	if currentNPC:HasInjury() and 
		currentNPC.EnemiesOnMe > 0
	then
		if TaskMangerIn:getCurrentTask() ~= "Flee" then 
			currentNPC:Speak("Cover me! I'm hurt and I need to get away!");
			TaskMangerIn:AddToTop(FleeTask:new(currentNPC, true, startingDangerRange + 4));
		end
		currentNPC:setRunning(true)
		return false
	-- Cowardice - Bravery
	elseif
		(currentNPC:getDangerSeenCount() > npcBravery and currentNPC.EnemiesOnMe >= 2) -- 2 enemies in grabbing distance -- more the npcBravery # of zombies in fight radius 
	then
		CreateLogLine("SuperSurvivor", isFleeCallLogged, tostring(currentNPC:getName()) .. " needs to flee because they are afraid");
		if TaskMangerIn:getCurrentTask() ~= "Flee" then 
			currentNPC:Speak("This is too much! Let's get out of here!");
			TaskMangerIn:AddToTop(FleeTask:new(currentNPC, true, startingDangerRange));
		end
		currentNPC:setRunning(true)
		return false
	-- Has Gun and Needs to Kite
	elseif
		currentNPC:hasGun() and
		currentNPC:usingGun() and
		currentNPC.EnemiesOnMe >= 2 -- Let see how walking away from 2 to 1 zombie works - Batmane
	then
		if TaskMangerIn:getCurrentTask() ~= "Flee" then 
			currentNPC:Speak("Cover me! I need space to use my gun!");
			if currentNPC.EnemiesOnMe > 2 then -- This is not ideal, Ideally they should run if theres a tonne of enemies mildly close
				-- Run away
				TaskMangerIn:AddToTop(FleeTask:new(currentNPC, true, startingDangerRange));
			else
				-- Walk away
				TaskMangerIn:AddToTop(FleeTask:new(currentNPC, false, criticalDangerRange + 1));
			end
		end
		return false
	end
	if checkAiTaskIs(TaskMangerIn, "Flee") then return false end -- No further task if above task is in progress


	-- ----------------------------- --
	-- 		Surrender Task	
	-- ----------------------------- --
	-- Cows: I haven't tampered with this one, it does OK for the most part.
	-- Bug: If you shoot the gun and it has nothing in it, the NPC will still keep their hands up
	if getSpecificPlayer(0) and SSM:Get(0) then
		local facingResult = getSpecificPlayer(0):getDotWithForwardDirection(
			currentNPC.player:getX(),
			currentNPC.player:getY()
		);
		if TaskMangerIn:getCurrentTask() ~= "Surender"
				-- and TaskMangerIn:getCurrentTask() ~= "Flee"
				and TaskMangerIn:getCurrentTask() ~= "Flee From Spot"
				and TaskMangerIn:getCurrentTask() ~= "Clean Inventory"
				and SSM:Get(0):usingGun()
				and getSpecificPlayer(0):CanSee(currentNPC.player)
				and (not currentNPC:usingGun() 
					or (not currentNPC:RealCanSee(getSpecificPlayer(0)) and distanceBetweenMainPlayer <= 3))
				and getSpecificPlayer(0):isAiming()
				and IsoPlayer.getCoopPVP()
				and not currentNPC:isInGroup(getSpecificPlayer(0))
				and facingResult > 0.95
				and distanceBetweenMainPlayer < startingDangerRange
		then
			TaskMangerIn:clear()
			TaskMangerIn:AddToTop(SurenderTask:new(currentNPC, SSM:Get(0)))
			return false
		end
	end
	if checkAiTaskIs(TaskMangerIn, "Surender") then return false end -- No further task if above task is in progress

	--- ----------------------------- --
    -- Heal self if there are no dangers nearby
    -- ----------------------------- --
    if currentNPC:HasInjury() 
    then
		if TaskMangerIn:getCurrentTask() ~= "First Aide" then 
			currentNPC:Speak("Cover me! I'm hurt and I need to heal!");
			TaskMangerIn:AddToTop(FirstAideTask:new(currentNPC));
		end
		return false
    end
	if checkAiTaskIs(TaskMangerIn, "First Aide") then return false end -- No further task if above task is in progress

	-- ----------------------------- --
	-- 	Follow Task -- Passive Task
	-- ----------------------------- --
	-- This is a passive task structure. It will not interupt other tasks below it unless a specific condition is met
	-- needToFollow means - that so as long as the NPC has a follow task in the list. 
	-- If Task is not complete in the list and the follow condition triggers are met, this follow tasks suddenly gets prioritized.
	-- If the Follow task is not first and foremost, clear and then make it foremost
	-- Interupt other tasks if following is needed
	-- We expect to pass through this task when the passive trigger conditions arent met
	if currentNPC:needToFollow()
	then
		if TaskMangerIn:getCurrentTask() ~= "Follow" then
			currentNPC:Speak('Wait for me!')
			TaskMangerIn:clear();
			TaskMangerIn:AddToTop(FollowTask:new(currentNPC, getSpecificPlayer(0)));
		end
		return false
	end

	-- ----------------------------- --
	-- 	Reequip Gun Tasks -- Passive Task
	-- ----------------------------- --
	-- I dont know what this does. 
	-- It just rerequips gun if you run out of ammo for current gun and can equip the last one you had?
	-- Never tested it
    if currentNPC:getNeedAmmo() 
        and currentNPC:hasAmmoForPrevGun() 
    then
		currentNPC:Speak('Out of Ammo, Switching Guns!')
        currentNPC:setNeedAmmo(false);
        currentNPC:reEquipGun();
		-- return false -- Should I return here? - Lets just assume we dont return here because this task is part of the other task below
    end

	-- ----------------------------- --
    -- 	Equip Weapon if have and none equiped                --
    -- ----------------------------- --
    -- Has not weapon in hand
    if not currentNPC:hasWeapon() 
	-- and currentNPC:Get():getPrimaryHandItem() == nil
    then
		if TaskMangerIn:getCurrentTask() ~= "Equip Weapon" then
			currentNPC:Speak('Wheres my weapon?!')
			TaskMangerIn:AddToTop(EquipWeaponTask:new(currentNPC))
		end
		return false
    end
	if checkAiTaskIs(TaskMangerIn, "Equip Weapon") then return false end -- No further task if above task is in progress

    -- ----------- --
    -- Attack or Threaten
    -- ----------- --
	-- CreateLogLine('NPC Attack', true, tostring(currentNPC:getName()) .. " currentNPC:getDangerSeenCount() = " .. tostring(currentNPC:getDangerSeenCount()))
	-- CreateLogLine('NPC Attack', true, tostring(currentNPC:getName()) .. " currentNPC:isInSameRoom(currentNPC.LastEnemySeen) = " .. tostring(currentNPC:isInSameRoom(currentNPC.LastEnemySeen)))
	-- CreateLogLine('NPC Attack', true, tostring(currentNPC:getName()) .. " currentNPC.dangerSeenCount = " .. tostring(currentNPC.dangerSeenCount))
    -- Do I need to attack the enemy?
    if currentNPC:isInSameRoom(currentNPC.LastEnemySeen) and 
		currentNPC:getDangerSeenCount() > 0 -- Cows: npcs can only attack seen danger. 
    then
		if currentNPC.player:getModData().isRobber
			and not currentNPC.player:getModData().hitByCharacter
			and isEnemySurvivor
			and not enemySurvivor.player:getModData().dealBreaker
		then
			if checkAiTaskIsNot(TaskMangerIn, "Threaten") then 
				currentNPC:Speak("Hey You!");
				TaskMangerIn:AddToTop(ThreatenTask:new(currentNPC, enemySurvivor, "Scram!"));
			end
			return false
		else
			if checkAiTaskIsNot(TaskMangerIn, "Attack") then 
				currentNPC:Speak("Attacking!");
				TaskMangerIn:AddToTop(AttackTask:new(currentNPC));
			end
			return false
		end
    end
	if checkAiTaskIs(TaskMangerIn, "Attack") then return false end -- No further task if above task is in progress
	if checkAiTaskIs(TaskMangerIn, "Threaten") then return false end -- No further task if above task is in progress

	-- ------------ --
    -- Pursue
    -- ------------ --
	if 
		currentNPC.LastEnemySeen
		and distance_AnyEnemy < currentNPC:NPC_CheckPursueScore()
	then
		if checkAiTaskIsNot(TaskMangerIn, "Pursue") then 
			currentNPC:Speak("Pursuing the target!");
			TaskMangerIn:AddToTop(PursueTask:new(currentNPC, currentNPC.LastEnemySeen));
		end
		return false
	end
	if checkAiTaskIs(TaskMangerIn, "Pursue") then return false end -- No further task if above task is in progress

	-- Not sure what priority this task takes
	-- ----------------------------- --
    -- New: To attempt players that are NOT trying to encounter a fight,
    -- should be able to run away. maybe a dice roll for the future?
    -- ----------------------------- --
    -- if isEnemySurvivor
    --     and checkAiTaskIs(TaskMangerIn, "Threaten")
    --     and distance_AnyEnemy > 10
    -- then
    --     -- End
    --     TaskMangerIn:AddToTop(WanderTask:new(currentNPC))
    --     TaskMangerIn:AddToTop(AttemptEntryIntoBuildingTask:new(currentNPC, nil))
    --     TaskMangerIn:AddToTop(WanderTask:new(currentNPC))
    --     TaskMangerIn:AddToTop(FindBuildingTask:new(currentNPC))
    --     -- Start
    -- end


	-- CreateLogLine("AIEssentialTasks", true, tostring(currentNPC:getName()) .. " has current finished all essential tasks in this run: ");


	return true -- Is Finished
end



function AIMediumPriorityTasks(TaskMangerIn) 
	local currentNPC = TaskMangerIn.parent;

    -- ----------------------------- --
    -- 	Ready magazines in spare time      --
    -- ----------------------------- --
	-- Test new magazine loading
	if currentNPC:hasGun() then
		currentNPC:LoadBulletsSpareMag()
	end

	-- ------------ --
    -- Wander -- Passive Task
    -- ------------ --
	-- If you got nothing to do then just wander (non-companion) or follow (companions)
	if currentNPC:getCurrentTask() == "None" or not currentNPC:getCurrentTask()
	then
		-- Continue follow and do not perform other jobs
		if currentNPC:getGroupRole() == "Companion" and currentNPC:getCurrentTask() ~= "Follow" then 
			if TaskMangerIn:getCurrentTask() ~= "Follow" then
				TaskMangerIn:AddToTop(FollowTask:new(currentNPC, getSpecificPlayer(0)));
			end

		-- Wander if not companion
		else
			if SurvivorRoles[currentNPC:getGroupRole()] == nil then 
				if TaskMangerIn:getCurrentTask() ~= "Wander" then
					TaskMangerIn:AddToTop(WanderTask:new(TaskMangerIn));
				end

				-- currentNPC:NPCTask_DoWander();
			end
		end
	end
	-- 
	return true
end


function AILowPriorityTasks(TaskMangerIn) 
	-- ----------------------------- --
	-- Find food / drink - like task --
	-- ----------------------------- --
	local currentNPC = TaskMangerIn.parent;
	local npcIsInAction = currentNPC:isInAction();
	local npcIsInBase = currentNPC:isInBase();
	local npcGroup = currentNPC:getGroup();
	-- Manages AI getting water
	if SurvivorNeedsFoodWater -- Sandbox Setting
		and npcIsInAction == false
		and TaskMangerIn:getCurrentTask() ~= "Enter New Building"
		and TaskMangerIn:getCurrentTask() ~= "Eat Food"
		and TaskMangerIn:getCurrentTask() ~= "Find This"
		and ((currentNPC:isThirsty() 
				and npcIsInBase)
			or currentNPC:isVThirsty())
		and currentNPC:getDangerSeenCount() == 0
		and currentNPC:getNoWaterNearBy() == false
	then
		if npcGroup then
			local area = npcGroup:getGroupAreaCenterSquare("FoodStorageArea")
			if area then currentNPC:walkTo(area) end
			currentNPC:Speak("I'm going to get some water before I die of thirst.")
		end
		TaskMangerIn:AddToTop(FindThisTask:new(currentNPC, "Water", "Category", 1))
		return false
	end


	return true
end


---@param TaskMangerIn any
---@return any
function AIManager(TaskMangerIn)
	local currentNPC = TaskMangerIn.parent; -- replaces both "ASuperbSurvivor" and "NPC".
	-- CreateLogLine('Task Manager ', true, tostring(TaskMangerIn.parent:getName()) .. ' has current task of ' .. tostring(TaskMangerIn:getCurrentTask()))
	-- CreateLogLine('Task Manager ', true, tostring(TaskMangerIn.parent:getName()) .. ' has current task of ' .. tostring(#TaskMangerIn.Tasks))

	if TaskMangerIn == nil or currentNPC == nil or not currentNPC.player then
		return false;
	end

	-- Skip all ai processing when player is asleep or non existent. Obviously ai cant do anything
	if getSpecificPlayer(0) == nil 
		or getSpecificPlayer(0):isAsleep() 
	then 
		return false
	end

	local hasFinishEssentialTasks = AIEssentialTasks(TaskMangerIn)

	if not hasFinishEssentialTasks then return false end

	-- Every 4 seconds do medium essential tasks
	local hasFinishMediumPriorityTasks
	if currentNPC.Reducer % (4 * globalBaseUpdateDelayTicks) == 0 then 
		hasFinishMediumPriorityTasks = AIMediumPriorityTasks(TaskMangerIn)
	
	end
	if not hasFinishMediumPriorityTasks then return false end

	-- Every 6 Seconds do Low priority tasks
	local hasFinishLowPriorityTasks
	if currentNPC.Reducer % (6 * globalBaseUpdateDelayTicks) == 0 then
		hasFinishLowPriorityTasks = AILowPriorityTasks(TaskMangerIn)
	end
	if not hasFinishLowPriorityTasks then return false end
	
	-- Test Early Return
	-- Only run very 6 ish seconds and finished essential tasks
	if currentNPC.Reducer % (6 * globalBaseUpdateDelayTicks) == 0 then 
		CreateLogLine("AIEssentialTasks", true, tostring(currentNPC:getName()) .. " is now processing old routines.... ");

		-- Skip Task Management if Survivor needs to follow you rn or is in a vehicle
		-- if currentNPC:needToFollow()
		-- 	or currentNPC:Get():getVehicle() ~= nil
		-- then
		-- 	return false
		-- end -- if in vehicle skip AI -- or high priority follow

		local npcIsInAction = currentNPC:isInAction();
		local npcGroup = currentNPC:getGroup();
		local centerBaseSquare = nil;
		if npcGroup then
			centerBaseSquare = npcGroup:getBaseCenter();
		end
		local npcIsInBase = currentNPC:isInBase();

		local distanceBetweenMainPlayer = currentNPC.distanceToPlayer0
		if not currentNPC.distanceToPlayer0 then 
			distanceBetweenMainPlayer = GetXYDistanceBetween(getSpecificPlayer(0), currentNPC:Get());
		end


		local isEnemySurvivor = instanceof(currentNPC.LastEnemySeen, "IsoPlayer");
		--

		-- ---------------------------------------------------------- --
		-- ------------------- Basic Tasks---------------------------- --
		-- ---------------------------------------------------------- --

		if currentNPC:getAIMode() ~= "Stand Ground"  -- Not on stand ground
		then
			local SafeToGoOutAndWork = true
			local AutoWorkTaskTimeLimit = 300

			-- -------
			-- Guard
			-- -------
			-- Batmane - Duplicate Code?
			if AiNPC_Job_Is(currentNPC, "Guard") then
				-- if getGroupArea 'getGroupArea = does this area exist'
				if 
					npcIsInAction == false
					and not checkAiTaskIs(TaskMangerIn, "Find This")
					and not checkAiTaskIs(TaskMangerIn, "Eat Food")
					-- and not checkAiTaskIs(TaskMangerIn, "Follow")
				then
					if npcGroup:getGroupAreaCenterSquare("GuardArea") ~= nil and npcGroup:getGroupArea("GuardArea") then
						if GetXYDistanceBetween(npcGroup:getGroupAreaCenterSquare("GuardArea"), currentNPC:Get():getCurrentSquare()) > 10 then
							currentNPC:Speak("I will guard around this area")
							TaskMangerIn:clear();
							TaskMangerIn:AddToTop(
								GuardTask:new(currentNPC, GetRandomAreaSquare(npcGroup:getGroupArea("GuardArea")))
							);
						end
					end

					if GetXYDistanceBetween(npcGroup:getGroupAreaCenterSquare("GuardArea"), currentNPC:Get():getCurrentSquare()) <= 10 then
						currentNPC:Speak("I will watch over this area")
						if npcGroup:getGroupAreaCenterSquare("GuardArea") ~= nil and npcGroup:getGroupArea("GuardArea") then
							TaskMangerIn:AddToTop(GuardTask:new(currentNPC,
								GetRandomAreaSquare(npcGroup:getGroupArea("GuardArea"))))
						end
					end

					if npcGroup:getGroupAreaCenterSquare("GuardArea") == nil and centerBaseSquare ~= nil and not npcIsInBase then
						TaskMangerIn:AddToTop(WanderInBaseTask:new(currentNPC))
					elseif npcGroup:getGroupAreaCenterSquare("GuardArea") == nil and centerBaseSquare == nil and not npcIsInBase then
						currentNPC:Speak("Count on me to watch this area!")
						TaskMangerIn:AddToTop(GuardTask:new(currentNPC, npcGroup:getRandomBaseSquare()))
					end
				else
					if checkAiTaskIs(TaskMangerIn, "Flee") then currentNPC:NPC_ShouldRunOrWalk() end
				end
			end

			if currentNPC:getCurrentTask() == "None" and 
				npcIsInBase and 
				not npcIsInAction and 
				ZombRand(4) == 0 
			then
				-- if AiNPC_Job_Is(currentNPC, "Companion") then
				-- 	TaskMangerIn:AddToTop(FollowTask:new(currentNPC, getSpecificPlayer(0)));
				-- else
				if not SurvivorCanFindWork and AiNPC_Job_Is(currentNPC, "Doctor") then
					local randresult = ZombRand(10) + 1;
					--
					if (randresult == 1) then
						currentNPC:Speak(Get_SS_UIActionText("IGoRelax"))
						TaskMangerIn:AddToTop(WanderInBaseTask:new(currentNPC))
					else
						local medicalarea = npcGroup:getGroupArea("MedicalStorageArea");
						local gotoSquare;
						--
						if (medicalarea) and (medicalarea[1] ~= 0) then
							gotoSquare = GetCenterSquareFromArea(medicalarea[1],
								medicalarea[2], medicalarea[3], medicalarea[4], medicalarea[5]);
						end
						--
						if (not gotoSquare) then
							gotoSquare = centerBaseSquare;
						end
						--
						if (gotoSquare) then
							currentNPC:walkTo(gotoSquare);
						end
						TaskMangerIn:AddToTop(DoctorTask:new(currentNPC))
						return TaskMangerIn
					end
				elseif (not SurvivorCanFindWork) and (AiNPC_Job_Is(currentNPC, "Farmer")) then
					if (SurvivorCanFindWork) and (RainManager.isRaining() == false) then
						local randresult = ZombRand(10) + 1

						if (randresult == 1) then
							currentNPC:Speak(Get_SS_UIActionText("IGoRelax"))
							TaskMangerIn:AddToTop(WanderInBaseTask:new(currentNPC))
							TaskMangerIn:setTaskUpdateLimit(AutoWorkTaskTimeLimit)
						else
							local area = npcGroup:getGroupArea("FarmingArea")
							if (area) then
								currentNPC:Speak(Get_SS_UIActionText("IGoFarm"))
								TaskMangerIn:AddToTop(FarmingTask:new(currentNPC))
								TaskMangerIn:setTaskUpdateLimit(AutoWorkTaskTimeLimit)
							else
								CreateLogLine("AI-Manager", isLocalLoggingEnabled, "farming area was nil");
							end
						end
					end
				elseif (SurvivorCanFindWork)
					and not (AiNPC_Job_Is(currentNPC, "Guard"))
					and not (AiNPC_Job_Is(currentNPC, "Leader"))
					and not (AiNPC_Job_Is(currentNPC, "Doctor"))
					and not (AiNPC_Job_Is(currentNPC, "Farming"))
				then
					if (currentNPC:Get():getBodyDamage():getWetness() < 0.2) then
						if (SafeToGoOutAndWork) then
							TaskMangerIn:setTaskUpdateLimit(AutoWorkTaskTimeLimit)

							local forageSquare = npcGroup:getGroupAreaCenterSquare("ForageArea")
							local chopWoodSquare = npcGroup:getGroupAreaCenterSquare("ChopTreeArea")
							local farmingArea = npcGroup:getGroupArea("FarmingArea")
							local guardArea = npcGroup:getGroupArea("GuardArea")

							local jobScores = {}
							local job = "Relax"
							-- idle tasks
							jobScores["Relax"] = 0 + math.floor(currentNPC:Get():getStats():getBoredom() * 20.0)
							jobScores["Wash Self"] = 1

							-- maintenance
							jobScores["Clean Inventory"] = 2
							jobScores["Gather Wood"] = 2
							jobScores["Pile Corpses"] = 2

							-- skilled work
							jobScores["Chop Wood"] = 2 +
								math.min(currentNPC:Get():getPerkLevel(Perks.FromString("Axe")), 3)
							jobScores["Forage"] = 2 +
								math.min(currentNPC:Get():getPerkLevel(Perks.FromString("Foraging")), 3)

							-- deprioritize assigned tasks
							jobScores["Farming"] = 0 +
								math.min(currentNPC:Get():getPerkLevel(Perks.FromString("Farming")), 3)
							jobScores["Doctor"] = -2 +
								math.min(currentNPC:Get():getPerkLevel(Perks.FromString("Doctor")), 3) +
								math.min(currentNPC:Get():getPerkLevel(Perks.FromString("First Aid")), 3)
							jobScores["Guard"] = 2 +
								math.min(currentNPC:Get():getPerkLevel(Perks.FromString("Aiming")), 3)

							-- jobs requiring zoned areas
							if (forageSquare == nil) then jobScores["Forage"] = -10 end
							if (chopWoodSquare == nil) then jobScores["Chop Wood"] = -10 end
							if (farmingArea[1] == 0) then jobScores["Farming"] = -10 end
							if (guardArea[1] == 0) then jobScores["Guard"] = -10 end

							-- reduce scores for jobs already being worked on
							for key, value in pairs(jobScores) do
								if key == "Guard" then
									jobScores[key] = value - npcGroup:getTaskCount("Wander In Area")
								elseif key == "Doctor" then
									-- no point in more than one doctor at a time
									jobScores[key] = value - (npcGroup:getTaskCount(key) * 10)
								elseif key == "Farming" then
									-- no point in more than one farmer at a time
									jobScores[key] = value - (npcGroup:getTaskCount(key) * 10)
								elseif key == "Forage" then
									-- little point in more than one forager at a time
									jobScores[key] = value - (npcGroup:getTaskCount(key) * 2)
								else
									jobScores[key] = value - npcGroup:getTaskCount(key)
								end
							end

							-- rainy days
							if RainManager.isRaining() then
								jobScores["Wash Self"] = jobScores["Wash Self"] + 2 -- can wash in puddles
								jobScores["Farming"] = jobScores["Farming"] - 10 -- really no reason to do this
								jobScores["Gather Wood"] = jobScores["Gather Wood"] - 1
								jobScores["Pile Corpses"] = jobScores["Pile Corpses"] - 2
								jobScores["Chop Wood"] = jobScores["Chop Wood"] - 3
								jobScores["Forage"] = jobScores["Forage"] - 3
							end
							if currentNPC:Get():getBodyDamage():getWetness() > 0.5 then
								-- do indoor stuff to dry off
								jobScores["Relax"] = jobScores["Relax"] + 3
								jobScores["Clean Inventory"] = jobScores["Clean Inventory"] + 3
								jobScores["Wash Self"] = jobScores["Wash Self"] + 2
							end

							-- personal needs
							local filth = currentNPC:getFilth()
							if filth < 1 then
								jobScores["Wash Self"] = jobScores["Wash Self"] - 2
							elseif filth < 5 then
								jobScores["Wash Self"] = jobScores["Wash Self"] - 1
							elseif filth < 10 then
								jobScores["Wash Self"] = jobScores["Wash Self"] + 1
							elseif filth < 15 then
								jobScores["Wash Self"] = jobScores["Wash Self"] + 2
							else
								jobScores["Wash Self"] = jobScores["Wash Self"] + 3
							end

							-- randomize
							for key, value in pairs(jobScores) do
								jobScores[key] = ZombRand(0, value)
							end

							-- find the best task
							for key, value in pairs(jobScores) do
								if value >= jobScores[job] then job = key end
							end

							currentNPC:Get():getStats():setBoredom(currentNPC:Get():getStats():getBoredom() +
								(ZombRand(5) / 100.0))
							if (job == "Relax") then
								currentNPC:Speak(Get_SS_UIActionText("IGoRelax"))
								currentNPC:Get():getStats():setBoredom(0.0)
								TaskMangerIn:AddToTop(WanderInBaseTask:new(currentNPC))
							elseif (job == "Gather Wood") then
								currentNPC:Speak(Get_SS_UIActionText("IGoGetWood"))
								local dropSquare = centerBaseSquare
								local woodstoragearea = npcGroup:getGroupArea("WoodStorageArea")
								if (woodstoragearea[1] ~= 0) then
									dropSquare = GetCenterSquareFromArea(woodstoragearea[1],
										woodstoragearea[2], woodstoragearea[3], woodstoragearea[4], woodstoragearea[5])
								end
								TaskMangerIn:AddToTop(GatherWoodTask:new(currentNPC, dropSquare))
								TaskMangerIn:setTaskUpdateLimit(AutoWorkTaskTimeLimit)
							elseif (job == "Pile Corpses") then
								currentNPC:Speak(Get_SS_UIActionText("IGoPileCorpse"))
								local baseBounds = npcGroup:getBounds()
								local dropSquare = getCell():getGridSquare(baseBounds[1] - 5, baseBounds[3] - 5, 0)
								local storagearea = npcGroup:getGroupArea("CorpseStorageArea")
								if (storagearea[1] ~= 0) then
									dropSquare = GetCenterSquareFromArea(storagearea[1],
										storagearea[2], storagearea[3], storagearea[4], storagearea[5])
								end
								if (dropSquare) then
									TaskMangerIn:AddToTop(PileCorpsesTask:new(currentNPC, dropSquare))
									TaskMangerIn:setTaskUpdateLimit(AutoWorkTaskTimeLimit)
								end
							elseif (job == "Forage") then
								local dropSquare = centerBaseSquare
								local FoodStorageCenter = npcGroup:getGroupAreaCenterSquare("FoodStorageArea")
								if (FoodStorageCenter) then dropSquare = FoodStorageCenter end

								if (forageSquare ~= nil) then
									currentNPC:Speak(Get_SS_UIActionText("IGoForage"))
									currentNPC:walkTo(forageSquare)
									TaskMangerIn:AddToTop(SortLootTask:new(currentNPC, false))
									TaskMangerIn:AddToTop(ForageTask:new(currentNPC))
									TaskMangerIn:setTaskUpdateLimit(AutoWorkTaskTimeLimit)
								else
									CreateLogLine("AI-Manager", isLocalLoggingEnabled, "forage area was nil");
								end
							elseif (job == "Chop Wood") then
								if (chopWoodSquare) then
									currentNPC:Speak(Get_SS_UIActionText("IGoChopWood"))
									TaskMangerIn:AddToTop(ChopWoodTask:new(currentNPC))
									TaskMangerIn:setTaskUpdateLimit(AutoWorkTaskTimeLimit)
								else
									CreateLogLine("AI-Manager", isLocalLoggingEnabled, "chopWoodArea area was nil");
								end
							elseif (job == "Farming") then
								if (farmingArea) then
									currentNPC:Speak(Get_SS_UIActionText("IGoFarm"))
									TaskMangerIn:AddToTop(FarmingTask:new(currentNPC))
									TaskMangerIn:setTaskUpdateLimit(AutoWorkTaskTimeLimit)
								else
									CreateLogLine("AI-Manager", isLocalLoggingEnabled, "farmingArea area was nil");
								end
							elseif (job == "Guard") then
								if (guardArea) then
									currentNPC:Speak(Get_SS_UIActionText("IGoGuard"))
									TaskMangerIn:AddToTop(WanderInAreaTask:new(currentNPC, guardArea))
									TaskMangerIn:setTaskUpdateLimit(AutoWorkTaskTimeLimit)
								else
									CreateLogLine("AI-Manager", isLocalLoggingEnabled, "guardArea area was nil");
								end
							elseif (job == "Doctor") then
								local medicalarea = npcGroup:getGroupArea("MedicalStorageArea")

								local gotoSquare
								if (medicalarea) and (medicalarea[1] ~= 0) then
									gotoSquare = GetCenterSquareFromArea(
										medicalarea[1], medicalarea[2], medicalarea[3], medicalarea[4], medicalarea[5])
								end
								if (not gotoSquare) then gotoSquare = centerBaseSquare end

								if (gotoSquare) then currentNPC:walkTo(gotoSquare) end
								TaskMangerIn:AddToTop(DoctorTask:new(currentNPC))
								TaskMangerIn:setTaskUpdateLimit(AutoWorkTaskTimeLimit)
							elseif (job == "Clean Inventory") then
								currentNPC:Speak("Cleaning Inventory")
								local dropSquare = centerBaseSquare
								local ToolStorageCenter = npcGroup:getGroupAreaCenterSquare("ToolStorageArea")
								if (ToolStorageCenter) then dropSquare = ToolStorageCenter end
								TaskMangerIn:AddToTop(SortLootTask:new(currentNPC, false))
							elseif (job == "Wash Self") then
								currentNPC:Speak("Washing Self")
								TaskMangerIn:AddToTop(WashSelfTask:new(currentNPC))
							end
						else
							TaskMangerIn:AddToTop(WanderInBaseTask:new(currentNPC))
						end -- safeto go out end
					end -- allowed to go out work end
				end
			end

			-- Return to base task
			-- Oop, found this. I could use this for followers to get back to main player
			if currentNPC:getCurrentTask() == "None" and 
				npcIsInBase == false and 
				not npcIsInAction and 
				npcGroup ~= nil 
			then
				local baseSq = centerBaseSquare;
				--
				if (baseSq ~= nil) then
					currentNPC:Speak(Get_SS_UIActionText("IGoBackBase"))
					TaskMangerIn:AddToTop(ReturnToBaseTask:new(currentNPC))
				end
			end
		end

		-- ----------------------------------------------------------- --
		-- ------ END -------- Base Tasks ------- END ---------------- --
		-- ----------------------------------------------------------- --

		-- ----------------------------- --
		-- Cows: Begin Random Solo(?)
		-- ----------------------------- --
		-- If NPC is Starving or dehydrating, force leave group
		-- To do - Give player option to let this task happen or not too
		-- ----------------------------- --
		if (false) and (currentNPC:getAIMode() ~= "Random Solo") and ((currentNPC:isStarving()) or (currentNPC:isDyingOfThirst())) then
			currentNPC:setAIMode("Random Solo");

			-- leave group and look for food if starving
			if (currentNPC:getGroupID() ~= nil) then
				local group = SSGM:GetGroupById(currentNPC:getGroupID())
				group:removeMember(currentNPC:getID())
			end
			currentNPC:getTaskManager():clear()
			if (currentNPC:Get():getStats():getHunger() > 0.40) then currentNPC:Get():getStats():setHunger(0.40) end
			if (currentNPC:Get():getStats():getThirst() > 0.40) then currentNPC:Get():getStats():setThirst(0.40) end
			currentNPC:Speak(Get_SS_Dialogue("LeaveGroupHungry"))
		elseif (TaskMangerIn:getCurrentTask() ~= "Enter New Building")
			and (TaskMangerIn:getCurrentTask() ~= "Clean Inventory")
			and (npcIsInAction == false)
			and (TaskMangerIn:getCurrentTask() ~= "Eat Food")
			and (TaskMangerIn:getCurrentTask() ~= "Find This")
			and (TaskMangerIn:getCurrentTask() ~= "First Aide")
			and (TaskMangerIn:getCurrentTask() ~= "Listen")
			and (((currentNPC:isHungry())
					and (npcIsInBase))
				or currentNPC:isVHungry())
			and (currentNPC:getDangerSeenCount() == 0)
		then
			if (not currentNPC:hasFood()) and (currentNPC:getNoFoodNearBy() == false) and ((getSpecificPlayer(0) == nil) or (not getSpecificPlayer(0):isAsleep())) then
				if (npcGroup) then
					local area = npcGroup:getGroupAreaCenterSquare("FoodStorageArea")
					if (area) then
						currentNPC:walkTo(area)
					end
				end
				TaskMangerIn:AddToTop(FindThisTask:new(currentNPC, "Food", "Category", 1))
			elseif (currentNPC:hasFood()) then
				TaskMangerIn:AddToTop(EatFoodTask:new(currentNPC, currentNPC:getFood()))
			end
		end

		-- TODO test: maybe add 'if not in attack / pursue / threaten , then do ' along with the 'none tasks'
		if currentNPC:getAIMode() == "Random Solo"
			and TaskMangerIn:getCurrentTask() ~= "Listen"
			and TaskMangerIn:getCurrentTask() ~= "Take Gift"
		then -- solo random survivor AI flow	
			if (TaskMangerIn:getCurrentTask() == "None")
				and (currentNPC.TargetBuilding ~= nil)
				and (not currentNPC:getBuildingExplored(currentNPC.TargetBuilding))
				and (not currentNPC:isEnemyInRange(currentNPC.LastEnemySeen))
			then
				TaskMangerIn:AddToTop(AttemptEntryIntoBuildingTask:new(currentNPC, currentNPC.TargetBuilding))
			elseif (TaskMangerIn:getCurrentTask() == "None")
				and ((not isEnemySurvivor)
					or (not currentNPC:isEnemyInRange(currentNPC.LastEnemySeen)))
			then
				TaskMangerIn:AddToTop(FindUnlootedBuildingTask:new(currentNPC))
			end

			if currentNPC.TargetBuilding ~= nil or currentNPC:inUnLootedBuilding() then
				if currentNPC.TargetBuilding == nil then currentNPC.TargetBuilding = currentNPC:getBuilding() end
				if (not currentNPC:hasWeapon()) and (TaskMangerIn:getCurrentTask() ~= "Loot Category")
					and (currentNPC:getDangerSeenCount() <= 0)
					and (currentNPC:inUnLootedBuilding())
					and (currentNPC:isTargetBuildingClaimed(currentNPC.TargetBuilding) == false)
				then
					TaskMangerIn:AddToTop(LootCategoryTask:new(currentNPC, currentNPC.TargetBuilding, "Food", 2))
					TaskMangerIn:AddToTop(EquipWeaponTask:new(currentNPC))
					TaskMangerIn:AddToTop(LootCategoryTask:new(currentNPC, currentNPC.TargetBuilding, "Weapon", 2))
				elseif (currentNPC:hasRoomInBag())
					and (TaskMangerIn:getCurrentTask() ~= "Loot Category")
					and (currentNPC:getDangerSeenCount() <= 0) and (currentNPC:inUnLootedBuilding())
					and (currentNPC:isTargetBuildingClaimed(currentNPC.TargetBuilding) == false)
				then
					TaskMangerIn:AddToTop(LootCategoryTask:new(currentNPC, currentNPC.TargetBuilding, "Food", 1))
				end
			end
			if (CanNpcsCreateBase) and
				(npcIsInAction == false) and -- New. Hopefully to stop spam
				(currentNPC:getBaseBuilding() == nil) and
				(currentNPC:getBuilding()) and
				(TaskMangerIn:getCurrentTask() ~= "First Aide") and
				(TaskMangerIn:getCurrentTask() ~= "Attack") and
				(TaskMangerIn:getCurrentTask() ~= "Threaten") and  -- new
				(TaskMangerIn:getCurrentTask() ~= "Pursue") and    -- new
				(TaskMangerIn:getCurrentTask() ~= "Enter New Building") and -- new
				(TaskMangerIn:getCurrentTask() ~= "Barricade Building") and
				(currentNPC:hasWeapon()) and
				(currentNPC:getGroupRole() ~= "Companion") and  -- New
				(currentNPC:isInSameBuildingWithEnemyAlt() == false) and -- That way npc doesn't stop what they're doing moment they look away from a hostile
				(currentNPC:hasFood())
			then
				TaskMangerIn:clear()
				currentNPC:setBaseBuilding(currentNPC:getBuilding())
				TaskMangerIn:AddToTop(WanderInBuildingTask:new(currentNPC, currentNPC:getBuilding()))
				TaskMangerIn:AddToTop(LockDoorsTask:new(currentNPC, true))
				TaskMangerIn:AddToTop(BarricadeBuildingTask:new(currentNPC))
				currentNPC:Speak("This will be my base.")
				local GroupId = SSGM:GetGroupIdFromSquare(currentNPC:Get():getCurrentSquare())

				CreateLogLine("AI-Manager", isLocalLoggingEnabled, tostring(currentNPC:getName()) .. " is making a base");
				CreateLogLine("AI-Manager", isLocalLoggingEnabled, tostring(GroupId) .. " is the base id");

				if (GroupId == -1) then -- if the base this npc is gonna stay in is not declared as another base then they set it as thier base.
					local nGroup = SSGM:newGroup()
					nGroup:addMember(currentNPC, "Leader")
					local def = currentNPC:getBuilding():getDef()
					local bounds = { def:getX() - 1, (def:getX() + def:getW() + 1), def:getY() - 1,
						(def:getY() + def:getH() + 1), 0 }
					nGroup:setBounds(bounds)
				elseif ((SSM:Get(0) == nil) or (GroupId ~= SSM:Get(0):getGroupID())) then
					local OwnerGroup = SSGM:GetGroupById(GroupId)
					local LeaderID = OwnerGroup:getLeader()
					if (LeaderID ~= 0) then
						OwnerGroup:addMember(currentNPC, "Worker")
						currentNPC:Speak("Please let me stay here")
						local LeaderObj = SSM:Get(LeaderID)
						if (LeaderObj) then
							LeaderObj:Speak("Welcome to our Group")
						end
					end
				end
			end

			if ((CanNpcsCreateBase)
					and (currentNPC:isStarving())
					or (currentNPC:isDyingOfThirst())
				)
				and (currentNPC:getBaseBuilding() ~= nil)
			then -- leave group and look for food if starving
				-- random survivor in base is starving - reset so he goes back out looking for food and re base there
				currentNPC:setAIMode("Random Solo")
				if (currentNPC:getGroupID() ~= nil) then
					local group = SSGM:GetGroupById(currentNPC:getGroupID())
					group:removeMember(currentNPC:getID())
				end
				currentNPC:getTaskManager():clear()
				currentNPC:Speak(Get_SS_UIActionText("LeaveBCHungry"))
				CreateLogLine("AI-Manager", isLocalLoggingEnabled,
					tostring(currentNPC:getName()) .. ": clearing task manager because too hungry");
				currentNPC:resetAllTables()
				currentNPC:setBaseBuilding(nil)
				if (currentNPC:Get():getStats():getHunger() > 0.30) then currentNPC:Get():getStats():setHunger(0.30) end
				if (currentNPC:Get():getStats():getThirst() > 0.30) then currentNPC:Get():getStats():setThirst(0.30) end
			end
		end

		-- ----------------------------- --
		-- 			Listen to Task
		-- ----------------------------- --
		-- Batmane - I have never seen this run. No survivor has ever said hey you to me. Maybe this is the main player saying it?
		if (currentNPC:Get():getModData().InitGreeting ~= nil or currentNPC:getAIMode() == "Random Solo")
			and TaskMangerIn:getCurrentTask() ~= "Listen"
			and TaskMangerIn:getCurrentTask() ~= "Surender"
			and TaskMangerIn:getCurrentTask() ~= "Flee From Spot"
			and TaskMangerIn:getCurrentTask() ~= "Take Gift"
			and currentNPC.LastSurvivorSeen ~= nil
			and currentNPC:getSpokeTo(currentNPC.LastSurvivorSeen:getModData().ID) == false
			and GetXYDistanceBetween(currentNPC.LastSurvivorSeen, currentNPC:Get()) < 8
			and currentNPC:getDangerSeenCount() == 0
			and TaskMangerIn:getCurrentTask() ~= "First Aide"
			and currentNPC:Get():CanSee(currentNPC.LastSurvivorSeen)
		then
			currentNPC:Speak(Get_SS_Dialogue("HeyYou"))
			currentNPC:SpokeTo(currentNPC.LastSurvivorSeen:getModData().ID)
			TaskMangerIn:AddToTop(ListenTask:new(currentNPC, currentNPC.LastSurvivorSeen, true))
		end

	end

	return TaskMangerIn
end
