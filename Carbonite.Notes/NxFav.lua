-------------------------------------------------------------------------------
-- NxFav - Favorites/Notes Window
-- Copyright 2008-2012 Carbon Based Creations, LLC
-------------------------------------------------------------------------------
-- Carbonite - Addon for World of Warcraft(tm)
-- Copyright 2007-2012 Carbon Based Creations, LLC
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- VERSION AND MODULE INITIALIZATION
-------------------------------------------------------------------------------

-- Data version for favorites/notes format
Nx.VERSIONFAV = .16

-- Notes module namespace
Nx.Notes = {}

-- Create the AceAddon for the Notes module
CarboniteNotes = LibStub("AceAddon-3.0"):NewAddon("CarboniteNotes", "AceTimer-3.0", "AceEvent-3.0", "AceComm-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Carbonite.Notes", true)

-------------------------------------------------------------------------------
-- KEYBINDING DEFINITIONS
-------------------------------------------------------------------------------

BINDING_HEADER_CarboniteNotes = "|cffc0c0ff" .. L["Carbonite Notes"] .. "|r"
BINDING_NAME_NxTOGGLEFAV = L["NxTOGGLEFAV"]

-------------------------------------------------------------------------------
-- LOCAL VARIABLES
-------------------------------------------------------------------------------

-- Storage for notes from other addons. Lives on the Nx.Notes
-- namespace (not as a file-local) so the extracted MapIcons /
-- AddonNote modules can see the same table without import gymnastics.
Nx.Notes.addonNotes = Nx.Notes.addonNotes or {}
local addonNotes = Nx.Notes.addonNotes

-------------------------------------------------------------------------------
-- DEFAULT OPTIONS



-------------------------------------------------------------------------------
-- SAFECALL IMPLEMENTATION
-- Protected function calls for addon compatibility. Lives on the
-- Nx.Notes namespace so extracted modules (Integrations/*.lua) can
-- call it without re-defining their own copy. The file-local alias
-- keeps existing NxFav.lua call sites unchanged.
-------------------------------------------------------------------------------

local function errorhandler(err)
    return geterrorhandler()(err)
end

function Nx.Notes.safecall(func, ...)
    if type(func) == "function" then
        return xpcall(func, errorhandler, ...)
    end
end

local safecall = Nx.Notes.safecall



-------------------------------------------------------------------------------
-- END OF FILE
-------------------------------------------------------------------------------
