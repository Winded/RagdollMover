TOOL.Name = "#tool.ragmover_propragdoll.name2"
TOOL.Category = "Poser"
TOOL.Command = nil
TOOL.ConfigName = ""

CVMaxPRBones = CreateConVar("sv_ragdollmover_max_prop_ragdoll_bones", 32, FCVAR_ARCHIVE + FCVAR_NOTIFY, "Maximum amount of bones that can be used in single Prop Ragdoll", 0, 4096)

local RGM_NOTIFY = {
	ENT_SELECTED = {id = 0, iserror = false},
	ENT_CLEARED = {id = 1, iserror = false},
	APPLIED = {id = 2, iserror = false},
	APPLY_FAILED = {id = 3, iserror = true},
	APPLY_FAILED_LIMIT = {id = 4, iserror = true},
	PROPRAGDOLL_CLEARED = {id = 5, iserror = false}
}

local function ClearPropRagdoll(ent)
	ent.rgmPRidtoent = nil
	ent.rgmPRenttoid = nil
	ent.rgmPRparent = nil
	duplicator.ClearEntityModifier(ent, "Ragdoll Mover Prop Ragdoll")
end

local function SendNotification(pl, id)
	net.Start("rgmprDoNotify")
	net.WriteUInt(id, 3)
	net.Send(pl)
end

if SERVER then

	util.AddNetworkString("rgmprSendConEnts")
	util.AddNetworkString("rgmprApplySkeleton")
	util.AddNetworkString("rgmprDoNotify")


	duplicator.RegisterEntityModifier("Ragdoll Mover Prop Ragdoll", function(pl, ent, data)

		ent.rgmPRenttoid = table.Copy(data.enttoid)
		ent.rgmPRidtoent = table.Copy(data.idtoent)
		ent.rgmPRparent = data.parent

		ent.rgmOldPostEntityPaste = ent.PostEntityPaste

		ent.PostEntityPaste = function(self, pl, ent, crtEnts)
			if ent.rgmOldPostEntityPaste then
				ent:rgmOldPostEntityPaste(pl, ent, crtEnts)
			end

			if not ent.rgmPRenttoid or not ent.rgmPRidtoent then return end

			for oldent, newent in pairs(crtEnts) do
				local id = ent.rgmPRenttoid[oldent]
				if not id then continue end

				ent.rgmPRidtoent[id] = newent
				ent.rgmPRenttoid[oldent] = nil
				ent.rgmPRenttoid[newent] = id
			end

			local newdata = {}
			newdata.enttoid = {}
			for e, id in pairs(ent.rgmPRenttoid) do
				if type(e) ~= "Entity" or not IsValid(e) then continue end
				newdata.enttoid[e:EntIndex()] = id
			end
			newdata.idtoent = table.Copy(ent.rgmPRidtoent)
			newdata.parent = ent.rgmPRparent

			duplicator.ClearEntityModifier(ent, "Ragdoll Mover Prop Ragdoll")
			duplicator.StoreEntityModifier(ent, "Ragdoll Mover Prop Ragdoll", newdata)

			for e, id in pairs(ent.rgmPRenttoid) do
				if type(e) ~= "Entity" or (type(e) == "Entity" and not IsValid(e)) then -- if some of those entities don't exist, then we gotta dissolve the "ragdoll"
					ClearPropRagdoll(ent)
					break
				end
			end
		end
	end)

	hook.Add("EntityRemoved", "rgmPropRagdollEntRemoved", function(ent)
		if ent.rgmPRidtoent then
			for id, ent in pairs(ent.rgmPRidtoent) do
				if not IsValid(ent) then continue end
				ClearPropRagdoll(ent)
			end
		end
	end)

	net.Receive("rgmprApplySkeleton", function(len, pl)
		local count = net.ReadUInt(13)
		local ents = {}
		local fail = false

		for i = 0, count - 1 do
			ents[i] = {}
			ents[i].ent = net.ReadEntity()
			ents[i].id = net.ReadUInt(13)
			local parent = net.ReadUInt(13)
			ents[i].parent = parent ~= 4100 and parent or nil
			if not IsValid(ents[i].ent) or not ents[i].ent:GetClass() == "prop_physics" then
				fail = true
			end
		end

		if fail or count > CVMaxPRBones:GetInt() then
			if fail then
				SendNotification(pl, RGM_NOTIFY.APPLY_FAILED.id)
			else
				SendNotification(pl, RGM_NOTIFY.APPLY_FAILED_LIMIT.id)
			end
			return
		end

		for id, data in pairs(ents) do
			local ent = data.ent

			if ent.rgmPRidtoent then
				for id, ent in pairs(ent.rgmPRidtoent) do
					ClearPropRagdoll(ent)
				end
			end

			ent.rgmPRidtoent = {}
			ent.rgmPRenttoid = {}
			ent.rgmPRparent = data.parent
			for id, moredata in pairs(ents) do
				ent.rgmPRidtoent[moredata.id] = moredata.ent
				ent.rgmPRenttoid[moredata.ent] = moredata.id
			end

			local data = {}
			data.idtoent = table.Copy(ent.rgmPRidtoent)
			data.enttoid = {}
			for ent, id in pairs(ent.rgmPRenttoid) do
				data.enttoid[ent:EntIndex()] = id
			end
			data.parent = ent.rgmPRparent

			duplicator.StoreEntityModifier(ent, "Ragdoll Mover Prop Ragdoll", data)
		end
		SendNotification(pl, RGM_NOTIFY.APPLIED.id)
	end)
