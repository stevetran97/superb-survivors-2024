local function spawnNpcs(mySS, spawnSquare)
    local hoursSurvived = math.floor(getGameTime():getWorldAgeHours());
    local FinalChanceToBeHostile = HostileSpawnRateBase + math.floor(hoursSurvived / 48);

    if (FinalChanceToBeHostile > HostileSpawnRateMax)
        and (HostileSpawnRateBase < HostileSpawnRateMax)
    then
        FinalChanceToBeHostile = HostileSpawnRateMax;
    end

    -- WIP - Cows: Need to rework the spawning functions and logic...
    -- TODO: Capped the number of groups, now to cap the number of survivors and clean up dead ones.
    if not spawnSquare then return end
    local isGroupHostile = false;
    local npcSurvivorGroup;
    local actualGroupsLimit = Limit_Npc_Groups + 1; -- Cows: +1 because the player group was is part of the Group Count total... -- Batmane based on this I can assume that group count should never exceed the sandbox setting
    local GroupSize = ZombRand(1, Max_Group_Size);
    -- Cows: Spawn a new group if possible.
    if SSGM.GroupCount < actualGroupsLimit then
    -- if #SSGM.Groups < actualGroupsLimit then
        CreateLogLine("Spawn Survivor", true, " Under Group Limit. new group made - Survivor");
        npcSurvivorGroup = SSGM:newGroup();
    else
        local rng = ZombRand(1, actualGroupsLimit);
        npcSurvivorGroup = SSGM:GetGroupById(rng);
        CreateLogLine("Spawn Survivor", true, " Group limit exceeded. Adding Survivor to group " .. tostring(rng));
    end

    if FinalChanceToBeHostile > ZombRand(0, 100) then
        isGroupHostile = true;
    end

    for i = 1, GroupSize do
        local npcSurvivor = SuperSurvivorSpawnNpcAtSquare(spawnSquare);
        CreateLogLine("SuperSurvivorsRandomSpawn", isLocalFunctionLoggingEnabled, "Spawning npcSurvivor" .. tostring(npcSurvivor));

        if (npcSurvivor) then
            local name = npcSurvivor:getName();
            npcSurvivor:setHostile(isGroupHostile);

            local isPlayerSurvivorGroup = SuperSurvivorGroup:isMember(mySS);

            if (i == 1 and not isPlayerSurvivorGroup) then
                npcSurvivorGroup:addMember(npcSurvivor, "Leader"); -- Cows: funny enough the leader still isn't set to the group with this role assignment...
            else
                -- npcSurvivorGroup:addMember(npcSurvivor, "Guard"); -- Cows: This... needs to be reworked because npcs would spawn in and do NOTHING.
                npcSurvivorGroup:addMember(npcSurvivor, "Follower"); -- Cows: I can't set "follow" nor "companion" because these roles defaults to following the player...
                npcSurvivor:NPCTask_DoWander();
            end

            npcSurvivor.player:getModData().isRobber = false;
            -- npcSurvivor:setName("Survivor " .. name); -- Name only
            npcSurvivor:setName(name);
            CreateLogLine("Spawn Survivor", true, " Created New Survivor with the name " .. tostring(npcSurvivor:getName()) .. ' with an id of ' .. tostring(npcSurvivor:getID()) .. ' inside of group ' .. tostring(npcSurvivorGroup:getID()));

            Equip_SS_RandomNpc(npcSurvivor, false);
            GetRandomSurvivorSuit(npcSurvivor) -- WIP: Cows - Consider creating a preset outfit for raiders?
        end
    end
end

