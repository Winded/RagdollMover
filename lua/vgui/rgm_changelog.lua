-- Inherits DFrame to provide a minimal changelog interface

---@class RGMChangelog: DFrame
---@field btnClose DButton
---@field lblTitle DLabel
---@field btnMaxim DButton
---@field btnMinim DButton
---@field m_bBackgroundBlur boolean
---@field m_fCreateTime number
---@field changelogText RichText
local PANEL = {}

local CHANGELOG_URL = "https://steamcommunity.com/sharedfiles/filedetails/changelog/104575630"
local CHANGELOG_ID = "RGMChangelog"

local COLOR_WHITE = Color(255, 255, 255, 255)
local COLOR_BG = Color(16, 19, 27, 255)
local COLOR_FG = Color(23, 26, 33, 255)

local TITLE_BAR_SIZE = 40

-- TODO: Add support for different langauges
local DISCUSS_FILTER = "Discuss this update in the"

local conversions = {
    ["&quot;"] = '"'
}

local generatedChangelog

-- TODO: Add support for different languages
---Obtain formatted change notes from html
---@param htmlBody string
---@return table
local function parseHTMLForChangelog(htmlBody)
    local changelogBody = {}

    -- The changelog is bound between 'var changeLogs = new Array();' and '"style="clear: both;"' we scrape our changelog
    local startPosition = string.find(htmlBody, "changeLogs", 1, true)
    local endPosition = string.find(htmlBody, 'style="clear: both;"', startPosition, true)

    if not startPosition and not endPosition then
        return {language.GetPhrase("#ui.ragdollmover.notes.error2")}
    end

    ---@cast startPosition integer
    ---@cast endPosition integer

    ---@type (string)[]
    local changelogBounds = string.Split(string.sub(htmlBody, startPosition, endPosition), "\n")
    for i = 2, #changelogBounds - 1 do
        -- Trim trailing lines and remove html tags
        local line = changelogBounds[i]:Trim():gsub("%b<>", "")
        if string.find(line, DISCUSS_FILTER, 1, true) then
            continue
        end

        if #line == 0 then continue end
        for pattern, convert in pairs(conversions) do
            line = line:gsub(pattern, convert)
        end
        if #line < 100 then
            table.insert(changelogBody, line .. "\n\n")
        else
            for j = 1, #line, 100 do
                table.insert(changelogBody, string.sub(line, j, j - 1 + 100))
            end
        end
    end

    return changelogBody
end

function PANEL:Init()
    self:MakePopup()
    self:SetTitle("#tool.ragdollmover.name")
    self:SetBackgroundBlur(true)

    self.btnClose.Paint = function( panel, w, h ) end

    self.changelogText = vgui.Create("RichText", self)
    self.changelogText:Dock(FILL)
    self.changelogText:InsertColorChange(COLOR_WHITE:Unpack())
    self.changelogText:InsertClickableTextStart(CHANGELOG_ID)
    self.changelogText:AppendText(language.GetPhrase("#ui.ragdollmover.notes.link"))
    self.changelogText:InsertClickableTextEnd()
    self.changelogText:AppendText("\n\n")
    
    -- Fetch the changelog once on panel initialization
    if generatedChangelog and type(generatedChangelog) == "string" then
        self.changelogText:AppendText(generatedChangelog)
    else
        http.Fetch(CHANGELOG_URL, function(body, _, _, _)
            generatedChangelog = ""
            self.changelogBody = parseHTMLForChangelog(body)
            self.changelogBodyIndex = 1
        end, function(err) 
            self.changelogText:AppendText(language.GetPhrase("#ui.ragdollmover.notes.error1\n\n"))
            self.changelogText:AppendText(err)
        end)
    end

    self.changelogText:GotoTextStart()

    function self.changelogText:OnTextClicked(id)
        if id == CHANGELOG_ID then
            gui.OpenURL(CHANGELOG_URL)
        end
    end
end

-- Override DFrame:Paint() and DFrame:PerformLayout() to provide our own styles for the changelog
function PANEL:Paint( w, h )
    if ( self.m_bBackgroundBlur ) then
        Derma_DrawBackgroundBlur( self, self.m_fCreateTime )
    end

    -- Draw title bar
    draw.RoundedBox(8, 0, TITLE_BAR_SIZE, self:GetWide(), self:GetTall() - TITLE_BAR_SIZE, COLOR_FG)

    -- Draw frame
    draw.RoundedBox(8, 0, 0, self:GetWide(), 80, COLOR_BG)
    -- self:SetBGColor(COLOR_BG)
end

function PANEL:Think()
    if self.changelogText and istable(self.changelogBody) and self.changelogBodyIndex <= #self.changelogBody then
        local text = self.changelogBody[self.changelogBodyIndex]
        generatedChangelog = generatedChangelog .. text
        self.changelogText:AppendText(text)
        self.changelogText:GotoTextStart()
        self.changelogBodyIndex = self.changelogBodyIndex + 1
    end
end

function PANEL:PerformLayout()
    self.btnClose:SetPos(self:GetWide() - 60, 30)
    self.btnClose:SetSize(31, 24)
    self.btnClose:SetText("X")
    self.btnClose:SetTextColor(COLOR_WHITE)
    self.btnClose:SetFontInternal("RagdollMoverChangelogTitleFont")

    self.lblTitle:SetPos( self:GetWide() / 4, 20 )
    self.lblTitle:SetSize( self:GetWide(), 40 )
    self.lblTitle:SetFontInternal("RagdollMoverChangelogTitleFont")

    self.btnMaxim:SetVisible( false )
    self.btnMinim:SetVisible( false )

    self.changelogText:SetFontInternal("RagdollMoverChangelogFont")
end

vgui.Register("rgm_changelog", PANEL, "DFrame")
