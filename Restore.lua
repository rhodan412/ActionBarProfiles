local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local DEBUG = "|cffff0000Debug:|r "

local S2KFI = LibStub("LibS2kFactionalItems-1.0")
ABP = ABP or {}
function addon:GetProfiles(filter, case)
    local list = self.db.profile.list
    local sorted = {}

    local name, profile

    for name, profile in pairs(list) do
        if not filter or name == filter or (case and name:lower() == filter:lower()) then
            profile.name = name
            table.insert(sorted, profile)
        end
    end

    if #sorted > 1 then
        local class = select(2, UnitClass("player"))

        table.sort(sorted, function(a, b)
            if a.class == b.class then
                return a.name < b.name
            else
                return a.class == class
            end
        end)
    end

    return unpack(sorted)
end

function addon:UseProfile(profile, check, cache)
    if type(profile) ~= "table" then
        local list = self.db.profile.list
        profile = list[profile]

        if not profile then
            return 0, 0
        end
    end

    cache = cache or self:MakeCache()

    local macros = cache.macros
    local talents = cache.talents

    local res = { fail = 0, total = 0 }

    if not profile.skipMacros then
        self:RestoreMacros(profile, check, cache, res)
    end

    if not profile.skipTalents then
        print("Debug: Calling RestoreTalents with profile:", profile.name)
        self:RestoreTalents(profile, check, cache, res)
    end

    if not profile.skipPvpTalents then
        self:RestorePvpTalents(profile, check, cache, res)
    end

    if not profile.skipActions then
        self:RestoreActions(profile, check, cache, res)
    end

    if not profile.skipPetActions then
        self:RestorePetActions(profile, check, cache, res)
    end

    if not profile.skipBindings then
        -- self:RestoreBindings(profile, check, cache, res)
    end

    cache.macros = macros
    cache.talents = talents

    if not check then
        self:UpdateGUI()
    end

    return res.fail, res.total
end

function addon:RestoreMacros(profile, check, cache, res)
    local fail, total = 0, 0

    local all, char = GetNumMacros()
    local macros

    if self.db.profile.replace_macros then
        macros = { id = {}, name = {} }

        if not check then
            local index
            for index = 1, all do
                DeleteMacro(1)
            end

            for index = 1, char do
                DeleteMacro(MAX_ACCOUNT_MACROS + 1)
            end
        end

        all, char = 0, 0
    else
        macros = table.s2k_copy(cache.macros)
    end

    local slot
    for slot = 1, ABP_MAX_ACTION_BUTTONS do
        local link = profile.actions[slot]
        if link then
            -- has action
            local data, name = link:match("^|c.-|H(.-)|h%[(.-)%]|h|r$")
            link = link:gsub("|Habp:.+|h(%[.+%])|h", "%1")

            if data then
                local type, sub, icon, body, global = strsplit(":", data)

                if type == "abp" and sub == "macro" then
                    local ok
                    total = total + 1

                    body = self:DecodeLink(body)

                    if self:GetFromCache(macros, self:PackMacro(body)) then
                        ok = true

                    elseif (global and all < MAX_ACCOUNT_MACROS) or (not global and char < MAX_CHARACTER_MACROS) then
                        if check or CreateMacro(name, icon, body, not global) then
                            ok = true
                            self:UpdateCache(macros, -1, self:PackMacro(body), name)
                        end

                        if ok then
                            all = all + ((global and 1) or 0)
                            char = char + ((global and 0) or 1)
                        end
                    end

                    if not ok then
                        fail = fail + 1
                        self:cPrintf(not check, L.msg_cant_create_macro, link)
                    end
                end
            else
                self:cPrintf(profile.skipActions and not check, L.msg_bad_link, link)
            end
        end
    end

    if self.db.profile.replace_macros and profile.macros then
        for slot = 1, #profile.macros do
            local link = profile.macros[slot]

            local data, name = link:match("^|c.-|H(.-)|h%[(.-)%]|h|r$")
            link = link:gsub("|Habp:.+|h(%[.+%])|h", "%1")

            if data then
                local type, sub, icon, body, global = strsplit(":", data)

                if type == "abp" and sub == "macro" then
                    local ok
                    total = total + 1

                    body = self:DecodeLink(body)

                    if self:GetFromCache(macros, self:PackMacro(body)) then
                        ok = true

                    elseif (global and all < MAX_ACCOUNT_MACROS) or (not global and char < MAX_CHARACTER_MACROS) then
                        if check or CreateMacro(name, icon, body, not global) then
                            ok = true
                            self:UpdateCache(macros, -1, self:PackMacro(body), name)
                        end

                        if ok then
                            all = all + ((global and 1) or 0)
                            char = char + ((global and 0) or 1)
                        end
                    end

                    if not ok then
                        fail = fail + 1
                        self:cPrintf(not check, L.msg_cant_create_macro, link)
                    end
                else
                    self:cPrintf(not check, L.msg_bad_link, link)
                end
            else
                self:cPrintf(not check, L.msg_bad_link, link)
            end
        end
    end

    if not check then
        -- correct macro ids
        self:PreloadMacros(macros)
    end

    cache.macros = macros

    if res then
        res.fail = res.fail + fail
        res.total = res.total + total
    end

    return fail, total
end

function ABP:DebugPrintTalents(classProfile, listProfile)
    local classProfiles = self.db and self.db.profiles[classProfile]
    if not classProfiles then
        print("Class profile not found: " .. tostring(classProfile))
        return
    end

    local profile = classProfiles.list and classProfiles.list[listProfile]
    if not profile or not profile.talents then
        print("List profile not found in class profile: " .. tostring(listProfile))
        return
    end

    print("Talents in profile: " .. listProfile)
    for i, talentInfo in ipairs(profile.talents) do
        print("Talent " .. i .. ": " .. talentInfo.spellName .. " (ID: " .. talentInfo.spellID .. ")")
    end
