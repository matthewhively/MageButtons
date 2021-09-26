-- debug, set debug level
-- 0: no debug, 1: minimal, 2: all
local debug = 0

local _, playerClass = UnitClass("player")
if playerClass ~= "MAGE" then
	print("MageButtons disabled, you are not a mage :(")
	return 0
end

local AceGUI = LibStub("AceGUI-3.0")
MageButtons = LibStub("AceAddon-3.0"):NewAddon("MageButtons", "AceEvent-3.0")
local addonName, addon = ...
local ldb = LibStub("LibDataBroker-1.1")
local channel = "RAID"
local MageButtonsMinimapIcon = LibStub("LibDBIcon-1.0")
local db
local castTable = {}
local lockStatus = 1

_G[addonName] = addon
addon.healthCheck = true


-- Add entries to keybinds page
BINDING_HEADER_MAGEBUTTONS = "MageButtons"
BINDING_NAME_MAGEBUTTONS_BUTTON1 = "Button 1"
BINDING_NAME_MAGEBUTTONS_BUTTON2 = "Button 2"
BINDING_NAME_MAGEBUTTONS_BUTTON3 = "Button 3"
BINDING_NAME_MAGEBUTTONS_BUTTON4 = "Button 4"
BINDING_NAME_MAGEBUTTONS_BUTTON5 = "Button 5"
BINDING_NAME_MAGEBUTTONS_BUTTON6 = "Button 6"

-- Saved Variables
MageButtonsDB = {}
if MageButtonsDB == nil then
	MageButtonsDB["position"] = {}
	MageButtonsDB["water"] = {}
	MageButtonsDB["food"] = {}
	MageButtonsDB["teleport"] = {}
	MageButtonsDB["portal"] = {}
	MageButtonsDB["managem"] = {}
	MageButtonsDB["ai"] = {}
end


-- slash commands
SlashCmdList["MAGEBUTTONS"] = function(inArgs)

	local wArgs = strtrim(inArgs)
	if wArgs == "" then
		print("usage: /magebuttons lock|move|unlock")
	elseif wArgs == "minimap 1" or wArgs == "minimap 0" then
		cmdarg, tog = string.split(" ", wArgs)
		MageButtons:maptoggle(tog)
	elseif wArgs == "move" or wArgs == "unlock" then
		print("NYI")
	elseif wArgs == "lock" then
		print("NYI")
	else
		print("usage: /MageButtons lock|move|unlock")
	end

end
SLASH_MAGEBUTTONS1 = "/magebuttons"

-- Set some default values
local xOffset = 0
local yOffset = 0
local totalHeight, totalWidth, backdropPadding = 0, 0, 5
local backdropAnchor = "TOP"
local backdropParentAnchor = "BOTTOM"
--local backdropOffset = 0
local frameBG = "Interface\\ChatFrame\\ChatFrameBackground"


------------------
--- Main frame ---
------------------
MageButtonsConfig = CreateFrame("Frame", "MageButtonsFrame", UIParent)
MageButtonsConfig:SetMovable(false)
MageButtonsConfig:EnableMouse(false)
MageButtonsConfig:RegisterForDrag("LeftButton")
MageButtonsConfig:SetScript("OnDragStart", MageButtonsConfig.StartMoving)
MageButtonsConfig:SetScript("OnDragStop", MageButtonsConfig.StopMovingOrSizing)
MageButtonsConfig:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
MageButtonsConfig:SetSize(40, 10)
-- SetPoint is done after ADDON_LOADED

MageButtonsFrame.texture = MageButtonsFrame:CreateTexture(nil, "BACKGROUND")
MageButtonsFrame.texture:SetAllPoints(MageButtonsFrame)
MageButtonsFrame:SetBackdrop({bgFile = [[Interface\ChatFrame\ChatFrameBackground]]})
MageButtonsFrame:SetBackdropColor(0, 0, 0, 0)


