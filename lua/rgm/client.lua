
include("shared.lua");

hook.Add("PostDrawHUD", "RgmDraw", function()
	for _, bone in pairs(RGM.Bones) do
		bone:Draw();
	end
end);