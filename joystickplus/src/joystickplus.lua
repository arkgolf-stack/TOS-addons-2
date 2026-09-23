local addonName = "JOYSTICKPLUS"
local addonNameLower = string.lower(addonName)
local author = "schale-tos"

_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][author] = _G["ADDONS"][author] or {}
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {}
local g = _G["ADDONS"][author][addonName]

g.configFileLoc = string.format("../addons/%s/config.json", addonNameLower)

g.const = {
	LR_PATTERN_PTR = {"NONE", "L1", "L2", "L1L2", "R1", "L1R1", "L2R1", "L1L2R1", "R2", "L1R2", "L2R2", "L1L2R2", "R1R2", "L1R1R2", "L2R1R2", "L1L2R1R2"},
	LR_PATTERN = function(pattern) for i, val in ipairs(g.const.LR_PATTERN_PTR) do if pattern == val then return i end end end,
	SLOT_CONVERT_TABLE = {L1R1 = 8, L1L2 = 20, L1R2 = 24, L2R2 = 28, L2R1 = 36, R1R2 = 32},
	HOTKEY_FUNCTION = {
		"RESTSIT", "RIDEON", "RIDEOFF", "MAP", "QUESTWARP",
		"CHATMACRO_1", "CHATMACRO_2", "CHATMACRO_3", "CHATMACRO_5", "CHATMACRO_6", "CHATMACRO_7", "CHATMACRO_8", "CHATMACRO_9", "CHATMACRO_0"
	}
}

g.config = {
	enable = false,
	hotkey = {
		SELECT = {
			NONE = "RIDEON",
			L1   = "MAP",
			L2   = "QUESTWARP",
			L1L2 = nil,
			R1   = "CHATMACRO_1",
			L1R1 = nil,
			L2R1 = nil,
			R2   = "RIDEOFF",
			L1R2 = nil,
			L2R2 = nil,
			R1R2 = "RESTSIT"
		}
	}
}

g.hotkeyFunction = {
	RESTSIT     = {l = "@dicID_^*$ETC_20151224_019810$*^", f = function() control.RestSit() end},
	RIDEON      = {l = "@dicID_^*$ETC_20150317_001796$*^", f = function() ON_RIDING_VEHICLE(1) end},
	RIDEOFF     = {l = "@dicID_^*$ETC_20150317_001797$*^", f = function() ON_RIDING_VEHICLE(0) end},
	MAP         = {l = "@dicID_^*$ETC_20150317_001894$*^", f = function() UI_TOGGLE_MAP() end},
	QUESTWARP   = {l = "@dicID_^*$ETC_20150317_001628$*^", f = function() SELECT_QUEST_WARP() end},
	CHATMACRO_1 = {l = "@dicID_^*$ETC_20151001_015214$*^ 1", f = function() EXEC_CHATMACRO(1) end},
	CHATMACRO_2 = {l = "@dicID_^*$ETC_20151001_015214$*^ 2", f = function() EXEC_CHATMACRO(2) end},
	CHATMACRO_3 = {l = "@dicID_^*$ETC_20151001_015214$*^ 3", f = function() EXEC_CHATMACRO(3) end},
	CHATMACRO_4 = {l = "@dicID_^*$ETC_20151001_015214$*^ 4", f = function() EXEC_CHATMACRO(4) end},
	CHATMACRO_5 = {l = "@dicID_^*$ETC_20151001_015214$*^ 5", f = function() EXEC_CHATMACRO(5) end},
	CHATMACRO_6 = {l = "@dicID_^*$ETC_20151001_015214$*^ 6", f = function() EXEC_CHATMACRO(6) end},
	CHATMACRO_7 = {l = "@dicID_^*$ETC_20151001_015214$*^ 7", f = function() EXEC_CHATMACRO(7) end},
	CHATMACRO_8 = {l = "@dicID_^*$ETC_20151001_015214$*^ 8", f = function() EXEC_CHATMACRO(8) end},
	CHATMACRO_9 = {l = "@dicID_^*$ETC_20151001_015214$*^ 9", f = function() EXEC_CHATMACRO(9) end},
	CHATMACRO_0 = {l = "@dicID_^*$ETC_20151001_015214$*^ 0", f = function() EXEC_CHATMACRO(10) end}
}

