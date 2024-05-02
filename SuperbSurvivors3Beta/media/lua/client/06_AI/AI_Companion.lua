-- --------------------------------------- --
-- Companion follower related code         --
-- --------------------------------------- --
-- -Cows: to my knowledge, "Companion" role is exclusive to the player group...
-- -@param TaskMangerIn any
-- function AI_Companion(TaskMangerIn)
--     local currentNPC = TaskMangerIn.parent; -- replaces both "ASuperbSurvivor" and "NPC".

--     -- Cows: No clue what the deal is here...
--     -- Batmane: Forces NPC to follow player if they have a follow order by 
--     -- blinding them to the last enemy they saw, 
--     -- clearing their tasks, 
--     -- and then ordering them to follow
--     -- Batmane: This gets them killed sometimes because they dont engage while following. You need to like increase the follow radius so they can defend themselves
--     -- Batmane update: this entire function geets skipped by AI manager if needToFollow is true very high up
--     if currentNPC:needToFollow() then
--         currentNPC:Speak('Wait for me!')
--         currentNPC.LastEnemySeen = nil;
--         TaskMangerIn:clear();
--         TaskMangerIn:AddToTop(FollowTask:new(currentNPC, getSpecificPlayer(0)));
--         return -- Batmane - Return to prevent other tasks below from interupting need To Follow. Tasks below will add interupting tasks and neutralize the clear that we just called
--     end



--     local npcBravery = currentNPC:getBravePoints();
--     local npcWeapon = currentNPC.player:getPrimaryHandItem();
--     --
--     local followAttackRange = GFollowDistance + currentNPC:getAttackRange();
--     --
--     local distanceBetweenEnemyAndFollowTarget = 10;
--     local distance_AnyEnemy = surveyRange;
--     -- Cows: Added a check... otherwise distance_AnyEnemy is always 1 or nil.

--     local isEnemySurvivor = instanceof(currentNPC.LastEnemySeen, "IsoPlayer");
--     local enemySurvivor = nil;

--     if isEnemySurvivor then
--         local id = currentNPC.LastEnemySeen:getModData().ID;
--         enemySurvivor = SSM:Get(id);
--     end

--     if currentNPC.LastEnemySeen ~= nil then
--         distance_AnyEnemy = GetCheap3DDistanceBetween(currentNPC.LastEnemySeen, currentNPC:Get());
--         distanceBetweenEnemyAndFollowTarget = GetCheap3DDistanceBetween(currentNPC.LastEnemySeen, currentNPC:getFollowChar())
--     end


--     -- Batmane: The above function does the exact same thing as this one but just constantly and not based on distance... Disabled by Batmane
--     -- This function also breaks the code slightly because now the npc can never leave the radius to attack any zombies. 
--     -- If radius is like 5, theyll be stuck at 5 and never purse or attack anyone
--     -- We need to let the rest of the function finish so that they can still fight while following.
--     -- Cows: Updated the distance code... so companions should NEVER leave the player's side.
--     -- Cows: Cut from SuperSurvivor:NPC _FleeWhileReadyingGun(), thsi should prevent companions from moving beyond GFollowDistance...
--     -- local distanceFromMainPlayer = GetXYDistanceBetween(getSpecificPlayer(0), currentNPC.player);
--     -- if (distanceFromMainPlayer > (GFollowDistance + 10)) then
--     --     currentNPC:getTaskManager():clear();
--     --     currentNPC:getTaskManager():AddToTop(FollowTask:new(currentNPC, getSpecificPlayer(0)));
--     --     return TaskMangerIn; -- Cows: Stops further processing...
--     -- end
--     -- 

--     -- ------------ --
--     -- Pursue
--     -- ------------ --
--     -- Do I need to pursue the enemy?
--     if checkAiTaskIsNot(TaskMangerIn, "First Aide")
--         and checkAiTaskIsNot(TaskMangerIn, "Pursue")
--         and checkAiTaskIsNot(TaskMangerIn, "Attack")
--         and checkAiTaskIsNot(TaskMangerIn, "Flee")
--         and currentNPC.LastEnemySeen
--         and distance_AnyEnemy < currentNPC:NPC_CheckPursueScore()
--     then
--         -- if isEnemySurvivor or instanceof(currentNPC.LastEnemySeen, "IsoZombie") then -- Pointless because lastEnemySeen is ALWAYS a isoplayer or zombie
--         TaskMangerIn:AddToTop(PursueTask:new(currentNPC, currentNPC.LastEnemySeen));
--         -- end
--     end

