require "04_Group.SuperSurvivorManager";
require "08_UI/UIUtils";
-- Batmane we don't need these imports because everything is global

local WINDOW_HEADER_HEIGHT = 30;
local WINDOW_HEIGHT = (WINDOW_HEADER_HEIGHT * 10) + (WINDOW_HEADER_HEIGHT * 3) - 4; -- Cows: 30 * 3 to cover the window header, panel header, and the tabs buttons. -4 to remove empty space.
local WINDOW_WIDTH = 600;
local PANEL_HEIGHT = WINDOW_HEADER_HEIGHT * 10; -- 30 is about the height of each row.
local context_options = {};
local survivor_headers = {};
local isLocalLoggingEnabled = false;
local baseColor = { r = 0, g = 0, b = 0, a = 0 }
local backgroundColor = { r = 0.25, g = 0.31, b = 0.37, a = 0.3 }
local outlineColor = { r = 1, g = 1, b = 1, a = 0.2 }

SurvivorPanels = {}

base_area_visibility = {
    ["Bounds"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["ChopTreeArea"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["TakeCorpseArea"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["TakeWoodArea"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["FarmingArea"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["ForageArea"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["CorpseStorageArea"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["FoodStorageArea"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["WoodStorageArea"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["ToolStorageArea"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["WeaponStorageArea"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["MedicalStorageArea"] = { area_shown = false, group_id = nil, button_title = "show" },
    ["GuardArea"] = { area_shown = false, group_id = nil, button_title = "show" }
}

--****************************************************
-- Utils
--****************************************************
function addRowItem(rowInfo, i, currentPosition) 
    local rowItem = ISButton:new(
        currentPosition, 
        0, 
        rowInfo.dwidth, 
        rowInfo.dheight, 
        rowInfo.label, 
        nil,
        rowInfo.onClick
    )

    rowItem.borderColor = rowInfo.borderColor
    rowItem.backgroundColor = rowInfo.backgroundColor
    rowItem.backgroundColorMouseOver = rowInfo.backgroundColor
    rowItem.enable = rowInfo.enable
    return rowItem, currentPosition + rowInfo.dwidth
end

-- Type
-- rowInfoArray = {
--     dwidth = number,
--     dheight = number,
--     label = string,
--     onClick = () => void,
--     borderColor = rgba object
--     backgroundColor = rgba object
--     backgroundColorMouseOver = rgba object
--     enable = boolean
-- }[],
-- position = number
function addOneRow(row_index, rowInfoArray, position, borderColor, backgroundColor, altColor, panelLeftPadding) 
    local panel_entry = ISPanel:new(0, position, WINDOW_WIDTH, WINDOW_HEADER_HEIGHT)
    panel_entry.borderColor = borderColor
    panel_entry.backgroundColor = backgroundColor
    panel_entry.dwidth = WINDOW_WIDTH / #rowInfoArray

    local currentPosition = panelLeftPadding

    for i, rowInfo in ipairs(rowInfoArray) do 
        local rowItem, newPosition = addRowItem(rowInfo, i, currentPosition)
        rowItem.backgroundColor = (row_index + 1) % 2 == 0 and backgroundColor or altColor or backgroundColor
        panel_entry:addChild(rowItem)
        currentPosition = newPosition
    end
    return panel_entry
end

--****************************************************
-- ListPanelGroup
--****************************************************
local ListPanelGroup = ISPanel:new(0, 60, WINDOW_WIDTH, PANEL_HEIGHT)
table.insert(SurvivorPanels, 1, ListPanelGroup)

local numListPanelGroupTabs = 4
-- This is very similar to the Companion menu
function ListPanelGroup:dupdate()
    self:clearChildren()
    local dy = 0
    -- local switch = 0
    local group = UIUtil_GetGroup()
    if not group then return end --clear panel on player death
    local group_id = group:getID()
    local group_members = group:getMembers(true)

    for row_index, memberSS in pairs(group_members) do        
        local name, role = UIUtil_GetMemberInfo(memberSS, group_id, group_members, group)
        if role == "IGUI_SS_Job_Leader" then role = Get_SS_ContextMenuText("Job_Leader") end

        local tabWidth = WINDOW_WIDTH / numListPanelGroupTabs

        local rowInfoArray = {
            -- cat_companion_name
            {
                dwidth = tabWidth,
                dheight = WINDOW_HEADER_HEIGHT,
                label = tostring(name) 
                    .. ' (' .. tostring(role) .. ')'
                ,
                onClick = function() context_options.show_context_menu_member(row_index, memberSS, group_id, group_members, group) end,
    
                borderColor = baseColor,
                backgroundColor = backgroundColor,
                enable = true
            },
            -- -- cat_member_role
            {
                dwidth = tabWidth,
                dheight = WINDOW_HEADER_HEIGHT,
                label = memberSS:getID() == 0 and "Give Order to All" or "Give Order",
                onClick = function() context_options.show_context_menu_role(memberSS) end,
    
                borderColor = baseColor,
                backgroundColor = backgroundColor,
                enable = true

            },
            -- cat_member_inventory
            {
                dwidth = tabWidth,
                dheight = WINDOW_HEADER_HEIGHT,
                label = "Inventory",
                onClick = function() create_panel_inventory_transfer(memberSS) end,
    
                borderColor = baseColor,
                backgroundColor = backgroundColor,
                enable = memberSS:getID() ~= 0
            },
            -- cat_member_loadout
            {
                dwidth = tabWidth,
                dheight = WINDOW_HEADER_HEIGHT,
                label = "Equipment",
                onClick = function() create_panel_loadout(memberSS) end,
    
                borderColor = baseColor,
                backgroundColor = backgroundColor,
                enable = memberSS:getID() ~= 0
            },
        }


        -- local panel_entry = ISPanel:new(0, dy, WINDOW_WIDTH, WINDOW_HEADER_HEIGHT)
        -- panel_entry.borderColor = outlineColor
        -- panel_entry.backgroundColor = baseColor
        -- panel_entry.dwidth = WINDOW_WIDTH / numListPanelGroupTabs

        -- local cat_member_name = ISButton:new(0, 0, panel_entry.dwidth, WINDOW_HEADER_HEIGHT, tostring(name) .. '(' .. tostring(role) .. ')', nil,
        --     function() context_options.show_context_menu_member(row_index, memberSS, group_id, group_members, group) end)
        -- local cat_member_role = ISButton:new(panel_entry.dwidth, 0, panel_entry.dwidth, WINDOW_HEADER_HEIGHT, tostring(role), nil,
        --     function() context_options.show_context_menu_role(memberSS) end)
        -- local cat_member_inventory = ISButton:new(panel_entry.dwidth * 2, 0, panel_entry.dwidth / 2, WINDOW_HEADER_HEIGHT, "Inventory", nil,
        --     function() create_panel_inventory_transfer(memberSS) end)
        -- local cat_member_loadout = ISButton:new(panel_entry.dwidth * 2 + cat_member_inventory.width - 1, 0,
        --     panel_entry.dwidth / 2, WINDOW_HEADER_HEIGHT, "Equipment", nil, function() create_panel_loadout(row_index) end)

        -- if memberSS:getID() == 0 then cat_member_inventory.enable = false end
        -- if memberSS:getID() == 0 then cat_member_loadout.enable = false end

        -- cat_member_name.borderColor = baseColor
        -- cat_member_role.borderColor = baseColor
        -- cat_member_inventory.borderColor = baseColor
        -- cat_member_loadout.borderColor = baseColor
        -- if switch == 0 then
        --     cat_member_name.backgroundColor = backgroundColor
        --     cat_member_role.backgroundColor = backgroundColor
        --     cat_member_inventory.backgroundColor = backgroundColor
        --     cat_member_loadout.backgroundColor = backgroundColor
        --     switch = 1
        -- else
        --     cat_member_name.backgroundColor = baseColor
        --     cat_member_role.backgroundColor = baseColor
        --     cat_member_inventory.backgroundColor = baseColor
        --     cat_member_loadout.backgroundColor = baseColor
        --     switch = 0
        -- end
        -- panel_entry:addChild(cat_member_name)
        -- panel_entry:addChild(cat_member_role)
        -- panel_entry:addChild(cat_member_inventory)
        -- panel_entry:addChild(cat_member_loadout)
        local panel_entry = addOneRow(row_index, rowInfoArray, dy, outlineColor, baseColor, backgroundColor, 1)

        self:addChild(panel_entry)
        dy = dy + WINDOW_HEADER_HEIGHT
    end
    self:addScrollBars()
    self:setScrollWithParent(false)
    self:setScrollChildren(true)
    self:setScrollHeight(WINDOW_HEADER_HEIGHT * #group_members)
end

function ListPanelGroup:prerender()
    self:setStencilRect(0, 0, self.width, self.height)
    if self.background then
        self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r,
            self.backgroundColor.g, self.backgroundColor.b)
    end
    if self.border then
        self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r,
            self.borderColor.g, self.borderColor.b)
    end
end

function ListPanelGroup:render()
    self:clearStencilRect()
end

function ListPanelGroup:onMouseWheel(dir)
    dir = dir * -1
    dir = (self:getScrollHeight() / 50) * dir
    dir = self:getYScroll() + dir
    self:setYScroll(dir)
    return true
end


--****************************************************
-- ListPanelBase
--****************************************************
local ListPanelBase = ISPanel:new(0, 60, WINDOW_WIDTH, PANEL_HEIGHT)
ListPanelBase:setVisible(false)
table.insert(SurvivorPanels, 2, ListPanelBase)

-- ListPanelBaseEntry
local ListPanelBaseEntry = ISPanel:derive("ListPanelBaseEntry")

function ListPanelBaseEntry:initialize()
    ISCollapsableWindow.initialise(self)
end

function is_area_set(area_name)
    local group = UIUtil_GetGroup()
    if not group then return false end--no area set on player dead
    local sum = 0
    if area_name == "Bounds" then
        for _, j in ipairs(group.Bounds) do
            sum = sum + j
        end
    else
        for _, j in ipairs(group.GroupAreas[area_name]) do
            sum = sum + j
        end
    end
    return (sum ~= 0) and true or false
end

function ListPanelBaseEntry:createChildren()
    local context_area_name = (self.area_name == "Bounds") and "BaseArea" or self.area_name

    local cat_area_name = ISButton:new(
        1, 
        0, 
        self.dwidth, 
        WINDOW_HEADER_HEIGHT, 
        getText("ContextMenu_SS_" .. context_area_name), 
        nil,
        function() print(self.area_name) end
    )
    local cat_area_set = ISButton:new(
        self.dwidth + 1, 
        0, 
        self.dwidth, 
        WINDOW_HEADER_HEIGHT, 
        self.area_set, 
        nil, 
        nil
    )
    local cat_area_show = ISButton:new(
        self.dwidth * 2, 
        0, 
        self.dwidth, 
        WINDOW_HEADER_HEIGHT,
        base_area_visibility[self.area_name].button_title, 
        nil,
        function() on_click_base_show(self.group_id, self.area_name) end
    )
    local cat_area_edit = ISButton:new(
        self.dwidth * 3, 
        0, 
        self.dwidth, 
        WINDOW_HEADER_HEIGHT, 
        "edit", 
        nil,
        function() create_panel_base_info(self.area_name) end
    )

    cat_area_name.onMouseDown = function() return end
    cat_area_set.onMouseDown = function() return end

    cat_area_name.borderColor = baseColor
    cat_area_set.borderColor = baseColor
    cat_area_show.borderColor = baseColor
    cat_area_edit.borderColor = baseColor

    cat_area_show.enable = is_area_set(self.area_name)
    
    if self.switch == 0 then
        cat_area_name.backgroundColor = backgroundColor
        cat_area_set.backgroundColor = backgroundColor
        cat_area_show.backgroundColor = backgroundColor
        cat_area_edit.backgroundColor = backgroundColor
        cat_area_set.backgroundColorMouseOver = backgroundColor
        cat_area_name.backgroundColorMouseOver = backgroundColor
    else
        cat_area_name.backgroundColor = baseColor
        cat_area_set.backgroundColor = baseColor
        cat_area_show.backgroundColor = baseColor
        cat_area_edit.backgroundColor = baseColor
        cat_area_set.backgroundColorMouseOver = baseColor
        cat_area_name.backgroundColorMouseOver = baseColor
    end
    self:addChild(cat_area_name)
    self:addChild(cat_area_set)
    self:addChild(cat_area_show)
    self:addChild(cat_area_edit)
end


local numListPanelBaseTabs = 4
function ListPanelBaseEntry:new(x, y, width, height, area_name, area_set, area_show, switch, group_id)
    local o = {}
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.borderColor = outlineColor
    o.backgroundColor = baseColor
    o.dwidth = WINDOW_WIDTH / numListPanelBaseTabs
    o.area_name = area_name
    o.area_set = area_set
    o.area_show = area_show
    o.switch = switch
    o.group_id = group_id
    return o
end

function ListPanelBase:dupdate()
    self:clearChildren()
    local dy = 0
    local switch = 0
    local group_id = SSM:Get(0):getGroupID()
    local group = UIUtil_GetGroup()
    if not group then return end--clear panel on player death
    -- bounds area
    local base_set = (is_area_set("Bounds")) and "set" or "not set"
    local panel_entry_base = ListPanelBaseEntry:new(
        0, 
        dy, 
        WINDOW_WIDTH, 
        WINDOW_HEADER_HEIGHT, 
        "Bounds", 
        base_set,
        base_area_visibility["Bounds"].button_title, 
        switch, 
        group_id
    )
    switch = (switch == 0) and 1 or 0
    self:addChild(panel_entry_base)
    dy = dy + WINDOW_HEADER_HEIGHT
    -- group areas
    local area_count = 1
    for area_name, _ in pairs(group.GroupAreas) do
        local area_set = (is_area_set(tostring(area_name))) and "set" or "not set"
        local panel_entry_area = ListPanelBaseEntry:new(
            0, 
            dy, 
            WINDOW_WIDTH, 
            WINDOW_HEADER_HEIGHT, 
            tostring(area_name), 
            area_set,
            base_area_visibility[tostring(area_name)].button_title, 
            switch, 
            group_id
        )
        switch = (switch == 0) and 1 or 0
        self:addChild(panel_entry_area)
        dy = dy + WINDOW_HEADER_HEIGHT
        area_count = area_count + 1
    end
    self:addScrollBars()
    self:setScrollWithParent(false)
    self:setScrollChildren(true)
    self:setScrollHeight(WINDOW_HEADER_HEIGHT * area_count)
end

function ListPanelBase:prerender()
    self:setStencilRect(0, 0, self.width, self.height)
    if self.background then
        self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r,
            self.backgroundColor.g, self.backgroundColor.b)
    end
    if self.border then
        self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r,
            self.borderColor.g, self.borderColor.b)
    end
end

function ListPanelBase:render()
    self:clearStencilRect()
end

function ListPanelBase:onMouseWheel(dir)
    dir = dir * -1
    dir = (self:getScrollHeight() / 50) * dir
    dir = self:getYScroll() + dir
    self:setYScroll(dir)
    return true
end

--****************************************************
-- ListPanelCompanions
--****************************************************
local ListPanelCompanions = ISPanel:new(0, 60, WINDOW_WIDTH, PANEL_HEIGHT)
ListPanelCompanions:setVisible(false)
table.insert(SurvivorPanels, 3, ListPanelCompanions)

local numListPanelCompanionsTabs = 3
local ListPanelCompanionsLeftIndent = 1
function ListPanelCompanions:dupdate()
    self:clearChildren()
    local dy = 0
    -- local switch = 0
    local group = UIUtil_GetGroup()
    if not group then return end --clear panel on player death
    local group_id = group:getID()
    local group_members = group:getMembers(true)
    local companion_count = 0

    for row_index, memberSS in pairs(group_members) do
        local name, role, _, ai_mode = UIUtil_GetMemberInfo(memberSS, group_id, group_members, group)
        -- local panel_entry = ISPanel:new(0, dy, WINDOW_WIDTH, WINDOW_HEADER_HEIGHT)
        -- panel_entry.borderColor = outlineColor
        -- panel_entry.backgroundColor = baseColor
        -- panel_entry.dwidth = WINDOW_WIDTH / numListPanelCompanionsTabs

        local tabWidth = WINDOW_WIDTH / numListPanelCompanionsTabs

        local rowInfoArray = {
            -- cat_companion_name
            {
                dwidth = tabWidth,
                dheight = WINDOW_HEADER_HEIGHT,
                label = tostring(name) .. ' (' .. tostring(ai_mode) .. ')',
                onClick = function() context_options.show_context_menu_member(i, memberSS, group_id, group_members, group) end,
    
                borderColor = baseColor,
                backgroundColor = backgroundColor,
                enable = true

            },
            -- cat_companion_order
            {
                dwidth = tabWidth,
                dheight = WINDOW_HEADER_HEIGHT,
                label = "Give Order",
                onClick = function() context_options.show_context_menu_order(memberSS) end,
    
                borderColor = baseColor,
                backgroundColor = backgroundColor,
                enable = true
            },
            -- cat_companion_call
            {
                dwidth = tabWidth,
                dheight = WINDOW_HEADER_HEIGHT,
                label = "Call Over",
                onClick = function() on_click_companion_call(memberSS) end,
    
                borderColor = baseColor,
                backgroundColor = backgroundColor,
                enable = true
            },
        }

        -- local cat_companion_name = ISButton:new(1, 0, panel_entry.dwidth, WINDOW_HEADER_HEIGHT, tostring(name) .. ' (' .. tostring(ai_mode) .. ')', nil,
        --     function() context_options.show_context_menu_member(i, memberSS, group_id, group_members, group) end)
        -- -- local cat_companion_task = ISButton:new(panel_entry.dwidth + 1, 0, panel_entry.dwidth, WINDOW_HEADER_HEIGHT, tostring(ai_mode), nil, nil)
        -- local cat_companion_order = ISButton:new(panel_entry.dwidth + 1, 0, panel_entry.dwidth, WINDOW_HEADER_HEIGHT, "Give Order", nil,
        --     function() context_options.show_context_menu_order(memberSS) end)
        -- local cat_companion_call = ISButton:new(panel_entry.dwidth * 2 + 1, 0, panel_entry.dwidth, WINDOW_HEADER_HEIGHT, "Call", nil,
        --     function() on_click_companion_call(memberSS) end)
        -- -- cat_companion_task.onMouseDown = function() return end
        -- cat_companion_name.borderColor = baseColor
        -- -- cat_companion_task.borderColor = baseColor
        -- cat_companion_order.borderColor = baseColor
        -- cat_companion_call.borderColor = baseColor

        if role == "Companion" then
            companion_count = companion_count + 1
            -- if switch == 0 then
            --     cat_companion_name.backgroundColor = backgroundColor
            --     -- cat_companion_task.backgroundColor = backgroundColor
            --     cat_companion_order.backgroundColor = backgroundColor
            --     cat_companion_call.backgroundColor = backgroundColor
            --     -- cat_companion_task.backgroundColorMouseOver = backgroundColor
            --     switch = 1
            -- else
            --     cat_companion_name.backgroundColor = baseColor
            --     -- cat_companion_task.backgroundColor = baseColor
            --     cat_companion_order.backgroundColor = baseColor
            --     cat_companion_call.backgroundColor = baseColor
            --     -- cat_companion_task.backgroundColorMouseOver = baseColor
            --     switch = 0
            -- end

            -- panel_entry:addChild(cat_companion_name)
            -- -- panel_entry:addChild(cat_companion_task)
            -- panel_entry:addChild(cat_companion_order)
            -- panel_entry:addChild(cat_companion_call)

            local panel_entry = addOneRow(row_index, rowInfoArray, dy, outlineColor, baseColor, backgroundColor, 1)
            self:addChild(panel_entry)
            dy = dy + WINDOW_HEADER_HEIGHT
        end
    end
    self:addScrollBars()
    self:setScrollWithParent(false)
    self:setScrollChildren(true)
    self:setScrollHeight(WINDOW_HEADER_HEIGHT * companion_count)
end

function ListPanelCompanions:prerender()
    self:setStencilRect(0, 0, self.width, self.height)
    if self.background then
        self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r,
            self.backgroundColor.g, self.backgroundColor.b)
    end
    if self.border then
        self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r,
            self.borderColor.g, self.borderColor.b)
    end
end

function ListPanelCompanions:render()
    self:clearStencilRect()
end

function ListPanelCompanions:onMouseWheel(dir)
    dir = dir * -1
    dir = (self:getScrollHeight() / 50) * dir
    dir = self:getYScroll() + dir
    self:setYScroll(dir)
    return true
end

--****************************************************
-- WindowSuperSurvivors
--****************************************************
local WindowSuperSurvivors = ISCollapsableWindow:derive("WindowSuperSurvivors")

function window_super_survivors_visibility()
    window_super_survivors:setVisible(not window_super_survivors:isVisible())
end

function remove_window_super_survivors()
    window_super_survivors:removeFromUIManager()
end

function create_window_super_survivors()
    window_super_survivors = WindowSuperSurvivors:new(200, 100, WINDOW_WIDTH, WINDOW_HEIGHT)
    window_super_survivors:addToUIManager()
    window_super_survivors:setVisible(false)
    window_super_survivors.pin = true
end

function WindowSuperSurvivors:initialize()
    ISCollapsableWindow.initialise(self)
end

function WindowSuperSurvivors:createChildren()
    -- self.y_pos = WINDOW_HEADER_HEIGHT;
    self.tab_width = self.width / 3;
    self.tab_height = 24;
    ISCollapsableWindow.createChildren(self)

    local mainPlayerSS = SSM:Get(0);

    ---------------------------------------------------
    -- Headers for Group
    ---------------------------------------------------
    -- self.headers_group = ISPanel:new(0, self.y_pos, self.width, 25)
    -- table.insert(survivor_headers, 1, self.headers_group)
    -- self.headers_group_width = self.width / 3
    -- self.headers_group_name = ISButton:new(0, 0, self.headers_group_width, 25, "Name", nil, nil)
    -- self.headers_group_status = ISButton:new(self.headers_group_width, 0, self.headers_group_width, 25, "Role", nil, nil)
    -- self.headers_group_inventory = ISButton:new(self.headers_group_width * 2, 0, self.headers_group_width, 25,
    --     "Inventory", nil, nil)
    -- self.headers_group_name.onMouseDown = function() return end
    -- self.headers_group_status.onMouseDown = function() return end
    -- self.headers_group_inventory.onMouseDown = function() return end
    -- self.headers_group_name.backgroundColorMouseOver = self.headers_group_name.backgroundColor
    -- self.headers_group_status.backgroundColorMouseOver = self.headers_group_status.backgroundColor
    -- self.headers_group_inventory.backgroundColorMouseOver = self.headers_group_inventory.backgroundColor
    -- self:addChild(self.headers_group)
    -- self.headers_group:addChild(self.headers_group_name)
    -- self.headers_group:addChild(self.headers_group_status)
    -- self.headers_group:addChild(self.headers_group_inventory)

    local group_panel_tab_width = self.width / numListPanelGroupTabs
    local rowInfoArrayGroup = {
        {
            dwidth = group_panel_tab_width,
            dheight = WINDOW_HEADER_HEIGHT,
            label = "Name",
            onClick = function() return end,

            borderColor = outlineColor,
            backgroundColor = baseColor,               
            enable = true
        },
        {
            dwidth = group_panel_tab_width,
            dheight = WINDOW_HEADER_HEIGHT,
            label = "Roles",
            onClick = function() context_options.show_context_menu_role(mainPlayerSS) end,

            borderColor = outlineColor,
            backgroundColor = baseColor,               
            enable = true
        },
        {
            dwidth = group_panel_tab_width,
            dheight = WINDOW_HEADER_HEIGHT,
            label = "Inventory",
            onClick = function() return end,

            borderColor = outlineColor,
            backgroundColor = baseColor,
            enable = true
        },
        {
            dwidth = group_panel_tab_width,
            dheight = WINDOW_HEADER_HEIGHT,
            label = "Equipment",
            onClick = function() return end,

            borderColor = outlineColor,
            backgroundColor = baseColor,
            enable = true

        },
    }

    self.headers_group = addOneRow(0, rowInfoArrayGroup, WINDOW_HEADER_HEIGHT, outlineColor, baseColor, backgroundColor, 1)
    table.insert(survivor_headers, 1, self.headers_group)
    self:addChild(self.headers_group)



    -- ------------------------------------------------
    -- Headers for Base
    -- ------------------------------------------------
    -- self.headers_base = ISPanel:new(0, self.y_pos, self.width, 25)
    -- self.headers_base:setVisible(false)
    -- table.insert(survivor_headers, 1, self.headers_base)
    -- self.headers_base_width = self.width / 4
    -- self.headers_base_area = ISButton:new(1, 0, self.headers_base_width, 25, "Area", nil, nil)
    -- self.headers_base_status = ISButton:new(self.headers_base_width + 1, 0, self.headers_base_width, 25, "Set", nil, nil)
    -- self.headers_base_show = ISButton:new(self.headers_base_width * 2, 0, self.headers_base_width, 25, "Show", nil, nil)
    -- self.headers_base_modify = ISButton:new(self.headers_base_width * 3, 0, self.headers_base_width, 25, "Modify", nil,
    --     nil)
    -- self.headers_base_area.onMouseDown = function() return end
    -- self.headers_base_status.onMouseDown = function() return end
    -- self.headers_base_show.onMouseDown = function() return end
    -- self.headers_base_area.backgroundColorMouseOver = self.headers_base_area.backgroundColor
    -- self.headers_base_status.backgroundColorMouseOver = self.headers_base_status.backgroundColor
    -- self.headers_base_show.backgroundColorMouseOver = self.headers_base_show.backgroundColor
    -- self.headers_base_modify.backgroundColorMouseOver = self.headers_base_modify.backgroundColor
    -- self:addChild(self.headers_base)
    -- self.headers_base:addChild(self.headers_base_area)
    -- self.headers_base:addChild(self.headers_base_status)
    -- self.headers_base:addChild(self.headers_base_show)
    -- self.headers_base:addChild(self.headers_base_modify)

    local base_panel_tab_width = self.width / numListPanelBaseTabs
    local rowInfoArrayBase = {
        {
            dwidth = base_panel_tab_width,
            dheight = WINDOW_HEADER_HEIGHT,
            label = "Area",
            onClick = function() return end,

            borderColor = outlineColor,
            backgroundColor = baseColor,              
            enable = true
        },
        {
            dwidth = base_panel_tab_width,
            dheight = WINDOW_HEADER_HEIGHT,
            label = "Set",
            onClick = function() return end,

            borderColor = outlineColor,
            backgroundColor = baseColor,
            enable = true
        },
        {
            dwidth = base_panel_tab_width,
            dheight = WINDOW_HEADER_HEIGHT,
            label = "Show",
            onClick = function() return end,

            borderColor = outlineColor,
            backgroundColor = baseColor,
            enable = true

        },
        {
            dwidth = base_panel_tab_width,
            dheight = WINDOW_HEADER_HEIGHT,
            label = "Modify",
            onClick = function() return end,

            borderColor = outlineColor,
            backgroundColor = baseColor,
            enable = true
        },
    }

    self.headers_base = addOneRow(0, rowInfoArrayBase, WINDOW_HEADER_HEIGHT, outlineColor, baseColor, backgroundColor, 1)
    self.headers_base:setVisible(false)
    table.insert(survivor_headers, 1, self.headers_base)
    self:addChild(self.headers_base)


    -- ------------------------------------------------
    -- Headers for Companions Tab
    -- ------------------------------------------------
    -- Old
    -- self.headers_companions = ISPanel:new(0, self.y_pos, self.width, 25)
    -- self.headers_companions:setVisible(false)
    -- table.insert(survivor_headers, 1, self.headers_companions)
    -- self.headers_companions_width = self.width / numListPanelCompanionsTabs
    -- self.headers_companions_name = ISButton:new(1, 0, self.headers_companions_width, 25, "Name", nil, nil)
    -- -- self.headers_companions_task = ISButton:new(self.headers_companions_width + 1, 0, self.headers_companions_width, 25,
    -- --     "Task", nil, nil)
    -- self.headers_companions_command = ISButton:new(self.headers_companions_width + 1, 0, self.headers_companions_width,
    --     25, "Command", nil, nil)
    -- self.headers_companions_call = ISButton:new(self.headers_companions_width * 2 + 1, 0, self.headers_companions_width, 25,
    --     "Call", nil, nil)
    -- self.headers_companions_name.onMouseDown = function() return end
    -- -- self.headers_companions_task.onMouseDown = function() return end
    -- self.headers_companions_command.onMouseDown = function() return end
    -- self.headers_base_modify.onMouseDown = function() return end

    -- self.headers_companions_name.backgroundColorMouseOver = self.headers_companions_name.backgroundColor
    -- -- self.headers_companions_task.backgroundColorMouseOver = self.headers_companions_task.backgroundColor
    -- self.headers_companions_command.backgroundColorMouseOver = self.headers_companions_command.backgroundColor
    -- self.headers_companions_call.backgroundColorMouseOver = self.headers_companions_call.backgroundColor

    -- self:addChild(self.headers_companions)
    -- self.headers_companions:addChild(self.headers_companions_name)
    -- -- self.headers_companions:addChild(self.headers_companions_task)
    -- self.headers_companions:addChild(self.headers_companions_command)
    -- self.headers_companions:addChild(self.headers_companions_call)

    local companion_panel_tab_width = self.width / numListPanelCompanionsTabs
    local rowInfoArrayCompanions = {
        {
            dwidth = companion_panel_tab_width,
            dheight = WINDOW_HEADER_HEIGHT,
            label = "Name",
            onClick = function() return end,

            borderColor = outlineColor,
            backgroundColor = baseColor,                
            enable = true
        },
        -- {
        --     dwidth = companion_panel_tab_width,
        --     dheight = WINDOW_HEADER_HEIGHT,
        --     label = "Task",
        --     onClick = function() return end,

        --     borderColor = baseColor,
        --     backgroundColor = backgroundColor,
        --     enable = true
        -- },
        {
            dwidth = companion_panel_tab_width,
            dheight = WINDOW_HEADER_HEIGHT,
            label = "Command All",
            onClick = function() context_options.show_context_menu_role(mainPlayerSS) end,

            borderColor = outlineColor,
            backgroundColor = baseColor,
            enable = true

        },
        {
            dwidth = companion_panel_tab_width,
            dheight = WINDOW_HEADER_HEIGHT,
            label = "Call All",
            onClick = function() on_click_companion_call(mainPlayerSS) return end,
            

            borderColor = outlineColor,
            backgroundColor = baseColor,
            enable = true
        },
    }

    self.headers_companions = addOneRow(0, rowInfoArrayCompanions, WINDOW_HEADER_HEIGHT, outlineColor, baseColor, backgroundColor, 1)
    self.headers_companions:setVisible(false)
    table.insert(survivor_headers, 1, self.headers_companions)
    self:addChild(self.headers_companions)


    -- ------------------------------------------------
    -- ------------------------------------------------
    -- ------------------------------------------------
    -- Add Panels 
    self:addChild(ListPanelGroup)
    self:addChild(ListPanelBase)
    self:addChild(ListPanelCompanions)

    ---------------------------------------------------
    -- Tabs Buttons - For Switching Between
    ---------------------------------------------------
    self.tabs = ISPanel:new(0, self.height - 25 + 3, 846, self.tab_height)
    self.tab_group = ISButton:new(
        0, 0, self.tab_width, self.tab_height, "Group", nil,
        function() on_click_tab(self.headers_group, ListPanelGroup) end
    );
    self.tab_base = ISButton:new(
        self.tab_width, 0, self.tab_width, self.tab_height, "Base", nil,
        function() on_click_tab(self.headers_base, ListPanelBase) end
    );
    self.tab_companions = ISButton:new(
        self.tab_width * 2, 0, self.tab_width, self.tab_height, "Companions", nil,
        function()
            on_click_tab(self.headers_companions, ListPanelCompanions)
        end
    );
    self.tab_group.borderColor = outlineColor
    self.tab_base.borderColor = outlineColor
    self.tab_companions.borderColor = outlineColor
    self:addChild(self.tabs)
    self.tabs:addChild(self.tab_group)
    self.tabs:addChild(self.tab_companions)
    self.tabs:addChild(self.tab_base)
end

function WindowSuperSurvivors:new(x, y, width, height)
    local o = {};
    o = ISCollapsableWindow:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;
    o.title = "Superb Survivors Continued";
    o.pin = false;
    o.resizable = false;
    o.borderColor = outlineColor;
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.7 };
    return o;
end

--****************************************************
-- ButtonSuperSurvivors
--****************************************************
local ButtonSuperSurvivors = ISButton:derive("ButtonSuperSurvivors")

function remove_button_super_survivors()
    button_super_survivors:removeFromUIManager()
end

function create_button_super_survivors()
    button_super_survivors = ButtonSuperSurvivors:new(getCore():getScreenWidth() - (125 + 100 + 8),
        getCore():getScreenHeight() - 50, 100, 25, "survivors", nil, function() window_super_survivors_visibility() end)
    button_super_survivors.borderColor = outlineColor
    button_super_survivors:setVisible(true)
    button_super_survivors:setEnable(true)
    button_super_survivors:addToUIManager()
end

--****************************************************
-- Utility
--****************************************************
function on_click_base_show(group_id, area_name)
    base_area_visibility[area_name].group_id = group_id
    if base_area_visibility[area_name].area_shown then
        base_area_visibility[area_name].area_shown = false;
        base_area_visibility[area_name].button_title = "show";
        Events.OnRenderTick.Remove(base_area_visibility.event_update_area_highlight);
    else
        base_area_visibility[area_name].area_shown = true;
        base_area_visibility[area_name].button_title = "hide";
        Events.OnRenderTick.Add(base_area_visibility.event_update_area_highlight);
    end
    SurvivorPanels[2]:dupdate();
end

function on_click_tab(target_headers, target_panel)
    for _, header in pairs(survivor_headers) do
        if header == target_headers then
            header:setVisible(true)
        else
            header:setVisible(false)
        end
    end
    for _, panel in pairs(SurvivorPanels) do
        if panel == target_panel then
            panel:setVisible(true)
            panel:dupdate()
        else
            panel:setVisible(false)
        end
    end
end


function handleCallOverSS(memberSS) 
    getSpecificPlayer(0):Say(Get_SS_UIActionText("CallName_Before") ..
    memberSS:getName() .. Get_SS_UIActionText("CallName_After"))
    memberSS:getTaskManager():AddToTop(ListenTask:new(memberSS, getSpecificPlayer(0), false))
end

function on_click_companion_call(memberSS)
    if memberSS then
        -- Case: Call Over All
        if memberSS:getID() == 0 then 
            local group = memberSS:getGroup()
            for i, MemberId in ipairs(group.Members) do
                if i ~= 0 then
                    local Member = SSM:Get(MemberId)
                    handleCallOverSS(Member)
                end
            end
        -- Case: Call Over One
        else
            handleCallOverSS(memberSS)
        end
    end
end

function addOrdersToContextMenu(context_menu, memberSS)
    context_menu:addOption("Stop", nil, function() UIUtil_GiveOrder(19, memberSS) end)
    context_menu:addOption("Follow", nil, function() UIUtil_GiveOrder(6, memberSS) end)
    context_menu:addOption("Sentry", nil, function() UIUtil_GiveOrder(24, memberSS) end)
    context_menu:addOption("Guard", nil, function() UIUtil_GiveOrder(13, memberSS) end)
    context_menu:addOption("Barricade", nil, function() UIUtil_GiveOrder(1, memberSS) end)

    context_menu:addOption("Chop Wood", nil, function() UIUtil_GiveOrder(2, memberSS) end)
    context_menu:addOption("Clean Up Inventory", nil, function() UIUtil_GiveOrder(3, memberSS) end)
    context_menu:addOption("Doctor", nil, function() UIUtil_GiveOrder(4, memberSS) end)
    context_menu:addOption("Explore", nil, function() UIUtil_GiveOrder(5, memberSS) end)
    context_menu:addOption("Farming", nil, function() UIUtil_GiveOrder(7, memberSS) end)
    context_menu:addOption("Forage", nil, function() UIUtil_GiveOrder(8, memberSS) end)
    context_menu:addOption("Gather Wood", nil, function() UIUtil_GiveOrder(9, memberSS) end)
    context_menu:addOption("Go Find Food", nil, function() UIUtil_GiveOrder(10, memberSS) end)
    context_menu:addOption("Go Find Water", nil, function() UIUtil_GiveOrder(11, memberSS) end)
    context_menu:addOption("Go Find Weapon", nil, function() UIUtil_GiveOrder(12, memberSS) end)
    context_menu:addOption("Lock Doors", nil, function() UIUtil_GiveOrder(14, memberSS) end)
    context_menu:addOption("Loot Room", nil, function() UIUtil_GiveOrder(15, memberSS) end)
    context_menu:addOption("Patrol", nil, function() UIUtil_GiveOrder(16, memberSS) end)
    context_menu:addOption("Pile Corpses", nil, function() UIUtil_GiveOrder(23, memberSS) end)
    context_menu:addOption("Sort Loot Into Base", nil, function() UIUtil_GiveOrder(17, memberSS) end)
    context_menu:addOption("Stand Ground", nil, function() UIUtil_GiveOrder(18, memberSS) end)
    context_menu:addOption("Dismiss", nil, function() UIUtil_GiveOrder(20, memberSS) end)
    context_menu:addOption("Relax", nil, function() UIUtil_GiveOrder(21, memberSS) end)
    context_menu:addOption("Return To Base", nil, function() UIUtil_GiveOrder(22, memberSS) end)
end


context_options.show_context_menu_order = function(memberSS)
    if memberSS:getID() == 0 then return end
    
    local context_menu = ISContextMenu.get(0, getMouseX(), getMouseY(), 1, 1)
    addOrdersToContextMenu(context_menu, memberSS)
end

context_options.show_context_menu_role = function(
        memberSS
    )
    local context_menu = ISContextMenu.get(0, getMouseX(), getMouseY(), 1, 1)
    addOrdersToContextMenu(context_menu, memberSS)
end

context_options.show_context_menu_member = function(member_index, memberSS, group_id, group_members, group)
    if memberSS:getID() == 0 then return end

    local context_menu = ISContextMenu.get(0, getMouseX(), getMouseY(), 1, 1)
    context_menu:addOption("Information", nil, function() ShowSurvivorInfo(memberSS, group) end)
    context_menu:addOption("Call", nil, function() on_click_companion_call(memberSS) end)

    context_menu:addOption("Equip Gun", nil, function() ForceWeaponType(nil, memberSS, true) end)
    context_menu:addOption("Equip Melee", nil, function() ForceWeaponType(nil, memberSS, false) end)

    context_menu:addOption("DEBUG: Unstuck", nil, function() memberSS:UnStuckFrozenAnim() end)

    local remove = context_menu:addOption("Remove", nil, nil)
    local sub_remove = context_menu:getNew(context_menu)
    sub_remove:addOption("Confirm", nil, 
        function() 
            group:removeMember(memberSS:getID()) 
        end
    )
    context_menu:addSubMenu(remove, sub_remove)
end

--****************************************************
-- Events
--****************************************************
LuaEventManager.AddEvent("on_update_group_role")

function base_area_visibility.event_update_area_highlight()
    local isLocalFunctionLoggingEnabled = false;
    CreateLogLine("SuperSurvivorWindow", isLocalFunctionLoggingEnabled,
        "function: base_area_visibility.event_update_area_highlight() called");
    for area_name, _ in pairs(base_area_visibility) do
        if tostring(area_name) ~= "event_update_area_highlight" then
            if base_area_visibility[tostring(area_name)].area_shown
                and base_area_visibility[tostring(area_name)].group_id ~= nil
            then
                local group_id = base_area_visibility[tostring(area_name)].group_id;
                local group = SSGM:GetGroupById(group_id);
                local coords = (tostring(area_name) == "Bounds") and group.Bounds or group.GroupAreas[area_name];
                local x1 = coords[1];
                local x2 = coords[2];
                local y1 = coords[3];
                local y2 = coords[4];
                for i = x1, x2 do
                    for j = y1, y2 do
                        local cell = getCell():getGridSquare(i, j, getSpecificPlayer(0):getZ());
                        if cell and cell:getFloor() then
                            cell:getFloor():setHighlightColor(
                                AreaColors[area_name].r, AreaColors[area_name].g,
                                AreaColors[area_name].b, AreaColors[area_name].a
                            );
                            cell:getFloor():setHighlighted(true);
                        end
                    end
                end
            end
        end
    end
end

function wrap_set_group_role(func)
    return function(...)
        LuaEventManager.triggerEvent("on_update_group_role")
        return func(...)
    end
end

function wrap_survivor_order(func)
    return function(...)
        LuaEventManager.triggerEvent("on_update_group_role")
        return func(...)
    end
end

function event_set_group_role()
    if window_super_survivors:isVisible() then
        CreateLogLine("SuperSurvivorWindow", isLocalLoggingEnabled, "function: event_set_group_role() called");
        SurvivorPanels[1]:dupdate()
        SurvivorPanels[3]:dupdate()
    end
end

Events.on_update_group_role.Add(event_set_group_role)

function event_update_group_role()
    if window_super_survivors:isVisible() then
        CreateLogLine("SuperSurvivorWindow", isLocalLoggingEnabled, "function: event_update_group_role() called");
        SurvivorPanels[1]:dupdate()
        SurvivorPanels[3]:dupdate()
    end
end

Events.on_update_group_role.Add(event_update_group_role)

function event_every_minute()
    if window_super_survivors:isVisible() then
        SurvivorPanels[1]:dupdate()
        SurvivorPanels[3]:dupdate()
    end
end

Events.EveryOneMinute.Add(event_every_minute)

--****************************************************
-- SuperSurvivorWindow entry point
--****************************************************
function super_survivor_window_entry_point()
    create_window_super_survivors()
    create_button_super_survivors()
end

Events.OnGameStart.Add(super_survivor_window_entry_point)
