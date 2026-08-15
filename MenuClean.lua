local MenuLib = {}

function MenuLib:Init(config)
    config = config or {}
    
    local Players = game:GetService("Players")
    while not Players do task.wait(); Players = game:GetService("Players") end
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local HttpService = game:GetService("HttpService")
    
    while not Players.LocalPlayer do task.wait() end
    local lp = Players.LocalPlayer
    local pg = lp:WaitForChild("PlayerGui")
    local _guid = tostring(tick() * 100000 % 1e12)
    pcall(function() _guid = HttpService:GenerateGUID(false) end)
    local RS_BIND_INP = "MenuGuiInp_" .. _guid
    
    _G._MenuAutoRefresh = true
    _G._BlurEnabled = false
    _G._LightingDimEnabled = false
    _G._OriginalBrightness = nil
    _G._OriginalClockTime = nil
    _G._OriginalQualityLevel = nil
    _G._MenuToggleKey = Enum.KeyCode.Insert
    _G._UnloadKey = Enum.KeyCode.Delete
    _G._SmoothAnimations = true
    _G._ESPColour = Color3.fromRGB(120, 40, 240)
    
    local ICON = {
        home = "rbxassetid://130068439240504",
        settings = "rbxassetid://11932591062",
        aim = "rbxassetid://111457651714934",
        players = "rbxassetid://13321848320",
        world = "rbxassetid://7744394226",
        misc = "rbxassetid://84090157888894",
        sfx = "rbxassetid://7203392850",
        exploits = "rbxassetid://16149155528",
        config = "rbxassetid://130521044774541",
        general = "rbxassetid://7733765398",
        appearance = "rbxassetid://7347408509",
        performance = "rbxassetid://13321880274",
        keyboard = "rbxassetid://7734022107",
        fire = "rbxassetid://14502433595",
        protection = "rbxassetid://73332630842054",
        skin = "rbxassetid://81837937089566",
        playerTab = "rbxthumb://type=Asset&id=2795572803&w=150&h=150",
    }
    
    -- Configurable icon size for the Players tab (change this to resize)
    local PLAYERS_TAB_ICON_SIZE = 20
    
    local function normalizeIconId(id)
        if type(id) ~= "string" and type(id) ~= "number" then return nil end
        local s = tostring(id):gsub("^%s+", ""):gsub("%s+$", "")
        if s == "" then return nil end
        if s:match("^rbxassetid://") or s:match("^rbxasset://") then return s end
        if s:match("^%d+$") then return "rbxassetid://" .. s end
        return s
    end
    
    local controls = nil
    local isOpen = false
    local prevMouseBehavior = Enum.MouseBehavior.Default
    local prevMouseIconEnabled = UserInputService.MouseIconEnabled
    
    -- Create sg first so inputBlocker can parent to it
    local sg = Instance.new("ScreenGui")
    sg.Name = "MenuGui_v4"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 2147483647
    sg.Parent = pg

    local inputBlocker = Instance.new("TextButton")
    inputBlocker.Size = UDim2.new(1, 0, 1, 0)
    inputBlocker.BackgroundTransparency = 1
    inputBlocker.Text = ""
    inputBlocker.Active = true
    inputBlocker.Visible = false
    inputBlocker.ZIndex = -10
    inputBlocker.Parent = sg
    
    pcall(function()
        local PM = require(lp:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        controls = PM:GetControls()
    end)
    
    local function lockInput()
        prevMouseBehavior = UserInputService.MouseBehavior
        prevMouseIconEnabled = UserInputService.MouseIconEnabled
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
        pcall(function() UserInputService.MouseBehavior = prevMouseBehavior end)
        pcall(function() UserInputService.MouseIconEnabled = prevMouseIconEnabled end)
    end
    
    RunService:BindToRenderStep(RS_BIND_INP, Enum.RenderPriority.Last.Value + 1, function()
        if not isOpen then return end
        if not win.Visible and not settingsPanel.Visible then
            isOpen = false
            return
        end
        pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
        pcall(function() UserInputService.MouseIconEnabled = true end)
    end)
    
    local C = {
        BG = Color3.fromRGB(8, 4, 18),
        SIDEBAR = Color3.fromRGB(5, 2, 12),
        CONTENT = Color3.fromRGB(11, 6, 24),
        HEADER = Color3.fromRGB(16, 9, 32),
        ACCENT = Color3.fromRGB(120, 40, 240),
        ACCENT2 = Color3.fromRGB(215, 38, 148),
        DIV = Color3.fromRGB(28, 13, 52),
        TEXT = Color3.fromRGB(255, 255, 255),
        DIM = Color3.fromRGB(140, 115, 175),
        SEC = Color3.fromRGB(185, 160, 220),
        GREEN = Color3.fromRGB(55, 210, 95),
        YELLOW = Color3.fromRGB(255, 185, 30),
        RED = Color3.fromRGB(225, 52, 52),
        BTN = Color3.fromRGB(20, 10, 40),
        BTNHOV = Color3.fromRGB(33, 17, 60),
        SEL = Color3.fromRGB(26, 13, 48),
        DARK = Color3.fromRGB(4, 2, 9),
    }
    
    local WIN_W = config.width or 650
    local WIN_H = config.height or 490
    local SIDE_W = config.sidebarWidth or 160
    local HUD_W = config.hudWidth or 520
    
    local function fr(parent, size, pos, col, trans, rad)
        local f = Instance.new("Frame")
        f.Size = size
        f.Position = pos or UDim2.new(0, 0, 0, 0)
        f.BackgroundColor3 = col or C.BG
        f.BackgroundTransparency = trans or 0
        f.BorderSizePixel = 0
        f.Parent = parent
        if rad ~= nil and rad ~= false then
            local c = Instance.new("UICorner")
            if typeof(rad) == "number" then
                c.CornerRadius = UDim.new(0, rad)
            else
                c.CornerRadius = rad
            end
            c.Parent = f
        end
        return f
    end
    
    local function lbl(parent, txt, size, pos, ts, col, font)
        local l = Instance.new("TextLabel")
        l.Size = size
        l.Position = pos or UDim2.new(0, 0, 0, 0)
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
        g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2) })
        g.Rotation = 90
        g.Parent = parent
        return g
    end
    
    local function pad(parent, l, r, t, b)
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, l or 0)
        p.PaddingRight = UDim.new(0, r or 0)
        p.PaddingTop = UDim.new(0, t or 0)
        p.PaddingBottom = UDim.new(0, b or 0)
        p.Parent = parent
        return p
    end
    
    local function tw(obj, props, t, style)
        if not obj then return end
        TweenService:Create(obj, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quint), props):Play()
    end
    
    local blurPart = nil
    local activeDropdownClosers = {}
    
    -- ============================================================
    -- FIX 1: Toggle - use Size animation so fill and knob are
    -- perfectly in sync (no more "fill beats knob" bug)
    -- ============================================================
    local function mkToggle(parent, posX, initState, onToggle)
        local track = fr(parent, UDim2.new(0, 44, 0, 24), UDim2.new(1, posX, 0.5, -12), Color3.fromRGB(18, 8, 36), 0, 12)
        track.ClipsDescendants = true
        -- Fill starts at zero width (not full width + transparent)
        -- This makes the size animation perfectly sync with knob position
        local fill = fr(track, UDim2.new(0, 0, 1, 0), nil, C.ACCENT, 0, 12)
        gradV(fill, C.ACCENT, C.ACCENT2)
        local knob = fr(track, UDim2.new(0, 18, 0, 18), UDim2.new(0, 3, 0.5, -9), C.TEXT, 0, 9)
        local togBtn = Instance.new("TextButton")
        togBtn.Size = UDim2.new(1, 0, 1, 0)
        togBtn.BackgroundTransparency = 1
        togBtn.Text = ""
        togBtn.Parent = track
        local state = initState
        local function apply(anim, silent)
            -- Animate SIZE instead of transparency â€” knob and fill move together at exactly the same speed
            local fillDest = state and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 1, 0)
            local dest = state and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            if anim then
                tw(fill, { Size = fillDest }, 0.35)
                tw(knob, { Position = dest }, 0.35)
            else
                fill.Size = fillDest
                knob.Position = dest
            end
            if onToggle and not silent then task.defer(function() onToggle(state) end) end
        end
        apply(false, true)
        togBtn.MouseButton1Click:Connect(function()
            state = not state
            apply(true, false)
        end)
        return { Get = function() return state end, Set = function(v) if v ~= state then state = v apply(true, false) end end }
    end
    
    -- Connection tracking for cleanup
    local conns = {}
    table.insert(conns, UserInputService.WindowFocusReleased:Connect(function()
        if isOpen then
            pcall(toggleMenu)
        end
    end))
    local unloaded = false
    -- Cleaned up old global mouse var

    -- UI (sg already created above)
    
    local hudBar = fr(sg, UDim2.new(0, HUD_W, 0, 44), UDim2.new(0.5, -HUD_W / 2, 0, 10), C.DARK, 0, 18)
    hudBar.ZIndex = 5
    
    local av = fr(hudBar, UDim2.new(0, 32, 0, 32), UDim2.new(0, 10, 0.5, -16), Color3.fromRGB(36, 14, 68), 0, 16)
    local avImg = Instance.new("ImageLabel")
    avImg.Size = UDim2.new(1, -4, 1, -4)
    avImg.Position = UDim2.new(0, 2, 0, 2)
    avImg.BackgroundTransparency = 1
    avImg.Parent = av
    Instance.new("UICorner").Parent = avImg
    task.spawn(function()
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
        end)
        if ok and url then avImg.Image = url end
    end)
    
    lbl(hudBar, "Welcome back,", UDim2.new(0, 140, 0, 14), UDim2.new(0, 48, 0, 6), 9, C.DIM)
    local nameLbl = lbl(hudBar, lp.Name, UDim2.new(0, 0, 0, 16), UDim2.new(0, 48, 0, 20), 12, C.TEXT, Enum.Font.GothamBold)
    nameLbl.AutomaticSize = Enum.AutomaticSize.X
    
    local fpsLbl = lbl(hudBar, "...", UDim2.new(0, 0, 0, 20), UDim2.new(0, 248, 0, 14), 14, C.ACCENT, Enum.Font.GothamBold)
    fpsLbl.AutomaticSize = Enum.AutomaticSize.X
    local pingLbl = lbl(hudBar, "...", UDim2.new(0, 0, 0, 20), UDim2.new(0, 340, 0, 14), 14, C.GREEN, Enum.Font.GothamBold)
    pingLbl.AutomaticSize = Enum.AutomaticSize.X
    local timeLbl = lbl(hudBar, "12:00 PM", UDim2.new(0, 0, 0, 16), UDim2.new(0, 556, 0, 12), 14, C.TEXT, Enum.Font.GothamBold)
    timeLbl.AutomaticSize = Enum.AutomaticSize.X
    
    local function mkDivL(parent)
        local d = fr(parent, UDim2.new(0, 2, 0, 18), UDim2.new(0, 0, 0.5, -9), C.DIV, 0.2, 1)
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
    homeBtn.Size = UDim2.new(0, 30, 0, 30)
    homeBtn.Position = UDim2.new(0, 420, 0.45, -15)
    homeBtn.BackgroundColor3 = Color3.fromRGB(24, 10, 48)
    homeBtn.BackgroundTransparency = 0.2
    homeBtn.Text = ""
    homeBtn.AutoButtonColor = false
    homeBtn.Parent = hudBar
    Instance.new("UICorner").Parent = homeBtn
    
    local homeBtnIcon1 = Instance.new("ImageLabel")
    homeBtnIcon1.Size = UDim2.new(1, 0, 1, 0)
    homeBtnIcon1.BackgroundTransparency = 1
    homeBtnIcon1.Image = ICON.settings
    homeBtnIcon1.ScaleType = Enum.ScaleType.Fit
    homeBtnIcon1.ImageColor3 = C.TEXT
    homeBtnIcon1.ImageTransparency = 0
    homeBtnIcon1.Parent = homeBtn
    
    local homeBtnIcon2 = Instance.new("ImageLabel")
    homeBtnIcon2.Size = UDim2.new(1, 0, 1, 0)
    homeBtnIcon2.BackgroundTransparency = 1
    homeBtnIcon2.Image = ICON.home
    homeBtnIcon2.ScaleType = Enum.ScaleType.Fit
    homeBtnIcon2.ImageColor3 = C.TEXT
    homeBtnIcon2.ImageTransparency = 1
    homeBtnIcon2.Parent = homeBtn
    
    local badge = fr(hudBar, UDim2.new(0, 32, 0, 28), UDim2.new(0, 670, 0.5, -14), C.ACCENT, 0, 8)
    gradV(badge, C.ACCENT, C.ACCENT2)
    local fireI = Instance.new("ImageLabel")
    fireI.Size = UDim2.new(0, 18, 0, 18)
    fireI.Position = UDim2.new(0.5, -9, 0.5, -9)
    fireI.BackgroundTransparency = 1
    fireI.Image = ICON.fire
    fireI.ScaleType = Enum.ScaleType.Fit
    fireI.ImageColor3 = Color3.fromRGB(255, 255, 255)
    fireI.Parent = badge
    gradV(fireI, C.ACCENT, C.ACCENT2)
    local fireClick = Instance.new("TextButton")
    fireClick.Size = UDim2.new(1, 0, 1, 0)
    fireClick.BackgroundTransparency = 1
    fireClick.Text = ""
    fireClick.ZIndex = 10
    fireClick.Parent = badge
    
    local win = fr(sg, UDim2.new(0, WIN_W, 0, WIN_H), UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2), C.BG, 0, 20)
    win.ClipsDescendants = true
    win.ZIndex = 1
    win.Visible = false
    
    local mainLayer = fr(win, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), C.BG, 1, 0)
    mainLayer.ZIndex = 2
    
    local dragHandle = Instance.new("TextButton")
    dragHandle.Size = UDim2.new(1, 0, 0, 12)
    dragHandle.Position = UDim2.new(0, 0, 0, 0)
    dragHandle.BackgroundTransparency = 1
    dragHandle.Text = ""
    dragHandle.ZIndex = 30
    dragHandle.Parent = mainLayer
    
    local bodyShell = fr(mainLayer, UDim2.new(1, 0, 1, -12), UDim2.new(0, 0, 0, 12), C.BG, 1, 0)
    bodyShell.ZIndex = 2

    local sidebar = fr(bodyShell, UDim2.new(0, SIDE_W, 1, -4), UDim2.new(0, 0, 0, 4), C.SIDEBAR, 0, 14)
    sidebar.ZIndex = 2
    sidebar.ClipsDescendants = true

    local sidebarDivider = fr(bodyShell, UDim2.new(0, 1, 1, -4), UDim2.new(0, SIDE_W, 0, 4), C.DIV)

    -- Horizontal tab bar (hidden by default, shown in horizontal mode)
    local TAB_BAR_H = 42
    local tabBarIsHorizontal = false

    local topTabBar = fr(bodyShell, UDim2.new(1, -4, 0, TAB_BAR_H), UDim2.new(0, 2, 0, 4), C.SIDEBAR, 0, 14)
    topTabBar.ZIndex = 3
    topTabBar.Visible = false
    topTabBar.ClipsDescendants = true

    local topTabScroll = Instance.new("ScrollingFrame")
    topTabScroll.Size = UDim2.new(1, 0, 1, 0)
    topTabScroll.BackgroundTransparency = 1
    topTabScroll.BorderSizePixel = 0
    topTabScroll.ScrollBarThickness = 0
    topTabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    topTabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    topTabScroll.ScrollingDirection = Enum.ScrollingDirection.X
    topTabScroll.Parent = topTabBar
    pad(topTabScroll, 6, 6, 4, 4)

    local topTabLayout = Instance.new("UIListLayout")
    topTabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    topTabLayout.FillDirection = Enum.FillDirection.Horizontal
    topTabLayout.Padding = UDim.new(0, 4)
    topTabLayout.Parent = topTabScroll

    local topTabDivider = fr(bodyShell, UDim2.new(1, -4, 0, 1), UDim2.new(0, 2, 0, TAB_BAR_H + 4), C.DIV)
    topTabDivider.Visible = false

    local contentArea = fr(bodyShell, UDim2.new(1, -SIDE_W - 2, 1, -32), UDim2.new(0, SIDE_W + 2, 0, 4), C.CONTENT, 0, 16)
    contentArea.ZIndex = 2

    local statusBar = fr(bodyShell, UDim2.new(1, -SIDE_W - 2, 0, 28), UDim2.new(0, SIDE_W + 2, 1, -32), C.DARK, 0, 12)
    
    local function mkSmallBtn(parent, txt, size, pos, fn)
        local b = Instance.new("TextButton")
        b.Size = size
        b.Position = pos
        b.BackgroundColor3 = C.BTN
        b.Text = txt
        b.TextColor3 = C.TEXT
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.Parent = parent
        Instance.new("UICorner").Parent = b
        b.MouseEnter:Connect(function() tw(b, { BackgroundColor3 = C.BTNHOV }, 0.12) end)
        b.MouseLeave:Connect(function() tw(b, { BackgroundColor3 = C.BTN }, 0.12) end)
        if fn then b.MouseButton1Click:Connect(fn) end
        return b
    end
    
    local navHolder = fr(sidebar, UDim2.new(1, 0, 1, 0), nil, C.SIDEBAR, 1, 0)
    local navScroll = Instance.new("ScrollingFrame")
    navScroll.Size = UDim2.new(1, 0, 1, 0)
    navScroll.ZIndex = 2
    navScroll.BackgroundTransparency = 1
    navScroll.BorderSizePixel = 0
    navScroll.ScrollBarThickness = 0
    navScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    navScroll.Parent = navHolder
    pad(navScroll, 8, 10, 12, 10)
    
    local navList = Instance.new("UIListLayout")
    navList.SortOrder = Enum.SortOrder.LayoutOrder
    navList.Padding = UDim.new(0, 6)
    navList.Parent = navScroll
    
    local activeTab = nil
    local allTabs = {}
    local tabContents = {}
    local settingsTabs = {}
    local navLayoutOrd = 0
    local topLayoutOrd = 0
    local function nextNavOrd()
        navLayoutOrd = navLayoutOrd + 1
        return navLayoutOrd
    end
    local function nextTopOrd()
        topLayoutOrd = topLayoutOrd + 1
        return topLayoutOrd
    end
    
    local sectionLabels = {}
    local navSectionCount = 0
    local function addSection(name)
        navSectionCount = navSectionCount + 1
        if navSectionCount > 1 then
            local rule = fr(navScroll, UDim2.new(1, -8, 0, 1), nil, C.DIV, 1, 0)
            rule.BackgroundTransparency = 0.35
            rule.LayoutOrder = nextNavOrd()
        end
        local s = lbl(navScroll, name, UDim2.new(1, -4, 0, 22), nil, 11, C.SEC, Enum.Font.GothamBold)
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.LayoutOrder = nextNavOrd()
        pad(s, 10, 0, 2, 0)
        table.insert(sectionLabels, s)
        -- Horizontal tab bar: subtle separator + same group title
        if navSectionCount > 1 then
            local vdiv = fr(topTabScroll, UDim2.new(0, 1, 0, 22), nil, C.DIV, 1, 0)
            vdiv.BackgroundTransparency = 0.4
            vdiv.LayoutOrder = nextTopOrd()
        end
        local hs = lbl(topTabScroll, name, UDim2.new(0, math.max(28, #name * 7), 0, 28), nil, 10, C.SEC, Enum.Font.GothamBold)
        hs.TextYAlignment = Enum.TextYAlignment.Center
        hs.LayoutOrder = nextTopOrd()
    end
    
    local function selectTab(entry)
        local isCompact = (SIDE_W <= 100)
        local tf = entry.frame
        tf.Visible = true
        tf.Position = UDim2.new(0, 30, 0, 0)
        tw(tf, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.4)
        -- Vertical sidebar highlight
        tw(entry.bg, { BackgroundTransparency = 0 }, 0.3)
        tw(entry.line, { BackgroundTransparency = isCompact and 1 or 0, Size = UDim2.new(0, 4, 0.5, 0) }, 0.35)
        tw(entry.lbl, { TextColor3 = C.TEXT }, 0.25)
        tw(entry.ico, { ImageColor3 = C.TEXT, Position = isCompact and UDim2.new(0.5, -entry.iconSize/2, 0.5, -entry.iconSize/2) or UDim2.new(0, entry.iconX + 4, 0.5, -entry.iconSize / 2) }, 0.3)
        -- Horizontal bar highlight
        if entry.hBtn then
            tw(entry.hBg, { BackgroundTransparency = 0 }, 0.3)
            tw(entry.hLine, { BackgroundTransparency = 0, Size = UDim2.new(0.5, 0, 0, 3) }, 0.35)
            tw(entry.hIco, { ImageColor3 = C.TEXT }, 0.25)
            tw(entry.hLbl, { TextColor3 = C.TEXT }, 0.25)
        end
    end

    local function deselectTab(entry)
        local isCompact = (SIDE_W <= 100)
        local tf = entry.frame
        tw(tf, { Position = UDim2.new(0, -30, 0, 0), BackgroundTransparency = 1 }, 0.35)
        -- Vertical sidebar deselect
        tw(entry.bg, { BackgroundTransparency = 1 }, 0.25)
        tw(entry.line, { BackgroundTransparency = 1, Size = UDim2.new(0, 4, 0, 0) }, 0.2)
        tw(entry.lbl, { TextColor3 = C.DIM }, 0.2)
        tw(entry.ico, { ImageColor3 = C.DIM, Position = isCompact and UDim2.new(0.5, -entry.iconSize/2, 0.5, -entry.iconSize/2) or UDim2.new(0, entry.iconX, 0.5, -entry.iconSize / 2) }, 0.25)
        task.delay(0.35, function() tf.Visible = false end)
        -- Horizontal bar deselect
        if entry.hBtn then
            tw(entry.hBg, { BackgroundTransparency = 1 }, 0.25)
            tw(entry.hLine, { BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 0, 0) }, 0.2)
            tw(entry.hIco, { ImageColor3 = C.DIM }, 0.2)
            tw(entry.hLbl, { TextColor3 = C.DIM }, 0.2)
        end
    end

    local function doTabSwitch(entry)
        if activeTab and activeTab ~= entry then deselectTab(activeTab) activeTab.frame.Visible = false end
        activeTab = entry
        entry.frame.Visible = true
        selectTab(entry)
    end

    local function addTab(name, iconImage, buildFn)
        local tf = fr(contentArea, UDim2.new(1, 0, 1, 0), nil, C.CONTENT, 1, 0)
        tf.Visible = false
        tf.ZIndex = 5
        if buildFn then buildFn(tf) end

        local navOrd = nextNavOrd()
        local topOrd = nextTopOrd()

        -- Vertical sidebar button
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 38)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.LayoutOrder = navOrd
        btn.Parent = navScroll
        Instance.new("UICorner").Parent = btn

        local selBg = fr(btn, UDim2.new(1, 0, 1, 0), nil, C.SEL, 1, 12)
        local selLine = fr(btn, UDim2.new(0, 4, 0.5, 0), UDim2.new(1, -5, 0.25, 0), C.ACCENT, 1, 4)
        gradV(selLine, C.ACCENT, C.ACCENT2)

        local iconSize = 24
        local iconX = 6
        if iconImage == ICON.aim then
            iconSize = 29
            iconX = 2
        elseif iconImage == ICON.players then
            iconSize = 28
            iconX = 2
        elseif iconImage == ICON.performance then
            iconSize = 28
            iconX = 2
        elseif iconImage == ICON.sfx then
            iconSize = 22
            iconX = 6.5
        elseif iconImage == ICON.world then
            iconSize = 20
        elseif iconImage == ICON.skin then
            iconSize = 28
            iconX = 4
        end

        local icoL = Instance.new("ImageLabel")
        icoL.Size = UDim2.new(0, iconSize, 0, iconSize)
        icoL.Position = UDim2.new(0, iconX, 0.5, -iconSize / 2)
        icoL.BackgroundTransparency = 1
        icoL.Image = normalizeIconId(iconImage) or ""
        icoL.ScaleType = Enum.ScaleType.Fit
        icoL.ImageColor3 = C.DIM
        icoL.Parent = btn

        local namL = lbl(btn, name, UDim2.new(1, -52, 1, 0), UDim2.new(0, 44, 0, 0), 12, C.DIM)

        -- Horizontal top bar button
        local hBtnW = math.max(#name * 7 + 42, 70)
        local hBtn = Instance.new("TextButton")
        hBtn.Size = UDim2.new(0, hBtnW, 1, -8)
        hBtn.BackgroundTransparency = 1
        hBtn.Text = ""
        hBtn.LayoutOrder = topOrd
        hBtn.Parent = topTabScroll
        Instance.new("UICorner").Parent = hBtn

        local hBg = fr(hBtn, UDim2.new(1, 0, 1, 0), nil, C.SEL, 1, 10)
        local hLine = fr(hBtn, UDim2.new(0.5, 0, 0, 0), UDim2.new(0.25, 0, 1, -3), C.ACCENT, 1, 2)
        gradV(hLine, C.ACCENT2, C.ACCENT)

        local hIco = Instance.new("ImageLabel")
        hIco.Size = UDim2.new(0, 18, 0, 18)
        hIco.Position = UDim2.new(0, 8, 0.5, -9)
        hIco.BackgroundTransparency = 1
        hIco.Image = normalizeIconId(iconImage) or ""
        hIco.ScaleType = Enum.ScaleType.Fit
        hIco.ImageColor3 = C.DIM
        hIco.Parent = hBtn

        local hLbl = lbl(hBtn, name, UDim2.new(1, -34, 1, 0), UDim2.new(0, 30, 0, 0), 11, C.DIM, Enum.Font.GothamBold)

        local entry = {
            btn = btn, frame = tf, bg = selBg, line = selLine, ico = icoL, lbl = namL,
            iconSize = iconSize, iconX = iconX,
            hBtn = hBtn, hBg = hBg, hLine = hLine, hIco = hIco, hLbl = hLbl
        }
        table.insert(allTabs, entry)
        tabContents[name] = tf

        entry._des = function() deselectTab(entry) end
        entry._sel = function() selectTab(entry) end

        -- Vertical button events
        btn.MouseEnter:Connect(function() if activeTab ~= entry then tw(selBg, { BackgroundTransparency = 0.5 }) end end)
        btn.MouseLeave:Connect(function() if activeTab ~= entry then tw(selBg, { BackgroundTransparency = 1 }) end end)
        btn.MouseButton1Click:Connect(function() doTabSwitch(entry) end)

        -- Horizontal button events
        hBtn.MouseEnter:Connect(function() if activeTab ~= entry then tw(hBg, { BackgroundTransparency = 0.5 }) end end)
        hBtn.MouseLeave:Connect(function() if activeTab ~= entry then tw(hBg, { BackgroundTransparency = 1 }) end end)
        hBtn.MouseButton1Click:Connect(function() doTabSwitch(entry) end)

        return entry, tf
    end

    -- Forward-declared so setTabLayout can call it once settings elements exist
    local applySettingsLayout = nil
    local compactEnabled = false
    
    -- Switch between vertical sidebar and horizontal top bar layout
    local function setTabLayout(horizontal, animate)
        tabBarIsHorizontal = horizontal
        local t = animate and 0.35 or 0
        local ease = Enum.EasingStyle.Quint

        if horizontal then
            -- Hide sidebar, show top bar
            tw(sidebar, { Size = UDim2.new(0, 0, 1, -4) }, t, ease)
            tw(sidebarDivider, { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 4) }, t, ease)
            task.delay(t, function()
                sidebar.Visible = false
                sidebarDivider.Visible = false
            end)
            topTabBar.Visible = true
            topTabBar.BackgroundTransparency = 1
            tw(topTabBar, { BackgroundTransparency = 0 }, t, ease)
            topTabDivider.Visible = true
            topTabDivider.BackgroundTransparency = 1
            tw(topTabDivider, { BackgroundTransparency = 0 }, t, ease)
            tw(contentArea, {
                Size = UDim2.new(1, -4, 1, -TAB_BAR_H - 36),
                Position = UDim2.new(0, 2, 0, TAB_BAR_H + 6)
            }, t, ease)
            tw(statusBar, {
                Size = UDim2.new(1, -4, 0, 28),
                Position = UDim2.new(0, 2, 1, -32)
            }, t, ease)
        else
            -- Show sidebar, hide top bar (respect compact state)
            local targetW = compactEnabled and 52 or 160
            SIDE_W = targetW
            sidebar.Visible = true
            sidebarDivider.Visible = true
            tw(sidebar, { Size = UDim2.new(0, targetW, 1, -4) }, t, ease)
            tw(sidebarDivider, { BackgroundTransparency = 0, Position = UDim2.new(0, targetW, 0, 4) }, t, ease)
            tw(topTabBar, { BackgroundTransparency = 1 }, t, ease)
            tw(topTabDivider, { BackgroundTransparency = 1 }, t, ease)
            task.delay(t, function()
                topTabBar.Visible = false
                topTabDivider.Visible = false
            end)
            tw(contentArea, {
                Size = UDim2.new(1, -targetW - 2, 1, -32),
                Position = UDim2.new(0, targetW + 2, 0, 4)
            }, t, ease)
            tw(statusBar, {
                Size = UDim2.new(1, -targetW - 2, 0, 28),
                Position = UDim2.new(0, targetW + 2, 1, -32)
            }, t, ease)
        end
        
        if applySettingsLayout then applySettingsLayout(horizontal, t, ease) end
    end
    
    -- Settings Panel (sibling of win, not child)
    local settingsPanel = fr(sg, UDim2.new(0, WIN_W, 0, WIN_H), UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2), C.BG, 0, 20)
    settingsPanel.ClipsDescendants = true
    settingsPanel.ZIndex = 100
    settingsPanel.Visible = false
    
    local settingsMainLayer = fr(settingsPanel, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), C.BG, 1, 0)
    settingsMainLayer.ZIndex = 2
    
    local settingsDrag = Instance.new("TextButton")
    settingsDrag.Size = UDim2.new(1, 0, 0, 12)
    settingsDrag.Position = UDim2.new(0, 0, 0, 0)
    settingsDrag.BackgroundTransparency = 1
    settingsDrag.Text = ""
    settingsDrag.ZIndex = 50
    settingsDrag.Parent = settingsMainLayer
    
    local settingsBodyShell = fr(settingsMainLayer, UDim2.new(1, 0, 1, -12), UDim2.new(0, 0, 0, 12), C.BG, 1, 0)
    settingsBodyShell.ZIndex = 2
    
    local settingsLeft = fr(settingsBodyShell, UDim2.new(0, SIDE_W, 1, -4), UDim2.new(0, 0, 0, 4), C.SIDEBAR, 0, 14)
    settingsLeft.ZIndex = 2
    settingsLeft.ClipsDescendants = true
    
    local settingsDivider = fr(settingsBodyShell, UDim2.new(0, 1, 1, -4), UDim2.new(0, SIDE_W, 0, 4), C.DIV)
    
    local catItems = { "General", "Appearance", "Performance", "Keybinds", "Players" }
    local catKeys = { ICON.general, ICON.appearance, ICON.performance, ICON.keyboard, ICON.playerTab }
    local catScroll = Instance.new("ScrollingFrame")
    catScroll.Size = UDim2.new(1, 0, 1, 0)
    catScroll.ZIndex = 2
    catScroll.BackgroundTransparency = 1
    catScroll.BorderSizePixel = 0
    catScroll.ScrollBarThickness = 0
    catScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    catScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    catScroll.Parent = fr(settingsLeft, UDim2.new(1, 0, 1, 0), nil, C.SIDEBAR, 1, 0)
    pad(catScroll, 8, 10, 12, 8)
    
    local catList = Instance.new("UIListLayout")
    catList.SortOrder = Enum.SortOrder.LayoutOrder
    catList.Padding = UDim.new(0, 4)
    catList.Parent = catScroll
    
    local catBtns = {}
    local settingsTabContents = {}
    local activeSettingTab = 1
    
    for i, cat in ipairs(catItems) do
        local cb = Instance.new("TextButton")
        cb.Size = UDim2.new(1, -4, 0, 38)
        cb.LayoutOrder = i
        cb.BackgroundColor3 = C.SEL
        cb.BackgroundTransparency = 1
        cb.Text = ""
        cb.AutoButtonColor = false
        cb.Parent = catScroll
        Instance.new("UICorner").Parent = cb
        
        local selBg = fr(cb, UDim2.new(1, 0, 1, 0), nil, C.SEL, 1, 12)
        local selLine = fr(cb, UDim2.new(0, 4, 0.5, 0), UDim2.new(1, -5, 0.25, 0), C.ACCENT, 1, 4)
        gradV(selLine, C.ACCENT, C.ACCENT2)
        
        local ci = Instance.new("ImageLabel")
        local ciSize = 24
        local ciOffset = 10
        if cat == "Players" then
            ciSize = PLAYERS_TAB_ICON_SIZE
            ciOffset = 10 + math.floor((24 - ciSize) / 2)
        elseif cat == "Performance" then
            ciSize = 27
            ciOffset = 10 + math.floor((24 - ciSize) / 2)
        end
        ci.Size = UDim2.new(0, ciSize, 0, ciSize)
        ci.Position = UDim2.new(0, ciOffset, 0.5, -math.floor(ciSize / 2))
        ci.BackgroundTransparency = 1
        ci.Image = normalizeIconId(catKeys[i]) or ""
        ci.ImageColor3 = C.DIM
        ci.Parent = cb
        
        local namL = lbl(cb, cat, UDim2.new(1, -44, 1, 0), UDim2.new(0, 40, 0, 0), 12, C.DIM)
        catBtns[i] = { btn = cb, icon = ci, lbl = namL, bg = selBg, line = selLine }
        
        local function updateTabVisuals(idx, isActive)
            local btn = catBtns[idx]
            if not btn then return end
            local isCompact = (SIDE_W <= 100)
            if isActive then
                tw(btn.bg, { BackgroundTransparency = 0 }, 0.25, Enum.EasingStyle.Quad)
                tw(btn.line, { BackgroundTransparency = isCompact and 1 or 0, Size = UDim2.new(0, 4, 0.5, 0) }, 0.25, Enum.EasingStyle.Quad)
                tw(btn.lbl, { TextColor3 = C.TEXT }, 0.2, Enum.EasingStyle.Quad)
                tw(btn.icon, { ImageColor3 = C.TEXT, Position = isCompact and UDim2.new(0.5, -12, 0.5, -12) or UDim2.new(0, 14, 0.5, -12) }, 0.25, Enum.EasingStyle.Quad)
            else
                tw(btn.bg, { BackgroundTransparency = 1 }, 0.2, Enum.EasingStyle.Quad)
                tw(btn.line, { BackgroundTransparency = 1, Size = UDim2.new(0, 4, 0, 0) }, 0.15, Enum.EasingStyle.Quad)
                tw(btn.lbl, { TextColor3 = C.DIM }, 0.15, Enum.EasingStyle.Quad)
                tw(btn.icon, { ImageColor3 = C.DIM, Position = isCompact and UDim2.new(0.5, -12, 0.5, -12) or UDim2.new(0, 10, 0.5, -12) }, 0.2, Enum.EasingStyle.Quad)
            end
        end
        
        cb.MouseEnter:Connect(function()
            if activeSettingTab ~= i then
                tw(selBg, { BackgroundTransparency = 0.5 }, 0.15)
            end
        end)
        
        cb.MouseLeave:Connect(function()
            if activeSettingTab ~= i then
                tw(selBg, { BackgroundTransparency = 1 }, 0.15)
            end
        end)
        
        cb.MouseButton1Click:Connect(function()
            if activeSettingTab ~= i then
                local oldIdx = activeSettingTab
                local newContent = settingsTabContents[i]
                local oldContent = settingsTabContents[oldIdx]
                
                updateTabVisuals(oldIdx, false)
                updateTabVisuals(i, true)
                
                if oldContent then
                    tw(oldContent, { Position = UDim2.new(0, -15, 0, 0) }, 0.12, Enum.EasingStyle.Quad)
                    oldContent.Visible = false
                end
                
                newContent.Visible = true
                newContent.Position = UDim2.new(0, 15, 0, 0)
                tw(newContent, { Position = UDim2.new(0, 0, 0, 0) }, 0.15, Enum.EasingStyle.Quad)
                
                activeSettingTab = i
            end
        end)
    end
    
    local sRight = fr(settingsBodyShell, UDim2.new(1, -SIDE_W - 2, 1, -32), UDim2.new(0, SIDE_W + 2, 0, 4), C.CONTENT, 0, 16)
    sRight.ZIndex = 2
    
    local function setSidebarWidth(w, animate)
        SIDE_W = w
        if tabBarIsHorizontal then return end
        local cw = UDim2.new(1, -SIDE_W - 2, 1, -32)
        local cp = UDim2.new(0, SIDE_W + 2, 0, 4)
        local sw = UDim2.new(0, SIDE_W, 1, -4)
        
        local atn = animate and 0.25 or 0
        if sidebar then tw(sidebar, {Size = sw}, atn) end
        if contentArea then tw(contentArea, {Size = cw, Position = cp}, atn) end
        if statusBar then tw(statusBar, {Size = UDim2.new(1, -SIDE_W - 2, 0, 28), Position = UDim2.new(0, SIDE_W + 2, 1, -32)}, atn) end
        if settingsLeft then tw(settingsLeft, {Size = sw}, atn) end
        if sRight then tw(sRight, {Size = cw, Position = cp}, atn) end
        
        local isCompact = (w <= 100)
        local tatn = animate and 0.2 or 0

        -- Hide/show section labels in compact mode
        for _, s in ipairs(sectionLabels or {}) do
            if isCompact then
                tw(s, {TextTransparency = 1}, tatn)
                task.delay(tatn, function() if s then s.Visible = false end end)
            else
                s.Visible = true
                tw(s, {TextTransparency = 0}, tatn)
            end
        end

        for _, t in ipairs(allTabs or {}) do
            if t.lbl then
                if isCompact then
                    tw(t.lbl, {TextTransparency = 1}, tatn)
                    task.delay(tatn, function() if t.lbl then t.lbl.Visible = false end end)
                else
                    t.lbl.Visible = true
                    tw(t.lbl, {TextTransparency = 0}, tatn)
                end
            end
            local isActive = (t.frame and t.frame.Visible)
            if t.line and isActive then
                tw(t.line, {BackgroundTransparency = isCompact and 1 or 0}, tatn)
            end
            if t.ico then
                tw(t.ico, {Position = isCompact and UDim2.new(0.5, -t.iconSize/2, 0.5, -t.iconSize/2) or UDim2.new(0, t.iconX + (isActive and 4 or 0), 0.5, -t.iconSize/2)}, tatn)
            end
        end
        for i, t in ipairs(catBtns or {}) do
            if t.lbl then
                if isCompact then
                    tw(t.lbl, {TextTransparency = 1}, tatn)
                    task.delay(tatn, function() if t.lbl then t.lbl.Visible = false end end)
                else
                    t.lbl.Visible = true
                    tw(t.lbl, {TextTransparency = 0}, tatn)
                end
            end
            local isActive = (i == activeSettingTab)
            if t.line and isActive then
                tw(t.line, {BackgroundTransparency = isCompact and 1 or 0}, tatn)
            end
            if t.icon then
                tw(t.icon, {Position = isCompact and UDim2.new(0.5, -12, 0.5, -12) or UDim2.new(0, 10 + (isActive and 4 or 0), 0.5, -12)}, tatn)
            end
        end
    end
    
    local titleRow = fr(sRight, UDim2.new(1, 0, 0, 40), nil, C.HEADER, 0, 0)
    lbl(titleRow, "Settings", UDim2.new(1, -16, 1, 0), UDim2.new(0, 14, 0, 0), 16, C.TEXT, Enum.Font.GothamBold)
    
    local SCAT_BAR_H = 36
    local settingsCatBar = fr(sRight, UDim2.new(1, 0, 0, SCAT_BAR_H), UDim2.new(0, 0, 0, 40), C.SIDEBAR, 0, 0)
    settingsCatBar.Visible = false
    settingsCatBar.ClipsDescendants = true
    local scatBarScroll = Instance.new("ScrollingFrame")
    scatBarScroll.Size = UDim2.new(1, 0, 1, 0)
    scatBarScroll.BackgroundTransparency = 1
    scatBarScroll.BorderSizePixel = 0
    scatBarScroll.ScrollBarThickness = 0
    scatBarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scatBarScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    scatBarScroll.ScrollingDirection = Enum.ScrollingDirection.X
    scatBarScroll.Parent = settingsCatBar
    pad(scatBarScroll, 6, 6, 4, 4)
    local scatBarLayout = Instance.new("UIListLayout")
    scatBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scatBarLayout.FillDirection = Enum.FillDirection.Horizontal
    scatBarLayout.Padding = UDim.new(0, 4)
    scatBarLayout.Parent = scatBarScroll
    
    local hCatBtns = {}
    for i, cat in ipairs(catItems) do
        local hcBtn = Instance.new("TextButton")
        hcBtn.Size = UDim2.new(0, math.max(#cat * 7 + 36, 70), 1, -8)
        hcBtn.BackgroundTransparency = 1
        hcBtn.Text = ""
        hcBtn.LayoutOrder = i
        hcBtn.Parent = scatBarScroll
        Instance.new("UICorner").Parent = hcBtn
        local hcBg = fr(hcBtn, UDim2.new(1, 0, 1, 0), nil, C.SEL, 1, 10)
        local hcLine = fr(hcBtn, UDim2.new(0.5, 0, 0, 0), UDim2.new(0.25, 0, 1, -3), C.ACCENT, 1, 2)
        gradV(hcLine, C.ACCENT2, C.ACCENT)
        local hcIco = Instance.new("ImageLabel")
        local hcSize = 16
        if cat == "Performance" then hcSize = 19 end
        hcIco.Size = UDim2.new(0, hcSize, 0, hcSize)
        hcIco.Position = UDim2.new(0, 6, 0.5, -math.floor(hcSize / 2))
        hcIco.BackgroundTransparency = 1
        hcIco.Image = normalizeIconId(catKeys[i]) or ""
        hcIco.ScaleType = Enum.ScaleType.Fit
        hcIco.ImageColor3 = C.DIM
        hcIco.Parent = hcBtn
        local hcLbl = lbl(hcBtn, cat, UDim2.new(1, -28, 1, 0), UDim2.new(0, 26, 0, 0), 11, C.DIM, Enum.Font.GothamBold)
        hCatBtns[i] = { btn = hcBtn, bg = hcBg, line = hcLine, ico = hcIco, lbl = hcLbl }
    end
    
    local function updateHCatVisuals()
        for j, hc in ipairs(hCatBtns) do
            if j == activeSettingTab then
                tw(hc.bg, { BackgroundTransparency = 0 }, 0.25)
                tw(hc.line, { BackgroundTransparency = 0, Size = UDim2.new(0.5, 0, 0, 3) }, 0.25)
                tw(hc.ico, { ImageColor3 = C.TEXT }, 0.2)
                tw(hc.lbl, { TextColor3 = C.TEXT }, 0.2)
            else
                tw(hc.bg, { BackgroundTransparency = 1 }, 0.2)
                tw(hc.line, { BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 0, 0) }, 0.15)
                tw(hc.ico, { ImageColor3 = C.DIM }, 0.15)
                tw(hc.lbl, { TextColor3 = C.DIM }, 0.15)
            end
        end
    end
    
    for i, hc in ipairs(hCatBtns) do
        hc.btn.MouseEnter:Connect(function()
            if activeSettingTab ~= i then tw(hc.bg, { BackgroundTransparency = 0.5 }, 0.12) end
        end)
        hc.btn.MouseLeave:Connect(function()
            if activeSettingTab ~= i then tw(hc.bg, { BackgroundTransparency = 1 }, 0.12) end
        end)
        hc.btn.MouseButton1Click:Connect(function()
            if activeSettingTab ~= i then
                local oldContent = settingsTabContents[activeSettingTab]
                local newContent = settingsTabContents[i]
                local oldIdx = activeSettingTab
                activeSettingTab = i
                
                local function updateTabVisuals(idx, isActive)
                    local btn = catBtns[idx]
                    if not btn then return end
                    local isCompact = (SIDE_W <= 100)
                    if isActive then
                        tw(btn.bg, { BackgroundTransparency = 0 }, 0.25)
                        tw(btn.line, { BackgroundTransparency = isCompact and 1 or 0, Size = UDim2.new(0, 4, 0.5, 0) }, 0.25)
                        tw(btn.lbl, { TextColor3 = C.TEXT }, 0.2)
                        tw(btn.icon, { ImageColor3 = C.TEXT }, 0.2)
                    else
                        tw(btn.bg, { BackgroundTransparency = 1 }, 0.2)
                        tw(btn.line, { BackgroundTransparency = 1, Size = UDim2.new(0, 4, 0, 0) }, 0.15)
                        tw(btn.lbl, { TextColor3 = C.DIM }, 0.15)
                        tw(btn.icon, { ImageColor3 = C.DIM }, 0.15)
                    end
                end
                updateTabVisuals(oldIdx, false)
                updateTabVisuals(i, true)
                updateHCatVisuals()
                
                if oldContent then
                    tw(oldContent, { Position = UDim2.new(0, -15, 0, 0) }, 0.12)
                    oldContent.Visible = false
                end
                newContent.Visible = true
                newContent.Position = UDim2.new(0, 15, 0, 0)
                tw(newContent, { Position = UDim2.new(0, 0, 0, 0) }, 0.15)
            end
        end)
    end
    
    local sHolder = fr(sRight, UDim2.new(1, 0, 1, -46), UDim2.new(0, 0, 0, 40), C.CONTENT, 1, 0)
    
    for i = 1, 5 do
        local sScroll = Instance.new("ScrollingFrame")
        sScroll.Size = UDim2.new(1, 0, 1, 0)
        sScroll.ZIndex = 2
        sScroll.BackgroundTransparency = 1
        sScroll.BorderSizePixel = 0
        sScroll.ScrollBarThickness = 0
        sScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        sScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sScroll.Parent = sHolder
        sScroll.Visible = (i == 1)
        pad(sScroll, 10, 18, 10, 10)
        local sLayout = Instance.new("UIListLayout")
        sLayout.SortOrder = Enum.SortOrder.LayoutOrder
        sLayout.Padding = UDim.new(0, 6)
        sLayout.Parent = sScroll
        table.insert(settingsTabContents, sScroll)
        settingsTabs[catItems[i]] = sScroll
    end
    
    applySettingsLayout = function(horizontal, t, ease)
        if horizontal then
            tw(settingsLeft, { Size = UDim2.new(0, 0, 1, -4) }, t, ease)
            tw(settingsDivider, { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 4) }, t, ease)
            task.delay(t, function()
                settingsLeft.Visible = false
                settingsDivider.Visible = false
            end)
            tw(sRight, {
                Size = UDim2.new(1, -4, 1, -32),
                Position = UDim2.new(0, 2, 0, 4)
            }, t, ease)
            settingsCatBar.Visible = true
            settingsCatBar.BackgroundTransparency = 1
            tw(settingsCatBar, { BackgroundTransparency = 0 }, t, ease)
            tw(sHolder, { Size = UDim2.new(1, 0, 1, -46 - SCAT_BAR_H), Position = UDim2.new(0, 0, 0, 40 + SCAT_BAR_H) }, t, ease)
            updateHCatVisuals()
        else
            local targetW = compactEnabled and 52 or 160
            settingsLeft.Visible = true
            settingsDivider.Visible = true
            tw(settingsLeft, { Size = UDim2.new(0, targetW, 1, -4) }, t, ease)
            tw(settingsDivider, { BackgroundTransparency = 0, Position = UDim2.new(0, targetW, 0, 4) }, t, ease)
            tw(settingsCatBar, { BackgroundTransparency = 1 }, t, ease)
            task.delay(t, function() settingsCatBar.Visible = false end)
            tw(sRight, {
                Size = UDim2.new(1, -targetW - 2, 1, -32),
                Position = UDim2.new(0, targetW + 2, 0, 4)
            }, t, ease)
            tw(sHolder, { Size = UDim2.new(1, 0, 1, -46), Position = UDim2.new(0, 0, 0, 40) }, t, ease)
        end
    end
    
    local function addSettingOption(tabName, labelText, hasToggle, callback, initValue)
        local scrollFrame = settingsTabs[tabName]
        if not scrollFrame then return nil end

        local existingChildren = #scrollFrame:GetChildren()
        if existingChildren > 2 then
            local divider = fr(scrollFrame, UDim2.new(1, -10, 0, 1), nil, C.DIV, 0.5, 0)
            divider.LayoutOrder = existingChildren
            divider.Name = "Divider"
            divider.BackgroundTransparency = 1
            tw(divider, { BackgroundTransparency = 0.5 }, 0.3)
        end

        local row = fr(scrollFrame, UDim2.new(1, -10, 0, 40), nil, C.HEADER, 0, 10)
        row.LayoutOrder = #scrollFrame:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        lbl(row, labelText, UDim2.new(1, -70, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)
        if hasToggle then 
            local toggle = mkToggle(row, -56, initValue or false, callback)
            -- Store reference for config loading
            if not _G._MenuToggles then _G._MenuToggles = {} end
            _G._MenuToggles[labelText] = toggle
            return toggle
        end
        return row
    end
    
    -- Default settings options
    addSettingOption("General", "Show FPS counter", true, function(on) fpsLbl.Visible = on end, true)
    addSettingOption("General", "Show ping counter", true, function(on) pingLbl.Visible = on end, true)
    addSettingOption("General", "Show clock", true, function(on) timeLbl.Visible = on end, true)
    addSettingOption("General", "Show watermark", true, function(on) hudBar.Visible = on end, true)
    
    addSettingOption("Appearance", "Compact sidebar", true, function(on)
        compactEnabled = on
        if not tabBarIsHorizontal then
            setSidebarWidth(on and 52 or 160, true)
        end
    end, false)

    -- Tab layout dropdown in settings
    do
        local scrollFrame = settingsTabs["Appearance"]
        if scrollFrame then
            local row = fr(scrollFrame, UDim2.new(1, -10, 0, 40), nil, C.HEADER, 0, 10)
            row.LayoutOrder = #scrollFrame:GetChildren()
            local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
            gradV(stripe, C.ACCENT, C.ACCENT2)
            lbl(row, "Tab layout", UDim2.new(1, -140, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)

            local layoutOptions = {"Vertical", "Horizontal"}
            local selectedIdx = 1
            local ddOpen = false
            local DROP_W = 110

            local layoutDropBtn = Instance.new("TextButton")
            layoutDropBtn.Size = UDim2.new(0, DROP_W, 0, 26)
            layoutDropBtn.Position = UDim2.new(1, -(DROP_W + 10), 0.5, -13)
            layoutDropBtn.BackgroundColor3 = C.DARK
            layoutDropBtn.Text = "Vertical"
            layoutDropBtn.TextColor3 = C.TEXT
            layoutDropBtn.TextSize = 11
            layoutDropBtn.Font = Enum.Font.GothamBold
            layoutDropBtn.Parent = row
            Instance.new("UICorner", layoutDropBtn).CornerRadius = UDim.new(0, 6)
            local ddStroke = Instance.new("UIStroke")
            ddStroke.Color = C.DIV
            ddStroke.Thickness = 1
            ddStroke.Transparency = 0.5
            ddStroke.Parent = layoutDropBtn

            local chevron = Instance.new("ImageLabel")
            chevron.Size = UDim2.new(0, 10, 0, 10)
            chevron.Position = UDim2.new(1, -16, 0.5, -5)
            chevron.BackgroundTransparency = 1
            chevron.Image = "rbxassetid://6031091004"
            chevron.ImageColor3 = C.ACCENT
            chevron.Parent = layoutDropBtn

            local ddPad = Instance.new("UIPadding")
            ddPad.PaddingRight = UDim.new(0, 18)
            ddPad.PaddingLeft = UDim.new(0, 4)
            ddPad.Parent = layoutDropBtn

            layoutDropBtn.MouseEnter:Connect(function()
                tw(layoutDropBtn, { BackgroundColor3 = C.BTN }, 0.12)
                tw(ddStroke, { Color = C.ACCENT, Transparency = 0.3 }, 0.12)
            end)
            layoutDropBtn.MouseLeave:Connect(function()
                tw(layoutDropBtn, { BackgroundColor3 = C.DARK }, 0.12)
                tw(ddStroke, { Color = C.DIV, Transparency = 0.5 }, 0.12)
            end)

            local dropFrame = nil
            local dropShadow = nil
            local closeConn = nil

            local function closeDrop()
                ddOpen = false
                if closeConn then closeConn:Disconnect() closeConn = nil end
                tw(chevron, { Rotation = 0 }, 0.2)
                if dropFrame then
                    tw(dropFrame, { Size = UDim2.new(0, DROP_W, 0, 0), BackgroundTransparency = 1 }, 0.2)
                    local cf = dropFrame
                    local cs = dropShadow
                    dropFrame = nil
                    dropShadow = nil
                    task.delay(0.25, function()
                        if cf then cf:Destroy() end
                        if cs then cs:Destroy() end
                    end)
                end
            end

            local function openDrop()
                if ddOpen then closeDrop() return end
                ddOpen = true
                tw(chevron, { Rotation = 180 }, 0.2)

                local btnPos = layoutDropBtn.AbsolutePosition
                local btnSize = layoutDropBtn.AbsoluteSize
                local dropY = btnPos.Y + btnSize.Y + 4
                local dropX = btnPos.X
                local targetH = #layoutOptions * 30 + 8

                dropShadow = fr(sg, UDim2.new(0, DROP_W, 0, 0), UDim2.new(0, dropX + 2, 0, dropY + 2), Color3.new(0, 0, 0), 0.7, 8)
                dropShadow.ZIndex = 998

                dropFrame = fr(sg, UDim2.new(0, DROP_W, 0, 0), UDim2.new(0, dropX, 0, dropY), C.DARK, 0, 8)
                dropFrame.ZIndex = 1000
                dropFrame.ClipsDescendants = true
                local dStroke = Instance.new("UIStroke")
                dStroke.Color = C.ACCENT
                dStroke.Thickness = 1.5
                dStroke.Transparency = 0.4
                dStroke.Parent = dropFrame

                local dScroll = Instance.new("ScrollingFrame")
                dScroll.Size = UDim2.new(1, -4, 1, -4)
                dScroll.Position = UDim2.new(0, 2, 0, 2)
                dScroll.BackgroundTransparency = 1
                dScroll.BorderSizePixel = 0
                dScroll.ScrollBarThickness = 0
                dScroll.CanvasSize = UDim2.new(0, 0, 0, #layoutOptions * 30)
                dScroll.Parent = dropFrame
                local dList = Instance.new("UIListLayout")
                dList.SortOrder = Enum.SortOrder.LayoutOrder
                dList.Padding = UDim.new(0, 2)
                dList.Parent = dScroll

                for i, opt in ipairs(layoutOptions) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, -4, 0, 28)
                    optBtn.BackgroundColor3 = (i == selectedIdx) and Color3.fromRGB(40, 20, 70) or C.DARK
                    optBtn.Text = opt
                    optBtn.TextColor3 = (i == selectedIdx) and C.TEXT or C.DIM
                    optBtn.TextSize = 11
                    optBtn.Font = Enum.Font.GothamBold
                    optBtn.TextXAlignment = Enum.TextXAlignment.Center
                    optBtn.Parent = dScroll
                    optBtn.LayoutOrder = i
                    optBtn.ZIndex = 1001
                    Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)

                    if i == selectedIdx then
                        local selS = Instance.new("UIStroke")
                        selS.Color = C.ACCENT
                        selS.Thickness = 1
                        selS.Transparency = 0.5
                        selS.Parent = optBtn
                    end

                    optBtn.MouseEnter:Connect(function()
                        if i ~= selectedIdx then tw(optBtn, { BackgroundColor3 = C.BTN, TextColor3 = C.TEXT }, 0.12) end
                    end)
                    optBtn.MouseLeave:Connect(function()
                        if i ~= selectedIdx then tw(optBtn, { BackgroundColor3 = C.DARK, TextColor3 = C.DIM }, 0.12) end
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        tw(optBtn, { BackgroundColor3 = C.ACCENT }, 0.08)
                        task.delay(0.14, function()
                            selectedIdx = i
                            layoutDropBtn.Text = opt
                            setTabLayout(opt == "Horizontal", true)
                            closeDrop()
                        end)
                    end)
                end

                tw(dropShadow, { Size = UDim2.new(0, DROP_W, 0, targetH) }, 0.25, Enum.EasingStyle.Quint)
                tw(dropFrame, { Size = UDim2.new(0, DROP_W, 0, targetH) }, 0.25, Enum.EasingStyle.Quint)

                task.delay(0.1, function()
                    if not ddOpen then return end
                    closeConn = UserInputService.InputBegan:Connect(function(input)
                        if not ddOpen then if closeConn then closeConn:Disconnect() end return end
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            local pos = Vector2.new(input.Position.X, input.Position.Y)
                            local df = dropFrame
                            local bb = layoutDropBtn
                            if not df or not bb then return end
                            local inDrop = pos.X >= df.AbsolutePosition.X and pos.X <= df.AbsolutePosition.X + df.AbsoluteSize.X and
                                           pos.Y >= df.AbsolutePosition.Y and pos.Y <= df.AbsolutePosition.Y + df.AbsoluteSize.Y
                            local inBtn = pos.X >= bb.AbsolutePosition.X and pos.X <= bb.AbsolutePosition.X + bb.AbsoluteSize.X and
                                          pos.Y >= bb.AbsolutePosition.Y and pos.Y <= bb.AbsolutePosition.Y + bb.AbsoluteSize.Y
                            if not inDrop and not inBtn then closeDrop() end
                        end
                    end)
                end)
            end

            layoutDropBtn.MouseButton1Click:Connect(openDrop)
        end
    end

    addSettingOption("Appearance", "Blur background", true, function(on)
        _G._BlurEnabled = on
        if on and isOpen then
            if not blurPart then
                blurPart = Instance.new("BlurEffect")
                blurPart.Size = 0
                blurPart.Parent = Lighting
            end
            tw(blurPart, {Size = 12}, 0.25)
        elseif blurPart then
            tw(blurPart, {Size = 0}, 0.25)
            local currentBlur = blurPart
            task.delay(0.25, function() if currentBlur and not _G._BlurEnabled then currentBlur:Destroy() if blurPart == currentBlur then blurPart = nil end end end)
        end
    end, false)
    
    addSettingOption("Performance", "Lighting preset dim", true, function(on)
        _G._LightingDimEnabled = on
        if on then
            if not _G._OriginalBrightness then
                _G._OriginalBrightness = Lighting.Brightness
                _G._OriginalClockTime = Lighting.ClockTime
            end
            Lighting.Brightness = 0.3
            Lighting.ClockTime = 0
        elseif _G._OriginalBrightness then
            Lighting.Brightness = _G._OriginalBrightness
            Lighting.ClockTime = _G._OriginalClockTime
        end
    end, false)
    addSettingOption("Performance", "Low quality mode", true, function(on)
        if on then
            if not _G._OriginalQualityLevel then _G._OriginalQualityLevel = settings().Rendering.QualityLevel end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        elseif _G._OriginalQualityLevel then
            settings().Rendering.QualityLevel = _G._OriginalQualityLevel
        end
    end, false)
    
    -- ============================================================
    -- PLAYERS TAB (Settings tab #5)
    -- ============================================================
    do
        local playersScroll = settingsTabs["Players"]
        if playersScroll then
            -- Initialize friends list in _G
            if not _G._FriendsList then _G._FriendsList = {} end
            
            -- Friends persistence file
            local friendsFolder = "MenuLibConfigs"
            local friendsFile = friendsFolder .. "/" .. tostring(lp.UserId) .. "_friends.json"
            
            local function SaveFriendsToFile()
                if makefolder and not isfolder(friendsFolder) then
                    pcall(function() makefolder(friendsFolder) end)
                end
                local success, encoded = pcall(function()
                    return HttpService:JSONEncode(_G._FriendsList)
                end)
                if success and encoded and writefile then
                    pcall(function() writefile(friendsFile, encoded) end)
                end
            end
            
            local function LoadFriendsFromFile()
                if isfile and isfile(friendsFile) then
                    local success, content = pcall(function() return readfile(friendsFile) end)
                    if success and content then
                        local s2, decoded = pcall(function() return HttpService:JSONDecode(content) end)
                        if s2 and decoded and type(decoded) == "table" then
                            _G._FriendsList = decoded
                            return true
                        end
                    end
                end
                return false
            end
            LoadFriendsFromFile()
            
            -- Two-column layout container
            local columnsRow = fr(playersScroll, UDim2.new(1, -10, 1, -10), nil, C.CONTENT, 1, 0)
            columnsRow.LayoutOrder = 1
            
            -- ===== LEFT COLUMN: Player List =====
            local leftCol = fr(columnsRow, UDim2.new(0.5, -4, 1, 0), UDim2.new(0, 0, 0, 0), C.HEADER, 0, 12)
            
            -- Header
            local leftHeader = fr(leftCol, UDim2.new(1, 0, 0, 36), nil, C.DARK, 0, UDim.new(0, 12))
            lbl(leftHeader, "Players", UDim2.new(0, 80, 1, 0), UDim2.new(0, 12, 0, 0), 14, C.TEXT, Enum.Font.GothamBold)
            local playerCountLbl = lbl(leftHeader, "0", UDim2.new(0, 30, 0, 18), UDim2.new(0, 80, 0.5, -9), 10, C.ACCENT, Enum.Font.GothamBold)
            playerCountLbl.BackgroundColor3 = C.SEL
            playerCountLbl.BackgroundTransparency = 0
            playerCountLbl.TextXAlignment = Enum.TextXAlignment.Center
            Instance.new("UICorner", playerCountLbl).CornerRadius = UDim.new(0, 6)
            
            -- Search bar (players)
            local playerSearchBar = fr(leftCol, UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 42), C.SEL, 0, 8)
            local playerSearchIcon = Instance.new("ImageLabel")
            playerSearchIcon.Size = UDim2.new(0, 14, 0, 14)
            playerSearchIcon.Position = UDim2.new(0, 8, 0.5, -7)
            playerSearchIcon.BackgroundTransparency = 1
            playerSearchIcon.Image = "rbxassetid://6031154871"
            playerSearchIcon.ImageColor3 = C.DIM
            playerSearchIcon.Parent = playerSearchBar
            
            local playerSearchBox = Instance.new("TextBox")
            playerSearchBox.Size = UDim2.new(1, -30, 1, 0)
            playerSearchBox.Position = UDim2.new(0, 26, 0, 0)
            playerSearchBox.BackgroundTransparency = 1
            playerSearchBox.Text = ""
            playerSearchBox.TextColor3 = C.TEXT
            playerSearchBox.PlaceholderText = "Search players..."
            playerSearchBox.PlaceholderColor3 = C.DIM
            playerSearchBox.TextSize = 11
            playerSearchBox.Font = Enum.Font.Gotham
            playerSearchBox.ClearTextOnFocus = false
            playerSearchBox.TextXAlignment = Enum.TextXAlignment.Left
            playerSearchBox.Parent = playerSearchBar
            
            -- Player list scroll
            local playerListScroll = Instance.new("ScrollingFrame")
            playerListScroll.Size = UDim2.new(1, -16, 1, -80)
            playerListScroll.Position = UDim2.new(0, 8, 0, 76)
            playerListScroll.BackgroundTransparency = 1
            playerListScroll.BorderSizePixel = 0
            playerListScroll.ScrollBarThickness = 3
            playerListScroll.ScrollBarImageColor3 = C.ACCENT
            playerListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            playerListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            playerListScroll.Parent = leftCol
            
            local playerListLayout = Instance.new("UIListLayout")
            playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            playerListLayout.Padding = UDim.new(0, 3)
            playerListLayout.Parent = playerListScroll
            
            -- ===== RIGHT COLUMN: Friends List =====
            local rightCol = fr(columnsRow, UDim2.new(0.5, -4, 1, 0), UDim2.new(0.5, 4, 0, 0), C.HEADER, 0, 12)
            
            -- Header
            local rightHeader = fr(rightCol, UDim2.new(1, 0, 0, 36), nil, C.DARK, 0, UDim.new(0, 12))
            lbl(rightHeader, "Friends", UDim2.new(0, 80, 1, 0), UDim2.new(0, 12, 0, 0), 14, C.TEXT, Enum.Font.GothamBold)
            local friendCountLbl = lbl(rightHeader, "0", UDim2.new(0, 30, 0, 18), UDim2.new(0, 80, 0.5, -9), 10, C.GREEN, Enum.Font.GothamBold)
            friendCountLbl.BackgroundColor3 = C.SEL
            friendCountLbl.BackgroundTransparency = 0
            friendCountLbl.TextXAlignment = Enum.TextXAlignment.Center
            Instance.new("UICorner", friendCountLbl).CornerRadius = UDim.new(0, 6)
            
            -- Search bar (friends)
            local friendSearchBar = fr(rightCol, UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 42), C.SEL, 0, 8)
            local friendSearchIcon = Instance.new("ImageLabel")
            friendSearchIcon.Size = UDim2.new(0, 14, 0, 14)
            friendSearchIcon.Position = UDim2.new(0, 8, 0.5, -7)
            friendSearchIcon.BackgroundTransparency = 1
            friendSearchIcon.Image = "rbxassetid://6031154871"
            friendSearchIcon.ImageColor3 = C.DIM
            friendSearchIcon.Parent = friendSearchBar
            
            local friendSearchBox = Instance.new("TextBox")
            friendSearchBox.Size = UDim2.new(1, -30, 1, 0)
            friendSearchBox.Position = UDim2.new(0, 26, 0, 0)
            friendSearchBox.BackgroundTransparency = 1
            friendSearchBox.Text = ""
            friendSearchBox.TextColor3 = C.TEXT
            friendSearchBox.PlaceholderText = "Search friends..."
            friendSearchBox.PlaceholderColor3 = C.DIM
            friendSearchBox.TextSize = 11
            friendSearchBox.Font = Enum.Font.Gotham
            friendSearchBox.ClearTextOnFocus = false
            friendSearchBox.TextXAlignment = Enum.TextXAlignment.Left
            friendSearchBox.Parent = friendSearchBar
            
            -- Friends list scroll
            local friendListScroll = Instance.new("ScrollingFrame")
            friendListScroll.Size = UDim2.new(1, -16, 1, -80)
            friendListScroll.Position = UDim2.new(0, 8, 0, 76)
            friendListScroll.BackgroundTransparency = 1
            friendListScroll.BorderSizePixel = 0
            friendListScroll.ScrollBarThickness = 3
            friendListScroll.ScrollBarImageColor3 = C.GREEN
            friendListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            friendListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            friendListScroll.Parent = rightCol
            
            local friendListLayout = Instance.new("UIListLayout")
            friendListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            friendListLayout.Padding = UDim.new(0, 3)
            friendListLayout.Parent = friendListScroll
            
            -- Forward-declare refresh functions
            local refreshPlayerList, refreshFriendList
            
            -- ===== REFRESH FRIENDS LIST =====
            refreshFriendList = function(filter)
                for _, child in ipairs(friendListScroll:GetChildren()) do
                    if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                        child:Destroy()
                    end
                end
                local count = 0
                local filterLower = filter and filter:lower() or ""
                
                for _, friendName in ipairs(_G._FriendsList or {}) do
                    if filterLower == "" or friendName:lower():find(filterLower, 1, true) then
                        count = count + 1
                        local row = fr(friendListScroll, UDim2.new(1, 0, 0, 36), nil, C.SEL, 0, 8)
                        row.LayoutOrder = count
                        
                        -- Friend avatar
                        local avFrame = fr(row, UDim2.new(0, 26, 0, 26), UDim2.new(0, 6, 0.5, -13), C.DARK, 0, 13)
                        local avFImg = Instance.new("ImageLabel")
                        avFImg.Size = UDim2.new(1, -4, 1, -4)
                        avFImg.Position = UDim2.new(0, 2, 0, 2)
                        avFImg.BackgroundTransparency = 1
                        avFImg.Parent = avFrame
                        Instance.new("UICorner", avFImg).CornerRadius = UDim.new(1, 0)
                        
                        -- Try to get avatar
                        task.spawn(function()
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p.Name == friendName then
                                    local ok2, url2 = pcall(function()
                                        return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                                    end)
                                    if ok2 and url2 then avFImg.Image = url2 end
                                    return
                                end
                            end
                        end)
                        
                        -- Name label
                        local fNameLbl = lbl(row, friendName, UDim2.new(1, -100, 1, 0), UDim2.new(0, 38, 0, 0), 11, C.TEXT, Enum.Font.GothamBold)
                        fNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                        
                        -- Online indicator
                        local isOnline = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p.Name == friendName then isOnline = true break end
                        end
                        local onlineDot = fr(row, UDim2.new(0, 8, 0, 8), UDim2.new(0, 38, 0, 4), isOnline and C.GREEN or C.RED, 0, 4)
                        
                        -- Remove button
                        local removeBtn = Instance.new("TextButton")
                        removeBtn.Size = UDim2.new(0, 60, 0, 24)
                        removeBtn.Position = UDim2.new(1, -66, 0.5, -12)
                        removeBtn.BackgroundColor3 = C.RED
                        removeBtn.Text = "Remove"
                        removeBtn.TextColor3 = C.TEXT
                        removeBtn.TextSize = 10
                        removeBtn.Font = Enum.Font.GothamBold
                        removeBtn.AutoButtonColor = false
                        removeBtn.Parent = row
                        Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 6)
                        local remGrad = Instance.new("UIGradient", removeBtn)
                        remGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C.RED), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 45, 45))})
                        remGrad.Rotation = 90
                        
                        removeBtn.MouseEnter:Connect(function() tw(removeBtn, {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}, 0.12) end)
                        removeBtn.MouseLeave:Connect(function() tw(removeBtn, {BackgroundColor3 = C.RED}, 0.12) end)
                        
                        removeBtn.MouseButton1Click:Connect(function()
                            -- Remove from friends list
                            for idx, fn in ipairs(_G._FriendsList) do
                                if fn == friendName then
                                    table.remove(_G._FriendsList, idx)
                                    break
                                end
                            end
                            SaveFriendsToFile()
                            -- Animate removal
                            tw(row, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.15)
                            task.delay(0.15, function()
                                row:Destroy()
                                refreshFriendList(friendSearchBox.Text)
                                refreshPlayerList(playerSearchBox.Text)
                            end)
                        end)
                        
                        -- Hover
                        local rowBtn = Instance.new("TextButton")
                        rowBtn.Size = UDim2.new(1, -70, 1, 0)
                        rowBtn.BackgroundTransparency = 1
                        rowBtn.Text = ""
                        rowBtn.Parent = row
                        rowBtn.MouseEnter:Connect(function() tw(row, {BackgroundColor3 = C.BTNHOV}, 0.1) end)
                        rowBtn.MouseLeave:Connect(function() tw(row, {BackgroundColor3 = C.SEL}, 0.1) end)
                    end
                end
                friendCountLbl.Text = tostring(count)
            end
            
            -- ===== REFRESH PLAYER LIST =====
            refreshPlayerList = function(filter)
                for _, child in ipairs(playerListScroll and playerListScroll:GetChildren() or {}) do
                    if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                        child:Destroy()
                    end
                end
                local count = 0
                local filterLower = filter and filter:lower() or ""
                
                local allPlayers = Players:GetPlayers()
                for _, player in ipairs(allPlayers) do
                    local pName = player.Name
                    if filterLower == "" or pName:lower():find(filterLower, 1, true) then
                        count = count + 1
                        local row = fr(playerListScroll, UDim2.new(1, 0, 0, 36), nil, C.SEL, 0, 8)
                        row.LayoutOrder = count
                        
                        -- Player avatar
                        local avFrame = fr(row, UDim2.new(0, 26, 0, 26), UDim2.new(0, 6, 0.5, -13), C.DARK, 0, 13)
                        local avPImg = Instance.new("ImageLabel")
                        avPImg.Size = UDim2.new(1, -4, 1, -4)
                        avPImg.Position = UDim2.new(0, 2, 0, 2)
                        avPImg.BackgroundTransparency = 1
                        avPImg.Parent = avFrame
                        Instance.new("UICorner", avPImg).CornerRadius = UDim.new(1, 0)
                        
                        task.spawn(function()
                            local ok2, url2 = pcall(function()
                                return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                            end)
                            if ok2 and url2 then avPImg.Image = url2 end
                        end)
                        
                        -- Name
                        local pNameLbl = lbl(row, pName, UDim2.new(1, -100, 1, 0), UDim2.new(0, 38, 0, 0), 11, C.TEXT, Enum.Font.GothamBold)
                        pNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                        
                        -- "You" badge for local player
                        if player == lp then
                            local youBadge = lbl(row, "YOU", UDim2.new(0, 28, 0, 14), UDim2.new(1, -96, 0.5, -7), 9, C.ACCENT, Enum.Font.GothamBold)
                            youBadge.BackgroundColor3 = C.SEL
                            youBadge.BackgroundTransparency = 0
                            youBadge.TextXAlignment = Enum.TextXAlignment.Center
                            Instance.new("UICorner", youBadge).CornerRadius = UDim.new(0, 4)
                        end
                        
                        -- Check if already a friend
                        local isFriend = false
                        for _, fn in ipairs(_G._FriendsList or {}) do
                            if fn == pName then isFriend = true break end
                        end
                        
                        -- Add Friend button (only if not self and not already friend)
                        if player ~= lp then
                            if isFriend then
                                local addedLbl = lbl(row, "âœ“ Friend", UDim2.new(0, 56, 0, 24), UDim2.new(1, -62, 0.5, -12), 10, C.GREEN, Enum.Font.GothamBold)
                                addedLbl.TextXAlignment = Enum.TextXAlignment.Center
                            else
                                local addBtn = Instance.new("TextButton")
                                addBtn.Size = UDim2.new(0, 46, 0, 24)
                                addBtn.Position = UDim2.new(1, -52, 0.5, -12)
                                addBtn.BackgroundColor3 = C.ACCENT
                                addBtn.Text = "Add"
                                addBtn.TextColor3 = C.TEXT
                                addBtn.TextSize = 10
                                addBtn.Font = Enum.Font.GothamBold
                                addBtn.AutoButtonColor = false
                                addBtn.Parent = row
                                Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 6)
                                local addGrad = Instance.new("UIGradient", addBtn)
                                addGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C.ACCENT), ColorSequenceKeypoint.new(1, C.ACCENT2)})
                                addGrad.Rotation = 90
                                
                                addBtn.MouseEnter:Connect(function() tw(addBtn, {BackgroundColor3 = Color3.fromRGB(140, 50, 255)}, 0.12) end)
                                addBtn.MouseLeave:Connect(function() tw(addBtn, {BackgroundColor3 = C.ACCENT}, 0.12) end)
                                
                                addBtn.MouseButton1Click:Connect(function()
                                    -- Add to friends
                                    table.insert(_G._FriendsList, pName)
                                    SaveFriendsToFile()
                                    -- Flash confirmation
                                    tw(addBtn, {BackgroundColor3 = C.GREEN}, 0.1)
                                    addBtn.Text = "âœ“"
                                    task.delay(0.3, function()
                                        refreshPlayerList(playerSearchBox.Text)
                                        refreshFriendList(friendSearchBox.Text)
                                    end)
                                end)
                            end
                        end
                        
                        -- Hover
                        local rowBtn = Instance.new("TextButton")
                        rowBtn.Size = UDim2.new(1, -56, 1, 0)
                        rowBtn.BackgroundTransparency = 1
                        rowBtn.Text = ""
                        rowBtn.Parent = row
                        rowBtn.MouseEnter:Connect(function() tw(row, {BackgroundColor3 = C.BTNHOV}, 0.1) end)
                        rowBtn.MouseLeave:Connect(function() tw(row, {BackgroundColor3 = C.SEL}, 0.1) end)
                    end
                end
                playerCountLbl.Text = tostring(count)
            end
            
            -- Search bar filtering
            playerSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                refreshPlayerList(playerSearchBox.Text)
            end)
            friendSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                refreshFriendList(friendSearchBox.Text)
            end)
            
            -- Auto-refresh when players join/leave
            table.insert(conns, Players.PlayerAdded:Connect(function()
                task.delay(0.5, function() refreshPlayerList(playerSearchBox.Text) end)
            end))
            table.insert(conns, Players.PlayerRemoving:Connect(function()
                task.delay(0.1, function() refreshPlayerList(playerSearchBox.Text) refreshFriendList(friendSearchBox.Text) end)
            end))
            
            -- Initial population
            refreshPlayerList("")
            refreshFriendList("")
        end
    end
    
    -- Keybinds
    local function addKeybindOption(tabName, label, key, onChange)
        local scrollFrame = settingsTabs[tabName]
        local row = fr(scrollFrame, UDim2.new(1, -10, 0, 40), nil, C.HEADER, 0, 10)
        row.LayoutOrder = #scrollFrame:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        lbl(row, label, UDim2.new(1, -100, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)
        local keyBtn = Instance.new("TextButton")
        keyBtn.Size = UDim2.new(0, 70, 0, 26)
        keyBtn.Position = UDim2.new(1, -82, 0.5, -13)
        keyBtn.BackgroundColor3 = C.SEL
        local keyText = ""
        if typeof(key) == "EnumItem" then
            if key.EnumType == Enum.KeyCode then
                keyText = key.Name
            elseif key.EnumType == Enum.UserInputType then
                keyText = key.Name:gsub("MouseButton", "MB")
            end
        else
            keyText = tostring(key)
        end
        keyBtn.Text = keyText
        keyBtn.TextColor3 = C.TEXT
        keyBtn.TextSize = 11
        keyBtn.TextTruncate = Enum.TextTruncate.AtEnd
        keyBtn.Font = Enum.Font.GothamBold
        keyBtn.Parent = row
        Instance.new("UICorner").Parent = keyBtn
        keyBtn.MouseButton1Click:Connect(function()
            keyBtn.Text = "..."
            keyBtn.BackgroundColor3 = C.ACCENT
            _G._SettingKeybind = true
            local conn
            conn = UserInputService.InputBegan:Connect(function(inp, gpe)
                if gpe then return end
                local selectedKey = nil
                local displayText = ""
                if inp.KeyCode and inp.KeyCode ~= Enum.KeyCode.Unknown then
                    selectedKey = inp.KeyCode
                    displayText = inp.KeyCode.Name
                elseif inp.UserInputType and (inp.UserInputType.Name:match("MouseButton") or inp.UserInputType.Name:match("MouseWheel")) then
                    selectedKey = inp.UserInputType
                    displayText = inp.UserInputType.Name:gsub("MouseButton", "MB")
                end
                if selectedKey then
                    conn:Disconnect()
                    keyBtn.Text = displayText
                    keyBtn.BackgroundColor3 = C.SEL
                    onChange(selectedKey)
                    task.defer(function()
                        _G._SettingKeybind = false
                    end)
                end
            end)
            task.delay(5, function()
                if conn.Connected then
                    conn:Disconnect()
                    _G._SettingKeybind = false
                    keyBtn.Text = keyText
                    keyBtn.BackgroundColor3 = C.SEL
                end
            end)
        end)
    end
    
    addKeybindOption("Keybinds", "Toggle menu key", _G._MenuToggleKey, function(k) _G._MenuToggleKey = k end)
    addKeybindOption("Keybinds", "Unload script key", _G._UnloadKey, function(k) _G._UnloadKey = k end)
    
    -- Menu Functions
    local inSettings = false
    local isTransitioning = false
    
    local function openSettings()
        if inSettings or isTransitioning then return end
        inSettings = true
        isTransitioning = true
        _G._MenuOpen = true
        tw(homeBtn, { Rotation = homeBtn.Rotation + 360 }, 0.5)
        tw(homeBtnIcon1, { ImageTransparency = 1 }, 0.25)
        tw(homeBtnIcon2, { ImageTransparency = 0 }, 0.25)
        
        tw(win, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.2)
        task.delay(0.2, function() 
            win.Visible = false 
        end)
        
        settingsPanel.Size = UDim2.new(0, 0, 0, 0)
        settingsPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
        settingsPanel.Visible = true
        tw(settingsPanel, { Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2) }, 0.25)
        activeSettingTab = 1
        for i, content in ipairs(settingsTabContents) do
            content.Visible = (i == 1)
        end
        if catBtns[1] then
            catBtns[1].bg.BackgroundTransparency = 0
            catBtns[1].line.BackgroundTransparency = 0
            catBtns[1].line.Size = UDim2.new(0, 4, 0.5, 0)
            catBtns[1].icon.ImageColor3 = C.TEXT
            catBtns[1].icon.Position = UDim2.new(0, 14, 0.5, -12)
            catBtns[1].lbl.TextColor3 = C.TEXT
        end
        for i = 2, #catBtns do
            catBtns[i].bg.BackgroundTransparency = 1
            catBtns[i].line.BackgroundTransparency = 1
            catBtns[i].line.Size = UDim2.new(0, 4, 0, 0)
            catBtns[i].icon.ImageColor3 = C.DIM
            catBtns[i].icon.Position = UDim2.new(0, 10, 0.5, -12)
            catBtns[i].lbl.TextColor3 = C.DIM
        end
        task.delay(0.25, function() isTransitioning = false end)
    end
    
    local function closeSettings()
        if not inSettings or isTransitioning then return end
        inSettings = false
        isTransitioning = true
        _G._MenuOpen = true
        tw(homeBtn, { Rotation = homeBtn.Rotation - 360 }, 0.5)
        tw(homeBtnIcon1, { ImageTransparency = 0 }, 0.25)
        tw(homeBtnIcon2, { ImageTransparency = 1 }, 0.25)
        
        tw(settingsPanel, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.2)
        task.delay(0.2, function() 
            settingsPanel.Visible = false 
        end)
        
        win.Size = UDim2.new(0, 0, 0, 0)
        win.Position = UDim2.new(0.5, 0, 0.5, 0)
        win.Visible = true
        tw(win, { Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2) }, 0.25)
        task.delay(0.25, function() isTransitioning = false end)
    end
    
    local function closeMenu()
        if not win.Visible and not settingsPanel.Visible then return end
        isOpen = false
        _G._MenuOpen = false
        -- Close any open dropdowns
        for _, closer in ipairs(activeDropdownClosers) do
            pcall(closer)
        end
        if blurPart and _G._BlurEnabled then
            tw(blurPart, {Size = 0}, 0.15)
            local currentBlur = blurPart
            task.delay(0.15, function() if currentBlur then currentBlur:Destroy() if blurPart == currentBlur then blurPart = nil end end end)
        end
        if inSettings then
            unlockInput()
            tw(settingsPanel, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.15)
            task.delay(0.15, function()
                settingsPanel.Visible = false
            end)
        else
            unlockInput()
            tw(win, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.15)
            task.delay(0.15, function()
                win.Visible = false
            end)
        end
    end
    
    local function openMenu()
        if not win or not settingsPanel then return end
        if win.Visible or settingsPanel.Visible then return end
        isOpen = true
        _G._MenuOpen = true
        lockInput()
        if hudBar then hudBar.Visible = true end
        if _G._BlurEnabled then
            if not blurPart then
                blurPart = Instance.new("BlurEffect")
                blurPart.Size = 0
                blurPart.Parent = Lighting
            end
            tw(blurPart, {Size = 12}, 0.25)
        end
        if inSettings then
            settingsPanel.Visible = true
            settingsPanel.Size = UDim2.new(0, 0, 0, 0)
            settingsPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
            tw(settingsPanel, { Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2) }, 0.22)
        else
            win.Visible = true
            win.Size = UDim2.new(0, 0, 0, 0)
            win.Position = UDim2.new(0.5, 0, 0.5, 0)
            tw(win, { Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2) }, 0.22)
        end
    end
    
    local function toggleMenu()
        if isOpen then
            closeMenu()
        else
            openMenu()
        end
    end
    
    fireClick.MouseButton1Click:Connect(toggleMenu)
    
    homeBtn.MouseButton1Click:Connect(function()
        if inSettings then
            closeSettings()
        else
            openSettings()
        end
    end)
    
    homeBtn.MouseEnter:Connect(function() tw(homeBtn, { BackgroundTransparency = 0.05 }, 0.12) end)
    homeBtn.MouseLeave:Connect(function() tw(homeBtn, { BackgroundTransparency = 0.2 }, 0.12) end)
    
    -- Dragging
    local dragging = false
    local dragOrig = Vector2.zero
    local winOrig = UDim2.new()
    local settingsOrig = UDim2.new()
    local dragTarget = nil
    
    dragHandle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragTarget = "main"
            dragOrig = Vector2.new(inp.Position.X, inp.Position.Y)
            if win then
                win.Size = UDim2.new(0, win.AbsoluteSize.X, 0, win.AbsoluteSize.Y)
                win.Position = UDim2.new(0, win.AbsolutePosition.X, 0, win.AbsolutePosition.Y)
                winOrig = win.Position
            end
        end
    end)
    
    dragHandle.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragTarget = nil
        end
    end)
    
    settingsDrag.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragTarget = "settings"
            dragOrig = Vector2.new(inp.Position.X, inp.Position.Y)
            if settingsPanel then
                settingsPanel.Size = UDim2.new(0, settingsPanel.AbsoluteSize.X, 0, settingsPanel.AbsoluteSize.Y)
                settingsPanel.Position = UDim2.new(0, settingsPanel.AbsolutePosition.X, 0, settingsPanel.AbsolutePosition.Y)
                settingsOrig = settingsPanel.Position
            end
        end
    end)
    
    settingsDrag.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragTarget = nil
        end
    end)
    
    -- HUD Layout
    local function updateHudLayout(animate)
        local baseX = 48
        local nameWidth = nameLbl and typeof(nameLbl.AbsoluteSize) == "Vector2" and nameLbl.AbsoluteSize.X or 0
        local spacing = 16
        local currentX = baseX
        
        if nameWidth > 0 then 
            currentX = currentX + math.max(70, nameWidth + 8) + spacing 
        else
            currentX = currentX + 70 + spacing
        end
        
        local function applyLayout(obj, isVisible, targetX, yOffset)
            if not obj then return currentX end
            if isVisible then
                obj.Visible = true
                if animate then
                    tw(obj, { Position = UDim2.new(0, targetX, 0.5, yOffset or -10) }, 0.2)
                else
                    obj.Position = UDim2.new(0, targetX, 0.5, yOffset or -10)
                end
                return targetX + (obj and typeof(obj.AbsoluteSize) == "Vector2" and obj.AbsoluteSize.X or 0) + spacing
            else
                obj.Visible = false
                return targetX
            end
        end

        local function applyDiv(divObj, isVisible, targetX)
            if isVisible then
                divObj.Visible = true
                if animate then
                    tw(divObj, { Position = UDim2.new(0, targetX - (spacing/2) - 1, 0.5, -9) }, 0.2)
                else
                    divObj.Position = UDim2.new(0, targetX - (spacing/2) - 1, 0.5, -9)
                end
            else
                divObj.Visible = false
            end
        end

        if fpsLbl.Visible then
            applyDiv(div1, true, currentX)
            currentX = applyLayout(fpsLbl, true, currentX, -10)
        else
            applyDiv(div1, false, currentX)
        end

        if pingLbl.Visible then
            applyDiv(div2, true, currentX)
            currentX = applyLayout(pingLbl, true, currentX, -10)
        else
            applyDiv(div2, false, currentX)
        end

        if timeLbl.Visible then
            applyDiv(div3, true, currentX)
            currentX = applyLayout(timeLbl, true, currentX, -8)
        else
            applyDiv(div3, false, currentX)
        end

        applyDiv(div4, true, currentX)
        currentX = applyLayout(homeBtn, true, currentX, -15)

        applyDiv(div5, true, currentX)
        currentX = applyLayout(badge, true, currentX, -14)

        local targetWidth = currentX + 8
        if animate then
            tw(hudBar, { Size = UDim2.new(0, targetWidth, 0, 44), Position = UDim2.new(0.5, -targetWidth / 2, 0, 10) }, 0.25)
        else
            hudBar.Size = UDim2.new(0, targetWidth, 0, 44)
            hudBar.Position = UDim2.new(0.5, -targetWidth / 2, 0, 10)
        end
    end
    
    task.defer(function() updateHudLayout(false) end)
    table.insert(conns, nameLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, fpsLbl:GetPropertyChangedSignal("Text"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, fpsLbl:GetPropertyChangedSignal("Visible"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, fpsLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, pingLbl:GetPropertyChangedSignal("Visible"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, timeLbl:GetPropertyChangedSignal("Visible"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, pingLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, timeLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))
    
    -- RenderStepped
    local fpsT, fpsN = 0, 0
    
    table.insert(conns, RunService.RenderStepped:Connect(function(dt)
        if unloaded then return end
        fpsT = fpsT + dt
        fpsN = fpsN + 1
        if fpsT >= 0.5 then
            if fpsT > 0 then
                pcall(function() fpsLbl.Text = tostring(math.round(fpsN / fpsT)) .. " FPS" end)
            else
                pcall(function() fpsLbl.Text = "0 FPS" end)
            end
            fpsN = 0
            fpsT = 0
        end
        pcall(function() pingLbl.Text = tostring(math.round(lp:GetNetworkPing() * 1000)) .. " ms" end)
        pcall(function() timeLbl.Text = os.date("%I:%M %p") end)

        if _G._LightingDimEnabled then
            Lighting.Brightness = 0.3
            Lighting.ClockTime = 0
        end

        if dragging and dragTarget then
            local mp = UserInputService:GetMouseLocation()
            if dragTarget == "settings" and settingsPanel then
                pcall(function() settingsPanel.Position = UDim2.new(0, settingsOrig.X.Offset + (mp.X - dragOrig.X), 0, settingsOrig.Y.Offset + (mp.Y - dragOrig.Y)) end)
            elseif dragTarget == "main" and win then
                pcall(function() win.Position = UDim2.new(0, winOrig.X.Offset + (mp.X - dragOrig.X), 0, winOrig.Y.Offset + (mp.Y - dragOrig.Y)) end)
            end
        end
    end))
    
    -- Input Handler
    table.insert(conns, UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        local toggleKey = _G._MenuToggleKey or Enum.KeyCode.Insert
        local unloadKey = _G._UnloadKey or Enum.KeyCode.Delete
        
        if inp.KeyCode == toggleKey and not _G._SettingKeybind then
            toggleMenu()
        elseif inp.KeyCode == unloadKey and not _G._SettingKeybind then
            -- Flag unloaded immediately to stop all callbacks (both local and global)
            unloaded = true
            _G._UnloadTriggered = true

            -- Disconnect ALL tracked connections first
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
            conns = {}

            -- Unbind RenderStep
            pcall(function() RunService:UnbindFromRenderStep(RS_BIND_INP) end)

            -- Restore input state
            isOpen = false
            pcall(function() controls:Enable() end)
            UserInputService.MouseBehavior = prevMouseBehavior
            UserInputService.MouseIconEnabled = prevMouseIconEnabled

            -- Restore lighting
            if _G._OriginalBrightness then
                Lighting.Brightness = _G._OriginalBrightness
                Lighting.ClockTime = _G._OriginalClockTime
            end

            -- Restore quality
            if _G._OriginalQualityLevel then
                settings().Rendering.QualityLevel = _G._OriginalQualityLevel
            end

            -- Destroy blur
            if blurPart then pcall(function() blurPart:Destroy() end) blurPart = nil end

            -- Destroy the entire GUI
            pcall(function() sg:Destroy() end)

            -- Clean up _G variables
            _G._MenuAutoRefresh = nil
            _G._BlurEnabled = nil
            _G._LightingDimEnabled = nil
            _G._OriginalBrightness = nil
            _G._OriginalClockTime = nil
            _G._OriginalQualityLevel = nil
            _G._MenuToggleKey = nil
            _G._UnloadKey = nil
            _G._SmoothAnimations = nil
            _G._ESPColour = nil
            _G._MenuOpen = nil
            _G._SettingKeybind = nil
            _G._MenuToggles = nil
            _G._MenuSliders = nil
            _G._MenuDropdowns = nil
            _G._ConfigList = nil
            _G._CurrentConfig = nil
            _G._ConfigLoaded = nil
            _G._FriendsList = nil
            _G.GetConfigData = nil
            _G.LoadConfigData = nil
        end
    end))
    
    -- Return API
    local API = {}
    
    API.AddSection = addSection
    
    API.AddTab = function(name, icon, buildFn)
        local tabEntry, contentFrame = addTab(name, icon, buildFn)
        return {
            Content = contentFrame,
            Select = function() 
                if activeTab then activeTab._des() activeTab.frame.Visible = false end
                activeTab = tabEntry
                tabEntry.frame.Visible = true
                tabEntry._sel()
            end
        }
    end
    
    -- Store panel references for tabs that use two-panel layout
    local tabPanels = {}

    -- Helper: find proper container for API element placement
    local function getContainer(tabName, side)
        local tf = tabContents[tabName]
        if not tf then return nil, false end
        local panels = tabPanels[tabName]
        if panels then
            -- Two-panel layout: add directly to the panel (it already has UIListLayout + padding)
            local panel = (side == "right") and panels.rightPanel or panels.leftPanel
            return panel, true
        end
        -- Non-panel tab: find ScrollingFrame, then find/create card inside it
        local scroll = tf:FindFirstChildWhichIsA("ScrollingFrame") or tf
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChildWhichIsA("UIListLayout") then
                return child, false
            end
        end
        -- No card found, create one
        local card = fr(scroll, UDim2.new(1, -4, 0, 0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
        return card, false
    end

    API.AddToggle = function(tabName, label, callback, default, side, reserveColorSlots)
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end

        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1, 0, 0, 40), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        lbl(row, label, UDim2.new(1, reserveColorSlots and -118 or -70, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)
        local toggle = mkToggle(row, -56, default or false, callback)
        toggle.Row = row
        -- Store reference for config loading
        if not _G._MenuToggles then _G._MenuToggles = {} end
        _G._MenuToggles[label] = toggle
        return toggle
    end
    
    API.AddSlider = function(tabName, label, min, max, callback, default, side)
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end

        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1, 0, 0, 50), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        
        lbl(row, label, UDim2.new(1, -20, 0, 20), UDim2.new(0, 14, 0, 4), 12, C.TEXT)
        local valueLbl = lbl(row, tostring(default or min), UDim2.new(0, 40, 0, 20), UDim2.new(1, -50, 0, 4), 12, C.ACCENT, Enum.Font.GothamBold)
        valueLbl.TextXAlignment = Enum.TextXAlignment.Right
        
        local track = fr(row, UDim2.new(1, -28, 0, 6), UDim2.new(0, 14, 0, 28), Color3.fromRGB(40, 20, 70), 0, 3)
        local fill = fr(track, UDim2.new(0, 0, 1, 0), nil, C.ACCENT, 0, 3)
        gradV(fill, C.ACCENT, C.ACCENT2)
        
        local knob = fr(track, UDim2.new(0, 12, 0, 12), nil, C.TEXT, 0, 6)
        
        local value = default or min
        local range = max - min
        
        local function updateVisuals(animate)
            local percent = math.clamp((value - min) / range, 0, 1)
            local targetWidth = UDim2.new(percent, 0, 1, 0)
            local targetPos = UDim2.new(percent, -6, 0, -3)
            if animate then
                tw(fill, { Size = targetWidth }, 0.15)
                tw(knob, { Position = targetPos }, 0.15)
            else
                fill.Size = targetWidth
                knob.Position = targetPos
            end
            valueLbl.Text = tostring(math.round(value))
        end
        
        updateVisuals(false)
        
        local dragging = false
        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                local absX = inp.Position.X - track.AbsolutePosition.X
                local percent = math.clamp(absX / track.AbsoluteSize.X, 0, 1)
                value = min + (percent * range)
                updateVisuals(true)
                if callback then callback(value) end
            end
        end)

        table.insert(conns, UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local absX = inp.Position.X - track.AbsolutePosition.X
                local percent = math.clamp(absX / track.AbsoluteSize.X, 0, 1)
                value = min + (percent * range)
                updateVisuals(true)
                if callback then callback(value) end
            end
        end))

        table.insert(conns, UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end))
        
        local sl = { Get = function() return value end, Set = function(v) value = math.clamp(v, min, max) updateVisuals(true) if callback then callback(value) end end }
        if not _G._MenuSliders then _G._MenuSliders = {} end
        _G._MenuSliders[label] = sl
        return sl
    end
    
    API.AddColorPicker = function(tabName, label, callback, defaultColor, side, compact)
        local compactMode = type(compact) == "table" and compact.Row ~= nil
        local row
        if compactMode then
            row = compact.Row
        else
            local container, isPanel = getContainer(tabName, side)
            if not container then return nil end

            local rowBg = isPanel and C.HEADER or C.SEL
            row = fr(container, UDim2.new(1, 0, 0, 40), nil, rowBg, 0, 10)
            row.LayoutOrder = #container:GetChildren()
            local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
            gradV(stripe, C.ACCENT, C.ACCENT2)
            lbl(row, label, UDim2.new(1, -70, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)
        end

        local color = defaultColor or Color3.fromRGB(255, 255, 255)
        local alpha = 1
        local preview
        local btn = Instance.new("TextButton")
        btn.AutoButtonColor = false
        if compactMode then
            btn.Size = UDim2.fromOffset(16, 16)
            btn.Position = UDim2.new(1, compact.Offset or -96, 0.5, -8)
            btn.BackgroundColor3 = color
            btn.Text = ""
            preview = btn
        else
            preview = fr(row, UDim2.fromOffset(36, 24), UDim2.new(1, -50, 0.5, -12), color, 0, 6)
            btn.Size = UDim2.fromOffset(50, 26)
            btn.Position = UDim2.new(1, -56, 0.5, -13)
            btn.BackgroundColor3 = C.BTN
            btn.Text = "Pick"
        end
        btn.TextColor3 = C.TEXT
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.Parent = row

        local compactCorner = Instance.new("UICorner")
        compactCorner.CornerRadius = compactMode and UDim.new(1, 0) or UDim.new(0, 6)
        compactCorner.Parent = btn

        if compactMode then
            local dotStroke = Instance.new("UIStroke")
            dotStroke.Color = Color3.fromRGB(245, 245, 255)
            dotStroke.Thickness = 1
            dotStroke.Transparency = 0.18
            dotStroke.Parent = btn
        else
            btn.MouseEnter:Connect(function() tw(btn, { BackgroundColor3 = C.BTNHOV }, 0.12) end)
            btn.MouseLeave:Connect(function() tw(btn, { BackgroundColor3 = C.BTN }, 0.12) end)
        end

        local PICKER_W, PICKER_H = 254, 324
        local pickerFrame = nil
        local pickerConnections = {}
        local openRefresh = nil
        local openSync = nil

        local function disconnectPickerConnections()
            for _, connection in ipairs(pickerConnections) do
                pcall(function() connection:Disconnect() end)
            end
            table.clear(pickerConnections)
        end

        local function closePicker()
            disconnectPickerConnections()
            openRefresh = nil
            openSync = nil
            if pickerFrame then
                local closingFrame = pickerFrame
                pickerFrame = nil
                tw(closingFrame, {
                    Size = UDim2.fromOffset(PICKER_W, 0),
                    BackgroundTransparency = 0.15,
                }, 0.14, Enum.EasingStyle.Quint)
                task.delay(0.16, function()
                    if closingFrame then closingFrame:Destroy() end
                end)
            end
        end
        table.insert(activeDropdownClosers, closePicker)

        btn.MouseButton1Click:Connect(function()
            if pickerFrame then
                closePicker()
                return
            end

            for _, closer in ipairs(activeDropdownClosers) do
                if closer ~= closePicker then pcall(closer) end
            end

            local GuiService = game:GetService("GuiService")
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
            local startX = math.floor((viewport.X - PICKER_W) * 0.5)
            local startY = math.floor((viewport.Y - PICKER_H) * 0.5)

            pickerFrame = fr(
                sg,
                UDim2.fromOffset(PICKER_W, 0),
                UDim2.fromOffset(startX, startY),
                C.HEADER,
                0,
                14
            )
            pickerFrame.Name = "ColorPickerV2"
            pickerFrame.ZIndex = 1000
            pickerFrame.ClipsDescendants = true

            local pStroke = Instance.new("UIStroke")
            pStroke.Color = C.ACCENT
            pStroke.Thickness = 1.25
            pStroke.Transparency = 0.28
            pStroke.Parent = pickerFrame

            tw(pickerFrame, { Size = UDim2.fromOffset(PICKER_W, PICKER_H) }, 0.2, Enum.EasingStyle.Quint)

            local function z(object, value)
                object.ZIndex = value
                return object
            end

            local function roundedStroke(object, radius, strokeColor, strokeTransparency, strokeThickness)
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, radius)
                corner.Parent = object
                if strokeColor then
                    local stroke = Instance.new("UIStroke")
                    stroke.Color = strokeColor
                    stroke.Transparency = strokeTransparency or 0
                    stroke.Thickness = strokeThickness or 1
                    stroke.Parent = object
                end
            end

            local function getPointerPosition(input)
                -- Use the same raw screen coordinate space as AbsolutePosition.
                -- Subtracting GuiInset here caused the selector to feel stuck or
                -- offset in several executors and fullscreen configurations.
                if input and input.Position then
                    return Vector2.new(input.Position.X, input.Position.Y)
                end
                return UserInputService:GetMouseLocation()
            end

            -- Draggable title bar so the picker never gets stuck in the middle.
            local header = z(fr(pickerFrame, UDim2.new(1, 0, 0, 34), nil, C.DARK, 0.05, 12), 1001)
            local title = lbl(header, label, UDim2.new(1, -92, 1, 0), UDim2.fromOffset(14, 0), 12, C.TEXT, Enum.Font.GothamBold)
            title.ZIndex = 1002
            title.TextTruncate = Enum.TextTruncate.AtEnd

            local livePreview = z(fr(header, UDim2.fromOffset(22, 22), UDim2.new(1, -58, 0.5, -11), color, 0, 11), 1002)
            roundedStroke(livePreview, 11, Color3.fromRGB(245, 245, 255), 0.25, 1)

            local closeButton = Instance.new("TextButton")
            closeButton.Size = UDim2.fromOffset(24, 24)
            closeButton.Position = UDim2.new(1, -30, 0.5, -12)
            closeButton.BackgroundColor3 = C.BTN
            closeButton.BackgroundTransparency = 0.15
            closeButton.Text = "Ã—"
            closeButton.TextColor3 = C.SEC
            closeButton.TextSize = 18
            closeButton.Font = Enum.Font.GothamBold
            closeButton.AutoButtonColor = false
            closeButton.ZIndex = 1004
            closeButton.Parent = header
            roundedStroke(closeButton, 7, Color3.fromRGB(255, 255, 255), 0.88, 1)
            closeButton.MouseEnter:Connect(function()
                tw(closeButton, { BackgroundColor3 = C.BTNHOV, TextColor3 = C.TEXT }, 0.1)
            end)
            closeButton.MouseLeave:Connect(function()
                tw(closeButton, { BackgroundColor3 = C.BTN, TextColor3 = C.SEC }, 0.1)
            end)
            closeButton.MouseButton1Click:Connect(closePicker)

            local headerDrag = Instance.new("TextButton")
            headerDrag.Size = UDim2.new(1, -88, 1, 0)
            headerDrag.BackgroundTransparency = 1
            headerDrag.Text = ""
            headerDrag.ZIndex = 1003
            headerDrag.Parent = header

            local h, s, v = color:ToHSV()
            local CANVAS_X, CANVAS_Y = 12, 42
            local CANVAS_W, CANVAS_H = PICKER_W - 24, 112

            local svCanvas = z(fr(
                pickerFrame,
                UDim2.fromOffset(CANVAS_W, CANVAS_H),
                UDim2.fromOffset(CANVAS_X, CANVAS_Y),
                Color3.fromHSV(h, 1, 1),
                0,
                8
            ), 1001)
            svCanvas.ClipsDescendants = false
            roundedStroke(svCanvas, 8, Color3.fromRGB(255, 255, 255), 0.72, 1)

            local whiteGradient = Instance.new("UIGradient")
            whiteGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
            whiteGradient.Parent = svCanvas

            local darkOverlay = z(fr(svCanvas, UDim2.fromScale(1, 1), nil, Color3.new(0, 0, 0), 0, 8), 1002)
            local darkGradient = Instance.new("UIGradient")
            darkGradient.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
            darkGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            })
            darkGradient.Rotation = 90
            darkGradient.Parent = darkOverlay

            local svKnob = z(fr(
                svCanvas,
                UDim2.fromOffset(12, 12),
                UDim2.fromOffset(s * CANVAS_W - 6, (1 - v) * CANVAS_H - 6),
                Color3.new(1, 1, 1),
                1,
                6
            ), 1005)
            roundedStroke(svKnob, 6, Color3.fromRGB(255, 255, 255), 0, 2)
            local svKnobInner = z(fr(svKnob, UDim2.fromOffset(6, 6), UDim2.fromOffset(3, 3), color, 0, 3), 1006)

            local svButton = Instance.new("TextButton")
            svButton.Size = UDim2.fromScale(1, 1)
            svButton.BackgroundTransparency = 1
            svButton.Text = ""
            svButton.Active = true
            svButton.ZIndex = 1004
            svButton.Parent = svCanvas

            -- One continuous horizontal hue strip instead of six blocky pieces.
            local hueY = 166
            local hueTrack = z(fr(
                pickerFrame,
                UDim2.fromOffset(CANVAS_W, 14),
                UDim2.fromOffset(CANVAS_X, hueY),
                Color3.new(1, 1, 1),
                0,
                7
            ), 1001)
            hueTrack.ClipsDescendants = false
            roundedStroke(hueTrack, 7, Color3.fromRGB(255, 255, 255), 0.75, 1)

            local hueGradient = Instance.new("UIGradient")
            hueGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            })
            hueGradient.Parent = hueTrack

            local hueKnob = z(fr(
                hueTrack,
                UDim2.fromOffset(12, 20),
                UDim2.new(h, -6, 0.5, -10),
                Color3.new(1, 1, 1),
                1,
                6
            ), 1004)
            roundedStroke(hueKnob, 6, Color3.fromRGB(255, 255, 255), 0, 2)
            local hueKnobInner = z(fr(hueKnob, UDim2.fromOffset(6, 14), UDim2.fromOffset(3, 3), Color3.fromHSV(h, 1, 1), 0, 3), 1005)

            local hueButton = Instance.new("TextButton")
            hueButton.Size = UDim2.new(1, 0, 1, 10)
            hueButton.Position = UDim2.fromOffset(0, -5)
            hueButton.BackgroundTransparency = 1
            hueButton.Text = ""
            hueButton.Active = true
            hueButton.ZIndex = 1003
            hueButton.Parent = hueTrack

            local alphaLabel = lbl(pickerFrame, "Opacity", UDim2.fromOffset(54, 16), UDim2.fromOffset(CANVAS_X, 188), 10, C.DIM, Enum.Font.GothamBold)
            alphaLabel.ZIndex = 1001
            local alphaValue = lbl(pickerFrame, "100%", UDim2.fromOffset(45, 16), UDim2.new(1, -57, 0, 188), 10, C.SEC, Enum.Font.GothamBold)
            alphaValue.TextXAlignment = Enum.TextXAlignment.Right
            alphaValue.ZIndex = 1001

            local alphaY = 205
            local alphaTrack = z(fr(
                pickerFrame,
                UDim2.fromOffset(CANVAS_W, 12),
                UDim2.fromOffset(CANVAS_X, alphaY),
                C.DARK,
                0,
                6
            ), 1001)
            alphaTrack.ClipsDescendants = false
            roundedStroke(alphaTrack, 6, Color3.fromRGB(255, 255, 255), 0.8, 1)

            local alphaInner = z(fr(alphaTrack, UDim2.fromScale(1, 1), nil, C.DARK, 0, 6), 1001)
            alphaInner.ClipsDescendants = true

            local checkerSize = 8
            for x = 0, math.ceil(CANVAS_W / checkerSize) - 1 do
                for y = 0, 1 do
                    z(fr(
                        alphaInner,
                        UDim2.fromOffset(checkerSize, checkerSize),
                        UDim2.fromOffset(x * checkerSize, y * checkerSize - 2),
                        ((x + y) % 2 == 0) and Color3.fromRGB(65, 58, 78) or Color3.fromRGB(25, 21, 34),
                        0,
                        0
                    ), 1001)
                end
            end

            local alphaOverlay = z(fr(alphaInner, UDim2.fromScale(1, 1), nil, color, 0, 6), 1002)
            local alphaGradient = Instance.new("UIGradient")
            alphaGradient.Color = ColorSequence.new(color, color)
            alphaGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            })
            alphaGradient.Parent = alphaOverlay

            local alphaKnob = z(fr(
                alphaTrack,
                UDim2.fromOffset(12, 18),
                UDim2.new(alpha, -6, 0.5, -9),
                Color3.new(1, 1, 1),
                1,
                6
            ), 1004)
            roundedStroke(alphaKnob, 6, Color3.fromRGB(255, 255, 255), 0, 2)

            local alphaButton = Instance.new("TextButton")
            alphaButton.Size = UDim2.new(1, 0, 1, 10)
            alphaButton.Position = UDim2.fromOffset(0, -5)
            alphaButton.BackgroundTransparency = 1
            alphaButton.Text = ""
            alphaButton.Active = true
            alphaButton.ZIndex = 1003
            alphaButton.Parent = alphaTrack

            local inputY = 228
            local channelLabels = { "R", "G", "B", "A" }
            local boxes = {}
            local fieldGap = 6
            local fieldW = math.floor((CANVAS_W - fieldGap * 3) / 4)

            for i, channel in ipairs(channelLabels) do
                local fieldX = CANVAS_X + (i - 1) * (fieldW + fieldGap)
                local field = z(fr(
                    pickerFrame,
                    UDim2.fromOffset(fieldW, 26),
                    UDim2.fromOffset(fieldX, inputY),
                    C.DARK,
                    0,
                    6
                ), 1001)
                roundedStroke(field, 6, Color3.fromRGB(255, 255, 255), 0.88, 1)

                local channelLabel = lbl(field, channel, UDim2.fromOffset(14, 26), UDim2.fromOffset(8, 0), 10, C.DIM, Enum.Font.GothamBold)
                channelLabel.ZIndex = 1002

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(1, -27, 1, 0)
                box.Position = UDim2.fromOffset(24, 0)
                box.BackgroundTransparency = 1
                box.TextColor3 = C.TEXT
                box.PlaceholderColor3 = C.DIM
                box.TextSize = 11
                box.Font = Enum.Font.GothamBold
                box.TextXAlignment = Enum.TextXAlignment.Center
                box.ClearTextOnFocus = true
                box.ZIndex = 1003
                box.Parent = field
                boxes[i] = box
            end

            local presets = {
                Color3.fromRGB(255, 70, 85),
                Color3.fromRGB(255, 170, 45),
                Color3.fromRGB(255, 235, 70),
                Color3.fromRGB(70, 235, 120),
                Color3.fromRGB(65, 220, 255),
                Color3.fromRGB(75, 125, 255),
                Color3.fromRGB(160, 90, 255),
                Color3.fromRGB(235, 75, 190),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(145, 145, 160),
                Color3.fromRGB(25, 25, 32),
                C.ACCENT,
            }

            local swatchY = 266
            local swatchSize = 14
            local swatchGap = math.floor((CANVAS_W - (#presets * swatchSize)) / (#presets - 1))
            for i, presetColor in ipairs(presets) do
                local swatch = Instance.new("TextButton")
                swatch.Size = UDim2.fromOffset(swatchSize, swatchSize)
                local swatchX = CANVAS_X + (i - 1) * (swatchSize + swatchGap)
                local swatchPosition = UDim2.fromOffset(swatchX, swatchY)
                swatch.Position = swatchPosition
                swatch.BackgroundColor3 = presetColor
                swatch.Text = ""
                swatch.AutoButtonColor = false
                swatch.ZIndex = 1002
                swatch.Parent = pickerFrame
                roundedStroke(swatch, 4, Color3.fromRGB(255, 255, 255), 0.72, 1)
                swatch.MouseEnter:Connect(function()
                    tw(swatch, { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(swatchX - 1, swatchY - 1) }, 0.1)
                end)
                swatch.MouseLeave:Connect(function()
                    tw(swatch, { Size = UDim2.fromOffset(14, 14), Position = swatchPosition }, 0.1)
                end)
                swatch.MouseButton1Click:Connect(function()
                    color = presetColor
                    h, s, v = color:ToHSV()
                    if openRefresh then openRefresh(true) end
                end)
            end

            local doneButton = Instance.new("TextButton")
            doneButton.Size = UDim2.fromOffset(CANVAS_W, 24)
            doneButton.Position = UDim2.fromOffset(CANVAS_X, 290)
            doneButton.BackgroundColor3 = C.ACCENT
            doneButton.Text = "Done"
            doneButton.TextColor3 = C.TEXT
            doneButton.TextSize = 11
            doneButton.Font = Enum.Font.GothamBold
            doneButton.AutoButtonColor = false
            doneButton.ZIndex = 1002
            doneButton.Parent = pickerFrame
            roundedStroke(doneButton, 7, nil)
            local doneGradient = Instance.new("UIGradient")
            doneGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, C.ACCENT),
                ColorSequenceKeypoint.new(1, C.ACCENT2),
            })
            doneGradient.Parent = doneButton
            doneButton.MouseEnter:Connect(function() tw(doneButton, { BackgroundTransparency = 0.08 }, 0.1) end)
            doneButton.MouseLeave:Connect(function() tw(doneButton, { BackgroundTransparency = 0 }, 0.1) end)
            doneButton.MouseButton1Click:Connect(closePicker)

            local function refreshInputs()
                boxes[1].Text = tostring(math.round(color.R * 255))
                boxes[2].Text = tostring(math.round(color.G * 255))
                boxes[3].Text = tostring(math.round(color.B * 255))
                boxes[4].Text = tostring(math.round(alpha * 255))
            end

            local function emitColor()
                color = Color3.fromHSV(h, s, v)
                preview.BackgroundColor3 = color
                livePreview.BackgroundColor3 = color
                svKnobInner.BackgroundColor3 = color
                alphaOverlay.BackgroundColor3 = color
                alphaGradient.Color = ColorSequence.new(color, color)
                if callback then callback(color, alpha) end
            end

            local function refreshVisuals(emit)
                svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                whiteGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
                svKnob.Position = UDim2.fromOffset(s * CANVAS_W - 6, (1 - v) * CANVAS_H - 6)
                hueKnob.Position = UDim2.new(h, -6, 0.5, -10)
                hueKnobInner.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                alphaKnob.Position = UDim2.new(alpha, -6, 0.5, -9)
                alphaValue.Text = tostring(math.round(alpha * 100)) .. "%"
                if emit then emitColor() end
                refreshInputs()
            end
            openRefresh = refreshVisuals
            openSync = function(emit)
                h, s, v = color:ToHSV()
                refreshVisuals(emit)
            end
            refreshVisuals(false)

            local activeDrag = nil
            local popupDragging = false
            local popupDragStart = nil
            local popupStartPosition = nil

            local function updateSV(point)
                s = math.clamp((point.X - svCanvas.AbsolutePosition.X) / math.max(svCanvas.AbsoluteSize.X, 1), 0, 1)
                v = 1 - math.clamp((point.Y - svCanvas.AbsolutePosition.Y) / math.max(svCanvas.AbsoluteSize.Y, 1), 0, 1)
                refreshVisuals(true)
            end

            local function updateHue(point)
                h = math.clamp((point.X - hueTrack.AbsolutePosition.X) / math.max(hueTrack.AbsoluteSize.X, 1), 0, 1)
                refreshVisuals(true)
            end

            local function updateAlpha(point)
                alpha = math.clamp((point.X - alphaTrack.AbsolutePosition.X) / math.max(alphaTrack.AbsoluteSize.X, 1), 0, 1)
                refreshVisuals(true)
            end

            local function beginControlDrag(kind, input)
                activeDrag = kind
                local point = getPointerPosition(input)
                if kind == "sv" then
                    updateSV(point)
                elseif kind == "hue" then
                    updateHue(point)
                elseif kind == "alpha" then
                    updateAlpha(point)
                end
            end

            svButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    beginControlDrag("sv", input)
                end
            end)
            hueButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    beginControlDrag("hue", input)
                end
            end)
            alphaButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    beginControlDrag("alpha", input)
                end
            end)

            headerDrag.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    popupDragging = true
                    popupDragStart = getPointerPosition(input)
                    popupStartPosition = Vector2.new(pickerFrame.AbsolutePosition.X, pickerFrame.AbsolutePosition.Y)
                end
            end)

            table.insert(pickerConnections, UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local point = getPointerPosition(input)

                if activeDrag == "sv" then
                    updateSV(point)
                elseif activeDrag == "hue" then
                    updateHue(point)
                elseif activeDrag == "alpha" then
                    updateAlpha(point)
                elseif popupDragging and popupDragStart and popupStartPosition then
                    local delta = point - popupDragStart
                    local newX = popupStartPosition.X + delta.X
                    local newY = popupStartPosition.Y + delta.Y
                    local currentCamera = workspace.CurrentCamera
                    local currentViewport = currentCamera and currentCamera.ViewportSize or viewport
                    newX = math.clamp(newX, 8, math.max(8, currentViewport.X - PICKER_W - 8))
                    newY = math.clamp(newY, 8, math.max(8, currentViewport.Y - PICKER_H - 8))
                    pickerFrame.Position = UDim2.fromOffset(newX, newY)
                end
            end))

            table.insert(pickerConnections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    activeDrag = nil
                    popupDragging = false
                end
            end))

            for i, box in ipairs(boxes) do
                box.FocusLost:Connect(function()
                    local value = tonumber(box.Text)
                    if not value then
                        refreshInputs()
                        return
                    end
                    value = math.clamp(math.round(value), 0, 255)
                    local r = math.round(color.R * 255)
                    local g = math.round(color.G * 255)
                    local b = math.round(color.B * 255)
                    if i == 1 then
                        r = value
                    elseif i == 2 then
                        g = value
                    elseif i == 3 then
                        b = value
                    else
                        alpha = value / 255
                    end
                    color = Color3.fromRGB(r, g, b)
                    h, s, v = color:ToHSV()
                    refreshVisuals(true)
                end)
            end
        end)

        local cp = {
            Get = function()
                return color, alpha
            end,
            Set = function(newColor, newAlpha)
                if typeof(newColor) == "Color3" then
                    color = newColor
                end
                if newAlpha ~= nil then
                    alpha = math.clamp(newAlpha, 0, 1)
                end
                preview.BackgroundColor3 = color
                if openSync then
                    openSync(false)
                end
                if callback then callback(color, alpha) end
            end,
        }
        if not _G._MenuColorPickers then _G._MenuColorPickers = {} end
        _G._MenuColorPickers[label] = cp
        return cp
    end


    -- Toggle row with two compact live color swatches. The left swatch is the
    -- visible color and the right swatch is the occluded/hidden color.
    API.AddColorToggle = function(tabName, label, toggleCallback, defaultState,
        visibleCallback, visibleColor, hiddenCallback, hiddenColor, side)
        local toggle = API.AddToggle(
            tabName,
            label,
            toggleCallback,
            defaultState,
            side,
            true
        )
        if not toggle or not toggle.Row then
            return nil
        end

        local visiblePicker = API.AddColorPicker(
            tabName,
            label .. " Visible",
            visibleCallback,
            visibleColor,
            side,
            { Row = toggle.Row, Offset = -98 }
        )
        local hiddenPicker = API.AddColorPicker(
            tabName,
            label .. " Hidden",
            hiddenCallback,
            hiddenColor,
            side,
            { Row = toggle.Row, Offset = -76 }
        )

        return {
            Toggle = toggle,
            Visible = visiblePicker,
            Hidden = hiddenPicker,
        }
    end
    
    -- ============================================================
    -- FIX 2+3+4: Dropdown â€” rolls DOWN, text centered, smooth anim
    -- ============================================================
    API.AddDropdown = function(tabName, label, options, callback, defaultIndex, side)
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end

        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1, 0, 0, 40), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        
        -- FIX: Wider label gap to accommodate 130px button instead of 110px
        lbl(row, label, UDim2.new(1, -155, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)
        
        local selectedIndex = defaultIndex or 1
        local ddIsOpen = false
        local DROP_W = 130  -- wider button for less wasted space

        -- FIX: Wider button (130px), centered text, right padding to not overlap chevron
        local dropdownBtn = Instance.new("TextButton")
        dropdownBtn.Size = UDim2.new(0, DROP_W, 0, 28)
        dropdownBtn.Position = UDim2.new(1, -(DROP_W + 8), 0.5, -14)
        dropdownBtn.BackgroundColor3 = C.DARK
        dropdownBtn.Text = options[selectedIndex] or "Select"
        dropdownBtn.TextColor3 = C.TEXT
        dropdownBtn.TextSize = 11
        dropdownBtn.Font = Enum.Font.GothamBold
        dropdownBtn.TextXAlignment = Enum.TextXAlignment.Center
        dropdownBtn.TextTruncate = Enum.TextTruncate.AtEnd
        dropdownBtn.Parent = row
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = dropdownBtn

        -- FIX: Right padding so centered text doesn't sit under the chevron
        local btnPad = Instance.new("UIPadding")
        btnPad.PaddingRight = UDim.new(0, 18)
        btnPad.PaddingLeft = UDim.new(0, 4)
        btnPad.Parent = dropdownBtn
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = C.DIV
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.5
        btnStroke.Parent = dropdownBtn
        
        -- Chevron at far right of button
        local chevron = Instance.new("ImageLabel")
        chevron.Size = UDim2.new(0, 10, 0, 10)
        chevron.Position = UDim2.new(1, -16, 0.5, -5)
        chevron.BackgroundTransparency = 1
        chevron.Image = "rbxassetid://6031091004"
        chevron.ImageColor3 = C.ACCENT
        chevron.Parent = dropdownBtn
        
        dropdownBtn.MouseEnter:Connect(function() 
            tw(dropdownBtn, { BackgroundColor3 = C.BTN }, 0.15)
            tw(btnStroke, { Color = C.ACCENT, Transparency = 0.3 }, 0.15)
        end)
        dropdownBtn.MouseLeave:Connect(function() 
            tw(dropdownBtn, { BackgroundColor3 = C.DARK }, 0.15)
            tw(btnStroke, { Color = C.DIV, Transparency = 0.5 }, 0.15)
        end)
        
        local dropdownFrame = nil
        local shadow = nil
        local closeConn = nil
        local optionButtons = {}
        
        local function closeDropdown()
            ddIsOpen = false
            if closeConn then closeConn:Disconnect() closeConn = nil end
            tw(chevron, { Rotation = 0 }, 0.2, Enum.EasingStyle.Quint)
            if shadow then
                tw(shadow, { Size = UDim2.new(0, DROP_W, 0, 0), BackgroundTransparency = 1 }, 0.22, Enum.EasingStyle.Quint)
            end
            if dropdownFrame then
                tw(dropdownFrame, { Size = UDim2.new(0, DROP_W, 0, 0), BackgroundTransparency = 1 }, 0.22, Enum.EasingStyle.Quint)
                local capturedFrame = dropdownFrame
                local capturedShadow = shadow
                dropdownFrame = nil
                shadow = nil
                task.delay(0.25, function()
                    if capturedFrame then capturedFrame:Destroy() end
                    if capturedShadow then capturedShadow:Destroy() end
                end)
            end
            optionButtons = {}
        end
        
        local function openDropdown()
            if ddIsOpen then closeDropdown() return end
            ddIsOpen = true
            
            tw(chevron, { Rotation = 180 }, 0.2)
            
            -- Get button screen position
            local btnAbsPos = dropdownBtn.AbsolutePosition
            local btnAbsSize = dropdownBtn.AbsoluteSize

            -- FIX: Always open BELOW the button
            -- dropY = bottom edge of button + small gap
            local dropY = btnAbsPos.Y + btnAbsSize.Y + 4
            local dropX = btnAbsPos.X

            local targetHeight = math.min(#options * 30 + 12, 150)
            
            -- Shadow (slight offset for depth)
            shadow = fr(sg, UDim2.new(0, DROP_W, 0, 0),
                UDim2.new(0, dropX + 2, 0, dropY + 2), Color3.fromRGB(0, 0, 0), 0.7, 8)
            shadow.ZIndex = 998
            
            -- Main dropdown frame â€” starts at height 0, grows DOWNWARD
            -- FIX: ClipsDescendants = true so contents are hidden until frame reveals them
            dropdownFrame = fr(sg, UDim2.new(0, DROP_W, 0, 0),
                UDim2.new(0, dropX, 0, dropY), C.DARK, 0, 8)
            dropdownFrame.ZIndex = 1000
            dropdownFrame.ClipsDescendants = true  -- KEY FIX: clips children as frame expands down

            local dropStroke = Instance.new("UIStroke")
            dropStroke.Color = C.ACCENT
            dropStroke.Thickness = 1.5
            dropStroke.Transparency = 0.4
            dropStroke.Parent = dropdownFrame

            -- Scroll inside
            local scroll = Instance.new("ScrollingFrame")
            scroll.Size = UDim2.new(1, -4, 1, -8)
            scroll.Position = UDim2.new(0, 2, 0, 4)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.ScrollBarThickness = 2
            scroll.ScrollBarImageColor3 = C.ACCENT
            scroll.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
            scroll.Parent = dropdownFrame
            
            local list = Instance.new("UIListLayout")
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.Padding = UDim.new(0, 2)
            list.Parent = scroll
            
            for i, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, -4, 0, 28)
                -- FIX: selected item highlighted, others dark
                optBtn.BackgroundColor3 = (i == selectedIndex) and Color3.fromRGB(40, 20, 70) or C.DARK
                optBtn.Text = opt
                optBtn.TextColor3 = (i == selectedIndex) and C.TEXT or C.DIM
                optBtn.TextSize = 11
                optBtn.Font = Enum.Font.GothamBold
                -- FIX: Center the text in the option buttons
                optBtn.TextXAlignment = Enum.TextXAlignment.Center
                optBtn.TextTruncate = Enum.TextTruncate.AtEnd
                optBtn.Parent = scroll
                optBtn.LayoutOrder = i
                optBtn.ZIndex = 1001
                local optCorner = Instance.new("UICorner")
                optCorner.CornerRadius = UDim.new(0, 4)
                optCorner.Parent = optBtn

                if i == selectedIndex then
                    local selStroke = Instance.new("UIStroke")
                    selStroke.Color = C.ACCENT
                    selStroke.Thickness = 1
                    selStroke.Transparency = 0.5
                    selStroke.Parent = optBtn
                end
                
                optBtn.MouseEnter:Connect(function()
                    if i ~= selectedIndex then
                        tw(optBtn, { BackgroundColor3 = C.BTN, TextColor3 = C.TEXT }, 0.12)
                    end
                end)
                optBtn.MouseLeave:Connect(function()
                    if i ~= selectedIndex then
                        tw(optBtn, { BackgroundColor3 = C.DARK, TextColor3 = C.DIM }, 0.12)
                    end
                end)
                
                -- FIX: Smooth selection flash animation then close
                optBtn.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        -- Flash accent colour on select for tactile feel
                        tw(optBtn, { BackgroundColor3 = C.ACCENT }, 0.08)
                        task.delay(0.14, function()
                            selectedIndex = i
                            dropdownBtn.Text = opt
                            if callback then callback(opt, i) end
                            closeDropdown()
                        end)
                    end
                end)
                
                table.insert(optionButtons, optBtn)
            end
            
            -- FIX: Animate DOWNWARD â€” top stays fixed, height grows to targetHeight
            tw(shadow, { Size = UDim2.new(0, DROP_W, 0, targetHeight) }, 0.25, Enum.EasingStyle.Quint)
            tw(dropdownFrame, { Size = UDim2.new(0, DROP_W, 0, targetHeight) }, 0.25, Enum.EasingStyle.Quint)
            
            -- Click-outside closes dropdown
            task.delay(0.1, function()
                if not ddIsOpen then return end
                closeConn = UserInputService.InputBegan:Connect(function(input, gpe)
                    if not ddIsOpen then
                        if closeConn then closeConn:Disconnect() closeConn = nil end
                        return
                    end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local pos = Vector2.new(input.Position.X, input.Position.Y)
                        local df = dropdownFrame
                        local bb = dropdownBtn
                        if not df or not bb then return end
                        local dropPos = df.AbsolutePosition
                        local dropSz  = df.AbsoluteSize
                        local btnPos  = bb.AbsolutePosition
                        local btnSz   = bb.AbsoluteSize
                        
                        local inDropdown = pos.X >= dropPos.X and pos.X <= dropPos.X + dropSz.X and
                                          pos.Y >= dropPos.Y and pos.Y <= dropPos.Y + dropSz.Y
                        local inButton   = pos.X >= btnPos.X  and pos.X <= btnPos.X  + btnSz.X  and
                                          pos.Y >= btnPos.Y  and pos.Y <= btnPos.Y  + btnSz.Y
                        
                        if not inDropdown and not inButton then
                            closeDropdown()
                        end
                    end
                end)
            end)
        end
        
        dropdownBtn.MouseButton1Click:Connect(openDropdown)
        table.insert(activeDropdownClosers, closeDropdown)
        
        local dd = { 
            Get = function() return options[selectedIndex], selectedIndex end, 
            Set = function(idx) selectedIndex = idx if options[idx] then dropdownBtn.Text = options[idx] end if callback then callback(options[idx], idx) end end,
            GetOptions = function() return options end,
            SetOptions = function(newOpts) options = newOpts selectedIndex = 1 dropdownBtn.Text = options[1] or "Select" end
        }
        if not _G._MenuDropdowns then _G._MenuDropdowns = {} end
        _G._MenuDropdowns[label] = dd
        return dd
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
        local row = fr(container, UDim2.new(1, 0, 0, 44), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        
        lbl(row, label, UDim2.new(1, -130, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 110, 0, 28)
        btn.Position = UDim2.new(1, -118, 0.5, -14)
        btn.BackgroundColor3 = C.ACCENT
        btn.Text = "Execute"
        btn.TextColor3 = C.TEXT
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.Parent = row
        btn.AutoButtonColor = false
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        local btnGrad = Instance.new("UIGradient")
        btnGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.ACCENT), ColorSequenceKeypoint.new(1, C.ACCENT2) })
        btnGrad.Rotation = 90
        btnGrad.Parent = btn
        
        btn.MouseEnter:Connect(function()
            tw(btn, { BackgroundColor3 = Color3.fromRGB(140, 50, 255) }, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            tw(btn, { BackgroundColor3 = C.ACCENT }, 0.12)
        end)
        
        btn.MouseButton1Click:Connect(function()
            if callback then
                pcall(callback)
            end
        end)
        
        return { Click = function() pcall(callback) end }
    end

    API.AddTextBox = function(tabName, label, callback, defaultText, side)
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end

        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1, 0, 0, 44), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        
        lbl(row, label, UDim2.new(1, -145, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)
        
        local txtBg = fr(row, UDim2.new(0, 120, 0, 28), UDim2.new(1, -128, 0.5, -14), C.BG, 0, 6)
        local stroke = Instance.new("UIStroke")
        stroke.Color = C.HEADER
        stroke.Thickness = 1
        stroke.Parent = txtBg
        
        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(1, -10, 1, 0)
        tb.Position = UDim2.new(0, 5, 0, 0)
        tb.BackgroundTransparency = 1
        tb.Text = tostring(defaultText or "")
        tb.TextColor3 = C.TEXT
        tb.TextSize = 11
        tb.Font = Enum.Font.Gotham
        tb.TextXAlignment = Enum.TextXAlignment.Left
        tb.ClearTextOnFocus = false
        tb.Parent = txtBg
        
        tb.FocusLost:Connect(function()
            if callback then pcall(callback, tb.Text) end
        end)
        
        local entry = { Type = "TextBox", Value = tb.Text, Element = tb, Container = row }
        if not _G._MenuTextBoxes then _G._MenuTextBoxes = {} end
        _G._MenuTextBoxes[label] = entry
        
        return entry
    end
    
    
    API.GetScreenGui = function() return sg end
    API.GetWindow = function() return win end
    API.GetHUD = function() return hudBar end
    
    API.Show = function()
        openMenu()
    end
    
    API.Hide = function()
        closeMenu()
    end
    
    -- Add default tabs (sidebar groups: AIM / VISUALS / MISC)
    addSection("AIM")
    local firstTab = API.AddTab("Aimbot", ICON.aim, function(f)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = f
        pad(scroll, 8, 10, 8, 8)
        
        -- Main card container like Configuration tab
        local card = fr(scroll, UDim2.new(1, -4, 0, 0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
        lbl(card, "Aimbot", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, Enum.Font.GothamBold)
        
        -- Two panel layout (left: main, right: Silent Aim)
        local mainRow = fr(card, UDim2.new(1, 0, 0, 0), nil, C.HEADER, 1, 0)
        mainRow.LayoutOrder = 1
        mainRow.AutomaticSize = Enum.AutomaticSize.Y
        local rowLayout = Instance.new("UIListLayout")
        rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rowLayout.Padding = UDim.new(0, 8)
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.Parent = mainRow
        
        local leftPanel = fr(mainRow, UDim2.new(0.5, -4, 0, 0), UDim2.new(0, 0, 0, 0), C.SEL, 0, 10)
        leftPanel.AutomaticSize = Enum.AutomaticSize.Y
        leftPanel.LayoutOrder = 1
        local leftV = Instance.new("UIListLayout")
        leftV.SortOrder = Enum.SortOrder.LayoutOrder
        leftV.Padding = UDim.new(0, 8)
        leftV.Parent = leftPanel
        pad(leftPanel, 12, 12, 12, 12)
        lbl(leftPanel, "Main", UDim2.new(1, 0, 0, 0), nil, 14, C.TEXT, Enum.Font.GothamBold)
        
        local rightPanel = fr(mainRow, UDim2.new(0.5, -4, 0, 0), UDim2.new(0.5, 4, 0, 0), C.SEL, 0, 10)
        rightPanel.AutomaticSize = Enum.AutomaticSize.Y
        rightPanel.LayoutOrder = 2
        local rightV = Instance.new("UIListLayout")
        rightV.SortOrder = Enum.SortOrder.LayoutOrder
        rightV.Padding = UDim.new(0, 8)
        rightV.Parent = rightPanel
        pad(rightPanel, 12, 12, 12, 12)
        lbl(rightPanel, "Silent Aim", UDim2.new(1, 0, 0, 0), nil, 14, C.TEXT, Enum.Font.GothamBold)
        
        -- Store panels for API use
        tabPanels["Aimbot"] = { leftPanel = leftPanel, rightPanel = rightPanel }
    end)
    RunService.Heartbeat:Wait()
    
    addSection("VISUALS")
    API.AddTab("Visuals", ICON.players, function(f)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = f
        pad(scroll, 8, 10, 8, 8)
        
        -- Main card container like Configuration tab
        local card = fr(scroll, UDim2.new(1, -4, 0, 0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
        lbl(card, "Visuals", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, Enum.Font.GothamBold)
        
        -- Two panel layout (left: ESP, right: Crosshair)
        local mainRow = fr(card, UDim2.new(1, 0, 0, 0), nil, C.HEADER, 1, 0)
        mainRow.LayoutOrder = 1
        mainRow.AutomaticSize = Enum.AutomaticSize.Y
        local rowLayout = Instance.new("UIListLayout")
        rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rowLayout.Padding = UDim.new(0, 8)
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.Parent = mainRow
        
        local leftPanel = fr(mainRow, UDim2.new(0.5, -4, 0, 0), UDim2.new(0, 0, 0, 0), C.SEL, 0, 10)
        leftPanel.AutomaticSize = Enum.AutomaticSize.Y
        leftPanel.LayoutOrder = 1
        local leftV = Instance.new("UIListLayout")
        leftV.SortOrder = Enum.SortOrder.LayoutOrder
        leftV.Padding = UDim.new(0, 8)
        leftV.Parent = leftPanel
        pad(leftPanel, 12, 12, 12, 12)
        
        local rightPanel = fr(mainRow, UDim2.new(0.5, -4, 0, 0), UDim2.new(0.5, 4, 0, 0), C.SEL, 0, 10)
        rightPanel.AutomaticSize = Enum.AutomaticSize.Y
        rightPanel.LayoutOrder = 2
        local rightV = Instance.new("UIListLayout")
        rightV.SortOrder = Enum.SortOrder.LayoutOrder
        rightV.Padding = UDim.new(0, 8)
        rightV.Parent = rightPanel
        pad(rightPanel, 12, 12, 12, 12)
        
        -- Store panels for API use
        tabPanels["Visuals"] = { leftPanel = leftPanel, rightPanel = rightPanel }
    end)
    RunService.Heartbeat:Wait()
    
    API.AddTab("World", ICON.world, function(f)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = f
        pad(scroll, 8, 10, 8, 8)
        
        local card = fr(scroll, UDim2.new(1, -4, 0, 0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
        lbl(card, "World", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, Enum.Font.GothamBold)
    end)
    RunService.Heartbeat:Wait()
    
    API.AddTab("Skin Changer", ICON.skin, function(f)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = C.ACCENT
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = f
        pad(scroll, 8, 10, 8, 8)
        
        local card = fr(scroll, UDim2.new(1, -4, 0, 0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
    end)
    RunService.Heartbeat:Wait()
    
    addSection("MISC")
    API.AddTab("Misc", ICON.misc, function(f)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = f
        pad(scroll, 8, 10, 8, 8)
        
        local card = fr(scroll, UDim2.new(1, -4, 0, 0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
        lbl(card, "Misc", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, Enum.Font.GothamBold)
    end)
    RunService.Heartbeat:Wait()

API.AddTab("Protections", ICON.protection, function(f)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = f
        pad(scroll, 8, 10, 8, 8)
        
        local card = fr(scroll, UDim2.new(1, -4, 0, 0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
        lbl(card, "Protections", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, Enum.Font.GothamBold)
    end)
    RunService.Heartbeat:Wait()
    
    API.AddTab("Exploits", ICON.exploits, function(f)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = f
        pad(scroll, 8, 10, 8, 8)
        
        local card = fr(scroll, UDim2.new(1, -4, 0, 0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
        lbl(card, "Exploits", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, Enum.Font.GothamBold)
    end)
    RunService.Heartbeat:Wait()

    API.AddTab("SFX", ICON.sfx, function(f)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = f
        pad(scroll, 8, 10, 8, 8)
        
        local card = fr(scroll, UDim2.new(1, -4, 0, 0), nil, C.HEADER, 0, 16)
        card.Name = "Card"
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
        lbl(card, "Sound Effects", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, Enum.Font.GothamBold)
    end)
    RunService.Heartbeat:Wait()
    
    API.AddTab("Configuration", ICON.config, function(f)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = f
        pad(scroll, 8, 10, 8, 8)
        
        local card = fr(scroll, UDim2.new(1, -4, 1, -16), nil, C.HEADER, 0, 16)
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
        lbl(card, "Configuration", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, Enum.Font.GothamBold)
        
        -- Config UI - Side by side layout (LEFT: buttons, RIGHT: list) - fills remaining height
        local mainRow = fr(card, UDim2.new(1, 0, 1, -28), nil, C.HEADER, 1, 0)
        mainRow.LayoutOrder = 1
        
        local leftPanel = fr(mainRow, UDim2.new(0.5, -6, 1, 0), UDim2.new(0, 0, 0, 0), C.SEL, 0, 10)
        local rightPanel = fr(mainRow, UDim2.new(0.5, -6, 1, 0), UDim2.new(0.5, 6, 0, 0), C.SEL, 0, 10)
        
        -- LEFT PANEL: Buttons
        local createBtn = Instance.new("TextButton")
        createBtn.Size = UDim2.new(1, -16, 0, 32)
        createBtn.Position = UDim2.new(0, 8, 0, 10)
        createBtn.BackgroundColor3 = C.ACCENT
        createBtn.Text = "Save Config"
        createBtn.TextColor3 = C.TEXT
        createBtn.TextSize = 12
        createBtn.Font = Enum.Font.GothamBold
        createBtn.AutoButtonColor = false
        createBtn.Parent = leftPanel
        Instance.new("UICorner", createBtn).CornerRadius = UDim.new(0, 8)
        local createGrad = Instance.new("UIGradient", createBtn)
        createGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.ACCENT), ColorSequenceKeypoint.new(1, C.ACCENT2) })
        createGrad.Rotation = 90
        
        local loadBtn = Instance.new("TextButton")
        loadBtn.Size = UDim2.new(1, -16, 0, 32)
        loadBtn.Position = UDim2.new(0, 8, 0, 50)
        loadBtn.BackgroundColor3 = C.ACCENT
        loadBtn.Text = "Load Config"
        loadBtn.TextColor3 = C.TEXT
        loadBtn.TextSize = 12
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.AutoButtonColor = false
        loadBtn.Parent = leftPanel
        Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 8)
        local loadGrad = Instance.new("UIGradient", loadBtn)
        loadGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.ACCENT), ColorSequenceKeypoint.new(1, C.ACCENT2) })
        loadGrad.Rotation = 90
        
        -- No status label - removed
        
        -- RIGHT PANEL: Config List
        local listTitle = lbl(rightPanel, "Saved Configs", UDim2.new(1, -16, 0, 20), UDim2.new(0, 10, 0, 8), 12, C.TEXT, Enum.Font.GothamBold)
        
        local configScroll = Instance.new("ScrollingFrame")
        configScroll.Size = UDim2.new(1, -16, 1, -32)
        configScroll.Position = UDim2.new(0, 8, 0, 28)
        configScroll.BackgroundTransparency = 1
        configScroll.BorderSizePixel = 0
        configScroll.ScrollBarThickness = 3
        configScroll.ScrollBarImageColor3 = C.ACCENT
        configScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        configScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        configScroll.Parent = rightPanel
        
        -- FILE PERSISTENCE FOR CONFIGS
        local configFolder = "MenuLibConfigs"
        local configFile = configFolder .. "/" .. tostring(lp.UserId) .. "_configs.json"
        
        -- Load saved configs from file
        local function LoadConfigsFromFile()
            if isfile and isfile(configFile) then
                local success, content = pcall(function()
                    return readfile(configFile)
                end)
                if success and content then
                    local success2, decoded = pcall(function()
                        return HttpService:JSONDecode(content)
                    end)
                    if success2 and decoded then
                        _G._ConfigList = decoded
                        return true
                    end
                end
            end
            _G._ConfigList = _G._ConfigList or {}
            return false
        end
        
        -- Save configs to file
        local function SaveConfigsToFile()
            if not _G._ConfigList then return end
            if makefolder and not isfolder(configFolder) then
                pcall(function() makefolder(configFolder) end)
            end
            local success, encoded = pcall(function()
                return HttpService:JSONEncode(_G._ConfigList)
            end)
            if success and encoded and writefile then
                pcall(function()
                    writefile(configFile, encoded)
                end)
            end
        end
        
        -- Initial load
        LoadConfigsFromFile()
        
        -- Bottom action buttons (Rename/Delete) - always visible at bottom
        local bottomActions = fr(rightPanel, UDim2.new(1, -16, 0, 32), UDim2.new(0, 8, 1, -36), C.SEL, 0, 8)
        bottomActions.ClipsDescendants = false
        
        -- Start visible
        bottomActions.Position = UDim2.new(0, 8, 1, -36)
        
        local renameBtnBottom = Instance.new("TextButton")
        renameBtnBottom.Size = UDim2.new(0.48, 0, 0, 28)
        renameBtnBottom.Position = UDim2.new(0, 0, 0, 0)
        renameBtnBottom.BackgroundColor3 = C.YELLOW
        renameBtnBottom.Text = "Rename"
        renameBtnBottom.TextColor3 = C.TEXT
        renameBtnBottom.TextSize = 11
        renameBtnBottom.Font = Enum.Font.GothamBold
        renameBtnBottom.AutoButtonColor = false
        renameBtnBottom.Parent = bottomActions
        Instance.new("UICorner", renameBtnBottom).CornerRadius = UDim.new(0, 6)
        local renGradB = Instance.new("UIGradient", renameBtnBottom)
        renGradB.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.YELLOW), ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 160, 20)) })
        renGradB.Rotation = 90
        
        local delBtnBottom = Instance.new("TextButton")
        delBtnBottom.Size = UDim2.new(0.48, 0, 0, 28)
        delBtnBottom.Position = UDim2.new(0.52, 0, 0, 0)
        delBtnBottom.BackgroundColor3 = C.RED
        delBtnBottom.Text = "Delete"
        delBtnBottom.TextColor3 = C.TEXT
        delBtnBottom.TextSize = 11
        delBtnBottom.Font = Enum.Font.GothamBold
        delBtnBottom.AutoButtonColor = false
        delBtnBottom.Parent = bottomActions
        Instance.new("UICorner", delBtnBottom).CornerRadius = UDim.new(0, 6)
        local delGradB = Instance.new("UIGradient", delBtnBottom)
        delGradB.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.RED), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 45, 45)) })
        delGradB.Rotation = 90
        
        -- Hide scroll when no selection, adjust size when selected
        local function updateBottomActions()
            if selectedConfig then
                configScroll.Size = UDim2.new(1, -16, 1, -72)
                -- Keep visible
                tw(bottomActions, {Position = UDim2.new(0, 8, 1, -36)}, 0.25, Enum.EasingStyle.Back)
            else
                configScroll.Size = UDim2.new(1, -16, 1, -32)
                -- Keep visible
                tw(bottomActions, {Position = UDim2.new(0, 8, 1, -36)}, 0.2)
            end
        end
        
        local selectedConfig = nil
        local selectedRow = nil
        
        -- CENTERED POPUP OVERLAY (for both create and rename) - ON TOP OF EVERYTHING
        local popupOverlay = fr(sg, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0), 0.6, 0)
        popupOverlay.Visible = false
        popupOverlay.ZIndex = 1000
        popupOverlay.Active = false -- Let mouse pass through for cursor
        
        local popupFrame = fr(popupOverlay, UDim2.new(0, 280, 0, 120), UDim2.new(0.5, -140, 0.5, -60), C.HEADER, 0, 16)
        popupFrame.ZIndex = 101
        
        local popupTitle = lbl(popupFrame, "Enter Config Name", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, 12), 14, C.TEXT, Enum.Font.GothamBold)
        popupTitle.TextXAlignment = Enum.TextXAlignment.Center
        
        local popupBox = Instance.new("TextBox")
        popupBox.Size = UDim2.new(1, -20, 0, 28)
        popupBox.Position = UDim2.new(0, 10, 0, 44)
        popupBox.BackgroundColor3 = C.SEL
        popupBox.TextColor3 = C.TEXT
        popupBox.TextSize = 12
        popupBox.Font = Enum.Font.Gotham
        popupBox.PlaceholderText = "Config name..."
        popupBox.ClearTextOnFocus = false
        popupBox.Parent = popupFrame
        popupBox.ZIndex = 102
        Instance.new("UICorner", popupBox).CornerRadius = UDim.new(0, 8)
        
        local popupBtnRow = fr(popupFrame, UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0, 80), C.HEADER, 1, 0)
        popupBtnRow.ZIndex = 102
        
        local popupConfirm = Instance.new("TextButton")
        popupConfirm.Size = UDim2.new(0.48, 0, 1, 0)
        popupConfirm.Position = UDim2.new(0, 0, 0, 0)
        popupConfirm.BackgroundColor3 = C.GREEN
        popupConfirm.Text = "OK"
        popupConfirm.TextColor3 = C.TEXT
        popupConfirm.TextSize = 12
        popupConfirm.Font = Enum.Font.GothamBold
        popupConfirm.Parent = popupBtnRow
        popupConfirm.ZIndex = 103
        Instance.new("UICorner", popupConfirm).CornerRadius = UDim.new(0, 6)
        local confirmGrad = Instance.new("UIGradient", popupConfirm)
        confirmGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.GREEN), ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 180, 75)) })
        confirmGrad.Rotation = 90
        
        local popupCancel = Instance.new("TextButton")
        popupCancel.Size = UDim2.new(0.48, 0, 1, 0)
        popupCancel.Position = UDim2.new(0.52, 0, 0, 0)
        popupCancel.BackgroundColor3 = C.RED
        popupCancel.Text = "Cancel"
        popupCancel.TextColor3 = C.TEXT
        popupCancel.TextSize = 12
        popupCancel.Font = Enum.Font.GothamBold
        popupCancel.Parent = popupBtnRow
        popupCancel.ZIndex = 103
        Instance.new("UICorner", popupCancel).CornerRadius = UDim.new(0, 6)
        local cancelGrad = Instance.new("UIGradient", popupCancel)
        cancelGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.RED), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 45, 45)) })
        cancelGrad.Rotation = 90
        
        local popupMode = "create" -- "create" or "rename"
        local renameOldName = nil
        
        local function showPopup(mode, title, defaultText)
            popupMode = mode
            popupTitle.Text = title
            popupBox.Text = defaultText or ""
            popupOverlay.Visible = true
            popupOverlay.BackgroundTransparency = 1
            popupFrame.Size = UDim2.new(0, 200, 0, 100)
            popupFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
            tw(popupOverlay, {BackgroundTransparency = 0.6}, 0.2)
            tw(popupFrame, {Size = UDim2.new(0, 280, 0, 120), Position = UDim2.new(0.5, -140, 0.5, -60)}, 0.25, Enum.EasingStyle.Back)
            task.delay(0.15, function() popupBox:CaptureFocus() end)
        end
        
        local function hidePopup()
            tw(popupFrame, {Size = UDim2.new(0, 200, 0, 100), Position = UDim2.new(0.5, -100, 0.5, -50)}, 0.2)
            tw(popupOverlay, {BackgroundTransparency = 1}, 0.2)
            task.delay(0.2, function() popupOverlay.Visible = false end)
        end
        
        local function RefreshConfigList()
            for _, child in ipairs(configScroll:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            selectedConfig = nil
            selectedRow = nil
            
            -- Ensure config list exists
            if not _G._ConfigList then
                _G._ConfigList = {}
            end
            
            -- Reset selection
            selectedConfig = nil
            selectedRow = nil
            
            for name, data in pairs(_G._ConfigList) do
    -- Config row with transparent background
                local row = fr(configScroll, UDim2.new(1, 0, 0, 32), nil, C.SEL, 0.8, 6)
                row.LayoutOrder = #configScroll:GetChildren()
                
                -- Config name label
                local nameLbl = lbl(row, name, UDim2.new(1, -16, 1, 0), UDim2.new(0, 12, 0, 0), 12, C.TEXT, Enum.Font.GothamBold)
                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                
                -- Selection indicator (left stripe)
                local stripe = fr(row, UDim2.new(0, 4, 0.6, 0), UDim2.new(0, 0, 0.2, 0), C.ACCENT, 1, 2)
                gradV(stripe, C.ACCENT, C.ACCENT2)
                
                -- Click to select
                local clickBtn = Instance.new("TextButton")
                clickBtn.Size = UDim2.new(1, 0, 1, 0)
                clickBtn.BackgroundTransparency = 1
                clickBtn.Text = ""
                clickBtn.Parent = row
                
                -- Selection logic with pop animation
                local function selectThis()
                    selectedConfig = name
                    selectedRow = row
                    
                    -- Reset all rows
                    for _, child in ipairs(configScroll:GetChildren()) do
                        if child:IsA("Frame") then
                            tw(child, {BackgroundTransparency = 1}, 0.15)
                            local sInd = child:FindFirstChildOfClass("Frame")
                            if sInd then
                                tw(sInd, {BackgroundTransparency = 1}, 0.15)
                            end
                        end
                    end
                    
                    -- Pop animation - expand then settle
                    row.Size = UDim2.new(1, 0, 0, 38)
                    tw(row, {Size = UDim2.new(1, 0, 0, 32)}, 0.2, Enum.EasingStyle.Back)
                    
                    -- Highlight this row with purple background
                    tw(row, {BackgroundColor3 = C.ACCENT, BackgroundTransparency = 0.3}, 0.2)
                    tw(stripe, {BackgroundTransparency = 0}, 0.25)
                    
                    -- Show bottom buttons
                    updateBottomActions()
                end
                
                clickBtn.MouseButton1Click:Connect(selectThis)
                
                -- Bottom button connections
                renameBtnBottom.MouseButton1Click:Connect(function()
                    if selectedConfig == name then
                        renameOldName = name
                        showPopup("rename", "Rename Config", name)
                    end
                end)
                
                delBtnBottom.MouseButton1Click:Connect(function()
                    if selectedConfig == name and _G._ConfigList then
                        _G._ConfigList[name] = nil
                        SaveConfigsToFile() -- SAVE TO FILE
                        selectedConfig = nil
                        selectedRow = nil
                        updateBottomActions()
                        tw(row, {Size = UDim2.new(1, 0, 0, 0)}, 0.15)
                        task.delay(0.15, function() row:Destroy() end)
                    end
                end)
                
                -- Hover effect
                clickBtn.MouseEnter:Connect(function()
                    if selectedConfig ~= name then
                        tw(row, {BackgroundColor3 = Color3.fromRGB(35, 20, 60)}, 0.1)
                    end
                end)
                clickBtn.MouseLeave:Connect(function()
                    if selectedConfig ~= name then
                        tw(row, {BackgroundTransparency = 1}, 0.1)
                    end
                end)
            end
        end
        
        createBtn.MouseButton1Click:Connect(function()
            showPopup("create", "Create New Config", "")
        end)
        
        popupConfirm.MouseButton1Click:Connect(function()
            local name = popupBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if name == "" then
                hidePopup()
                return
            end
            
            if not _G._ConfigList then _G._ConfigList = {} end
            
            if popupMode == "create" then
                if _G.GetConfigData then
                    _G._ConfigList[name] = _G.GetConfigData()
                    SaveConfigsToFile() -- SAVE TO FILE
                    RefreshConfigList()
                end
            elseif popupMode == "rename" and renameOldName then
                if name == renameOldName then
                    -- Same name, do nothing
                elseif _G._ConfigList[name] then
                    -- Name already exists, do nothing
                else
                    _G._ConfigList[name] = _G._ConfigList[renameOldName]
                    _G._ConfigList[renameOldName] = nil
                    SaveConfigsToFile() -- SAVE TO FILE
                    RefreshConfigList()
                end
            end
            hidePopup()
        end)
        
        popupCancel.MouseButton1Click:Connect(hidePopup)
        
        loadBtn.MouseButton1Click:Connect(function()
            if selectedConfig and _G._ConfigList[selectedConfig] then
                if _G.LoadConfigData then
                    _G.LoadConfigData(_G._ConfigList[selectedConfig])
                    _G._CurrentConfig = selectedConfig
                end
            end
        end)
        
        -- Store all toggle/slider references for config loading
        _G._MenuToggles = {}
        _G._MenuSliders = {}
        _G._MenuDropdowns = {}
        
        -- Ensure config functions exist - MUST be defined BEFORE any UI creation
        if not _G.GetConfigData then
            _G.GetConfigData = function()
                local data = {
                    Toggles = {},
                    Sliders = {},
                    Dropdowns = {},
                    ColorPickers = {}
                }
                if _G._MenuToggles then
                    for label, tog in pairs(_G._MenuToggles) do
                        data.Toggles[label] = tog.Get()
                    end
                end
                if _G._MenuSliders then
                    for label, sl in pairs(_G._MenuSliders) do
                        data.Sliders[label] = sl.Get()
                    end
                end
                if _G._MenuDropdowns then
                    for label, dd in pairs(_G._MenuDropdowns) do
                        local opt, idx = dd.Get()
                        data.Dropdowns[label] = idx
                    end
                end
                if _G._MenuColorPickers then
                    for label, cp in pairs(_G._MenuColorPickers) do
                        local c, a = cp.Get()
                        data.ColorPickers[label] = {r = c.R, g = c.G, b = c.B, a = a}
                    end
                end
                
                if _G._equippedCosmetics then data._equippedCosmetics = _G._equippedCosmetics end
                if _G._favoritedCosmetics then data._favoritedCosmetics = _G._favoritedCosmetics end

                -- Support legacy structure so we don't break Raknet entirely
                data._MenuSettings = {
                    BlurEnabled = _G._BlurEnabled,
                    LightingDimEnabled = _G._LightingDimEnabled,
                    MenuToggleKey = tostring(_G._MenuToggleKey),
                    UnloadKey = tostring(_G._UnloadKey),
                    SmoothAnimations = _G._SmoothAnimations,
                    BoxESPEnabled = _G._BoxESPEnabled,
                    FilledBoxESPEnabled = _G._FilledBoxESPEnabled,
                    ESPColour = _G._ESPColour and {r = _G._ESPColour.R, g = _G._ESPColour.G, b = _G._ESPColour.B} or nil,
                    AimbotEnabled = _G._AimbotEnabled,
                    ShowFOVCircle = _G._ShowFOVCircle,
                    AimbotTargetMode = _G._AimbotTargetMode,
                    AimbotFOV = _G._AimbotFOV,
                    AimbotFOVMode = _G._AimbotFOVMode,
                    AimbotMaxDistance = _G._AimbotMaxDistance,
                    AimbotSmoothness = _G._AimbotSmoothness,
                    TeamCheck = _G._TeamCheck,
                    SilentAimFOV = _G._SilentAimFOV,
                    SilentAimPart = _G._SilentAimPart,
                    SilentAimEnabled = _G._SilentAimEnabled,
                    AimKeybind = _G._AimKeybind and tostring(_G._AimKeybind.Name) or nil,
                    NameESPEnabled = _G._NameESPEnabled,
                    DistanceESPEnabled = _G._DistanceESPEnabled,
                    HealthESPEnabled = _G._HealthESPEnabled,
                    OutlineESPEnabled = _G._OutlineESPEnabled,
                    ChamsEnabled = _G._ChamsEnabled,
                    ChamsMaterialToken = _G._ChamsMaterialToken,
                    WeaponChamsEnabled = _G._WeaponChamsEnabled,
                    HandChamsEnabled = _G._HandChamsEnabled,
                    MaxESPDistance = _G._MaxESPDistance,
                    WorldModulationEnabled = _G._WorldModulationEnabled,
                    WorldTheme = _G._WorldTheme,
                    WorldTimeOfDay = _G._WorldTimeOfDay,
                    WorldBloomIntensity = _G._WorldBloomIntensity,
                    PlayerAura = _G._PlayerAura,
                    SyncESPToTheme = _G._SyncESPToTheme,
                    AntiFlingEnabled = _G._AntiFlingEnabled,
                    AntiKatanaEnabled = _G._AntiKatanaEnabled,
                    ShowFPS = _G._ShowFPS,
                    ShowPing = _G._ShowPing,
                    ShowClock = _G._ShowClock,
                    ShowWatermark = _G._ShowWatermark,
                    CompactSidebar = _G._CompactSidebar,
                    LowQualityMode = _G._LowQualityMode,
                }
                return data
            end
        end
        
        if not _G.LoadConfigData then
            _G.LoadConfigData = function(data)
                if not data then return end
                
                -- Load dynamic UI elements (so the menu updates correctly)
                if data.Toggles and _G._MenuToggles then
                    for label, val in pairs(data.Toggles) do
                        if _G._MenuToggles[label] then _G._MenuToggles[label].Set(val) end
                    end
                end
                if data.Sliders and _G._MenuSliders then
                    for label, val in pairs(data.Sliders) do
                        if _G._MenuSliders[label] then _G._MenuSliders[label].Set(val) end
                    end
                end
                if data.Dropdowns and _G._MenuDropdowns then
                    for label, idx in pairs(data.Dropdowns) do
                        if _G._MenuDropdowns[label] then _G._MenuDropdowns[label].Set(idx) end
                    end
                end
                if data.ColorPickers and _G._MenuColorPickers then
                    for label, val in pairs(data.ColorPickers) do
                        if _G._MenuColorPickers[label] then _G._MenuColorPickers[label].Set(Color3.new(val.r, val.g, val.b), val.a) end
                    end
                end

                if data._equippedCosmetics and _G._equippedCosmetics then
                    table.clear(_G._equippedCosmetics)
                    for k, v in pairs(data._equippedCosmetics) do _G._equippedCosmetics[k] = v end
                elseif data._equippedCosmetics then
                    _G._equippedCosmetics = data._equippedCosmetics
                end
                
                if data._favoritedCosmetics and _G._favoritedCosmetics then
                    table.clear(_G._favoritedCosmetics)
                    for k, v in pairs(data._favoritedCosmetics) do _G._favoritedCosmetics[k] = v end
                elseif data._favoritedCosmetics then
                    _G._favoritedCosmetics = data._favoritedCosmetics
                end

                -- Load ALL legacy global settings
                if data._MenuSettings then
                    local s = data._MenuSettings
                    -- Menu settings
                    _G._BlurEnabled = s.BlurEnabled
                    _G._LightingDimEnabled = s.LightingDimEnabled
                    _G._SmoothAnimations = s.SmoothAnimations
                    if s.MenuToggleKey then pcall(function() _G._MenuToggleKey = Enum.KeyCode[s.MenuToggleKey] end) end
                    if s.UnloadKey then pcall(function() _G._UnloadKey = Enum.KeyCode[s.UnloadKey] end) end
                    -- ESP settings
                    _G._BoxESPEnabled = s.BoxESPEnabled
                    _G._FilledBoxESPEnabled = s.FilledBoxESPEnabled
                    if s.ESPColour then pcall(function() _G._ESPColour = Color3.new(s.ESPColour.r, s.ESPColour.g, s.ESPColour.b) end) end
                    -- Aimbot settings
                    _G._AimbotEnabled = s.AimbotEnabled
                    _G._ShowFOVCircle = s.ShowFOVCircle
                    _G._AimbotTargetMode = s.AimbotTargetMode
                    _G._AimbotFOV = s.AimbotFOV
                    if s.AimbotFOVMode ~= nil then _G._AimbotFOVMode = s.AimbotFOVMode end
                    _G._AimbotMaxDistance = s.AimbotMaxDistance
                    _G._AimbotSmoothness = s.AimbotSmoothness
                    _G._TeamCheck = s.TeamCheck
                    if s.SilentAimFOV ~= nil then _G._SilentAimFOV = s.SilentAimFOV end
                    if s.SilentAimPart ~= nil then _G._SilentAimPart = s.SilentAimPart end
                    if s.SilentAimEnabled ~= nil then _G._SilentAimEnabled = s.SilentAimEnabled end
                    if s.AimKeybind then pcall(function() _G._AimKeybind = Enum.KeyCode[s.AimKeybind] end) end
                    -- More ESP
                    _G._NameESPEnabled = s.NameESPEnabled
                    _G._DistanceESPEnabled = s.DistanceESPEnabled
                    _G._HealthESPEnabled = s.HealthESPEnabled
                    _G._OutlineESPEnabled = s.OutlineESPEnabled
                    _G._ChamsEnabled = s.ChamsEnabled
                    if s.ChamsMaterialToken ~= nil and type(s.ChamsMaterialToken) == "string" then
                        local cmt = s.ChamsMaterialToken
                        if cmt:sub(1, 3) == "MV:" or cmt:sub(1, 5) ~= "ENUM:" then
                            cmt = "ENUM:ForceField"
                        end
                        _G._ChamsMaterialToken = cmt
                    end
                    if _G._ChamsMaterialDropdownSync then
                        pcall(_G._ChamsMaterialDropdownSync)
                    end
                    if s.WeaponChamsEnabled ~= nil then _G._WeaponChamsEnabled = s.WeaponChamsEnabled end
                    if s.HandChamsEnabled ~= nil then _G._HandChamsEnabled = s.HandChamsEnabled end
                    _G._MaxESPDistance = s.MaxESPDistance
                    -- World
                    _G._WorldModulationEnabled = s.WorldModulationEnabled
                    if s.WorldTheme ~= nil then _G._WorldTheme = s.WorldTheme end
                    if s.WorldTimeOfDay ~= nil then _G._WorldTimeOfDay = s.WorldTimeOfDay end
                    if s.WorldBloomIntensity ~= nil then _G._WorldBloomIntensity = s.WorldBloomIntensity end
                    if s.PlayerAura ~= nil then _G._PlayerAura = s.PlayerAura end
                    if s.SyncESPToTheme ~= nil then _G._SyncESPToTheme = s.SyncESPToTheme end
                    -- Protections
                    _G._AntiFlingEnabled = s.AntiFlingEnabled
                    _G._AntiKatanaEnabled = s.AntiKatanaEnabled
                    -- HUD
                    _G._ShowFPS = s.ShowFPS
                    _G._ShowPing = s.ShowPing
                    _G._ShowClock = s.ShowClock
                    _G._ShowWatermark = s.ShowWatermark
                    _G._CompactSidebar = s.CompactSidebar
                    _G._LowQualityMode = s.LowQualityMode
                    
                    -- Trigger config loaded event for external scripts
                    _G._ConfigLoaded = tick()
                end
            end
        end
        
        RefreshConfigList()
    end)
    
    -- Select first tab
    if firstTab and firstTab.Select then
        local success, err = pcall(function()
            firstTab:Select()
        end)
        if not success then
            warn("Menu init error: " .. tostring(err))
        end
    end
    
    -- Window Resizer Grip
    local resizer = Instance.new("TextButton")
    resizer.Size = UDim2.new(0, 20, 0, 20)
    resizer.Position = UDim2.new(1, -20, 1, -20)
    resizer.BackgroundTransparency = 1
    resizer.Text = ""
    resizer.ZIndex = 50
    resizer.Parent = win
    
    local settingsResizer = Instance.new("TextButton")
    settingsResizer.Size = UDim2.new(0, 20, 0, 20)
    settingsResizer.Position = UDim2.new(1, -20, 1, -20)
    settingsResizer.BackgroundTransparency = 1
    settingsResizer.Text = ""
    settingsResizer.ZIndex = 50
    settingsResizer.Parent = settingsPanel
    
    local isResizing = false
    local resizeStartMouse = nil
    local resizeStartW = 0
    local resizeStartH = 0
    
    local function beginResize(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isResizing = true
            resizeStartMouse = UserInputService:GetMouseLocation()
            resizeStartW = WIN_W
            resizeStartH = WIN_H
        end
    end
    resizer.InputBegan:Connect(beginResize)
    settingsResizer.InputBegan:Connect(beginResize)

    table.insert(conns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isResizing = false
        end
    end))

    table.insert(conns, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and isResizing then
            local currMouse = UserInputService:GetMouseLocation()
            local delta = currMouse - resizeStartMouse
            WIN_W = math.max(600, resizeStartW + delta.X * 2)
            WIN_H = math.max(380, resizeStartH + delta.Y * 2)
            
            win.Size = UDim2.new(0, WIN_W, 0, WIN_H)
            win.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
            settingsPanel.Size = UDim2.new(0, WIN_W, 0, WIN_H)
            settingsPanel.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
            
            setSidebarWidth(SIDE_W, false)
        end
    end))

    return API
end

return MenuLib