end

SLASH_ABPDEBUG1 = '/abpdebug'

SlashCmdList["ABPDEBUG"] = function(input)
    local listProfile = input:trim()
    if listProfile and listProfile ~= "" then
        -- Assuming PALADIN as default class profile for this example
        local classProfile = "PALADIN"
        ABP:DebugPrintTalents(classProfile, listProfile)
    else
        print("You must provide a list profile name.")
    end
end



local function OnAddonLoaded(self, event, arg1)
    if arg1 == "ActionBarProfiles" then  -- Replace with the actual name of your addon
        -- Check if ActionBarProfilesDBv3 is available
        if ActionBarProfilesDBv3 then
            ABP.db = ActionBarProfilesDBv3
            print("ActionBarProfilesDBv3 assigned to ABP.db")

            -- Initialize the talents table
            ActionBarProfilesDBv3.talentsByProfile = ActionBarProfilesDBv3.talentsByProfile or {}
            print("Initialized talentsByProfile in ActionBarProfilesDBv3")

            -- Call your UpdateTalentsTable function here if needed
            if addon.UpdateTalentsTable then
                addon:UpdateTalentsTable()
            else
                --print("Error: UpdateTalentsTable function not found.")
            end
        else
            --print("Error: ActionBarProfilesDBv3 is not available.")
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnAddonLoaded)

-- -- Function to get talents for a given class and profile name
-- function GetTalentsForProfile(class, profileName)
	-- ActionBarProfilesDBv3.talentsByProfile = ActionBarProfilesDBv3.talentsByProfile or {}
    -- if not ActionBarProfilesDBv3 or not ActionBarProfilesDBv3.profiles or not ActionBarProfilesDBv3.profiles[class] then
        -- return nil
    -- end

    -- local classProfiles = ActionBarProfilesDBv3.profiles[class]
    -- local profile = classProfiles.list and classProfiles.list[profileName]

    -- if profile and profile.talents then
        -- return profile.talents
    -- end

    -- return nil
-- end

-- -- Example usage
-- local class = "PALADIN"
-- local profileName = "Paladin-Ret"
-- local talents = GetTalentsForProfile(class, profileName)

-- if talents then
    -- for _, talent in ipairs(talents) do
        -- print("Talent ID:", talent.entryID)
        -- print("Talent Spell ID:", talent.spellID)
        -- print("Talent Spell Name:", talent.spellName)
        -- -- Add code here to handle talent (e.g., learning the talent if not already learned)
    -- end
-- else
    -- print("No talents found for", class, profileName)
-- end



function addon:RestoreTalents(profile, check, cache, res)
    print("Debug: RestoreTalents called with profile:", profile.name)
    local fail, total = 0, 0
    local talents = { id = {}, name = {} }
    local rest = self.auraState or IsResting()

    -- Apply talents from the profile using the new API method
    if not check then
        local specIndex = GetSpecialization()
        if specIndex then
            local specID = select(1, GetSpecializationInfo(specIndex))
            local treeID = C_ClassTalents.GetTraitTreeForSpec(specID)
            if treeID then
                configID = C_Traits.GetConfigIDByTreeID(treeID)
                print("Debug: Obtained configID -", configID)
            else
                print("Error: Invalid treeID")
            end
        else
            print("Error: Unable to obtain specialization information")
        end

        if configID then
            -- Call ApplyTalentsFromProfile function
            ApplyTalentsFromProfile(profile, configID)
        else
            print("Error: configID not found.")
        end
    end
	
    for tier = 1, MAX_TALENT_TIERS do
        local link = profile.talents[tier]
		print("Debug: Processing Talent - Tier:", tier, "Link:", link)
		if type(link) == "string" then
			local ok
			total = total + 1
			local data, name = link:match("^|c.-|H(.-)|h%[(.-)%]|h|r$")
			link = link:gsub("|Habp:.+|h(%[.+%])|h", "%1")

            if data then
                local type, sub = strsplit(":", data)
                local id = tonumber(sub)

                if type == "talent" then
                    local found = self:GetFromCache(cache.allTalents[tier], id, name, not check and link)
                    print("Debug: Found Talent - ID:", id, "Found:", found)
                    if found then
                        if self:GetFromCache(cache.talents, id) or rest or select(2, GetTalentTierInfo(tier, 1)) == 0 then
                            ok = true
                            self:UpdateCache(talents, found, id, select(2, GetTalentInfoByID(id)))
                            if not check then
                                print("Debug: Attempting to learn Talent - Tier:", tier, "ID:", id)
                                LearnTalent(found)
                            end
                        else
                            print("Debug: Cannot learn Talent now - Tier:", tier, "ID:", id, "Resting State:", rest, "Talent Available:", select(2, GetTalentTierInfo(tier, 1)))
                            self:cPrintf(not check, L.msg_cant_learn_talent, link)
                        end
                    else
                        print("Debug: Talent not found in cache - Tier:", tier, "ID:", id)
                        self:cPrintf(not check, L.msg_talent_not_exists, link)
                    end
                else
                    print("Debug: Invalid talent link type - Tier:", tier, "Link:", link)
                    self:cPrintf(not check, L.msg_bad_link, link)
                end
            else
                print("Debug: Bad link format - Tier:", tier, "Link:", link)
                self:cPrintf(not check, L.msg_bad_link, link)
            end

            if not ok then
                fail = fail + 1
            end
        else
            print("Debug: Link is not a string - Tier:", tier, "Link:", tostring(link))

            -- Debugging logic for table links
            if type(link) == "table" then
                -- Print the content of the table for debugging
                for key, value in pairs(link) do
                    --print("Key:", key, "Value:", value)
                end
                -- Additional logic to handle table type links
                -- You will need to update this part based on the structure of the table
            end
        end
    end

    cache.talents = talents

    if res then
        res.fail = res.fail + fail
        res.total = res.total + total
    end

    return fail, total
