-- Carbonite.Warehouse | Options
-- AceConfig options table for the Warehouse module. Lazily built
-- on first request and cached so subsequent /config opens dont
-- rebuild it. Registered with Nx:AddToConfig from NxWarehouses
-- OnInitialize.

local L = LibStub('AceLocale-3.0'):GetLocale('Carbonite.Warehouse', true)

local Nx = _G.Nx
if not Nx then return end
Nx.Warehouse = Nx.Warehouse or {}

local warehouseopts

function Nx.Warehouse:GetOptionsConfig()
    if not warehouseopts then
        warehouseopts = {
            type = "group",
            name = L["Warehouse Options"],
            childGroups = "tab",
            args = {
                main = {
                    order = 1,
                    name = L["Warehouse"],
                    type = "group",
                    args = {
                        toolTip = {
                            order = 1,
                            type = "toggle",
                            width = "full",
                            name = L["Add Warehouse Tooltip"],
                            desc = L["When enabled, will show warehouse information in hover tooltips of items"],
                            get = function()
                                return Nx.wdb.profile.Warehouse.AddTooltip
                            end,
                            set = function()
                                Nx.wdb.profile.Warehouse.AddTooltip = not Nx.wdb.profile.Warehouse.AddTooltip
                            end,
                        },
                        showGold = {
                            order = 2,
                            type = "toggle",
                            width = "full",
                            name = L["Show coin count in warehouse list"],
                            desc = L["Restores the coin totals after character names in warehouse listing"],
                            get = function()
                                return Nx.wdb.profile.Warehouse.ShowGold
                            end,
                            set = function()
                                Nx.wdb.profile.Warehouse.ShowGold = not Nx.wdb.profile.Warehouse.ShowGold
                            end,
                        },
                        tiphidelist = {
                            order = 3,
                            name = L["Use don't display list"],
                            desc = L["If enabled, don't show listed items in tooltips"],
                            type = "toggle",
                            width = "full",
                            descStyle = "inline",
                            get = function()
                                return Nx.wdb.profile.Warehouse.TooltipIgnore
                            end,
                            set = function()
                                Nx.wdb.profile.Warehouse.TooltipIgnore = not Nx.wdb.profile.Warehouse.TooltipIgnore
                            end,
                        },
                        hidenew = {
                            order = 4,
                            type = "input",
                            name = L["New Item To Ignore (Case Insensative)"],
                            desc = L["Enter the name of the item you want to not track in tooltips. You can drag and drop an item from your inventory aswell."],
                            width = "full",
                            disabled = function()
                                return not Nx.wdb.profile.Warehouse.TooltipIgnore
                            end,
                            get = false,
                            set = function (info, value)
                                local name = C_Item.GetItemInfo(value)
                                name = name or value
                                StaticPopupDialogs["NX_AddIgnore"] = {
                                    text = L["Ignore"] .. " " .. value .. "?",
                                    button1 = L["Yes"],
                                    button2 = L["No"],
                                    OnAccept = function()
                                        Nx.wdb.profile.Warehouse.IgnoreList[name] = name
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("Carbonite")
                                    end,
                                    hideOnEscape = true,
                                    whileDead = true,
                                }
                                local dlg = StaticPopup_Show("NX_AddIgnore")
                            end,
                        },
                        hidedelete = {
                            order = 5,
                            type = "select",
                            style = "radio",
                            name = L["Delete Item"],
                            disabled = function()
                                return not Nx.wdb.profile.Warehouse.TooltipIgnore
                            end,
                            get = false,
                            values = Nx.wdb.profile.Warehouse.IgnoreList,
                            set = function(info, value)
                                StaticPopupDialogs["NX_DelIgnore"] = {
                                    text = L["Delete"] .. " " .. value .. "?",
                                    button1 = L["Yes"],
                                    button2 = L["No"],
                                    OnAccept = function()
                                        Nx.wdb.profile.Warehouse.IgnoreList[value] = nil
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("Carbonite")
                                    end,
                                    hideOnEscape = true,
                                    whileDead = true,
                                }
                                local dlg = StaticPopup_Show("NX_DelIgnore")
                            end,
                        },
                        WareFont = {
                            order = 6,
                            type    = "select",
                            name    = L["Warehouse Font"],
                            desc    = L["Sets the font to be used for warehouse windows"],
                            get    = function()
                                local vals = Nx.Opts:CalcChoices("FontFace","Get")
                                for a,b in pairs(vals) do
                                  if (b == Nx.wdb.profile.Warehouse.WarehouseFont) then
                                     return a
                                  end
                                end
                                return ""
                            end,
                            set    = function(info, name)
                                local vals = Nx.Opts:CalcChoices("FontFace","Get")
                                Nx.wdb.profile.Warehouse.WarehouseFont = vals[name]
                                Nx.Opts:NXCmdFontChange()
                            end,
                            values    = function()
                                return Nx.Opts:CalcChoices("FontFace","Get")
                            end,
                        },
                        WareFontSize = {
                            order = 7,
                            type = "range",
                            name = L["Warehouse Font Size"],
                            desc = L["Sets the size of the warehouse font"],
                            min = 6,
                            max = 14,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.wdb.profile.Warehouse.WarehouseFontSize
                            end,
                            set = function(info,value)
                                Nx.wdb.profile.Warehouse.WarehouseFontSize = value
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                        WareFontSpacing = {
                            order = 8,
                            type = "range",
                            name = L["Warehouse Font Spacing"],
                            desc = L["Sets the spacing of the warehouse font"],
                            min = -10,
                            max = 20,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Nx.wdb.profile.Warehouse.WarehouseFontSpacing
                            end,
                            set = function(info,value)
                                Nx.wdb.profile.Warehouse.WarehouseFontSpacing = value
                                Nx.Opts:NXCmdFontChange()
                            end,
                        },
                    },
                },
                seller = {
                    order = 2,
                    name = L["Auto Sell"],
                    type = "group",
                    args = {
                        sellopts = {
                            order = 1,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                enabletest = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Test Selling"],
                                    desc = L["Enabling this allows you to see what would get sold, without actually selling."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellTesting
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellTesting = not Nx.wdb.profile.Warehouse.SellTesting
                                    end,
                                },
                                enableverb = {
                                    order = 2,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Verbose Selling"],
                                    desc = L["When enabled shows what items got sold instead of just the grand total earned."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellVerbose
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellVerbose = not Nx.wdb.profile.Warehouse.SellVerbose
                                    end,
                                },
                            },
                        },
                        greys = {
                            order = 2,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                sellgreys = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Auto Sell"] .. " |cff777777" .. L["Grey"] .. "|r " .. L["Items"],
                                    desc = L["When you open a merchant, will auto sell your grey items"],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreys
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellGreys = not Nx.wdb.profile.Warehouse.SellGreys
                                    end,
                                },
                            },
                        },
                        whites = {
                            order = 3,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                sellwhites = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Auto Sell"] .. " |cffffffff" .. L["White"] .. "|r " .. L["Items"],
                                    desc = L["When you open a merchant, will auto sell your white items."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellWhites
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellWhites = not Nx.wdb.profile.Warehouse.SellWhites
                                    end,
                                },
                                whiteilvl = {
                                    order = 2,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Enable iLevel Limit"],
                                    desc = L["Only sells items that are under the item level specified"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellWhites
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellWhitesiLVL
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellWhitesiLVL = not Nx.wdb.profile.Warehouse.SellWhitesiLVL
                                    end,
                                },
                                whitevalue = {
                                    order = 3,
                                    type = "range",
                                    width = "full",
                                    name = L["iLevel"],
                                    desc = L["Sets the maximum item level which will be auto sold"],
                                    min = 0,
                                    max = 1000,
                                    step = 1,
                                    bigStep = 5,
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellWhites or not Nx.wdb.profile.Warehouse.SellWhitesiLVL
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellWhitesiLVLValue
                                    end,
                                    set = function(info, value)
                                        Nx.wdb.profile.Warehouse.SellWhitesiLVLValue = value
                                    end,
                                },
                            },
                        },
                        greens = {
                            order = 4,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                sellgreens = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Auto Sell"] .. " |cff00ff00" .. L["Green"] .. "|r " .. L["Items"],
                                    desc = L["When you open a merchant, will auto sell your green items."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreens
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellGreens = not Nx.wdb.profile.Warehouse.SellGreens
                                    end,
                                },
                                greepbop = {
                                    order = 2,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOP Items"],
                                    desc = L["When enabled will sell items that are BOP"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellGreens
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreensBOP
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellGreensBOP = not Nx.wdb.profile.Warehouse.SellGreensBOP
                                    end,
                                },
                                greenboe = {
                                    order = 3,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOE Items"],
                                    desc = L["When enabled will sell items that are BOE"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellGreens
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreensBOE
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellGreensBOE = not Nx.wdb.profile.Warehouse.SellGreensBOE
                                    end,
                                },
                                greenilvl = {
                                    order = 4,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Enable iLevel Limit"],
                                    desc = L["Only sells items that are under the item level specified"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellGreens
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreensiLVL
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellGreensiLVL = not Nx.wdb.profile.Warehouse.SellGreensiLVL
                                    end,
                                },
                                greenvalue = {
                                    order = 5,
                                    type = "range",
                                    width = "full",
                                    name = L["iLevel"],
                                    desc = L["Sets the maximum item level which will be auto sold"],
                                    min = 0,
                                    max = 1000,
                                    step = 1,
                                    bigStep = 5,
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellGreens or not Nx.wdb.profile.Warehouse.SellGreensiLVL
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellGreensiLVLValue
                                    end,
                                    set = function(info, value)
                                        Nx.wdb.profile.Warehouse.SellGreensiLVLValue = value
                                    end,
                                },
                            },
                        },
                        blues = {
                            order = 5,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                sellblues = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Auto Sell"] .. " |cff3333ff" .. L["Blue"] .. "|r " .. L["Items"],
                                    desc = L["When you open a merchant, will auto sell your blue items."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellBlues
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellBlues = not Nx.wdb.profile.Warehouse.SellBlues
                                    end,
                                },
                                bluebop = {
                                    order = 2,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOP Items"],
                                    desc = L["When enabled will sell items that are BOP"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellBlues
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellBluesBOP
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellBluesBOP = not Nx.wdb.profile.Warehouse.SellBluesBOP
                                    end,
                                },
                                blueboe = {
                                    order = 3,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOE Items"],
                                    desc = L["When enabled will sell items that are BOE"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellBlues
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellBluesBOE
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellBluesBOE = not Nx.wdb.profile.Warehouse.SellBluesBOE
                                    end,
                                },
                                blueilvl = {
                                    order = 4,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Enable iLevel Limit"],
                                    desc = L["Only sells items that are under the item level specified"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellBlues
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellBluesiLVL
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellBluesiLVL = not Nx.wdb.profile.Warehouse.SellBluesiLVL
                                    end,
                                },
                                bluevalue = {
                                    order = 5,
                                    type = "range",
                                    width = "full",
                                    name = L["iLevel"],
                                    desc = L["Sets the maximum item level which will be auto sold"],
                                    min = 0,
                                    max = 1000,
                                    step = 1,
                                    bigStep = 5,
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellBlues or not Nx.wdb.profile.Warehouse.SellBluesiLVL
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellBluesiLVLValue
                                    end,
                                    set = function(info, value)
                                        Nx.wdb.profile.Warehouse.SellBluesiLVLValue = value
                                    end,
                                },
                            },
                        },
                        purps = {
                            order = 6,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                sellpurps = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Auto Sell"] .. " |cffff00ff" .. L["Purple"] .. "|r " .. L["Items"],
                                    desc = L["When you open a merchant, will auto sell your purple items."],
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellPurps
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellPurps = not Nx.wdb.profile.Warehouse.SellPurps
                                    end,
                                },
                                purpbop = {
                                    order = 2,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOP Items"],
                                    desc = L["When enabled will sell items that are BOP"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellPurps
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellPurpsBOP
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellPurpsBOP = not Nx.wdb.profile.Warehouse.SellPurpsBOP
                                    end,
                                },
                                purpboe = {
                                    order = 3,
                                    type = "toggle",
                                    width = "double",
                                    name = L["Sell BOE Items"],
                                    desc = L["When enabled will sell items that are BOE"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellPurps
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellPurpsBOE
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellPurpsBOE = not Nx.wdb.profile.Warehouse.SellPurpsBOE
                                    end,
                                },
                                purpilvl = {
                                    order = 4,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Enable iLevel Limit"],
                                    desc = L["Only sells items that are under the item level specified"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellPurps
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellPurpsiLVL
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellPurpsiLVL = not Nx.wdb.profile.Warehouse.SellPurpsiLVL
                                    end,
                                },
                                purpvalue = {
                                    order = 5,
                                    type = "range",
                                    width = "full",
                                    name = L["iLevel"],
                                    desc = L["Sets the maximum item level which will be auto sold"],
                                    min = 0,
                                    max = 1000,
                                    step = 1,
                                    bigStep = 5,
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellPurps or not Nx.wdb.profile.Warehouse.SellPurpsiLVL
                                    end,
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellPurpsiLVLValue
                                    end,
                                    set = function(info, value)
                                        Nx.wdb.profile.Warehouse.SellPurpsiLVLValue = value
                                    end,
                                },
                            },
                        },
                        list = {
                            order = 7,
                            name = " ",
                            type = "group",
                            guiInline = true,
                            args = {
                                selllist = {
                                    order = 1,
                                    name = L["Sell items based on a list"],
                                    desc = L["If item name matches one on the list, auto-sell it"],
                                    type = "toggle",
                                    width = "full",
                                    descStyle = "inline",
                                    get = function()
                                        return Nx.wdb.profile.Warehouse.SellList
                                    end,
                                    set = function()
                                        Nx.wdb.profile.Warehouse.SellList = not Nx.wdb.profile.Warehouse.SellList
                                    end,
                                },
                                new = {
                                    order = 2,
                                    type = "input",
                                    name = L["New Item To Sell (Case Insensative)"],
                                    desc = L["Enter the name of the item you want to auto-sell. You can drag and drop an item from your inventory aswell."],
                                    width = "full",
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellList
                                    end,
                                    get = false,
                                    set = function (info, value)
                                        local name = C_Item.GetItemInfo(value)
                                        name = name or value
                                        StaticPopupDialogs["NX_AddSell"] = {
                                            text = L["Add"] .. " " .. value .. "?",
                                            button1 = L["Yes"],
                                            button2 = L["No"],
                                            OnAccept = function()
                                                Nx.wdb.profile.Warehouse.SellingList[name] = name
                                                LibStub("AceConfigRegistry-3.0"):NotifyChange("Carbonite")
                                            end,
                                            hideOnEscape = true,
                                            whileDead = true,
                                        }
                                        local dlg = StaticPopup_Show("NX_AddSell")
                                    end,
                                },
                                delete = {
                                    order = 3,
                                    type = "select",
                                    style = "radio",
                                    name = L["Delete Item"],
                                    disabled = function()
                                        return not Nx.wdb.profile.Warehouse.SellList
                                    end,
                                    get = false,
                                    values = Nx.wdb.profile.Warehouse.SellingList,
                                    set = function(info, value)
                                        StaticPopupDialogs["NX_DelSell"] = {
                                            text = L["Delete"] .. " " .. value .. "?",
                                            button1 = L["Yes"],
                                            button2 = L["No"],
                                            OnAccept = function()
                                                Nx.wdb.profile.Warehouse.SellingList[value] = nil
                                                LibStub("AceConfigRegistry-3.0"):NotifyChange("Carbonite")
                                            end,
                                            hideOnEscape = true,
                                            whileDead = true,
                                        }
                                        local dlg = StaticPopup_Show("NX_DelSell")
                                    end,
                                },
                            },
                        },
                    },
                },
                repair = {
                    order = 3,
                    name = L["Auto Repair"],
                    type = "group",
                    args = {
                        autorepair = {
                            order = 1,
                            type = "toggle",
                            width = "full",
                            descStyle = "inline",
                            name = L["Auto Repair Gear"],
                            desc = L["When you open a merchant, will attempt to auto repair your gear"],
                            get = function()
                                return Nx.wdb.profile.Warehouse.RepairAuto
                            end,
                            set = function()
                                Nx.wdb.profile.Warehouse.RepairAuto = not Nx.wdb.profile.Warehouse.RepairAuto
                            end,
                        },
                        guildrepair = {
                            order = 2,
                            type = "toggle",
                            width = "full",
                            descStyle = "inline",
                            disabled = function()
                                return not Nx.wdb.profile.Warehouse.RepairAuto
                            end,
                            name = L["Use Guild Repair First"],
                            desc = L["Will try to use guild funds to pay for repairs before your own"],
                            get = function()
                                return Nx.wdb.profile.Warehouse.RepairGuild
                            end,
                            set = function()
                                Nx.wdb.profile.Warehouse.RepairGuild = not Nx.wdb.profile.Warehouse.RepairGuild
                            end,
                        },
                    },
                },
            },
        }
    end
    Nx.Opts:AddToProfileMenu(L["Warehouse"], 5, Nx.wdb)
    return warehouseopts
end