--------------
--- Events ---
--------------
local function onevent(self, event, arg1, ...)
	--print(event)
	
	-- Stuff to do after addon is loaded
	if(event == "ADDON_LOADED" and arg1 == "MageButtons") then	

		-- Needs a slight delay on initial startup, don't know why
		C_Timer.After(1, function()
			local buttonTypes = { "Water", "Food", "Teleports", "Portals", "Gems", "Polymorph"}
			
			-- Set up lists of spells
			WaterSpells = {5504, 5505, 5506, 6127, 10138, 10139, 10140}
			FoodSpells = {587, 597, 990, 6129, 10144, 10145, 28612}
			TelportsSpells = {}
			PortalsSpells = {}
			if UnitFactionGroup("player") == "Alliance" then
				TeleportsSpells = {3565, 3561, 3562}
				PortalsSpells = {11419, 10059, 11416}
			else
				TeleportsSpells = {3566, 3563, 3567}
				PortalsSpells = {11420, 11418, 11417}
			end
			GemsSpells = {759, 3552, 10053, 10054}
			
			if IsSpellKnown(12826) then sheep = 12826
			elseif IsSpellKnown(12825) then sheep = 12825
			elseif IsSpellKnown(12824) then sheep = 12824
			elseif IsSpellKnown(118) then sheep = 118 end
			PolymorphSpells = {sheep, 28272, 28271, 28270}
			
			----------------------------------------
			-- Create tables from the spell lists --
			----------------------------------------
			for k = 1, #buttonTypes, 1 do
				local btnType = buttonTypes[k]
				
				-- For each type of spell in buttonTypes table
				--   get number of spells
				--   create table of that type with spells that are known (trained)
				if btnType ~= nil and btnType ~= "none" then
					local obj2 = btnType .. [[Table = {}
					for i = 1, #]] .. btnType .. [[Spells, 1 do
						if IsSpellKnown(]] .. btnType .. [[Spells[i]) then
							local ]] .. btnType .. [[Name = GetSpellInfo(]] .. btnType .. [[Spells[i]) .. "(" .. GetSpellSubtext(]] .. btnType .. [[Spells[i]) .. ")"
							--]] .. btnType .. [[Table[i] = ]] .. btnType .. [[Name
							table.insert(]] .. btnType .. [[Table, ]] .. btnType .. [[Name)
						end
					end	]]
					
					-- execute the above command
					local cmdRun2 = assert(loadstring(obj2))
					cmdRun2()
				end
			end
			
			-- Get saved frame location
			local relPoint, anchorX, anchorY = addon:getAnchorPosition()
			MageButtonsConfig:ClearAllPoints()
			MageButtonsConfig:SetPoint(relPoint, UIParent, relPoint, anchorX, anchorY)
			
			-- Pull items from Saved Variables
			growthDir = addon:getSV("growth", "direction") or "Horizontal"
			menuDir = addon:getSV("growth", "buttons") or "Up"
			btnSize = addon:getSV("buttonSettings", "size") or 26
			padding = addon:getSV("buttonSettings", "padding") or 5
			border = addon:getSV("borderStatus", "borderStatus") or 1
			backdropPadding = addon:getSV("buttonSettings", "bgpadding") or 2.5
			backdropRed = addon:getSV("bgcolor", "red") or .1
			backdropGreen = addon:getSV("bgcolor", "green") or .1
			backdropBlue = addon:getSV("bgcolor", "blue") or .1
			backdropAlpha = addon:getSV("bgcolor", "alpha") or 1

			------------------
			-- Base Buttons --
			------------------
			local baseSpells = { Water = WaterTable[#WaterTable], Food = FoodTable[#FoodTable], Teleports = TeleportsTable[#TeleportsTable], Portals = PortalsTable[#PortalsTable], Gems = GemsTable[#GemsTable], Polymorph = PolymorphTable[#PolymorphTable]}
			local spellCounts = {Water = #WaterTable, Food = #FoodTable, Teleports = #TeleportsTable, Portals = #PortalsTable, Gems = #GemsTable, Polymorph = #PolymorphTable}
			local createButtonMenu = {addon:getSV("buttons", "a") or buttonTypes[1], addon:getSV("buttons", "b") or buttonTypes[2], 
									  addon:getSV("buttons", "c") or buttonTypes[3], addon:getSV("buttons", "d") or buttonTypes[4], 
									  addon:getSV("buttons", "e") or buttonTypes[5], addon:getSV("buttons", "f") or buttonTypes[6]}

			-- These store the menu state for each button (0 = closed, 1 = open)
			WaterMenu, FoodMenu, TeleportsMenu, PortalsMenu, GemsMenu, PolymorphMenu = 0, 0, 0, 0, 0, 0

			local j = 0
			for j = 1, #createButtonMenu, 1 do
				--createItem = createButtonMenu[j]
				local btnType = createButtonMenu[j]
				local baseSpell = baseSpells[btnType]
				local spellCount = spellCounts[btnType]
				--local keybind = "U"

				if baseSpell ~= nil and baseSpell ~= "none" then
					--keybind = GetBindingKey("MAGEBUTTONS_BUTTON1")
					--print(keybind)
				
					-- The lines below are executed as a single command to create the initial/base buttons
					--   Create a button (from a spell in the corresponding spell table)
					--   Set its left click and right click actions
					--   Set its position, size and icon
					--   Create a backdrop

					local obj = btnType .. [[Button0 = CreateFrame("Button", "]] .. btnType .. [[Button0", MageButtonsConfig, "SecureActionButtonTemplate");
					]] .. btnType .. [[Button0:RegisterForClicks("LeftButtonDown", "RightButtonDown")
					]] .. btnType .. [[Button0:SetAttribute("*type1", "spell");
					]] .. btnType .. [[Button0:SetAttribute("spell", "]]  .. baseSpell .. [[");
					--print(GetBindingKey("MAGEBUTTONS_BUTTON]] .. j .. [["))
					if GetBindingKey("MAGEBUTTONS_BUTTON]] .. j .. [[") ~= nil then
						--print("bound")
						keybind = GetBindingKey("MAGEBUTTONS_BUTTON]] .. j .. [[")
						SetBindingClick(keybind, ]] .. btnType .. [[Button0:GetName());
					else
						 
						--print("not bound")
					end
					]] .. btnType .. [[Button0:SetScript("PostClick", function(self, button)
						if button == "RightButton" then
							if ]] .. btnType .. [[Menu == 0 then
								MageButtons:showButtons("]] .. btnType .. [[", ]] .. spellCount .. [[)
								]] .. btnType .. [[Menu = 1
							else
								MageButtons:hideButtons("]] .. btnType .. [[", ]] .. spellCount .. [[)
								]] .. btnType .. [[Menu = 0
							end
						else
							MageButtons:hideButtons("]] .. btnType .. [[", ]] .. spellCount .. [[)
							]] .. btnType .. [[Menu = 0
						end
					end)

					]] .. btnType .. [[Button0:SetPoint("TOP", MageButtonsFrame, "BOTTOM", ]] .. xOffset .. [[, ]] .. yOffset .. [[)
					]] .. btnType .. [[Button0:SetSize(]] .. btnSize .. [[, ]] .. btnSize .. [[)
					]] .. btnType .. [[Button0.t =]]  .. btnType .. [[Button0:CreateTexture(nil, "BACKGROUND")
					local _, _, buttonTexture = GetSpellInfo("]] .. baseSpell .. [[")
					]] .. btnType .. [[Button0.t:SetTexture(buttonTexture)
					
					if ]] .. border .. [[ == 1 then
						]] .. btnType .. [[Button0.t:SetTexCoord(0.1,0.9,0.1,0.9)
					end
					]] .. btnType .. [[Button0.t:SetAllPoints()


					
					local ]] .. btnType .. [[Button0Backdrop= CreateFrame("Frame", "]] .. btnType .. [[Button0BackdropFrame", UIParent)
					]] .. btnType .. [[Button0Backdrop:SetPoint("CENTER", ]] .. btnType .. [[Button0, "CENTER", 0, 0)
					]] .. btnType .. [[Button0Backdrop:SetSize(]] .. btnSize .. [[ + ]] .. backdropPadding .. [[ * 2, ]] .. btnSize .. [[ + ]] .. backdropPadding .. [[ * 2)

					]] .. btnType .. [[Button0BackdropFrame.texture = ]] .. btnType .. [[Button0BackdropFrame:CreateTexture(nil, "BACKGROUND")
					]] .. btnType .. [[Button0BackdropFrame.texture:SetAllPoints(]] .. btnType .. [[Button0BackdropFrame)
					]] .. btnType .. [[Button0BackdropFrame:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
					]] .. btnType .. [[Button0BackdropFrame:SetBackdropColor(]] .. backdropRed .. [[, ]] .. backdropGreen .. [[, ]] .. backdropBlue .. [[, ]] .. backdropAlpha .. [[)
					
					]] .. btnType .. [[Button0:Show()]]

					
					-- execute the above command
					local cmdRun = assert(loadstring(obj))
					cmdRun()
					

					
					-- Determine the growth criteria based on user settings
					if growthDir == "Vertical" then
						yOffset = yOffset - (btnSize + padding)
						totalHeight = -(yOffset - backdropPadding)
						totalWidth = btnSize + backdropPadding + backdropPadding
						xOffset = 0
					elseif growthDir == "Horizontal" then
						yOffset = 0
						xOffset = xOffset + (btnSize + padding)
						totalHeight = btnSize + backdropPadding + backdropPadding
						totalWidth = xOffset + backdropPadding
						backdropAnchor = "TOPLEFT"
						backdropParentAnchor = "BOTTOM"
						--backdropOffset = -(btnSize / 2 + backdropPadding)
					else
						print("MageButtons: Invalid growth direction")
					end
				end
				
			end
			

			-- Create the menu buttons for each spell type
			MageButtons:makeButtons("Water", WaterTable)
			MageButtons:makeButtons("Food", FoodTable)
			MageButtons:makeButtons("Teleports", TeleportsTable)
			MageButtons:makeButtons("Portals", PortalsTable)
			MageButtons:makeButtons("Gems", GemsTable)
			MageButtons:makeButtons("Polymorph", PolymorphTable)
			
			
			-----------------
			-- Data Broker --
			-----------------
			local lockStatus = addon:getSV("framelock", "lock")
			
			db = LibStub("AceDB-3.0"):New("MageButtonsDB", SettingsDefaults)
			MageButtonsDB.db = db;
			MageButtonsMinimapData = ldb:NewDataObject("MageButtons",{
				type = "data source",
				text = "MageButtons",
				icon = "Interface/Icons/Spell_Holy_MagicalSentry.blp",
				OnClick = function(self, button)
					if button == "RightButton" then
						if IsShiftKeyDown() then
							MageButtons:maptoggle("0")
							print("MageButtons: Hiding icon, re-enable with: /MageButtons minimap 1")
						else
							InterfaceOptionsFrame_OpenToCategory(mbPanel)
							InterfaceOptionsFrame_OpenToCategory(mbPanel)
							InterfaceOptionsFrame_OpenToCategory(mbPanel)
						end
					
					elseif button == "LeftButton" then
						if lockStatus == 0 then
							-- Not locked, lock it and save the anchor position
							MageButtonsConfig:SetMovable(false)
							MageButtonsConfig:EnableMouse(false)
							MageButtonsFrame:SetBackdropColor(0, 0, 0, 0)

							local _, _, relativePoint, xPos, yPos = MageButtonsConfig:GetPoint()
							addon:setAnchorPosition(relativePoint, xPos, yPos)
							lockStatus = 1
						else
							-- locked, unlock
							MageButtonsConfig:SetMovable(true)
							MageButtonsConfig:EnableMouse(true)
							MageButtonsFrame:SetBackdropColor(0, .7, 1, 1)
							lockStatus = 0
						end
					end
				end,
				
				-- Minimap Icon tooltip
				OnTooltipShow = function(tooltip)
					tooltip:AddLine("|cffffffffMageButtons|r\nLeft-click to lock/unlock.\nRight-click to hide minimap button.")
				end,
			})
			
			-- display the minimap icon?
			if mmap == 1 then
				MageButtonsMinimapIcon:Register("mageButtonsIcon", MageButtonsMinimapData, MageButtonsDB)
				addon:maptoggle(1)
			else
				addon:maptoggle(0)
			end
		end); --end of 1 second delay
	end
end

-------------------------------
--- Minimap toggle function ---
-------------------------------
function addon:maptoggle(mtoggle)
	if ( debug == 1 ) then print("icon state: " .. mtoggle) end
	
	local mmTbl = {
		icon = mtoggle
	}
	
	MageButtonsDB["minimap"] = mmTbl
	
	if mtoggle == "0" then
		if ( debug >= 1 ) then print("hiding icon") end
		MageButtonsMinimapIcon:Hide("mageButtonsIcon")
	else
		if (MageButtonsMinimapIcon:IsRegistered("mageButtonsIcon")) then
			MageButtonsMinimapIcon:Show("mageButtonsIcon")
		else
			MageButtonsMinimapIcon:Register("mageButtonsIcon", MageButtonsMinimapData, MageButtonsDB)
			MageButtonsMinimapIcon:Show("mageButtonsIcon")
		end
	end
end

------------------------------
-- Retrieve anchor position --
------------------------------
function addon:getAnchorPosition()

	local posTbl = MageButtonsDB["position"]
	if posTbl == nil then
		return "CENTER", 200, -200
	else
		-- Table exists, get the value if it is defined
		relativePoint = posTbl["relativePoint"] or "CENTER"
		xPos = posTbl["xPos"] or 200
		yPos = posTbl["yPos"] or -200
		return relativePoint, xPos, yPos
	end
end

--------------------------
-- Save anchor position --
--------------------------
function addon:setAnchorPosition(relativePoint, xPos, yPos)
	posTbl = {
		relativePoint = relativePoint,
		xPos = xPos,
		yPos = yPos,
	}

	MageButtonsDB["position"] = posTbl
	
	--MageButtonsConfig:SetPoint("CENTER", xPos, yPos)
end

-----------------------
-- Make menu buttons --
-----------------------
function addon:makeButtons(btnType, typeTable)
	-- Create buttons of the requested type
	-- type = Portal, Water, etc
	-- typeTable = table of values from the start of this file (WaterTable, etc)
	-- i = index to define uniqe button names (PortalsButton1, PortalsButton2, etc)
	local btnAnchor = nil
	local parentAnchor = nil
	local xOffset = 0
	local yOffset = 0

	if menuDir == "Down" then
		--yOffset = yOffset - (btnSize + padding)
		btnAnchor = "TOP"
		parentAnchor = "BOTTOM"
		yOffset = -padding
	elseif menuDir == "Up" then
		--yOffset = yOffset + (btnSize + padding)
		btnAnchor = "BOTTOM"
		parentAnchor = "TOP"
		yOffset = padding
	elseif menuDir == "Right" then
		--xOffset = xOffset + (btnSize + padding)
		btnAnchor = "LEFT"
		parentAnchor = "RIGHT"
		xOffset = padding
	elseif menuDir == "Left" then
		--yOffset = 0
		--xOffset = xOffset - (btnSize + padding)	
		btnAnchor = "RIGHT"
		parentAnchor = "LEFT"
		xOffset = -padding
	else
		print("MageButtons: Invalid growth direction")
	end
	
	local i
	for i = 1, #typeTable, 1 do
		if typeTable[i] ~= nil then
			-- everything below is one command:
			--   creates button, positions it next to the previous button, sets its OnClick to make the main button perform the new spell, 
			--   updates the texture of the main button, hides all but the main button

			local obj = btnType .. [[Button]] .. i .. [[ = CreateFrame("Button", "]] .. btnType .. [[Button]] .. i .. [[", MageButtonsConfig)
			]] .. btnType .. [[Button]] .. i .. [[:SetPoint("]] .. btnAnchor .. [[", ]] .. btnType .. [[Button]] .. i-1 .. [[, "]] .. parentAnchor .. [[", ]] .. xOffset .. [[, ]] .. yOffset .. [[)
			]] .. btnType .. [[Button]] .. i .. [[:SetSize(]] .. btnSize .. [[, ]] .. btnSize .. [[)
			]] .. btnType .. [[Button]] .. i .. [[:SetScript("OnClick", function()
				MageButtons:hideButtons("]] .. btnType .. [[", ]] .. #typeTable .. [[)
				]] .. btnType .. [[Button0:SetAttribute("spell", "]] .. typeTable[i] .. [[")
				local _, _, buttonTexture = GetSpellInfo("]] .. typeTable[i] .. [[")
				]] .. btnType .. [[Button0.t:SetTexture(buttonTexture)
				]] .. btnType .. [[Button0.t:SetAllPoints()
			end)
			
			]] .. btnType .. [[Button]] .. i .. [[.t = ]] .. btnType .. [[Button]] .. i .. [[:CreateTexture(nil, "BACKGROUND")
			local _, _, buttonTexture = GetSpellInfo("]] .. typeTable[i] .. [[")
			]] .. btnType .. [[Button]] .. i .. [[.t:SetTexture(buttonTexture)
			if ]] .. border .. [[ == 1 then
				]] .. btnType .. [[Button]] .. i .. [[.t:SetTexCoord(0.1,0.9,0.1,0.9)
			end
			]] .. btnType .. [[Button]] .. i .. [[.t:SetAllPoints()
			
			
			local ]] .. btnType .. [[Button]] .. i .. [[Backdrop= CreateFrame("Frame", "]] .. btnType .. [[Button]] .. i .. [[BackdropFrame", UIParent)
			]] .. btnType .. [[Button]] .. i .. [[Backdrop:SetPoint("CENTER", ]] .. btnType .. [[Button]] .. i .. [[, "CENTER", 0, 0)
			]] .. btnType .. [[Button]] .. i .. [[Backdrop:SetSize(]] .. btnSize .. [[ + ]] .. backdropPadding .. [[ * 2, ]] .. btnSize .. [[ + ]] .. padding .. [[ * 1)

			]] .. btnType .. [[Button]] .. i .. [[BackdropFrame.texture = ]] .. btnType .. [[Button]] .. i .. [[BackdropFrame:CreateTexture(nil, "BACKGROUND")
			]] .. btnType .. [[Button]] .. i .. [[BackdropFrame.texture:SetAllPoints(]] .. btnType .. [[Button]] .. i .. [[BackdropFrame)
			]] .. btnType .. [[Button]] .. i .. [[BackdropFrame:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
			]] .. btnType .. [[Button]] .. i .. [[BackdropFrame:SetBackdropColor(]] .. backdropRed .. [[, ]] .. backdropGreen .. [[, ]] .. backdropBlue .. [[, ]] .. backdropAlpha .. [[)
		
			]] .. btnType .. [[Button]] .. i .. [[BackdropFrame:Hide()
			]] .. btnType .. [[Button]] .. i .. [[:Hide()]]
			
			-- execute the above as a single command
			local cmdRun = assert(loadstring(obj))
			cmdRun()
		end
	end
end

function addon:showButtons(btnType, count)
	for i = 1, count, 1 do
		local obj = btnType .. [[Button]] .. i .. [[:Show()
		]] .. btnType .. [[Button]] .. i .. [[BackdropFrame:Show()]]
		
		local cmdRun = assert(loadstring(obj))
		cmdRun()
	end
end

function addon:hideButtons(btnType, count)
	for i = 1, count, 1 do
		local obj = btnType .. [[Button]] .. i .. [[:Hide()
		]] .. btnType .. [[Button]] .. i .. [[BackdropFrame:Hide()]]
		
		local cmdRun = assert(loadstring(obj))
		cmdRun()
	end
end

-- Function to retrieve Saved Variables
function addon:getSV(category, variable)
	local vartbl = MageButtonsDB[category]
	
	if vartbl == nil then
		vartbl = {}
	end
	
	if ( vartbl[variable] ~= nil ) then
		--print("getSV - " .. variable .. ": " .. vartbl[variable])
		return vartbl[variable]
	else
		return nil
	end
end

function addon:getButtonType(btnNumber)
	local buttontbl = MageButtonsDB["buttons"]
	if ( buttontbl[btnNumber] == "none" ) then
		return "none"
	else
		return buttontbl[btnNumber]
	end
end

-- Register Events
MageButtonsConfig:RegisterEvent("ADDON_LOADED")
MageButtonsConfig:SetScript("OnEvent", onevent)