end


function ApplyTalentsFromProfile(profile, configID)
	print("Debug: Running ApplyTalentsFromProfile with configID:", configID)
    -- Ensure profile and configID are valid
    if not profile or not profile.talents or not configID then
        print("Invalid profile or configuration ID.")
        return
    end

    -- Apply talents from the profile
    for _, talentInfo in ipairs(profile.talents) do
        if talentInfo.ranksPurchased > 0 then
            print("Debug: Applying talent:", talentInfo.spellName, "ID:", talentInfo.spellID, "NodeID:", talentInfo.nodeID)

            -- Check if the talent is a selection node or a regular node
            if talentInfo.isSelectionNode then
                -- Apply selection node
                local selectSuccess = C_Traits.SetSelection(configID, talentInfo.nodeID, talentInfo.entryID)
                if not selectSuccess then
                    print("Failed to select talent:", talentInfo.spellName)
                end
            else
                -- Purchase rank for regular nodes
                local purchaseSuccess = C_Traits.PurchaseRank(configID, talentInfo.nodeID)
                if not purchaseSuccess then
                    print("Failed to purchase talent:", talentInfo.spellName)
                end
            end
        end
    end

    -- Commit the changes
    local commitSuccess = C_Traits.CommitConfig(configID)
    if not commitSuccess then
        print("There was an error committing the talent configuration.")
    end
end



-- PlayerTalentFrameTalents
function PlayerTalentFrameTalent_OnClick(self, button)
	if ( selectedSpec and (activeSpec == selectedSpec)) then
        local talentID = self:GetID()
		local _, _, _, _, available, _, _, _, _, known = GetTalentInfoByID(talentID, specs[selectedSpec].talentGroup, true);
		if ( available and not known and button == "LeftButton") then
            return LearnTalent(talentID);
		end
	end
	return false;
end


function addon:LearnTalentsFromDB(profileName)
    local profile = self.db.profile.list[profileName]
    if not profile or not profile.talents then return end

    for _, talentData in ipairs(profile.talents) do
        if talentData and talentData.nodeID and talentData.ranksPurchased > 0 then
            local talentID = talentData.nodeID
            -- Check if the talent is already learned
            local _, _, _, isSelected = GetTalentInfoByID(talentID, 1)
            if not isSelected then
                LearnTalent(talentID)
            else
                print("Talent already learned:", talentData.spellName, "ID:", talentID)
            end
        end
    end
end









function addon:RestorePvpTalents(profile, check, cache, res)
    if not profile.pvpTalents then
        return 0, 0
    end

    local fail, total = 0, 0
    local pvpTalents = { id = {}, name = {} }
    local rest = self.auraState or IsResting()

    for tier = 1, 3 do
        local link = profile.pvpTalents[tier]
        if link then
            local ok
            total = total + 1

            local data, name = link:match("^|c.-|H(.-)|h%[(.-)%]|h|r$")
            link = link:gsub("|Habp:.+|h(%[.+%])|h", "%1")

            if data then
                local type, sub = strsplit(":", data)
                local id = tonumber(sub)

                if type == "pvptal" then
                    local found = self:GetFromCache(cache.allPvpTalents[tier], id, name, not check and link)
                    if found then
                        if self:GetFromCache(cache.pvpTalents, id) or rest or select(2, GetPvpTalentInfoByID(id, 1)) == 0 then
                            ok = true
                            self:UpdateCache(pvpTalents, found, id, select(2, GetPvpTalentInfoByID(id)))
                            if not check then
                                LearnPvpTalent(found, tier)
                            end
                        else
                            self:cPrintf(not check, L.msg_cant_learn_talent, link)
                        end
                    else
                        self:cPrintf(not check, L.msg_talent_not_exists, link)
                    end
                else
                    self:cPrintf(not check, L.msg_bad_link, link)
                end
            else
                self:cPrintf(not check, L.msg_bad_link, link)
            end

            if not ok then
                fail = fail + 1
            end
        end
    end

    cache.pvpTalents = pvpTalents

    if res then
        res.fail = res.fail + fail
        res.total = res.total + total
    end

    return fail, total
end



--
--
---- FURYUS DIRTY HACK PVP TALENT RESTORE
---- reads directly from the db file pvpTalents table and not the cache
--
--function addon:RestorePvpTalents(profile, check)
--	local fail, total = 0, 0
--
--	local tier
--	for tier = 1, 3 do
--		local id = profile.pvpTalents[tier]
--		if id then
--			-- has action
--			local ok
--			total = total + 1
--			if id == tonumber(id) then
--				ok = true
--				if not check then
--					LearnPvpTalent(id, tier)
--				end
--			else
--				self:cPrintf(not check, L.msg_bad_link, id)
--			end
--
--			if not ok then
--				fail = fail + 1
--			end
--		end
--	end
--
--	return fail, total
--end
--
--

