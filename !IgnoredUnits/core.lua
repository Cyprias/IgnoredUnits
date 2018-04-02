--[[******************************************************************************
	Addon:      !IgnoredUnits
	Author:     Cyprias
	License:    MIT License	(http://opensource.org/licenses/MIT)
**********************************************************************************]]

local folder, core = ...
_G._IU = core

core.title		= GetAddOnMetadata(folder, "Title")
core.version	= GetAddOnMetadata(folder, "Version")
core.titleFull	= core.title.." v"..core.version
core.addonDir   = "Interface\\AddOns\\"..folder.."\\"

LibStub("AceAddon-3.0"):NewAddon(core, folder, "AceConsole-3.0", "AceHook-3.0") -- "AceComm-3.0", 

core.defaultSettings = {}
core.defaultSettings.profile = {}

do
	local OnInitialize = core.OnInitialize
	function core:OnInitialize()
		if OnInitialize then OnInitialize(self) end
		self.db = LibStub("AceDB-3.0"):New("IgnoredUnits_DB", self.defaultSettings, true) --'Default'

		self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
		self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
		self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
		self.db.RegisterCallback(self, "OnProfileDeleted", "OnProfileChanged")
		
		self:RegisterChatCommand("iu", "ChatCommand");

		self.db.global.version = core.version;
	end
end

function core:ChatCommand(input)
	if not input or input:trim() == "" then
		self:OpenOptionsFrame()
	end
end

function core:OpenOptionsFrame()
	LibStub("AceConfigDialog-3.0"):Open(core.title)
end

function core:OnProfileChanged(...)	
	self:Disable() -- Shut down anything left from previous settings
	self:Enable() -- Enable again with the new settings
end

do 
	local OnEnable = core.OnEnable
	function core:OnEnable()
		if OnEnable then OnEnable(self) end
		core:Hook("IgnoreList_Update", true);-- IgnoreMore doesn't fire IGNORELIST_UPDATE, so I'm hooking IgnoreList_Update() instead.
	end
end

do
	local origUnitInRange = UnitInRange;
	local function newUnitInRange(...)
		--core:Debug("<newUnitInRange>", ...);
		if (core:IsEnabled()) then
			local unit = select(1, ...);
			local name = UnitName(unit);
			if (core.ignoredNames[name]) then
				return false, true;
			end
		end
		return origUnitInRange(...);
	end
	--hooksecurefunc("UnitInRange", newUnitInRange)
	UnitInRange = newUnitInRange;
end

--[[
do
	local origUnitIsVisible = UnitIsVisible;
	local function newUnitIsVisible(...)
		core:Debug("<newUnitIsVisible>", ...);
		
		if (core:IsEnabled()) then
			local unit = select(1, ...);
			local name = UnitName(unit);
			--core:Debug("unit: " .. tostring(unit) .. ", name: " .. tostring(name));
			if (core.ignoredNames[name]) then
				return nil;
			end
		end
		
		return origUnitIsVisible(...);
	end
	--hooksecurefunc("UnitIsVisible", newUnitIsVisible)
	UnitIsVisible = newUnitIsVisible;
end
]]

--[[ ]]
do
	local origIsSpellInRange = IsSpellInRange;
	local function newIsSpellInRange(...)
		core:Debug("<newIsSpellInRange>", ...);
		
		if (core:IsEnabled()) then
			local count = select("#", ...);
			local unit = select(count, ...);
			local name = UnitName(unit);
			--core:Debug("unit: " .. tostring(unit) .. ", name: " .. tostring(name));
			if (core.ignoredNames[name]) then
				return nil;
			end
		end
		
		return origIsSpellInRange(...);
	end
	--hooksecurefunc("IsSpellInRange", newIsSpellInRange)
	IsSpellInRange = newIsSpellInRange;
end


--[[ ]]
do
	local origIsItemInRange = IsItemInRange;
	local function newIsItemInRange(...)
		core:Debug("<newIsItemInRange>", ...);
		
		if (core:IsEnabled()) then
			local count = select("#", ...);
			local unit = select(count, ...);
			local name = UnitName(unit);
			--core:Debug("unit: " .. tostring(unit) .. ", name: " .. tostring(name));
			if (core.ignoredNames[name]) then
				return nil;
			end
		end
		
		return origIsItemInRange(...);
	end
	--hooksecurefunc("IsItemInRange", newIsItemInRange)
	IsItemInRange = newIsItemInRange;
end


function core:IgnoreList_Update(...)
	core:Debug("<IgnoreList_Update>", ...);
	core:UpdateIgnoreList();
end	

core.ignoredNames = {}
function core:UpdateIgnoreList()
	core.ignoredNames = {} --reset
	local name;
	for i=1, GetNumIgnores() do
		name = GetIgnoreName(i)
		if name then
			name = self:GetJustName(name);
			--core:Debug("Ignored name: '" .. tostring(name) .. "'");
			core.ignoredNames[name] = true
		end
	end
end

function core:GetJustName(fullName)
    return fullName:match("(.+)%-") or fullName;
end

--[[
do
	local OnDisable = core.OnDisable
	function core:OnDisable(...)
		if OnDisable then OnDisable(self, ...) end
	end
end
]]

local strWhiteBar		= "|cffffff00 || |r" -- a white bar to seperate the debug info.
do
	local colouredName		= "|cff008000IU:|r "

	local tostring = tostring
	local select = select
	local _G = _G

	local msg
	local part
	
	local cf
	local function echo(self, ...)
		msg = tostring(select(1, ...))
		for i = 2, select("#", ...) do
			part = select(i, ...)
			msg = msg..strWhiteBar..tostring(part)
		end
		
		cf = _G["ChatFrame1"]
		if cf then
			cf:AddMessage(colouredName..msg,.7,.7,.7)
		end
	end
	core.echo = echo

	local strDebugFrom		= "|cffffff00[%s]|r" --Yellow function name. help pinpoint where the debug msg is from.
	
	local select = select
	local tostring = tostring
	
	local msg
	local part
	local function Debug(self, ...)
		if core.db.profile.debugMessages == false then
			return
		end
		
		msg = "nil"
		if select(1, ...) then
			msg = tostring(select(1, ...))
			for i = 2, select("#", ...) do
				part = select(i, ...)
				msg = msg..strWhiteBar..tostring(part)
			end
		end
		core:echo(strDebugFrom:format("D").." "..msg)
	end
	core.Debug = Debug
end