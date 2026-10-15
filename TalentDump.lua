--------------------------------------------------
-- TalentDump (Vanilla 1.12 / Vanilla+)
-- Minimap → panel with checkboxes → dump window (Ctrl+A / Ctrl+C)
-- Authors: Grok, Rodina
--------------------------------------------------

TalentDumpDB = TalentDumpDB or {}

local OPTION_KEYS = {
	"equipment",
	"talentsTaken",
	"talentsFull",
	"bcs",
	"bags",
	"bank",
	"spellbook",
	"trainer",
}

local OPTION_LABELS = {
	equipment   = "Equipment",
	talentsTaken = "Talents (taken)",
	talentsFull = "Talents (full tree)",
	bcs         = "BCS stats",
	bags        = "Bags",
	bank        = "Bank",
	spellbook   = "Spellbook",
	trainer     = "Trainer (open)",
}

local function EnsureDB()
	if TalentDumpDB.equipment == nil then TalentDumpDB.equipment = true end
	if TalentDumpDB.talentsTaken == nil then TalentDumpDB.talentsTaken = true end
	if TalentDumpDB.talentsFull == nil then TalentDumpDB.talentsFull = true end
	if TalentDumpDB.bcs == nil then TalentDumpDB.bcs = true end
	if TalentDumpDB.bags == nil then TalentDumpDB.bags = false end
	if TalentDumpDB.bank == nil then TalentDumpDB.bank = false end
	if TalentDumpDB.spellbook == nil then TalentDumpDB.spellbook = false end
	if TalentDumpDB.trainer == nil then TalentDumpDB.trainer = false end
	-- migrate old keys if present
	if TalentDumpDB.includeBags ~= nil then
		TalentDumpDB.bags = TalentDumpDB.includeBags and true or false
		TalentDumpDB.includeBags = nil
	end
	if TalentDumpDB.includeBank ~= nil then
		TalentDumpDB.bank = TalentDumpDB.includeBank and true or false
		TalentDumpDB.includeBank = nil
	end
end

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function Append(output, line)
	output[table.getn(output) + 1] = line
end

local function AppendLines(output, lines)
	if not lines then return end
	local i = 1
	while i <= table.getn(lines) do
		Append(output, lines[i])
		i = i + 1
	end
end

local function ReadTooltipLines()
	local name = GameTooltip:GetName()
	local result = {}
	local i = 1
	while i <= GameTooltip:NumLines() do
		local left = getglobal(name .. "TextLeft" .. i)
		if left then
			local text = left:GetText()
			if text and text ~= "" then
				result[table.getn(result) + 1] = text
			end
		end
		i = i + 1
	end
	GameTooltip:Hide()
	return result
end

local function GetTalentTooltip(tab, talent)
	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	GameTooltip:SetTalent(tab, talent)
	return ReadTooltipLines()
end

local function GetItemTooltipText(slot)
	local link = GetInventoryItemLink("player", slot)
	if not link then return nil end
	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	GameTooltip:SetInventoryItem("player", slot)
	return ReadTooltipLines()
end

local function GetSpellTooltip(spellIndex)
	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	GameTooltip:SetSpell(spellIndex, BOOKTYPE_SPELL)
	return ReadTooltipLines()
end

local function QualityFromLink(link)
	if not link then return "Unknown" end
	if string.find(link, "|cffa335ee") then return "Epic"
	elseif string.find(link, "|cff0070dd") then return "Rare"
	elseif string.find(link, "|cff1eff00") then return "Uncommon"
	elseif string.find(link, "|cffffffff") then return "Common"
	elseif string.find(link, "|cff9d9d9d") then return "Poor"
	elseif string.find(link, "|cffff8000") then return "Legendary"
	else return "Unknown" end
end

local function ExtractItemID(link)
	if not link then return "?" end
	local id = string.gsub(link, ".*item:(%d+):.*", "%1")
	if id == link then return "?" end
	return id
end

local function ExtractItemName(link)
	if not link then return "?" end
	local name = GetItemInfo(link)
	if name then return name end
	name = string.gsub(link, ".*%[(.-)%].*", "%1")
	if name and name ~= link then return name end
	return "?"
end