function addon:RestoreActions(profile, check, cache, res)
    local fail, total = 0, 0

    local slot
    for slot = 1, ABP_MAX_ACTION_BUTTONS do
        local link = profile.actions[slot]
        if (slot >= 145 and slot <= 156) then
            if not link then
                link = profile.actions[slot-132]
            end
        end
        if link then
            -- has action
            local ok
            total = total + 1

            local data, name = link:match("^|c.-|H(.-)|h%[(.-)%]|h|r$")
            link = link:gsub("|Habp:.+|h(%[.+%])|h", "%1")

            if data then
                local type, sub, p1, p2, _, _, _, p6 = strsplit(":", data)
                local id = tonumber(sub)

                if type == "spell" or type == "talent" then
                    if id == ABP_RANDOM_MOUNT_SPELL_ID then
                        ok = true

                        if not check then
                            self:PlaceMount(slot, 0, link)
                        end
                    else
                        local found = self:FindSpellInCache(cache.spells, id, name, not check and link)
                        if found then
                            ok = true

                            if not check then
                                self:PlaceSpell(slot, found, link)
                            end
                        else
                            found = self:GetFromCache(cache.talents, id, name, not check and link)
                            if found then
                                ok = true

                                if not check then
                                    self:PlaceTalent(slot, found, link)
                                end
                            end
                        end
                    end

                    self:cPrintf(not ok and not check, L.msg_spell_not_exists, link)

                -- almost certain this routine not needed since a pvp talent that is placed on an action bar is recorded on the bar with its spellid rather than its talentid
                elseif type == "pvptal" then
                    local found = self:GetFromCache(cache.pvpTalents, id, name, not check and link)
                    if found then
                        ok = true

                        if not check then
                            self:PlacePvpTalent(slot, found, link)
                        end
                    end

                    self:cPrintf(not ok and not check, L.msg_spell_not_exists, link)

                elseif type == "item" then
                    if PlayerHasToy(id) then
                        ok = true

                        if not check then
                            self:PlaceItem(slot, id, link)
                        end
                    else
                        local found = self:FindItemInCache(cache.equip, id, name, not check and link)
                        if found then
                            ok = true

                            if not check then
                                self:PlaceInventoryItem(slot, found, link)
                            end
                        else
                            found = self:FindItemInCache(cache.bags, id, name, not check and link)
                            if found then
                                ok = true

                                if not check then
                                    self:PlaceContainerItem(slot, found[1], found[2], link)
                                end
                            end
                        end
                    end

                    if not ok and not check then
                        self:PlaceItem(slot, S2KFI:GetConvertedItemId(id) or id, link)
                    end

                    ok = true   -- sic!

                elseif type == "battlepet" then
                    local found = self:GetFromCache(cache.pets, p6, id, not check and link)
                    if found then
                        ok = true

                        if not check then
                            self:PlacePet(slot, found, link)
                        end
                    end

                    self:cPrintf(not ok and not check, L.msg_pet_not_exists, link)

                elseif type == "abp" then
                    id = tonumber(p1)

                    if sub == "flyout" then
                        local found = self:FindFlyoutInCache(cache.flyouts, id, name, not check and link)
                        if found then
                            ok = true

                            if not check then
                                self:PlaceFlyout(slot, found, BOOKTYPE_SPELL, link)
                            end
                        end

                        self:cPrintf(not ok and not check, L.msg_spell_not_exists, link)

                    elseif sub == "macro" then
                        local found = self:GetFromCache(cache.macros, self:PackMacro(self:DecodeLink(p2)), name, not check and link)
                        if found then
                            ok = true

                            if not check then
                                self:PlaceMacro(slot, found, link)
                            end
                        end

                        if profile.skipMacros then
                            self:cPrintf(not ok and not check, L.msg_macro_not_exists, link)
                        else
                            total = total - 1
                            if not ok then
                                fail = fail - 1
                            end
                        end

                    elseif sub == "equip" then
                        if GetEquipmentSetInfoByName(name) then
                            ok = true

                            if not check then
                                self:PlaceEquipment(slot, name, link)
                            end
                        end

                        self:cPrintf(not ok and not check, L.msg_equip_not_exists, link)
                    else
                        self:cPrintf(not check, L.msg_bad_link, link)
                    end
                else
                    self:cPrintf(not check, L.msg_bad_link, link)
                end
            else
                self:cPrintf(not check, L.msg_bad_link, link)
            end

            if not ok then
                fail = fail + 1

                if not profile.skipEmptySlots and not check then
                    self:ClearSlot(slot)
                end
            end
        else
            if not profile.skipEmptySlots and not check then
                self:ClearSlot(slot)
            end
        end
    end

	function addon:ShouldSkipClearingActionBar2()
		for i = 13, 24 do
			self:ClearSlot(i)
		end
		return false
	end

    if res then
        res.fail = res.fail + fail
        res.total = res.total + total
    end

    return fail, total
end

