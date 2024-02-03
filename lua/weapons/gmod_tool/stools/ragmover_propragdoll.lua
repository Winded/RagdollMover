TOOL.Name = "#tool.ragmover_propragdoll.name2"
TOOL.Category = "Poser"
TOOL.Command = nil
TOOL.ConfigName = ""

CVMaxPRBones = CreateConVar("sv_ragdollmover_max_prop_ragdoll_bones", 32, FCVAR_ARCHIVE + FCVAR_NOTIFY, "Maximum amount of bones that can be used in single Prop Ragdoll", 0, 4096)

local APPLIED = 2
local APPLY_FAILED = 3
local APPLY_FAILED_LIMIT = 4
local PROPRAGDOLL_CLEARED = 5

local function ClearPropRagdoll(ent)
	if SERVER then
		for id, pl in ipairs(player.GetAll()) do
			if pl.rgm and pl.rgm.Entity == ent then
				pl.rgm.Entity = nil
				net.Start("rgmDeselectEntity")
				net.Send(pl)
			end
		end
	end

	ent.rgmPRidtoent = nil
	ent.rgmPRenttoid = nil
	ent.rgmPRparent = nil
	ent.rgmPRoffset = nil
	ent.rgmIKChains = nil
	if ent.rgmOldPostEntityPaste then
		ent.PostEntityPaste = ent.rgmOldPostEntityPaste
		ent.rgmOldPostEntityPaste = nil
	end

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
util.AddNetworkString("rgmprSendEnt")

duplicator.RegisterEntityModifier("Ragdoll Mover Prop Ragdoll", function(pl, ent, data)

	ent.rgmPRenttoid = table.Copy(data.enttoid)
	ent.rgmPRidtoent = table.Copy(data.idtoent)
	ent.rgmPRparent = data.parent
	ent.rgmPRoffset = data.offset
	ent.rgmPRaoffset = data.aoffset -- a stands for angle

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
		newdata.offset = ent.rgmPRoffset
		newdata.aoffset = ent.rgmPRaoffset

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
	local ents, filter = {}, {}
	local fail = false

	for i = 0, count - 1 do
		ents[i] = {}

		local ent = net.ReadEntity()
		ents[i].ent = ent
		filter[ent] = true

		ents[i].id = net.ReadUInt(13)
		local parent = net.ReadUInt(13)
		ents[i].parent = parent ~= 4100 and parent or nil
		if not IsValid(ents[i].ent) or not ents[i].ent:GetClass() == "prop_physics" then
			fail = true
		end
		ents[i].offset = net.ReadVector()
		ents[i].aoffset = net.ReadAngle()
	end

	if fail or count > CVMaxPRBones:GetInt() then
		if fail then
			SendNotification(pl, APPLY_FAILED)
		else
			SendNotification(pl, APPLY_FAILED_LIMIT)
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
		ent.rgmPRoffset = data.offset
		ent.rgmPRaoffset = data.aoffset
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
		data.offset = ent.rgmPRoffset
		data.aoffset = ent.rgmPRaoffset

		duplicator.StoreEntityModifier(ent, "Ragdoll Mover Prop Ragdoll", data)
	end

	for id, ply in ipairs(player.GetAll()) do
		if filter[ply.rgm.Entity]  then
			ply.rgm.Entity = nil
			net.Start("rgmDeselectEntity")
			net.Send(ply)
		end
	end

	SendNotification(pl, APPLIED)
end)

end

function TOOL:LeftClick(tr)
	local pl = self:GetOwner()
	local ent = tr.Entity

	if IsValid(ent) then
		if SERVER then
			net.Start("rgmprSendEnt")
				net.WriteEntity(ent)
				net.WriteBool(pl:KeyDown(IN_USE))
			net.Send(pl)
		end

		return true
	end

	return false
end

function TOOL:RightClick(tr)
	if SERVER then
		local pl = self:GetOwner()
		local ent = tr.Entity
		local doweusethis = false
		local conents = {}
		local count = 0

		if IsValid(ent) and ent:GetClass("prop_physics") then
			doweusethis = true
			local ents = constraint.GetAllConstrainedEntities(ent)
			for ent, _ in pairs(ents) do
				if ent:GetClass() == "prop_physics" and not IsValid(ent:GetParent()) and IsValid(ent) then
					conents[ent] = true
					count = count + 1
				end
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
		local pl = self:GetOwner()
		for id, ent in pairs(ent.rgmPRidtoent) do
			ClearPropRagdoll(ent)
		end
		SendNotification(self:GetOwner(), PROPRAGDOLL_CLEARED)
	end

	return true
