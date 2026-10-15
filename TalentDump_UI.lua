--------------------------------------------------
-- TalentDump UI: result window, options panel, minimap, slash
--------------------------------------------------

TalentDump = TalentDump or {}

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

function TalentDump.ShowText(text)
	text = text or ""
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

function TalentDump.ShowDumpResult()
	TalentDump.ShowText(TalentDump.BuildDump())
end

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
	label:SetText(TalentDump.OPTION_LABELS[key])
	cb:SetScript("OnClick", function()
		TalentDumpDB[key] = (this:GetChecked() == 1)
	end)
	checkboxes[key] = cb
	return cb
end

local oi = 1
while oi <= table.getn(TalentDump.OPTION_KEYS) do
	MakeCheckbox(TalentDump.OPTION_KEYS[oi], oi)
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
	TalentDump.ShowDumpResult()
end)

local function SyncCheckboxes()
	TalentDump.EnsureDB()
	local i = 1
	while i <= table.getn(TalentDump.OPTION_KEYS) do
		local key = TalentDump.OPTION_KEYS[i]
		local cb = checkboxes[key]
		if cb then
			cb:SetChecked(TalentDumpDB[key] and 1 or 0)
		end
		i = i + 1
	end
end

function TalentDump.TogglePanel()
	if panel:IsVisible() then
		panel:Hide()
	else
		SyncCheckboxes()
		panel:Show()
	end
end

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
	TalentDump.TogglePanel()
end)
minimapBtn:SetScript("OnEnter", function()
	GameTooltip:SetOwner(this, "ANCHOR_LEFT")
	GameTooltip:AddLine("TalentDump", 1, 1, 1)
	GameTooltip:AddLine("Open dump options", 0.8, 0.8, 0.8)
	GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
	GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

SLASH_TALENTDUMP1 = "/talentdump"
SLASH_TALENTDUMP2 = "/fulldump"
SlashCmdList["TALENTDUMP"] = function(msg)
	msg = msg and string.lower(msg) or ""
	if msg == "dump" then
		TalentDump.ShowDumpResult()
	elseif msg == "boss" then
		if TalentDump.ShowAtlasLootBossDump then
			TalentDump.ShowAtlasLootBossDump()
		end
	elseif msg == "inst" or msg == "instance" then
		if TalentDump.ShowAtlasLootInstanceDump then
			TalentDump.ShowAtlasLootInstanceDump()
		end
	else
		TalentDump.TogglePanel()
	end
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_ENTERING_WORLD")
init:SetScript("OnEvent", function()
	TalentDump.EnsureDB()
	SyncCheckboxes()
end)

DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TalentDump|r v3.0 loaded. Minimap /talentdump | AtlasLoot: Dump Boss / Dump Inst")
