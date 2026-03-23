--[[
    ╔══════════════════════════════════════════╗
    ║         H4LL0 ADMIN HUB                 ║
    ║          Admin Panel  •  v2.0           ║
    ║     FIXED: Fly Mobile Controller        ║
    ╚══════════════════════════════════════════╝
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Debris           = game:GetService("Debris")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

local C = {
    BG_Main    = Color3.fromRGB(8,  12, 20),
    BG_Side    = Color3.fromRGB(12, 18, 30),
    BG_Content = Color3.fromRGB(14, 22, 36),
    BG_Card    = Color3.fromRGB(18, 28, 46),
    Accent     = Color3.fromRGB(30, 100, 220),
    AccentDim  = Color3.fromRGB(20,  60, 140),
    AccentGlow = Color3.fromRGB(60, 140, 255),
    ON         = Color3.fromRGB(30, 100, 220),
    OFF        = Color3.fromRGB(20,  30,  50),
    TextMain   = Color3.fromRGB(200, 220, 255),
    TextSub    = Color3.fromRGB(100, 130, 180),
    TextDim    = Color3.fromRGB(50,  70, 110),
    Border     = Color3.fromRGB(30,  60, 110),
    Red        = Color3.fromRGB(220, 50,  50),
    Green      = Color3.fromRGB(50,  200, 120),
    Gold       = Color3.fromRGB(255, 200, 50),
    Purple     = Color3.fromRGB(168, 85,  247),
    Orange     = Color3.fromRGB(255, 140, 50),
    Cyan       = Color3.fromRGB(50,  200, 220),
}

local Toggles = {
    GodMode    = false,
    Invisible  = false,
    Fly        = false,
    InfJump    = false,
    Aimbot     = false,
    SilentAim  = false,
    StrongLock = false,
    AutoShoot  = false,
}

local Settings = {
    WalkSpeed      = 16,
    FlySpeed       = 50,
    FOV            = 200,
    AimSpeed       = 10,
    FlyDir         = nil, -- for mobile fly controller
    FlyBG          = nil,
    FlyBV          = nil,
    SelectedPlayer = nil,
    BannedPlayers  = {},
    VALID_KEY      = "Admin_key_Cheat",
}

local Connections = {}
local Minimized   = false

local function New(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    if parent then obj.Parent = parent end
    return obj
end

local function Corner(p, r)
    return New("UICorner", {CornerRadius = UDim.new(0, r or 8)}, p)
end

local function Stroke(p, col, th)
    return New("UIStroke", {Color = col or C.Border, Thickness = th or 1}, p)
end

local function Tween(obj, props, t)
    pcall(function()
        TweenService:Create(obj, TweenInfo.new(t or 0.25, Enum.EasingStyle.Quart), props):Play()
    end)
end

local function GetChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function StopAll()
    for k, c in pairs(Connections) do
        pcall(function() c:Disconnect() end)
        Connections[k] = nil
    end
end

local function GetOtherPlayers()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(list, plr) end
    end
    return list
end

local function GetAimTarget()
    local closest, dist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < Settings.FOV and d < dist then dist=d; closest=head end
                end
            end
        end
    end
    return closest
end

local function StartBanCheck()
    Connections.BanCheck = Players.PlayerAdded:Connect(function(plr)
        if Settings.BannedPlayers[plr.UserId] or Settings.BannedPlayers[plr.Name] then
            pcall(function() plr:Kick("🛡️ You are banned from this server by H4ll0 Admin Hub.") end)
        end
    end)
end

local function ApplyFeature(key, val)
    local char, hrp, hum = GetChar()

    if key == "GodMode" then
        if val then
            Connections.GodMode = RunService.Heartbeat:Connect(function()
                local _,_,h = GetChar()
                if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
            end)
        else
            if Connections.GodMode then pcall(function() Connections.GodMode:Disconnect() end); Connections.GodMode=nil end
        end

    elseif key == "Invisible" then
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                pcall(function()
                    if p:IsA("BasePart") or p:IsA("Decal") then
                        p.Transparency = val and 1 or 0
                    end
                end)
            end
        end

    elseif key == "Fly" then
        if val then
            pcall(function()
                if not hrp then return end
                local bg = Instance.new("BodyGyro")
                bg.MaxTorque = Vector3.new(1e9,1e9,1e9)
                bg.P = 1e4; bg.Parent = hrp
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.zero
                bv.MaxForce = Vector3.new(1e9,1e9,1e9)
                bv.Parent = hrp
                Settings.FlyBG = bg
                Settings.FlyBV = bv

                Connections.Fly = RunService.Heartbeat:Connect(function()
                    local cam = workspace.CurrentCamera
                    local vel = Vector3.zero

                    -- Keyboard (PC)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        vel = cam.CFrame.LookVector * Settings.FlySpeed
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        vel = -cam.CFrame.LookVector * Settings.FlySpeed
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        vel = -cam.CFrame.RightVector * Settings.FlySpeed
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        vel = cam.CFrame.RightVector * Settings.FlySpeed
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        vel = Vector3.new(0, Settings.FlySpeed, 0)
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        vel = Vector3.new(0, -Settings.FlySpeed, 0)
                    end

                    -- GUI buttons (Mobile)
                    if Settings.FlyDir then
                        if Settings.FlyDir == "forward" then
                            vel = cam.CFrame.LookVector * Settings.FlySpeed
                        elseif Settings.FlyDir == "back" then
                            vel = -cam.CFrame.LookVector * Settings.FlySpeed
                        elseif Settings.FlyDir == "left" then
                            vel = -cam.CFrame.RightVector * Settings.FlySpeed
                        elseif Settings.FlyDir == "right" then
                            vel = cam.CFrame.RightVector * Settings.FlySpeed
                        elseif Settings.FlyDir == "up" then
                            vel = Vector3.new(0, Settings.FlySpeed, 0)
                        elseif Settings.FlyDir == "down" then
                            vel = Vector3.new(0, -Settings.FlySpeed, 0)
                        end
                    end

                    bv.Velocity = vel
                    bg.CFrame = cam.CFrame
                end)
            end)
        else
            if Connections.Fly then pcall(function() Connections.Fly:Disconnect() end); Connections.Fly=nil end
            Settings.FlyDir=nil; Settings.FlyBG=nil; Settings.FlyBV=nil
            if hrp then
                for _, obj in ipairs(hrp:GetChildren()) do
                    if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end

    elseif key == "InfJump" then
        if val then
            Connections.InfJump = UserInputService.JumpRequest:Connect(function()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if Connections.InfJump then pcall(function() Connections.InfJump:Disconnect() end); Connections.InfJump=nil end
        end

    elseif key == "Aimbot" then
        if val then
            Connections.Aimbot = RunService.RenderStepped:Connect(function()
                local t = GetAimTarget()
                if t then
                    pcall(function()
                        Camera.CFrame = Camera.CFrame:Lerp(
                            CFrame.lookAt(Camera.CFrame.Position, t.Position),
                            math.clamp(Settings.AimSpeed/100, 0.02, 0.3))
                    end)
                end
            end)
        else
            if Connections.Aimbot then pcall(function() Connections.Aimbot:Disconnect() end); Connections.Aimbot=nil end
        end

    elseif key == "SilentAim" then
        if val then
            Connections.SilentAim = RunService.RenderStepped:Connect(function()
                local t = GetAimTarget()
                if t and hrp then
                    pcall(function()
                        local dir = (t.Position - hrp.Position).Unit
                        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.atan2(dir.X, dir.Z), 0)
                    end)
                end
            end)
        else
            if Connections.SilentAim then pcall(function() Connections.SilentAim:Disconnect() end); Connections.SilentAim=nil end
        end

    elseif key == "StrongLock" then
        if val then
            Connections.StrongLock = RunService.RenderStepped:Connect(function()
                local t = GetAimTarget()
                if t then
                    pcall(function()
                        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, t.Position)
                    end)
                end
            end)
        else
            if Connections.StrongLock then pcall(function() Connections.StrongLock:Disconnect() end); Connections.StrongLock=nil end
        end

    elseif key == "AutoShoot" then
        if val then
            Connections.AutoShoot = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        local remote = tool:FindFirstChildOfClass("RemoteEvent")
                        if remote then remote:FireServer() end
                    end
                end)
            end)
        else
            if Connections.AutoShoot then pcall(function() Connections.AutoShoot:Disconnect() end); Connections.AutoShoot=nil end
        end
    end
