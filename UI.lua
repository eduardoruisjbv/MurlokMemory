local _, MM = ...

local GOLD = {0.96, 0.78, 0.20}
local PANEL = {0.035, 0.038, 0.048, 0.98}
local BORDER = {0.42, 0.34, 0.18, 0.95}
local ROW = {0.07, 0.075, 0.085, 0.98}
local backdrop = {bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1}

local function makeText(parent, template, x, y, width)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetWidth(width)
    fs:SetJustifyH("LEFT")
    return fs
end

local function makeButton(parent, label, x, y, width, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(width, 28)
    button:SetBackdrop(backdrop)
    button:SetBackdropColor(0.075, 0.075, 0.085, 0.98)
    button:SetBackdropBorderColor(unpack(BORDER))
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.label:SetPoint("CENTER")
    button.label:SetText(label)
    button.label:SetTextColor(unpack(GOLD))
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 0.88, 0.38, 1)
        GameTooltip:Hide()
    end)
    button:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(BORDER)) end)
    return button
end

function MM:CreateUI()
    if self.ui then return end
    local f = CreateFrame("Frame", "MurlokMemoryWindow", UIParent, "BackdropTemplate")
    f:SetSize(620, 500)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop(backdrop)
    f:SetBackdropColor(unpack(PANEL))
    f:SetBackdropBorderColor(unpack(BORDER))
    table.insert(UISpecialFrames, "MurlokMemoryWindow")

    local title = makeText(f, "GameFontNormalLarge", 18, -16, 520)
    title:SetText("|cffffd100MurlokMemory|r  |cffaaa89f" .. self.version .. "|r")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    f.specIcon = f:CreateTexture(nil, "ARTWORK")
    f.specIcon:SetSize(24, 24)
    f.specIcon:SetPoint("TOPLEFT", 18, -48)
    f.character = makeText(f, "GameFontHighlight", 50, -53, 548)
    f.character:SetTextColor(unpack(GOLD))
    f.modeLabel = makeText(f, "GameFontHighlightSmall", 18, -82, 580)

    f.modeButtons = {}
    local modeWidths = {70, 90, 70, 70, 70}
    local modeX = 18
    for index, mode in ipairs(self.modes) do
        local selectedMode = mode.key
        local button = makeButton(f, mode.label, modeX, -101, modeWidths[index], function()
            self.selectedMode = selectedMode
            MurlokMemoryDB.mode = selectedMode
            self.selectedProfile = nil
            self:RefreshProfiles()
            self:RefreshUI()
        end)
        button.modeKey = selectedMode
        f.modeButtons[index] = button
        modeX = modeX + modeWidths[index] + 8
    end

    f.info = makeText(f, "GameFontHighlightSmall", 18, -140, 580)
    f.info:SetTextColor(0.72, 0.72, 0.70)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -164)
    scroll:SetPoint("BOTTOMRIGHT", -38, 76)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(550)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    f.scroll = scroll
    f.content = content
    f.rows = {}
    f.empty = makeText(content, "GameFontHighlight", 8, -14, 520)
    f.empty:SetTextColor(0.8, 0.77, 0.68)

    f.import = makeButton(f, self:T("Importar perfil selecionado"), 18, -426, 250, function()
        self:ImportProfile(self.profiles[self.selectedProfile or 0])
    end)
    f.footer = makeText(f, "GameFontHighlightSmall", 18, -465, 580)
    f.footer:SetTextColor(0.72, 0.72, 0.70)
    f.footer:SetText(self:T("O addon usa os códigos de talentos distribuídos pelo MurlokExport; ele não altera talentos sem confirmação do jogador."))
    f:Hide()
    self.ui = f
end

