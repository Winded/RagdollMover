-- Inherits DFrame to provide a minimal changelog interface
local PANEL = {}

local changelogURL = "https://steamcommunity.com/sharedfiles/filedetails/changelog/104575630"
local changelogId = "RGMChangelog"

local COLOR_WHITE = Color(255, 255, 255, 255)
local COLOR_BG = Color(16, 19, 27, 255)
local COLOR_FG = Color(23, 26, 33, 255)

local titleBarSize = 40
local discussFilter = "Discuss this update in the"

local generatedChangelog

local conversions = {
    ["&quot;"] = '"'
}

---Obtain formatted change notes from html
---@param htmlBody string
---@return string
local function parseHTMLForChangelog(htmlBody)
    local changelogBody = ""

    -- The changelog is bound between 'var changeLogs = new Array();' and '"style="clear: both;"' we scrape our changelog
    local startPosition = string.find(htmlBody, "changeLogs", 1, true)
    local endPosition = string.find(htmlBody, 'style="clear: both;"', startPosition, true)

    if not startPosition and not endPosition then
        return "Failed to scrape HTML for change notes"
    end

    ---@cast startPosition integer
    ---@cast endPosition integer

    ---@type (string)[]
    local changelogBounds = string.Split(string.sub(htmlBody, startPosition, endPosition), "\n")

    for i = 2, #changelogBounds - 1 do
        -- Trim trailing lines and remove html tags
        local line = changelogBounds[i]:Trim():gsub("%b<>", "")
        if string.find(line, discussFilter, 1, true) then
            continue
        end

        if #line == 0 then continue end
        for pattern, convert in pairs(conversions) do
            line = line:gsub(pattern, convert)
        end

        changelogBody = changelogBody .. line .. "\n\n"
    end

    return changelogBody
end

function PANEL:Init()
    self:MakePopup()
    self:SetTitle("Ragdoll Mover Changelog")
    self:SetBackgroundBlur(true)

    self.btnClose.Paint = function( panel, w, h ) end

    self.changelogText = vgui.Create("RichText", self)
    self.changelogText:Dock(FILL)
    self.changelogText:InsertColorChange(COLOR_WHITE:Unpack())
    self.changelogText:InsertClickableTextStart(changelogId)
    self.changelogText:AppendText("Full Changelog\n\n")
    self.changelogText:InsertClickableTextEnd()
    
    -- Fetch the changelog once on panel initialization
    if generatedChangelog and type(generatedChangelog) == "string" then
        self.changelogText:AppendText(generatedChangelog)
    else
        http.Fetch(changelogURL, function(body, _, _, _)
            generatedChangelog = parseHTMLForChangelog(body)
            self.changelogText:AppendText(generatedChangelog)
        end, function(err) 
            self.changelogText:AppendText("Failed to fetch changelog\n\n")
            self.changelogText:AppendText(err)
        end)    
    end

    function self.changelogText:OnTextClicked(id)
        if id == changelogId then
            gui.OpenURL(changelogURL)
        end
    end
end

-- Override DFrame:Paint() and DFrame:PerformLayout() to provide our own styles for the changelog
function PANEL:Paint( w, h )
    if ( self.m_bBackgroundBlur ) then
        Derma_DrawBackgroundBlur( self, self.m_fCreateTime )
    end

    -- Draw title bar
    draw.RoundedBox(8, 0, titleBarSize, self:GetWide(), self:GetTall() - titleBarSize, COLOR_FG)

    -- Draw frame
    draw.RoundedBox(8, 0, 0, self:GetWide(), 80, COLOR_BG)
    -- self:SetBGColor(COLOR_BG)
end

function PANEL:PerformLayout()
    self.btnClose:SetPos(self:GetWide() - 60, 30)
    self.btnClose:SetSize(31, 24)
    self.btnClose:SetText("X")
    self.btnClose:SetTextColor(COLOR_WHITE)
    self.btnClose:SetFontInternal("RagdollMoverChangelogTitleFont")

    self.lblTitle:SetPos( self:GetWide() / 8, 20 )
    self.lblTitle:SetSize( self:GetWide(), 40 )
    self.lblTitle:SetFontInternal("RagdollMoverChangelogTitleFont")

    self.btnMaxim:SetVisible( false )
    self.btnMinim:SetVisible( false )

    self.changelogText:SetFontInternal("RagdollMoverChangelogFont")
end

vgui.Register("rgm_changelog", PANEL, "DFrame")