local function spawnRaiders(mySS, spawnSquare)
    local isLocalFunctionLoggingEnabled = false;
    -- WIP - Cows: Need to rework the spawning functions and logic...
    -- TODO: Capped the number of groups, now to cap the number of survivors and clean up dead ones.
    if (spawnSquare ~= nil) then
        local raiderGroup;
        local actualGroupsLimit = Limit_Npc_Groups + 1;
        -- Cows: Spawn a new group if possible.

        if (SSGM.GroupCount < actualGroupsLimit) then
        -- if #SSGM.Groups < actualGroupsLimit then
            CreateLogLine("Spawn Survivor", true, " Under Group Limit. new group made");
            raiderGroup = SSGM:newGroup();
        else
            local rng = ZombRand(1, actualGroupsLimit);
            raiderGroup = SSGM:GetGroupById(rng);
            CreateLogLine("Spawn Survivor", true, " Group limit exceeded. Adding survivor to group " .. tostring(rng));
        end

        local GroupSize = ZombRand(1, Max_Group_Size);
        local nearestRaiderDistance = NpcSpawnDistance;
        if (nearestRaiderDistance == nil) then nearestRaiderDistance = 30 end;

        for i = 1, GroupSize do
            local raider = SuperSurvivorSpawnNpcAtSquare(spawnSquare);
            CreateLogLine("SuperSurvivorsRandomSpawn", isLocalFunctionLoggingEnabled, "Spawning raider" .. tostring(raider));


            if (raider) then
                local name = raider:getName();

                if (i == 1) then
                    raiderGroup:addMember(raider, "Leader"); -- Cows: funny enough the leader still isn't set to the group with this role assignment...
                else
                    -- raiderGroup:addMember(raider, "Guard"); -- Cows: This... needs to be reworked because npcs would spawn in and do NOTHING.
                    raiderGroup:addMember(raider, "Follower");
                    raider:NPCTask_DoWander();
                end
                raider:setHostile(true);
                raider.player:getModData().isRobber = true;
                -- raider:setName("Raider " .. name);
                raider:setName(name); -- name only
				CreateLogLine("Spawn Survivor", true, " Created New Raider with the name " .. tostring(raider:getName()) .. ' with an id of ' .. tostring(raider:getID()) .. ' inside of group ' .. tostring(raiderGroup:getID()));

                raider:getTaskManager():AddToTop(PursueTask:new(raider, mySS:Get()));

                Equip_SS_RandomNpc(raider, true);

                local number = ZombRand(1, 3);
                -- Batmane TODO: Rework banditry to include more outfits or include survivor outfits
                SetRandomSurvivorSuit(raider, "Rare", "Bandit" .. tostring(number));
                local currentRaiderDistanceFromPlayer = GetDistanceBetween(raider, mySS);

                if (nearestRaiderDistance > currentRaiderDistanceFromPlayer) then
                    nearestRaiderDistance = currentRaiderDistanceFromPlayer;
                end
            end
        end

        if (getSpecificPlayer(0):isAsleep() and nearestRaiderDistance < 15) then
            getSpecificPlayer(0):Say(Get_SS_Dialogue("IGotABadFeeling"));
            getSpecificPlayer(0):forceAwake();
        else
            getSpecificPlayer(0):Say(Get_SS_Dialogue("WhatWasThatSound"));
        end
    end
end

--- WIP - Cows: Need to rework the spawning functions and logic...
--- SuperSurvivorsNewSurvivorManager() is called once every in-game hour and uses NpcSpawnChance.
---@return any
function SuperSurvivorsRandomSpawn()
    local isLocalFunctionLoggingEnabled = false;
    -- CreateLogLine("SuperSurvivorsRandomSpawn", isLocalFunctionLoggingEnabled, "function: SuperSurvivorsRandomSpawn() called");
    CreateLogLine("SuperSurvivorsRandomSpawn", true, "Start Spawning Survivors");

    local mySS = SSM:Get(0);
    if not mySS then return end -- inhibit spawn while the main player is dead.
    local hisGroup = SSGM:initPlayer0Group()
    -- local hisGroup = mySS:getGroup();
    -- if not hisGroup then
    --     hisGroup = SSGM:newGroupWithID(0);
    --     hisGroup:addMember(SSM:Get(0), "Leader");
    -- end

    -- if hisGroup:getID() ~= 0 then 
    --     hisGroup = SSGM:GetGroupById(0);
    --     if hisGroup then 
    --         hisGroup = SSGM:newGroupWithID(0);
    --     end
    --     hisGroup:addMember(SSM:Get(0), "Leader");
    -- end

    if getSpecificPlayer(0) == nil 
        or hisGroup == nil 
    then
        return false;
    end

    -- Cows: ... this might be problematic... I'm guessing this means if the bounds exist due to a group's base area, it won't spawn npcs near the player...
    local center = Get_SS_PlayerGroupBoundsCenter(hisGroup);
    local spawnSquare = Set_SS_SpawnSquare(hisGroup, center);

    -- local globalAliveNpcs = Get_SS_Alive_Count();
    -- local activeNpcs = Get_SS_Active_Count()
    local globalAliveNpcs = SSM.aliveNpcs
    local activeNpcs = SSM.activeNpcs
    -- CreateLogLine("SuperSurvivorsRandomSpawn", true, "activeNpcs = " .. tostring(activeNpcs));

    local spawnChanceVal = NpcSpawnChance;

    local hours = math.floor(getGameTime():getWorldAgeHours());
    local RaidersStartTimePassed = (hours >= RaidersStartAfterHours);
    
    -- Cows: Spawn up to this many npc groups.
    for i = 1, NpcGroupsSpawnsSize do
        -- Cows: Spawn if spawnChanceVal is greater than the random roll between 0 and 100, and activeNPCs are less than the limit.
        local isSpawning = spawnChanceVal > ZombRand(0, 100) 
            and activeNpcs < Limit_Npcs_Active
            and globalAliveNpcs < Limit_Npcs_Global

        local rngRaiderSpawnCheck = (RaidersSpawnChance > ZombRand(0, 100));
        local isSpawningRaiders = (rngRaiderSpawnCheck and RaidersStartTimePassed);

        if isSpawning then
            if isSpawningRaiders then
                CreateLogLine("SuperSurvivorsRandomSpawn", true, "spawn raiders");
                spawnRaiders(mySS, spawnSquare);
            else
                CreateLogLine("SuperSurvivorsRandomSpawn", true, "spawn Survivor");
                spawnNpcs(mySS, spawnSquare);
            end
        end
    end
end

Events.EveryHours.Add(SuperSurvivorsRandomSpawn);
-- Batmane - Delete this if no issues with the refresh function not running
-- Events.EveryHours.Add(Refresh_SS_NpcStatus);