-- Common
function g.LOAD_CONFIG()
	local acutil = require('acutil')

	if not g.loaded then
		local t, err = acutil.loadJSON(g.configFileLoc, g.config)
		if not err then
			g.config = t;
		end
		g.loaded = true;
	end
end

function g.SAVE_CONFIG()
	local acutil = require('acutil')

	acutil.saveJSON(g.configFileLoc, g.config)
end

function g.PRINT_MESSAGE(msg)
	CHAT_SYSTEM(string.format("[joystick+] %s", msg))
end

function g.CHANGE_RICHTEXT(obj, txt, font, m1, m2, m3, m4)
	local target = tolua.cast(obj, "ui::CRichText")
	target:SetMargin(m1,m2,m3,m4)
	target:SetFontName(font)
	target:SetFormat(txt)
	target:SetText(txt)
end

function g.GET_JOYSTICK_LR()
	local input_L1 = joystick.IsKeyPressed("JOY_BTN_5")
	local input_L2 = joystick.IsKeyPressed("JOY_BTN_7")
	local input_R1 = joystick.IsKeyPressed("JOY_BTN_6")
	local input_R2 = joystick.IsKeyPressed("JOY_BTN_8")

	return (input_L1 * 1) + (input_L2 * 2) + (input_R1 * 4) + (input_R2 * 8) + 1
end

function g.UPDATE_SLOT_SKIN(frame, enable, target)
	local current_skin = frame:GetChildRecursively(target):GetSkinName()

	if enable and current_skin == padslot_offskin then
		frame:GetChildRecursively(target):SetSkinName(padslot_onskin)
	elseif not enable and current_skin == padslot_onskin then
		frame:GetChildRecursively(target):SetSkinName(padslot_offskin)
	end
end

function g.CHANGE_HOTKEY_ASSIGN(id, key, pressedKey, scp, category)
	config.CreateHotKeyElementsForConfig("hotkey_joystick.xml", category)
	local idx = config.GetHotKeyElementIndex("ID", id)
	config.SetHotKeyElementAttributeForConfig(idx, "Key", key)
	config.SetHotKeyElementAttributeForConfig(idx, "PressedKey", pressedKey)
	config.SetHotKeyElementAttributeForConfig(idx, "DownScp", scp)
	config.SaveHotKey("hotkey_joystick.xml")
end