local function GetBagName(bag)
	if bag == 0 then return "Backpack" end
	local invSlot = bag + 19
	local link = GetInventoryItemLink("player", invSlot)
	if link then
		local name = ExtractItemName(link)
		if name and name ~= "?" then return name end
	end
	return "Bag " .. bag
end

local function DumpContainer(output, bag, header)
	local numSlots = GetContainerNumSlots(bag) or 0
	if numSlots == 0 then return end
	Append(output, "--- " .. header .. " (bag " .. bag .. ") ---")
	local free = 0
	local slot = 1
	while slot <= numSlots do
		local texture, itemCount = GetContainerItemInfo(bag, slot)
		local link = GetContainerItemLink(bag, slot)
		if link then
			local name = ExtractItemName(link)
			local id = ExtractItemID(link)
			local q = QualityFromLink(link)
			Append(output, string.format("  %dx %s | id:%s | %s", itemCount or 1, name, id, q))
		else
			free = free + 1
		end
		slot = slot + 1
	end
	Append(output, "  Free slots: " .. free .. " / " .. numSlots)
end

local function IsBankOpen()
	if BankFrame and BankFrame:IsVisible() then return true end
	if pfUI and pfUI.bag and pfUI.bag.left and pfUI.bag.left:IsVisible() then return true end
	local pfBank = getglobal("pfBank")
	if pfBank and pfBank:IsVisible() then return true end
	return false
end

--------------------------------------------------
-- Section builders
--------------------------------------------------

local function BuildEquipment(output)
	Append(output, "================================")
	Append(output, "EQUIPMENT DUMP")
	Append(output, "================================")
	Append(output, "")
	local slot = 1
	while slot <= 19 do
		local itemLines = GetItemTooltipText(slot)
		if itemLines then
			Append(output, "--- Slot " .. slot .. " ---")
			AppendLines(output, itemLines)
			Append(output, "")
		end
		slot = slot + 1
	end
end

local function BuildTalentsTaken(output)
	Append(output, "================================")
	Append(output, "TALENT DUMP (taken only)")
	Append(output, "================================")
	Append(output, "")
	local tabs = GetNumTalentTabs() or 0
	local tab = 1
	while tab <= tabs do
		local tabName, _, pointsSpent = GetTalentTabInfo(tab)
		Append(output, "TREE: " .. (tabName or ("Tab " .. tab)) .. "  [" .. (pointsSpent or 0) .. " pts]")
		Append(output, "--------------------------------")
		local talents = GetNumTalents(tab) or 0
		local talent = 1
		while talent <= talents do
			local name, _, tier, column, rank, maxRank = GetTalentInfo(tab, talent)
			if rank and rank > 0 then
				Append(output, "Talent: " .. (name or "?") .. " (" .. rank .. "/" .. maxRank .. ")  [tier " .. (tier or "?") .. "]")
				AppendLines(output, GetTalentTooltip(tab, talent))
				Append(output, "")
			end
			talent = talent + 1
		end
		tab = tab + 1
	end
end

local function BuildTalentsFull(output)
	Append(output, "================================")
	Append(output, "FULL TALENT TREE (all talents)")
	Append(output, "================================")
	Append(output, "Format: Name (rank/maxRank) [tier X, col Y]")
	Append(output, "")
	local tabs = GetNumTalentTabs() or 0
	local tab = 1
	while tab <= tabs do
		local tabName, _, pointsSpent = GetTalentTabInfo(tab)
		Append(output, "### TREE: " .. (tabName or ("Tab " .. tab)) .. "  [" .. (pointsSpent or 0) .. " pts spent]")
		Append(output, "--------------------------------")
		local talents = GetNumTalents(tab) or 0
		local talent = 1
		while talent <= talents do
			local name, _, tier, column, rank, maxRank = GetTalentInfo(tab, talent)
			rank = rank or 0
			maxRank = maxRank or 0
			Append(output, string.format(
				"Talent: %s (%d/%d)  [tier %s, col %s]",
				name or "?", rank, maxRank,
				tostring(tier or "?"), tostring(column or "?")
			))
			AppendLines(output, GetTalentTooltip(tab, talent))
			Append(output, "")
			talent = talent + 1
		end
		tab = tab + 1
	end
end