end

if CLIENT then

TOOL.Information = {
	{name = "left"},
	{name = "left_use"},
	{name = "right"},
	{name = "reload"},
}

local ENT_SELECTED = 0
local ENT_CLEARED = 1
local PROP_NOT_IN_SET = 6

local IsEditingSliders = false

local RGM_NOTIFY = {
	[ENT_SELECTED] = false,
	[ENT_CLEARED] = false,
	[APPLIED] = false,
	[APPLY_FAILED] = true,
	[APPLY_FAILED_LIMIT] = true,
	[PROPRAGDOLL_CLEARED] = false,
	[PROP_NOT_IN_SET] = true,
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
			net.WriteUInt(node.parent or 4100, 13)
			net.WriteVector(node.offset)
			net.WriteAngle(node.aoffset)
		end
	net.SendToServer()
end

local function rgmDoNotification(message)
	if RGM_NOTIFY[message] == true then
		notification.AddLegacy("#tool.ragmover_propragdoll.message" .. message, NOTIFY_ERROR, 5)
		surface.PlaySound("buttons/button10.wav")
	elseif RGM_NOTIFY[message] == false then
		notification.AddLegacy("#tool.ragmover_propragdoll.message" .. message, NOTIFY_GENERIC, 5)
		surface.PlaySound("buttons/button14.wav")
	end
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

local function AddHBar(self) -- Copied over from ragdoll mover's thing
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

local function CCol(cpanel, text, notexpanded)
	local cat = vgui.Create("DCollapsibleCategory", cpanel)
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
local function CSlider(cpanel, axis, text)
	local sliderman = vgui.Create("DNumSlider", cpanel)
	sliderman:SetDark(true)
	sliderman:SetText(text)
	sliderman:SetDecimals(1)
	sliderman:SetDefaultValue(0)
	sliderman:SetMinMax(-1024, 1024)
	sliderman:SetValue(0)

	local mround = math.Round

	sliderman.OnValueChanged = function(self, val)
		if IsEditingSliders then return end
		IsEditingSliders = true
		local node = PRUI.PRTree:GetSelectedItem()
		if not IsValid(node) then 
			IsEditingSliders = false
			return
		end
		node.offset[axis] = val
		PRUI.PRTree.OffsetEntry:SetValue(mround(node.offset[1], 1) .. " " .. mround(node.offset[2], 1) .. " " .. mround(node.offset[3], 1))
		IsEditingSliders = false
	end

	cpanel:AddItem(sliderman)
	return sliderman
end
local function CASlider(cpanel, axis, text)
	local sliderman = vgui.Create("DNumSlider", cpanel)
	sliderman:SetDark(true)
	sliderman:SetText(text)
	sliderman:SetDecimals(1)
	sliderman:SetDefaultValue(0)
	sliderman:SetMinMax(-360, 360)
	sliderman:SetValue(0)

	local mround = math.Round

	sliderman.OnValueChanged = function(self, val)
		if IsEditingSliders then return end
		IsEditingSliders = true
		local node = PRUI.PRTree:GetSelectedItem()
		if not IsValid(node) then 
			IsEditingSliders = false
			return
		end
		node.aoffset[axis] = val
		PRUI.PRTree.AOffsetEntry:SetValue(mround(node.aoffset[1], 1) .. " " .. mround(node.aoffset[2], 1) .. " " .. mround(node.aoffset[3], 1))
		IsEditingSliders = false
	end

	cpanel:AddItem(sliderman)
	return sliderman
end

local function AddPRNode(parent, node)
	HoveredEnt = nil

	if node.used then return end
	if not PRUI then return end
	local bones = PRUI.PRTree.Bones

	if bones + 1 > CVMaxPRBones:GetInt() then
		rgmDoNotification(APPLY_FAILED_LIMIT)
		return
	end
	local id = 0
	while PRUI.PRTree.Nodes[id] do
		id = id + 1
	end

	node.id = id

	PRUI.PRTree.Nodes[id] = parent:AddNode(id .. " [" .. node.text .. "]", "icon16/brick.png")
	PRUI.PRTree.Nodes[id].ent = node.ent
	PRUI.PRTree.Nodes[id].id = id
	PRUI.PRTree.Nodes[id].offset = Vector(0, 0, 0)
	PRUI.PRTree.Nodes[id].aoffset = Angle(0, 0, 0)
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

	PRUI.PRTree.Nodes[id].Label.OnCursorEntered = function()
		HoveredEnt = node.ent
	end

	PRUI.PRTree.Nodes[id].Label.OnCursorExited = function()
		HoveredEnt = nil
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
		if IsValid(node) then
			node.used = false
			node.id = nil
			node:SetIcon("icon16/brick.png")
		end
		if PRUI.PRTree.Bones > 0 then
			PRUI.PRTree.Bones = PRUI.PRTree.Bones - 1
		end
		if not PRUI.PRTree.Nodes[id] then return end -- after some gmod update it seems like on remove is being called after the Nodes thing is emptied?
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
			v.depth = 1
			if next(parent:GetChildren()) then
				parent:SetVisible(true)
			else
				parent:GetParent().ChildNodes = nil
			end

			TreeUpdateHBar()
		end

	end)

	PropRagdollUI.PRTree.DoClick = function(self, node)
		if not PropRagdollUI.PRTree.Offsets or not IsValid(PropRagdollUI.PRTree.Offsets[1]) then return end
		PropRagdollUI.PRTree.Offsets[1]:SetValue(node.offset[1])
		PropRagdollUI.PRTree.Offsets[2]:SetValue(node.offset[2])
		PropRagdollUI.PRTree.Offsets[3]:SetValue(node.offset[3])

		PropRagdollUI.PRTree.AOffsets[1]:SetValue(node.aoffset[1])
		PropRagdollUI.PRTree.AOffsets[2]:SetValue(node.aoffset[2])
		PropRagdollUI.PRTree.AOffsets[3]:SetValue(node.aoffset[3])
	end

	AddHBar(PropRagdollUI.PRTree)
	creatorpanel:AddItem(PropRagdollUI.PRTree)
	creatorpanel:AddItem(PropRagdollUI.PRTree.HBar)

	PropRagdollUI.PRTree.OffsetEntry = vgui.Create("DTextEntry", creatorpanel)
	PropRagdollUI.PRTree.OffsetEntry:SetValue("0 0 0")
	PropRagdollUI.PRTree.OffsetEntry:SetUpdateOnType(true)
	PropRagdollUI.PRTree.OffsetEntry.OnValueChange = function(self, value)
		if IsEditingSliders then return end
		IsEditingSliders = true
		local node = PropRagdollUI.PRTree:GetSelectedItem()
		if not IsValid(node) then 
			IsEditingSliders = false
			return
		end

		local values = string.Explode(" ", value)

		for i = 1, 3 do
			if values[i] and tonumber(values[i]) then
				PropRagdollUI.PRTree.Offsets[i]:SetValue(tonumber(values[i]))
				node.offset[i] = tonumber(values[i])
			end
		end
		IsEditingSliders = false
	end
	creatorpanel:AddItem(PropRagdollUI.PRTree.OffsetEntry)

	PropRagdollUI.PRTree.Offsets = {}

	PropRagdollUI.PRTree.Offsets[1] = CSlider(creatorpanel, 1, "X")
	PropRagdollUI.PRTree.Offsets[2] = CSlider(creatorpanel, 2, "Y")
	PropRagdollUI.PRTree.Offsets[3] = CSlider(creatorpanel, 3, "Z")

	PropRagdollUI.PRTree.AOffsetEntry = vgui.Create("DTextEntry", creatorpanel)
	PropRagdollUI.PRTree.AOffsetEntry:SetValue("0 0 0")
	PropRagdollUI.PRTree.AOffsetEntry:SetUpdateOnType(true)
	PropRagdollUI.PRTree.AOffsetEntry.OnValueChange = function(self, value)
		if IsEditingSliders then return end
		IsEditingSliders = true
		local node = PropRagdollUI.PRTree:GetSelectedItem()
		if not IsValid(node) then 
			IsEditingSliders = false
			return
		end

		local values = string.Explode(" ", value)

		for i = 1, 3 do
			if values[i] and tonumber(values[i]) then
				PropRagdollUI.PRTree.AOffsets[i]:SetValue(tonumber(values[i]))
				node.aoffset[i] = tonumber(values[i])
			end
		end
		IsEditingSliders = false
	end
	creatorpanel:AddItem(PropRagdollUI.PRTree.AOffsetEntry)

	PropRagdollUI.PRTree.AOffsets = {}

	PropRagdollUI.PRTree.AOffsets[1] = CASlider(creatorpanel, 1, "#tool.ragdollmover.rot1")
	PropRagdollUI.PRTree.AOffsets[2] = CASlider(creatorpanel, 2, "#tool.ragdollmover.rot2")
	PropRagdollUI.PRTree.AOffsets[3] = CASlider(creatorpanel, 3, "#tool.ragdollmover.rot3")

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

	if not next(ents) then rgmDoNotification(ENT_CLEARED) return end
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
	rgmDoNotification(ENT_SELECTED)