function MM:RefreshUI()
    if not self.ui then self:CreateUI() end
    local f = self.ui
    if not self.configReady then return end

    local _, classToken = UnitClass("player")
    local specIndex = GetSpecialization and GetSpecialization()
    local specID, specName, _, specIcon
    if specIndex then specID, specName, _, specIcon = GetSpecializationInfo(specIndex) end
    local _, className = UnitClass("player")
    f.specIcon:SetTexture(specIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
    f.character:SetText((className or classToken or "?") .. " · " .. (specName or "…"))
    f.modeLabel:SetText(self:T("Modo") .. ": " .. (self.modeMap[self.selectedMode].label or self.selectedMode))

    for _, button in ipairs(f.modeButtons) do
        local active = button.modeKey == self.selectedMode
        button:SetBackdropColor(active and 0.18 or 0.075, active and 0.15 or 0.075, active and 0.075 or 0.085, 0.98)
        button:SetBackdropBorderColor(active and 1 or BORDER[1], active and 0.8 or BORDER[2], active and 0.24 or BORDER[3], 1)
    end

    local updated = self:DataTimestamp()
    if not _G.MurlokExport then
        f.info:SetText(self:T("MurlokExport não está instalado ou carregado. Instale/atualize o MurlokExport para fornecer os perfis Murlok."))
    elseif not specID then
        f.info:SetText(self:T("Carregando dados do personagem…"))
    else
        f.info:SetText(self:T("Dados fornecidos pelo MurlokExport") .. (updated and (" · " .. self:T("Dados atualizados: ") .. updated) or ""))
    end

    f.empty:SetShown(#self.profiles == 0)
    if #self.profiles == 0 then
        f.empty:SetText(_G.MurlokExport and specID and self:T("Não há perfis para esta especialização e modo.")
            or not _G.MurlokExport and self:T("MurlokExport não está instalado ou carregado. Instale/atualize o MurlokExport para fornecer os perfis Murlok.")
            or self:T("Carregando dados do personagem…"))
    end

    for index, profile in ipairs(self.profiles) do
        local row = f.rows[index]
        if not row then
            row = CreateFrame("Button", nil, f.content, "BackdropTemplate")
            row:SetSize(540, 42)
            row:SetBackdrop(backdrop)
            row:SetBackdropColor(unpack(ROW))
            row:SetBackdropBorderColor(unpack(BORDER))
            row.heroIcon = row:CreateTexture(nil, "ARTWORK")
            row.heroIcon:SetSize(28, 28)
            row.heroIcon:SetPoint("LEFT", 7, 0)
            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.text:SetPoint("TOPLEFT", row.heroIcon, "TOPRIGHT", 8, -3)
            row.text:SetJustifyH("LEFT")
            row.meta = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.meta:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -2)
            row.meta:SetJustifyH("LEFT")
            row.style = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            row.style:SetPoint("RIGHT", -12, 0)
            row.style:SetTextColor(unpack(GOLD))
            row:SetScript("OnClick", function(button)
                self.selectedProfile = button.profileIndex
                self:RefreshUI()
            end)
            row:SetScript("OnEnter", function(button)
                local item = self.profiles[button.profileIndex]
                if not item then return end
                GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
                GameTooltip:SetText(string.format("%s · #%02d", item.heroDisplay or item.hero, item.rank), 1, 0.82, 0.25)
                if item.rating then GameTooltip:AddLine(self:T("Rating da especialização heroica") .. ": " .. item.rating, 0.9, 0.9, 0.9) end
                if item.population then GameTooltip:AddLine(self:T("Jogadores na amostra") .. ": " .. item.population, 0.9, 0.9, 0.9) end
                if item.weaponStyle then
                    GameTooltip:AddLine(self:T("Estilo de arma") .. ": " .. self:T(item.weaponStyle == "2h" and "2h = arma de duas mãos" or "2w = duas armas"), 0.9, 0.9, 0.9)
                end
                GameTooltip:AddLine(self:T("A posição é deste código; rating e amostra são agregados por talento heroico."), 0.68, 0.68, 0.68, true)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", GameTooltip_Hide)
            f.rows[index] = row
        end
        row.profileIndex = index
        row.text:SetText(string.format("#%02d  ·  %s", profile.rank, profile.heroDisplay or profile.hero))
        local meta = {}
        if profile.rating then meta[#meta + 1] = self:T("rating") .. " " .. profile.rating end
        if profile.population then meta[#meta + 1] = self:T("amostra") .. " " .. profile.population end
        row.meta:SetText(table.concat(meta, "  ·  "))
        row.style:SetText(profile.weaponStyle or "")
        if profile.heroAtlas then
            row.heroIcon:SetAtlas(profile.heroAtlas)
        else
            row.heroIcon:SetTexture(specIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        local active = self.selectedProfile == index
        row:SetBackdropBorderColor(active and 1 or BORDER[1], active and 0.8 or BORDER[2], active and 0.24 or BORDER[3], 1)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 46)
        row:Show()
    end
    for index = #self.profiles + 1, #f.rows do f.rows[index]:Hide() end
    f.content:SetHeight(math.max(1, #self.profiles * 46))
    f.import:SetEnabled(#self.profiles > 0 and self.selectedProfile ~= nil)
end

function MM:ToggleUI()
    if not self.ui then self:CreateUI() end
    if self.ui:IsShown() then
        self.ui:Hide()
    else
        self:RefreshProfiles()
        self:RefreshUI()
        self.ui:Show()
    end
end

local login = CreateFrame("Frame")
login:RegisterEvent("ADDON_LOADED")
login:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == "MurlokMemory" then
        login:UnregisterEvent("ADDON_LOADED")
        MM.configReady = true
        if MM.ui then MM:RefreshUI() end
    end
end)
