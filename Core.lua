local addon, MM = ...
MM.name = addon
MM.version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addon, "Version")) or "?"
MM.selectedMode = "m+"
MM.profiles = {}

local frame = CreateFrame("Frame")
MM.events = frame

local function currentCharacter()
    local _, classToken = UnitClass("player")
    local specIndex = GetSpecialization and GetSpecialization()
    local specID, specName
    if specIndex then
        specID, specName = GetSpecializationInfo(specIndex)
    end
    return classToken, specID, specName
end

-- Specs whose talent string decides the weapon setup (the hero-level gear data
-- cannot tell two builds of the same hero tree apart).
local STYLE_TALENTS = {
    [251] = {spellID = 81333, present = "2h", absent = "2w"}, -- Frost DK: Might of the Frozen Wastes
    [72] = {spellID = 46917, present = "2h", absent = "2w"},  -- Fury: Titan's Grip
}

local BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local base64Values = {}
for i = 1, #BASE64 do base64Values[BASE64:sub(i, i)] = i - 1 end

-- Reads the native talent export format (6 bits per character, low bit first).
local function newBitReader(text)
    local position, total = 0, #text * 6
    return function(width)
        local value = 0
        for bit = 0, width - 1 do
            if position >= total then return nil end
            local index = math.floor(position / 6) + 1
            local chunk = base64Values[text:sub(index, index)]
            if not chunk then return nil end
            if math.floor(chunk / 2 ^ (position % 6)) % 2 == 1 then value = value + 2 ^ bit end
            position = position + 1
        end
        return value
    end
end

local treeNodesCache = {}

local function stringHasSpell(importString, specID, spellID)
    if not (C_ClassTalents and C_Traits and C_ClassTalents.GetTraitTreeForSpec and C_ClassTalents.GetActiveConfigID) then return nil end
    local configID = C_ClassTalents.GetActiveConfigID()
    local treeID = C_ClassTalents.GetTraitTreeForSpec(specID)
    if not (treeID and configID) then return nil end
    local nodes = treeNodesCache[treeID]
    if not nodes then
        nodes = C_Traits.GetTreeNodes(treeID)
        treeNodesCache[treeID] = nodes
    end
    if not nodes then return nil end

    local read = newBitReader(importString)
    local version = read(8)
    if version == nil then return nil end
    -- The node layout below is only valid for the current serialization version.
    if C_Traits.GetLoadoutSerializationVersion and version ~= C_Traits.GetLoadoutSerializationVersion() then return nil end
    if read(16) ~= specID then return nil end
    for _ = 1, 16 do if read(8) == nil then return nil end end

    for _, nodeID in ipairs(nodes) do
        local selected = read(1)
        if selected == nil then return nil end
        if selected == 1 and read(1) == 1 then
            if read(1) == 1 and read(6) == nil then return nil end
            local choiceIndex = 0
            if read(1) == 1 then choiceIndex = read(2) end
            if choiceIndex == nil then return nil end
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            local entryID = nodeInfo and nodeInfo.entryIDs and nodeInfo.entryIDs[choiceIndex + 1]
            local entryInfo = entryID and C_Traits.GetEntryInfo(configID, entryID)
            local definition = entryInfo and entryInfo.definitionID and C_Traits.GetDefinitionInfo(entryInfo.definitionID)
            if definition and definition.spellID == spellID then return true end
        end
    end
    return false
end

-- Returns "2h", "2w" or nil when the data cannot tell.
function MM:WeaponStyleFromString(importString, specID)
    local marker = STYLE_TALENTS[specID]
    if not marker then return nil end
    local ok, found = pcall(stringHasSpell, importString, specID, marker.spellID)
    if not ok or found == nil then return nil end
    return found and marker.present or marker.absent
end

local WEAPON_SLOTS = {
    INVTYPE_WEAPON = true, INVTYPE_WEAPONMAINHAND = true,
    INVTYPE_WEAPONOFFHAND = true, INVTYPE_2HWEAPON = true,
}

-- Hero-level fallback from the weapons the sampled players wore.
local function weaponStyleFromEquips(equips)
    if type(equips) ~= "table" then return nil end
    local getInfo = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not getInfo then return nil end
    local function tally(slot, accepted)
        local items = type(equips[slot]) == "table" and equips[slot].items
        if type(items) ~= "table" then return 0, 0 end
        local hits, total = 0, 0
        for itemID, info in pairs(items) do
            local count = type(info) == "table" and tonumber(info.count) or 0
            total = total + count
            local equipLoc = select(4, getInfo(itemID))
            if equipLoc and accepted[equipLoc] then hits = hits + count end
        end
        return hits, total
    end
    -- Both shares use the main-hand sample as the denominator: players without
    -- an off-hand item are absent from the off-hand table.
    local twoHanded, players = tally("main-hand", {INVTYPE_2HWEAPON = true})
    if players == 0 then return nil end
    if twoHanded / players >= 0.5 then return "2h" end
    if tally("off-hand", WEAPON_SLOTS) / players >= 0.5 then return "2w" end
    return nil
end