-- View
function g.REMODELING_JOYSTICK_QUICKSLOT(enable)
	local const = {}
	local jsqFrame = ui.GetFrame('joystickquickslot')
	local joystickRestFrame = ui.GetFrame('joystickrestquickslot')
	local monsterQuickslot = ui.GetFrame('monsterquickslot')
	local refreshBtn = jsqFrame:GetChild('refreshBtn')

	const[true]  = {270,120,-330,230,0,"yellow_14_ol","yellow_14_ol","L1+L2","L1+R2","R1+R2","R1+L2","L2+R2",9,11,9,11,1}
	const[false] = {170, 15,-145,  3,1,"yellow_16_ol","yellow_14_ol","L1","L2","R1","R2","L1+R1",20,10,9,11,0}

	jsqFrame:ShowWindow(0)
	jsqFrame:Resize(1920,const[enable][1])
	jsqFrame:GetChild("Set2"):SetOffset(0,const[enable][2])

	refreshBtn:SetMargin(const[enable][3],const[enable][4],0,0)
	refreshBtn:SetGravity(ui.CENTER_HORZ, ui.TOP)
	refreshBtn:ShowWindow(1)

	jsqFrame:GetChild("L2R2"):ShowWindow(const[enable][5])
	jsqFrame:GetChild("L2R2_Set1"):ShowWindow(const[enable][5])
	jsqFrame:GetChild("L2R2_Set2"):ShowWindow(const[enable][5])

	g.CHANGE_RICHTEXT(jsqFrame:GetChildRecursively("L1_Set2"), const[enable][8], const[enable][6], const[enable][13],const[enable][14],0,0)
	g.CHANGE_RICHTEXT(jsqFrame:GetChildRecursively("L2_Set2"), const[enable][9], const[enable][6], const[enable][13],const[enable][14],0,0)
	g.CHANGE_RICHTEXT(jsqFrame:GetChildRecursively("R1_Set2"), const[enable][10], const[enable][6], const[enable][13],const[enable][14],0,0)
	g.CHANGE_RICHTEXT(jsqFrame:GetChildRecursively("R2_Set2"), const[enable][11], const[enable][6], const[enable][13],const[enable][14],0,0)
	g.CHANGE_RICHTEXT(jsqFrame:GetChildRecursively("L1+R1_Set2"), const[enable][12], const[enable][7], const[enable][15],const[enable][16],0,0)

	JOYSTICK_QUICKSLOT_UPDATE_ALL_SLOT();
	jsqFrame:GetChild("Set1"):ShowWindow(1)
	jsqFrame:GetChild("Set2"):ShowWindow(const[enable][17])

	if IsJoyStickMode() == 1 and joystickRestFrame:IsVisible() == 0 and monsterQuickslot:IsVisible() == 0 then
		jsqFrame:ShowWindow(1)
	end

	jsqFrame:Invalidate()
end

-- Hook
function g.UI_MODE_CHANGE_HOOK(index)
	g.UI_MODE_CHANGE(index)
	if index == 1 then
		g.REMODELING_JOYSTICK_QUICKSLOT(true)
	end
end

function g.JOYSTICK_INPUT_HOOK()
	g.JOYSTICK_INPUT()

	if GetChangeUIMode() == 0 then
		local jsqFrame = ui.GetFrame('joystickquickslot')
		jsqFrame:GetChild("Set1"):ShowWindow(1)
		jsqFrame:GetChild("Set2"):ShowWindow(1)
	end
end

function g.UPDATE_JOYSTICK_INPUT_HOOK(frame)
	if IsJoyStickMode() == 0 then
		return;
	end

	local input_LR = g.GET_JOYSTICK_LR()

	g.UPDATE_SLOT_SKIN(frame, input_LR == g.const.LR_PATTERN("L1"),   "L1_slot_Set1")
	g.UPDATE_SLOT_SKIN(frame, input_LR == g.const.LR_PATTERN("L2"),   "L2_slot_Set1")
	g.UPDATE_SLOT_SKIN(frame, input_LR == g.const.LR_PATTERN("L1L2"), "L1_slot_Set2")
	g.UPDATE_SLOT_SKIN(frame, input_LR == g.const.LR_PATTERN("R1"),   "R1_slot_Set1")
	g.UPDATE_SLOT_SKIN(frame, input_LR == g.const.LR_PATTERN("L1R1"), "L1R1_slot_Set1")
	g.UPDATE_SLOT_SKIN(frame, input_LR == g.const.LR_PATTERN("L2R1"), "R2_slot_Set2")
	g.UPDATE_SLOT_SKIN(frame, input_LR == g.const.LR_PATTERN("R2"),   "R2_slot_Set1")
	g.UPDATE_SLOT_SKIN(frame, input_LR == g.const.LR_PATTERN("L1R2"), "L2_slot_Set2")
	g.UPDATE_SLOT_SKIN(frame, input_LR == g.const.LR_PATTERN("L2R2"), "L1R1_slot_Set2")
	g.UPDATE_SLOT_SKIN(frame, input_LR == g.const.LR_PATTERN("R1R2"), "R1_slot_Set2")
