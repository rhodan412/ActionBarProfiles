local addonName, addon = ...
ABP = ABP or {}
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local DEBUG = "|cffff0000Debug:|r "
local GetSpecialization = C_SpecializationInfo.GetSpecialization
local GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
local GetPvpTalentInfoByID = C_SpecializationInfo.GetPvpTalentInfoByID or _G.GetPvpTalentInfoByID
local GetPvpTalentLink = C_SpecializationInfo.GetPvpTalentLink or _G.GetPvpTalentLink

-- These globals are no longer exported by the Retail client, although macro
-- indices still reserve slots 1-120 for account macros.
local MAX_ACCOUNT_MACROS = _G.MAX_ACCOUNT_MACROS or 120

-- Tries to guess a unique name for a new profile.
-- If the provided name is not in use, it returns that name.
-- Otherwise, it appends a number to the name to create a unique one.
function addon:GuessName(name)
    local list = self.db.profile.list  -- Retrieve the list of existing profiles.

    if not list[name] then  -- Check if the name is not already in use.
        return name  -- Return the provided name if it is unique.
    end

    -- Iterate through numbers from 2 to 99 to find a unique name.
    for i = 2, 99 do
        local try = string.format("%s (%d)", name, i)  -- Generate a new name by appending a number.
        if not list[try] then  -- Check if this generated name is unique.
            return try  -- Return the generated unique name.
        end
    end
end


-- Saves a profile with the specified name and options.
-- Updates the profile options and GUI, and prints a message indicating that the profile has been saved.
function addon:SaveProfile(name, options)
    local list = self.db.profile.list  -- Retrieve the list of profiles.
    local profile = list[name] or { name = name }  -- Retrieve existing profile or create a new one with the given name.

    -- Save the current specID
    profile.specID = GetSpecializationInfo(GetSpecialization())
    if not profile.specID then
        self:Printf("Error: Unable to save profile, specID is missing or invalid.")
        return
    end

    -- Debug: Log the name of the profile being saved
    self:Printf("Debug: Saving profile %s with specID %s", name, tostring(profile.specID))

    -- Update the profile with talents, actions, and other necessary data
    self:UpdateProfileOptions(profile, options, true)
    self:UpdateProfile(profile, true)

    -- Save the profile back to the database
    list[name] = profile

    -- Confirm profile is saved
    self:Printf("Profile %s updated", name)

    -- Update the GUI to reflect the changes
    self:UpdateGUI()

    -- Print a message indicating that the profile has been saved
    self:Printf(L.msg_profile_saved, name)
end


-- Updates the options for a given profile and optionally refreshes the GUI.
-- If the profile is passed as a name, it is retrieved from the list.
-- Existing options starting with "skip" are removed, and new options are applied.
function addon:UpdateProfileOptions(profile, options, quiet)
    if type(profile) ~= "table" then  -- Check if profile is a name instead of a table.
        local list = self.db.profile.list
        profile = list[profile]  -- Retrieve the profile from the list.

        if not profile then return end  -- Exit if the profile doesn't exist.
    end

    if options then  -- If there are options provided, update the profile.
        -- Remove existing options that start with "skip".
        for k in pairs(profile) do
            if k:sub(1, 4) == "skip" then
                profile[k] = nil
            end
        end

        -- Apply the new options to the profile.
        for k, v in pairs(options) do
            profile[k] = v
        end
    end

    if not quiet then  -- If not in quiet mode, refresh the GUI and print a message.
        self:UpdateGUI()
        self:Printf(L.msg_profile_updated, profile.name)
    end
end


-- Updates a profile with the current player's class, icon, and actions.
-- Saves the profile's actions, pet actions, and bindings, and optionally refreshes the GUI.
function addon:UpdateProfile(profile, quiet)
    if type(profile) ~= "table" then  -- Check if profile is a name instead of a table.
        local list = self.db.profile.list
        profile = list[profile]  -- Retrieve the profile from the list.

        if not profile then return end  -- Exit if the profile doesn't exist.
    end

    -- Set the profile's class and icon based on the current player's data.
    profile.class = select(2, UnitClass("player"))
    profile.icon  = select(4, GetSpecializationInfo(GetSpecialization()))

    -- Save the profile's actions, pet actions, and bindings.
    self:SaveActions(profile)
    self:SavePetActions(profile)
    self:SaveBindings(profile)

    if not quiet then  -- If not in quiet mode, refresh the GUI and print a message.
        self:UpdateGUI()
        self:Printf(L.msg_profile_updated, profile.name)
    end

    return profile  -- Return the updated profile.