function addon:RestoreSingleAction(action, slot, cache)
    local fail = 0
    if action then
        -- has action
        local link = action
        local ok

        local data, name = link:match("^|c.-|H(.-)|h%[(.-)%]|h|r$")
        link = link:gsub("|Habp:.+|h(%[.+%])|h", "%1")

        if data then
            local type, sub, p1, p2, _, _, _, p6 = strsplit(":", data)
            local id = tonumber(sub)

            if type == "spell" or type == "talent" then
                if id == ABP_RANDOM_MOUNT_SPELL_ID then
                    ok = true

                    if not check then
                        self:PlaceMount(slot, 0, link)
                    end
                else
                    local found = self:FindSpellInCache(cache.spells, id, name, not check and link)
                    if found then
                        ok = true

                        if not check then
                            self:PlaceSpell(slot, found, link)
                        end
                    else
                        found = self:GetFromCache(cache.talents, id, name, not check and link)
                        if found then
                            ok = true

                            if not check then
                                self:PlaceTalent(slot, found, link)
                            end
                        end
                    end
                end

                self:cPrintf(not ok and not check, L.msg_spell_not_exists, link)

            -- almost certain this routine not needed since a pvp talent that is placed on an action bar is recorded on the bar with its spellid rather than its talentid
            elseif type == "pvptal" then
                local found = self:GetFromCache(cache.pvpTalents, id, name, not check and link)
                if found then
                    ok = true

                    if not check then
                        self:PlacePvpTalent(slot, found, link)
                    end
                end

                self:cPrintf(not ok and not check, L.msg_spell_not_exists, link)

            elseif type == "item" then
                if PlayerHasToy(id) then
                    ok = true

                    if not check then
                        self:PlaceItem(slot, id, link)
                    end
                else
                    local found = self:FindItemInCache(cache.equip, id, name, not check and link)
                    if found then
                        ok = true

                        if not check then
                            self:PlaceInventoryItem(slot, found, link)
                        end
                    else
                        found = self:FindItemInCache(cache.bags, id, name, not check and link)
                        if found then
                            ok = true

                            if not check then
                                self:PlaceContainerItem(slot, found[1], found[2], link)
                            end
                        end
                    end
                end

                if not ok and not check then
                    self:PlaceItem(slot, S2KFI:GetConvertedItemId(id) or id, link)
                end

                ok = true   -- sic!

            elseif type == "battlepet" then
                local found = self:GetFromCache(cache.pets, p6, id, not check and link)
                if found then
                    ok = true

                    if not check then
                        self:PlacePet(slot, found, link)
                    end
                end

                self:cPrintf(not ok and not check, L.msg_pet_not_exists, link)

            elseif type == "abp" then
                id = tonumber(p1)

                if sub == "flyout" then
                    local found = self:FindFlyoutInCache(cache.flyouts, id, name, not check and link)
                    if found then
                        ok = true

                        if not check then
                            self:PlaceFlyout(slot, found, BOOKTYPE_SPELL, link)
                        end
                    end

                    self:cPrintf(not ok and not check, L.msg_spell_not_exists, link)

                elseif sub == "macro" then
                    local found = self:GetFromCache(cache.macros, self:PackMacro(self:DecodeLink(p2)), name, not check and link)
                    if found then
                        ok = true

                        if not check then
                            self:PlaceMacro(slot, found, link)
                        end
                    end

                    if profile.skipMacros then
                        self:cPrintf(not ok and not check, L.msg_macro_not_exists, link)
                    else
                    end

                elseif sub == "equip" then
                    if GetEquipmentSetInfoByName(name) then
                        ok = true

                        if not check then
                            self:PlaceEquipment(slot, name, link)
                        end
                    end

                    self:cPrintf(not ok and not check, L.msg_equip_not_exists, link)
                else
                    self:cPrintf(not check, L.msg_bad_link, link)
                end
            else
                self:cPrintf(not check, L.msg_bad_link, link)
            end
        else
            self:cPrintf(not check, L.msg_bad_link, link)
        end

        if not ok then
            fail = fail + 1
            if not profile.skipEmptySlots and not check then
                self:ClearSlot(slot)
            end
        end
    else
        if not profile.skipEmptySlots and not check then
            self:ClearSlot(slot)
        end
    end
    return fail
end

function addon:RestorePetActions(profile, check, cache, res)
    if not HasPetSpells() or not profile.petActions then
        return 0, 0
    end

    local fail, total = 0, 0

    local slot
    for slot = 1, NUM_PET_ACTION_SLOTS do
        local link = profile.petActions[slot]
        if link then
            -- has action
            local ok
            total = total + 1

            local data, name = link:match("^|c.-|H(.-)|h%[(.-)%]|h|r$")
            link = link:gsub("|Habp:.+|h(%[.+%])|h", "%1")

            if data then
                local type, sub, p1 = strsplit(":", data)
                local id = tonumber(sub)

                if type == "spell" or (type == "abp" and sub == "pet") then
                    if type == "spell" then
                        name = GetSpellInfo(id) or name
                    else
                        id = -2
                        name = _G[name] or name
                    end

                    local found = self:GetFromCache(cache.petSpells, id, name, type == "spell" and link)
                    if found then
                        ok = true

                        if not check then
                            self:PlacePetSpell(slot, found, link)
                        end
                    end
                else
                    self:cPrintf(not check, L.msg_bad_link, link)
                end
            else
                self:cPrintf(not check, L.msg_bad_link, link)
            end

            if not ok then
                fail = fail + 1

                if not check then
                    self:ClearPetSlot(slot)
                end
            end
        else
            -- empty slot
            if not check then
                self:ClearPetSlot(slot)
            end
        end
    end

    if res then
        res.fail = res.fail + fail
        res.total = res.total + total
    end

    return fail, total
end