end

function g.JOYSTICK_QUICKSLOT_EXECUTE_HOOK(slotIndex)
	local input_LR = g.GET_JOYSTICK_LR()
	local joystickRestFrame = ui.GetFrame('joystickrestquickslot')

	if g.const.SLOT_CONVERT_TABLE[g.const.LR_PATTERN_PTR[input_LR]] ~= nil then
		slotIndex = g.const.SLOT_CONVERT_TABLE[g.const.LR_PATTERN_PTR[input_LR]] + (slotIndex % 4)
	end

	if joystickRestFrame:IsVisible() == 1 then
		REST_JOYSTICK_SLOT_USE(joystickRestFrame, slotIndex);
		return;
	end

	local quickslotFrame = ui.GetFrame('joystickquickslot')

	if quickslotFrame ~= nil and quickslotFrame:IsVisible() == 0 then
		local monsterquickslot = ui.GetFrame('monsterquickslot');
        if monsterquickslot ~= nil and monsterquickslot:IsVisible() == 1 then
            quickslotFrame = monsterquickslot;
        end
    end

	local slot = quickslotFrame:GetChildRecursively("slot"..slotIndex + 1)

	QUICKSLOTNEXPBAR_SLOT_USE(quickSlotFrame, slot, 'None', 0)
end

function g.JOYSTICK_QUICKSLOT_SWAP_HOOK(test)
	local input_LR = g.GET_JOYSTICK_LR()

	if g.config.hotkey.SELECT[g.const.LR_PATTERN_PTR[input_LR]] ~= nil and
	   g.hotkeyFunction[g.config.hotkey.SELECT[g.const.LR_PATTERN_PTR[input_LR]]] ~= nil then
		g.hotkeyFunction[g.config.hotkey.SELECT[g.const.LR_PATTERN_PTR[input_LR]]].f()
	end
end

function g.JOYSTICK_QUICKSLOT_ON_MSG_HOOK(frame, msg, argStr, argNum)
	g["JOYSTICK_QUICKSLOT_ON_MSG"](frame, msg, argStr, argNum)

	if msg == 'RESET_ABILITY_ACTIVE' then
		DebounceScript("JOYSTICK_QUICKSLOT_UPDATE_ALL_SLOT", 0.1, 0);
	end
end

