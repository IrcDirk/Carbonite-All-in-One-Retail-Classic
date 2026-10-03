if ( GetLocale() ~= "zhCN" ) then
	return
end

local L = LibStub("AceLocale-3.0"):NewLocale("Carbonite", "zhCN")
if not L then return end

L["Carbonite"] = "Carbonite"
L["NxMAPTOGORIGINAL"] = "显示/隐藏暴雪地图"
L["NxMAPTOGNORMMAX"] = "切换地图大小"
L["NxMAPTOGNONEMAX"] = "显示/隐藏完整地图"
L["NxMAPTOGNONENORM"] = "显示/隐藏地图"
L["NxMAPSCALERESTORE"] = "重置地图缩放"
L["NxMAPTOGMINIFULL"] = "切换小地图/完整地图"
L["NxMAPTOGHERB"] = "显示/隐藏草点"
L["NxMAPTOGMINE"] = "显示/隐藏矿点"
L["NxTOGGLEGUIDE"] = "显示/隐藏百科指南"
L["NxMAPSKIPTARGET"] = "跳过地图当前目标"
L["NxMAPTOGTIMBER"] = "显示/隐藏木材"