function addon:RestoreBindings(profile, check, cache, res)
    if check then
        return 0, 0
    end

    -- clear
    local index
    for index = 1, GetNumBindings() do
        local bind = { GetBinding(index) }
        if bind[3] then
            local key
            for key in table.s2k_values({ select(3, unpack(bind)) }) do
                SetBinding(key)
            end
        end
    end

    -- restore
    local cmd, keys
    for cmd, keys in pairs(profile.bindings) do
        local key
        for key in table.s2k_values(keys) do
            SetBinding(key, cmd)
        end
    end

    if LibStub("AceAddon-3.0"):GetAddon("Dominos", true) and profile.bindingsDominos then
        for index = 13, 60 do
            local key

            -- clear
            for key in table.s2k_values({ GetBindingKey(string.format("CLICK DominosActionButton%d:LeftButton", index)) }) do
                SetBinding(key)
            end

            -- restore
            if profile.bindingsDominos[index] then
                for key in table.s2k_values(profile.bindingsDominos[index]) do
                    SetBindingClick(key, string.format("DominosActionButton%d", index), "LeftButton")
                end
            end
        end
    end

    SaveBindings(GetCurrentBindingSet())

    return 0, 0
end

function addon:UpdateCache(cache, value, id, name)
    cache.id[id] = value

    if cache.name and name then
        cache.name[name] = value
    end
end

function addon:GetFromCache(cache, id, name, link)
    if cache.id[id] then
        return cache.id[id]
    end

    if cache.name and name and cache.name[name] then
        self:cPrintf(link, DEBUG .. L.msg_found_by_name, link)
        return cache.name[name]
    end
end

function addon:FindSpellInCache(cache, id, name, link)
    name = GetSpellInfo(id) or name

    local found = self:GetFromCache(cache, id, name, link)
    if found then
        return found
    end

    local similar = ABP_SIMILAR_SPELLS[id]
    if similar then
        local alt
        for alt in table.s2k_values(similar) do
            local found = self:GetFromCache(cache, alt)
            if found then
                return found
            end
        end
    end
end

function addon:FindFlyoutInCache(cache, id, name, link)
    local ok, info_name = pcall(GetFlyoutInfo, id)
    if ok then
        name = info_name
    end

    local found = self:GetFromCache(cache, id, name, link)
    if found then
        return found
    end
end

function addon:FindItemInCache(cache, id, name, link)
    local found = self:GetFromCache(cache, id, name, link)
    if found then
        return found
    end

    local alt = S2KFI:GetConvertedItemId(id)
    if alt then
        found = self:GetFromCache(cache, alt)
        if found then
            return found
        end
    end

    local similar = ABP_SIMILAR_ITEMS[id]
    if similar then
        for alt in table.s2k_values(similar) do
            found = self:GetFromCache(cache, alt)
            if found then
                return found
            end
        end
    end
end

function addon:MakeCache()
    local cache = {
        talents = { id = {}, name = {} },
        allTalents = {},

        pvpTalents = { id = {}, name = {} },
        allPvpTalents = {},

        spells = { id = {}, name = {} },
        flyouts = { id = {}, name = {} },

        equip = { id = {}, name = {} },
        bags = { id = {}, name = {} },

        pets = { id = {}, name = {} },

        macros = { id = {}, name = {} },

        petSpells = { id = {}, name = {} },
    }

    self:PreloadTalents(cache.talents, cache.allTalents)
    self:PreloadPvpTalents(cache.pvpTalents, cache.allPvpTalents)
    --self:PreloadPvpTalentSpells(cache.spells)

    self:PreloadSpecialSpells(cache.spells)
    self:PreloadSpellbook(cache.spells, cache.flyouts)
    self:PreloadMountjournal(cache.spells)
    self:PreloadCombatAllySpells(cache.spells)

    self:PreloadEquip(cache.equip)
    self:PreloadBags(cache.bags)

    self:PreloadPetJournal(cache.pets)

    self:PreloadMacros(cache.macros)

    self:PreloadPetSpells(cache.petSpells)

    return cache
end

function addon:PreloadSpecialSpells(spells)
    local level = UnitLevel("player")
    local class = select(2, UnitClass("player"))
    local faction = UnitFactionGroup("player")
    local spec = GetSpecializationInfo(GetSpecialization())

    local id, info
    for id, info in pairs(ABP_SPECIAL_SPELLS) do
        if (not info.level or level >= info.level) and
            (not info.class or class == info.class) and
            (not info.faction or faction == info.faction) and
            (not info.spec or spec == info.spec)
        then
            self:UpdateCache(spells, id, id)

            if info.altSpellIds then
                local alt
                for alt in table.s2k_values(info.altSpellIds) do
                    self:UpdateCache(spells, id, alt)
                end
            end
        end
    end
end

function addon:PreloadSpellbook(spells, flyouts)
    local tabs = {}

    local book
    for book = 1, GetNumSpellTabs() do
        local offset, count, _, spec = select(3, GetSpellTabInfo(book))

        if spec == 0 then
            table.insert(tabs, { type = BOOKTYPE_SPELL, offset = offset, count = count })
        end
    end

    local prof
    for prof in table.s2k_values({ GetProfessions() }) do
        if prof then
            local count, offset = select(5, GetProfessionInfo(prof))

            table.insert(tabs, { type = BOOKTYPE_PROFESSION, offset = offset, count = count })
        end
    end

    local tab
    for tab in table.s2k_values(tabs) do
        local index
        for index = tab.offset + 1, tab.offset + tab.count do
            local type, id = GetSpellBookItemInfo(index, tab.type)
            local name = GetSpellBookItemName(index, tab.type)

            if type == "FLYOUT" then
                self:UpdateCache(flyouts, index, id, name)
                -- Handle FLYOUTS that actually contain spells
                local name, description, numSlots, isKnown = GetFlyoutInfo(id)
                for idx = 1, numSlots do
                    local flyoutid, _, isKnown, spellName, _ = GetFlyoutSlotInfo(id, idx)
                    self:UpdateCache(spells, flyoutid, flyoutid, spellName)
                end

            elseif type == "SPELL" then
                self:UpdateCache(spells, id, id, name)
            end
        end
    end