end


-- Renames a profile in the list and optionally refreshes the GUI.
-- The old name is removed from the list, and the profile is saved under the new name.
function addon:RenameProfile(name, rename, quiet)
    local list = self.db.profile.list
    local profile = list[name]  -- Retrieve the profile by its current name.

    if not profile then return end  -- Exit if the profile doesn't exist.

    profile.name = rename  -- Update the profile's name to the new name.

    list[name] = nil  -- Remove the old name from the list.
    list[rename] = profile  -- Save the profile under the new name.

    if not quiet then  -- If not in quiet mode, refresh the GUI.
        self:UpdateGUI()
    end

    -- Print a message indicating the profile has been renamed.
    self:Printf(L.msg_profile_renamed, name, rename)
end


-- Deletes a profile from the list and refreshes the GUI.
-- Also prints a message confirming the profile's deletion.
function addon:DeleteProfile(name)
    local list = self.db.profile.list

    list[name] = nil  -- Remove the profile from the list.

    self:UpdateGUI()  -- Refresh the GUI to reflect the change.
    self:Printf(L.msg_profile_deleted, name)  -- Print a message confirming the deletion.
end


-- This function saves the player's current action bar setup into the provided profile.
function addon:SaveActions(profile)
    local flyouts, tsNames, tsIds = {}, {}, {}

    ---@class SpellBookSkillLineInfo
    ---@field itemIndexOffset number

    for skillLineIndex = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
        local offset = skillLineInfo.itemIndexOffset
        local count = skillLineInfo.numSpellBookItems
        local spec = skillLineInfo.specID or 0

        if spec == 0 then
            for index = offset + 1, offset + count do
            ---@type Enum.SpellBookSpellBank
            local spellBookBankType = Enum.SpellBookSpellBank.Player
                local type, id = C_SpellBook.GetSpellBookItemType(index, Enum.SpellBookSpellBank.Player)
                local name = C_SpellBook.GetSpellBookItemName(index, Enum.SpellBookSpellBank.Player)

                if type == "FLYOUT" then
                    flyouts[id] = name
                elseif type == "SPELL" and C_SpellBook.IsClassTalentSpellBookItem(index, Enum.SpellBookSpellBank.Player) then
                    tsNames[name] = id
                elseif type == "SPELL" and C_SpellBook.IsPvPTalentSpellBookItem(index, Enum.SpellBookSpellBank.Player) then
                    tsNames[name] = id
                end
            end
        end
    end

    local talents = {}
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return end

    ---@class TraitConfigInfo
    ---@field ID number
    ---@field type Enum.TraitConfigType
    ---@field name string
    ---@field treeIDs number[]
    ---@field usesSharedActionBars boolean

    local configInfo = C_Traits.GetConfigInfo(configID) ---@type TraitConfigInfo
    if not configInfo or not configInfo.treeIDs then return end

    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodes = C_Traits.GetTreeNodes(treeID)

        for _, nodeID in ipairs(nodes or {}) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)

            for _, entryID in ipairs(nodeInfo and nodeInfo.entryIDsWithCommittedRanks or {}) do
                local entryInfo = C_Traits.GetEntryInfo(configID, entryID)

                ---@class TraitEntryInfo
                ---@field entryID number
                ---@field rank number
                ---@field definitionID number
                if entryInfo and entryInfo.definitionID then
                    local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)

                    ---@class TraitDefinitionInfo
                    ---@field spellID number
                    if definitionInfo and definitionInfo.spellID then
                        local spellInfo = C_Spell.GetSpellInfo(definitionInfo.spellID)
                        if spellInfo and spellInfo.name then
                            local isFreeTalent = nodeInfo.currentRank > 0 and nodeInfo.ranksPurchased == 0 and not nodeInfo.canPurchaseRank
                            talents[#talents + 1] = {
                                nodeID = nodeInfo.ID,
                                entryID = entryID,
                                spellID = definitionInfo.spellID,
                                spellName = spellInfo.name,
                                ranksPurchased = nodeInfo.ranksPurchased,
                                maxRanks = nodeInfo.maxRanks,
                                isSelectionNode = #nodeInfo.entryIDs > 1,
                                posX = nodeInfo.posX,
                                posY = nodeInfo.posY,
                                --row = nodeInfo.row,   -- "row" and "column" are not part of officially documented field within TraitNodeInfo
                                --column = nodeInfo.column,
                                isFreeTalent = isFreeTalent or false -- Flag to identify free talents
                            }
                        else
                            print("Warning: Unable to retrieve spell information for spellID:", definitionInfo.spellID)
                        end
                    end
                elseif entryInfo and entryInfo.subTreeID then
                    -- Hero talent choices are structural entries.  They select a
                    -- sub-tree and intentionally have no definitionID or spellID.
                    -- Preserve them so a profile can restore its hero specialization.
                    talents[#talents + 1] = {
                        nodeID = nodeInfo.ID,
                        entryID = entryID,
                        ranksPurchased = nodeInfo.ranksPurchased,
                        maxRanks = nodeInfo.maxRanks,
                        isSelectionNode = true,
                        isSubTreeSelection = true,
                        subTreeID = entryInfo.subTreeID,
                        posX = nodeInfo.posX,
                        posY = nodeInfo.posY,
                        isFreeTalent = nodeInfo.currentRank > 0 and nodeInfo.ranksPurchased == 0 and not nodeInfo.canPurchaseRank,
                    }
                end
            end
        end
    end

    -- Sort talents by vertical position (posY) to ensure proper order of unlocking
    table.sort(talents, function(a, b) return a["posY"] < b["posY"] end)
    profile.talents = talents  -- Save the talents in the profile

    -- Save PvP talents and their associated spell links
    local pvpTalentIDs, pvpTalents, pvpTalentSpells = {}, {}, {}
    pvpTalentIDs = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()

    for tier = 1, #pvpTalentIDs do
        -- Save the PvP Talent Link
        ---@diagnostic disable-next-line: redundant-parameter
        pvpTalents[tier] = GetPvpTalentLink(pvpTalentIDs[tier])
        --print("pvpTalents [Tier] are: " .. pvpTalents[tier])

        -- Retrieve spell info and save the spell link using the new API
        local id = select(6, GetPvpTalentInfoByID(pvpTalentIDs[tier]))
        pvpTalentSpells[tier] = C_Spell.GetSpellLink(id)
    end

    profile.pvpTalentsIds = pvpTalentIDs  -- Save PvP talent IDs in the profile
    profile.pvpTalents = pvpTalents  -- Save PvP talent links in the profile
    profile.pvpTalentSpells = pvpTalentSpells  -- Save PvP talent spell links in the profile

    -- Save actions on the player's action bars
    local actions = {}
    local savedMacros = {}

    -- Check if the RandomHearth addon is loaded
    local isRandomHearthstoneLoaded = C_AddOns.IsAddOnLoaded("RandomHearth")

    for slot = 1, ABP_MAX_ACTION_BUTTONS do
        local type, id, sub = GetActionInfo(slot)  -- Retrieve action info for the slot

        if type == "spell" then
            if tsIds[id] then
                actions[slot] = GetTalentLink(tsIds[id])
            elseif id then
                actions[slot] = C_Spell.GetSpellLink(id)  -- Save spell link
            end

        elseif type == "flyout" then
            if flyouts[id] then
                actions[slot] = string.format(
                    "|cffff0000|Habp:flyout:%d|h[%s]|h|r",
                    id, flyouts[id]
                )
            end

        elseif type == "item" then
            -- Ensure id is not nil before using it
            if id then
                -- Use the new API to get item info
                local itemName, itemLink = C_Item.GetItemInfo(id)
                if itemLink then
                    actions[slot] = itemLink  -- Save item link
                else
                    -- If item is not yet cached, you might want to handle it asynchronously
                    actions[slot] = string.format("|cffff0000|Habp:item:%d|h[%s]|h|r", id, "Unknown Item")
                end
            else
                -- Handle the case where id is nil
                actions[slot] = "|cffff0000|Habp:item:0|h[Unknown Item]|h|r"
            end

        elseif type == "companion" then
            if sub == "MOUNT" and id then
                actions[slot] = C_Spell.GetSpellLink(id)  -- Save mount spell link
            else
                -- Handle the case where id is nil or sub is not "MOUNT"
                actions[slot] = "|cffff0000|Habp:companion:0|h[Unknown Mount]|h|r"
            end

        elseif type == "summonpet" then
            if id then
                actions[slot] = C_PetJournal.GetBattlePetLink(id)  -- Save battle pet link
            else
                -- Handle the case where id is nil
                actions[slot] = "|cffff0000|Habp:summonpet:0|h[Unknown Pet]|h|r"
            end

        elseif type == "summonmount" then
            if id == 0xFFFFFFF then
                actions[slot] = C_Spell.GetSpellLink(ABP_RANDOM_MOUNT_SPELL_ID)  -- Save random mount spell link
            elseif id then  -- Ensure id is not nil before using it
                local mountInfo = C_MountJournal.GetMountInfoByID(id)
                if mountInfo and mountInfo[2] then
                    actions[slot] = C_Spell.GetSpellLink(mountInfo[2])  -- Save specific mount spell link
                else
                    -- Handle the case where mountInfo or the specific mount ID is nil
                    actions[slot] = "|cffff0000|Habp:summonmount:0|h[Unknown Mount]|h|r"
                end
            else
                -- Handle the case where id is nil
                actions[slot] = "|cffff0000|Habp:summonmount:0|h[Unknown Mount]|h|r"
            end

        elseif type == "macro" then
            -- Can't trust id from GetActionInfo
            local macroName = GetActionText(slot)

            if macroName then  -- Ensure macroName is not nil before proceeding
                local macroIndex = GetMacroIndexByName(macroName)
                if macroIndex > 0 then
                    local name, icon, body = GetMacroInfo(macroName)

                    icon = icon or ABP_EMPTY_ICON_TEXTURE_ID

                    if macroIndex > MAX_ACCOUNT_MACROS then
                        actions[slot] = string.format(
                            "|cffff0000|Habp:macro:%s:%s|h[%s]|h|r",
                            icon, self:EncodeLink(body), name
                        )
                    else
                        actions[slot] = string.format(
                            "|cffff0000|Habp:macro:%s:%s:1|h[%s]|h|r",
                            icon, self:EncodeLink(body), name
                        )
                    end

                    savedMacros[macroIndex] = true  -- Mark macro as saved
                end
            else
                -- Handle the case where macroName is nil
                actions[slot] = "|cffff0000|Habp:macro:0|h[Unknown Macro]|h|r"
            end

        elseif type == "equipmentset" then
            actions[slot] = string.format(
                "|cffff0000|Habp:equip|h[%s]|h|r",
                id  -- Save equipment set ID
            )
        end
    end

    profile.actions = actions  -- Save actions to the profile

    -- Save unsaved macros to the profile
    local macros = {}
    local allMacros, charMacros = GetNumMacros()

    for index = 1, allMacros do
        local name, icon, body = GetMacroInfo(index)

        icon = icon or ABP_EMPTY_ICON_TEXTURE_ID

        if body and not savedMacros[index] then
            table.insert(macros, string.format(
                "|cffff0000|Habp:macro:%s:%s:1|h[%s]|h|r",
                icon, self:EncodeLink(body), name
            ))
        end
    end

    for index = MAX_ACCOUNT_MACROS + 1, MAX_ACCOUNT_MACROS + charMacros do
        local name, icon, body = GetMacroInfo(index)

        icon = icon or ABP_EMPTY_ICON_TEXTURE_ID

        if body and not savedMacros[index] then
            table.insert(macros, string.format(
                "|cffff0000|Habp:macro:%s:%s|h[%s]|h|r",
                icon, self:EncodeLink(body), name
            ))
        end
    end

    profile.macros = macros  -- Save macros to the profile