end

local function AddEntity(ent, setnext)
	if not PRUI or not PRUI.EntNodes or not PRUI.EntNodes[ent] then
		rgmDoNotification(PROP_NOT_IN_SET)
		return
	end

	local node = PRUI.EntNodes[ent]

	if not node.used then
		local selected = PRUI.PRTree:GetSelectedItem()
		if not IsValid(selected) then
			AddPRNode(PRUI.PRTree, node)
			notification.AddLegacy("#tool.ragmover_propragdoll.setroot", NOTIFY_GENERIC, 5)
			surface.PlaySound("buttons/button14.wav")
		else
			AddPRNode(selected, node)
			notification.AddLegacy(language.GetPhrase("tool.ragmover_propragdoll.attach") .. " " .. selected.id, NOTIFY_GENERIC, 5)
			surface.PlaySound("buttons/button14.wav")
		end

		if setnext then
			PRUI.PRTree:SetSelectedItem(PRUI.PRTree.Nodes[node.id])
		end
	else
		local selected = PRUI.PRTree:GetSelectedItem()

		if IsValid(selected) then
			local prnode = PRUI.PRTree.Nodes[node.id]
			if FindSelfRecursive(prnode, selected) then return end
			local parent = prnode:GetParent()
			parent:SetVisible(false)
			selected:InsertNode(prnode)
			prnode.parent = selected.id
			prnode.depth = selected.depth + 1
			if next(parent:GetChildren()) then
				parent:SetVisible(true)
			else
				parent:GetParent().ChildNodes = nil
			end

			TreeUpdateHBar()

			notification.AddLegacy(language.GetPhrase("tool.ragmover_propragdoll.attach") .. " " .. selected.id, NOTIFY_GENERIC, 5)
			surface.PlaySound("buttons/button14.wav")
		else
			local prnode = PRUI.PRTree.Nodes[node.id]
			local root = PRUI.PRTree
			if FindSelfRecursive(prnode, root) then return end
			local parent = prnode:GetParent()
			parent:SetVisible(false)
			root:Root():InsertNode(prnode)
			prnode.parent = nil
			prnode.depth = 1
			if next(parent:GetChildren()) then
				parent:SetVisible(true)
			else
				parent:GetParent().ChildNodes = nil
			end

			TreeUpdateHBar()

			notification.AddLegacy("#tool.ragmover_propragdoll.setroot", NOTIFY_GENERIC, 5)
			surface.PlaySound("buttons/button14.wav")
		end

		if setnext then
			PRUI.PRTree:SetSelectedItem(PRUI.PRTree.Nodes[node.id])
		end
	end