local function BuildBCS(output)
	if BCS and BCS.GetDumpText then
		Append(output, BCS:GetDumpText())
	else
		Append(output, "================================")
		Append(output, "BCS STATS: BetterCharacterStats not loaded")
		Append(output, "================================")
	end
	Append(output, "")
end

local function BuildBags(output)
	Append(output, "================================")
	Append(output, "BAGS")
	Append(output, "================================")
	local bag = 0
	while bag <= 4 do
		DumpContainer(output, bag, GetBagName(bag))
		bag = bag + 1
	end
	Append(output, "")
end

local function BuildBank(output)
	Append(output, "================================")
	Append(output, "BANK")
	Append(output, "================================")
	if not IsBankOpen() then
		Append(output, "Bank window is not open.")
		Append(output, "")
		return
	end
	DumpContainer(output, -1, "Bank")
	local bag = 5
	while bag <= 10 do
		local numSlots = GetContainerNumSlots(bag) or 0
		if numSlots > 0 then
			DumpContainer(output, bag, "Bank Bag " .. (bag - 4))
		end
		bag = bag + 1
	end
	Append(output, "")
end

local function BuildSpellbook(output)
	Append(output, "================================")
	Append(output, "SPELLBOOK")
	Append(output, "================================")
	Append(output, "")

	local numTabs = GetNumSpellTabs() or 0
	local tab = 1
	while tab <= numTabs do
		local name, texture, offset, numSpells = GetSpellTabInfo(tab)
		Append(output, "### TAB: " .. (name or ("Tab " .. tab)) .. "  (" .. (numSpells or 0) .. " spells)")
		Append(output, "--------------------------------")

		local i = 1
		while i <= (numSpells or 0) do
			local spellIndex = offset + i
			local spellName, rank = GetSpellName(spellIndex, BOOKTYPE_SPELL)
			if spellName then
				local rankStr = rank and rank ~= "" and rank or ""
				if rankStr ~= "" then
					Append(output, "Spell: " .. spellName .. " (" .. rankStr .. ")")
				else
					Append(output, "Spell: " .. spellName)
				end
				AppendLines(output, GetSpellTooltip(spellIndex))
				Append(output, "")
			end
			i = i + 1
		end
		tab = tab + 1
	end
end

local function IsTrainerOpen()
	if ClassTrainerFrame and ClassTrainerFrame:IsVisible() then return true end
	if TradeSkillFrame and TradeSkillFrame:IsVisible() and IsTradeskillTrainer and IsTradeskillTrainer() then return true end
	-- some UIs keep the API alive while talking to trainer
	local n = GetNumTrainerServices and GetNumTrainerServices() or 0
	return n > 0
end

local function FormatMoneyCopper(copper)
	copper = copper or 0
	local g = math.floor(copper / 10000)
	local s = math.floor((copper - g * 10000) / 100)
	local c = copper - math.floor(copper / 100) * 100
	if g > 0 then
		return string.format("%dg %ds %dc", g, s, c)
	elseif s > 0 then
		return string.format("%ds %dc", s, c)
	else
		return string.format("%dc", c)
	end
end

local function BuildTrainer(output)
	Append(output, "================================")
	Append(output, "TRAINER (spells offered for purchase)")
	Append(output, "================================")

	if not GetNumTrainerServices then
		Append(output, "Trainer API not available.")
		Append(output, "")
		return
	end

	local num = GetNumTrainerServices() or 0
	if num == 0 or not IsTrainerOpen() then
		Append(output, "Trainer window is not open (or no services).")
		Append(output, "Open a class/profession trainer, then dump again.")
		Append(output, "")
		return
	end

	-- Try to show available + unavailable (not yet bought)
	if SetTrainerServiceTypeFilter then
		SetTrainerServiceTypeFilter("available", 1)
		SetTrainerServiceTypeFilter("unavailable", 1)
		SetTrainerServiceTypeFilter("used", 0)
	end
	num = GetNumTrainerServices() or 0

	Append(output, "Total entries: " .. num)
	Append(output, "")

	local i = 1
	while i <= num do
		local name, rank, category = GetTrainerServiceInfo(i)
		category = category or "?"

		if category == "header" then
			Append(output, "### " .. (name or "Header"))
		else
			local cost = GetTrainerServiceCost and GetTrainerServiceCost(i) or 0
			local levelReq = GetTrainerServiceLevelReq and GetTrainerServiceLevelReq(i) or 0
			local skill, skillRank = nil, nil
			if GetTrainerServiceSkillReq then
				skill, skillRank = GetTrainerServiceSkillReq(i)
			end

			local rankStr = (rank and rank ~= "" and rank) or ""
			local line = "Spell: " .. (name or "?")
			if rankStr ~= "" then
				line = line .. " (" .. rankStr .. ")"
			end
			line = line .. " | status: " .. category
			line = line .. " | cost: " .. FormatMoneyCopper(cost)
			if levelReq and levelReq > 0 then
				line = line .. " | lvl: " .. levelReq
			end
			if skill then
				line = line .. " | skill: " .. skill
				if skillRank then
					line = line .. " " .. skillRank
				end
			end
			Append(output, line)

			-- Description if available (1.12 may need service selected)
			if GetTrainerServiceDescription then
				local desc = GetTrainerServiceDescription(i)
				if desc and desc ~= "" then
					Append(output, "  " .. desc)
				end
			end
		end
		i = i + 1
	end
	Append(output, "")
