--dofile("../data/test_addons/fpssavior/addon_d.ipf/fpssavior/fpssavior.lua")
local addonName = "FPSSAVIOR"
local author = "JABBERWOCK"

_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][author] = _G["ADDONS"][author] or {}
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {}
local g = _G["ADDONS"][author][addonName]

local acutil = require("acutil")
g.fpssavior_path = string.format("../addons/%s/settings.json", string.lower(addonName))

g.saviormode = {
    "{#2D9B27}{ol}HIGH",
    "{#F2F407}{ol}MEDIUM",
    "{#284B7E}{ol}LOW",
    "{#532881}{ol}UltraLOW",
    "{#9c3022}{ol}UltraLOW2"
}

local FPSSAVIOR_MODES_CONFIG = {
    [1] = { name = "HIGH", bloom = 1, glow = 1, edge = 1, fxaa = 1, tex = 1, soft = 1, shadow = 1, light = 1, water = 1, dead = 1, glow_hit = 1, hidden = 1 },
    [2] = { name = "MEDIUM", bloom = 0, glow = 1, edge = 1, fxaa = 1, tex = 1, soft = 0, shadow = 0, light = 1, water = 1, dead = 0, glow_hit = 0, hidden = 1 },
    [3] = { name = "LOW", bloom = 0, glow = 0, edge = 0, fxaa = 0, tex = 0, soft = 0, shadow = 0, light = 0, water = 0, dead = 0, glow_hit = 0, hidden = 1, dmg_fx = 0 },
    [4] = { name = "UltraLOW", bloom = 0, glow = 0, edge = 0, fxaa = 0, tex = 0, soft = 0, shadow = 0, light = 0, water = 0, dead = 0, glow_hit = 0, hidden = 1, dmg_fx = 0, imc_fx = 0, fx = 0 },
    [5] = { name = "UltraLOW2", bloom = 0, glow = 0, edge = 0, fxaa = 0, tex = 0, soft = 0, shadow = 0, light = 0, water = 0, dead = 0, glow_hit = 0, hidden = 0, dmg_fx = 0, imc_fx = 0, fx = 0 }
}

local SHORTCUT_BUTTONS = {
    { key = "btnh", text = "{s16}{#2D9B27}{ol}H", toggle = 1 },
    { key = "btnm", text = "{s16}{#F2F407}{ol}M", toggle = 2 },
    { key = "btnl", text = "{s16}{#284B7E}{ol}L", toggle = 3 },
    { key = "btnul", text = "{s16}{#532881}{ol}U1", toggle = 4 },
    { key = "btnex", text = "{s16}{#9c3022}{ol}U2", toggle = 5 }
}

local SETTING_CHECKBOXES = {
    { key = "fx_self",         label = "All FX",                   category = "Auto hide FX:",               script = "FPSSAVIOR_SAVECONFIG_FX_SOURCE" },
    { key = "fx_others",       label = "Other player skill FX",    category = nil,                           script = "FPSSAVIOR_SAVECONFIG_FX_SOURCE" },
    { key = "fx_town",         label = "Town / Capital Area",      category = "Select An Area To Hide:",     script = "FPSSAVIOR_SAVECONFIG_FX_AREA" },
    { key = "fx_field",        label = "Field / Hunting Area",     category = nil,                           script = "FPSSAVIOR_SAVECONFIG_FX_AREA" },
    { key = "fx_raid",         label = "Raid / Instanced Dungeon", category = nil,                           script = "FPSSAVIOR_SAVECONFIG_FX_AREA" },
    { key = "fx_challenge",    label = "Challenge / Singularity",  category = nil,                           script = "FPSSAVIOR_SAVECONFIG_FX_AREA" },
    { key = "hidebossflash",   label = "Hide Boss Dead Flashbang", category = "Boss Effect Settings:",       script = "FPSSAVIOR_SAVECONFIG_FLASH" },
    { key = "show_itemdrops",  label = "Always Show FX",           category = "Item drop FX:",               script = "FPSSAVIOR_ITEMDROP_FORCE" },
    { key = "lock",            label = "Lock Main Frame Position", category = "Window Protection:",         script = "FPSSAVIOR_SAVECONFIG_LOCK" }
	--{ key = "new_key", label = "label", category = "category", script = "script" },
}

function g.block_click_through(frame)
    if frame == nil then return end
    frame:EnableHitTest(1)
    frame:EnableHittestFrame(1)
end

local cachedMapType = "Field"
local COMPAT_RAID_INDUN_IDS = {
    [734] = true, [733] = true, [737] = true, [736] = true, [731] = true, [730] = true, [729] = true,
    [727] = true, [726] = true, [725] = true, [724] = true, [723] = true, [722] = true, [718] = true,
    [717] = true, [716] = true, [709] = true, [708] = true, [707] = true, [712] = true, [711] = true,
    [710] = true, [696] = true, [695] = true, [697] = true, [689] = true, [688] = true, [690] = true,
    [686] = true, [685] = true, [687] = true, [680] = true, [679] = true, [681] = true, [677] = true,
    [676] = true, [678] = true, [674] = true, [673] = true, [675] = true, [672] = true, [671] = true,
    [670] = true, [667] = true, [666] = true, [665] = true, [669] = true, [635] = true, [628] = true,
    [661] = true, [662] = true, [663] = true, [623] = true, [201] = true, [684] = true, [732] = true
}