function MM:RefreshProfiles()
    local previous = self.profiles[self.selectedProfile or 0]
    self.profiles = {}
    self.selectedProfile = nil
    local provider = _G.MurlokExport
    if type(provider) ~= "table" then return false, "provider" end

    local classToken, specID = currentCharacter()
    local classSlug = self.classSlugs[classToken]
    local specSlug = self.specSlugs[specID]
    if not classSlug or not specSlug then return true end

    local modeData = provider[self.selectedMode]
    local specData = modeData and modeData[classSlug] and modeData[classSlug][specSlug]
    if type(specData) ~= "table" then return true end

    for heroName, heroData in pairs(specData) do
        if type(heroData) == "table" and type(heroData.talents) == "table" then
            local heroNameDisplay = heroName:gsub("^%l", string.upper)
            local heroStyle = weaponStyleFromEquips(heroData.equips)
            local heroAtlas
            if heroData.id and C_Traits and C_Traits.GetSubTreeInfo then
                local configID
                if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
                    configID = C_ClassTalents.GetActiveConfigID()
                end
                configID = configID or (Constants and Constants.TraitConsts and Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID)
                if configID then
                    local ok, subtreeInfo = pcall(C_Traits.GetSubTreeInfo, configID, heroData.id)
                    if ok and type(subtreeInfo) == "table" then
                        heroNameDisplay = subtreeInfo.name or heroNameDisplay
                        heroAtlas = subtreeInfo.iconElementID
                    end
                end
            end
            for rank, importString in ipairs(heroData.talents) do
                if type(importString) == "string" and importString ~= "" then
                    self.profiles[#self.profiles + 1] = {
                        hero = heroName,
                        heroDisplay = heroNameDisplay,
                        heroAtlas = heroAtlas,
                        heroID = heroData.id,
                        rating = heroData.rating,
                        population = heroData.count,
                        rank = rank,
                        importString = importString,
                        weaponStyle = self:WeaponStyleFromString(importString, specID) or heroStyle,
                    }
                end
            end
        end
    end

    table.sort(self.profiles, function(a, b)
        if a.hero ~= b.hero then return a.hero < b.hero end
        return a.rank < b.rank
    end)
    if previous then
        for index, profile in ipairs(self.profiles) do
            if profile.importString == previous.importString then
                self.selectedProfile = index
                break
            end
        end
    end
    return true
end

function MM:DataTimestamp()
    local provider = _G.MurlokExport
    return type(provider) == "table" and provider.timestamp or nil
end

function MM:Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100MurlokMemory|r: " .. message)
    end
end

function MM:ImportProfile(profile)
    if InCombatLockdown() then return self:Print(self:T("Saia do combate antes de importar um perfil.")) end
    if not profile or type(profile.importString) ~= "string" then return self:Print(self:T("Selecione um perfil na lista.")) end

    local classToken, specID = currentCharacter()
    if not specID or not self.specSlugs[specID] then return self:Print(self:T("Carregando dados do personagem…")) end

    if not PlayerSpellsFrame or not ClassTalentLoadoutImportDialog then
        if C_AddOns and C_AddOns.LoadAddOn then pcall(C_AddOns.LoadAddOn, "Blizzard_PlayerSpells") end
    end
    if not PlayerSpellsFrame or not ClassTalentLoadoutImportDialog then
        return self:Print(self:T("O diálogo de importação de talentos não está disponível. Abra a aba Talentos e tente novamente."))
    end

    if not ClassTalentLoadoutImportDialog.ImportControl or not ClassTalentLoadoutImportDialog.NameControl then
        return self:Print(self:T("Não foi possível abrir o diálogo nativo de importação."))
    end

    if self.ui then self.ui:Hide() end
    if PlayerSpellsUtil and PlayerSpellsUtil.OpenToClassTalentsTab then
        PlayerSpellsUtil.OpenToClassTalentsTab()
    else
        ShowUIPanel(PlayerSpellsFrame)
        if PlayerSpellsFrame.SetTab and PlayerSpellsFrame.talentTabID then
            PlayerSpellsFrame:SetTab(PlayerSpellsFrame.talentTabID)
        end
    end
    ClassTalentLoadoutImportDialog:ShowDialog()

    ClassTalentLoadoutImportDialog.ImportControl:SetText(profile.importString)
    local modeName = self.selectedMode == "m+" and "Mplus" or self.selectedMode
    local loadoutName = string.format("MM_%s_%s_%d_%s", modeName, tostring(profile.hero):sub(1, 10), profile.rank, date("%Y%m%d"))
    ClassTalentLoadoutImportDialog.NameControl:SetText(loadoutName:sub(1, 30))
    self:Print(self:T("O perfil foi enviado ao diálogo nativo. Revise o nome e confirme a importação no WoW."))
end

function MM:Initialize()
    MurlokMemoryDB = type(MurlokMemoryDB) == "table" and MurlokMemoryDB or {}
    if not self.modeMap[MurlokMemoryDB.mode] then MurlokMemoryDB.mode = "m+" end
    self.selectedMode = MurlokMemoryDB.mode
    self.configReady = true

    SLASH_MURLOKMEMORY1 = "/murlokmemory"
    SLASH_MURLOKMEMORY2 = "/mmurlok"
    SlashCmdList.MURLOKMEMORY = function() self:ToggleUI() end
end

MM.modeMap = {}
for _, mode in ipairs(MM.modes) do MM.modeMap[mode.key] = mode end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event, arg)
    if event == "ADDON_LOADED" and arg == addon then
        frame:UnregisterEvent("ADDON_LOADED")
        MM:Initialize()
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" and arg ~= "player" then
        return
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        -- ToggleUI refreshes on open, so only a visible window needs updating.
        if MM.ui and MM.ui:IsShown() then
            MM:RefreshProfiles()
            MM:RefreshUI()
        end
    end
end)
