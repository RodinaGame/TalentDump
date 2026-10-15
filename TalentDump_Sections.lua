--------------------------------------------------
-- TalentDump Sections: equipment, talents, BCS, bags, bank, spellbook, trainer
--------------------------------------------------

TalentDump = TalentDump or {}

function TalentDump.BuildEquipment(output)
	local Append = TalentDump.Append
	Append(output, "================================")
	Append(output, "EQUIPMENT DUMP")
	Append(output, "================================")
	Append(output, "")
	local slot = 1
	while slot <= 19 do
		local itemLines = TalentDump.GetItemTooltipText(slot)
		if itemLines then
			Append(output, "--- Slot " .. slot .. " ---")
			TalentDump.AppendLines(output, itemLines)
			Append(output, "")
		end
		slot = slot + 1
	end
end

function TalentDump.BuildTalentsTaken(output)
	local Append = TalentDump.Append
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
				TalentDump.AppendLines(output, TalentDump.GetTalentTooltip(tab, talent))
				Append(output, "")
			end
			talent = talent + 1
		end
		tab = tab + 1
	end
end

function TalentDump.BuildTalentsFull(output)
	local Append = TalentDump.Append
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
			TalentDump.AppendLines(output, TalentDump.GetTalentTooltip(tab, talent))
			Append(output, "")
			talent = talent + 1
		end
		tab = tab + 1
	end
end

function TalentDump.BuildBCS(output)
	local Append = TalentDump.Append
	if BCS and BCS.GetDumpText then
		Append(output, BCS:GetDumpText())
	else
		Append(output, "================================")
		Append(output, "BCS STATS: BetterCharacterStats not loaded")
		Append(output, "================================")
	end
	Append(output, "")
end

function TalentDump.BuildBags(output)
	local Append = TalentDump.Append
	Append(output, "================================")
	Append(output, "BAGS")
	Append(output, "================================")
	local bag = 0
	while bag <= 4 do
		TalentDump.DumpContainer(output, bag, TalentDump.GetBagName(bag))
		bag = bag + 1
	end
	Append(output, "")
end

function TalentDump.BuildBank(output)
	local Append = TalentDump.Append
	Append(output, "================================")
	Append(output, "BANK")
	Append(output, "================================")
	if not TalentDump.IsBankOpen() then
		Append(output, "Bank window is not open.")
		Append(output, "")
		return
	end
	TalentDump.DumpContainer(output, -1, "Bank")
	local bag = 5
	while bag <= 10 do
		local numSlots = GetContainerNumSlots(bag) or 0
		if numSlots > 0 then
			TalentDump.DumpContainer(output, bag, "Bank Bag " .. (bag - 4))
		end
		bag = bag + 1
	end
	Append(output, "")
end

function TalentDump.BuildSpellbook(output)
	local Append = TalentDump.Append
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
				TalentDump.AppendLines(output, TalentDump.GetSpellTooltip(spellIndex))
				Append(output, "")
			end
			i = i + 1
		end
		tab = tab + 1
	end
end

function TalentDump.IsTrainerOpen()
	if ClassTrainerFrame and ClassTrainerFrame:IsVisible() then return true end
	if TradeSkillFrame and TradeSkillFrame:IsVisible() and IsTradeskillTrainer and IsTradeskillTrainer() then return true end
	local n = GetNumTrainerServices and GetNumTrainerServices() or 0
	return n > 0
end

function TalentDump.BuildTrainer(output)
	local Append = TalentDump.Append
	Append(output, "================================")
	Append(output, "TRAINER (spells offered for purchase)")
	Append(output, "================================")

	if not GetNumTrainerServices then
		Append(output, "Trainer API not available.")
		Append(output, "")
		return
	end

	local num = GetNumTrainerServices() or 0
	if num == 0 or not TalentDump.IsTrainerOpen() then
		Append(output, "Trainer window is not open (or no services).")
		Append(output, "Open a class/profession trainer, then dump again.")
		Append(output, "")
		return
	end

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
			line = line .. " | cost: " .. TalentDump.FormatMoneyCopper(cost)
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

function TalentDump.BuildDump()
	TalentDump.EnsureDB()
	local Append = TalentDump.Append
	local output = {}
	local _, className = UnitClass("player")
	local level = UnitLevel("player")
	local playerName = UnitName("player") or "?"

	Append(output, "VANILLA+ " .. (className or "UNKNOWN") .. " (LVL " .. level .. ") DUMP")
	Append(output, "Character: " .. playerName)

	local opts = {}
	local k = 1
	local keys = TalentDump.OPTION_KEYS
	while k <= table.getn(keys) do
		local key = keys[k]
		if TalentDumpDB[key] then
			opts[table.getn(opts) + 1] = TalentDump.OPTION_LABELS[key]
		end
		k = k + 1
	end
	Append(output, "Sections: " .. (table.getn(opts) > 0 and table.concat(opts, ", ") or "none"))
	Append(output, "================================")
	Append(output, "")

	if TalentDumpDB.equipment then TalentDump.BuildEquipment(output) end
	if TalentDumpDB.talentsTaken then TalentDump.BuildTalentsTaken(output) end
	if TalentDumpDB.bcs then TalentDump.BuildBCS(output) end
	if TalentDumpDB.talentsFull then TalentDump.BuildTalentsFull(output) end
	if TalentDumpDB.bags then TalentDump.BuildBags(output) end
	if TalentDumpDB.bank then TalentDump.BuildBank(output) end
	if TalentDumpDB.spellbook then TalentDump.BuildSpellbook(output) end
	if TalentDumpDB.trainer then TalentDump.BuildTrainer(output) end

	Append(output, "================================")
	Append(output, "END OF DUMP")
	return table.concat(output, "\n")
end
