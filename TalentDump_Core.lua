--------------------------------------------------
-- TalentDump Core (Vanilla 1.12 / Vanilla+)
-- Namespace, DB, shared helpers
-- Authors: Grok, Rodina
--------------------------------------------------

TalentDump = TalentDump or {}
TalentDumpDB = TalentDumpDB or {}

TalentDump.OPTION_KEYS = {
	"equipment",
	"talentsTaken",
	"talentsFull",
	"bcs",
	"bags",
	"bank",
	"spellbook",
	"trainer",
}

TalentDump.OPTION_LABELS = {
	equipment   = "Equipment",
	talentsTaken = "Talents (taken)",
	talentsFull = "Talents (full tree)",
	bcs         = "BCS stats",
	bags        = "Bags",
	bank        = "Bank",
	spellbook   = "Spellbook",
	trainer     = "Trainer (open)",
}

function TalentDump.EnsureDB()
	local db = TalentDumpDB
	if db.equipment == nil then db.equipment = true end
	if db.talentsTaken == nil then db.talentsTaken = true end
	if db.talentsFull == nil then db.talentsFull = true end
	if db.bcs == nil then db.bcs = true end
	if db.bags == nil then db.bags = false end
	if db.bank == nil then db.bank = false end
	if db.spellbook == nil then db.spellbook = false end
	if db.trainer == nil then db.trainer = false end
	if db.includeBags ~= nil then
		db.bags = db.includeBags and true or false
		db.includeBags = nil
	end
	if db.includeBank ~= nil then
		db.bank = db.includeBank and true or false
		db.includeBank = nil
	end
end

function TalentDump.Append(output, line)
	output[table.getn(output) + 1] = line
end

function TalentDump.AppendLines(output, lines)
	if not lines then return end
	local i = 1
	while i <= table.getn(lines) do
		TalentDump.Append(output, lines[i])
		i = i + 1
	end
end

function TalentDump.ReadTooltipLines()
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

function TalentDump.GetTalentTooltip(tab, talent)
	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	GameTooltip:SetTalent(tab, talent)
	return TalentDump.ReadTooltipLines()
end

function TalentDump.GetItemTooltipText(slot)
	local link = GetInventoryItemLink("player", slot)
	if not link then return nil end
	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	GameTooltip:SetInventoryItem("player", slot)
	return TalentDump.ReadTooltipLines()
end

function TalentDump.GetSpellTooltip(spellIndex)
	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	GameTooltip:SetSpell(spellIndex, BOOKTYPE_SPELL)
	return TalentDump.ReadTooltipLines()
end

function TalentDump.QualityFromLink(link)
	if not link then return "Unknown" end
	if string.find(link, "|cffa335ee") then return "Epic"
	elseif string.find(link, "|cff0070dd") then return "Rare"
	elseif string.find(link, "|cff1eff00") then return "Uncommon"
	elseif string.find(link, "|cffffffff") then return "Common"
	elseif string.find(link, "|cff9d9d9d") then return "Poor"
	elseif string.find(link, "|cffff8000") then return "Legendary"
	else return "Unknown" end
end

function TalentDump.QualityFromCode(s)
	if not s then return "Unknown" end
	if string.find(s, "=q5=") or string.find(s, "|cffff8000") then return "Legendary" end
	if string.find(s, "=q4=") or string.find(s, "|cffa335ee") then return "Epic" end
	if string.find(s, "=q3=") or string.find(s, "|cff0070dd") then return "Rare" end
	if string.find(s, "=q2=") or string.find(s, "|cff1eff00") then return "Uncommon" end
	if string.find(s, "=q1=") or string.find(s, "|cffffffff") then return "Common" end
	if string.find(s, "=q0=") or string.find(s, "|cff9d9d9d") then return "Poor" end
	return "Unknown"
end

function TalentDump.StripAtlasText(s)
	if not s then return "" end
	if AtlasLoot_FixText then
		s = AtlasLoot_FixText(s)
	end
	s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "")
	s = string.gsub(s, "|r", "")
	s = string.gsub(s, "=q%d=", "")
	s = string.gsub(s, "=ds=", "")
	s = string.gsub(s, "=q=", "")
	return s
end

function TalentDump.ExtractItemID(link)
	if not link then return "?" end
	local id = string.gsub(link, ".*item:(%d+):.*", "%1")
	if id == link then return "?" end
	return id
end

function TalentDump.ExtractItemName(link)
	if not link then return "?" end
	local name = GetItemInfo(link)
	if name then return name end
	name = string.gsub(link, ".*%[(.-)%].*", "%1")
	if name and name ~= link then return name end
	return "?"
end

function TalentDump.GetBagName(bag)
	if bag == 0 then return "Backpack" end
	local invSlot = bag + 19
	local link = GetInventoryItemLink("player", invSlot)
	if link then
		local name = TalentDump.ExtractItemName(link)
		if name and name ~= "?" then return name end
	end
	return "Bag " .. bag
end

function TalentDump.DumpContainer(output, bag, header)
	local numSlots = GetContainerNumSlots(bag) or 0
	if numSlots == 0 then return end
	TalentDump.Append(output, "--- " .. header .. " (bag " .. bag .. ") ---")
	local free = 0
	local slot = 1
	while slot <= numSlots do
		local texture, itemCount = GetContainerItemInfo(bag, slot)
		local link = GetContainerItemLink(bag, slot)
		if link then
			local name = TalentDump.ExtractItemName(link)
			local id = TalentDump.ExtractItemID(link)
			local q = TalentDump.QualityFromLink(link)
			TalentDump.Append(output, string.format("  %dx %s | id:%s | %s", itemCount or 1, name, id, q))
		else
			free = free + 1
		end
		slot = slot + 1
	end
	TalentDump.Append(output, "  Free slots: " .. free .. " / " .. numSlots)
end

function TalentDump.IsBankOpen()
	if BankFrame and BankFrame:IsVisible() then return true end
	if pfUI and pfUI.bag and pfUI.bag.left and pfUI.bag.left:IsVisible() then return true end
	local pfBank = getglobal("pfBank")
	if pfBank and pfBank:IsVisible() then return true end
	return false
end

function TalentDump.FormatMoneyCopper(copper)
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
