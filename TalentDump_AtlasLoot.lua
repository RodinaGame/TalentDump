--------------------------------------------------
-- TalentDump AtlasLoot: dump boss / full instance loot
-- Requires AtlasLoot Enhanced (Vanilla+) loaded
--------------------------------------------------

TalentDump = TalentDump or {}

-- Shared / non-boss tables to skip in full-instance dump
local SKIP_TABLES = {
	VanillaKeys = true,
	LunarFestival1 = true,
	LunarFestival2 = true,
}

local function ResolveDataSource(dataID)
	if AtlasLoot_TableNames and AtlasLoot_TableNames[dataID] then
		return AtlasLoot_TableNames[dataID][2] or "AtlasLootItems"
	end
	return "AtlasLootItems"
end

local function ResolveBossName(dataID)
	if AtlasLoot_TableNames and AtlasLoot_TableNames[dataID] and AtlasLoot_TableNames[dataID][1] then
		return TalentDump.StripAtlasText(AtlasLoot_TableNames[dataID][1])
	end
	return dataID
end

local function GetCurrentZoneID()
	if AtlasOptions and ATLAS_DROPDOWNS then
		local t = AtlasOptions.AtlasType
		local z = AtlasOptions.AtlasZone
		if t and z and ATLAS_DROPDOWNS[t] then
			return ATLAS_DROPDOWNS[t][z]
		end
	end
	return nil
end

local function GetLootTable(dataID)
	if not dataID or dataID == "" then return nil end
	local src = ResolveDataSource(dataID)
	if AtlasLoot_Data and AtlasLoot_Data[src] and AtlasLoot_Data[src][dataID] then
		return AtlasLoot_Data[src][dataID], src
	end
	local try = {
		"AtlasLootItems",
		"AtlasLootWBItems",
		"AtlasLootSetItems",
		"AtlasLootCrafting",
		"AtlasLootGeneral",
		"AtlasLootBP",
		"AtlasLootRuins",
	}
	local i = 1
	while i <= table.getn(try) do
		if AtlasLoot_Data and AtlasLoot_Data[try[i]] and AtlasLoot_Data[try[i]][dataID] then
			return AtlasLoot_Data[try[i]][dataID], try[i]
		end
		i = i + 1
	end
	if AtlasLoot_Data then
		for dsName, ds in pairs(AtlasLoot_Data) do
			if type(ds) == "table" and ds[dataID] then
				return ds[dataID], dsName
			end
		end
	end
	return nil, src
end

local function FormatLootEntry(entry)
	if not entry then return nil end
	local itemID = entry[1]
	if not itemID or itemID == 0 or itemID == "" then
		local title = entry[3]
		if title and title ~= "" and entry[2] and entry[2] ~= "" then
			return "### " .. TalentDump.StripAtlasText(title)
		end
		return nil
	end
	local nameRaw = entry[3] or ""
	local extraRaw = entry[4] or ""
	local drop = entry[5] or ""
	local q = TalentDump.QualityFromCode(nameRaw)
	local name = TalentDump.StripAtlasText(nameRaw)
	local extra = TalentDump.StripAtlasText(extraRaw)
	local line = string.format("  [%s] %s | id:%s", q, name, tostring(itemID))
	if extra and extra ~= "" then
		line = line .. " | " .. extra
	end
	if drop and drop ~= "" then
		line = line .. " | " .. drop
	end
	return line
end

function TalentDump.DumpBossLootTable(output, dataID, bossTitle)
	local Append = TalentDump.Append
	local tableData, src = GetLootTable(dataID)
	local title = bossTitle or ResolveBossName(dataID)
	Append(output, "--------------------------------")
	Append(output, "BOSS: " .. title)
	Append(output, "Table: " .. tostring(dataID) .. "  [" .. tostring(src or "?") .. "]")
	if not tableData then
		Append(output, "  (loot table not found)")
		return 0
	end
	local count = 0
	local i = 1
	while i <= table.getn(tableData) do
		local line = FormatLootEntry(tableData[i])
		if line then
			Append(output, line)
			if string.sub(line, 1, 3) ~= "###" then
				count = count + 1
			end
		end
		i = i + 1
	end
	Append(output, "  Items listed: " .. count)
	return count