end

function TOOL:LeftClick(tr)
	local stage = self:GetStage()
	local ent = tr.Entity

	return false
end

function TOOL:RightClick(tr)
	if SERVER then
		local ent = tr.Entity
		local doweusethis = false
		local conents = {}
		local count = 0

		if IsValid(ent) and ent:GetClass("prop_physics") then
			doweusethis = true
			local ents = constraint.GetAllConstrainedEntities(ent)
			for ent, _ in pairs(ents) do
				if ent:GetClass() == "prop_physics" and not IsValid(ent:GetParent()) then
					conents[ent] = true
				end
			end
			for ent, _ in pairs(conents) do
				count = count + 1
			end
		end

		net.Start("rgmprSendConEnts")
		net.WriteBool(doweusethis)
		if doweusethis then
			net.WriteUInt(count, 13)
			for ent, _ in pairs(conents) do
				net.WriteEntity(ent)
			end
		end
		net.Send(self:GetOwner())
	end

	return true
end

function TOOL:Reload(tr)
	local ent = tr.Entity
	if not IsValid(ent) or not ent.rgmPRidtoent then return false end

	if SERVER then
		for id, ent in pairs(ent.rgmPRidtoent) do
			ClearPropRagdoll(ent)
		end
		SendNotification(self:GetOwner(), RGM_NOTIFY.PROPRAGDOLL_CLEARED.id)
	end

	return true
end

if CLIENT then

TOOL.Information = {
	{name = "right"},
	{name = "reload"}
}

local PRUI
local HoveredEnt

local function RGMCallApplySkeleton()
	if not PRUI or not PRUI.PRTree or not PRUI.PRTree.Nodes then return end
	if not next(PRUI.PRTree.Nodes) then return end
	local tree = PRUI.PRTree

	net.Start("rgmprApplySkeleton")
		net.WriteUInt(tree.Bones, 13)
		for id, node in pairs(tree.Nodes) do
			net.WriteEntity(node.ent)
			net.WriteUInt(node.id, 13)
			net.WriteUInt(node.parent or 4100,13)
		end
	net.SendToServer()
end

local function rgmDoNotification(message)
	local MessageTable = {}

	for key, data in pairs(RGM_NOTIFY) do
		if not data.iserror then
			MessageTable[data.id] = function()
				notification.AddLegacy("#tool.ragmover_propragdoll.message" .. data.id, NOTIFY_GENERIC, 5)
				surface.PlaySound("buttons/button14.wav")
			end
		else
			MessageTable[data.id] = function()
				notification.AddLegacy("#tool.ragmover_propragdoll.message" .. data.id, NOTIFY_ERROR, 5)
				surface.PlaySound("buttons/button10.wav")
			end
		end
	end

	MessageTable[message]()
end

local function DeleteNodeRecursive(node)
	if IsValid(node) then
		PRUI.PRTree.Nodes[node.id] = nil
		node:SetParent(nil)
		node:Remove()
		for _, child in ipairs(node:GetChildNodes()) do
			DeleteNodeRecursive(child)
		end
	end
end

local function FindSelfRecursive(nodestart, nodefind)
	if nodestart == nodefind then return true end

	for _, node in ipairs(nodestart:GetChildNodes()) do
		if node == nodefind then return true end
		if FindSelfRecursive(node, nodefind) then return true end
	end
	return false
end

local function TreeUpdateHBar()
	local width = 0

	for id, node in pairs(PRUI.PRTree.Nodes) do
		local labelsize = node.Label:GetTextSize()
		local curwidth = labelsize + (node.depth * 17)
		if curwidth > width then
			width = curwidth
		end
	end

	PRUI.PRTree:UpdateWidth(width + 8 + 32 + 16)
end

