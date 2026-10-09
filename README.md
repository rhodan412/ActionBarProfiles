# Action Bar Profiles (Fan Update)

Save named World of Warcraft Retail action bar layouts and switch between them from the character panel. A profile can include action buttons, talents, PvP talents, macros, pet actions, and key bindings, with separate choices for what to apply.

[Download on CurseForge](https://www.curseforge.com/wow/addons/action-bar-profiles-fan-update) · [Player guide](https://github.com/rhodan412/ActionBarProfiles/wiki) · [Gallery](https://www.curseforge.com/wow/addons/action-bar-profiles-fan-update/gallery) · [Report a bug or request a feature](https://github.com/rhodan412/ActionBarProfiles/issues/new/choose)

## Get started

1. Install the published Retail build from CurseForge and enable the addon in World of Warcraft. Check the file's listed game version before installing.
2. Open the character panel and select the **Action Bars** sidebar icon.
3. Choose **New Profile**, enter a name, and check the parts of your setup that the profile should manage. Select **Okay** to save it.
4. Select a saved profile and press **Use** to apply it. If some actions cannot be used by the current character, review the confirmation prompt before continuing.

The **Save** button updates a selected profile from your current setup. The profile's edit control changes its name and saved options. A profile marked as the default for your character and specialization can be loaded when you switch to that specialization.

## What profiles can manage

- **Action bars:** spells, items, macros, and other supported action button types. The **Empty slots** option controls whether empty action slots are also restored.
- **Talents and PvP talents:** save and apply the selected talent setup for the character's specialization.
- **Macros:** save macros used by the layout. The addon settings include a separate **Replace macros** option; review that setting before using a profile if you want to keep existing macros.
- **Pet or demon actions and key bindings:** include these when their checkboxes are selected and the character has the relevant actions.

Uncheck a category in the profile options if you do not want **Use** to apply it. Profiles are stored in the addon's SavedVariables, so back up your World of Warcraft WTF folder before major changes or reinstalling the game.

## Chat commands

| Command | Action |
| --- | --- |
| /abp list | List saved profiles. |
| /abp save PROFILE_NAME | Create a profile or update one with that name. |
| /abp use PROFILE_NAME | Apply a saved profile. |
| /abp del PROFILE_NAME | Delete a saved profile. |

The command parser also accepts ls, sv, load / ld, and delete / remove / rm as aliases. See the [wiki](https://github.com/rhodan412/ActionBarProfiles/wiki) for the full walkthrough and troubleshooting steps.

## Compatibility and known issues

Action Bar Profiles is for **WoW Retail**. The [CurseForge Files page](https://www.curseforge.com/wow/addons/action-bar-profiles-fan-update/files) lists the supported game version of each published download.

The published build has reported problems with character-specific macros being restored into account-wide macro slots and with key bindings not restoring consistently. See [the macro report](https://github.com/rhodan412/ActionBarProfiles/issues/2) and the [issue tracker](https://github.com/rhodan412/ActionBarProfiles/issues) for current reports and status. If you encounter a problem, please [open a GitHub bug report](https://github.com/rhodan412/ActionBarProfiles/issues/new/choose) with the addon version, WoW version, steps to reproduce, and the full Lua error if one appears. Feature requests belong there too.

## Credits

This fan update continues [Action Bar Profiles (Saver)](https://www.curseforge.com/wow/addons/action-bar-profiles) by Silencer2k ([original source](https://github.com/Silencer2K/wow-action-bar-profiles)). The GitHub repository includes the project's [MIT license](https://github.com/rhodan412/ActionBarProfiles/blob/main/LICENSE).