function g.KEYCONFIG_OPEN_CATEGORY_HOOK(frame, fileName, category)
	local bg_ac_key = GET_CHILD(frame, "bg_ac_key")
	local txt_action = GET_CHILD(bg_ac_key, "txt_action")
	local txt_key = GET_CHILD(bg_ac_key, "txt_key")

	if string.find(fileName, "joystick")  == nil then
	--UI_20151001_001813 = action
	--UI_20150729_001735 = key
		txt_action:ResetParamInfo()
		txt_action:SetFormat("{@st45tw2}@dicID_^*$UI_20151001_001813$*^") 
		txt_action:SetText("{@st45tw2}@dicID_^*$UI_20151001_001813$*^")

		txt_key:ResetParamInfo()
		txt_key:SetFormat("{@st45tw2}@dicID_^*$UI_20150729_001735$*^") 
		txt_key:SetText("{@st45tw2}@dicID_^*$UI_20150729_001735$*^")

		g.KEYCONFIG_OPEN_CATEGORY(frame, fileName, category)
	else
		txt_action:ResetParamInfo()
		txt_action:SetFormat("{@st45tw2}@dicID_^*$UI_20150729_001735$*^")
		txt_action:SetText("{@st45tw2}@dicID_^*$UI_20150729_001735$*^")

		txt_key:ResetParamInfo()
		txt_key:SetFormat("{@st45tw2}@dicID_^*$UI_20151001_001813$*^")
		txt_key:SetText("{@st45tw2}@dicID_^*$UI_20151001_001813$*^")

		local bg_key = GET_CHILD(frame, "bg_key")
		local bg_keylist = GET_CHILD(bg_key, "bg_keylist")
		bg_keylist:RemoveAllChild()

		local lr_list = {}
		for i, lr_ptr in ipairs(g.const.LR_PATTERN_PTR) do lr_list[i] = lr_ptr end
		table.sort(lr_list, function(a,b)
			if a == "NONE" or b == "NONE" then
				return a == "NONE"
			elseif #a ~= #b then
				return #a < #b
			else
				return a < b
			end
		end)

		local button = "SELECT"
		for i, lr_ptr in ipairs(lr_list) do
			local ctrl_set = bg_keylist:CreateOrGetControl("controlset", string.format("joystickplus_key_%s_%s", button, lr_ptr), 0, 0, 450, 52)
			local txt_pattern = ctrl_set:CreateOrGetControl("richtext", "txt_pattern", 0, 0, 200, 50)
			local label_line = ctrl_set:CreateOrGetControl("labelline", "label_line", 0, 0, 450, 1)
			local action_list = ctrl_set:CreateOrGetControl("droplist", "action_list", 0, 0, 230, 40)

			ctrl_set:SetMargin(0, i * 52, 0, 0)

			local label = tolua.cast(txt_pattern, "ui::CRichText")
			label:SetMargin(15,15,0,0)
			label:SetFontName("white_16_ol")
			label:SetFormat(string.format(lr_ptr == "NONE" and "{@st42b}SELECT{/}" or "{@st42b}SELECT + %s{/}", lr_ptr))
			label:SetText(string.format(lr_ptr == "NONE" and "SELECT" or "SELECT + %s", lr_ptr))
			label:SetTextAlign("left", "center")

			label_line:SetSkinName("labelline_def")
			label_line:SetMargin(0, 50, 0, 0)

			local drop_list = tolua.cast(action_list, "ui::CDropList")
			drop_list:SetMargin(215, 15, 0, 0)
			drop_list:SetSkinName("droplist_normal")
			drop_list:SetTextAlign("center", "center")
			drop_list:SetOverSound("button_over")
			drop_list:SetClickSound("button_click_big_2")
			drop_list:SetSelectedScp("JOYSTICKPLUS_KEYCONFIG_UPDATE")
			drop_list:ClearItems()

			local selIndex = 0
			drop_list:AddItem(0, "{@st42b}-{/}")
			for j, key in ipairs(g.const.HOTKEY_FUNCTION) do
				drop_list:AddItem(j, string.format("{@st42b}%s{/}", g.hotkeyFunction[key].l))

				if g.config.hotkey.SELECT[lr_ptr] == key then
					selIndex = j
				end
			end
			drop_list:SelectItem(selIndex)
		end

		GBOX_AUTO_ALIGN(bg_keylist, 0, 0, 0, true, true)
		bg_key:UpdateData()
	end
end

function g.KEYCONFIG_RESTORE_DEFAULT_HOOK(parent)
	local frame = parent:GetTopParentFrame();
	local bg_key = GET_CHILD(frame, "bg_key");
	local bg_keylist = GET_CHILD(bg_key, "bg_keylist");
	bg_keylist:RemoveAllChild();

	config.RestoreHotKey("hotkey.xml");
	config.RestoreHotKey("hotkey_mousemode.xml");
	--config.RestoreHotKey("hotkey_joystick.xml");  -- Do not restore joystick hotkey
	ReloadHotKey();
	local keyFrame = ui.GetFrame("quickslotnexpbar");
	QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME(keyFrame);
	keyFrame:Invalidate();

	local fileName = frame:GetUserValue("FILENAME");
	local categoryName = frame:GetUserValue("CATEGORY");
	KEYCONFIG_OPEN_CATEGORY(frame, fileName, categoryName);

	ui.SysMsg(ClMsg("ResetKeyConfig"));