end


-- This function saves the player's current pet action bar setup into the provided profile.
function addon:SavePetActions(profile)
    local petActions = nil  -- Initialize petActions as nil.

    -- Check if the pet has spells available in the spellbook.
    local numPetSpells, petToken = C_SpellBook.HasPetSpells()
    if numPetSpells then  -- If the pet has spells, proceed with saving them.
        local petSpells = {}  -- Table to hold the pet spells by name.

        -- Iterate through all pet spells.
        for index = 1, numPetSpells do
            -- Get the spell type and ID from the pet spellbook.
            local type, id = C_SpellBook.GetSpellBookItemType(index, Enum.SpellBookSpellBank.Pet)
            -- Get the spell name and subname (if any).
            local name, subName = C_SpellBook.GetSpellBookItemName(index, Enum.SpellBookSpellBank.Pet)

            id = bit.band(id, 0xFFFFFF)  -- Mask the spell ID to ensure it's a valid ID.

            petSpells[name] = id  -- Store the spell ID by its name.
        end

        petActions = {}  -- Initialize petActions as an empty table.

        -- Iterate through the pet action bar slots.
        for slot = 1, NUM_PET_ACTION_SLOTS do
            -- Get the pet action information for the current slot.
            local name, _, _, token = GetPetActionInfo(slot)

            if name then  -- If there is an action in this slot, proceed.
                if not token and petSpells[name] then
                    -- If the action is a spell and not a token, save the spell link.
                    petActions[slot] = C_Spell.GetSpellLink(petSpells[name])
                else
                    -- If the action is not a spell (or is a token), save it with a custom link format.
                    petActions[slot] = string.format(
                        "|cffff0000|Habp:pet:%s|h[%s]|h|r",
                        name, _G[name]
                    )
                end
            end
        end
    end

    profile.petActions = petActions  -- Save the pet actions to the profile.