end

function addon:PreloadMountjournal(mounts)
    local all = C_MountJournal.GetMountIDs()
    local faction = (UnitFactionGroup("player") == "Alliance" and 1) or 0

    local mount
    for mount in table.s2k_values(all) do
        local name, id, required, collected = table.s2k_select({ C_MountJournal.GetMountInfoByID(mount) }, 1, 2, 9, 11)

        if collected and (not required or required == faction) then
            self:UpdateCache(mounts, id, id, name)
        end
    end
end

function addon:PreloadCombatAllySpells(spells)
    local follower
    for follower in table.s2k_values(C_Garrison.GetFollowers() or {}) do
        if follower.garrFollowerID then
            local id
            for id in table.s2k_values({ C_Garrison.GetFollowerZoneSupportAbilities(follower.garrFollowerID) }) do
                local name = GetSpellInfo(id)
                self:UpdateCache(spells, 211390, id, name)
            end
        end
    end
end

function addon:PreloadTalents(talents, all)
    local tier
    for tier = 1, MAX_TALENT_TIERS do
        all[tier] = all[tier] or { id = {}, name = {} }

        if GetTalentTierInfo(tier, 1) then
            local column
            for column = 1, NUM_TALENT_COLUMNS do
                local id, name, _, selected = GetTalentInfo(tier, column, 1)

                if selected then
                    self:UpdateCache(talents, id, id, name)
                end

                self:UpdateCache(all[tier], id, id, name)
            end
        end
    end
end

function addon:PreloadPvpTalents(pvpTalents, allPvpTalents)
    local pvpTalentIDs = {}
    pvpTalentIDs = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
    local tier
    for tier = 1, 3 do
        allPvpTalents[tier] = allPvpTalents[tier] or { id = {}, name = {} }

        if pvpTalentIDs[tier] then
            if GetPvpTalentInfoByID(pvpTalentIDs[tier]) then
                local id, name, _, _, available, spellID, unlocked, _, _, known = GetPvpTalentInfoByID(pvpTalentIDs[tier])
                if available and unlocked and known then
                    self:UpdateCache(pvpTalents, id, id, name)
                end
            end
        end

        local pvpAvailableTalentIDs = {}
        pvpAvailableTalentIDs = C_SpecializationInfo.GetPvpTalentSlotInfo(tier).availableTalentIDs
        local row
        for row = 1, #pvpAvailableTalentIDs do
            local id, name, _, _, available, spellID, unlocked, _, _, known = GetPvpTalentInfoByID(pvpAvailableTalentIDs[row])
            self:UpdateCache(allPvpTalents[tier], id, id, name)
        end
    end
end

--function addon:PreloadPvpTalentSpells(spells)
--    local pvpTalentIDs = {}
--    pvpTalentIDs = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
--    local tier
--    for tier = 1, 3 do
--        if pvpTalentIDs[tier] then
--            if GetPvpTalentInfoByID(pvpTalentIDs[tier]) then
--                local id, name, _, _, available, spellID, unlocked, _, _, known = GetPvpTalentInfoByID(pvpTalentIDs[tier])
--                if available and unlocked and known then
--                    self:UpdateCache(spells, spellID, spellID, name)
--                end
--            end
--        end
--    end
--end
--
function addon:PreloadEquip(equip)
    local slot
    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local id = GetInventoryItemID("player", slot)
        if id then
            self:UpdateCache(equip, slot, id, GetItemInfo(id))
        end
    end
end

function addon:PreloadBags(bags)
    local bag
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local index
        for index = 1, C_Container.GetContainerNumSlots(bag) do
            local id = C_Container.GetContainerItemID(bag, index)
            if id then
                self:UpdateCache(bags, { bag, index }, id, GetItemInfo(id))
            end
        end
    end
end

function addon:PreloadPetJournal(pets)
    local saved = self:SavePetJournalFilters()

    C_PetJournal.ClearSearchFilter()

    C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, true)
    C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED, false)

    C_PetJournal.SetAllPetSourcesChecked(true)
    C_PetJournal.SetAllPetTypesChecked(true)

    local index
    for index = 1, C_PetJournal:GetNumPets() do
        local id, species = C_PetJournal.GetPetInfoByIndex(index)
        self:UpdateCache(pets, id, id, species)
    end

    self:RestorePetJournalFilters(saved)
end

function addon:PreloadMacros(macros)
    local all, char = GetNumMacros()

    local index
    for index = 1, all do
        local name, _, body = GetMacroInfo(index)
        if body then
            self:UpdateCache(macros, index, addon:PackMacro(body), name)
        end
    end

    for index = MAX_ACCOUNT_MACROS + 1, MAX_ACCOUNT_MACROS + char do
        local name, _, body = GetMacroInfo(index)
        if body then
            self:UpdateCache(macros, index, addon:PackMacro(body), name)
        end
    end
end

function addon:PreloadPetSpells(spells)
    if HasPetSpells() then
        local index
        for index = 1, HasPetSpells() do
            local id = select(2, GetSpellBookItemInfo(index, BOOKTYPE_PET))
            local name = GetSpellBookItemName(index, BOOKTYPE_PET)
            local token = bit.band(id, 0x80000000) == 0 and bit.rshift(id, 24) ~= 1

            id = bit.band(id, 0xFFFFFF)

            if token then
                self:UpdateCache(spells, index, -1, name)
            else
                self:UpdateCache(spells, index, id, name)
            end
        end
    end
end

function addon:ClearSlot(slot)
    ClearCursor()
    PickupAction(slot)
    --ClearCursor()