end

-- Apply hook
function g.SETUP_HOOK(enable, target)
	if enable then
		if not g[target] then
			g[target] = _G[target]
		end
		_G[target] = g[target .. "_HOOK"]
	else
		if g[target] then
			_G[target] = g[target]
		end
	end
end

function g.ENABLE_HOOK(enable)
	g.SETUP_HOOK(enable, "UI_MODE_CHANGE")
	g.SETUP_HOOK(enable, "JOYSTICK_INPUT")
	g.SETUP_HOOK(enable, "UPDATE_JOYSTICK_INPUT")
	g.SETUP_HOOK(enable, "JOYSTICK_QUICKSLOT_EXECUTE")
	g.SETUP_HOOK(enable, "JOYSTICK_QUICKSLOT_SWAP")
	g.SETUP_HOOK(enable, "JOYSTICK_QUICKSLOT_ON_MSG")
	g.SETUP_HOOK(enable, "KEYCONFIG_OPEN_CATEGORY")
	g.SETUP_HOOK(enable, "KEYCONFIG_RESTORE_DEFAULT")
end

-- Enable/Disable
function g.ENABLE_JOYSTICKPLUS(enable)
	g.ENABLE_HOOK(enable)
	g.ENABLE_CUSTOM_KEYCONFIG(enable)
	g.REMODELING_JOYSTICK_QUICKSLOT(enable)
	g.config.enable = enable
	g.SAVE_CONFIG()
end

-- Global Action
function JOYSTICKPLUS_SYSTEMOPTION(frame, ctrl, argStr, argNum)
	if ctrl:IsChecked() == 1 then
		g.ENABLE_JOYSTICKPLUS(true)
	else
		g.ENABLE_JOYSTICKPLUS(false)
	end
end

function JOYSTICKPLUS_KEYCONFIG_UPDATE(parent,ctrl)
	local functionName = g.const.HOTKEY_FUNCTION[ctrl:GetSelItemIndex()]
	local button = string.gsub(parent:GetName(), "joystickplus_key_([^_]+)_.+", "%1", 1)
	local lr_ptr = string.gsub(parent:GetName(), "joystickplus_key_.+_([^_]+)", "%1", 1)

	g.config.hotkey[button][lr_ptr] = functionName
	g.SAVE_CONFIG()
end

-- Slash Command
function g.JOYSTICKPLUS_SLASHCOMMAND(command)
	local param = ""
	if #command > 0 then
		local sysopFrame = ui.GetFrame('systemoption')
		local controltype_jpex = sysopFrame:GetChildRecursively("controltype_jpex")
		controltype_jpex = tolua.cast(controltype_jpex, "ui::CCheckBox")

		param = table.remove(command, 1)
		if param == "on" then
			controltype_jpex:SetCheck(1)
			g.ENABLE_JOYSTICKPLUS(true)
			return
		elseif param == "off" then
			controltype_jpex:SetCheck(0)
			g.ENABLE_JOYSTICKPLUS(false)
			return
		end
	end

	g.PRINT_MESSAGE("/joystick+ [on/off]")
end

-- Setting
function g.ADD_SETTING(addon)
	local sysopFrame = ui.GetFrame('systemoption')
	local uiModeBox = sysopFrame:GetChildRecursively("uiModeBox")

	uiModeBox = tolua.cast(uiModeBox, "ui::CGroupBox")
	local controltype_jpex = uiModeBox:CreateOrGetControl("checkbox", "controltype_jpex", 0, 0, 0, 0)
	controltype_jpex = tolua.cast(controltype_jpex, "ui::CCheckBox")
	controltype_jpex:SetText("{@st66b}JoyStick+{/}")
	controltype_jpex:SetGravity(ui.RIGHT, ui.TOP)
	controltype_jpex:SetMargin(0, 0, 0, 0)
	controltype_jpex:SetEventScript(ui.LBUTTONUP, "JOYSTICKPLUS_SYSTEMOPTION")

	if g.config.enable == true then
		controltype_jpex:SetCheck(1)
		addon:RegisterMsg("GAME_START_3SEC", "JOYSTICKPLUS_INIT")
	else
		controltype_jpex:SetCheck(0)
	end
