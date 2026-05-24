local MenuLib = {}

function MenuLib:Init(config)
    config = config or {}

    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local HttpService = game:GetService("HttpService")

    local lp = Players.LocalPlayer
    local _guid = tostring(tick() * 100000 % 1e12)
    pcall(function() _guid = HttpService:GenerateGUID(false) end)
    local RS_BIND_INP = "MenuGuiInp_" .. _guid

    local conns = {}
    local unloaded = false
    local isOpen = false
    local prevMouseBehavior = Enum.MouseBehavior.Default
    local origMouseIconEnabled = UserInputService.MouseIconEnabled
    local activeDropdownClosers = {}

    local sg = Instance.new("ScreenGui")
    sg.Name = "MenuGui_v4"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 2147483647
    sg.Enabled = true

    local openMenu, closeMenu, toggleMenu

    -- ── All supported input types for keybind display ──────────────────
    local function inputDisplayName(inp)
        if inp.KeyCode and inp.KeyCode ~= Enum.KeyCode.Unknown then
            return inp.KeyCode.Name
        elseif inp.UserInputType then
            local t = inp.UserInputType
            if t == Enum.UserInputType.MouseButton1 then return "Mouse1"
            elseif t == Enum.UserInputType.MouseButton2 then return "Mouse2"
            elseif t == Enum.UserInputType.MouseButton3 then return "Mouse3"
            elseif t == Enum.UserInputType.MouseWheelForward then return "WheelUp"
            elseif t == Enum.UserInputType.MouseWheelBackward then return "WheelDown"
            else return t.Name end
        end
        return "?"
    end

    local function keyMatches(inp, key)
        if typeof(key) ~= "EnumItem" then return false end
        if key.EnumType == Enum.KeyCode then
            return inp.KeyCode == key
        elseif key.EnumType == Enum.UserInputType then
            return inp.UserInputType == key
        end
        return inp.KeyCode == key
    end

    local function keyDisplayName(key)
        if typeof(key) ~= "EnumItem" then return tostring(key) end
        if key.EnumType == Enum.UserInputType then
            if key == Enum.UserInputType.MouseButton1 then return "Mouse1"
            elseif key == Enum.UserInputType.MouseButton2 then return "Mouse2"
            elseif key == Enum.UserInputType.MouseButton3 then return "Mouse3"
            elseif key == Enum.UserInputType.MouseWheelForward then return "WheelUp"
            elseif key == Enum.UserInputType.MouseWheelBackward then return "WheelDown"
            else return key.Name end
        end
        return key.Name
    end

    table.insert(conns, UserInputService.InputBegan:Connect(function(inp, gpe)
        local toggleKey = _G._MenuToggleKey or Enum.KeyCode.Insert
        local unloadKey = _G._UnloadKey or Enum.KeyCode.Delete

        if isOpen and inp.KeyCode == Enum.KeyCode.Escape then
            if closeMenu then closeMenu() end
            return
        end

        if keyMatches(inp, toggleKey) and not _G._SettingKeybind then
            if toggleMenu then toggleMenu() end
        elseif keyMatches(inp, unloadKey) and not _G._SettingKeybind then
            unloaded = true
            _G._UnloadTriggered = true
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
            conns = {}
            pcall(function() RunService:UnbindFromRenderStep(RS_BIND_INP) end)
            isOpen = false
            if _G._OriginalBrightness then
                Lighting.Brightness = _G._OriginalBrightness
                Lighting.ClockTime = _G._OriginalClockTime
            end
            pcall(function() sg:Destroy() end)
        end
    end))

    local pg = lp:FindFirstChild("PlayerGui")
    task.spawn(function()
        if not pg then pg = lp:WaitForChild("PlayerGui", 10) end
        if pg then sg.Parent = pg end
    end)

    local inputBlocker = Instance.new("TextButton")
    inputBlocker.Size = UDim2.new(1, 0, 1, 0)
    inputBlocker.BackgroundTransparency = 1
    inputBlocker.Text = ""
    inputBlocker.Active = true
    inputBlocker.Visible = false
    inputBlocker.ZIndex = -10
    inputBlocker.Parent = sg

    local controls = nil
    task.spawn(function()
        pcall(function()
            local PM = require(lp:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
            controls = PM:GetControls()
        end)
    end)

    _G._MenuAutoRefresh   = true
    _G._BlurEnabled       = false
    _G._LightingDimEnabled = false
    _G._OriginalBrightness = nil
    _G._OriginalClockTime  = nil
    _G._MenuToggleKey      = Enum.KeyCode.Insert
    _G._UnloadKey          = Enum.KeyCode.Delete
    _G._SmoothAnimations   = true
    _G._ESPColour          = Color3.fromRGB(120, 40, 240)

    local ICON = {
        home        = "rbxassetid://130068439240504",
        settings    = "rbxassetid://11932591062",
        aim         = "rbxassetid://111457651714934",
        players     = "rbxassetid://13321848320",
        world       = "rbxassetid://7744394226",
        misc        = "rbxassetid://84090157888894",
        exploits    = "rbxassetid://16149155528",
        config      = "rbxassetid://130521044774541",
        general     = "rbxassetid://7733765398",
        appearance  = "rbxassetid://7347408509",
        performance = "rbxassetid://13321880274",
        keyboard    = "rbxassetid://7734022107",
        fire        = "rbxassetid://14502433595",
        protection  = "rbxassetid://73332630842054",
        skin        = "rbxassetid://81837937089566",
    }

    local function normalizeIconId(id)
        if type(id) ~= "string" and type(id) ~= "number" then return nil end
        local s = tostring(id):gsub("^%s+", ""):gsub("%s+$", "")
        if s == "" then return nil end
        if s:match("^rbxassetid://") or s:match("^rbxasset://") then return s end
        if s:match("^%d+$") then return "rbxassetid://" .. s end
        return s
    end

    local function lockInput()
        prevMouseBehavior = UserInputService.MouseBehavior
        isOpen = true
        inputBlocker.Visible = true
        pcall(function() controls:Disable() end)
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end

    local function unlockInput()
        isOpen = false
        inputBlocker.Visible = false
        pcall(function() controls:Enable() end)
        UserInputService.MouseBehavior = prevMouseBehavior
        UserInputService.MouseIconEnabled = origMouseIconEnabled
    end

    RunService:BindToRenderStep(RS_BIND_INP, Enum.RenderPriority.Input.Value + 1, function()
        if not isOpen then return end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)

    -- ── Colour palette ─────────────────────────────────────────────────
    local C = {
        BG      = Color3.fromRGB(8,   4,  18),
        SIDEBAR = Color3.fromRGB(5,   2,  12),
        CONTENT = Color3.fromRGB(11,  6,  24),
        HEADER  = Color3.fromRGB(16,  9,  32),
        ACCENT  = Color3.fromRGB(120, 40, 240),
        ACCENT2 = Color3.fromRGB(215, 38, 148),
        DIV     = Color3.fromRGB(28,  13,  52),
        TEXT    = Color3.fromRGB(255,255,255),
        DIM     = Color3.fromRGB(140,115,175),
        SEC     = Color3.fromRGB(185,160,220),
        GREEN   = Color3.fromRGB(55, 210,  95),
        YELLOW  = Color3.fromRGB(255,185,  30),
        RED     = Color3.fromRGB(225,  52,  52),
        BTN     = Color3.fromRGB(20,  10,  40),
        BTNHOV  = Color3.fromRGB(33,  17,  60),
        SEL     = Color3.fromRGB(26,  13,  48),
        DARK    = Color3.fromRGB(4,    2,   9),
    }

    local WIN_W  = config.width        or 650
    local WIN_H  = config.height       or 490
    local SIDE_W = config.sidebarWidth or 160
    local HUD_W  = config.hudWidth     or 520

    -- ── UI helpers ─────────────────────────────────────────────────────
    local function fr(parent, size, pos, col, trans, rad)
        local f = Instance.new("Frame")
        f.Size = size
        f.Position = pos or UDim2.new(0,0,0,0)
        f.BackgroundColor3 = col or C.BG
        f.BackgroundTransparency = trans or 0
        f.BorderSizePixel = 0
        f.Parent = parent
        if rad ~= nil and rad ~= false then
            local c = Instance.new("UICorner")
            c.CornerRadius = (typeof(rad) == "number") and UDim.new(0,rad) or rad
            c.Parent = f
        end
        return f
    end

    local function lbl(parent, txt, size, pos, ts, col, font)
        local l = Instance.new("TextLabel")
        l.Size = size
        l.Position = pos or UDim2.new(0,0,0,0)
        l.BackgroundTransparency = 1
        l.Text = txt
        l.TextColor3 = col or C.TEXT
        l.TextSize = ts or 11
        l.Font = font or Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextWrapped = true
        l.Parent = parent
        return l
    end

    local function gradV(parent, c1, c2)
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(1,c2)})
        g.Rotation = 90
        g.Parent = parent
        return g
    end

    local function pad(parent, l, r, t, b)
        local p = Instance.new("UIPadding")
        p.PaddingLeft   = UDim.new(0, l or 0)
        p.PaddingRight  = UDim.new(0, r or 0)
        p.PaddingTop    = UDim.new(0, t or 0)
        p.PaddingBottom = UDim.new(0, b or 0)
        p.Parent = parent
        return p
    end

    local function tw(obj, props, t, style)
        TweenService:Create(obj, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quint), props):Play()
    end

    local blurPart = nil

    -- ── Toggle widget ──────────────────────────────────────────────────
    local function mkToggle(parent, posX, initState, onToggle)
        local track = fr(parent, UDim2.new(0,44,0,24), UDim2.new(1,posX,0.5,-12), Color3.fromRGB(18,8,36), 0, 12)
        track.ClipsDescendants = true
        local fill = fr(track, UDim2.new(0,0,1,0), nil, C.ACCENT, 0, 12)
        gradV(fill, C.ACCENT, C.ACCENT2)
        local knob = fr(track, UDim2.new(0,18,0,18), UDim2.new(0,3,0.5,-9), C.TEXT, 0, 9)
        local togBtn = Instance.new("TextButton")
        togBtn.Size = UDim2.new(1,0,1,0)
        togBtn.BackgroundTransparency = 1
        togBtn.Text = ""
        togBtn.Parent = track
        local state = initState
        local function apply(anim, silent)
            local fillDest = state and UDim2.new(1,0,1,0) or UDim2.new(0,0,1,0)
            local dest     = state and UDim2.new(0,23,0.5,-9) or UDim2.new(0,3,0.5,-9)
            if anim then
                tw(fill, {Size=fillDest}, 0.35)
                tw(knob, {Position=dest}, 0.35)
            else
                fill.Size = fillDest
                knob.Position = dest
            end
            if onToggle and not silent then task.defer(function() onToggle(state) end) end
        end
        apply(false, true)
        togBtn.MouseButton1Click:Connect(function() state = not state apply(true,false) end)
        return {Get=function() return state end, Set=function(v) if v~=state then state=v apply(true,false) end end}
    end

    -- ── HUD bar ────────────────────────────────────────────────────────
    local hudBar = fr(sg, UDim2.new(0,HUD_W,0,44), UDim2.new(0.5,-HUD_W/2,0,10), C.DARK, 0, 18)
    hudBar.ZIndex = 5

    local av = fr(hudBar, UDim2.new(0,32,0,32), UDim2.new(0,10,0.5,-16), Color3.fromRGB(36,14,68), 0, 16)
    local avImg = Instance.new("ImageLabel")
    avImg.Size = UDim2.new(1,-4,1,-4)
    avImg.Position = UDim2.new(0,2,0,2)
    avImg.BackgroundTransparency = 1
    avImg.Parent = av
    Instance.new("UICorner").Parent = avImg
    task.spawn(function()
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
        end)
        if ok and url then avImg.Image = url end
    end)

    lbl(hudBar, "Welcome back,", UDim2.new(0,140,0,14), UDim2.new(0,48,0,6), 9, C.DIM)
    local nameLbl = lbl(hudBar, lp.Name, UDim2.new(0,0,0,16), UDim2.new(0,48,0,20), 12, C.TEXT, Enum.Font.GothamBold)
    nameLbl.AutomaticSize = Enum.AutomaticSize.X

    local fpsLbl  = lbl(hudBar, "...", UDim2.new(0,0,0,20), UDim2.new(0,248,0,14), 14, C.ACCENT,  Enum.Font.GothamBold)
    fpsLbl.AutomaticSize = Enum.AutomaticSize.X
    local pingLbl = lbl(hudBar, "...", UDim2.new(0,0,0,20), UDim2.new(0,340,0,14), 14, C.GREEN,   Enum.Font.GothamBold)
    pingLbl.AutomaticSize = Enum.AutomaticSize.X
    local timeLbl = lbl(hudBar, "12:00 PM", UDim2.new(0,0,0,16), UDim2.new(0,556,0,12), 14, C.TEXT, Enum.Font.GothamBold)
    timeLbl.AutomaticSize = Enum.AutomaticSize.X

    local function mkDivL(parent)
        local d = fr(parent, UDim2.new(0,2,0,18), UDim2.new(0,0,0.5,-9), C.DIV, 0.2, 1)
        gradV(d, C.ACCENT, C.ACCENT2)
        d.Visible = false
        return d
    end
    local div1 = mkDivL(hudBar)
    local div2 = mkDivL(hudBar)
    local div3 = mkDivL(hudBar)
    local div4 = mkDivL(hudBar)
    local div5 = mkDivL(hudBar)

    local homeBtn = Instance.new("TextButton")
    homeBtn.Size = UDim2.new(0,30,0,30)
    homeBtn.Position = UDim2.new(0,420,0.45,-15)
    homeBtn.BackgroundColor3 = Color3.fromRGB(24,10,48)
    homeBtn.BackgroundTransparency = 0.2
    homeBtn.Text = ""
    homeBtn.AutoButtonColor = false
    homeBtn.Parent = hudBar
    Instance.new("UICorner").Parent = homeBtn

    local homeBtnIcon1 = Instance.new("ImageLabel")
    homeBtnIcon1.Size = UDim2.new(1,0,1,0)
    homeBtnIcon1.BackgroundTransparency = 1
    homeBtnIcon1.Image = ICON.settings
    homeBtnIcon1.ScaleType = Enum.ScaleType.Fit
    homeBtnIcon1.ImageColor3 = C.TEXT
    homeBtnIcon1.ImageTransparency = 0
    homeBtnIcon1.Parent = homeBtn

    local homeBtnIcon2 = Instance.new("ImageLabel")
    homeBtnIcon2.Size = UDim2.new(1,0,1,0)
    homeBtnIcon2.BackgroundTransparency = 1
    homeBtnIcon2.Image = ICON.home
    homeBtnIcon2.ScaleType = Enum.ScaleType.Fit
    homeBtnIcon2.ImageColor3 = C.TEXT
    homeBtnIcon2.ImageTransparency = 1
    homeBtnIcon2.Parent = homeBtn

    local badge = fr(hudBar, UDim2.new(0,32,0,28), UDim2.new(0,670,0.5,-14), C.ACCENT, 0, 8)
    gradV(badge, C.ACCENT, C.ACCENT2)
    local fireI = Instance.new("ImageLabel")
    fireI.Size = UDim2.new(0,18,0,18)
    fireI.Position = UDim2.new(0.5,-9,0.5,-9)
    fireI.BackgroundTransparency = 1
    fireI.Image = ICON.fire
    fireI.ScaleType = Enum.ScaleType.Fit
    fireI.ImageColor3 = Color3.fromRGB(255,255,255)
    fireI.Parent = badge
    gradV(fireI, C.ACCENT, C.ACCENT2)
    local fireClick = Instance.new("TextButton")
    fireClick.Size = UDim2.new(1,0,1,0)
    fireClick.BackgroundTransparency = 1
    fireClick.Text = ""
    fireClick.ZIndex = 10
    fireClick.Parent = badge

    -- ── Main window ────────────────────────────────────────────────────
    local win = fr(sg, UDim2.new(0,WIN_W,0,WIN_H), UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2), C.BG, 0, 20)
    win.ClipsDescendants = true
    win.ZIndex = 1
    win.Visible = false

    local mainLayer = fr(win, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), C.BG, 1, 0)
    mainLayer.ZIndex = 2

    local dragHandle = Instance.new("TextButton")
    dragHandle.Size = UDim2.new(1,0,0,12)
    dragHandle.Position = UDim2.new(0,0,0,0)
    dragHandle.BackgroundTransparency = 1
    dragHandle.Text = ""
    dragHandle.ZIndex = 30
    dragHandle.Parent = mainLayer

    local bodyShell = fr(mainLayer, UDim2.new(1,0,1,-12), UDim2.new(0,0,0,12), C.BG, 1, 0)
    bodyShell.ZIndex = 2

    local sidebar = fr(bodyShell, UDim2.new(0,SIDE_W,1,-4), UDim2.new(0,0,0,4), C.SIDEBAR, 0, 14)
    sidebar.ZIndex = 2
    sidebar.ClipsDescendants = true

    local sidebarDivider = fr(bodyShell, UDim2.new(0,1,1,-4), UDim2.new(0,SIDE_W,0,4), C.DIV)

    local TAB_BAR_H = 42
    local tabBarIsHorizontal = false

    local topTabBar = fr(bodyShell, UDim2.new(1,-4,0,TAB_BAR_H), UDim2.new(0,2,0,4), C.SIDEBAR, 0, 14)
    topTabBar.ZIndex = 3
    topTabBar.Visible = false
    topTabBar.ClipsDescendants = true

    local topTabScroll = Instance.new("ScrollingFrame")
    topTabScroll.Size = UDim2.new(1,0,1,0)
    topTabScroll.BackgroundTransparency = 1
    topTabScroll.BorderSizePixel = 0
    topTabScroll.ScrollBarThickness = 0
    topTabScroll.CanvasSize = UDim2.new(0,0,0,0)
    topTabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    topTabScroll.ScrollingDirection = Enum.ScrollingDirection.X
    topTabScroll.Parent = topTabBar
    pad(topTabScroll, 6,6,4,4)

    local topTabLayout = Instance.new("UIListLayout")
    topTabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    topTabLayout.FillDirection = Enum.FillDirection.Horizontal
    topTabLayout.Padding = UDim.new(0,4)
    topTabLayout.Parent = topTabScroll

    local topTabDivider = fr(bodyShell, UDim2.new(1,-4,0,1), UDim2.new(0,2,0,TAB_BAR_H+4), C.DIV)
    topTabDivider.Visible = false

    local contentArea = fr(bodyShell, UDim2.new(1,-SIDE_W-2,1,-32), UDim2.new(0,SIDE_W+2,0,4), C.CONTENT, 0, 16)
    contentArea.ZIndex = 2

    local statusBar = fr(bodyShell, UDim2.new(1,-SIDE_W-2,0,28), UDim2.new(0,SIDE_W+2,1,-32), C.DARK, 0, 12)

    -- ── Nav scroll ─────────────────────────────────────────────────────
    local navHolder = fr(sidebar, UDim2.new(1,0,1,0), nil, C.SIDEBAR, 1, 0)
    local navScroll = Instance.new("ScrollingFrame")
    navScroll.Size = UDim2.new(1,0,1,0)
    navScroll.ZIndex = 2
    navScroll.BackgroundTransparency = 1
    navScroll.BorderSizePixel = 0
    navScroll.ScrollBarThickness = 0
    navScroll.CanvasSize = UDim2.new(0,0,0,0)
    navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    navScroll.Parent = navHolder
    pad(navScroll, 8,10,12,10)

    local navList = Instance.new("UIListLayout")
    navList.SortOrder = Enum.SortOrder.LayoutOrder
    navList.Padding = UDim.new(0,6)
    navList.Parent = navScroll

    local activeTab = nil
    local allTabs = {}
    local tabContents = {}
    local settingsTabs = {}
    local navLayoutOrd = 0
    local topLayoutOrd = 0
    local function nextNavOrd() navLayoutOrd = navLayoutOrd+1 return navLayoutOrd end
    local function nextTopOrd() topLayoutOrd = topLayoutOrd+1 return topLayoutOrd end

    local sectionLabels = {}
    local navSectionCount = 0
    local function addSection(name)
        navSectionCount = navSectionCount+1
        if navSectionCount > 1 then
            local rule = fr(navScroll, UDim2.new(1,-8,0,1), nil, C.DIV, 1, 0)
            rule.BackgroundTransparency = 0.35
            rule.LayoutOrder = nextNavOrd()
        end
        local s = lbl(navScroll, name, UDim2.new(1,-4,0,22), nil, 11, C.SEC, Enum.Font.GothamBold)
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.LayoutOrder = nextNavOrd()
        pad(s, 10,0,2,0)
        table.insert(sectionLabels, s)
        if navSectionCount > 1 then
            local vdiv = fr(topTabScroll, UDim2.new(0,1,0,22), nil, C.DIV, 1, 0)
            vdiv.BackgroundTransparency = 0.4
            vdiv.LayoutOrder = nextTopOrd()
        end
        local hs = lbl(topTabScroll, name, UDim2.new(0,math.max(28,#name*7),0,28), nil, 10, C.SEC, Enum.Font.GothamBold)
        hs.TextYAlignment = Enum.TextYAlignment.Center
        hs.LayoutOrder = nextTopOrd()
    end

    local function selectTab(entry)
        local isCompact = (SIDE_W <= 100)
        local tf = entry.frame
        tf.Visible = true
        tf.Position = UDim2.new(0,30,0,0)
        tw(tf, {Position=UDim2.new(0,0,0,0), BackgroundTransparency=0}, 0.4)
        tw(entry.bg,   {BackgroundTransparency=0}, 0.3)
        tw(entry.line, {BackgroundTransparency=isCompact and 1 or 0, Size=UDim2.new(0,4,0.5,0)}, 0.35)
        tw(entry.lbl,  {TextColor3=C.TEXT}, 0.25)
        tw(entry.ico,  {ImageColor3=C.TEXT, Position=isCompact and UDim2.new(0.5,-entry.iconSize/2,0.5,-entry.iconSize/2) or UDim2.new(0,entry.iconX+4,0.5,-entry.iconSize/2)}, 0.3)
        if entry.hBtn then
            tw(entry.hBg,  {BackgroundTransparency=0}, 0.3)
            tw(entry.hLine,{BackgroundTransparency=0, Size=UDim2.new(0.5,0,0,3)}, 0.35)
            tw(entry.hIco, {ImageColor3=C.TEXT}, 0.25)
            tw(entry.hLbl, {TextColor3=C.TEXT}, 0.25)
        end
    end

    local function deselectTab(entry)
        local isCompact = (SIDE_W <= 100)
        local tf = entry.frame
        tw(tf, {Position=UDim2.new(0,-30,0,0), BackgroundTransparency=1}, 0.35)
        tw(entry.bg,   {BackgroundTransparency=1}, 0.25)
        tw(entry.line, {BackgroundTransparency=1, Size=UDim2.new(0,4,0,0)}, 0.2)
        tw(entry.lbl,  {TextColor3=C.DIM}, 0.2)
        tw(entry.ico,  {ImageColor3=C.DIM, Position=isCompact and UDim2.new(0.5,-entry.iconSize/2,0.5,-entry.iconSize/2) or UDim2.new(0,entry.iconX,0.5,-entry.iconSize/2)}, 0.25)
        task.delay(0.35, function() tf.Visible = false end)
        if entry.hBtn then
            tw(entry.hBg,  {BackgroundTransparency=1}, 0.25)
            tw(entry.hLine,{BackgroundTransparency=1, Size=UDim2.new(0.5,0,0,0)}, 0.2)
            tw(entry.hIco, {ImageColor3=C.DIM}, 0.2)
            tw(entry.hLbl, {TextColor3=C.DIM}, 0.2)
        end
    end

    local function doTabSwitch(entry)
        if activeTab and activeTab ~= entry then deselectTab(activeTab) activeTab.frame.Visible = false end
        activeTab = entry
        entry.frame.Visible = true
        selectTab(entry)
    end

    local function addTab(name, iconImage, buildFn)
        local tf = fr(contentArea, UDim2.new(1,0,1,0), nil, C.CONTENT, 1, 0)
        tf.Visible = false
        tf.ZIndex = 5
        if buildFn then buildFn(tf) end

        local navOrd = nextNavOrd()
        local topOrd = nextTopOrd()

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-8,0,38)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.LayoutOrder = navOrd
        btn.Parent = navScroll
        Instance.new("UICorner").Parent = btn

        local selBg   = fr(btn, UDim2.new(1,0,1,0), nil, C.SEL, 1, 12)
        local selLine  = fr(btn, UDim2.new(0,4,0.5,0), UDim2.new(1,-5,0.25,0), C.ACCENT, 1, 4)
        gradV(selLine, C.ACCENT, C.ACCENT2)

        local iconSize = 24
        local iconX    = 6
        if iconImage == ICON.aim or iconImage == ICON.players then iconSize = 28; iconX = 2
        elseif iconImage == ICON.world then iconSize = 20
        elseif iconImage == ICON.skin  then iconSize = 28; iconX = 4 end

        local icoL = Instance.new("ImageLabel")
        icoL.Size = UDim2.new(0,iconSize,0,iconSize)
        icoL.Position = UDim2.new(0,iconX,0.5,-iconSize/2)
        icoL.BackgroundTransparency = 1
        icoL.Image = normalizeIconId(iconImage) or ""
        icoL.ScaleType = Enum.ScaleType.Fit
        icoL.ImageColor3 = C.DIM
        icoL.Parent = btn

        local namL = lbl(btn, name, UDim2.new(1,-52,1,0), UDim2.new(0,44,0,0), 12, C.DIM)

        local hBtnW = math.max(#name*7+42, 70)
        local hBtn = Instance.new("TextButton")
        hBtn.Size = UDim2.new(0,hBtnW,1,-8)
        hBtn.BackgroundTransparency = 1
        hBtn.Text = ""
        hBtn.LayoutOrder = topOrd
        hBtn.Parent = topTabScroll
        Instance.new("UICorner").Parent = hBtn

        local hBg   = fr(hBtn, UDim2.new(1,0,1,0), nil, C.SEL, 1, 10)
        local hLine  = fr(hBtn, UDim2.new(0.5,0,0,0), UDim2.new(0.25,0,1,-3), C.ACCENT, 1, 2)
        gradV(hLine, C.ACCENT2, C.ACCENT)

        local hIco = Instance.new("ImageLabel")
        hIco.Size = UDim2.new(0,18,0,18)
        hIco.Position = UDim2.new(0,8,0.5,-9)
        hIco.BackgroundTransparency = 1
        hIco.Image = normalizeIconId(iconImage) or ""
        hIco.ScaleType = Enum.ScaleType.Fit
        hIco.ImageColor3 = C.DIM
        hIco.Parent = hBtn

        local hLbl = lbl(hBtn, name, UDim2.new(1,-34,1,0), UDim2.new(0,30,0,0), 11, C.DIM, Enum.Font.GothamBold)

        local entry = {
            btn=btn, frame=tf, bg=selBg, line=selLine, ico=icoL, lbl=namL,
            iconSize=iconSize, iconX=iconX,
            hBtn=hBtn, hBg=hBg, hLine=hLine, hIco=hIco, hLbl=hLbl
        }
        table.insert(allTabs, entry)
        tabContents[name] = tf
        entry._des = function() deselectTab(entry) end
        entry._sel = function() selectTab(entry) end

        btn.MouseEnter:Connect(function() if activeTab~=entry then tw(selBg,{BackgroundTransparency=0.5}) end end)
        btn.MouseLeave:Connect(function() if activeTab~=entry then tw(selBg,{BackgroundTransparency=1}) end end)
        btn.MouseButton1Click:Connect(function() doTabSwitch(entry) end)
        hBtn.MouseEnter:Connect(function() if activeTab~=entry then tw(hBg,{BackgroundTransparency=0.5}) end end)
        hBtn.MouseLeave:Connect(function() if activeTab~=entry then tw(hBg,{BackgroundTransparency=1}) end end)
        hBtn.MouseButton1Click:Connect(function() doTabSwitch(entry) end)

        return entry, tf
    end

    local applySettingsLayout = nil
    local compactEnabled = false

    local function setTabLayout(horizontal, animate)
        tabBarIsHorizontal = horizontal
        local t    = animate and 0.35 or 0
        local ease = Enum.EasingStyle.Quint
        if horizontal then
            tw(sidebar,        {Size=UDim2.new(0,0,1,-4)}, t, ease)
            tw(sidebarDivider, {BackgroundTransparency=1, Position=UDim2.new(0,0,0,4)}, t, ease)
            task.delay(t, function() sidebar.Visible=false; sidebarDivider.Visible=false end)
            topTabBar.Visible=true; topTabBar.BackgroundTransparency=1
            tw(topTabBar,    {BackgroundTransparency=0}, t, ease)
            topTabDivider.Visible=true; topTabDivider.BackgroundTransparency=1
            tw(topTabDivider,{BackgroundTransparency=0}, t, ease)
            tw(contentArea,  {Size=UDim2.new(1,-4,1,-TAB_BAR_H-36), Position=UDim2.new(0,2,0,TAB_BAR_H+6)}, t, ease)
            tw(statusBar,    {Size=UDim2.new(1,-4,0,28), Position=UDim2.new(0,2,1,-32)}, t, ease)
        else
            local targetW = compactEnabled and 52 or 160
            SIDE_W = targetW
            sidebar.Visible=true; sidebarDivider.Visible=true
            tw(sidebar,        {Size=UDim2.new(0,targetW,1,-4)}, t, ease)
            tw(sidebarDivider, {BackgroundTransparency=0, Position=UDim2.new(0,targetW,0,4)}, t, ease)
            tw(topTabBar,      {BackgroundTransparency=1}, t, ease)
            tw(topTabDivider,  {BackgroundTransparency=1}, t, ease)
            task.delay(t, function() topTabBar.Visible=false; topTabDivider.Visible=false end)
            tw(contentArea,    {Size=UDim2.new(1,-targetW-2,1,-32), Position=UDim2.new(0,targetW+2,0,4)}, t, ease)
            tw(statusBar,      {Size=UDim2.new(1,-targetW-2,0,28), Position=UDim2.new(0,targetW+2,1,-32)}, t, ease)
        end
        if applySettingsLayout then applySettingsLayout(horizontal, t, ease) end
    end

    -- ── Settings panel ─────────────────────────────────────────────────
    local settingsPanel = fr(sg, UDim2.new(0,WIN_W,0,WIN_H), UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2), C.BG, 0, 20)
    settingsPanel.ClipsDescendants = true
    settingsPanel.ZIndex = 100
    settingsPanel.Visible = false

    local settingsMainLayer = fr(settingsPanel, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), C.BG, 1, 0)
    settingsMainLayer.ZIndex = 2

    local settingsDrag = Instance.new("TextButton")
    settingsDrag.Size = UDim2.new(1,0,0,12)
    settingsDrag.Position = UDim2.new(0,0,0,0)
    settingsDrag.BackgroundTransparency = 1
    settingsDrag.Text = ""
    settingsDrag.ZIndex = 50
    settingsDrag.Parent = settingsMainLayer

    local settingsBodyShell = fr(settingsMainLayer, UDim2.new(1,0,1,-12), UDim2.new(0,0,0,12), C.BG, 1, 0)
    settingsBodyShell.ZIndex = 2

    local settingsLeft = fr(settingsBodyShell, UDim2.new(0,SIDE_W,1,-4), UDim2.new(0,0,0,4), C.SIDEBAR, 0, 14)
    settingsLeft.ZIndex = 2
    settingsLeft.ClipsDescendants = true

    local settingsDivider = fr(settingsBodyShell, UDim2.new(0,1,1,-4), UDim2.new(0,SIDE_W,0,4), C.DIV)

    -- ── Settings category list (LEFT sidebar) ──────────────────────────
    -- Now includes "Players" as 5th category
    local catItems = {"General","Appearance","Performance","Keybinds","Players"}
    local catKeys  = {ICON.general, ICON.appearance, ICON.performance, ICON.keyboard, ICON.players}

    local catScroll = Instance.new("ScrollingFrame")
    catScroll.Size = UDim2.new(1,0,1,0)
    catScroll.ZIndex = 2
    catScroll.BackgroundTransparency = 1
    catScroll.BorderSizePixel = 0
    catScroll.ScrollBarThickness = 0
    catScroll.CanvasSize = UDim2.new(0,0,0,0)
    catScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    catScroll.Parent = fr(settingsLeft, UDim2.new(1,0,1,0), nil, C.SIDEBAR, 1, 0)
    pad(catScroll, 8,10,12,8)

    local catList = Instance.new("UIListLayout")
    catList.SortOrder = Enum.SortOrder.LayoutOrder
    catList.Padding = UDim.new(0,4)
    catList.Parent = catScroll

    local catBtns          = {}
    local settingsTabContents = {}
    local activeSettingTab = 1

    for i, cat in ipairs(catItems) do
        local cb = Instance.new("TextButton")
        cb.Size = UDim2.new(1,-4,0,38)
        cb.LayoutOrder = i
        cb.BackgroundColor3 = C.SEL
        cb.BackgroundTransparency = 1
        cb.Text = ""
        cb.AutoButtonColor = false
        cb.Parent = catScroll
        Instance.new("UICorner").Parent = cb

        local selBg   = fr(cb, UDim2.new(1,0,1,0), nil, C.SEL, 1, 12)
        local selLine  = fr(cb, UDim2.new(0,4,0.5,0), UDim2.new(1,-5,0.25,0), C.ACCENT, 1, 4)
        gradV(selLine, C.ACCENT, C.ACCENT2)

        local ci = Instance.new("ImageLabel")
        ci.Size = UDim2.new(0,24,0,24)
        ci.Position = UDim2.new(0,10,0.5,-12)
        ci.BackgroundTransparency = 1
        ci.Image = normalizeIconId(catKeys[i]) or ""
        ci.ImageColor3 = C.DIM
        ci.Parent = cb

        local namL = lbl(cb, cat, UDim2.new(1,-44,1,0), UDim2.new(0,40,0,0), 12, C.DIM)
        catBtns[i] = {btn=cb, icon=ci, lbl=namL, bg=selBg, line=selLine}

        local function updateTabVisuals(idx, isActive)
            local b = catBtns[idx]
            if not b then return end
            local isCompact = (SIDE_W <= 100)
            if isActive then
                tw(b.bg,   {BackgroundTransparency=0},    0.25, Enum.EasingStyle.Quad)
                tw(b.line, {BackgroundTransparency=isCompact and 1 or 0, Size=UDim2.new(0,4,0.5,0)}, 0.25, Enum.EasingStyle.Quad)
                tw(b.lbl,  {TextColor3=C.TEXT},           0.2,  Enum.EasingStyle.Quad)
                tw(b.icon, {ImageColor3=C.TEXT, Position=isCompact and UDim2.new(0.5,-12,0.5,-12) or UDim2.new(0,14,0.5,-12)}, 0.25, Enum.EasingStyle.Quad)
            else
                tw(b.bg,   {BackgroundTransparency=1},    0.2,  Enum.EasingStyle.Quad)
                tw(b.line, {BackgroundTransparency=1, Size=UDim2.new(0,4,0,0)}, 0.15, Enum.EasingStyle.Quad)
                tw(b.lbl,  {TextColor3=C.DIM},            0.15, Enum.EasingStyle.Quad)
                tw(b.icon, {ImageColor3=C.DIM, Position=isCompact and UDim2.new(0.5,-12,0.5,-12) or UDim2.new(0,10,0.5,-12)}, 0.2, Enum.EasingStyle.Quad)
            end
        end

        cb.MouseEnter:Connect(function() if activeSettingTab~=i then tw(selBg,{BackgroundTransparency=0.5},0.15) end end)
        cb.MouseLeave:Connect(function() if activeSettingTab~=i then tw(selBg,{BackgroundTransparency=1},0.15) end end)

        cb.MouseButton1Click:Connect(function()
            if activeSettingTab == i then return end
            local oldIdx    = activeSettingTab
            local oldContent = settingsTabContents[oldIdx]
            local newContent = settingsTabContents[i]
            updateTabVisuals(oldIdx, false)
            updateTabVisuals(i, true)
            if oldContent then
                tw(oldContent, {Position=UDim2.new(0,-15,0,0)}, 0.12, Enum.EasingStyle.Quad)
                oldContent.Visible = false
            end
            newContent.Visible = true
            newContent.Position = UDim2.new(0,15,0,0)
            tw(newContent, {Position=UDim2.new(0,0,0,0)}, 0.15, Enum.EasingStyle.Quad)
            activeSettingTab = i
        end)
    end

    local sRight = fr(settingsBodyShell, UDim2.new(1,-SIDE_W-2,1,-32), UDim2.new(0,SIDE_W+2,0,4), C.CONTENT, 0, 16)
    sRight.ZIndex = 2

    local function setSidebarWidth(w, animate)
        SIDE_W = w
        if tabBarIsHorizontal then return end
        local cw  = UDim2.new(1,-SIDE_W-2,1,-32)
        local cp  = UDim2.new(0,SIDE_W+2,0,4)
        local sw  = UDim2.new(0,SIDE_W,1,-4)
        local atn = animate and 0.25 or 0
        if sidebar      then tw(sidebar,      {Size=sw}, atn) end
        if contentArea  then tw(contentArea,  {Size=cw, Position=cp}, atn) end
        if statusBar    then tw(statusBar,    {Size=UDim2.new(1,-SIDE_W-2,0,28), Position=UDim2.new(0,SIDE_W+2,1,-32)}, atn) end
        if settingsLeft then tw(settingsLeft, {Size=sw}, atn) end
        if sRight       then tw(sRight,       {Size=cw, Position=cp}, atn) end
        local isCompact = (w <= 100)
        local tatn = animate and 0.2 or 0
        for _, s in ipairs(sectionLabels or {}) do
            if isCompact then tw(s,{TextTransparency=1},tatn); task.delay(tatn, function() if s then s.Visible=false end end)
            else s.Visible=true; tw(s,{TextTransparency=0},tatn) end
        end
        for _, t in ipairs(allTabs or {}) do
            if t.lbl then
                if isCompact then tw(t.lbl,{TextTransparency=1},tatn); task.delay(tatn,function() if t.lbl then t.lbl.Visible=false end end)
                else t.lbl.Visible=true; tw(t.lbl,{TextTransparency=0},tatn) end
            end
            local isActive = (t.frame and t.frame.Visible)
            if t.line and isActive then tw(t.line,{BackgroundTransparency=isCompact and 1 or 0},tatn) end
            if t.ico then tw(t.ico,{Position=isCompact and UDim2.new(0.5,-t.iconSize/2,0.5,-t.iconSize/2) or UDim2.new(0,t.iconX+(isActive and 4 or 0),0.5,-t.iconSize/2)},tatn) end
        end
        for idx, bt in ipairs(catBtns or {}) do
            if bt.lbl then
                if isCompact then tw(bt.lbl,{TextTransparency=1},tatn); task.delay(tatn,function() if bt.lbl then bt.lbl.Visible=false end end)
                else bt.lbl.Visible=true; tw(bt.lbl,{TextTransparency=0},tatn) end
            end
            local isActive2 = (idx == activeSettingTab)
            if bt.line and isActive2 then tw(bt.line,{BackgroundTransparency=isCompact and 1 or 0},tatn) end
            if bt.icon then tw(bt.icon,{Position=isCompact and UDim2.new(0.5,-12,0.5,-12) or UDim2.new(0,10+(isActive2 and 4 or 0),0.5,-12)},tatn) end
        end
    end

    local titleRow = fr(sRight, UDim2.new(1,0,0,40), nil, C.HEADER, 0, 0)
    lbl(titleRow, "Settings", UDim2.new(1,-16,1,0), UDim2.new(0,14,0,0), 16, C.TEXT, Enum.Font.GothamBold)

    local SCAT_BAR_H = 36
    local settingsCatBar = fr(sRight, UDim2.new(1,0,0,SCAT_BAR_H), UDim2.new(0,0,0,40), C.SIDEBAR, 0, 0)
    settingsCatBar.Visible = false
    settingsCatBar.ClipsDescendants = true
    local scatBarScroll = Instance.new("ScrollingFrame")
    scatBarScroll.Size = UDim2.new(1,0,1,0)
    scatBarScroll.BackgroundTransparency = 1
    scatBarScroll.BorderSizePixel = 0
    scatBarScroll.ScrollBarThickness = 0
    scatBarScroll.CanvasSize = UDim2.new(0,0,0,0)
    scatBarScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    scatBarScroll.ScrollingDirection = Enum.ScrollingDirection.X
    scatBarScroll.Parent = settingsCatBar
    pad(scatBarScroll,6,6,4,4)
    local scatBarLayout = Instance.new("UIListLayout")
    scatBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scatBarLayout.FillDirection = Enum.FillDirection.Horizontal
    scatBarLayout.Padding = UDim.new(0,4)
    scatBarLayout.Parent = scatBarScroll

    local hCatBtns = {}
    for i, cat in ipairs(catItems) do
        local hcBtn = Instance.new("TextButton")
        hcBtn.Size = UDim2.new(0, math.max(#cat*7+36,70), 1,-8)
        hcBtn.BackgroundTransparency = 1
        hcBtn.Text = ""
        hcBtn.LayoutOrder = i
        hcBtn.Parent = scatBarScroll
        Instance.new("UICorner").Parent = hcBtn
        local hcBg   = fr(hcBtn, UDim2.new(1,0,1,0), nil, C.SEL, 1, 10)
        local hcLine  = fr(hcBtn, UDim2.new(0.5,0,0,0), UDim2.new(0.25,0,1,-3), C.ACCENT, 1, 2)
        gradV(hcLine, C.ACCENT2, C.ACCENT)
        local hcIco = Instance.new("ImageLabel")
        hcIco.Size = UDim2.new(0,16,0,16)
        hcIco.Position = UDim2.new(0,6,0.5,-8)
        hcIco.BackgroundTransparency = 1
        hcIco.Image = normalizeIconId(catKeys[i]) or ""
        hcIco.ScaleType = Enum.ScaleType.Fit
        hcIco.ImageColor3 = C.DIM
        hcIco.Parent = hcBtn
        local hcLbl = lbl(hcBtn, cat, UDim2.new(1,-28,1,0), UDim2.new(0,26,0,0), 11, C.DIM, Enum.Font.GothamBold)
        hCatBtns[i] = {btn=hcBtn, bg=hcBg, line=hcLine, ico=hcIco, lbl=hcLbl}
    end

    local function updateHCatVisuals()
        for j, hc in ipairs(hCatBtns) do
            if j == activeSettingTab then
                tw(hc.bg,   {BackgroundTransparency=0}, 0.25)
                tw(hc.line, {BackgroundTransparency=0, Size=UDim2.new(0.5,0,0,3)}, 0.25)
                tw(hc.ico,  {ImageColor3=C.TEXT}, 0.2)
                tw(hc.lbl,  {TextColor3=C.TEXT}, 0.2)
            else
                tw(hc.bg,   {BackgroundTransparency=1}, 0.2)
                tw(hc.line, {BackgroundTransparency=1, Size=UDim2.new(0.5,0,0,0)}, 0.15)
                tw(hc.ico,  {ImageColor3=C.DIM}, 0.15)
                tw(hc.lbl,  {TextColor3=C.DIM}, 0.15)
            end
        end
    end

    for i, hc in ipairs(hCatBtns) do
        hc.btn.MouseEnter:Connect(function() if activeSettingTab~=i then tw(hc.bg,{BackgroundTransparency=0.5},0.12) end end)
        hc.btn.MouseLeave:Connect(function() if activeSettingTab~=i then tw(hc.bg,{BackgroundTransparency=1},0.12) end end)
        hc.btn.MouseButton1Click:Connect(function()
            if activeSettingTab == i then return end
            local oldContent = settingsTabContents[activeSettingTab]
            local newContent = settingsTabContents[i]
            local oldIdx     = activeSettingTab
            activeSettingTab = i

            local function updV(idx, isActive)
                local b = catBtns[idx]
                if not b then return end
                local isCompact = (SIDE_W <= 100)
                if isActive then
                    tw(b.bg,   {BackgroundTransparency=0},   0.25)
                    tw(b.line, {BackgroundTransparency=isCompact and 1 or 0, Size=UDim2.new(0,4,0.5,0)}, 0.25)
                    tw(b.lbl,  {TextColor3=C.TEXT},          0.2)
                    tw(b.icon, {ImageColor3=C.TEXT},         0.2)
                else
                    tw(b.bg,   {BackgroundTransparency=1},   0.2)
                    tw(b.line, {BackgroundTransparency=1, Size=UDim2.new(0,4,0,0)}, 0.15)
                    tw(b.lbl,  {TextColor3=C.DIM},           0.15)
                    tw(b.icon, {ImageColor3=C.DIM},          0.15)
                end
            end
            updV(oldIdx, false); updV(i, true); updateHCatVisuals()
            if oldContent then tw(oldContent,{Position=UDim2.new(0,-15,0,0)},0.12); oldContent.Visible=false end
            newContent.Visible=true; newContent.Position=UDim2.new(0,15,0,0)
            tw(newContent,{Position=UDim2.new(0,0,0,0)},0.15)
        end)
    end

    -- ── Settings scroll frames (1‑5, one per category) ─────────────────
    local sHolder = fr(sRight, UDim2.new(1,0,1,-46), UDim2.new(0,0,0,40), C.CONTENT, 1, 0)

    for i = 1, 5 do
        local sScroll = Instance.new("ScrollingFrame")
        sScroll.Size = UDim2.new(1,0,1,0)
        sScroll.ZIndex = 2
        sScroll.BackgroundTransparency = 1
        sScroll.BorderSizePixel = 0
        sScroll.ScrollBarThickness = 0
        sScroll.CanvasSize = UDim2.new(0,0,0,0)
        sScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sScroll.Parent = sHolder
        sScroll.Visible = (i == 1)
        pad(sScroll, 10,18,10,10)
        local sLayout = Instance.new("UIListLayout")
        sLayout.SortOrder = Enum.SortOrder.LayoutOrder
        sLayout.Padding = UDim.new(0,6)
        sLayout.Parent = sScroll
        table.insert(settingsTabContents, sScroll)
        settingsTabs[catItems[i]] = sScroll
    end

    -- ══════════════════════════════════════════════════════════════════
    -- PLAYERS TAB  (category 5 in Settings – full two-panel layout)
    -- ══════════════════════════════════════════════════════════════════
    do
        -- Override the default scroll frame with a plain frame that fills the area
        local pContainer = settingsTabContents[5]
        -- Disable auto canvas size – we manage the layout ourselves
        pContainer.AutomaticCanvasSize = Enum.AutomaticSize.None
        pContainer.ScrollBarThickness = 0

        _G._MenuFriends = _G._MenuFriends or {}
        local friendList = _G._MenuFriends

        local function saveFriends()
            _G._MenuFriends = friendList
            pcall(function()
                if makefolder and not isfolder("MenuLibConfigs") then makefolder("MenuLibConfigs") end
                if writefile then
                    writefile("MenuLibConfigs/"..tostring(lp.UserId).."_friends.json",
                              HttpService:JSONEncode(friendList))
                end
            end)
        end

        pcall(function()
            if isfile and isfile("MenuLibConfigs/"..tostring(lp.UserId).."_friends.json") then
                local ok, data = pcall(function()
                    return HttpService:JSONDecode(readfile("MenuLibConfigs/"..tostring(lp.UserId).."_friends.json"))
                end)
                if ok and data then for k,v in pairs(data) do friendList[k]=v end end
            end
        end)

        local function isFriend(name)
            for n in pairs(friendList) do
                if n:lower() == name:lower() then return true end
            end
            return false
        end

        -- Two-panel container that fills the scroll frame
        local panelHolder = fr(pContainer, UDim2.new(1,-4,0,0), UDim2.new(0,2,0,2), C.CONTENT, 1, 0)
        panelHolder.AutomaticSize = Enum.AutomaticSize.Y
        -- Force it to fill the parent height by matching parent size directly
        panelHolder.Size = UDim2.new(1,-4, 1,-4)
        panelHolder.AutomaticSize = Enum.AutomaticSize.None

        local leftPanel  = fr(panelHolder, UDim2.new(0.5,-4,1,0), UDim2.new(0,0,0,0),       C.SEL, 0, 10)
        local rightPanel = fr(panelHolder, UDim2.new(0.5,-4,1,0), UDim2.new(0.5,4,0,0), C.SEL, 0, 10)

        -- ── Helper: search bar ───────────────────────────────────────
        local function makeSearchBar(parent, placeholder)
            local bar = Instance.new("TextBox")
            bar.Size = UDim2.new(1,-20,0,28)
            bar.Position = UDim2.new(0,10,0,36)
            bar.BackgroundColor3 = C.DARK
            bar.TextColor3 = C.TEXT
            bar.TextSize = 12
            bar.Font = Enum.Font.Gotham
            bar.PlaceholderText = placeholder
            bar.PlaceholderColor3 = C.DIM
            bar.ClearTextOnFocus = false
            bar.Parent = parent
            Instance.new("UICorner", bar).CornerRadius = UDim.new(0,6)
            local st = Instance.new("UIStroke", bar)
            st.Color = C.DIV; st.Thickness = 1
            bar.Focused:Connect(function()  tw(st,{Color=C.ACCENT, Thickness=1.5},0.15) end)
            bar.FocusLost:Connect(function() tw(st,{Color=C.DIV,   Thickness=1},  0.15) end)
            -- search icon
            local ico = Instance.new("ImageLabel", bar)
            ico.Size = UDim2.new(0,14,0,14)
            ico.Position = UDim2.new(1,-20,0.5,-7)
            ico.BackgroundTransparency = 1
            ico.Image = "rbxassetid://3926305904"
            ico.ImageColor3 = C.DIM
            return bar
        end

        -- ── Left: Players list ──────────────────────────────────────
        lbl(leftPanel, "Players", UDim2.new(1,-16,0,24), UDim2.new(0,10,0,6), 14, C.TEXT, Enum.Font.GothamBold)
        local leftSearch = makeSearchBar(leftPanel, "Search players...")

        local playerScroller = Instance.new("ScrollingFrame")
        playerScroller.Size = UDim2.new(1,-8,1,-72)
        playerScroller.Position = UDim2.new(0,4,0,70)
        playerScroller.BackgroundTransparency = 1
        playerScroller.BorderSizePixel = 0
        playerScroller.ScrollBarThickness = 3
        playerScroller.ScrollBarImageColor3 = C.ACCENT
        playerScroller.CanvasSize = UDim2.new(0,0,0,0)
        playerScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
        playerScroller.Parent = leftPanel
        pad(playerScroller,4,4,4,4)
        local pLayout = Instance.new("UIListLayout")
        pLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pLayout.Padding = UDim.new(0,3)
        pLayout.Parent = playerScroller

        -- ── Right: Friends list ─────────────────────────────────────
        lbl(rightPanel, "Friends", UDim2.new(1,-16,0,24), UDim2.new(0,10,0,6), 14, C.TEXT, Enum.Font.GothamBold)
        local rightSearch = makeSearchBar(rightPanel, "Search friends...")

        local friendScroller = Instance.new("ScrollingFrame")
        friendScroller.Size = UDim2.new(1,-8,1,-72)
        friendScroller.Position = UDim2.new(0,4,0,70)
        friendScroller.BackgroundTransparency = 1
        friendScroller.BorderSizePixel = 0
        friendScroller.ScrollBarThickness = 3
        friendScroller.ScrollBarImageColor3 = C.ACCENT
        friendScroller.CanvasSize = UDim2.new(0,0,0,0)
        friendScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
        friendScroller.Parent = rightPanel
        pad(friendScroller,4,4,4,4)
        local fLayout = Instance.new("UIListLayout")
        fLayout.SortOrder = Enum.SortOrder.LayoutOrder
        fLayout.Padding = UDim.new(0,3)
        fLayout.Parent = friendScroller

        -- ── Forward-declare so they can reference each other ─────────
        local renderPlayerList, renderFriendList

        -- ── Player row builder ───────────────────────────────────────
        local function buildPlayerRow(parent, playerName, displayName, userId, rightSide)
            local row = fr(parent, UDim2.new(1,0,0,36), nil, C.HEADER, 0.6, 7)
            row.LayoutOrder = #parent:GetChildren()

            -- Avatar thumbnail
            local avatarBg = fr(row, UDim2.new(0,28,0,28), UDim2.new(0,5,0.5,-14), Color3.fromRGB(30,12,55), 0, 14)
            local thumbImg = Instance.new("ImageLabel", avatarBg)
            thumbImg.Size = UDim2.new(1,0,1,0)
            thumbImg.BackgroundTransparency = 1
            thumbImg.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            Instance.new("UICorner", thumbImg).CornerRadius = UDim.new(1,0)
            task.spawn(function()
                local ok, url = pcall(function()
                    return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
                if ok and url then thumbImg.Image = url end
            end)

            -- Name labels
            local nL = lbl(row, playerName, UDim2.new(0,100,0,15), UDim2.new(0,40,0,4), 11, C.TEXT, Enum.Font.GothamBold)
            nL.TextTruncate = Enum.TextTruncate.AtEnd
            local dL = lbl(row, "@"..displayName, UDim2.new(0,100,0,13), UDim2.new(0,40,0,19), 9, C.DIM)
            dL.TextTruncate = Enum.TextTruncate.AtEnd

            if rightSide then
                -- Remove button for friends list
                local removeBtn = Instance.new("TextButton", row)
                removeBtn.Size = UDim2.new(0,26,0,26)
                removeBtn.Position = UDim2.new(1,-32,0.5,-13)
                removeBtn.BackgroundColor3 = C.RED
                removeBtn.Text = "✕"
                removeBtn.TextColor3 = C.TEXT
                removeBtn.TextSize = 11
                removeBtn.Font = Enum.Font.GothamBold
                removeBtn.AutoButtonColor = false
                Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0,5)
                removeBtn.MouseButton1Click:Connect(function()
                    friendList[playerName] = nil
                    saveFriends()
                    tw(row, {Size=UDim2.new(1,0,0,0)}, 0.15)
                    task.delay(0.15, function() row:Destroy() end)
                    renderPlayerList(leftSearch.Text)
                end)
            else
                -- Add/Friend toggle button for player list
                local isFren = isFriend(playerName)
                local addBtn = Instance.new("TextButton", row)
                addBtn.Size = UDim2.new(0,50,0,24)
                addBtn.Position = UDim2.new(1,-56,0.5,-12)
                addBtn.BackgroundColor3 = isFren and Color3.fromRGB(40,160,75) or C.ACCENT
                addBtn.Text = isFren and "✓" or "+"
                addBtn.TextColor3 = C.TEXT
                addBtn.TextSize = isFren and 13 or 16
                addBtn.Font = Enum.Font.GothamBold
                addBtn.AutoButtonColor = false
                Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0,5)
                if not isFren then
                    local grad = Instance.new("UIGradient", addBtn)
                    grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,C.ACCENT),ColorSequenceKeypoint.new(1,C.ACCENT2)})
                    grad.Rotation = 90
                end
                local statusL = lbl(addBtn, isFren and "Friend" or "Add", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), 9, C.TEXT, Enum.Font.Gotham)
                statusL.TextXAlignment = Enum.TextXAlignment.Center
                statusL.TextYAlignment = Enum.TextYAlignment.Bottom
                addBtn.MouseButton1Click:Connect(function()
                    if isFriend(playerName) then
                        friendList[playerName] = nil
                        saveFriends()
                        tw(addBtn, {BackgroundColor3=C.ACCENT}, 0.2)
                        addBtn.Text = "+"
                        statusL.Text = "Add"
                    else
                        friendList[playerName] = userId
                        saveFriends()
                        tw(addBtn, {BackgroundColor3=Color3.fromRGB(40,160,75)}, 0.2)
                        addBtn.Text = "✓"
                        statusL.Text = "Friend"
                    end
                    renderFriendList(rightSearch.Text)
                end)
            end
            return row
        end

        -- ── Render functions ─────────────────────────────────────────
        renderPlayerList = function(query)
            for _, child in ipairs(playerScroller:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            local q = (query or ""):lower()
            for _, p in ipairs(Players:GetPlayers()) do
                local n = p.Name; local d = p.DisplayName
                if q == "" or n:lower():find(q,1,true) or d:lower():find(q,1,true) then
                    buildPlayerRow(playerScroller, n, d, p.UserId, false)
                end
            end
        end

        renderFriendList = function(query)
            for _, child in ipairs(friendScroller:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            local q = (query or ""):lower()
            local any = false
            for name, userId in pairs(friendList) do
                if q == "" or name:lower():find(q,1,true) then
                    any = true
                    buildPlayerRow(friendScroller, name, name, userId, true)
                end
            end
            if not any then
                local emptyL = lbl(friendScroller, "No friends added yet.", UDim2.new(1,0,0,30), nil, 11, C.DIM)
                emptyL.TextXAlignment = Enum.TextXAlignment.Center
            end
        end

        leftSearch:GetPropertyChangedSignal("Text"):Connect(function()  renderPlayerList(leftSearch.Text) end)
        rightSearch:GetPropertyChangedSignal("Text"):Connect(function() renderFriendList(rightSearch.Text) end)

        table.insert(conns, Players.PlayerAdded:Connect(function()
            renderPlayerList(leftSearch.Text); renderFriendList(rightSearch.Text)
        end))
        table.insert(conns, Players.PlayerRemoving:Connect(function()
            renderPlayerList(leftSearch.Text); renderFriendList(rightSearch.Text)
        end))

        renderPlayerList(""); renderFriendList("")
    end  -- end Players tab do-block

    -- ── applySettingsLayout ─────────────────────────────────────────────
    applySettingsLayout = function(horizontal, t, ease)
        if horizontal then
            tw(settingsLeft,    {Size=UDim2.new(0,0,1,-4)}, t, ease)
            tw(settingsDivider, {BackgroundTransparency=1, Position=UDim2.new(0,0,0,4)}, t, ease)
            task.delay(t, function() settingsLeft.Visible=false; settingsDivider.Visible=false end)
            tw(sRight, {Size=UDim2.new(1,-4,1,-32), Position=UDim2.new(0,2,0,4)}, t, ease)
            settingsCatBar.Visible=true; settingsCatBar.BackgroundTransparency=1
            tw(settingsCatBar, {BackgroundTransparency=0}, t, ease)
            tw(sHolder, {Size=UDim2.new(1,0,1,-46-SCAT_BAR_H), Position=UDim2.new(0,0,0,40+SCAT_BAR_H)}, t, ease)
            updateHCatVisuals()
        else
            local targetW = compactEnabled and 52 or 160
            settingsLeft.Visible=true; settingsDivider.Visible=true
            tw(settingsLeft,    {Size=UDim2.new(0,targetW,1,-4)}, t, ease)
            tw(settingsDivider, {BackgroundTransparency=0, Position=UDim2.new(0,targetW,0,4)}, t, ease)
            tw(settingsCatBar,  {BackgroundTransparency=1}, t, ease)
            task.delay(t, function() settingsCatBar.Visible=false end)
            tw(sRight,  {Size=UDim2.new(1,-targetW-2,1,-32), Position=UDim2.new(0,targetW+2,0,4)}, t, ease)
            tw(sHolder, {Size=UDim2.new(1,0,1,-46), Position=UDim2.new(0,0,0,40)}, t, ease)
        end
    end

    -- ── addSettingOption ────────────────────────────────────────────────
    local function addSettingOption(tabName, labelText, hasToggle, callback, initValue)
        local scrollFrame = settingsTabs[tabName]
        if not scrollFrame then return nil end
        local existingChildren = #scrollFrame:GetChildren()
        if existingChildren > 2 then
            local divider = fr(scrollFrame, UDim2.new(1,-10,0,1), nil, C.DIV, 0.5, 0)
            divider.LayoutOrder = existingChildren
            divider.Name = "Divider"
        end
        local row = fr(scrollFrame, UDim2.new(1,-10,0,40), nil, C.HEADER, 0, 10)
        row.LayoutOrder = #scrollFrame:GetChildren()
        local stripe = fr(row, UDim2.new(0,3,1,-8), UDim2.new(0,0,0,4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        lbl(row, labelText, UDim2.new(1,-70,1,0), UDim2.new(0,14,0,0), 12, C.TEXT)
        if hasToggle then
            local toggle = mkToggle(row, -56, initValue or false, callback)
            if not _G._MenuToggles then _G._MenuToggles={} end
            _G._MenuToggles[labelText] = toggle
            return toggle
        end
        return row
    end

    addSettingOption("General",     "Show FPS counter",   true, function(on) fpsLbl.Visible  = on end, true)
    addSettingOption("General",     "Show ping counter",  true, function(on) pingLbl.Visible = on end, true)
    addSettingOption("General",     "Show clock",         true, function(on) timeLbl.Visible = on end, true)
    addSettingOption("General",     "Show watermark",     true, function(on) hudBar.Visible  = on end, true)
    addSettingOption("Appearance",  "Compact sidebar",    true, function(on)
        compactEnabled = on
        if not tabBarIsHorizontal then setSidebarWidth(on and 52 or 160, true) end
    end, false)

    -- Tab layout dropdown (Appearance)
    do
        local scrollFrame = settingsTabs["Appearance"]
        if scrollFrame then
            local row = fr(scrollFrame, UDim2.new(1,-10,0,40), nil, C.HEADER, 0, 10)
            row.LayoutOrder = #scrollFrame:GetChildren()
            local stripe = fr(row, UDim2.new(0,3,1,-8), UDim2.new(0,0,0,4), C.ACCENT, 0, 0)
            gradV(stripe, C.ACCENT, C.ACCENT2)
            lbl(row, "Tab layout", UDim2.new(1,-170,1,0), UDim2.new(0,14,0,0), 12, C.TEXT)

            local layoutOptions = {"Vertical","Horizontal"}
            local selectedIdx = 1
            local ddOpen = false
            local DROP_W = 150

            local layoutDropBtn = Instance.new("TextButton", row)
            layoutDropBtn.Size = UDim2.new(0,DROP_W,0,30)
            layoutDropBtn.Position = UDim2.new(1,-(DROP_W+10),0.5,-15)
            layoutDropBtn.BackgroundColor3 = C.DARK
            layoutDropBtn.Text = "Vertical"
            layoutDropBtn.TextColor3 = C.TEXT
            layoutDropBtn.TextSize = 11
            layoutDropBtn.Font = Enum.Font.GothamBold
            Instance.new("UICorner",layoutDropBtn).CornerRadius = UDim.new(0,6)
            local ddStroke = Instance.new("UIStroke",layoutDropBtn)
            ddStroke.Color = C.DIV; ddStroke.Thickness = 1; ddStroke.Transparency = 0.5
            local chevron = Instance.new("ImageLabel",layoutDropBtn)
            chevron.Size = UDim2.new(0,10,0,10); chevron.Position = UDim2.new(1,-16,0.5,-5)
            chevron.BackgroundTransparency = 1; chevron.Image = "rbxassetid://6031091004"
            chevron.ImageColor3 = C.ACCENT
            local ddPad = Instance.new("UIPadding",layoutDropBtn)
            ddPad.PaddingRight = UDim.new(0,18); ddPad.PaddingLeft = UDim.new(0,4)
            layoutDropBtn.MouseEnter:Connect(function() tw(layoutDropBtn,{BackgroundColor3=C.BTN},0.12); tw(ddStroke,{Color=C.ACCENT,Transparency=0.3},0.12) end)
            layoutDropBtn.MouseLeave:Connect(function() tw(layoutDropBtn,{BackgroundColor3=C.DARK},0.12); tw(ddStroke,{Color=C.DIV,Transparency=0.5},0.12) end)

            local dropFrame, dropShadow, closeConn = nil,nil,nil
            local function closeDrop()
                ddOpen=false
                if closeConn then closeConn:Disconnect(); closeConn=nil end
                tw(chevron,{Rotation=0},0.2)
                if dropFrame then
                    tw(dropFrame,{Size=UDim2.new(0,DROP_W,0,0),BackgroundTransparency=1},0.2)
                    local cf,cs = dropFrame, dropShadow
                    dropFrame=nil; dropShadow=nil
                    task.delay(0.25, function() if cf then cf:Destroy() end; if cs then cs:Destroy() end end)
                end
            end
            local function openDrop()
                if ddOpen then closeDrop() return end
                ddOpen=true; tw(chevron,{Rotation=180},0.2)
                local bp = layoutDropBtn.AbsolutePosition; local bs = layoutDropBtn.AbsoluteSize
                local dropY = bp.Y+bs.Y+4; local dropX = bp.X
                local targetH = #layoutOptions*30+8
                dropShadow = fr(sg,UDim2.new(0,DROP_W,0,0),UDim2.new(0,dropX+2,0,dropY+2),Color3.new(0,0,0),0.7,8)
                dropShadow.ZIndex=998
                dropFrame = fr(sg,UDim2.new(0,DROP_W,0,0),UDim2.new(0,dropX,0,dropY),C.DARK,0,8)
                dropFrame.ZIndex=1000; dropFrame.ClipsDescendants=true
                local dStroke=Instance.new("UIStroke",dropFrame); dStroke.Color=C.ACCENT; dStroke.Thickness=1.5; dStroke.Transparency=0.4
                local dScroll=Instance.new("ScrollingFrame",dropFrame)
                dScroll.Size=UDim2.new(1,-4,1,-4); dScroll.Position=UDim2.new(0,2,0,2)
                dScroll.BackgroundTransparency=1; dScroll.BorderSizePixel=0; dScroll.ScrollBarThickness=0
                dScroll.CanvasSize=UDim2.new(0,0,0,#layoutOptions*30)
                Instance.new("UIListLayout",dScroll).SortOrder=Enum.SortOrder.LayoutOrder
                for i2,opt in ipairs(layoutOptions) do
                    local ob=Instance.new("TextButton",dScroll)
                    ob.Size=UDim2.new(1,-4,0,28); ob.LayoutOrder=i2
                    ob.BackgroundColor3=(i2==selectedIdx) and Color3.fromRGB(40,20,70) or C.DARK
                    ob.Text=opt; ob.TextColor3=(i2==selectedIdx) and C.TEXT or C.DIM
                    ob.TextSize=11; ob.Font=Enum.Font.GothamBold; ob.TextXAlignment=Enum.TextXAlignment.Center
                    ob.ZIndex=1001; Instance.new("UICorner",ob).CornerRadius=UDim.new(0,4)
                    ob.MouseEnter:Connect(function() if i2~=selectedIdx then tw(ob,{BackgroundColor3=C.BTN,TextColor3=C.TEXT},0.12) end end)
                    ob.MouseLeave:Connect(function() if i2~=selectedIdx then tw(ob,{BackgroundColor3=C.DARK,TextColor3=C.DIM},0.12) end end)
                    ob.MouseButton1Click:Connect(function()
                        tw(ob,{BackgroundColor3=C.ACCENT},0.08)
                        task.delay(0.14,function() selectedIdx=i2; layoutDropBtn.Text=opt; setTabLayout(opt=="Horizontal",true); closeDrop() end)
                    end)
                end
                tw(dropShadow,{Size=UDim2.new(0,DROP_W,0,targetH)},0.25,Enum.EasingStyle.Quint)
                tw(dropFrame, {Size=UDim2.new(0,DROP_W,0,targetH)},0.25,Enum.EasingStyle.Quint)
                task.delay(0.1,function()
                    if not ddOpen then return end
                    closeConn=UserInputService.InputBegan:Connect(function(input)
                        if not ddOpen then if closeConn then closeConn:Disconnect() end return end
                        if input.UserInputType==Enum.UserInputType.MouseButton1 then
                            local pos=Vector2.new(input.Position.X,input.Position.Y)
                            local df,bb=dropFrame,layoutDropBtn
                            if not df or not bb then return end
                            local inDrop=pos.X>=df.AbsolutePosition.X and pos.X<=df.AbsolutePosition.X+df.AbsoluteSize.X and pos.Y>=df.AbsolutePosition.Y and pos.Y<=df.AbsolutePosition.Y+df.AbsoluteSize.Y
                            local inBtn =pos.X>=bb.AbsolutePosition.X and pos.X<=bb.AbsolutePosition.X+bb.AbsoluteSize.X and pos.Y>=bb.AbsolutePosition.Y and pos.Y<=bb.AbsolutePosition.Y+bb.AbsoluteSize.Y
                            if not inDrop and not inBtn then closeDrop() end
                        end
                    end)
                end)
            end
            layoutDropBtn.MouseButton1Click:Connect(openDrop)
        end
    end

    addSettingOption("Appearance",  "Blur background",    true, function(on)
        _G._BlurEnabled = on
        if on and isOpen then
            if not blurPart then blurPart=Instance.new("BlurEffect"); blurPart.Size=0; blurPart.Parent=Lighting end
            tw(blurPart,{Size=12},0.25)
        elseif blurPart then
            tw(blurPart,{Size=0},0.25)
            local cur=blurPart; task.delay(0.25,function() if cur and not _G._BlurEnabled then cur:Destroy(); if blurPart==cur then blurPart=nil end end end)
        end
    end, false)

    addSettingOption("Performance", "Lighting preset dim", true, function(on)
        _G._LightingDimEnabled = on
        if on then
            if not _G._OriginalBrightness then _G._OriginalBrightness=Lighting.Brightness; _G._OriginalClockTime=Lighting.ClockTime end
            Lighting.Brightness=0.3; Lighting.ClockTime=0
        elseif _G._OriginalBrightness then
            Lighting.Brightness=_G._OriginalBrightness; Lighting.ClockTime=_G._OriginalClockTime
        end
    end, false)
    addSettingOption("Performance", "Low quality mode", true, function(on) end, false)

    -- ══════════════════════════════════════════════════════════════════
    -- KEYBIND OPTIONS  – now supports ALL keys + all mouse buttons
    -- ══════════════════════════════════════════════════════════════════
    local function addKeybindOption(tabName, label, key, onChange)
        local scrollFrame = settingsTabs[tabName]
        if not scrollFrame then return end
        local row = fr(scrollFrame, UDim2.new(1,-10,0,40), nil, C.HEADER, 0, 10)
        row.LayoutOrder = #scrollFrame:GetChildren()
        local stripe = fr(row, UDim2.new(0,3,1,-8), UDim2.new(0,0,0,4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        lbl(row, label, UDim2.new(1,-100,1,0), UDim2.new(0,14,0,0), 12, C.TEXT)

        -- Auto-size the key button based on text length
        local initialText = keyDisplayName(key)
        local btnW = math.max(70, #initialText * 8 + 20)

        local keyBtn = Instance.new("TextButton", row)
        keyBtn.Size = UDim2.new(0,btnW,0,26)
        keyBtn.Position = UDim2.new(1,-(btnW+8),0.5,-13)
        keyBtn.BackgroundColor3 = C.SEL
        keyBtn.Text = initialText
        keyBtn.TextColor3 = C.TEXT
        keyBtn.TextSize = 11
        keyBtn.TextTruncate = Enum.TextTruncate.AtEnd
        keyBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner").Parent = keyBtn
        local kStroke = Instance.new("UIStroke", keyBtn)
        kStroke.Color = C.DIV; kStroke.Thickness = 1

        keyBtn.MouseEnter:Connect(function() tw(kStroke,{Color=C.ACCENT,Thickness=1.5},0.12) end)
        keyBtn.MouseLeave:Connect(function() tw(kStroke,{Color=C.DIV,Thickness=1},0.12) end)

        keyBtn.MouseButton1Click:Connect(function()
            keyBtn.Text = "..."
            keyBtn.BackgroundColor3 = C.ACCENT
            kStroke.Color = C.ACCENT2
            _G._SettingKeybind = true

            local conn
            -- Listen on InputBegan for keyboard/mouse button presses
            conn = UserInputService.InputBegan:Connect(function(inp, gpe)
                if gpe then return end

                local selectedKey = nil
                local displayText = ""

                -- Mouse buttons (1, 2, 3)
                local uitype = inp.UserInputType
                if uitype == Enum.UserInputType.MouseButton1 then
                    selectedKey = Enum.UserInputType.MouseButton1; displayText = "Mouse1"
                elseif uitype == Enum.UserInputType.MouseButton2 then
                    selectedKey = Enum.UserInputType.MouseButton2; displayText = "Mouse2"
                elseif uitype == Enum.UserInputType.MouseButton3 then
                    selectedKey = Enum.UserInputType.MouseButton3; displayText = "Mouse3"
                elseif inp.KeyCode and inp.KeyCode ~= Enum.KeyCode.Unknown then
                    selectedKey = inp.KeyCode; displayText = inp.KeyCode.Name
                end

                if selectedKey then
                    conn:Disconnect()
                    -- Also listen briefly for scroll wheel (InputChanged)
                    local w = math.max(70, #displayText*8+20)
                    keyBtn.Text = displayText
                    keyBtn.Size = UDim2.new(0,w,0,26)
                    keyBtn.Position = UDim2.new(1,-(w+8),0.5,-13)
                    keyBtn.BackgroundColor3 = C.SEL
                    kStroke.Color = C.DIV
                    onChange(selectedKey)
                    task.defer(function() _G._SettingKeybind = false end)
                end
            end)

            -- Also handle scroll wheel via InputChanged
            local scrollConn
            scrollConn = UserInputService.InputChanged:Connect(function(inp)
                if not _G._SettingKeybind then scrollConn:Disconnect(); return end
                local uitype = inp.UserInputType
                local selectedKey2, displayText2
                if uitype == Enum.UserInputType.MouseWheelForward then
                    selectedKey2=Enum.UserInputType.MouseWheelForward; displayText2="WheelUp"
                elseif uitype == Enum.UserInputType.MouseWheelBackward then
                    selectedKey2=Enum.UserInputType.MouseWheelBackward; displayText2="WheelDown"
                end
                if selectedKey2 then
                    scrollConn:Disconnect(); conn:Disconnect()
                    local w = math.max(70, #displayText2*8+20)
                    keyBtn.Text = displayText2
                    keyBtn.Size = UDim2.new(0,w,0,26)
                    keyBtn.Position = UDim2.new(1,-(w+8),0.5,-13)
                    keyBtn.BackgroundColor3 = C.SEL
                    kStroke.Color = C.DIV
                    onChange(selectedKey2)
                    task.defer(function() _G._SettingKeybind = false end)
                end
            end)

            -- Timeout after 6 seconds
            task.delay(6, function()
                if conn.Connected then conn:Disconnect() end
                if scrollConn.Connected then scrollConn:Disconnect() end
                if _G._SettingKeybind then _G._SettingKeybind=false end
                if keyBtn.Text == "..." then
                    keyBtn.Text = initialText
                    keyBtn.BackgroundColor3 = C.SEL
                    kStroke.Color = C.DIV
                end
            end)
        end)
    end

    addKeybindOption("Keybinds", "Toggle menu key",  _G._MenuToggleKey, function(k) _G._MenuToggleKey = k end)
    addKeybindOption("Keybinds", "Unload script key", _G._UnloadKey,    function(k) _G._UnloadKey = k    end)

    -- ── Menu open/close/toggle ─────────────────────────────────────────
    local inSettings = false

    local function openSettings()
        if inSettings then return end
        inSettings = true; _G._MenuOpen = true
        tw(homeBtn,       {Rotation=homeBtn.Rotation+360}, 0.5)
        tw(homeBtnIcon1,  {ImageTransparency=1}, 0.25)
        tw(homeBtnIcon2,  {ImageTransparency=0}, 0.25)
        tw(win, {Size=UDim2.new(0,0,0,0), Position=UDim2.new(0.5,0,0.5,0)}, 0.2)
        task.delay(0.1, function() win.Visible=false end)
        settingsPanel.Size=UDim2.new(0,0,0,0); settingsPanel.Position=UDim2.new(0.5,0,0.5,0)
        settingsPanel.Visible=true
        tw(settingsPanel,{Size=UDim2.new(0,WIN_W,0,WIN_H), Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)}, 0.25)
        activeSettingTab=1
        for i2, content in ipairs(settingsTabContents) do content.Visible=(i2==1) end
        if catBtns[1] then
            catBtns[1].bg.BackgroundTransparency=0; catBtns[1].line.BackgroundTransparency=0
            catBtns[1].line.Size=UDim2.new(0,4,0.5,0); catBtns[1].icon.ImageColor3=C.TEXT
            catBtns[1].icon.Position=UDim2.new(0,14,0.5,-12); catBtns[1].lbl.TextColor3=C.TEXT
        end
        for i2=2,#catBtns do
            catBtns[i2].bg.BackgroundTransparency=1; catBtns[i2].line.BackgroundTransparency=1
            catBtns[i2].line.Size=UDim2.new(0,4,0,0); catBtns[i2].icon.ImageColor3=C.DIM
            catBtns[i2].icon.Position=UDim2.new(0,10,0.5,-12); catBtns[i2].lbl.TextColor3=C.DIM
        end
    end

    local function closeSettings()
        if not inSettings then return end
        inSettings=false; _G._MenuOpen=true
        tw(homeBtn,      {Rotation=homeBtn.Rotation-360}, 0.5)
        tw(homeBtnIcon1, {ImageTransparency=0}, 0.25)
        tw(homeBtnIcon2, {ImageTransparency=1}, 0.25)
        tw(settingsPanel,{Size=UDim2.new(0,0,0,0), Position=UDim2.new(0.5,0,0.5,0)}, 0.2)
        task.delay(0.1, function() settingsPanel.Visible=false end)
        win.Size=UDim2.new(0,0,0,0); win.Position=UDim2.new(0.5,0,0.5,0); win.Visible=true
        tw(win,{Size=UDim2.new(0,WIN_W,0,WIN_H), Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)}, 0.25)
    end

    closeMenu = function()
        if not win.Visible and not settingsPanel.Visible then return end
        isOpen=false; _G._MenuOpen=false
        for _, closer in ipairs(activeDropdownClosers) do pcall(closer) end
        if inSettings then
            tw(settingsPanel,{Size=UDim2.new(0,0,0,0), Position=UDim2.new(0.5,0,0.5,0)}, 0.15)
            task.delay(0.15, function() settingsPanel.Visible=false; unlockInput() end)
        else
            tw(win,{Size=UDim2.new(0,0,0,0), Position=UDim2.new(0.5,0,0.5,0)}, 0.15)
            task.delay(0.15, function() win.Visible=false; unlockInput() end)
        end
    end

    openMenu = function()
        if not win or not settingsPanel then return end
        if win.Visible or settingsPanel.Visible then return end
        isOpen=true; _G._MenuOpen=true; pcall(lockInput)
        if hudBar then hudBar.Visible=true end
        if inSettings then
            settingsPanel.Visible=true; settingsPanel.Size=UDim2.new(0,0,0,0); settingsPanel.Position=UDim2.new(0.5,0,0.5,0)
            tw(settingsPanel,{Size=UDim2.new(0,WIN_W,0,WIN_H), Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)}, 0.22)
        else
            win.Visible=true; win.Size=UDim2.new(0,0,0,0); win.Position=UDim2.new(0.5,0,0.5,0)
            tw(win,{Size=UDim2.new(0,WIN_W,0,WIN_H), Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)}, 0.22)
        end
    end

    toggleMenu = function() if isOpen then closeMenu() else openMenu() end end

    fireClick.MouseButton1Click:Connect(toggleMenu)
    homeBtn.MouseButton1Click:Connect(function() if inSettings then closeSettings() else openSettings() end end)
    homeBtn.MouseEnter:Connect(function() tw(homeBtn,{BackgroundTransparency=0.05},0.12) end)
    homeBtn.MouseLeave:Connect(function() tw(homeBtn,{BackgroundTransparency=0.2}, 0.12) end)

    -- ── Dragging ────────────────────────────────────────────────────────
    local dragging = false
    local dragOrig = Vector2.zero
    local winOrig, settingsOrig = UDim2.new(), UDim2.new()
    local dragTarget = nil

    dragHandle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging=true; dragTarget="main"
            dragOrig=Vector2.new(inp.Position.X,inp.Position.Y)
            win.Size=UDim2.new(0,win.AbsoluteSize.X,0,win.AbsoluteSize.Y)
            win.Position=UDim2.new(0,win.AbsolutePosition.X,0,win.AbsolutePosition.Y)
            winOrig=win.Position
        end
    end)
    dragHandle.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false; dragTarget=nil end
    end)
    settingsDrag.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragTarget="settings"
            dragOrig=Vector2.new(inp.Position.X,inp.Position.Y)
            settingsPanel.Size=UDim2.new(0,settingsPanel.AbsoluteSize.X,0,settingsPanel.AbsoluteSize.Y)
            settingsPanel.Position=UDim2.new(0,settingsPanel.AbsolutePosition.X,0,settingsPanel.AbsolutePosition.Y)
            settingsOrig=settingsPanel.Position
        end
    end)
    settingsDrag.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false; dragTarget=nil end
    end)

    -- ── HUD layout ───────────────────────────────────────────────────────
    local function updateHudLayout(animate)
        local baseX = 48
        local nameWidth = math.max(nameLbl.AbsoluteSize.X, nameLbl.TextBounds.X)
        local spacing = 16
        local currentX = baseX
        currentX = currentX + math.max(70, nameWidth+8) + spacing

        local function applyLayout(obj, isVisible, targetX, yOffset)
            if not obj then return targetX end
            if isVisible then
                obj.Visible=true
                local w = obj.AbsoluteSize.X
                if obj:IsA("TextLabel") then
                    w = math.max(w, obj.TextBounds.X)
                    if w==0 or obj.Text=="..." then
                        if obj==fpsLbl or obj==pingLbl then w=48 elseif obj==timeLbl then w=68 end
                    end
                end
                if w==0 then if obj==badge then w=32 elseif obj==homeBtn then w=30 end end
                if animate then tw(obj,{Position=UDim2.new(0,targetX,0.5,yOffset or -10)},0.2)
                else obj.Position=UDim2.new(0,targetX,0.5,yOffset or -10) end
                return targetX+(w or 0)+spacing
            else
                obj.Visible=false; return targetX
            end
        end
        local function applyDiv(divObj, isVisible, targetX)
            if isVisible then
                divObj.Visible=true
                if animate then tw(divObj,{Position=UDim2.new(0,targetX-(spacing/2)-1,0.5,-9)},0.2)
                else divObj.Position=UDim2.new(0,targetX-(spacing/2)-1,0.5,-9) end
            else divObj.Visible=false end
        end
        if fpsLbl.Visible  then applyDiv(div1,true,currentX);  currentX=applyLayout(fpsLbl, true,currentX,-10) else applyDiv(div1,false,currentX) end
        if pingLbl.Visible then applyDiv(div2,true,currentX);  currentX=applyLayout(pingLbl,true,currentX,-10) else applyDiv(div2,false,currentX) end
        if timeLbl.Visible then applyDiv(div3,true,currentX);  currentX=applyLayout(timeLbl,true,currentX,-10) else applyDiv(div3,false,currentX) end
        applyDiv(div4,true,currentX); currentX=applyLayout(homeBtn,true,currentX,-15)
        applyDiv(div5,true,currentX); currentX=applyLayout(badge,true,currentX,-14)
        local targetWidth=currentX+8
        if animate then tw(hudBar,{Size=UDim2.new(0,targetWidth,0,44), Position=UDim2.new(0.5,-targetWidth/2,0,10)},0.25)
        else hudBar.Size=UDim2.new(0,targetWidth,0,44); hudBar.Position=UDim2.new(0.5,-targetWidth/2,0,10) end
    end
    task.defer(function() updateHudLayout(false) end)
    table.insert(conns, nameLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, fpsLbl:GetPropertyChangedSignal("Text"):Connect(function()     updateHudLayout(true) end))
    table.insert(conns, fpsLbl:GetPropertyChangedSignal("Visible"):Connect(function()  updateHudLayout(true) end))
    table.insert(conns, fpsLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, pingLbl:GetPropertyChangedSignal("Visible"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, timeLbl:GetPropertyChangedSignal("Visible"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, pingLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, timeLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))

    -- ── RenderStepped ────────────────────────────────────────────────────
    local fpsT, fpsN = 0, 0
    table.insert(conns, RunService.RenderStepped:Connect(function(dt)
        if unloaded then return end
        fpsT=fpsT+dt; fpsN=fpsN+1
        if fpsT >= 0.5 then
            pcall(function() fpsLbl.Text=tostring(math.round(fpsN/fpsT)).." FPS" end)
            fpsN=0; fpsT=0
        end
        pcall(function() pingLbl.Text=tostring(math.round(lp:GetNetworkPing()*1000)).." ms" end)
        pcall(function() timeLbl.Text=os.date("%I:%M %p") end)
        if _G._LightingDimEnabled then Lighting.Brightness=0.3; Lighting.ClockTime=0 end
        if dragging and dragTarget then
            local mp = UserInputService:GetMouseLocation()
            if dragTarget=="settings" and settingsPanel then
                pcall(function() settingsPanel.Position=UDim2.new(0,settingsOrig.X.Offset+(mp.X-dragOrig.X),0,settingsOrig.Y.Offset+(mp.Y-dragOrig.Y)) end)
            elseif dragTarget=="main" and win then
                pcall(function() win.Position=UDim2.new(0,winOrig.X.Offset+(mp.X-dragOrig.X),0,winOrig.Y.Offset+(mp.Y-dragOrig.Y)) end)
            end
        end
    end))

    -- ══════════════════════════════════════════════════════════════════
    -- PUBLIC API
    -- ══════════════════════════════════════════════════════════════════
    local API = {}
    API.AddSection = addSection

    local tabPanels = {}

    local function getContainer(tabName, side)
        local tf = tabContents[tabName]
        if not tf then return nil, false end
        local panels = tabPanels[tabName]
        if panels then
            local panel = (side=="right") and panels.rightPanel or panels.leftPanel
            return panel, true
        end
        local scroll = tf:FindFirstChildWhichIsA("ScrollingFrame") or tf
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChildWhichIsA("UIListLayout") then
                return child, false
            end
        end
        local card = fr(scroll, UDim2.new(1,-4,0,0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout", card)
        v.SortOrder = Enum.SortOrder.LayoutOrder; v.Padding = UDim.new(0,8)
        pad(card,16,16,16,16)
        return card, false
    end

    API.AddTab = function(name, icon, buildFn)
        local tabEntry, contentFrame = addTab(name, icon, buildFn)
        return {
            Content = contentFrame,
            Select  = function()
                if activeTab then activeTab._des(); activeTab.frame.Visible=false end
                activeTab=tabEntry; tabEntry.frame.Visible=true; tabEntry._sel()
            end
        }
    end

    API.AddToggle = function(tabName, label, callback, default, side)
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end
        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1,0,0,40), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0,3,1,-8), UDim2.new(0,0,0,4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        lbl(row, label, UDim2.new(1,-70,1,0), UDim2.new(0,14,0,0), 12, C.TEXT)
        local toggle = mkToggle(row,-56, default or false, callback)
        if not _G._MenuToggles then _G._MenuToggles={} end
        _G._MenuToggles[label] = toggle
        return toggle
    end

    API.AddSlider = function(tabName, label, min, max, callback, default, side)
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end
        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1,0,0,50), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0,3,1,-8), UDim2.new(0,0,0,4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        lbl(row, label, UDim2.new(1,-20,0,20), UDim2.new(0,14,0,4), 12, C.TEXT)
        local valueLbl = lbl(row, tostring(default or min), UDim2.new(0,40,0,20), UDim2.new(1,-50,0,4), 12, C.ACCENT, Enum.Font.GothamBold)
        valueLbl.TextXAlignment = Enum.TextXAlignment.Right
        local track = fr(row, UDim2.new(1,-28,0,6), UDim2.new(0,14,0,28), Color3.fromRGB(40,20,70), 0, 3)
        local fill  = fr(track, UDim2.new(0,0,1,0), nil, C.ACCENT, 0, 3)
        gradV(fill, C.ACCENT, C.ACCENT2)
        local knob = fr(track, UDim2.new(0,12,0,12), nil, C.TEXT, 0, 6)
        local value = default or min
        local range = max-min
        local function updateVisuals(anim)
            local pct = math.clamp((value-min)/range,0,1)
            if anim then tw(fill,{Size=UDim2.new(pct,0,1,0)},0.15); tw(knob,{Position=UDim2.new(pct,-6,0,-3)},0.15)
            else fill.Size=UDim2.new(pct,0,1,0); knob.Position=UDim2.new(pct,-6,0,-3) end
            valueLbl.Text=tostring(math.round(value))
        end
        updateVisuals(false)
        local draggingSlider=false
        track.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then
                draggingSlider=true
                local pct=math.clamp((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                value=min+(pct*range); updateVisuals(true); if callback then callback(value) end
            end
        end)
        table.insert(conns, UserInputService.InputChanged:Connect(function(inp)
            if draggingSlider and inp.UserInputType==Enum.UserInputType.MouseMovement then
                local pct=math.clamp((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                value=min+(pct*range); updateVisuals(true); if callback then callback(value) end
            end
        end))
        table.insert(conns, UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then draggingSlider=false end
        end))
        local sliderObj={Get=function() return value end, Set=function(v) value=math.clamp(v,min,max); updateVisuals(true); if callback then callback(value) end end}
        if not _G._MenuSliders then _G._MenuSliders={} end
        _G._MenuSliders[label]=sliderObj
        return sliderObj
    end

    API.AddColorPicker = function(tabName, label, callback, defaultColor, side)
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end
        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1,0,0,40), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        gradV(fr(row,UDim2.new(0,3,1,-8),UDim2.new(0,0,0,4),C.ACCENT,0,0), C.ACCENT, C.ACCENT2)
        lbl(row, label, UDim2.new(1,-70,1,0), UDim2.new(0,14,0,0), 12, C.TEXT)
        local color = defaultColor or Color3.fromRGB(255,255,255)
        local alpha = 1
        local preview = fr(row, UDim2.new(0,36,0,24), UDim2.new(1,-50,0.5,-12), color, 0, 6)
        local btn = Instance.new("TextButton",row)
        btn.Size=UDim2.new(0,50,0,26); btn.Position=UDim2.new(1,-56,0.5,-13)
        btn.BackgroundColor3=C.BTN; btn.Text="Pick"; btn.TextColor3=C.TEXT
        btn.TextSize=11; btn.Font=Enum.Font.GothamBold
        Instance.new("UICorner").Parent=btn
        btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=C.BTNHOV},0.12) end)
        btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=C.BTN},0.12) end)
        local pickerFrame=nil
        local function closePicker()
            if pickerFrame then
                tw(pickerFrame,{Size=UDim2.new(0,200,0,0)},0.15)
                local pf=pickerFrame; pickerFrame=nil; task.delay(0.2,function() if pf then pf:Destroy() end end)
            end
        end
        table.insert(activeDropdownClosers, closePicker)
        btn.MouseButton1Click:Connect(function()
            if pickerFrame then closePicker() return end
            local PW,PH=260,300
            pickerFrame=fr(sg,UDim2.new(0,PW,0,0),UDim2.new(0.5,-PW/2,0.5,-PH/2),C.HEADER,0,12)
            pickerFrame.ZIndex=1000; pickerFrame.ClipsDescendants=true
            local pStroke=Instance.new("UIStroke",pickerFrame); pStroke.Color=C.ACCENT; pStroke.Thickness=1.5; pStroke.Transparency=0.4
            tw(pickerFrame,{Size=UDim2.new(0,PW,0,PH)},0.2,Enum.EasingStyle.Quint)
            local h,s,v=color:ToHSV()
            local function updateColor() color=Color3.fromHSV(h,s,v); preview.BackgroundColor3=color; if callback then callback(color,alpha) end end
            local hueBar=fr(pickerFrame,UDim2.new(0,20,0,150),UDim2.new(0,PW-34,0,10),C.DARK,0,4); hueBar.ZIndex=1001
            for i2=0,5 do
                local seg=fr(hueBar,UDim2.new(1,0,0,25),UDim2.new(0,0,0,i2*25),Color3.fromHSV(i2/6,1,1),0,0); seg.ZIndex=1001
                local g2=Instance.new("UIGradient"); g2.Color=ColorSequence.new(Color3.fromHSV(i2/6,1,1),Color3.fromHSV(math.min((i2+1)/6,1),1,1)); g2.Rotation=90; g2.Parent=seg
            end
            local hueKnob=fr(hueBar,UDim2.new(1,4,0,4),UDim2.new(0,-2,0,h*150-2),C.TEXT,0,2); hueKnob.ZIndex=1003
            local hueBtn=Instance.new("TextButton",hueBar); hueBtn.Size=UDim2.new(1,0,1,0); hueBtn.BackgroundTransparency=1; hueBtn.Text=""; hueBtn.ZIndex=1002
            local canvasSize=PW-50
            local svCanvas=fr(pickerFrame,UDim2.new(0,canvasSize,0,150),UDim2.new(0,10,0,10),Color3.fromHSV(h,1,1),0,4); svCanvas.ZIndex=1001
            local wGrad=Instance.new("UIGradient",svCanvas); wGrad.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromHSV(h,1,1))
            local darkOverlay=fr(svCanvas,UDim2.new(1,0,1,0),nil,Color3.new(0,0,0),0,4); darkOverlay.ZIndex=1001
            local dGrad=Instance.new("UIGradient",darkOverlay); dGrad.Color=ColorSequence.new(Color3.new(0,0,0),Color3.new(0,0,0)); dGrad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}); dGrad.Rotation=90
            local svKnob=fr(svCanvas,UDim2.new(0,8,0,8),UDim2.new(0,s*canvasSize-4,0,(1-v)*150-4),C.TEXT,0,4); svKnob.ZIndex=1003
            local svKS=Instance.new("UIStroke",svKnob); svKS.Color=Color3.new(0,0,0); svKS.Thickness=1
            local svBtn=Instance.new("TextButton",svCanvas); svBtn.Size=UDim2.new(1,0,1,0); svBtn.BackgroundTransparency=1; svBtn.Text=""; svBtn.ZIndex=1002
            lbl(pickerFrame,"A",UDim2.new(0,14,0,16),UDim2.new(0,10,0,168),11,C.DIM,Enum.Font.GothamBold).ZIndex=1001
            local alphaTrack=fr(pickerFrame,UDim2.new(0,PW-50,0,12),UDim2.new(0,28,0,170),C.DARK,0,3); alphaTrack.ZIndex=1001
            local alphaFill=fr(alphaTrack,UDim2.new(alpha,0,1,0),nil,C.ACCENT,0,3); alphaFill.ZIndex=1001; gradV(alphaFill,C.ACCENT,C.ACCENT2)
            local alphaKnob=fr(alphaTrack,UDim2.new(0,8,0,16),UDim2.new(alpha,-4,0.5,-8),C.TEXT,0,4); alphaKnob.ZIndex=1003
            local alphaBtn=Instance.new("TextButton",alphaTrack); alphaBtn.Size=UDim2.new(1,0,1,0); alphaBtn.BackgroundTransparency=1; alphaBtn.Text=""; alphaBtn.ZIndex=1002
            local labels2={"R","G","B","A"}; local boxes={}
            for i2,l2 in ipairs(labels2) do
                local ix=10+(i2-1)*62
                lbl(pickerFrame,l2,UDim2.new(0,12,0,20),UDim2.new(0,ix,0,195),11,C.DIM,Enum.Font.GothamBold).ZIndex=1001
                local box=Instance.new("TextBox",pickerFrame); box.Size=UDim2.new(0,42,0,22); box.Position=UDim2.new(0,ix+14,0,195)
                box.BackgroundColor3=C.DARK; box.TextColor3=C.TEXT; box.TextSize=11; box.Font=Enum.Font.GothamBold; box.ClearTextOnFocus=true; box.ZIndex=1002
                Instance.new("UICorner",box).CornerRadius=UDim.new(0,4); boxes[i2]=box
            end
            local function refreshInputs() boxes[1].Text=tostring(math.round(color.R*255)); boxes[2].Text=tostring(math.round(color.G*255)); boxes[3].Text=tostring(math.round(color.B*255)); boxes[4].Text=tostring(math.round(alpha*255)) end
            local function refreshVisuals()
                svCanvas.BackgroundColor3=Color3.fromHSV(h,1,1); wGrad.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromHSV(h,1,1))
                svKnob.Position=UDim2.new(0,s*canvasSize-4,0,(1-v)*150-4); hueKnob.Position=UDim2.new(0,-2,0,h*150-2)
                alphaFill.Size=UDim2.new(alpha,0,1,0); alphaKnob.Position=UDim2.new(alpha,-4,0.5,-8); refreshInputs()
            end
            refreshInputs()
            local presets={Color3.fromRGB(255,0,0),Color3.fromRGB(0,255,0),Color3.fromRGB(0,0,255),Color3.fromRGB(255,255,0),Color3.fromRGB(255,0,255),Color3.fromRGB(0,255,255),Color3.fromRGB(255,105,180),Color3.fromRGB(255,165,0),Color3.fromRGB(128,0,128),Color3.fromRGB(255,255,255),Color3.fromRGB(0,0,0),Color3.fromRGB(120,40,240)}
            for i2,pc in ipairs(presets) do
                local sw=Instance.new("TextButton",pickerFrame); sw.Size=UDim2.new(0,16,0,16); sw.Position=UDim2.new(0,10+(i2-1)*20,0,228); sw.BackgroundColor3=pc; sw.Text=""; sw.ZIndex=1001; Instance.new("UICorner",sw).CornerRadius=UDim.new(0,3)
                sw.MouseButton1Click:Connect(function() color=pc; h,s,v=color:ToHSV(); updateColor(); refreshVisuals() end)
            end
            local okBtn=Instance.new("TextButton",pickerFrame); okBtn.Size=UDim2.new(1,-20,0,28); okBtn.Position=UDim2.new(0,10,0,258); okBtn.BackgroundColor3=C.ACCENT; okBtn.Text="Done"; okBtn.TextColor3=C.TEXT; okBtn.TextSize=12; okBtn.Font=Enum.Font.GothamBold; okBtn.ZIndex=1001
            Instance.new("UICorner",okBtn).CornerRadius=UDim.new(0,6)
            local okGrad=Instance.new("UIGradient",okBtn); okGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.ACCENT),ColorSequenceKeypoint.new(1,C.ACCENT2)}); okGrad.Rotation=90
            okBtn.MouseButton1Click:Connect(closePicker)
            local svD=false; svBtn.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then svD=true end end)
            table.insert(conns,UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then svD=false end end))
            table.insert(conns,UserInputService.InputChanged:Connect(function(inp) if svD and inp.UserInputType==Enum.UserInputType.MouseMovement then s=math.clamp((inp.Position.X-svCanvas.AbsolutePosition.X)/canvasSize,0,1); v=1-math.clamp((inp.Position.Y-svCanvas.AbsolutePosition.Y)/150,0,1); updateColor(); refreshVisuals() end end))
            svBtn.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then s=math.clamp((inp.Position.X-svCanvas.AbsolutePosition.X)/canvasSize,0,1); v=1-math.clamp((inp.Position.Y-svCanvas.AbsolutePosition.Y)/150,0,1); updateColor(); refreshVisuals() end end)
            local hD=false; hueBtn.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then hD=true; h=math.clamp((inp.Position.Y-hueBar.AbsolutePosition.Y)/150,0,1); updateColor(); refreshVisuals() end end)
            table.insert(conns,UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then hD=false end end))
            table.insert(conns,UserInputService.InputChanged:Connect(function(inp) if hD and inp.UserInputType==Enum.UserInputType.MouseMovement then h=math.clamp((inp.Position.Y-hueBar.AbsolutePosition.Y)/150,0,1); updateColor(); refreshVisuals() end end))
            local aD=false; alphaBtn.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then aD=true; alpha=math.clamp((inp.Position.X-alphaTrack.AbsolutePosition.X)/alphaTrack.AbsoluteSize.X,0,1); updateColor(); refreshVisuals() end end)
            table.insert(conns,UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then aD=false end end))
            table.insert(conns,UserInputService.InputChanged:Connect(function(inp) if aD and inp.UserInputType==Enum.UserInputType.MouseMovement then alpha=math.clamp((inp.Position.X-alphaTrack.AbsolutePosition.X)/alphaTrack.AbsoluteSize.X,0,1); updateColor(); refreshVisuals() end end))
            for i2,box in ipairs(boxes) do
                box.FocusLost:Connect(function()
                    local val=tonumber(box.Text); if not val then refreshInputs(); return end
                    val=math.clamp(math.round(val),0,255)
                    if i2==1 then color=Color3.fromRGB(val,math.round(color.G*255),math.round(color.B*255))
                    elseif i2==2 then color=Color3.fromRGB(math.round(color.R*255),val,math.round(color.B*255))
                    elseif i2==3 then color=Color3.fromRGB(math.round(color.R*255),math.round(color.G*255),val)
                    elseif i2==4 then alpha=val/255 end
                    h,s,v=color:ToHSV(); updateColor(); refreshVisuals()
                end)
            end
        end)
        return {Get=function() return color,alpha end, Set=function(c,a) color=c; if a then alpha=a end; preview.BackgroundColor3=c; if callback then callback(c,alpha) end end}
    end

    -- ══════════════════════════════════════════════════════════════════
    -- DROPDOWN  – auto-sizes to longest option, rolls down, centered text
    -- ══════════════════════════════════════════════════════════════════
    API.AddDropdown = function(tabName, label, options, callback, defaultIndex, side)
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end

        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1,0,0,40), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        gradV(fr(row,UDim2.new(0,3,1,-8),UDim2.new(0,0,0,4),C.ACCENT,0,0), C.ACCENT, C.ACCENT2)
        lbl(row, label, UDim2.new(1,-205,1,0), UDim2.new(0,14,0,0), 12, C.TEXT)

        local selectedIndex = defaultIndex or 1
        local ddIsOpen = false

        -- Auto-size DROP_W based on the longest option name
        local longestText = label
        for _, opt in ipairs(options) do
            if #opt > #longestText then longestText = opt end
        end
        -- 8px per char + 40px padding for chevron etc., clamped between 120 and 260
        local DROP_W = math.clamp(#longestText*8+40, 120, 260)

        local dropdownBtn = Instance.new("TextButton", row)
        dropdownBtn.Size = UDim2.new(0,DROP_W,0,28)
        dropdownBtn.Position = UDim2.new(1,-(DROP_W+8),0.5,-14)
        dropdownBtn.BackgroundColor3 = C.DARK
        dropdownBtn.Text = options[selectedIndex] or "Select"
        dropdownBtn.TextColor3 = C.TEXT
        dropdownBtn.TextSize = 11
        dropdownBtn.Font = Enum.Font.GothamBold
        dropdownBtn.TextXAlignment = Enum.TextXAlignment.Center
        dropdownBtn.TextTruncate = Enum.TextTruncate.AtEnd
        Instance.new("UICorner",dropdownBtn).CornerRadius = UDim.new(0,6)
        local btnStroke = Instance.new("UIStroke",dropdownBtn)
        btnStroke.Color=C.DIV; btnStroke.Thickness=1; btnStroke.Transparency=0.5
        -- Right-side padding so text doesn't overlap chevron
        local btnPad=Instance.new("UIPadding",dropdownBtn)
        btnPad.PaddingRight=UDim.new(0,20); btnPad.PaddingLeft=UDim.new(0,6)
        local chevron=Instance.new("ImageLabel",dropdownBtn)
        chevron.Size=UDim2.new(0,10,0,10); chevron.Position=UDim2.new(1,-16,0.5,-5)
        chevron.BackgroundTransparency=1; chevron.Image="rbxassetid://6031091004"; chevron.ImageColor3=C.ACCENT

        dropdownBtn.MouseEnter:Connect(function() tw(dropdownBtn,{BackgroundColor3=C.BTN},0.15); tw(btnStroke,{Color=C.ACCENT,Transparency=0.3},0.15) end)
        dropdownBtn.MouseLeave:Connect(function() tw(dropdownBtn,{BackgroundColor3=C.DARK},0.15); tw(btnStroke,{Color=C.DIV,Transparency=0.5},0.15) end)

        local dropdownFrame, shadow, closeConn = nil, nil, nil

        local function closeDropdown()
            ddIsOpen=false
            if closeConn then closeConn:Disconnect(); closeConn=nil end
            tw(chevron,{Rotation=0},0.2,Enum.EasingStyle.Quint)
            if shadow then tw(shadow,{Size=UDim2.new(0,DROP_W,0,0),BackgroundTransparency=1},0.22,Enum.EasingStyle.Quint) end
            if dropdownFrame then
                tw(dropdownFrame,{Size=UDim2.new(0,DROP_W,0,0),BackgroundTransparency=1},0.22,Enum.EasingStyle.Quint)
                local cf,cs=dropdownFrame,shadow
                dropdownFrame=nil; shadow=nil
                task.delay(0.25, function() if cf then cf:Destroy() end; if cs then cs:Destroy() end end)
            end
        end

        local function openDropdown()
            if ddIsOpen then closeDropdown() return end
            ddIsOpen=true
            tw(chevron,{Rotation=180},0.2)
            local btnAbsPos=dropdownBtn.AbsolutePosition; local btnAbsSize=dropdownBtn.AbsoluteSize
            -- Always open BELOW the button
            local dropY=btnAbsPos.Y+btnAbsSize.Y+4; local dropX=btnAbsPos.X
            local targetHeight=math.min(#options*30+12, 200)

            shadow=fr(sg,UDim2.new(0,DROP_W,0,0),UDim2.new(0,dropX+2,0,dropY+2),Color3.new(0,0,0),0.7,8)
            shadow.ZIndex=998
            dropdownFrame=fr(sg,UDim2.new(0,DROP_W,0,0),UDim2.new(0,dropX,0,dropY),C.DARK,0,8)
            dropdownFrame.ZIndex=1000; dropdownFrame.ClipsDescendants=true
            local dStroke=Instance.new("UIStroke",dropdownFrame); dStroke.Color=C.ACCENT; dStroke.Thickness=1.5; dStroke.Transparency=0.4

            local scroll=Instance.new("ScrollingFrame",dropdownFrame)
            scroll.Size=UDim2.new(1,-4,1,-8); scroll.Position=UDim2.new(0,2,0,4)
            scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
            scroll.ScrollBarThickness=2; scroll.ScrollBarImageColor3=C.ACCENT
            scroll.CanvasSize=UDim2.new(0,0,0,#options*30)
            local list=Instance.new("UIListLayout",scroll); list.SortOrder=Enum.SortOrder.LayoutOrder; list.Padding=UDim.new(0,2)

            for i2, opt in ipairs(options) do
                local optBtn=Instance.new("TextButton",scroll)
                optBtn.Size=UDim2.new(1,-4,0,28); optBtn.LayoutOrder=i2
                optBtn.BackgroundColor3=(i2==selectedIndex) and Color3.fromRGB(40,20,70) or C.DARK
                optBtn.Text=opt; optBtn.TextColor3=(i2==selectedIndex) and C.TEXT or C.DIM
                optBtn.TextSize=11; optBtn.Font=Enum.Font.GothamBold
                optBtn.TextXAlignment=Enum.TextXAlignment.Center
                optBtn.TextTruncate=Enum.TextTruncate.AtEnd
                optBtn.ZIndex=1001; Instance.new("UICorner",optBtn).CornerRadius=UDim.new(0,4)
                if i2==selectedIndex then local ss=Instance.new("UIStroke",optBtn); ss.Color=C.ACCENT; ss.Thickness=1; ss.Transparency=0.5 end
                optBtn.MouseEnter:Connect(function() if i2~=selectedIndex then tw(optBtn,{BackgroundColor3=C.BTN,TextColor3=C.TEXT},0.12) end end)
                optBtn.MouseLeave:Connect(function() if i2~=selectedIndex then tw(optBtn,{BackgroundColor3=C.DARK,TextColor3=C.DIM},0.12) end end)
                optBtn.InputEnded:Connect(function(input)
                    if input.UserInputType==Enum.UserInputType.MouseButton1 then
                        tw(optBtn,{BackgroundColor3=C.ACCENT},0.08)
                        task.delay(0.14,function() selectedIndex=i2; dropdownBtn.Text=opt; if callback then callback(opt,i2) end; closeDropdown() end)
                    end
                end)
            end

            tw(shadow,       {Size=UDim2.new(0,DROP_W,0,targetHeight)},0.25,Enum.EasingStyle.Quint)
            tw(dropdownFrame,{Size=UDim2.new(0,DROP_W,0,targetHeight)},0.25,Enum.EasingStyle.Quint)

            task.delay(0.1,function()
                if not ddIsOpen then return end
                closeConn=UserInputService.InputBegan:Connect(function(input)
                    if not ddIsOpen then if closeConn then closeConn:Disconnect() end return end
                    if input.UserInputType==Enum.UserInputType.MouseButton1 then
                        local pos=Vector2.new(input.Position.X,input.Position.Y)
                        local df,bb=dropdownFrame,dropdownBtn
                        if not df or not bb then return end
                        local inDrop=pos.X>=df.AbsolutePosition.X and pos.X<=df.AbsolutePosition.X+df.AbsoluteSize.X and pos.Y>=df.AbsolutePosition.Y and pos.Y<=df.AbsolutePosition.Y+df.AbsoluteSize.Y
                        local inBtn =pos.X>=bb.AbsolutePosition.X and pos.X<=bb.AbsolutePosition.X+bb.AbsoluteSize.X and pos.Y>=bb.AbsolutePosition.Y and pos.Y<=bb.AbsolutePosition.Y+bb.AbsoluteSize.Y
                        if not inDrop and not inBtn then closeDropdown() end
                    end
                end)
            end)
        end

        dropdownBtn.MouseButton1Click:Connect(openDropdown)
        table.insert(activeDropdownClosers, closeDropdown)

        local ddObj={
            Get=function() return options[selectedIndex], selectedIndex end,
            Set=function(idx) selectedIndex=idx; dropdownBtn.Text=options[idx]; if callback then callback(options[idx],idx) end end,
            GetOptions=function() return options end,
            SetOptions=function(newOpts) options=newOpts; selectedIndex=1; dropdownBtn.Text=options[1] or "Select" end
        }
        if not _G._MenuDropdowns then _G._MenuDropdowns={} end
        _G._MenuDropdowns[label]=ddObj
        return ddObj
    end

    API.AddSetting = function(tabName, label, toggleCallback, default)
        return addSettingOption(tabName, label, true, toggleCallback, default)
    end
    API.AddKeybindOption = function(tabName, label, key, onChange)
        return addKeybindOption(tabName, label, key, onChange)
    end

    API.AddButton = function(tabName, label, callback)
        local container, isPanel = getContainer(tabName)
        if not container then return nil end
        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1,0,0,44), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        gradV(fr(row,UDim2.new(0,3,1,-8),UDim2.new(0,0,0,4),C.ACCENT,0,0),C.ACCENT,C.ACCENT2)
        lbl(row, label, UDim2.new(1,-130,1,0), UDim2.new(0,14,0,0), 12, C.TEXT)
        local btn=Instance.new("TextButton",row); btn.Size=UDim2.new(0,110,0,28); btn.Position=UDim2.new(1,-118,0.5,-14)
        btn.BackgroundColor3=C.ACCENT; btn.Text="Execute"; btn.TextColor3=C.TEXT; btn.TextSize=11; btn.Font=Enum.Font.GothamBold; btn.AutoButtonColor=false
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
        local bg=Instance.new("UIGradient",btn); bg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.ACCENT),ColorSequenceKeypoint.new(1,C.ACCENT2)}); bg.Rotation=90
        btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=Color3.fromRGB(140,50,255)},0.12) end)
        btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=C.ACCENT},0.12) end)
        btn.MouseButton1Click:Connect(function() if callback then pcall(callback) end end)
        return {Click=function() pcall(callback) end}
    end

    API.GetScreenGui = function() return sg  end
    API.GetWindow    = function() return win end
    API.GetHUD       = function() return hudBar end
    API.Show = function() openMenu() end
    API.Hide = function() closeMenu() end

    -- ── Default tabs ───────────────────────────────────────────────────
    local function makeScrollCard(f, title)
        local scroll=Instance.new("ScrollingFrame",f); scroll.Size=UDim2.new(1,0,1,0); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=0; scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
        pad(scroll,8,10,8,8)
        local card=fr(scroll,UDim2.new(1,-4,0,0),nil,C.HEADER,0,16); card.AutomaticSize=Enum.AutomaticSize.Y
        local v=Instance.new("UIListLayout",card); v.SortOrder=Enum.SortOrder.LayoutOrder; v.Padding=UDim.new(0,8)
        pad(card,16,16,16,16)
        if title then lbl(card,title,UDim2.new(1,0,0,0),nil,18,C.TEXT,Enum.Font.GothamBold) end
        return scroll, card
    end

    addSection("AIM")
    local firstTab = API.AddTab("Aimbot", ICON.aim, function(f)
        local _, card = makeScrollCard(f, "Aimbot")
        local mainRow=fr(card,UDim2.new(1,0,0,0),nil,C.HEADER,1,0); mainRow.LayoutOrder=1; mainRow.AutomaticSize=Enum.AutomaticSize.Y
        local rl=Instance.new("UIListLayout",mainRow); rl.SortOrder=Enum.SortOrder.LayoutOrder; rl.Padding=UDim.new(0,8); rl.FillDirection=Enum.FillDirection.Horizontal
        local leftPanel=fr(mainRow,UDim2.new(0.5,-4,0,0),UDim2.new(0,0,0,0),C.SEL,0,10); leftPanel.AutomaticSize=Enum.AutomaticSize.Y; leftPanel.LayoutOrder=1
        local lv=Instance.new("UIListLayout",leftPanel); lv.SortOrder=Enum.SortOrder.LayoutOrder; lv.Padding=UDim.new(0,8); pad(leftPanel,12,12,12,12)
        lbl(leftPanel,"Main",UDim2.new(1,0,0,0),nil,14,C.TEXT,Enum.Font.GothamBold)
        local rightPanel=fr(mainRow,UDim2.new(0.5,-4,0,0),UDim2.new(0.5,4,0,0),C.SEL,0,10); rightPanel.AutomaticSize=Enum.AutomaticSize.Y; rightPanel.LayoutOrder=2
        local rv=Instance.new("UIListLayout",rightPanel); rv.SortOrder=Enum.SortOrder.LayoutOrder; rv.Padding=UDim.new(0,8); pad(rightPanel,12,12,12,12)
        lbl(rightPanel,"Silent Aim",UDim2.new(1,0,0,0),nil,14,C.TEXT,Enum.Font.GothamBold)
        tabPanels["Aimbot"]={leftPanel=leftPanel,rightPanel=rightPanel}
    end)
    RunService.Heartbeat:Wait()

    addSection("VISUALS")
    API.AddTab("Visuals", ICON.players, function(f)
        local _, card = makeScrollCard(f, "Visuals")
        local mainRow=fr(card,UDim2.new(1,0,0,0),nil,C.HEADER,1,0); mainRow.LayoutOrder=1; mainRow.AutomaticSize=Enum.AutomaticSize.Y
        local rl=Instance.new("UIListLayout",mainRow); rl.SortOrder=Enum.SortOrder.LayoutOrder; rl.Padding=UDim.new(0,8); rl.FillDirection=Enum.FillDirection.Horizontal
        local leftPanel=fr(mainRow,UDim2.new(0.5,-4,0,0),UDim2.new(0,0,0,0),C.SEL,0,10); leftPanel.AutomaticSize=Enum.AutomaticSize.Y; leftPanel.LayoutOrder=1
        Instance.new("UIListLayout",leftPanel).Padding=UDim.new(0,8); pad(leftPanel,12,12,12,12)
        local rightPanel=fr(mainRow,UDim2.new(0.5,-4,0,0),UDim2.new(0.5,4,0,0),C.SEL,0,10); rightPanel.AutomaticSize=Enum.AutomaticSize.Y; rightPanel.LayoutOrder=2
        Instance.new("UIListLayout",rightPanel).Padding=UDim.new(0,8); pad(rightPanel,12,12,12,12)
        tabPanels["Visuals"]={leftPanel=leftPanel,rightPanel=rightPanel}
    end)
    RunService.Heartbeat:Wait()

    API.AddTab("World", ICON.world, function(f) makeScrollCard(f,"World") end)
    RunService.Heartbeat:Wait()
    API.AddTab("Skin Changer", ICON.skin, function(f) local _,card=makeScrollCard(f,nil) end)
    RunService.Heartbeat:Wait()

    addSection("MISC")
    API.AddTab("Misc",        ICON.misc,       function(f) makeScrollCard(f,"Misc") end)
    RunService.Heartbeat:Wait()
    API.AddTab("Protections", ICON.protection, function(f) makeScrollCard(f,"Protections") end)
    RunService.Heartbeat:Wait()
    API.AddTab("Exploits",    ICON.exploits,   function(f) makeScrollCard(f,"Exploits") end)
    RunService.Heartbeat:Wait()

    API.AddTab("Configuration", ICON.config, function(f)
        local scroll=Instance.new("ScrollingFrame",f); scroll.Size=UDim2.new(1,0,1,0); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=0; scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
        pad(scroll,8,10,8,8)
        local card=fr(scroll,UDim2.new(1,-4,1,-16),nil,C.HEADER,0,16)
        local v=Instance.new("UIListLayout",card); v.SortOrder=Enum.SortOrder.LayoutOrder; v.Padding=UDim.new(0,8)
        pad(card,16,16,16,16)
        lbl(card,"Configuration",UDim2.new(1,0,0,0),nil,18,C.TEXT,Enum.Font.GothamBold)
        local mainRow=fr(card,UDim2.new(1,0,1,-28),nil,C.HEADER,1,0); mainRow.LayoutOrder=1
        local leftPanel=fr(mainRow,UDim2.new(0.5,-6,1,0),UDim2.new(0,0,0,0),C.SEL,0,10)
        local rightPanel=fr(mainRow,UDim2.new(0.5,-6,1,0),UDim2.new(0.5,6,0,0),C.SEL,0,10)
        local createBtn=Instance.new("TextButton",leftPanel); createBtn.Size=UDim2.new(1,-16,0,32); createBtn.Position=UDim2.new(0,8,0,10); createBtn.BackgroundColor3=C.ACCENT; createBtn.Text="Save Config"; createBtn.TextColor3=C.TEXT; createBtn.TextSize=12; createBtn.Font=Enum.Font.GothamBold; createBtn.AutoButtonColor=false; Instance.new("UICorner",createBtn).CornerRadius=UDim.new(0,8); local cg=Instance.new("UIGradient",createBtn); cg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.ACCENT),ColorSequenceKeypoint.new(1,C.ACCENT2)}); cg.Rotation=90
        local loadBtn=Instance.new("TextButton",leftPanel); loadBtn.Size=UDim2.new(1,-16,0,32); loadBtn.Position=UDim2.new(0,8,0,50); loadBtn.BackgroundColor3=C.ACCENT; loadBtn.Text="Load Config"; loadBtn.TextColor3=C.TEXT; loadBtn.TextSize=12; loadBtn.Font=Enum.Font.GothamBold; loadBtn.AutoButtonColor=false; Instance.new("UICorner",loadBtn).CornerRadius=UDim.new(0,8); local lg=Instance.new("UIGradient",loadBtn); lg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.ACCENT),ColorSequenceKeypoint.new(1,C.ACCENT2)}); lg.Rotation=90
        lbl(rightPanel,"Saved Configs",UDim2.new(1,-16,0,20),UDim2.new(0,10,0,8),12,C.TEXT,Enum.Font.GothamBold)
        local configScroll=Instance.new("ScrollingFrame",rightPanel); configScroll.Size=UDim2.new(1,-16,1,-72); configScroll.Position=UDim2.new(0,8,0,28); configScroll.BackgroundTransparency=1; configScroll.BorderSizePixel=0; configScroll.ScrollBarThickness=3; configScroll.ScrollBarImageColor3=C.ACCENT; configScroll.CanvasSize=UDim2.new(0,0,0,0); configScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
        local configFolder="MenuLibConfigs"; local configFile=configFolder.."/"..tostring(lp.UserId).."_configs.json"
        local function LoadConfigsFromFile() if isfile and isfile(configFile) then local ok,content=pcall(function() return readfile(configFile) end); if ok and content then local ok2,dec=pcall(function() return HttpService:JSONDecode(content) end); if ok2 and dec then _G._ConfigList=dec; return true end end end; _G._ConfigList=_G._ConfigList or {}; return false end
        local function SaveConfigsToFile() if not _G._ConfigList then return end; if makefolder and not isfolder(configFolder) then pcall(function() makefolder(configFolder) end) end; local ok,enc=pcall(function() return HttpService:JSONEncode(_G._ConfigList) end); if ok and enc and writefile then pcall(function() writefile(configFile,enc) end) end end
        LoadConfigsFromFile()
        local bottomActions=fr(rightPanel,UDim2.new(1,-16,0,32),UDim2.new(0,8,1,-36),C.SEL,0,8); bottomActions.ClipsDescendants=false
        local renameBtnBottom=Instance.new("TextButton",bottomActions); renameBtnBottom.Size=UDim2.new(0.48,0,0,28); renameBtnBottom.Position=UDim2.new(0,0,0,0); renameBtnBottom.BackgroundColor3=C.YELLOW; renameBtnBottom.Text="Rename"; renameBtnBottom.TextColor3=C.TEXT; renameBtnBottom.TextSize=11; renameBtnBottom.Font=Enum.Font.GothamBold; renameBtnBottom.AutoButtonColor=false; Instance.new("UICorner",renameBtnBottom).CornerRadius=UDim.new(0,6)
        local delBtnBottom=Instance.new("TextButton",bottomActions); delBtnBottom.Size=UDim2.new(0.48,0,0,28); delBtnBottom.Position=UDim2.new(0.52,0,0,0); delBtnBottom.BackgroundColor3=C.RED; delBtnBottom.Text="Delete"; delBtnBottom.TextColor3=C.TEXT; delBtnBottom.TextSize=11; delBtnBottom.Font=Enum.Font.GothamBold; delBtnBottom.AutoButtonColor=false; Instance.new("UICorner",delBtnBottom).CornerRadius=UDim.new(0,6)
        local selectedConfig=nil; local selectedRow=nil
        local popupOverlay=fr(sg,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),Color3.fromRGB(0,0,0),0.6,0); popupOverlay.Visible=false; popupOverlay.ZIndex=1000; popupOverlay.Active=false
        local popupFrame=fr(popupOverlay,UDim2.new(0,280,0,120),UDim2.new(0.5,-140,0.5,-60),C.HEADER,0,16); popupFrame.ZIndex=101
        local popupTitle=lbl(popupFrame,"Enter Config Name",UDim2.new(1,-20,0,24),UDim2.new(0,10,0,12),14,C.TEXT,Enum.Font.GothamBold); popupTitle.TextXAlignment=Enum.TextXAlignment.Center
        local popupBox=Instance.new("TextBox",popupFrame); popupBox.Size=UDim2.new(1,-20,0,28); popupBox.Position=UDim2.new(0,10,0,44); popupBox.BackgroundColor3=C.SEL; popupBox.TextColor3=C.TEXT; popupBox.TextSize=12; popupBox.Font=Enum.Font.Gotham; popupBox.PlaceholderText="Config name..."; popupBox.ClearTextOnFocus=false; popupBox.ZIndex=102; Instance.new("UICorner",popupBox).CornerRadius=UDim.new(0,8)
        local popupBtnRow=fr(popupFrame,UDim2.new(1,-20,0,28),UDim2.new(0,10,0,80),C.HEADER,1,0); popupBtnRow.ZIndex=102
        local popupConfirm=Instance.new("TextButton",popupBtnRow); popupConfirm.Size=UDim2.new(0.48,0,1,0); popupConfirm.BackgroundColor3=C.GREEN; popupConfirm.Text="OK"; popupConfirm.TextColor3=C.TEXT; popupConfirm.TextSize=12; popupConfirm.Font=Enum.Font.GothamBold; popupConfirm.ZIndex=103; Instance.new("UICorner",popupConfirm).CornerRadius=UDim.new(0,6)
        local popupCancel=Instance.new("TextButton",popupBtnRow); popupCancel.Size=UDim2.new(0.48,0,1,0); popupCancel.Position=UDim2.new(0.52,0,0,0); popupCancel.BackgroundColor3=C.RED; popupCancel.Text="Cancel"; popupCancel.TextColor3=C.TEXT; popupCancel.TextSize=12; popupCancel.Font=Enum.Font.GothamBold; popupCancel.ZIndex=103; Instance.new("UICorner",popupCancel).CornerRadius=UDim.new(0,6)
        local popupMode="create"; local renameOldName=nil
        local function showPopup(mode,title,defaultText) popupMode=mode; popupTitle.Text=title; popupBox.Text=defaultText or ""; popupOverlay.Visible=true; popupOverlay.BackgroundTransparency=1; popupFrame.Size=UDim2.new(0,200,0,100); popupFrame.Position=UDim2.new(0.5,-100,0.5,-50); tw(popupOverlay,{BackgroundTransparency=0.6},0.2); tw(popupFrame,{Size=UDim2.new(0,280,0,120),Position=UDim2.new(0.5,-140,0.5,-60)},0.25,Enum.EasingStyle.Back); task.delay(0.15,function() popupBox:CaptureFocus() end) end
        local function hidePopup() tw(popupFrame,{Size=UDim2.new(0,200,0,100),Position=UDim2.new(0.5,-100,0.5,-50)},0.2); tw(popupOverlay,{BackgroundTransparency=1},0.2); task.delay(0.2,function() popupOverlay.Visible=false end) end
        local function RefreshConfigList()
            for _,child in ipairs(configScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
            selectedConfig=nil; selectedRow=nil
            if not _G._ConfigList then _G._ConfigList={} end
            for name,_ in pairs(_G._ConfigList) do
                local row2=fr(configScroll,UDim2.new(1,0,0,32),nil,C.SEL,0.8,6); row2.LayoutOrder=#configScroll:GetChildren()
                local nL2=lbl(row2,name,UDim2.new(1,-16,1,0),UDim2.new(0,12,0,0),12,C.TEXT,Enum.Font.GothamBold); nL2.TextTruncate=Enum.TextTruncate.AtEnd
                local stripe2=fr(row2,UDim2.new(0,4,0.6,0),UDim2.new(0,0,0.2,0),C.ACCENT,1,2); gradV(stripe2,C.ACCENT,C.ACCENT2)
                local clickBtn=Instance.new("TextButton",row2); clickBtn.Size=UDim2.new(1,0,1,0); clickBtn.BackgroundTransparency=1; clickBtn.Text=""
                local function selectThis()
                    selectedConfig=name; selectedRow=row2
                    for _,child in ipairs(configScroll:GetChildren()) do if child:IsA("Frame") then tw(child,{BackgroundTransparency=1},0.15) end end
                    row2.Size=UDim2.new(1,0,0,38); tw(row2,{Size=UDim2.new(1,0,0,32)},0.2,Enum.EasingStyle.Back); tw(row2,{BackgroundColor3=C.ACCENT,BackgroundTransparency=0.3},0.2); tw(stripe2,{BackgroundTransparency=0},0.25)
                    configScroll.Size=UDim2.new(1,-16,1,-72)
                end
                clickBtn.MouseButton1Click:Connect(selectThis)
                clickBtn.MouseEnter:Connect(function() if selectedConfig~=name then tw(row2,{BackgroundColor3=Color3.fromRGB(35,20,60)},0.1) end end)
                clickBtn.MouseLeave:Connect(function() if selectedConfig~=name then tw(row2,{BackgroundTransparency=1},0.1) end end)
            end
        end
        renameBtnBottom.MouseButton1Click:Connect(function() if selectedConfig then renameOldName=selectedConfig; showPopup("rename","Rename Config",selectedConfig) end end)
        delBtnBottom.MouseButton1Click:Connect(function()
            if selectedConfig and _G._ConfigList and _G._ConfigList[selectedConfig] then
                _G._ConfigList[selectedConfig]=nil; SaveConfigsToFile(); local oldRow=selectedRow; selectedConfig=nil; selectedRow=nil
                configScroll.Size=UDim2.new(1,-16,1,-32)
                if oldRow then tw(oldRow,{Size=UDim2.new(1,0,0,0)},0.15); task.delay(0.15,function() if oldRow then oldRow:Destroy() end end) end
                RefreshConfigList()
            end
        end)
        createBtn.MouseButton1Click:Connect(function()
            if selectedConfig and _G._ConfigList and _G._ConfigList[selectedConfig] then
                if _G.GetConfigData then _G._ConfigList[selectedConfig]=_G.GetConfigData(); SaveConfigsToFile(); RefreshConfigList() end
            else showPopup("create","Save New Config","") end
        end)
        popupConfirm.MouseButton1Click:Connect(function()
            local name=popupBox.Text:gsub("^%s+",""):gsub("%s+$",""); if name=="" then hidePopup(); return end
            if not _G._ConfigList then _G._ConfigList={} end
            if popupMode=="create" then
                if not _G._ConfigList[name] and _G.GetConfigData then _G._ConfigList[name]=_G.GetConfigData(); SaveConfigsToFile(); RefreshConfigList() end
            elseif popupMode=="rename" and renameOldName then
                if name~=renameOldName and not _G._ConfigList[name] then _G._ConfigList[name]=_G._ConfigList[renameOldName]; _G._ConfigList[renameOldName]=nil; SaveConfigsToFile(); RefreshConfigList() end
            end
            hidePopup()
        end)
        popupCancel.MouseButton1Click:Connect(hidePopup)
        loadBtn.MouseButton1Click:Connect(function() if selectedConfig and _G._ConfigList[selectedConfig] and _G.LoadConfigData then _G.LoadConfigData(_G._ConfigList[selectedConfig]); _G._CurrentConfig=selectedConfig end end)
        if not _G._MenuToggles   then _G._MenuToggles={} end
        if not _G._MenuSliders   then _G._MenuSliders={} end
        if not _G._MenuDropdowns then _G._MenuDropdowns={} end
        if not _G.GetConfigData then
            _G.GetConfigData=function()
                local data={}
                data._MenuSettings={BlurEnabled=_G._BlurEnabled,LightingDimEnabled=_G._LightingDimEnabled,MenuToggleKey=tostring(_G._MenuToggleKey),UnloadKey=tostring(_G._UnloadKey),SmoothAnimations=_G._SmoothAnimations}
                if _G._MenuToggles   then data._ToggleStates={};   for lbl2,tog in pairs(_G._MenuToggles)   do data._ToggleStates[lbl2]=tog.Get and tog.Get() or false end end
                if _G._MenuSliders   then data._SliderStates={};   for lbl2,sl  in pairs(_G._MenuSliders)   do data._SliderStates[lbl2]=sl.Get  and sl.Get()  or 0     end end
                if _G._MenuDropdowns then data._DropdownStates={}; for lbl2,dd  in pairs(_G._MenuDropdowns) do local _,idx=nil,1; if dd.Get then _,idx=dd.Get() end; data._DropdownStates[lbl2]=idx or 1 end end
                return data
            end
        end
        if not _G.LoadConfigData then
            _G.LoadConfigData=function(data)
                if not data then return end
                if data._MenuSettings then local s=data._MenuSettings; _G._BlurEnabled=s.BlurEnabled; _G._LightingDimEnabled=s.LightingDimEnabled; _G._SmoothAnimations=s.SmoothAnimations; if s.MenuToggleKey then pcall(function() _G._MenuToggleKey=Enum.KeyCode[s.MenuToggleKey] end) end; if s.UnloadKey then pcall(function() _G._UnloadKey=Enum.KeyCode[s.UnloadKey] end) end end
                if data._ToggleStates   and _G._MenuToggles   then for lbl2,val in pairs(data._ToggleStates)   do local t=_G._MenuToggles[lbl2];   if t and t.Set then t.Set(val) end end end
                if data._SliderStates   and _G._MenuSliders   then for lbl2,val in pairs(data._SliderStates)   do local sl=_G._MenuSliders[lbl2];  if sl and sl.Set then sl.Set(val) end end end
                if data._DropdownStates and _G._MenuDropdowns then for lbl2,idx in pairs(data._DropdownStates) do local dd=_G._MenuDropdowns[lbl2]; if dd and dd.Set then dd.Set(idx) end end end
                _G._ConfigLoaded=tick()
            end
        end
        RefreshConfigList()
    end)

    -- Select first tab
    if firstTab and firstTab.Select then
        pcall(function() firstTab:Select() end)
    end

    -- ── Window resizer grip ──────────────────────────────────────────────
    local function makeResizer(parent)
        local r=Instance.new("TextButton",parent); r.Size=UDim2.new(0,20,0,20); r.Position=UDim2.new(1,-20,1,-20); r.BackgroundTransparency=1; r.Text=""; r.ZIndex=50; return r
    end
    local resizer = makeResizer(win)
    local settingsResizer = makeResizer(settingsPanel)
    local isResizing=false; local resizeStartMouse=nil; local resizeStartW=0; local resizeStartH=0
    local function beginResize(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then isResizing=true; resizeStartMouse=UserInputService:GetMouseLocation(); resizeStartW=WIN_W; resizeStartH=WIN_H end
    end
    resizer.InputBegan:Connect(beginResize); settingsResizer.InputBegan:Connect(beginResize)
    table.insert(conns, UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then isResizing=false end end))
    table.insert(conns, UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement and isResizing then
            local cm=UserInputService:GetMouseLocation(); local delta=cm-resizeStartMouse
            WIN_W=math.max(600,resizeStartW+delta.X*2); WIN_H=math.max(380,resizeStartH+delta.Y*2)
            win.Size=UDim2.new(0,WIN_W,0,WIN_H); win.Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
            settingsPanel.Size=UDim2.new(0,WIN_W,0,WIN_H); settingsPanel.Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
            setSidebarWidth(SIDE_W,false)
        end
    end))

    return API
end

return MenuLib