end

-- ═══════════════════════════
--        KEY SCREEN
-- ═══════════════════════════
local GUI = New("ScreenGui", {
    Name="H4ll0Admin", ResetOnSpawn=false,
    DisplayOrder=999, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
}, game.CoreGui)

local KeyScreen = New("Frame", {
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=C.BG_Main, BorderSizePixel=0,
}, GUI)

for i=1,20 do
    New("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(i/20,0,0,0),BackgroundColor3=C.Border,BackgroundTransparency=0.85,BorderSizePixel=0},KeyScreen)
    New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,i/20,0),BackgroundColor3=C.Border,BackgroundTransparency=0.85,BorderSizePixel=0},KeyScreen)
end

local glowCircle=New("Frame",{Size=UDim2.new(0,200,0,200),Position=UDim2.new(0.5,-100,0.2,-100),BackgroundColor3=C.Accent,BackgroundTransparency=0.85,BorderSizePixel=0},KeyScreen)
Corner(glowCircle,100)

local shieldLbl=New("TextLabel",{Size=UDim2.new(0,80,0,80),Position=UDim2.new(0.5,-40,0.2,-40),BackgroundTransparency=1,Text="🛡️",TextSize=56,Font=Enum.Font.GothamBold},KeyScreen)
task.spawn(function()
    while shieldLbl and shieldLbl.Parent do
        Tween(shieldLbl,{TextTransparency=0.2},1.5); task.wait(1.5)
        Tween(shieldLbl,{TextTransparency=0},1.5); task.wait(1.5)
    end
end)

New("TextLabel",{Size=UDim2.new(0,440,0,40),Position=UDim2.new(0.5,-220,0.38,0),BackgroundTransparency=1,Text="H4LL0 ADMIN HUB",TextColor3=C.AccentGlow,TextSize=26,Font=Enum.Font.GothamBold,TextStrokeTransparency=0.5,TextStrokeColor3=C.Accent},KeyScreen)
New("TextLabel",{Size=UDim2.new(0,440,0,22),Position=UDim2.new(0.5,-220,0.46,0),BackgroundTransparency=1,Text="ADMIN PANEL  •  KEY NEEDED",TextColor3=C.TextSub,TextSize=12,Font=Enum.Font.Gotham},KeyScreen)