end

--------------------------------------------------
-- Build dump from selected options
--------------------------------------------------

local function BuildDump()
	EnsureDB()
	local output = {}
	local _, className = UnitClass("player")
	local level = UnitLevel("player")
	local playerName = UnitName("player") or "?"

	Append(output, "VANILLA+ " .. (className or "UNKNOWN") .. " (LVL " .. level .. ") DUMP")
	Append(output, "Character: " .. playerName)

	local opts = {}
	local k = 1
	while k <= table.getn(OPTION_KEYS) do
		local key = OPTION_KEYS[k]
		if TalentDumpDB[key] then
			opts[table.getn(opts) + 1] = OPTION_LABELS[key]
		end
		k = k + 1
	end
	Append(output, "Sections: " .. (table.getn(opts) > 0 and table.concat(opts, ", ") or "none"))
	Append(output, "================================")
	Append(output, "")

	if TalentDumpDB.equipment then BuildEquipment(output) end
	if TalentDumpDB.talentsTaken then BuildTalentsTaken(output) end
	if TalentDumpDB.bcs then BuildBCS(output) end
	if TalentDumpDB.talentsFull then BuildTalentsFull(output) end
	if TalentDumpDB.bags then BuildBags(output) end
	if TalentDumpDB.bank then BuildBank(output) end
	if TalentDumpDB.spellbook then BuildSpellbook(output) end
	if TalentDumpDB.trainer then BuildTrainer(output) end

	Append(output, "================================")
	Append(output, "END OF DUMP")
	return table.concat(output, "\n")
end

--------------------------------------------------
-- Result window (copy-paste)
--------------------------------------------------

local resultFrame = CreateFrame("Frame", "TalentDumpResultFrame", UIParent)
resultFrame:SetWidth(720)
resultFrame:SetHeight(520)
resultFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
resultFrame:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 12,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
resultFrame:SetBackdropColor(0, 0, 0, 0.92)
resultFrame:SetMovable(true)
resultFrame:EnableMouse(true)
resultFrame:RegisterForDrag("LeftButton")
resultFrame:SetScript("OnDragStart", function() this:StartMoving() end)
resultFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
resultFrame:Hide()

local resultTitle = resultFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
resultTitle:SetPoint("TOP", 0, -10)
resultTitle:SetText("Dump — Ctrl+A / Ctrl+C")

local scroll = CreateFrame("ScrollFrame", "TalentDumpScroll", resultFrame, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 12, -32)
scroll:SetPoint("BOTTOMRIGHT", -32, 12)

local edit = CreateFrame("EditBox", "TalentDumpEditBox", scroll)
edit:SetMultiLine(true)
edit:SetAutoFocus(false)
edit:SetFontObject(ChatFontNormal)
edit:SetWidth(640)
edit:SetHeight(50000)
edit:SetJustifyH("LEFT")
edit:SetJustifyV("TOP")
edit:SetTextInsets(4, 4, 4, 4)
if edit.SetMaxLetters then edit:SetMaxLetters(999999) end
scroll:SetScrollChild(edit)

local resultClose = CreateFrame("Button", nil, resultFrame, "UIPanelCloseButton")
resultClose:SetPoint("TOPRIGHT", resultFrame, "TOPRIGHT", 0, 0)