end

function addon:PlaceToSlot(slot)
    PlaceAction(slot)
    ClearCursor()
end

function addon:ClearPetSlot(slot)
    ClearCursor()
    PickupPetAction(slot)
    ClearCursor()
end

function addon:PlaceToPetSlot(slot)
    PickupPetAction(slot)
    ClearCursor()
end

function addon:PlaceSpell(slot, id, link, count)
    count = count or ABP_PICKUP_RETRY_COUNT

    ClearCursor()
    PickupSpell(id)

    if not CursorHasSpell() then
        if count > 0 then
            self:ScheduleTimer(function()
                self:PlaceSpell(slot, id, link, count - 1)
            end, ABP_PICKUP_RETRY_INTERVAL)
        else
            self:cPrintf(link, DEBUG .. L.msg_cant_place_spell, link)
        end
    else
        self:PlaceToSlot(slot)
    end
end

function addon:PlaceSpellBookItem(slot, id, tab, link, count)
    count = count or ABP_PICKUP_RETRY_COUNT

    ClearCursor()
    PickupSpellBookItem(id, tab)

    if not CursorHasSpell() then
        if count > 0 then
            self:ScheduleTimer(function()
                self:PlaceSpellBookItem(slot, id, tab, link, count - 1)
            end, ABP_PICKUP_RETRY_INTERVAL)
        else
            self:cPrintf(link, DEBUG .. L.msg_cant_place_spell, link)
        end
    else
        self:PlaceToSlot(slot)
    end
end

function addon:PlaceFlyout(slot, id, tab, link, count)
    ClearCursor()
    PickupSpellBookItem(id, tab)

    self:PlaceToSlot(slot)
end

function addon:PlaceTalent(slot, id, link, count)
    count = count or ABP_PICKUP_RETRY_COUNT

    ClearCursor()
    PickupTalent(id)

    if not CursorHasSpell() then
        if count > 0 then
            self:ScheduleTimer(function()
                self:PlaceTalent(slot, id, link, count - 1)
            end, ABP_PICKUP_RETRY_INTERVAL)
        else
            self:cPrintf(link, DEBUG .. L.msg_cant_place_spell, link)
        end
    else
        self:PlaceToSlot(slot)
    end
end

function addon:PlacePvpTalent(slot, id, link, count)
    count = count or ABP_PICKUP_RETRY_COUNT

    ClearCursor()
    PickupPvpTalent(id)

    if not CursorHasSpell() then
        if count > 0 then
            self:ScheduleTimer(function()
                self:PlacePvpTalent(slot, id, link, count - 1)
            end, ABP_PICKUP_RETRY_INTERVAL)
        else
            self:cPrintf(link, DEBUG .. L.msg_cant_place_spell, link)
        end
    else
        self:PlaceToSlot(slot)
    end
end

function addon:PlaceMount(slot, id, link, count)
    ClearCursor()
    C_MountJournal.Pickup(id)

    self:PlaceToSlot(slot)
end

function addon:PlaceItem(slot, id, link, count)
    ClearCursor()
    PickupItem(id)

    self:PlaceToSlot(slot)
end

function addon:PlaceInventoryItem(slot, id, link, count)
    count = count or ABP_PICKUP_RETRY_COUNT

    ClearCursor()
    PickupInventoryItem(id)

    if not CursorHasItem() then
        if count > 0 then
            self:ScheduleTimer(function()
                self:PlaceInventoryItem(slot, id, link, count - 1)
            end, ABP_PICKUP_RETRY_INTERVAL)
        else
            self:cPrintf(link, DEBUG .. L.msg_cant_place_item, link)
        end
    else
        self:PlaceToSlot(slot)
    end
end

function addon:PlaceContainerItem(slot, bag, id, link, count)
    count = count or ABP_PICKUP_RETRY_COUNT

    ClearCursor()
    C_Container.PickupContainerItem(bag, id)

    if not CursorHasItem() then
        if count > 0 then
            self:ScheduleTimer(function()
                self:PlaceContainerItem(slot, id, link, count - 1)
            end, ABP_PICKUP_RETRY_INTERVAL)
        else
            self:cPrintf(link, DEBUG .. L.msg_cant_place_item, link)
        end
    else
        self:PlaceToSlot(slot)
    end
end

function addon:PlacePet(slot, id, link, count)
    ClearCursor()
    C_PetJournal.PickupPet(id)

    self:PlaceToSlot(slot)
end

function addon:PlaceMacro(slot, id, link, count)
    count = count or ABP_PICKUP_RETRY_COUNT

    ClearCursor()
    PickupMacro(id)

    if not CursorHasMacro() then
        if count > 0 then
            self:ScheduleTimer(function()
                self:PlaceMacro(slot, id, link, count - 1)
            end, ABP_PICKUP_RETRY_INTERVAL)
        else
            self:cPrintf(link, DEBUG .. L.msg_cant_place_macro, link)
        end
    else
        self:PlaceToSlot(slot)
    end
end

function addon:PlaceEquipment(slot, id, link, count)
    ClearCursor()
    PickupEquipmentSetByName(id)

    self:PlaceToSlot(slot)
end

function addon:PlacePetSpell(slot, id, link, count)
    ClearCursor()
    PickupSpellBookItem(id, BOOKTYPE_PET)

    self:PlaceToPetSlot(slot)
end

function addon:IsDefault(profile, key)
    if type(profile) ~= "table" then
        local list = self.db.profile.list
        profile = list[profile]

        if not profile then return end
    end

    return profile.fav and profile.fav[key] and true or nil
end