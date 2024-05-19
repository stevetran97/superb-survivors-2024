local isLocalLoggingEnabled = false;

-- WIP - Cows: This was made so the 4 arrow keys can be used to call the assigned orders in SuperSurvivorKeyBindAction() ...
local function superSurvivorsHotKeyOrder(index)
    CreateLogLine('Orders', isLocalLoggingEnabled, " Giving order of index " .. tostring(index))

    local order, isListening;
    if (index <= #Orders) then
        order = Orders[index];
        isListening = false;
    else --single
        order = Orders[(index - #Orders)];
        isListening = true;
    end


    local myGroup = SSM:Get(0):getGroup();
    CreateLogLine('Orders', isLocalLoggingEnabled, " Player group = " .. tostring(myGroup))

    if (myGroup) then
        local myMembers = myGroup:getMembersInRange(SSM:Get(0):Get(), 25, isListening);
        for i = 1, #myMembers do
            SurvivorOrder(nil, myMembers[i].player, order, nil)
        end
    end
end

-- Batmane - Apr 24 - This was rewritten to be more efficient using a hash table

allowedAboveNPCLimit = 10
-- WIP - Cows: Renamed from "supersurvivortemp()" to "SuperSurvivorKeyBindAction()"
function SuperSurvivorKeyBindAction(keyNum)
    local isLocalFunctionLoggingEnabled = false
    CreateLogLine("SuperSurvivorsHotKeys", isLocalFunctionLoggingEnabled, "function: SuperSurvivorKeyBindAction called")

    local playerSurvivor = getSpecificPlayer(0)
    if not playerSurvivor or not playerSurvivor:isAlive() then return end

    local keyActions = {
        [156] = function() -- the NumPad enter key
            local activeNpcs = Get_SS_Alive_Count()
            if activeNpcs >= Limit_Npcs_Spawn then
                playerSurvivor:Say("Active NPCs limit reached, no spawn.")
                return
            end
            local ss = SuperSurvivorSpawnNpcAtSquare(playerSurvivor:getCurrentSquare())
            if ss then
                local name = ss:getName()
                ss.player:getModData().isRobber = false
                ss:setName(name)
            end
        end,
        [78] = function() -- "numpad +" key
            if GFollowDistance < 50 then
                GFollowDistance = GFollowDistance + 1
            end
            playerSurvivor:Say("Spread out more (" .. tostring(GFollowDistance) .. ")")
        end,
        [74] = function() -- "numpad -" key
            if GFollowDistance > 0 then
                GFollowDistance = GFollowDistance - 1
            end
            playerSurvivor:Say("Stay closer (" .. tostring(GFollowDistance) .. ")")
        end,
        [181] = function() --  "numpad /" key
            local mySS = SSM:Get(0)
            local SS = SSM:GetClosestNonParty()
            if SS then
                mySS:Speak(Get_SS_Dialogue("Hey You"))
                SS:getTaskManager():AddToTop(ListenTask:new(SS, mySS:Get(), false))
            end
        end,
        [201] = window_super_survivors_visibility, -- "Page Up" key
        [209] = function() -- "Page Down" key . Below is the exact same function...
            handleGroupMemberInteraction(SSM:Get(0), "ComeWithMe")
        end,
        [55] = function() superSurvivorsHotKeyOrder(13) end, -- "numpad *" key
        [200] = function() superSurvivorsHotKeyOrder(6) end, -- Up key, Order "Follow"
        [208] = function() superSurvivorsHotKeyOrder(19) end, -- Down key, Order "Stop"
        [203] = function() superSurvivorsHotKeyOrder(18) end, -- Left key, Order "Stand Ground"
        [205] = function() superSurvivorsHotKeyOrder(1) end, -- Right key, Order "Barricade"
        [76] = LogSSDebugInfo -- Numpad 5 key, log debug info.
    }

    -- Execute the function associated with the keyNum
    if keyActions[keyNum] then
        keyActions[keyNum]()
    end
end

function handleGroupMemberInteraction(mySS, command)
    if mySS:getGroupID() == nil then
        playerSurvivor:Say("No group for player found")
        return
    end
    local myGroup = SSGM:GetGroupById(mySS:getGroupID())
    if not myGroup then return end
    local member = myGroup:getClosestMember(nil, mySS:Get())
    if not member then
        playerSurvivor:Say("GetClosestMember returned nil")
        return
    end
    mySS:Get():Say(Get_SS_UIActionText("ComeWithMe_Before") ..
                   member:Get():getForname() .. Get_SS_UIActionText(command .. "_After"))
    member:getTaskManager():clear()
    member:getTaskManager():AddToTop(FollowTask:new(member, mySS:Get()))
end

local function ss_HotKeyPress()
    Events.OnKeyPressed.Add(SuperSurvivorKeyBindAction);
end

Events.OnGameStart.Add(ss_HotKeyPress); -- Cows: This is to prevent the function from being called BEFORE the game starts.