end


-- This function saves the player's current keybindings into the provided profile.
function addon:SaveBindings(profile)
    local bindings = {}  -- Initialize a table to store keybindings.

    -- Iterate through all keybindings.
    for index = 1, GetNumBindings() do
        local bind = { GetBinding(index) }  -- Get the binding information for the current index.
        if bind[3] then  -- If the binding has keys associated with it (at least one keybinding exists).
            bindings[bind[1]] = { select(3, unpack(bind)) }  -- Save the binding command and associated keys.
        end
    end

    profile.bindings = bindings  -- Save the bindings to the profile.

    local bindingsDominos = nil  -- Initialize the table for Dominos bindings as nil.

    -- Check if the Dominos addon is loaded.
    if LibStub("AceAddon-3.0"):GetAddon("Dominos", true) then
        bindingsDominos = {}  -- Initialize a table to store Dominos keybindings.

        -- Iterate through Dominos action buttons (13 to 60).
        for index = 13, 60 do
            local bind = { GetBindingKey(string.format("CLICK DominosActionButton%d:LeftButton", index)) }  -- Get the keybindings for the Dominos action button.
            if #bind > 0 then  -- If there are any keybindings for this button.
                bindingsDominos[index] = bind  -- Save the keybindings to the bindingsDominos table.
            end
        end
    end

    profile.bindingsDominos = bindingsDominos  -- Save the Dominos bindings to the profile.
