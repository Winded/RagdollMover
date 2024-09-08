-- Inherits DFrame to provide a minimal changelog interface
local PANEL = {}

local changelogURL = "https://steamcommunity.com/sharedfiles/filedetails/changelog/104575630"

local COLOR_WHITE = Color(255, 255, 255, 255)

function PANEL:Init()
    self:MakePopup()
    self:SetTitle("Ragdoll Mover Changelog")
    self:SetBackgroundBlur(true)

    self.btnClose.Paint = function( panel, w, h ) end

    local changelogDisplay = vgui.Create("HTML", self)
    changelogDisplay:Dock(FILL)
    changelogDisplay:OpenURL(changelogURL)
end

-- Override DFrame:Paint() and DFrame:PerformLayout() to provide our own styles for the changelog
function PANEL:Paint( w, h )
    if ( self.m_bBackgroundBlur ) then
        Derma_DrawBackgroundBlur( self, self.m_fCreateTime )
    end

    return true
end

function PANEL:PerformLayout()
    local titlePush = 0

    self.btnClose:SetPos(self:GetWide() - 31 - 4, 0)
    self.btnClose:SetSize(31, 24)
    self.btnClose:SetText("X")
    self.btnClose:SetTextColor(COLOR_WHITE)
    self.btnClose:SetFontInternal("RagdollMoverChangelogFont")

    self.lblTitle:SetPos( 8 + titlePush, 2 )
    self.lblTitle:SetSize( self:GetWide() - 25 - titlePush, 20 )
    self.lblTitle:SetFontInternal("RagdollMoverChangelogFont")

    self.btnMaxim:SetVisible( false )
    self.btnMinim:SetVisible( false )
end

vgui.Register("rgm_changelog", PANEL, "DFrame")
