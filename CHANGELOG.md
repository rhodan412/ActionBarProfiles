12.1.0.0



&#x09;\*\*HIGHLIGHTS\*\*

&#x09;	- Updated the addon for WoW Retail 12.1.0 so the Action Bars character-panel view and profile controls work with current specialization, talent, and macro APIs.

&#x09;	- Profiles now save and restore hero talent sub-tree choices along with class and specialization talents.

&#x09;	- Talent restoration now reapplies all saved ranks of multi-rank choice and bottom-of-tree talents, including talents such as Midnight.

&#x09;	- Shortened the delay between talent selections so a profile restores more quickly.

&#x09;	- Reduced routine chat spam from talent mismatches, choice switches, and special action-slot skips during restore.

&#x09;	- Fixed errors caused by talent entries without spell definitions and by missing macro-limit globals in Retail 12.1.0.

&#x09;	- Fixed a talent-restore Lua syntax error that prevented the addon from loading and left the Action Bars profile list blank.



&#x09;ActionBarProfiles.lua

&#x09;	- Updated specialization lookups to the current Retail API so saved profiles and per-specialization defaults use the correct specialization. (2026.08.31)



&#x09;ActionBarProfiles.toc

&#x09;	- Set the Retail interface number to 120100 and the addon version to 12.1.0.0 for this compatibility update. (2026.08.31)



&#x09;GUI.lua

&#x09;	- Updated specialization lookups used by the Action Bars character-panel list and favorite/default profile controls for the Retail API. (2026.08.31)



&#x09;Restore.lua

&#x09;	- Skip trait entries without definition IDs while preloading talents, preventing the Action Bars panel from failing to open on structural hero talent entries. (2026.08.31)

&#x09;	- Use fallback account and character macro limits when Retail no longer exports the old globals, preventing cache and macro restore errors. (2026.08.31)

&#x09;	- Compare and restore hero sub-tree selections before dependent talent nodes, then reset and rebuild the saved talent configuration in dependency order. (2026.08.31)

&#x09;	- Refresh choice-node state after selection and purchase all remaining saved ranks, restoring multi-rank and bottom-of-tree talents completely. (2026.08.31)

&#x09;	- Reduced the per-node talent restore delay to 0.02 seconds while keeping purchases ordered. (2026.08.31)

&#x09;	- Suppressed routine mismatch, choice-switch, and special action-slot skip debug messages during profile use. (2026.08.31)

&#x09;	- Corrected the talent-restore block's Lua syntax so Restore.lua loads and the character-panel profile list can populate. (2026.08.31)



&#x09;Save.lua

&#x09;	- Updated specialization and PvP-talent API lookups for Retail 12.1.0 profile saving. (2026.08.31)

&#x09;	- Save hero sub-tree selection entries even when they have no spell definition, and retain purchased ranks for full talent restoration. (2026.08.31)

&#x09;	- Use a fallback account macro limit so account and character macro slots can be saved when the old global is unavailable. (2026.08.31)





11.0.2.1b



&#x09;- Fixed some general coding issues



&#x09;ActionBarProfiles.lua

&#x09;	- Removed/commented out CopyBar6To13() function as no longer used

&#x09;	- Fixed issue where profile was being restored when mousing over the LDB button



&#x09;GUI.lua

&#x09;	- Fixed code from GetRealmName("player") to GetRealmName()



&#x09;Restore.lua

&#x09;	- Updates to addon:AreTalentsMatching() and addon:RestoreTalents() to fix issue of talents not swapping when different choice node is used

&#x09;	- Removed/commented out PlayerTalentFrameTalent\_OnClick() and addon:RestoreSingleAction() functions as no longer used

&#x09;	- API fix/replacement of PickupSpellBookItem to reflect 11.0 change to C\_SpellBook.PickupSpellBookItem



&#x09;Save.lua

&#x09;	- API fix/replacement of IsTalentSpell to reflect 11.0 change to C\_SpellBook.IsClassTalentSpellBookItem

&#x09;	- API fix/replacement of IsPvpTalentSpell to reflect 11.0 change to C\_SpellBook.IsPvPTalentSpellBookItem





11.0.2.1

&#x09;- Changed version number





11.0.0.2

&#x09;ActionBarProfiles.lua

&#x09;	- Modified ignoreList



&#x09;GUI.lua

&#x09;	- Commented out code that while it checks to find out how many failures exist in the profile (those not able to be restored when the "Use" button is pressed) instead results in addon 'clicking' the "Use" 

&#x09;	every time the character pane icon was pressed or when selecting a different profile



&#x09;Restore.lua