local function ShowDumpResult()
	local text = BuildDump()
	edit:SetText(text)
	local nlines = 1
	for _ in string.gfind(text, "\n") do
		nlines = nlines + 1
	end
	edit:SetHeight(math.max(500, nlines * 14 + 40))
	edit:SetFocus()
	edit:HighlightText()
	resultFrame:Show()
	scroll:SetVerticalScroll(0)
end

--------------------------------------------------
-- Options panel
--------------------------------------------------

local panel = CreateFrame("Frame", "TalentDumpPanel", UIParent)
panel:SetWidth(220)
panel:SetHeight(305)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
panel:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 12,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
panel:SetBackdropColor(0, 0, 0, 0.9)
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function() this:StartMoving() end)
panel:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
panel:Hide()

local panelTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
panelTitle:SetPoint("TOP", 0, -12)
panelTitle:SetText("TalentDump")

local panelClose = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
panelClose:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 2, 2)
panelClose:SetWidth(24)
panelClose:SetHeight(24)

local checkboxes = {}

local function MakeCheckbox(key, index)
	local cb = CreateFrame("CheckButton", "TalentDumpCB_" .. key, panel, "UICheckButtonTemplate")
	cb:SetWidth(24)
	cb:SetHeight(24)
	cb:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -28 - (index - 1) * 24)
	local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
	label:SetText(OPTION_LABELS[key])
	cb:SetScript("OnClick", function()
		TalentDumpDB[key] = (this:GetChecked() == 1)
	end)
	checkboxes[key] = cb
	return cb
end

local oi = 1
while oi <= table.getn(OPTION_KEYS) do
	MakeCheckbox(OPTION_KEYS[oi], oi)
	oi = oi + 1
end

local dumpBtn = CreateFrame("Button", "TalentDumpDoButton", panel, "UIPanelButtonTemplate")
dumpBtn:SetWidth(100)
dumpBtn:SetHeight(22)
dumpBtn:SetPoint("BOTTOM", panel, "BOTTOM", 0, 12)
local dumpBtnText = dumpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dumpBtnText:SetAllPoints()
dumpBtnText:SetText("Dump")
dumpBtn:SetScript("OnClick", function()
	ShowDumpResult()
end)

local function SyncCheckboxes()
	EnsureDB()
	local i = 1
	while i <= table.getn(OPTION_KEYS) do
		local key = OPTION_KEYS[i]
		local cb = checkboxes[key]
		if cb then
			cb:SetChecked(TalentDumpDB[key] and 1 or 0)
		end
		i = i + 1
	end
end

local function TogglePanel()
	if panel:IsVisible() then
		panel:Hide()
	else
		SyncCheckboxes()
		panel:Show()
	end
end

--------------------------------------------------
-- Minimap button
--------------------------------------------------

local minimapBtn = CreateFrame("Button", "TalentDumpMinimapButton", Minimap)
minimapBtn:SetWidth(32)
minimapBtn:SetHeight(32)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 8, -40)
minimapBtn:SetMovable(true)
minimapBtn:EnableMouse(true)
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetScript("OnDragStart", function() this:StartMoving() end)
minimapBtn:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
minimapBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Book_09")
minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimapBtn:SetScript("OnClick", function()
	TogglePanel()
end)
minimapBtn:SetScript("OnEnter", function()
	GameTooltip:SetOwner(this, "ANCHOR_LEFT")
	GameTooltip:AddLine("TalentDump", 1, 1, 1)
	GameTooltip:AddLine("Open dump options", 0.8, 0.8, 0.8)
	GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
	GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

--------------------------------------------------
-- Slash
--------------------------------------------------

SLASH_TALENTDUMP1 = "/talentdump"
SLASH_TALENTDUMP2 = "/fulldump"
SlashCmdList["TALENTDUMP"] = function(msg)
	msg = msg and string.lower(msg) or ""
	if msg == "dump" then
		ShowDumpResult()
	else
		TogglePanel()
	end
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_ENTERING_WORLD")
init:SetScript("OnEvent", function()
	EnsureDB()
	SyncCheckboxes()
end)

DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TalentDump|r loaded. Minimap button or /talentdump")