end

function TOOL.BuildCPanel(CPanel)

	PRUI = PropRagdollCreator(CPanel)

end

local COLOR_RGMGREEN = Color(0, 200, 0, 255)
local VECTOR_FORWARD = Vector(1, 0, 0)
local VECTOR_LEFT = Vector(0, 1, 0)

function TOOL:DrawHUD()

	if PRUI and PRUI.PRTree and PRUI.PRTree.Nodes then
		for id, node in pairs(PRUI.PRTree.Nodes) do
			local ent = node.ent
			if not IsValid(ent) then break end
			local pos = ent:GetPos()
			pos = LocalToWorld(node.offset, angle_zero, pos, ent:GetAngles())

			pos = pos:ToScreen()

			local textpos = { x = pos.x + 5, y = pos.y - 5 }
			surface.DrawCircle(pos.x, pos.y, 3.5, COLOR_RGMGREEN)
			if ent ~= HoveredEnt then
				draw.SimpleText(node.id, "Default", textpos.x, textpos.y, COLOR_RGMGREEN, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			end

			if not node.parent then continue end
			local parentnode = PRUI.PRTree.Nodes[node.parent]
			local parent = parentnode.ent
			local parentpos = parent:GetPos()
			parentpos = LocalToWorld(parentnode.offset, angle_zero, parentpos, parent:GetAngles())
			parentpos = parentpos:ToScreen()

			surface.SetDrawColor(255, 255, 255)
			surface.DrawLine(pos.x, pos.y, parentpos.x, parentpos.y)
		end

		local selnode = PRUI.PRTree:GetSelectedItem()
		if IsValid(selnode) then
			local ent = selnode.ent
			if not IsValid(ent) then goto skip end
			local pos, ang = ent:GetPos(), ent:GetAngles()
			pos = LocalToWorld(selnode.offset, angle_zero, pos, ang)
			local xpos = LocalToWorld(VECTOR_FORWARD * 50, angle_zero, pos, ang)
			local ypos = LocalToWorld(VECTOR_LEFT * 50, angle_zero, pos, ang)
			local zpos = LocalToWorld(vector_up * 50, angle_zero, pos, ang)

			_, ang = LocalToWorld(vector_origin, selnode.aoffset, vector_origin, ang)
			local rxpos = LocalToWorld(VECTOR_FORWARD * 25, angle_zero, pos, ang)
			local rypos = LocalToWorld(VECTOR_LEFT * 25, angle_zero, pos, ang)
			local rzpos = LocalToWorld(vector_up * 25, angle_zero, pos, ang)

			pos, xpos, ypos, zpos = pos:ToScreen(), xpos:ToScreen(), ypos:ToScreen(), zpos:ToScreen()
			rxpos, rypos, rzpos = rxpos:ToScreen(), rypos:ToScreen(), rzpos:ToScreen()

			surface.SetDrawColor(175, 0, 0)
			surface.DrawLine(pos.x, pos.y, rxpos.x, rxpos.y)

			surface.SetDrawColor(0, 175, 0)
			surface.DrawLine(pos.x, pos.y, rypos.x, rypos.y)

			surface.SetDrawColor(0, 0, 175)
			surface.DrawLine(pos.x, pos.y, rzpos.x, rzpos.y)

			surface.SetDrawColor(255, 0, 0)
			surface.DrawLine(pos.x, pos.y, xpos.x, xpos.y)

			surface.SetDrawColor(0, 255, 0)
			surface.DrawLine(pos.x, pos.y, ypos.x, ypos.y)

			surface.SetDrawColor(0, 0, 255)
			surface.DrawLine(pos.x, pos.y, zpos.x, zpos.y)
		end
	end
	::skip::
	if IsValid(HoveredEnt) then
		rgm.DrawEntName(HoveredEnt)
	end

end

local COLOR_YOU_KNOW_WHO_ELSE_IS_THE_HONORED_ONE = Color(255, 0, 255)

hook.Add("PreDrawHalos", "rgmPRDrawSelectedHalo", function()
	if IsValid(HoveredEnt) then
		halo.Add({HoveredEnt}, COLOR_YOU_KNOW_WHO_ELSE_IS_THE_HONORED_ONE, 2, 2, 1, true, true)
	end
end)

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

net.Receive("rgmprSendEnt", function(len)
	local ent = net.ReadEntity()
	local setnext = net.ReadBool()
	if not IsValid(ent) then return end
	AddEntity(ent, setnext)
end)

net.Receive("rgmprDoNotify", function(len)
	local msgid = net.ReadUInt(3)
	rgmDoNotification(msgid)
end)

end
