local url = "https://raw.githubusercontent.com/Abxx147369/CX/main/HWGdpkhaIAAnAuL.jpg"
local asset = url
if writefile and getcustomasset then pcall(function() writefile("img.jpg", game:HttpGet(url)) asset = getcustomasset("img.jpg") end) end

local function rep(v)
    if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
        pcall(function() v.Text = "冰美式" end)
    end
    
    if v:IsA("ImageLabel") or v:IsA("ImageButton") then
        for _, p in ipairs({"Image","HoverImage","PressedImage","BackgroundImage"}) do pcall(function() v[p]=asset end) end
    elseif v:IsA("Decal") or v:IsA("Texture") then
        pcall(function() v.Texture=asset end)
    elseif v:IsA("BasePart") and v.Name~="HumanoidRootPart" and not v:FindFirstChild("ForceTex") then
        for _, f in ipairs({Enum.NormalId.Front,Enum.NormalId.Back,Enum.NormalId.Top,Enum.NormalId.Bottom,Enum.NormalId.Left,Enum.NormalId.Right}) do
            pcall(function()
                local t=Instance.new("Texture",v)
                t.Name="ForceTex" t.Face=f t.Texture=asset t.StudsPerTileU=8 t.StudsPerTileV=8
            end)
        end
    end
end

local cg = game:GetService("CoreGui")
local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

for _, c in ipairs({cg, pg, workspace}) do
    for _, v in ipairs(c:GetDescendants()) do rep(v) end
end

cg.DescendantAdded:Connect(rep)
pg.DescendantAdded:Connect(rep)