local function AddHBar(self) -- There is no horizontal scrollbars in gmod, so I guess we'll override vertical one from GMod
	self.HBar = vgui.Create("DVScrollBar")

	self.HBar.btnUp.Paint = function(panel, w, h) derma.SkinHook("Paint", "ButtonLeft", panel, w, h) end
	self.HBar.btnDown.Paint = function(panel, w, h) derma.SkinHook("Paint", "ButtonRight", panel, w, h) end

	self.PanelWidth = 100
	self.LastWidth = 1

	self.HBar.SetScroll = function(self, scrll)
		if (not self.Enabled) then self.Scroll = 0 return end

		self.Scroll = math.Clamp( scrll, 0, self.CanvasSize )

		self:InvalidateLayout()

		local func = self:GetParent().OnHScroll
		if func then
			func(self:GetParent(), self:GetOffset())
		end
	end

	self.HBar.OnMousePressed = function(self)
		local x, y = self:CursorPos()

		local PageSize = self.BarSize

		if (x > self.btnGrip.x) then
			self:SetScroll(self:GetScroll() + PageSize)
		else
			self:SetScroll(self:GetScroll() - PageSize)
		end
	end

	self.HBar.OnCursorMoved = function(self, x, y)
		if (not self.Enabled) then return end
		if (not self.Dragging) then return end

		local x, y = self:ScreenToLocal(gui.MouseX(), 0)

		x = x - self.btnUp:GetWide()
		x = x - self.HoldPos

		local BtnHeight = self:GetTall()
		if (self:GetHideButtons()) then BtnHeight = 0 end

		local TrackSize = self:GetWide() - BtnHeight * 2 - self.btnGrip:GetWide()

		x = x / TrackSize

		self:SetScroll(x * self.CanvasSize)
	end

	self.HBar.Grip = function(self)
		if (!self.Enabled) then return end
		if (self.BarSize == 0) then return end

		self:MouseCapture(true)
		self.Dragging = true

		local x, y = self.btnGrip:ScreenToLocal(gui.MouseX(), 0)
		self.HoldPos = x

		self.btnGrip.Depressed = true
	end

	self.HBar.PerformLayout = function(self)
		local Tall = self:GetTall()
		local BtnHeight = Tall
		if (self:GetHideButtons()) then BtnHeight = 0 end
		local Scroll = self:GetScroll() / self.CanvasSize
		local BarSize = math.max(self:BarScale() * (self:GetWide() - (BtnHeight * 2)), 10)
		local Track = self:GetWide() - (BtnHeight * 2) - BarSize
		Track = Track + 1

		Scroll = Scroll * Track

		self.btnGrip:SetPos(BtnHeight + Scroll, 0)
		self.btnGrip:SetSize(BarSize, Tall)

		if (BtnHeight > 0) then
			self.btnUp:SetPos(0, 0)
			self.btnUp:SetSize(BtnHeight, Tall)

			self.btnDown:SetPos(self:GetWide() - BtnHeight, 0)
			self.btnDown:SetSize(BtnHeight, Tall)

			self.btnUp:SetVisible( true )
			self.btnDown:SetVisible( true )
		else
			self.btnUp:SetVisible( false )
			self.btnDown:SetVisible( false )
			self.btnDown:SetSize(BtnHeight, Tall)
			self.btnUp:SetSize(BtnHeight, Tall)
		end
	end

	self.OnVScroll = function(self, iOffset)
		local x = self.pnlCanvas:GetPos()
		self.pnlCanvas:SetPos(x, iOffset)
	end

	self.OnHScroll = function(self, iOffset)
		local _, y = self.pnlCanvas:GetPos()
		self.pnlCanvas:SetPos(iOffset, y)
	end

	self.PerformLayoutInternal = function(self)
		local HTall, VTall = self:GetTall(), self.pnlCanvas:GetTall()
		local HWide, VWide = self:GetWide(), self.PanelWidth
		local XPos, YPos = 0, 0

		self:Rebuild()

		self.VBar:SetUp(self:GetTall(), self.pnlCanvas:GetTall())
		self.HBar:SetUp(self:GetWide(), self.pnlCanvas:GetWide())
		YPos = self.VBar:GetOffset()
		XPos = self.HBar:GetOffset()

		if (self.VBar.Enabled) then VWide = VWide - self.VBar:GetWide() end
		if (self.HBar.Enabled) then HTall = HTall - self.HBar:GetTall() end

		self.pnlCanvas:SetPos(XPos, YPos)
		self.pnlCanvas:SetSize(VWide, HTall)

		self:Rebuild()

		if (HWide ~= self.LastWidth) then
			self.HBar:SetScroll(self.HBar:GetScroll())
		end

		if (VTall ~= self.pnlCanvas:GetTall()) then
			self.VBar:SetScroll(self.VBar:GetScroll())
		end

		self.LastWidth = HWide
	end

	self.PerformLayout = function(self)
		self:PerformLayoutInternal()
	end

	self.UpdateWidth = function(self, newwidth)
		self.PanelWidth = newwidth
		self:InvalidateLayout()
	end