end

function g.ENABLE_CUSTOM_KEYCONFIG(enable)
	local keyconfigFrame = ui.GetFrame('keyconfig')
	local tree = GET_CHILD(keyconfigFrame, "tree")

	if enable then
		-- Apply Custom KeyConfig
		if not GET_CHILD(tree, "joystickplus") then
			tree:Add(tree:CreateOrGetControlSet("keyconfig_tree", "joystickplus", 0, 0))
		end

		INIT_KEYCONFIG_CATEGORY(tree, "joystickplus", "joypad_img")
		local htreeitem = tree:FindByName("joystickplus");
		local key = "hotkey_joystick.xml#Basic";
		tree:Add(htreeitem, "{@st42b}" .. ScpArgMsg("DefaultMove"), key, "{#000000}")
		tree:OpenNodeAll()

		g.CHANGE_HOTKEY_ASSIGN("QuickSlotSwap1", "JOY_BTN_9", "None", "JOYSTICK_QUICKSLOT_SWAP(1)", "Basic")
		g.CHANGE_HOTKEY_ASSIGN("QuickSlotSwap2", "None", "None", "None", "Basic")
		g.CHANGE_HOTKEY_ASSIGN("Map", "None", "None", "None", "Basic")
		g.CHANGE_HOTKEY_ASSIGN("WarpQuest", "None", "None", "None", "Basic")
		g.CHANGE_HOTKEY_ASSIGN("RideOn", "None", "None", "None", "Basic")
		g.CHANGE_HOTKEY_ASSIGN("RideOff", "None", "None", "None", "Basic")
		g.CHANGE_HOTKEY_ASSIGN("ToggleRest", "None", "None", "None", "Battle")
	else
		-- Apply Default KeyConfig
		local selectedNode = tree:GetLastSelectedNode()
		if selectedNode ~= nil and string.find(selectedNode:GetValue(), "joystick")  ~= nil then
			local bg_key = GET_CHILD(keyconfigFrame, "bg_key");
			local bg_keylist = GET_CHILD(bg_key, "bg_keylist");
			bg_keylist:RemoveAllChild();
		end
		tree:Delete(tree:FindByName("joystickplus"))
		config.RestoreHotKey("hotkey_joystick.xml")
		ReloadHotKey()


		local bg_ac_key = GET_CHILD(keyconfigFrame, "bg_ac_key")
		local txt_action = GET_CHILD(bg_ac_key, "txt_action")
		local txt_key = GET_CHILD(bg_ac_key, "txt_key")

		txt_action:ResetParamInfo()
		txt_action:SetFormat("{@st45tw2}@dicID_^*$UI_20151014_001811$*^")
		txt_action:SetText("{@st45tw2}@dicID_^*$UI_20151014_001811$*^")

		txt_key:ResetParamInfo()
		txt_key:SetFormat("{@st45tw2}@dicID_^*$UI_20150729_001735$*^")
		txt_key:SetText("{@st45tw2}@dicID_^*$UI_20150729_001735$*^")
	end
end

-- Init
function JOYSTICKPLUS_INIT()
	g.ENABLE_JOYSTICKPLUS(true)
end

function JOYSTICKPLUS_ON_INIT(addon, frame)
	local acutil = require('acutil')

	g.LOAD_CONFIG()

	acutil.slashCommand("/joystick+", g.JOYSTICKPLUS_SLASHCOMMAND)

	g.ADD_SETTING(addon)
end

-- load message
g.PRINT_MESSAGE("JoyStick+ Addon is loaded.")