end


-- This function resets the default profile for a given key.
-- It iterates through all profiles in the list and removes the specified key from the "fav" table.
-- If the "quiet" parameter is false or not provided, it updates the GUI after resetting the default.
function addon:ResetDefault(key, quiet)
    local list = self.db.profile.list  -- Get the list of profiles.
    local profile

    -- Iterate through each profile and remove the key from the "fav" table if it exists.
    for profile in table.s2k_values(list) do
        profile.fav = profile.fav or {}  -- Ensure the "fav" table exists.
        profile.fav[key] = nil  -- Remove the key from the "fav" table.
    end

    -- If "quiet" is not true, update the GUI to reflect changes.
    if not quiet then
        self:UpdateGUI()
    end
end


-- This function sets a profile as the default for a given key.
-- It first resets any existing defaults for that key, then sets the specified profile as the default.
function addon:SetDefault(name, key)
    local list = self.db.profile.list  -- Get the list of profiles.
    local profile = list[name]  -- Retrieve the profile by name.

    -- If the profile doesn't exist, return early.
    if not profile then return end

    -- Reset any existing defaults for this key.
    self:ResetDefault(key, true)

    profile.fav = profile.fav or {}  -- Ensure the "fav" table exists.
    profile.fav[key] = 1  -- Set this profile as the default for the specified key.

    self:UpdateGUI()  -- Update the GUI to reflect changes.
end


-- This function unsets a profile as the default for a given key.
-- It removes the specified key from the profile's "fav" table.
function addon:UnsetDefault(name, key)
    local list = self.db.profile.list  -- Get the list of profiles.
    local profile = list[name]  -- Retrieve the profile by name.

    -- If the profile doesn't exist, return early.
    if not profile then return end

    profile.fav = profile.fav or {}  -- Ensure the "fav" table exists.
    profile.fav[key] = nil  -- Remove the key from the "fav" table.

    self:UpdateGUI()  -- Update the GUI to reflect changes.
end