end

local function CCol(cpanel,text, notexpanded)
	local cat = vgui.Create("DCollapsibleCategory",cpanel)
	cat:SetExpanded(1)
	cat:SetLabel(text)
	cpanel:AddItem(cat)
	local col = vgui.Create("DPanelList")
	col:SetAutoSize(true)
	col:SetSpacing(5)
	col:EnableHorizontal(false)
	col:EnableVerticalScrollbar(true)
	col.Paint = function()
		surface.DrawRect(0, 0, 500, 500)
	end
	cat:SetContents(col)
	cat:SetExpanded(not notexpanded)
	return col, cat
end
local function AddPRNode(parent, node)
	HoveredEnt = nil

	if node.used then return end
	if not PRUI then return end
	local bones = PRUI.PRTree.Bones

	if bones + 1 > CVMaxPRBones:GetInt() then return end
	local id = 0
	while PRUI.PRTree.Nodes[id] do
		id = id + 1
	end

	PRUI.PRTree.Nodes[id] = parent:AddNode(id .. " [" .. node.text .. "]", "icon16/brick.png")
	PRUI.PRTree.Nodes[id].ent = node.ent
	PRUI.PRTree.Nodes[id].id = id
	PRUI.PRTree.Nodes[id].parent = parent.id or nil
	PRUI.PRTree.Nodes[id].depth = parent.depth and parent.depth + 1 or 1
	PRUI.PRTree.Nodes[id]:Droppable("rgmPRMove")

	PRUI.PRTree.Nodes[id].DoRightClick = function()
		local deletemenu = DermaMenu(false, PRUI.PRTree)

		local deletebutt = deletemenu:AddOption("Remove from list", function()
			local parent = PRUI.PRTree.Nodes[id]:GetParent()
			parent:SetVisible(false)
			DeleteNodeRecursive(PRUI.PRTree.Nodes[id])
			if next(parent:GetChildren()) then
				parent:SetVisible(true)
			else
				parent:GetParent().ChildNodes = nil
			end
		end)
		deletebutt:SetIcon("icon16/cross.png")

		deletemenu:Open()
		return true
	end

	PRUI.PRTree.Nodes[id]:Receiver("rgmprNew", function(self, received, dropped)
		PRUI.PRTree:SetSelectedItem(PRUI.PRTree.Nodes[id])
		if not dropped then return end

		for k, v in ipairs(received) do
			AddPRNode(PRUI.PRTree.Nodes[id], v)
		end

	end)

	PRUI.PRTree.Nodes[id]:Receiver("rgmPRMove", function(self, received, dropped)
		PRUI.PRTree:SetSelectedItem(PRUI.PRTree.Nodes[id])
		if not dropped then return end

		for k, v in ipairs(received) do
			if FindSelfRecursive(v, self) then continue end
			local parent = v:GetParent()
			parent:SetVisible(false)
			self:InsertNode(v)
			v.parent = id
			v.depth = self.depth + 1
			if next(parent:GetChildren()) then
				parent:SetVisible(true)
			else
				parent:GetParent().ChildNodes = nil
			end

			TreeUpdateHBar()
		end
	end)

	PRUI.PRTree.Nodes[id].OnRemove = function()
		if not PRUI.PRTree.Nodes[id] then return end
		node.used = false
		node:SetIcon("icon16/brick.png")
		PRUI.PRTree.Bones = PRUI.PRTree.Bones - 1
		PRUI.PRTree.Nodes[id] = nil
	end

	node.used = true
	node:SetIcon("icon16/delete.png")

	if IsValid(PRUI.PRTree.Nodes[id]:GetParent()) then
		PRUI.PRTree.Nodes[id]:GetParent():SetVisible(true)
	end

	PRUI.PRTree.Bones = bones + 1

	TreeUpdateHBar()

end