local function GetCurrentMapType()
    return cachedMapType
end

function FPSSAVIOR_LOADSETTINGS()
    local settings = g.load_json and g.load_json(g.fpssavior_path) or acutil.loadJSON(g.fpssavior_path)
    if not settings then
        FPSSAVIOR_SAVESETTINGS(true)
        return
    end
    if settings.show_itemdrops == nil then settings.show_itemdrops = 1 end
    local defaults = {
        saviorToggle = 2, displayX = 400, displayY = 400, lock = 0, drawplayer = 100, drawmonster = 100,
        fx_self = 0, fx_others = 0, fx_monsters = 0, fx_bosses = 0, fx_town = 0, fx_field = 0, fx_raid = 0, fx_challenge = 0, fx_division = 0,
        show_itemdrops = 1, hidebossflash = 0, fontsize_main = 14, fontsize_config = 14, main_margin = 45, is_minimized = 0, config_opened_cache = 0, boss_effect_value = 255
    }
    for k, v in pairs(defaults) do if settings[k] == nil then settings[k] = v end end
    g.settings = settings
end
function FPSSAVIOR_SAVESETTINGS(forceDefault)
    if forceDefault or g.settings == nil then
        g.settings = {
            saviorToggle = 2, displayX = 400, displayY = 400, lock = 0, drawplayer = 100, drawmonster = 100,
            fx_self = 0, fx_others = 0, fx_monsters = 0, fx_bosses = 0, fx_town = 0, fx_field = 0, fx_raid = 0, fx_challenge = 0, fx_division = 0,
            show_itemdrops = 1, hidebossflash = 0, fontsize_main = 14, fontsize_config = 14, main_margin = 45, is_minimized = 0, config_opened_cache = 0, boss_effect_value = 255
        }
    else
        if g.settings.fontsize_main == nil or g.settings.fontsize_main == 0 then g.settings.fontsize_main = 14 end
        if g.settings.fontsize_config == nil or g.settings.fontsize_config == 0 then g.settings.fontsize_config = 14 end
        if g.settings.main_margin == nil or g.settings.main_margin == 0 then g.settings.main_margin = 45 end
        if g.settings.is_minimized == nil then g.settings.is_minimized = 0 end
        if g.settings.config_opened_cache == nil then g.settings.config_opened_cache = 0 end
        if g.settings.fx_self == nil then g.settings.fx_self = 0 end
        if g.settings.fx_others == nil then g.settings.fx_others = 0 end
        if g.settings.fx_monsters == nil then g.settings.fx_monsters = 0 end
        if g.settings.fx_bosses == nil then g.settings.fx_bosses = 0 end
        if g.settings.fx_town == nil then g.settings.fx_town = 0 end
        if g.settings.fx_field == nil then g.settings.fx_field = 0 end
        if g.settings.fx_raid == nil then g.settings.fx_raid = 0 end
        if g.settings.fx_challenge == nil then g.settings.fx_challenge = 0 end
        if g.settings.fx_division == nil then g.settings.fx_division = 0 end
        if g.settings.show_itemdrops == nil then g.settings.show_itemdrops = 1 end
        if g.settings.boss_effect_value == nil then g.settings.boss_effect_value = 255 end
    end
    if g.save_json then g.save_json(g.fpssavior_path, g.settings) else acutil.saveJSON(g.fpssavior_path, g.settings) end
end