end

function TalentDump.GetCurrentBossDataID()
	local zoneID = GetCurrentZoneID()

	if zoneID and AtlasLootBossButtons and AtlasLootBossButtons[zoneID]
		and AtlasLootItemsFrame and AtlasLootItemsFrame.activeBoss then
		local idx = AtlasLootItemsFrame.activeBoss
		local dataID = AtlasLootBossButtons[zoneID][idx]
		if dataID and dataID ~= "" then
			return dataID, ResolveBossName(dataID)
		end
	end

	if AtlasLootItemsFrame and AtlasLootItemsFrame.refresh
		and AtlasLootItemsFrame.refresh[1]
		and AtlasLootItemsFrame.refresh[1] ~= "" then
		local dataID = AtlasLootItemsFrame.refresh[1]
		local text = AtlasLootItemsFrame.refresh[3]
		if zoneID and AtlasLootBossButtons and AtlasLootBossButtons[zoneID] then
			local ok = false
			local bosses = AtlasLootBossButtons[zoneID]
			local i = 1
			while i <= table.getn(bosses) do
				if bosses[i] == dataID then ok = true break end
				i = i + 1
			end
			if ok then
				return dataID, text or ResolveBossName(dataID)
			end
		else
			return dataID, text or ResolveBossName(dataID)
		end
	end

	if AtlasLootCharDB and AtlasLootCharDB.LastBoss and AtlasLootCharDB.LastBoss ~= "" then
		local dataID = AtlasLootCharDB.LastBoss
		if zoneID and AtlasLootBossButtons and AtlasLootBossButtons[zoneID] then
			local bosses = AtlasLootBossButtons[zoneID]
			local i = 1
			while i <= table.getn(bosses) do
				if bosses[i] == dataID then
					return dataID, AtlasLootCharDB.LastBossText or ResolveBossName(dataID)
				end
				i = i + 1
			end
		else
			return dataID, AtlasLootCharDB.LastBossText
		end
	end

	return nil, nil
end

function TalentDump.BuildAtlasLootBossDump()
	local Append = TalentDump.Append
	local output = {}
	Append(output, "ATLASLOOT DUMP — CURRENT BOSS")
	local zoneID = GetCurrentZoneID()
	if zoneID then
		Append(output, "Instance map: " .. tostring(zoneID))
	end
	local dataID, bossText = TalentDump.GetCurrentBossDataID()
	if not dataID then
		Append(output, "No boss selected for this map.")
		Append(output, "Click a boss number on the Atlas list (right panel), then dump again.")
		Append(output, "END OF DUMP")
		return table.concat(output, "\n")
	end
	local name = bossText and TalentDump.StripAtlasText(bossText) or ResolveBossName(dataID)
	Append(output, "Selected: " .. name)
	Append(output, "================================")
	TalentDump.DumpBossLootTable(output, dataID, name)
	Append(output, "================================")
	Append(output, "END OF DUMP")
	return table.concat(output, "\n")
end