local function PropRagdollCreator(cpanel)

	local helptext = vgui.Create("DLabel", cpanel)
	helptext:SetWrap(true)
	helptext:SetAutoStretchVertical(true)
	helptext:SetDark(true)
	helptext:SetText("#tool.ragmover_propragdoll.treeinfo")
	cpanel:AddItem(helptext)

	local PropRagdollUI = {}
	local constrainedents = CCol(cpanel, "#tool.ragmover_propragdoll.conents")

	PropRagdollUI.EntTree = vgui.Create("DTree", constrainedents)
	PropRagdollUI.EntTree:SetTall(300)
	constrainedents:AddItem(PropRagdollUI.EntTree)

	local creatorpanel = CCol(cpanel, "#tool.ragmover_propragdoll.propragdoll")

	PropRagdollUI.PRTree = vgui.Create("DTree", creatorpanel)
	PropRagdollUI.PRTree:SetTall(300)
	PropRagdollUI.PRTree.Bones = 0
	PropRagdollUI.PRTree:Receiver("rgmprNew", function(self, received, dropped)
		if not dropped then return end

		for k, v in ipairs(received) do
			AddPRNode(PropRagdollUI.PRTree, v)
		end

	end)

	PropRagdollUI.PRTree:Receiver("rgmPRMove", function(self, received, dropped)
		if not dropped then return end

		for k, v in ipairs(received) do
			local parent = v:GetParent()
			parent:SetVisible(false)
			self:Root():InsertNode(v)
			v.parent = nil
			if next(parent:GetChildren()) then
				parent:SetVisible(true)
			else
				parent:GetParent().ChildNodes = nil
			end

			TreeUpdateHBar()
		end

	end)

	AddHBar(PropRagdollUI.PRTree)
	creatorpanel:AddItem(PropRagdollUI.PRTree)
	creatorpanel:AddItem(PropRagdollUI.PRTree.HBar)

	local applybutt = vgui.Create("DButton", creatorpanel)
	applybutt:SetText("#tool.ragmover_propragdoll.apply")

	applybutt.DoClick = RGMCallApplySkeleton

	creatorpanel:AddItem(applybutt)

	return PropRagdollUI

end

local function GetModelName(ent)
	local name = ent:GetModel()
	local splitname = string.Split(name, "/")
	return splitname[#splitname]
end

local function UpdateConstrainedEnts(ents)
	if not PRUI then return end
	PRUI.EntTree:Clear()
	PRUI.PRTree:Clear()
	PRUI.EntNodes = {}
	PRUI.PRTree.Bones = 0
	PRUI.PRTree.Nodes = {}

	if not next(ents) then 	rgmDoNotification(1) return end
	for _, ent in ipairs(ents) do
		local text = GetModelName(ent)
		PRUI.EntNodes[ent] = PRUI.EntTree:AddNode(text, "icon16/brick.png")
		PRUI.EntNodes[ent]:Droppable("rgmprNew")
		PRUI.EntNodes[ent].ent = ent
		PRUI.EntNodes[ent].text = text
		PRUI.EntNodes[ent].used = false

		PRUI.EntNodes[ent].Label.OnCursorEntered = function()
			if PRUI.EntNodes[ent].used then return end
			HoveredEnt = ent
		end

		PRUI.EntNodes[ent].Label.OnCursorExited = function()
			HoveredEnt = nil
		end
	end
	rgmDoNotification(0)
end

function TOOL.BuildCPanel(CPanel)

	PRUI = PropRagdollCreator(CPanel)

end

local COLOR_RGMGREEN = Color(0,200,0,255)

function TOOL:DrawHUD()

	if PRUI and PRUI.PRTree and PRUI.PRTree.Nodes then
		for id, node in pairs(PRUI.PRTree.Nodes) do
			local ent = node.ent
			if not IsValid(ent) then break end
			local pos = ent:GetPos():ToScreen()
			local textpos = { x = pos.x+5, y = pos.y-5 }
			surface.DrawCircle(pos.x, pos.y, 3.5, COLOR_RGMGREEN)
			draw.SimpleText(node.id,"Default",textpos.x,textpos.y,COLOR_RGMGREEN,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)

			if not node.parent then continue end
			local parent = PRUI.PRTree.Nodes[node.parent].ent
			local parentpos = parent:GetPos():ToScreen()
			surface.SetDrawColor(255, 255, 255)
			surface.DrawLine(pos.x, pos.y, parentpos.x, parentpos.y)
		end
	end

	if IsValid(HoveredEnt) then
		rgm.DrawEntName(HoveredEnt)
	end

end

net.Receive("rgmprSendConEnts", function(len)

	local validents = net.ReadBool()
	local ents = {}

	if validents then
		local count = net.ReadUInt(13)
		for i = 1, count do
			ents[i] = net.ReadEntity()
		end
	end

	UpdateConstrainedEnts(ents)
end)

net.Receive("rgmprDoNotify", function(len)
	local msgid = net.ReadUInt(3)
	rgmDoNotification(msgid)
end)

end