function FPSSAVIOR_START()
    local masterFrame = ui.GetFrame("fpssaviormaster")
    if masterFrame == nil then
        masterFrame = ui.CreateNewFrame("notice_on_pc", "fpssaviormaster")
        masterFrame:SetBorder(0, 0, 0, 0) masterFrame:SetLayerLevel(61) masterFrame.isDragging = false
        masterFrame:SetEventScript(ui.LBUTTONDOWN, "FPSSAVIOR_START_DRAG")
        masterFrame:SetEventScript(ui.LBUTTONUP, "FPSSAVIOR_END_DRAG")
    end
    g.block_click_through(masterFrame) masterFrame:RemoveAllChild()
    local secretLock = masterFrame:CreateOrGetControlSet('inv_itemlock', "fps_immortal_lock", 0, 0)
    if secretLock ~= nil then secretLock:ShowWindow(0) end
    if g.settings.skin_name == nil then g.settings.skin_name = "pip_simple_frame" end
    masterFrame:SetSkinName(g.settings.skin_name)
    if g.settings.displayX == nil or g.settings.displayX < 0 or g.settings.displayX > ui.GetSceneWidth() then g.settings.displayX = 400 end
    if g.settings.displayY == nil or g.settings.displayY < 0 or g.settings.displayY > ui.GetSceneHeight() then g.settings.displayY = 400 end
        if g.settings.is_minimized == 1 then
        masterFrame:Resize(1000, 36) 
        masterFrame:SetOffset(g.settings.displayX, g.settings.displayY)
        masterFrame:EnableMove(g.settings.lock == 1 and 0 or 1) 
        masterFrame:ShowWindow(1)
        
        local btnsaviorC = masterFrame:CreateOrGetControl('button', 'btnc', 5, 5, 60, 26)
        btnsaviorC:SetText("{ol}{s10}FPS FIX") 
        btnsaviorC:SetEventScript(ui.LBUTTONDOWN, 'FPSSAVIOR_OPENCONFIG')
        btnsaviorC:SetEventScript(ui.RBUTTONDOWN, 'FPSSAVIOR_TOGGLE_MINIMIZE')
		-- {ol}{nl} {#FFCC00} = [Warning] {#FF5555} = [Critical] {#00FF00} = [Info] {#4183D7} = [Tip/Guide] {#FFFFFF} = Text 
        btnsaviorC:SetTextTooltip("{ol}{#4183D7}[Control Guides]{nl}{#FFFFFF}- Left-Click: Open Config Settings{nl}- Right-Click: Expand Main Frame")    
        masterFrame:Resize(btnsaviorC:GetX() + btnsaviorC:GetWidth() + 6, 36)
    else
        masterFrame:Resize(1000, 65) 
        masterFrame:SetOffset(g.settings.displayX, g.settings.displayY)
        masterFrame:EnableMove(g.settings.lock == 1 and 0 or 1) 
        masterFrame:ShowWindow(1)
        
        local btnsaviorC = masterFrame:CreateOrGetControl('button', 'btnc', 6, 5, 60, 26)
        btnsaviorC:SetText("{ol}{s10}FPS FIX") 
        btnsaviorC:SetEventScript(ui.LBUTTONDOWN, 'FPSSAVIOR_OPENCONFIG')
        btnsaviorC:SetEventScript(ui.RBUTTONDOWN, 'FPSSAVIOR_TOGGLE_MINIMIZE')
        btnsaviorC:SetTextTooltip("{ol}{#4183D7}[Control Guides]{nl}{#FFFFFF}- Left-Click: Open Config Settings{nl}- Right-Click: Minimize Main Frame")

        local saviorText = masterFrame:CreateOrGetControl("richtext", "saviortext", 72, 12, 0, 0)
        saviorText = tolua.cast(saviorText, "ui::CRichText") saviorText:EnableHitTest(0)
        saviorText:SetText("{s" .. g.settings.fontsize_main .. "}" .. g.saviormode[g.settings.saviorToggle])
        FPSSAVIOR_CREATE_SHORTCUT_BUTTONS(masterFrame)
        local btnDef = masterFrame:GetChild("btndef")
        if btnDef ~= nil then masterFrame:Resize(btnDef:GetX() + btnDef:GetWidth() + 6, 65) else masterFrame:Resize(214, 65) end
    end
    masterFrame:ShowWindow(1) masterFrame:SetAlpha(100)
    FPSSAVIOR_APPLY_GRAPHICS_MODE(g.settings.saviorToggle)
    masterFrame:ShowWindow(1) 
    masterFrame:SetAlpha(100)
    FPSSAVIOR_APPLY_GRAPHICS_MODE(g.settings.saviorToggle)
end

function FPSSAVIOR_CREATE_SHORTCUT_BUTTONS(masterFrame)
    local w, startX, currentY = 30, 6, 35
    for _, btn in ipairs(SHORTCUT_BUTTONS) do
        local ctrl = masterFrame:CreateOrGetControl('button', btn.key, startX, currentY, w, 22)
        ctrl:SetText(btn.text) ctrl:SetEventScript(ui.LBUTTONDOWN, 'FPSSAVIOR_ON_CLICK_SHORTCUT')
        ctrl:SetEventScriptArgNumber(ui.LBUTTONDOWN, btn.toggle) startX = startX + w
    end
    local btnDef = masterFrame:CreateOrGetControl('button', 'btndef', startX, currentY, w, 22)
    btnDef:SetText("{s16}{#4183D7}{ol}D") btnDef:SetEventScript(ui.LBUTTONDOWN, 'FPSSAVIOR_CLICK_DEFAULT_BTN')
end

function FPSSAVIOR_CMD(strArgs)
    local masterFrame = ui.GetFrame("fpssaviormaster")
    if masterFrame ~= nil then
        ui.DestroyFrame("fpssaviormaster")
    end
    local configframe = ui.GetFrame('fpssaviorconfig')
    if configframe ~= nil then
        ui.DestroyFrame('fpssaviorconfig')
    end
    
    FPSSAVIOR_START()
    CHAT_SYSTEM("FPS Savior: Frame successfully reloaded and restored!")
end


function FPSSAVIOR_ON_INIT(addon, frame)
    if frame ~= nil then frame:ShowWindow(1) end
    acutil.slashCommand("/fpssavior", FPSSAVIOR_CMD)
    if addon ~= nil then
        addon:RegisterMsg("GAME_START", "FPSSAVIOR_START")
        addon:RegisterMsg("FPS_UPDATE", "FPSSAVIOR_REALTIME_RESURRECT_LOOP")
        addon:RegisterMsg("TARGET_SET_BOSS", "FPSSAVIOR_BOSS_FRAME_TRIGGER")
        addon:RegisterMsg("TARGET_UPDATE", "FPSSAVIOR_BOSS_FRAME_TRIGGER")
        addon:RegisterMsg("TARGET_BUFF_UPDATE", "FPSSAVIOR_BOSS_FRAME_TRIGGER")
    end
    FPSSAVIOR_ADDON_OBJECT_LINK = addon or _G["FPSSAVIOR_ADDON_OBJECT_LINK"]
    FPSSAVIOR_LOADSETTINGS()
    
    if _G["FPSSAVIOR_SYSTEM_HOOKS_SET"] == nil then
        local sysmenuFrame = ui.GetFrame("sysmenu")
        if sysmenuFrame then
            local orig_ShowWindow = sysmenuFrame.ShowWindow
            sysmenuFrame.ShowWindow = function(self, showAttr, ...) 
                if showAttr == 1 and (g.settings and g.settings.is_hidden_cache ~= 1) then 
                    FPSSAVIOR_START() 
                end 
                return orig_ShowWindow(self, showAttr, ...) 
            end
        end
        local hudFrame = ui.GetFrame("headsupdisplay")
        if hudFrame then
            local orig_ShowWindow = hudFrame.ShowWindow
            hudFrame.ShowWindow = function(self, showAttr, ...) 
                if showAttr == 1 and (g.settings and g.settings.is_hidden_cache ~= 1) then 
                    FPSSAVIOR_START() 
                end 
                return orig_ShowWindow(self, showAttr, ...) 
            end
        end
        _G["FPSSAVIOR_SYSTEM_HOOKS_SET"] = true
    end
end


local lastCheckedMapName = ""


function FPSSAVIOR_REALTIME_RESURRECT_LOOP()
    local mapName = session.GetMapName()
    local mapCls = GetClass("Map", mapName)
    if mapCls then
        local mapType = mapCls.MapType
        local className = string.lower(mapCls.ClassName)
        if mapType == "City" then cachedMapType = "Town"
        elseif className:find("challenge") or className:find("cd_") or className:find("singularity") or className:find("ds_") then cachedMapType = "Challenge"
        elseif className:find("raid") or className:find("dungeon") or mapType == "Indun" then cachedMapType = "Raid"
        else cachedMapType = "Field" end
    end
    
    if mapName ~= lastCheckedMapName then 
        lastCheckedMapName = mapName 
        FPSSAVIOR_APPLY_GRAPHICS_MODE(g.settings.saviorToggle, true) 
    end
    
    FPSSAVIOR_SHOWORHIDE_OBJ()
    
    if _G["UpdateItemDropsData"] then 
        _G["UpdateItemDropsData"]() 
    end
    
    local mf = ui.GetFrame("fpssaviormaster")
    if mf == nil then

        FPSSAVIOR_START()
        if g.settings and g.settings.config_opened_cache == 1 then 
            FPSSAVIOR_CONFIGFRAME() 
        end
    else
        if g.settings and g.settings.displayX >= 0 and g.settings.displayY >= 0 then 
            mf:SetOffset(g.settings.displayX, g.settings.displayY) 
        end
        
        if mf:GetAlpha() > 0 then
            mf:ShowWindow(1)
        end
    end
end


function FPSSAVIOR_CONFIGFRAME()
    local masterFrame = ui.GetFrame("fpssaviormaster") if masterFrame == nil then return end
    local configframe = ui.GetFrame('fpssaviorconfig') or ui.CreateNewFrame("chat_memberlist", "fpssaviorconfig")
    configframe:SetLayerLevel(61) g.block_click_through(configframe) configframe:RemoveAllChild()
    if g.settings.skin_name == nil then g.settings.skin_name = "pip_simple_frame" end
    configframe:SetSkinName(g.settings.skin_name)
    local cfsize = g.settings.fontsize_config local rowHeight = cfsize + 8 configframe:Resize(2000, 2000)
    local mainX, mainY, startX, currentY = masterFrame:GetX(), masterFrame:GetY(), 14, 16
    for i, item in ipairs(SETTING_CHECKBOXES) do
        if item.category then
            currentY = currentY + 6
            local header = configframe:CreateOrGetControl("richtext", "hdr_" .. item.key, startX, currentY, 0, 0)
            header:SetText("{s" .. cfsize .. "}{ol}{#FFD700}" .. item.category) currentY = currentY + rowHeight + 2
        end
        local box = configframe:CreateOrGetControl('checkbox', item.key .. "box", startX, currentY + math.floor((cfsize - 18) / 2), 18, 18)
        box:SetText("") box:SetEventScript(ui.LBUTTONUP, item.script)
        GET_CHILD(configframe, item.key .. "box"):SetCheck(g.settings[item.key] or 0)
		
		-- {ol}{nl} {#FFCC00} = [Warning] {#FF5555} = [Critical] {#00FF00} = [Info] {#4183D7} = [Tip/Guide] {#FFFFFF} = Text 
		--if item.key == "Key" then
        --	box:SetTextTooltip("Text")
        --end
		if item.key == "fx_self" then
           box:SetTextTooltip("{ol}{#00FF00}[Info]: This setting will hide all FX on screen except boss attack range on specific area contents.{nl}{#FFFFFF}- Recommended: Leave checked to hide heavy effect.")
        end
		if item.key == "fx_others" then
           box:SetTextTooltip("{ol}{#00FF00}[Info]: This setting will hide Other player and Other Object FX on screen{nl} except player skill FX and boss skill FX on specific area.{nl}{#FFFFFF}- Recommended: Leave checked to hide heavy effect.")
        end
		if item.key == "fx_town" or item.key == "fx_field" or item.key == "fx_raid" or item.key == "fx_challenge" then
           box:SetTextTooltip("{ol}{#00FF00}[Info]: This setting will hide FX on specific area contents.{nl}{#FFFFFF}- Recommended: Leave checked to hide heavy effect.")
        end
		if item.key == "hidebossflash" then
            box:SetTextTooltip("{ol}{#00FF00}[Info]: This setting may not working for some boss.{nl}{#FFFFFF}- Recommended: Leave checked to hide most boss flashbang.")
        end
        if item.key == "show_itemdrops" then
            box:SetTextTooltip("{ol}{#FFCC00}[Warning]: This setting may cause a temporary Other FX rendering bug on specific area.{nl}{#FFFFFF}- Recommended: Leave checked for casual farming, uncheck for heavy raids.")
        end
        if item.key == "lock" then
            box:SetTextTooltip("{ol}{#00FF00}[Info]: This setting will lock Preset frame position.{nl}{#FFFFFF}- Recommended: Leave checked to lock Preset frame position.")
        end

        local labelText = configframe:CreateOrGetControl("richtext", "lbl_" .. item.key, startX + 28, currentY, 0, 0)
        labelText = tolua.cast(labelText, "ui::CRichText") labelText:EnableHitTest(0) labelText:SetText("{s" .. cfsize .. "}{ol}{#FFFFFF}" .. item.label)
		
		-- {ol}{nl} {#FFCC00} = [Warning] {#FF5555} = [Critical] {#00FF00} = [Info] {#4183D7} = [Tip/Guide] {#FFFFFF} = Text 
        --if item.key == "Key" then
         --   labelText:EnableHitTest(1) 
         --   labelText:SetTextTooltip("Text")
        --end
		if item.key == "fx_self" then
			labelText:EnableHitTest(1) 
			labelText:SetTextTooltip("{ol}{#00FF00}[Info]: This setting will hide all FX on screen except boss attack range.{nl}{#FFFFFF}- Recommended: Leave checked to hide heavy effect.")
        end
		if item.key == "fx_others" then
           labelText:EnableHitTest(1) 
			labelText:SetTextTooltip("{ol}{#00FF00}[Info]: This setting will hide Other player and Other Object FX on screen{nl} except player skill FX and boss skill FX on specific area.{nl}{#FFFFFF}- Recommended: Leave checked to hide heavy effect.")
        end
		if item.key == "fx_town" or item.key == "fx_field" or item.key == "fx_raid" or item.key == "fx_challenge" then
           labelText:EnableHitTest(1) 
			labelText:SetTextTooltip("{ol}{#00FF00}[Info]: This setting will hide FX on specific area contents.{nl}{#FFFFFF}- Recommended: Leave checked to hide heavy effect.")
        end
		if item.key == "hidebossflash" then
            labelText:EnableHitTest(1)
            labelText:SetTextTooltip("{ol}{#00FF00}[Info]: This setting may not working for some boss.{nl}{#FFFFFF}- Recommended: Leave checked to hide most boss flashbang.")
        end
		
        if item.key == "show_itemdrops" then
            labelText:EnableHitTest(1)
            labelText:SetTextTooltip("{ol}{#FFCC00}[Warning]: This setting may cause a temporary Other FX rendering bug on specific area.{nl}{#FFFFFF}- Recommended: Leave checked for casual farming, uncheck for heavy raids.")
        end
        if item.key == "lock" then
            labelText:EnableHitTest(1)
            labelText:SetTextTooltip("{ol}{#00FF00}[Info]: This setting will lock Preset frame position.{nl}{#FFFFFF}- Recommended: Leave checked to lock Preset frame position.")
        end
		
        currentY = currentY + rowHeight
    end

    currentY = currentY + 12
    local sizeText = configframe:CreateOrGetControl("richtext", "fontsizetext", startX, currentY, 0, 0)
    sizeText:SetText("{s" .. cfsize .. "}{ol}{#FFFFFF}Font Size: " .. cfsize)
    local btnMinus = configframe:CreateOrGetControl("button", "btn_font_minus", startX + 130, currentY - 2, 24, 22)
    btnMinus:SetText("{ol}-") btnMinus:SetEventScript(ui.LBUTTONDOWN, "FPSSAVIOR_CHANGE_FONT_SCALE") btnMinus:SetEventScriptArgNumber(ui.LBUTTONDOWN, -1)
    local btnPlus = configframe:CreateOrGetControl("button", "btn_font_plus", startX + 158, currentY - 2, 24, 22)
    btnPlus:SetText("{ol}+") btnPlus:SetEventScript(ui.LBUTTONDOWN, "FPSSAVIOR_CHANGE_FONT_SCALE") btnPlus:SetEventScriptArgNumber(ui.LBUTTONDOWN, 1)
    currentY = currentY + rowHeight + 12
    local skinBtn = configframe:CreateOrGetControl("button", "btn_skin_switch", startX, currentY, 182, 26)
    skinBtn:SetText("{s12}{ol}Switch UI Skin") skinBtn:SetEventScript(ui.LBUTTONDOWN, "FPSSAVIOR_TOGGLE_SKIN_COMMAND")
    currentY = currentY + 30
    local resetBtn = configframe:CreateOrGetControl("button", "fontmarginresetbtn", startX, currentY, 182, 26)
    resetBtn = tolua.cast(resetBtn, "ui::CButton") resetBtn:SetSkinName("basebtn") resetBtn:SetText("{s" .. cfsize .. "}{ol}Reset UI Config")
    resetBtn:SetEventScript(ui.LBUTTONDOWN, "FPSSAVIOR_RESET_FONT_MARGIN")
    local maxWidth, maxHeight = 0, 0
    for i = 0, configframe:GetChildCount() - 1 do
        local child = configframe:GetChildByIndex(i)
        if child ~= nil then
            if child:GetX() + child:GetWidth() > maxWidth then maxWidth = child:GetX() + child:GetWidth() end
            if child:GetY() + child:GetHeight() > maxHeight then maxHeight = child:GetY() + child:GetHeight() end
        end
    end
    configframe:Resize(maxWidth + 20, maxHeight + 16)
    if mainY + masterFrame:GetHeight() + configframe:GetHeight() <= ui.GetSceneHeight() then configframe:SetOffset(mainX, mainY + masterFrame:GetHeight() + 2)
    else configframe:SetOffset(mainX, mainY - configframe:GetHeight() - 2) end
    configframe:ShowWindow(1)
end

function FPSSAVIOR_TOGGLE_MINIMIZE(parent, control) 
	g.settings.is_minimized = (g.settings.is_minimized == 1) and 0 or 1 
	if ui.GetFrame('fpssaviorconfig') then 
		ui.GetFrame('fpssaviorconfig'):ShowWindow(0) 
		g.settings.config_opened_cache = 0 
	end 
	FPSSAVIOR_SAVESETTINGS() 
	FPSSAVIOR_START() 
end

function FPSSAVIOR_CHANGE_FONT_SCALE(parent, control, strArg, numArg) 
	local newSize = (g.settings.fontsize_config or 14) + numArg if newSize >= 11 and newSize <= 24 then 
		g.settings.fontsize_main = newSize 
		g.settings.fontsize_config = newSize 
		FPSSAVIOR_SAVESETTINGS() 
		FPSSAVIOR_START() 
		FPSSAVIOR_CONFIGFRAME() 
	end 
end

function FPSSAVIOR_TOGGLE_SKIN_COMMAND(parent, control) 
	g.settings.skin_name = (g.settings.skin_name == "pip_simple_frame") and "test_frame_low" or "pip_simple_frame" 
		FPSSAVIOR_SAVESETTINGS() 
		FPSSAVIOR_START() 
		FPSSAVIOR_CONFIGFRAME() 
end

function FPSSAVIOR_OPENCONFIG() 
	local cf = ui.GetFrame('fpssaviorconfig') 
	if cf and cf:IsVisible() == 1 then 
		cf:ShowWindow(0) 
		g.settings.config_opened_cache = 0 
	else 
		FPSSAVIOR_CONFIGFRAME() 
		g.settings.config_opened_cache = 1 
	end 
	FPSSAVIOR_SAVESETTINGS() 
end

function FPSSAVIOR_BOSS_FRAME_TRIGGER(frame, msg) 
	if ui.GetFrame("fpssaviormaster") ~= nil then 
		ui.GetFrame("fpssaviormaster"):ShowWindow(1) 
	end 
end

function FPSSAVIOR_APPLY_GRAPHICS_MODE(modeIndex, isMapChangeRefresh)
    local cfg = FPSSAVIOR_MODES_CONFIG[modeIndex] if cfg == nil then return end
    g.settings.saviorToggle = modeIndex 
    
    if modeIndex == 1 then
        graphic.SetDrawActor(100)
        graphic.SetDrawMonster(100)
    elseif modeIndex == 2 then
        graphic.SetDrawActor(40)
        graphic.SetDrawMonster(80)
    elseif modeIndex == 3 then
        graphic.SetDrawActor(20)
        graphic.SetDrawMonster(40)
    elseif modeIndex == 4 then
        graphic.SetDrawActor(10)
        graphic.SetDrawMonster(20)
    elseif modeIndex == 5 then
        graphic.SetDrawActor(5)
        graphic.SetDrawMonster(10)
    end
    
    graphic.EnableCharEdge(cfg.edge) 
    graphic.EnableFXAA(cfg.fxaa) 
    graphic.EnableHighTexture(cfg.tex) 
    graphic.EnableSoftParticle(cfg.soft) 
    graphic.EnableWater(cfg.water)
    config.SetRenderShadow(cfg.shadow) 
    imcperfOnOff.EnableRenderShadow(cfg.shadow) 
    imcperfOnOff.EnablePlaneLight(cfg.light) 
    imcperfOnOff.EnableWater(cfg.water) 
    imcperfOnOff.EnableDeadParts(cfg.dead) 
    graphic.EnableHitGlow(cfg.glow_hit)
		
    if cfg.hidden == 1 then 
        imcperfOnOff.EnableFog(1) imcperfOnOff.EnableGrass(1) imcperfOnOff.EnableLight(1) 
        imcperfOnOff.EnableParticleEffectModel(1) imcperfOnOff.EnableParticleInstancing(1) 
        imcperfOnOff.EnableParticleInstancing2(1) imcperfOnOff.EnableParticleModel(1) 
        imcperfOnOff.EnableParticlePoint(1) imcperfOnOff.EnableParticleScreen(1) 
        imcperfOnOff.EnableParticleVertex(1) imcperfOnOff.EnableSky(1) imcperfOnOff.EnableMud(1)
    else 
        imcperfOnOff.EnableFog(0) imcperfOnOff.EnableGrass(0) imcperfOnOff.EnableLight(0) 
        imcperfOnOff.EnableParticleEffectModel(0) imcperfOnOff.EnableParticleInstancing(0) 
        imcperfOnOff.EnableParticleInstancing2(0) imcperfOnOff.EnableParticleModel(0) 
        imcperfOnOff.EnableParticlePoint(0) imcperfOnOff.EnableParticleScreen(0) 
        imcperfOnOff.EnableParticleVertex(0) imcperfOnOff.EnableSky(0) imcperfOnOff.EnableMud(0) 
    end

    if isMapChangeRefresh then 
        config.SaveConfig() 
    end 
    FPSSAVIOR_SAVESETTINGS() 
    FPSSAVIOR_SHOWORHIDE_OBJ()

    local mf = ui.GetFrame("fpssaviormaster") 
    if mf and mf:GetChild("saviortext") then 
        tolua.cast(mf:GetChild("saviortext"), "ui::CRichText"):SetText("{s" .. g.settings.fontsize_main .. "}" .. g.saviormode[modeIndex]) 
    end

    pcall(function()
        collectgarbage("collect")
    end)
end



function FPSSAVIOR_SAVECONFIG_FX_SOURCE(parent, control) 
    local key = string.gsub(control:GetName(), "box$", "") 
    if g.settings[key] ~= nil then 
        g.settings[key] = control:IsChecked() 
        FPSSAVIOR_SAVESETTINGS() 
        FPSSAVIOR_CONFIGFRAME() 
        FPSSAVIOR_SHOWORHIDE_OBJ() 
		
        pcall(function()
            collectgarbage("collect")
        end)
    end 
end

function FPSSAVIOR_SAVECONFIG_FX_AREA(parent, control) 
    local key = string.gsub(control:GetName(), "box$", "") 
    if g.settings[key] ~= nil then 
        g.settings[key] = control:IsChecked() 
        FPSSAVIOR_SAVESETTINGS() 
        FPSSAVIOR_CONFIGFRAME() 
        FPSSAVIOR_SHOWORHIDE_OBJ() 

        pcall(function()
            collectgarbage("collect")
        end)
    end 
end


function FPSSAVIOR_ON_CLICK_SHORTCUT(parent, control, strArg, numArg) FPSSAVIOR_APPLY_GRAPHICS_MODE(tonumber(numArg) or 2, true) end

function FPSSAVIOR_CLICK_DEFAULT_BTN() 
	if ui.GetFrame('fpssaviorconfig') then 
		ui.DestroyFrame('fpssaviorconfig') 
	end 
		g.settings.displayX = 400 
		g.settings.displayY = 400 
		g.settings.lock = 0 
		g.settings.is_minimized = 0 
		g.settings.config_opened_cache = 0 
		FPSSAVIOR_SAVESETTINGS() 
		FPSSAVIOR_START() 
		CHAT_SYSTEM("FPS Savior: Reset Center!") 
end

function FPSSAVIOR_RESET_FONT_MARGIN() 
	if ui.GetFrame('fpssaviorconfig') then 
		ui.DestroyFrame('fpssaviorconfig') 
	end 
		g.settings.fontsize_main = 14 
		g.settings.fontsize_config = 14 
		g.settings.main_margin = 45 
		g.settings.config_opened_cache = 0 
		FPSSAVIOR_SAVESETTINGS() 
		FPSSAVIOR_START() 
		CHAT_SYSTEM("FPS Savior: Config Reset!") 
end

function FPSSAVIOR_ON_CHANGE_FONTSIZE(p, c) end

function FPSSAVIOR_START_DRAG() 
	local mf = ui.GetFrame("fpssaviormaster") 
	if mf and g.settings.lock == 0 then 
		mf.isDragging = true 
		mf:CreateTimer("fpssavior_drag_timer", 0.02, "FPSSAVIOR_DRAG_TIMER_TICK") 
	end 
end

function FPSSAVIOR_END_DRAG()
    local mf = ui.GetFrame("fpssaviormaster")
    if mf then
        g.settings.displayX = mf:GetX()
        g.settings.displayY = mf:GetY()
        FPSSAVIOR_SAVESETTINGS()
        mf.isDragging = false
        mf:RemoveTimer("fpssavior_drag_timer")
        if _G["MINIMAP_REGION_INFO_SYNC_LAYOUT"] then
            _G["MINIMAP_REGION_INFO_SYNC_LAYOUT"]()
        end
        if ui.GetFrame('fpssaviorconfig') and ui.GetFrame('fpssaviorconfig'):IsVisible() == 1 then
            FPSSAVIOR_CONFIGFRAME()
        end
    end
end

function FPSSAVIOR_SAVECONFIG_GENERIC(parent, control)
    local key = string.gsub(control:GetName(), "box$", "")
    if g.settings[key] ~= nil then
        g.settings[key] = control:IsChecked()
        FPSSAVIOR_SAVESETTINGS()
        FPSSAVIOR_CONFIGFRAME()
        FPSSAVIOR_SHOWORHIDE_OBJ()
    end
end

function FPSSAVIOR_SAVECONFIG_FLASH(parent, control)
    g.settings.hidebossflash = control:IsChecked()
    FPSSAVIOR_SAVESETTINGS()
    FPSSAVIOR_SHOWORHIDE_OBJ()
end

function FPSSAVIOR_SAVECONFIG_LOCK(parent, control)
    g.settings.lock = control:IsChecked()
    local masterFrame = ui.GetFrame("fpssaviormaster")
    if masterFrame ~= nil then
        masterFrame:EnableMove(g.settings.lock == 1 and 0 or 1)
    end
    FPSSAVIOR_SAVESETTINGS()
end

function FPSSAVIOR_DRAG_TIMER_TICK()
    local mf = ui.GetFrame("fpssaviormaster")
    if mf and mf.isDragging == true then
        local mx = mf:GetX()
        local my = mf:GetY()
        
        local infoRail = ui.GetFrame('minimap_region_info_player')
        if infoRail and infoRail:IsVisible() == 1 then
            infoRail:SetOffset(mx, my + mf:GetHeight() + 2)
        end
        
        local cf = ui.GetFrame('fpssaviorconfig')
        if cf and cf:IsVisible() == 1 then
            if my + mf:GetHeight() + cf:GetHeight() <= ui.GetSceneHeight() then
                cf:SetOffset(mx, my + mf:GetHeight() + 2)
            else
                cf:SetOffset(mx, my - cf:GetHeight() - 2)
            end
        end
    end
end

function FPSSAVIOR_SHOWORHIDE_OBJ()
    local currentArea = GetCurrentMapType() 
    local areaMatch = false
    if currentArea == "Town" and g.settings.fx_town == 1 then areaMatch = true
    elseif currentArea == "Field" and g.settings.fx_field == 1 then areaMatch = true
    elseif currentArea == "Raid" and g.settings.fx_raid == 1 then areaMatch = true
    elseif currentArea == "Challenge" and g.settings.fx_challenge == 1 then areaMatch = true end
    
    local cfg = FPSSAVIOR_MODES_CONFIG[g.settings.saviorToggle or 2]
    
    if areaMatch and g.settings.fx_self == 1 then 
        imcperfOnOff.EnableIMCEffect(0) 
        imcperfOnOff.EnableEffect(0) 
        config.EnableOtherPCEffect(0) 
        return 
    end
	
    if areaMatch and currentArea ~= "Town" and g.settings.hidebossflash == 1 then 
        graphic.EnableBloom(0) 
        graphic.EnableGlow(0) 
    end
    
    if cfg then 
        imcperfOnOff.EnableIMCEffect(cfg.imc_fx or 1) 
        imcperfOnOff.EnableEffect(cfg.fx or 1) 
    end

    local targetFXState = (areaMatch and g.settings.fx_others == 1) and 0 or 1
    if g.settings.show_itemdrops == 1 and _G["ITEMDROPS_ACTIVE_TICK"] and imcTime.GetAppTime() < _G["ITEMDROPS_ACTIVE_TICK"] then
        targetFXState = 1
    end
    
    config.EnableOtherPCEffect(targetFXState)
    config.EnableOtherPCDamageEffect(targetFXState)
end

function FPSSAVIOR_ITEMDROP_FORCE(parent, control)
    if g.settings ~= nil then
        g.settings.show_itemdrops = control:IsChecked()
        FPSSAVIOR_SAVESETTINGS()
        FPSSAVIOR_CONFIGFRAME()
        FPSSAVIOR_SHOWORHIDE_OBJ()
    end
end

local buttonClickStartTime = 0

function FPSSAVIOR_BUTTON_DOWN_TIME_CHECK(p, c)
    buttonClickStartTime = imcTime.GetAppTime()
    FPSSAVIOR_START_DRAG()
end

function FPSSAVIOR_BUTTON_UP_TIME_CHECK(p, c)
    if imcTime.GetAppTime() - buttonClickStartTime < 0.20 then
        FPSSAVIOR_OPENCONFIG()
    end
    FPSSAVIOR_END_DRAG()
end
