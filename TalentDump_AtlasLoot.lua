--------------------------------------------------
-- TalentDump AtlasLoot: dump boss / full instance loot
-- Requires AtlasLoot Enhanced (Vanilla+) loaded
--------------------------------------------------

TalentDump = TalentDump or {}

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
	local try = { "AtlasLootItems", "AtlasLootWBItems", "AtlasLootSetItems", "AtlasLootCrafting", "AtlasLootGeneral" }
	local i = 1
	while i <= table.getn(try) do
		if AtlasLoot_Data and AtlasLoot_Data[try[i]] and AtlasLoot_Data[try[i]][dataID] then
			return AtlasLoot_Data[try[i]][dataID], try[i]
		end
		i = i + 1
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
	if AtlasLootCharDB and AtlasLootCharDB.LastBoss and AtlasLootCharDB.LastBoss ~= "" then
		return AtlasLootCharDB.LastBoss, AtlasLootCharDB.LastBossText
	end
	if AtlasLootItemsFrame and AtlasLootItemsFrame.refresh and AtlasLootItemsFrame.refresh[1] then
		return AtlasLootItemsFrame.refresh[1], AtlasLootItemsFrame.refresh[3]
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
		Append(output, "No boss selected. Open AtlasLoot and click a boss.")
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
	local i = 1
	while i <= table.getn(bosses) do
		local dataID = bosses[i]
		if dataID and dataID ~= "" then
			local n = TalentDump.DumpBossLootTable(output, dataID, ResolveBossName(dataID))
			total = total + (n or 0)
			Append(output, "")
		end
		i = i + 1
	end
	Append(output, "================================")
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

local function PlaceButtons()
	local parent = getglobal("AtlasLootDefaultFrame")
	if not parent then parent = getglobal("AtlasLootItemsFrame") end
	if not parent then return end

	if not TalentDump.AtlasBossBtn then
		local b1 = CreateFrame("Button", "TalentDumpAtlasBossBtn", parent, "UIPanelButtonTemplate")
		b1:SetWidth(90)
		b1:SetHeight(20)
		local t1 = b1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		t1:SetAllPoints()
		t1:SetText("Dump Boss")
		b1:SetScript("OnClick", function()
			TalentDump.ShowAtlasLootBossDump()
		end)
		TalentDump.AtlasBossBtn = b1

		local b2 = CreateFrame("Button", "TalentDumpAtlasInstBtn", parent, "UIPanelButtonTemplate")
		b2:SetWidth(90)
		b2:SetHeight(20)
		local t2 = b2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		t2:SetAllPoints()
		t2:SetText("Dump Inst")
		b2:SetScript("OnClick", function()
			TalentDump.ShowAtlasLootInstanceDump()
		end)
		TalentDump.AtlasInstBtn = b2
	end

	local b1 = TalentDump.AtlasBossBtn
	local b2 = TalentDump.AtlasInstBtn
	b1:SetParent(parent)
	b2:SetParent(parent)
	b1:ClearAllPoints()
	b2:ClearAllPoints()
	b1:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -120, -28)
	b2:SetPoint("RIGHT", b1, "LEFT", -6, 0)
	b1:Show()
	b2:Show()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" and arg1 and string.find(string.lower(arg1), "atlasloot") then
		PlaceButtons()
	end
	if event == "PLAYER_ENTERING_WORLD" then
		if IsAddOnLoaded and (IsAddOnLoaded("AtlasLoot") or IsAddOnLoaded("AtlasLootEnhanced")) then
			PlaceButtons()
		elseif getglobal("AtlasLootDefaultFrame") or getglobal("AtlasLootItemsFrame") then
			PlaceButtons()
		end
	end
end)

local function TryHook()
	if AtlasLootDefaultFrame_OnShow and not TalentDump._atlasHooked then
		local orig = AtlasLootDefaultFrame_OnShow
		AtlasLootDefaultFrame_OnShow = function()
			orig()
			PlaceButtons()
		end
		TalentDump._atlasHooked = true
	end
end

local hf = CreateFrame("Frame")
hf:SetScript("OnUpdate", function()
	TryHook()
	if TalentDump._atlasHooked then
		this:SetScript("OnUpdate", nil)
	end
end)