&#x09;	- Updated addon:ClearSlot(slot) function to include hearthstone toy ignore when clearing slots and also to not clear random favorite mount button





11.0.0.1 - BETA

&#x20;- Massive changes to the SAVE and RESTORE of profiles in updating to 11.0 API coding

&#x20;- Added addon tables for proper flow of data between files/functions

&#x20;- Update to README (thx sc0ttkclark)

&#x20;- Updated TOC

&#x20;- Cleaned up code somewhat/Added comments to make future changes easier

&#x20;- Changed some coding from self/addon to ABP for functionality purposes



&#x20;SPECIFIC FILE CHANGES:

&#x09;ActionBarProfiles.lua

&#x09;	- Added debug for profileName when Saving Profile

&#x09;	- Added an ignnoreList for spells that won't be removed from action bar on clearing



&#x09;	API Updates:

&#x09;	- Update in API from GetSpellInfo to C\_Spell.GetSpellInfo

&#x09;	- Update in API from UnitAura to C\_UnitAuras.GetAuraDataByIndex

&#x09;	

&#x09;	Testing:

&#x09;	- Added some testing code to file for purpose of checking new talent restoration/learning methods from pre-DF talents



&#x09;	Post Alpha Changes:

&#x09;	- Fixed addon:AreTalentsMatching function to better check talents in the DB profile vs what exist

&#x09;	- Modification to addon:RestoreTalents(profile, check, cache, res) function to attempt switching a few talents instead of clearing entire talent tree (if this doesn't work, fail safe kicks in allowing full clearing 

&#x09;	of talent tree and re-learning

&#x09;	- Added ABP:ActionButtonOverride(profileKey, profileName) function to update your action bars with spells and macros that should've been placed there when addon:RestoreActions(profile, check, cache, res) fires but 

&#x09;	wasn't due to issues on new coding/API

&#x09;	- Modified addon:ClearSlot(slot) function to check ignoreList and also to include flyout buttons (if you had 'Call Demon' on your Action Bar this would be removed because it is technically not a spell, but a flyout. 

&#x09;	This is hopefully a temporary change as I work to make sure that flyouts, pets, items are all properly re-added during the restore action period



&#x09;Const.lua

&#x09;	- Updated download link for add-on (was the old URL for previous iteration)

&#x09;	- Removed/Commented out duplicate line for Elysian Decree



&#x09;Dialogs.lua

&#x09;	- Commented out line within addon:ShowPopup(id, p1, p2, options) and updated addon:UseProfile(popup.name) functions while testing situation where talents would be restored before pressing 'Yes' when confirmation 

&#x09;	popup was visible (in the end, running RestoreTalents twice



&#x09;GUI.lua

&#x09;	- Removed declaration of 'i' from frame:Update() function (possibly temporarily)

&#x09;	- Commented out some code within frame:OnShow() function that was triggering profile "Use" when just selecting the profile (this is bad if you're attempting to save changes to your profile)



&#x09;GUISave.lua

&#x09;	API Update:

&#x09;	- Update in API from HasPetSpells to C\_SpellBook.HasPetSpells



&#x09;Restore.lua

&#x09;	MASSIVE changes to the way that the RestoreActions/RestoreTalents functions operate!



&#x09;	- Change to way that GetSpecializationInfo is retrieved from API

&#x09;	- Re-enabled the debug print of specIndex, specID, treeID, configID and currentClassProfile within GetMySpecAndConfig() function



&#x09;	TEMP CHANGES?:

&#x09;	- Removed local macros = cache.macros and local talents = cache.talents from addon:UseProfile(profile, check, cache) function

&#x09;	- Added addon:AreTalentsMatching(profile) function to check to see if talents from the restore profile matched those currently used



&#x09;	TESTING

&#x09;	- Added function to test restoration of talents in a specific profile



&#x09;Save.lua:

&#x09;	MASSIVE changes to the way that the SaveActions function operates!



&#x09;	API Updates:

&#x09;	- Update in API from GetSpellLink to C\_Spell.GetSpellLink

&#x09;	- - Update in API from HasPetSpells to C\_SpellBook.HasPetSpells



&#x09;	TEMP CHANGES?:

&#x09;	- Removed declaration of 'index' from addon:SaveBindings(profile) function (possibly temporarily)





10.2.5.3

&#x20;- Fixes to talents restoring from profiles (Known Issue: talents swap automatically, when player clicks the Action Bars icon within their Character Panel, to the most applicable talent. If multiple specs within same spec, 

&#x20;it will bounce between the two of them when frame is open)





10.2.5.2

&#x20;- Fixes to PvP talent restoration (spec/class talent restoration is a known issue)





10.2.5.1

&#x20;- Re-release as fan-update