local KBG=New("Frame",{Size=UDim2.new(0,340,0,36),Position=UDim2.new(0.5,-170,0.54,0),BackgroundColor3=C.BG_Card,BorderSizePixel=0},KeyScreen)
Corner(KBG,8); Stroke(KBG,C.Accent,1.5)
local KInput=New("TextBox",{Size=UDim2.new(1,-14,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,PlaceholderText="🛡️  Enter admin key...",PlaceholderColor3=C.TextDim,Text="",TextColor3=C.TextMain,TextXAlignment=Enum.TextXAlignment.Left,TextSize=13,Font=Enum.Font.GothamBold,ClearTextOnFocus=false},KBG)

local DiscordBtn=New("TextButton",{Size=UDim2.new(0,130,0,30),Position=UDim2.new(0.5,-170,0.64,0),BackgroundColor3=C.AccentDim,Text="💬 Get Key (Discord)",TextColor3=C.TextMain,TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},KeyScreen); Corner(DiscordBtn,7); Stroke(DiscordBtn,C.Border,1)
local PasteBtn=New("TextButton",{Size=UDim2.new(0,72,0,30),Position=UDim2.new(0.5,-32,0.64,0),BackgroundColor3=C.BG_Card,Text="📋 Paste",TextColor3=C.TextMain,TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},KeyScreen); Corner(PasteBtn,7); Stroke(PasteBtn,C.Border,1)
local EnterBtn=New("TextButton",{Size=UDim2.new(0,72,0,30),Position=UDim2.new(0.5,48,0.64,0),BackgroundColor3=C.Accent,Text="▶ Enter",TextColor3=Color3.fromRGB(200,220,255),TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},KeyScreen); Corner(EnterBtn,7)
local KStatus=New("TextLabel",{Size=UDim2.new(0,340,0,22),Position=UDim2.new(0.5,-170,0.72,0),BackgroundTransparency=1,Text="Enter admin key to access panel...",TextColor3=C.TextDim,TextSize=11,Font=Enum.Font.Gotham},KeyScreen)

DiscordBtn.MouseButton1Click:Connect(function()
    pcall(function() setclipboard("https://discord.gg/xCV9Tf4y5N") end)
    DiscordBtn.Text="✓ Copied!"; DiscordBtn.BackgroundColor3=C.Green
    task.wait(2); DiscordBtn.Text="💬 Get Key (Discord)"; DiscordBtn.BackgroundColor3=C.AccentDim
end)
PasteBtn.MouseButton1Click:Connect(function()
    local ok,cb=pcall(getclipboard); if ok and cb and cb~="" then KInput.Text=cb end
end)

-- ═══════════════════════════
--        MAIN ADMIN GUI
-- ═══════════════════════════
local function BuildMain()
    KeyScreen:Destroy()

    local Win=New("Frame",{Size=UDim2.new(0,640,0,460),Position=UDim2.new(0.5,-320,0.5,-230),BackgroundColor3=C.BG_Main,BorderSizePixel=0,Active=true},GUI)
    Corner(Win,12); Stroke(Win,C.Accent,1.5)

    for i=1,20 do
        New("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(i/20,0,0,0),BackgroundColor3=C.Border,BackgroundTransparency=0.92,BorderSizePixel=0},Win)
    end

    local drag,dStart,dPos=false,nil,nil
    Win.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; dStart=i.Position; dPos=Win.Position end end)
    UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dStart; Win.Position=UDim2.new(dPos.X.Scale,dPos.X.Offset+d.X,dPos.Y.Scale,dPos.Y.Offset+d.Y) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)

    local Top=New("Frame",{Size=UDim2.new(1,0,0,42),BackgroundColor3=C.BG_Side,BorderSizePixel=0,ZIndex=5},Win); Corner(Top,12)
    New("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C.BG_Side,BorderSizePixel=0,ZIndex=4},Top)
    New("Frame",{Size=UDim2.new(1,0,0,3),Position=UDim2.new(0,0,1,-3),BackgroundColor3=C.Accent,BorderSizePixel=0,ZIndex=6},Top)
    New("TextLabel",{Size=UDim2.new(0,28,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="🛡️",TextSize=20,ZIndex=6},Top)
    New("TextLabel",{Size=UDim2.new(0,220,1,0),Position=UDim2.new(0,40,0,0),BackgroundTransparency=1,Text="H4ll0 Admin Hub",TextColor3=C.AccentGlow,TextXAlignment=Enum.TextXAlignment.Left,TextSize=14,Font=Enum.Font.GothamBold,ZIndex=6},Top)
    local adminLbl=New("Frame",{Size=UDim2.new(0,70,0,20),Position=UDim2.new(0,264,0.5,-10),BackgroundColor3=Color3.fromRGB(5,15,35),BorderSizePixel=0,ZIndex=6},Top); Corner(adminLbl,5); Stroke(adminLbl,C.Accent,1)
    New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="⚙ ADMIN",TextColor3=C.Accent,TextSize=9,Font=Enum.Font.GothamBold,ZIndex=7},adminLbl)
    New("TextLabel",{Size=UDim2.new(0,150,1,0),Position=UDim2.new(1,-300,0,0),BackgroundTransparency=1,Text="👤 "..LocalPlayer.Name,TextColor3=C.TextSub,TextXAlignment=Enum.TextXAlignment.Right,TextSize=11,Font=Enum.Font.Gotham,ZIndex=6},Top)
    local MinBtn=New("TextButton",{Size=UDim2.new(0,26,0,22),Position=UDim2.new(1,-60,0.5,-11),BackgroundColor3=C.BG_Card,Text="─",TextColor3=C.TextMain,TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=6},Top); Corner(MinBtn,5)
    local CloseBtn=New("TextButton",{Size=UDim2.new(0,26,0,22),Position=UDim2.new(1,-28,0.5,-11),BackgroundColor3=C.Red,Text="✕",TextColor3=Color3.fromRGB(255,200,200),TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=6},Top); Corner(CloseBtn,5)
    CloseBtn.MouseButton1Click:Connect(function() StopAll(); Tween(Win,{Size=UDim2.new(0,640,0,0)},0.3); task.wait(0.35); GUI:Destroy() end)
    MinBtn.MouseButton1Click:Connect(function() Minimized=not Minimized; if Minimized then Tween(Win,{Size=UDim2.new(0,640,0,42)},0.3); MinBtn.Text="□" else Tween(Win,{Size=UDim2.new(0,640,0,460)},0.3); MinBtn.Text="─" end end)

    local CH=New("Frame",{Size=UDim2.new(1,0,1,-42),Position=UDim2.new(0,0,0,42),BackgroundTransparency=1,ClipsDescendants=true},Win)
    local Side=New("Frame",{Size=UDim2.new(0,130,1,0),BackgroundColor3=C.BG_Side,BorderSizePixel=0},CH); Stroke(Side,C.Border,1)
    New("UIListLayout",{Padding=UDim.new(0,3)},Side)
    New("UIPadding",{PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)},Side)
    local CA=New("Frame",{Size=UDim2.new(1,-130,1,0),Position=UDim2.new(0,130,0,0),BackgroundColor3=C.BG_Content,BorderSizePixel=0,ClipsDescendants=true},CH)
    New("UIPadding",{PaddingAll=UDim.new(0,10)},CA)

    local Pages,TabBtns={},{}
    local function MakePage(name)
        local pg=New("ScrollingFrame",{Name=name,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Accent,CanvasSize=UDim2.new(0,0,0,0),Visible=false},CA)
        local ll=New("UIListLayout",{Padding=UDim.new(0,6)},pg)
        ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() pg.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+16) end)
        Pages[name]=pg; return pg
    end
    local function SetTab(name)
        for n,pg in pairs(Pages) do pg.Visible=(n==name) end
        for n,btn in pairs(TabBtns) do
            if n==name then Tween(btn,{BackgroundColor3=C.AccentDim},0.2); btn.BackgroundTransparency=0; btn.TextColor3=C.AccentGlow
            else btn.BackgroundTransparency=1; btn.TextColor3=C.TextSub end
        end
    end
    for _,t in ipairs({{"Players","👥"},{"Combat","🎯"},{"Admin","🛡️"},{"Self","👤"},{"Cmd","💬"},{"Settings","⚙"}}) do
        MakePage(t[1])
        local btn=New("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,BackgroundColor3=C.BG_Side,Text=t[2].."  "..t[1],TextColor3=C.TextSub,TextXAlignment=Enum.TextXAlignment.Left,TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},Side)
        Corner(btn,6); New("UIPadding",{PaddingLeft=UDim.new(0,7)},btn)
        TabBtns[t[1]]=btn; btn.MouseButton1Click:Connect(function() SetTab(t[1]) end)
    end

    local function Section(parent,txt,col)
        local f=New("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1},parent)
        New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="  ▸  "..txt,TextColor3=col or C.Accent,TextXAlignment=Enum.TextXAlignment.Left,TextSize=10,Font=Enum.Font.GothamBold},f)
    end
    local function Toggle(parent,label,key,desc,col)
        local card=New("Frame",{Size=UDim2.new(1,0,0,desc and 52 or 40),BackgroundColor3=C.BG_Card,BorderSizePixel=0},parent); Corner(card,8); Stroke(card,C.Border,1)
        New("TextLabel",{Size=UDim2.new(1,-70,0,20),Position=UDim2.new(0,10,0,5),BackgroundTransparency=1,Text=label,TextColor3=C.TextMain,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},card)
        if desc then New("TextLabel",{Size=UDim2.new(1,-70,0,16),Position=UDim2.new(0,10,0,26),BackgroundTransparency=1,Text=desc,TextColor3=C.TextDim,TextXAlignment=Enum.TextXAlignment.Left,TextSize=10,Font=Enum.Font.Gotham},card) end
        local onCol=col or C.ON
        local tb=New("TextButton",{Size=UDim2.new(0,46,0,22),Position=UDim2.new(1,-54,0.5,-11),BackgroundColor3=C.OFF,Text="",BorderSizePixel=0},card); Corner(tb,11)
        local circ=New("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,3,0.5,-8),BackgroundColor3=Color3.fromRGB(200,220,255),BorderSizePixel=0},tb); Corner(circ,8)
        tb.MouseButton1Click:Connect(function()
            Toggles[key]=not Toggles[key]
            Tween(tb,{BackgroundColor3=Toggles[key] and onCol or C.OFF},0.2)
            Tween(circ,{Position=Toggles[key] and UDim2.new(0,27,0.5,-8) or UDim2.new(0,3,0.5,-8)},0.2)
            pcall(function() ApplyFeature(key,Toggles[key]) end)
        end)
    end
    local function Btn(parent,label,col,fn)
        local b=New("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundColor3=col or C.BG_Card,Text=label,TextColor3=col and Color3.fromRGB(200,220,255) or C.TextMain,TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0},parent)
        Corner(b,8); if not col then Stroke(b,C.Border,1) end
        b.MouseButton1Click:Connect(function() pcall(fn); b.BackgroundColor3=C.Green; task.wait(0.5); b.BackgroundColor3=col or C.BG_Card end)
        return b
    end
    local function Slider(parent,label,min,max,def,fn,suffix)
        local card=New("Frame",{Size=UDim2.new(1,0,0,62),BackgroundColor3=C.BG_Card,BorderSizePixel=0},parent); Corner(card,8); Stroke(card,C.Border,1)
        New("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,10,0,5),BackgroundTransparency=1,Text=label,TextColor3=C.TextMain,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},card)
        local vl=New("TextLabel",{Size=UDim2.new(0,60,0,20),Position=UDim2.new(1,-65,0,5),BackgroundTransparency=1,Text=tostring(def)..(suffix or ""),TextColor3=C.Gold,TextXAlignment=Enum.TextXAlignment.Right,TextSize=11,Font=Enum.Font.GothamBold},card)
        local pct=(def-min)/(max-min)
        local bg=New("Frame",{Size=UDim2.new(1,-20,0,8),Position=UDim2.new(0,10,0,36),BackgroundColor3=C.BG_Main,BorderSizePixel=0},card); Corner(bg,4)
        local fill=New("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=C.Accent,BorderSizePixel=0},bg); Corner(fill,4)
        local thumb=New("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(pct,-8,0.5,-8),BackgroundColor3=Color3.fromRGB(200,220,255),BorderSizePixel=0},bg); Corner(thumb,8)
        local sliding=false
        bg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=false end end)
        UserInputService.InputChanged:Connect(function(i)
            if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                local rel=math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
                local v=math.floor(min+(max-min)*rel)
                vl.Text=tostring(v)..(suffix or ""); fill.Size=UDim2.new(rel,0,1,0); thumb.Position=UDim2.new(rel,-8,0.5,-8)
                pcall(fn,v)
            end
        end)
    end

    local selectedPlayerLbl = nil
    local function BuildPlayerSelector(parent)
        local card=New("Frame",{Size=UDim2.new(1,0,0,96),BackgroundColor3=C.BG_Card,BorderSizePixel=0},parent); Corner(card,8); Stroke(card,C.Border,1)
        New("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,10,0,4),BackgroundTransparency=1,Text="👥 Select Player",TextColor3=C.TextMain,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},card)
        local list=New("ScrollingFrame",{Size=UDim2.new(1,-20,0,44),Position=UDim2.new(0,10,0,26),BackgroundColor3=C.BG_Main,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Accent,CanvasSize=UDim2.new(0,0,0,0)},card); Corner(list,5)
        local ll=New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4)},list)
        New("UIPadding",{PaddingLeft=UDim.new(0,4)},list)
        local function Refresh()
            for _,c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for _,plr in ipairs(GetOtherPlayers()) do
                local isSel=Settings.SelectedPlayer==plr
                local b=New("TextButton",{Size=UDim2.new(0,80,0,36),BackgroundColor3=isSel and C.Accent or C.BG_Card,Text=plr.Name,TextColor3=isSel and Color3.fromRGB(200,220,255) or C.TextSub,TextSize=9,Font=Enum.Font.GothamBold,BorderSizePixel=0},list)
                Corner(b,5); Stroke(b,isSel and C.Accent or C.Border,1)
                b.MouseButton1Click:Connect(function()
                    Settings.SelectedPlayer=plr
                    if selectedPlayerLbl then selectedPlayerLbl.Text="Selected: "..plr.Name end
                    Refresh()
                end)
            end
            ll:ApplyLayout()
            list.CanvasSize=UDim2.new(0,ll.AbsoluteContentSize.X+10,0,0)
        end
        Refresh()
        Btn(card,"🔄 Refresh",nil,Refresh)
    end

    -- ══════════════════════
    --   👥 PLAYERS TAB
    -- ══════════════════════
    local PP=Pages["Players"]
    Section(PP,"SELECT PLAYER")
    BuildPlayerSelector(PP)
    local selCard=New("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.BG_Card,BorderSizePixel=0},PP); Corner(selCard,8); Stroke(selCard,C.Accent,1)
    selectedPlayerLbl=New("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="Selected: None",TextColor3=C.AccentGlow,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},selCard)
    Section(PP,"ACTIONS")
    Btn(PP,"🚪 Kick Player",C.Red,function()
        local plr=Settings.SelectedPlayer; if plr then pcall(function() plr:Kick("🛡️ Kicked by H4ll0 Admin Hub.") end) end
    end)
    Btn(PP,"🔨 Ban Player",Color3.fromRGB(150,30,30),function()
        local plr=Settings.SelectedPlayer
        if plr then Settings.BannedPlayers[plr.UserId]=true; Settings.BannedPlayers[plr.Name]=true; pcall(function() plr:Kick("🛡️ Banned from this server.") end) end
    end)
    Btn(PP,"📍 Teleport to Me",C.Accent,function()
        local plr=Settings.SelectedPlayer
        if plr and plr.Character then
            local root=plr.Character:FindFirstChild("HumanoidRootPart"); local _,hrp2,_=GetChar()
            if root and hrp2 then root.CFrame=CFrame.new(hrp2.Position+Vector3.new(3,0,0)) end
        end
    end)
    Btn(PP,"❄️ Freeze Player",Color3.fromRGB(50,100,200),function()
        local plr=Settings.SelectedPlayer
        if plr and plr.Character then for _,p in ipairs(plr.Character:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.Anchored=true end) end end end
    end)
    Btn(PP,"🔥 Unfreeze Player",C.AccentDim,function()
        local plr=Settings.SelectedPlayer
        if plr and plr.Character then for _,p in ipairs(plr.Character:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.Anchored=false end) end end end
    end)
    Btn(PP,"💀 Kill Player",C.Red,function()
        local plr=Settings.SelectedPlayer
        if plr and plr.Character then
            local root=plr.Character:FindFirstChild("HumanoidRootPart")
            if root then local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(0,5000,0); bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Parent=root; Debris:AddItem(bv,0.1) end
        end
    end)
    Btn(PP,"🚀 Fling Player",C.Orange,function()
        local plr=Settings.SelectedPlayer
        if plr and plr.Character then
            local root=plr.Character:FindFirstChild("HumanoidRootPart")
            if root then local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(math.random(-500,500),1000,math.random(-500,500)); bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Parent=root; Debris:AddItem(bv,0.1) end
        end
    end)
    Btn(PP,"⚡ Speed Player",C.Cyan,function()
        local plr=Settings.SelectedPlayer
        if plr and plr.Character then local hum=plr.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.WalkSpeed=100 end end
    end)
    Btn(PP,"🔧 Give Tool",C.AccentDim,function()
        local plr=Settings.SelectedPlayer
        if plr then
            pcall(function()
                local tool=Instance.new("Tool"); tool.Name="AdminTool"
                local handle=Instance.new("Part"); handle.Name="Handle"; handle.Size=Vector3.new(1,1,1); handle.BrickColor=BrickColor.new("Bright blue"); handle.Parent=tool
                tool.Parent=plr.Backpack
            end)
        end
    end)

    -- ══════════════════
    --   🎯 COMBAT TAB
    -- ══════════════════
    local CP=Pages["Combat"]
    Section(CP,"AIMBOT")
    Toggle(CP,"Aimbot","Aimbot","Camera-only aim")
    Toggle(CP,"Silent Aim","SilentAim","Aim diam tanpa gerak kamera")
    Toggle(CP,"Strong Lock","StrongLock","Lock kamera terus ke target")
    Toggle(CP,"Auto Shoot","AutoShoot","Auto fire senjata",C.Red)
    Slider(CP,"🎯 FOV Radius",50,500,200,function(v) Settings.FOV=v end," px")
    Slider(CP,"⚡ Aim Speed",1,30,10,function(v) Settings.AimSpeed=v end,"")

    -- ══════════════════
    --   🛡️ ADMIN TAB
    -- ══════════════════
    local AP=Pages["Admin"]
    Section(AP,"SERVER CONTROL",C.Red)
    Btn(AP,"📢 Announce Message",C.Accent,function()
        pcall(function()
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage",{
                Text="[🛡️ ADMIN] H4ll0 Admin Hub is active!",
                Color=Color3.fromRGB(30,100,220),
                Font=Enum.Font.GothamBold,
                FontSize=Enum.FontSize.Size18,
            })
        end)
    end)
    Btn(AP,"🌐 Server Hop",C.AccentDim,function()
        pcall(function()
            local data=game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
            local servers={}
            for _,s in ipairs(data.data) do if s.playing<s.maxPlayers then table.insert(servers,s.id) end end
            if #servers>0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,servers[math.random(1,#servers)],LocalPlayer) end
        end)
    end)
    Btn(AP,"🔄 Rejoin",C.AccentDim,function()
        game:GetService("TeleportService"):Teleport(game.PlaceId,LocalPlayer)
    end)
    Section(AP,"BAN LIST")
    Btn(AP,"🗑️ Clear Ban List",C.AccentDim,function() Settings.BannedPlayers={} end)

    -- ══════════════════
    --   👤 SELF TAB
    -- ══════════════════
    local SELFP=Pages["Self"]
    Section(SELFP,"SELF ADMIN")
    Toggle(SELFP,"God Mode","GodMode","HP selalu penuh",C.Green)
    Toggle(SELFP,"Invisible","Invisible","Tidak terlihat player lain",C.Cyan)
    Toggle(SELFP,"Fly","Fly","Terbang — pakai controller di bawah!")
    Slider(SELFP,"✈️ Fly Speed",10,200,50,function(v) Settings.FlySpeed=v end,"")

    -- ════════════════════════════
    --   FLY CONTROLLER (MOBILE)
    -- ════════════════════════════
    Section(SELFP,"FLY CONTROLLER 📱",C.Cyan)

    local flyCard=New("Frame",{
        Size=UDim2.new(1,0,0,140),
        BackgroundColor3=C.BG_Card,BorderSizePixel=0,
    },SELFP)
    Corner(flyCard,8); Stroke(flyCard,C.Accent,1)

    New("TextLabel",{
        Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,10,0,4),
        BackgroundTransparency=1,Text="✈️ Tahan tombol untuk gerak",
        TextColor3=C.TextSub,TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=10,Font=Enum.Font.Gotham,
    },flyCard)

    -- UP button (top right)
    local upBtn=New("TextButton",{
        Size=UDim2.new(0,46,0,36),Position=UDim2.new(1,-56,0,22),
        BackgroundColor3=C.Green,Text="↑\nNaik",
        TextColor3=Color3.fromRGB(255,255,255),TextSize=10,
        Font=Enum.Font.GothamBold,BorderSizePixel=0,
    },flyCard); Corner(upBtn,7)

    -- DOWN button (bottom right)
    local downBtn=New("TextButton",{
        Size=UDim2.new(0,46,0,36),Position=UDim2.new(1,-56,0,96),
        BackgroundColor3=C.Red,Text="↓\nTurun",
        TextColor3=Color3.fromRGB(255,255,255),TextSize=10,
        Font=Enum.Font.GothamBold,BorderSizePixel=0,
    },flyCard); Corner(downBtn,7)

    -- Forward
    local fwdBtn=New("TextButton",{
        Size=UDim2.new(0,52,0,36),Position=UDim2.new(0.5,-26,0,24),
        BackgroundColor3=C.Accent,Text="▲\nMaju",
        TextColor3=Color3.fromRGB(200,220,255),TextSize=10,
        Font=Enum.Font.GothamBold,BorderSizePixel=0,
    },flyCard); Corner(fwdBtn,7)

    -- Left
    local leftBtn=New("TextButton",{
        Size=UDim2.new(0,52,0,36),Position=UDim2.new(0.5,-82,0,64),
        BackgroundColor3=C.AccentDim,Text="◀\nKiri",
        TextColor3=Color3.fromRGB(200,220,255),TextSize=10,
        Font=Enum.Font.GothamBold,BorderSizePixel=0,
    },flyCard); Corner(leftBtn,7)

    -- Stop
    local stopFlyBtn=New("TextButton",{
        Size=UDim2.new(0,52,0,36),Position=UDim2.new(0.5,-26,0,64),
        BackgroundColor3=C.BG_Main,Text="■\nStop",
        TextColor3=Color3.fromRGB(200,220,255),TextSize=10,
        Font=Enum.Font.GothamBold,BorderSizePixel=0,
    },flyCard); Corner(stopFlyBtn,7); Stroke(stopFlyBtn,C.Border,1)

    -- Right
    local rightBtn=New("TextButton",{
        Size=UDim2.new(0,52,0,36),Position=UDim2.new(0.5,30,0,64),
        BackgroundColor3=C.AccentDim,Text="▶\nKanan",
        TextColor3=Color3.fromRGB(200,220,255),TextSize=10,
        Font=Enum.Font.GothamBold,BorderSizePixel=0,
    },flyCard); Corner(rightBtn,7)

    -- Back
    local backBtn=New("TextButton",{
        Size=UDim2.new(0,52,0,36),Position=UDim2.new(0.5,-26,0,104),
        BackgroundColor3=C.Accent,Text="▼\nMundur",
        TextColor3=Color3.fromRGB(200,220,255),TextSize=10,
        Font=Enum.Font.GothamBold,BorderSizePixel=0,
    },flyCard); Corner(backBtn,7)

    -- Button connections - TAHAN untuk gerak, LEPAS untuk stop
    local function setDir(dir) Settings.FlyDir=dir end
    local function stopDir() Settings.FlyDir=nil end

    -- Forward
    fwdBtn.MouseButton1Down:Connect(function() setDir("forward") end)
    fwdBtn.MouseButton1Up:Connect(stopDir)
    fwdBtn.TouchLongPress:Connect(function() setDir("forward") end)
    fwdBtn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then stopDir() end end)

    -- Back
    backBtn.MouseButton1Down:Connect(function() setDir("back") end)
    backBtn.MouseButton1Up:Connect(stopDir)
    backBtn.TouchLongPress:Connect(function() setDir("back") end)
    backBtn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then stopDir() end end)

    -- Left
    leftBtn.MouseButton1Down:Connect(function() setDir("left") end)
    leftBtn.MouseButton1Up:Connect(stopDir)
    leftBtn.TouchLongPress:Connect(function() setDir("left") end)
    leftBtn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then stopDir() end end)

    -- Right
    rightBtn.MouseButton1Down:Connect(function() setDir("right") end)
    rightBtn.MouseButton1Up:Connect(stopDir)
    rightBtn.TouchLongPress:Connect(function() setDir("right") end)
    rightBtn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then stopDir() end end)

    -- Up
    upBtn.MouseButton1Down:Connect(function() setDir("up") end)
    upBtn.MouseButton1Up:Connect(stopDir)
    upBtn.TouchLongPress:Connect(function() setDir("up") end)
    upBtn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then stopDir() end end)

    -- Down
    downBtn.MouseButton1Down:Connect(function() setDir("down") end)
    downBtn.MouseButton1Up:Connect(stopDir)
    downBtn.TouchLongPress:Connect(function() setDir("down") end)
    downBtn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then stopDir() end end)

    -- Stop
    stopFlyBtn.MouseButton1Click:Connect(stopDir)

    -- More self features
    Toggle(SELFP,"Infinite Jump","InfJump","Loncat tanpa batas")
    Slider(SELFP,"🏃 Walk Speed",16,300,16,function(v)
        Settings.WalkSpeed=v; local _,_,hum=GetChar(); if hum then hum.WalkSpeed=v end
    end,"")
    Btn(SELFP,"🔄 Restore Defaults",C.AccentDim,function()
        local _,_,hum=GetChar(); if hum then hum.WalkSpeed=16; hum.JumpPower=50 end; workspace.Gravity=196.2
    end)

    -- ══════════════════
    --   💬 CMD TAB
    -- ══════════════════
    local CMDP=Pages["Cmd"]
    Section(CMDP,"CMD2 COMMANDS",C.Cyan)
    local cmdInfo=New("Frame",{Size=UDim2.new(1,0,0,120),BackgroundColor3=C.BG_Card,BorderSizePixel=0},CMDP); Corner(cmdInfo,8); Stroke(cmdInfo,C.Border,1)
    New("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,
        Text=":kick [name]  :ban [name]\n:ff [name]  :unff [name]\n:god [name]  :ungod [name]\n:speed [name] [num]\n:bring [name]  :kill [name]\n:freeze [name]  :thaw [name]\n:respawn [name]",
        TextColor3=C.TextSub,TextXAlignment=Enum.TextXAlignment.Left,TextSize=11,TextWrapped=true,Font=Enum.Font.GothamBold},cmdInfo)

    Section(CMDP,"EXECUTE CMD")
    local cmdCard=New("Frame",{Size=UDim2.new(1,0,0,72),BackgroundColor3=C.BG_Card,BorderSizePixel=0},CMDP); Corner(cmdCard,8); Stroke(cmdCard,C.Accent,1)
    New("TextLabel",{Size=UDim2.new(1,-16,0,20),Position=UDim2.new(0,8,0,4),BackgroundTransparency=1,Text="💬 Command Input",TextColor3=C.TextMain,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},cmdCard)
    local cmdInput=New("TextBox",{Size=UDim2.new(1,-20,0,28),Position=UDim2.new(0,10,0,26),BackgroundColor3=C.BG_Main,BorderSizePixel=0,PlaceholderText=":kick PlayerName",PlaceholderColor3=C.TextDim,Text="",TextColor3=C.AccentGlow,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold,ClearTextOnFocus=false},cmdCard); Corner(cmdInput,6); Stroke(cmdInput,C.Border,1)

    Btn(CMDP,"▶ Execute Command",C.Accent,function()
        local cmd=cmdInput.Text; if cmd=="" then return end
        local args={}; for word in cmd:gmatch("%S+") do table.insert(args,word) end
        local command=args[1] and args[1]:lower() or ""
        local targetName=args[2] or ""
        local targetPlr=nil
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr.Name:lower():find(targetName:lower()) then targetPlr=plr; break end
        end
        if command==":kick" and targetPlr then pcall(function() targetPlr:Kick("Kicked by admin.") end)
        elseif command==":kill" and targetPlr and targetPlr.Character then
            local root=targetPlr.Character:FindFirstChild("HumanoidRootPart")
            if root then local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(0,5000,0); bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Parent=root; Debris:AddItem(bv,0.1) end
        elseif command==":ff" and targetPlr and targetPlr.Character then Instance.new("ForceField").Parent=targetPlr.Character
        elseif command==":unff" and targetPlr and targetPlr.Character then
            for _,ff in ipairs(targetPlr.Character:GetChildren()) do if ff:IsA("ForceField") then ff:Destroy() end end
        elseif command==":freeze" and targetPlr and targetPlr.Character then
            for _,p in ipairs(targetPlr.Character:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.Anchored=true end) end end
        elseif command==":thaw" and targetPlr and targetPlr.Character then
            for _,p in ipairs(targetPlr.Character:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.Anchored=false end) end end
        elseif command==":speed" and targetPlr and targetPlr.Character then
            local spd=tonumber(args[3]) or 50; local hum=targetPlr.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.WalkSpeed=spd end
        elseif command==":bring" and targetPlr and targetPlr.Character then
            local root=targetPlr.Character:FindFirstChild("HumanoidRootPart"); local _,hrp2,_=GetChar()
            if root and hrp2 then root.CFrame=CFrame.new(hrp2.Position+Vector3.new(3,0,0)) end
        elseif command==":respawn" and targetPlr then pcall(function() targetPlr:LoadCharacter() end)
        elseif command==":god" and targetPlr and targetPlr.Character then
            local hum=targetPlr.Character:FindFirstChildOfClass("Humanoid")
            if hum then Connections["GOD_"..targetPlr.Name]=RunService.Heartbeat:Connect(function() if hum and hum.Health<hum.MaxHealth then hum.Health=hum.MaxHealth end end) end
        elseif command==":ungod" then
            if Connections["GOD_"..targetName] then pcall(function() Connections["GOD_"..targetName]:Disconnect() end); Connections["GOD_"..targetName]=nil end
        end
        cmdInput.Text=""
    end)

    -- ══════════════════
    --   ⚙ SETTINGS TAB
    -- ══════════════════
    local SETP=Pages["Settings"]
    Section(SETP,"PERFORMANCE")
    Btn(SETP,"🚀 Boost FPS",C.AccentDim,function()
        for _,obj in ipairs(workspace:GetDescendants()) do
            pcall(function() if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then obj.Enabled=false end end)
        end
    end)
    Btn(SETP,"☀️ Full Bright",C.AccentDim,function()
        local L=game:GetService("Lighting"); L.Brightness=10; L.ClockTime=14; L.FogEnd=1e6; L.GlobalShadows=false
    end)
    Btn(SETP,"🌙 Reset Lighting",nil,function()
        local L=game:GetService("Lighting"); L.Brightness=1; L.ClockTime=14; L.FogEnd=100000; L.GlobalShadows=true
    end)
    Section(SETP,"ABOUT")
    local about=New("Frame",{Size=UDim2.new(1,0,0,80),BackgroundColor3=C.BG_Card,BorderSizePixel=0},SETP); Corner(about,8); Stroke(about,C.Accent,1.5)
    New("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,
        Text="🛡️  H4ll0 Admin Hub  v2.0\nFix: Mobile Fly Controller ✅\nAdmin : "..LocalPlayer.Name.."\nDiscord: discord.gg/xCV9Tf4y5N",
        TextColor3=C.TextSub,TextXAlignment=Enum.TextXAlignment.Left,TextSize=11,TextWrapped=true,Font=Enum.Font.Gotham},about)
    local stopBtn=New("TextButton",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.Red,Text="⛔  Stop All Features",TextColor3=Color3.fromRGB(200,220,255),TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0},SETP); Corner(stopBtn,8)
    stopBtn.MouseButton1Click:Connect(function()
        StopAll(); for k in pairs(Toggles) do Toggles[k]=false end
        stopBtn.Text="✅ All Stopped"; task.wait(2); stopBtn.Text="⛔  Stop All Features"
    end)

    SetTab("Players")
    StartBanCheck()
end

-- ═══════════════════════════
--      KEY VALIDATION
-- ═══════════════════════════
EnterBtn.MouseButton1Click:Connect(function()
    if KInput.Text==Settings.VALID_KEY then
        KStatus.Text="✅ Access Granted! Loading..."; KStatus.TextColor3=C.Green
        for _,obj in ipairs(KeyScreen:GetDescendants()) do
            pcall(function()
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then Tween(obj,{TextTransparency=1},0.3) end
                if obj:IsA("Frame") then Tween(obj,{BackgroundTransparency=1},0.3) end
            end)
        end
        Tween(KeyScreen,{BackgroundTransparency=1},0.3)
        task.wait(0.5); BuildMain()
    else
        KStatus.Text="❌ Invalid admin key!"; KStatus.TextColor3=C.Red
        Tween(KBG,{BackgroundColor3=Color3.fromRGB(30,10,10)},0.2)
        task.wait(0.3); Tween(KBG,{BackgroundColor3=C.BG_Card},0.2)
    end
end)