function TalentDump.BuildAtlasLootInstanceDump()
	local Append = TalentDump.Append
	local output = {}
	Append(output, "ATLASLOOT DUMP — FULL INSTANCE")
	local zoneID = GetCurrentZoneID()
	if not zoneID then
		Append(output, "Atlas map not available. Open Atlas + AtlasLoot.")
		Append(output, "END OF DUMP")
		return table.concat(output, "\n")
	end
	Append(output, "Instance map: " .. tostring(zoneID))
	Append(output, "================================")

	if not AtlasLootBossButtons or not AtlasLootBossButtons[zoneID] then
		Append(output, "No AtlasLootBossButtons for this map.")
		local dataID, bossText = TalentDump.GetCurrentBossDataID()
		if dataID then
			TalentDump.DumpBossLootTable(output, dataID, bossText and TalentDump.StripAtlasText(bossText))
		end
		Append(output, "END OF DUMP")
		return table.concat(output, "\n")
	end

	local bosses = AtlasLootBossButtons[zoneID]
	local total = 0
	local dumped = 0
	local i = 1
	while i <= table.getn(bosses) do
		local dataID = bosses[i]
		if dataID and dataID ~= "" and not SKIP_TABLES[dataID] then
			if not string.find(dataID, "Keys$") then
				local n = TalentDump.DumpBossLootTable(output, dataID, ResolveBossName(dataID))
				total = total + (n or 0)
				dumped = dumped + 1
				Append(output, "")
			end
		end
		i = i + 1
	end
	Append(output, "================================")
	Append(output, "Boss tables dumped: " .. dumped)
	Append(output, "Total item rows (approx): " .. total)
	Append(output, "END OF DUMP")
	return table.concat(output, "\n")
end

function TalentDump.ShowAtlasLootBossDump()
	if TalentDump.ShowText then
		TalentDump.ShowText(TalentDump.BuildAtlasLootBossDump())
	end
end

function TalentDump.ShowAtlasLootInstanceDump()
	if TalentDump.ShowText then
		TalentDump.ShowText(TalentDump.BuildAtlasLootInstanceDump())
	end
end

local function MakeBtn(name, parent, text, onClick)
	local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
	b:SetWidth(88)
	b:SetHeight(22)
	local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	fs:SetAllPoints()
	fs:SetText(text)
	b:SetScript("OnClick", onClick)
	return b
end

local function PlaceButtons()
	local atlas = getglobal("AtlasFrame")
	local alDefault = getglobal("AtlasLootDefaultFrame")
	local alItems = getglobal("AtlasLootItemsFrame")
	local parent = atlas or alDefault or alItems
	if not parent then return end

	if not TalentDump.AtlasBossBtn then
		TalentDump.AtlasBossBtn = MakeBtn("TalentDumpAtlasBossBtn", parent, "Dump Boss", function()
			TalentDump.ShowAtlasLootBossDump()
		end)
		TalentDump.AtlasInstBtn = MakeBtn("TalentDumpAtlasInstBtn", parent, "Dump Inst", function()
			TalentDump.ShowAtlasLootInstanceDump()
		end)
	end

	local b1 = TalentDump.AtlasBossBtn
	local b2 = TalentDump.AtlasInstBtn
	b1:SetParent(parent)
	b2:SetParent(parent)
	b1:ClearAllPoints()
	b2:ClearAllPoints()

	if atlas and parent == atlas then
		b2:SetPoint("BOTTOMLEFT", atlas, "BOTTOMLEFT", 20, 48)
		b1:SetPoint("LEFT", b2, "RIGHT", 6, 0)
	else
		b1:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -100, -28)
		b2:SetPoint("RIGHT", b1, "LEFT", -6, 0)
	end
	b1:Show()
	b2:Show()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" and arg1 then
		local n = string.lower(arg1)
		if string.find(n, "atlas") then
			PlaceButtons()
		end
	end
	if event == "PLAYER_ENTERING_WORLD" then
		PlaceButtons()
	end
end)

local function TryHook()
	if not TalentDump._atlasHooked then
		if Atlas_OnShow then
			local orig = Atlas_OnShow
			Atlas_OnShow = function()
				orig()
				PlaceButtons()
			end
		end
		if AtlasLootDefaultFrame_OnShow then
			local orig2 = AtlasLootDefaultFrame_OnShow
			AtlasLootDefaultFrame_OnShow = function()
				orig2()
				PlaceButtons()
			end
		end
		TalentDump._atlasHooked = true
	end
end

local hf = CreateFrame("Frame")
hf:SetScript("OnUpdate", function()
	TryHook()
	PlaceButtons()
	if TalentDump._atlasHooked and (getglobal("AtlasFrame") or getglobal("AtlasLootDefaultFrame")) then
		this:SetScript("OnUpdate", nil)
	end
end)