--     -- ----------- --
--     -- Attack
--     -- ----------- --
--     -- Do I need to attack the enemy?
--     if checkAiTaskIsNot(TaskMangerIn, "Attack")
--         and checkAiTaskIsNot(TaskMangerIn, "Threaten")
--         and checkAiTaskIsNot(TaskMangerIn, "First Aide")
--         and checkAiTaskIsNot(TaskMangerIn, "Flee")
--         and currentNPC:isInSameRoom(currentNPC.LastEnemySeen)
--         and currentNPC:getDangerSeenCount() > 0  -- Cows: npcs can only attack seen danger. 
--         -- and distanceBetweenEnemyAndFollowTarget < followAttackRange -- Cows: npcs only engages enemies while they're within the followAttackRange -- Batmane Simplify
--     then
--         if currentNPC.player
--             and currentNPC.player:getModData().isRobber
--             and not currentNPC.player:getModData().hitByCharacter
--             and isEnemySurvivor
--             and not enemySurvivor.player:getModData().dealBreaker
--         then
--             TaskMangerIn:AddToTop(ThreatenTask:new(currentNPC, enemySurvivor, "Scram!"));
--         else
--             TaskMangerIn:AddToTop(AttackTask:new(currentNPC));
--         end
--     end

--     -- --------------------------------- --
--     -- 	Reload Gun
--     -- --------------------------------- --
--     -- Do I need to switch to a side arm/other gun
--     -- The only check that prevents this from causing the npc from equiping a gun is that the last gun used is nil
--     if currentNPC:getNeedAmmo() 
--         and currentNPC:hasAmmoForPrevGun() 
--     then
--         currentNPC:setNeedAmmo(false);
--         currentNPC:reEquipGun();
--     end

--     -- --------------------------------- --
--     -- 	Ready Weapon
--     -- --------------------------------- --
--     -- Do I need to ready my weapon?
--     -- if (currentNPC:needToReload()
--     --         or currentNPC:needToReadyGun(npcWeapon))
--     --     and (currentNPC:hasAmmoForPrevGun()
--     --         or IsInfiniteAmmoEnabled)
--     --     and currentNPC:usingGun() -- removed and (currentNPC:getNeedAmmo() condition -
--     -- then
--     --     currentNPC:ReadyGun(npcWeapon);
--     -- end

--     -- ----------------------------- --
--     -- 	Equip Weapon                 --
--     -- ----------------------------- --
--     -- Do I need to equip my weapon?
--     if currentNPC:hasWeapon() 
--         and currentNPC:Get():getPrimaryHandItem() == nil
--         and TaskMangerIn:getCurrentTask() ~= "Equip Weapon" 
--     then
--         TaskMangerIn:AddToTop(EquipWeaponTask:new(currentNPC))
--     end

--     -- ----------------------------- --
--     -- 	Handle Guns                 --
--     -- ----------------------------- --
--     if currentNPC:NPC_CheckIfCanReadyGun()
--     then
--         currentNPC:ReadyGun(npcWeapon);
--     end


--     -- This is now a common util used between non companion and companion ais
--     -- ----------------------------- --
--     -- 	Flee
--     -- ----------------------------- --
--     -- Cows: Conditions for fleeing and healing...
--     if TaskMangerIn:getCurrentTask() ~= "Flee" then
--         -- Cowardice
--         if
--             currentNPC:getDangerSeenCount() > npcBravery -- more the npcBravery # of zombies in fight radius
--             -- and currentNPC:hasWeapon() - Batmane - Doesnt matter if they have weapon or not - for cowardice
--             -- and not currentNPC:usingGun() -- Melee - Doesnt matter if they are using melee
--             and currentNPC.EnemiesOnMe > 2 -- 2 enemies in grabbing distance
--         then
-- 		    CreateLogLine("SuperSurvivor", isFleeCallLogged, tostring(currentNPC:getName()) .. " needs to flee because they are afraid");
--             currentNPC:Speak("This is too much! Let's get out of here!");
--             TaskMangerIn:AddToTop(FleeTask:new(currentNPC, true, 15));
--         -- Injured and need to Heal
--         elseif currentNPC:HasInjury() and currentNPC:getDangerSeenCount() > 0
--         then
--             CreateLogLine("SuperSurvivor", isFleeCallLogged, tostring(currentNPC:getName()) .. " needs to flee in order to heal");
--             currentNPC:Speak("Cover me! I'm hurt and I need to heal!");
--             TaskMangerIn:AddToTop(FleeTask:new(currentNPC, true, 8));
--         end
--     end
--     --- ----------------------------- --
--     -- Heal self if there are no dangers nearby
--     -- ----------------------------- --
--     if currentNPC:HasInjury() 
--         and currentNPC.EnemiesOnMe <= 0
--         and TaskMangerIn:getCurrentTask() ~= "First Aide"
--     then
--         TaskMangerIn:AddToTop(FirstAideTask:new(currentNPC));
--     end
-- end
