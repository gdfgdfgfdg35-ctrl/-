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

    -- Core state and connection tracking
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

    -- Define toggle/close functions early so input handler can use them
    local openMenu, closeMenu, toggleMenu

    local function keyMatches(inp, key)
        if typeof(key) ~= "EnumItem" then return false end
        if key.EnumType == Enum.KeyCode then
            return inp.KeyCode == key
        elseif key.EnumType == Enum.UserInputType then
            return inp.UserInputType == key
        end
        return inp.KeyCode == key
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
            -- cleanup lighting, blur, gui
            if _G._OriginalBrightness then
                Lighting.Brightness = _G._OriginalBrightness
                Lighting.ClockTime = _G._OriginalClockTime
            end
            pcall(function() sg:Destroy() end)
            pcall(function()
                local CoreGui = game:GetService("CoreGui")
                local menuGui = CoreGui and CoreGui:FindFirstChild("RobloxGui") and CoreGui.RobloxGui:FindFirstChild("MenuGui")
                if menuGui then menuGui.Enabled = true end
            end)
        end
    end))

    local pg = lp:FindFirstChild("PlayerGui")
    task.spawn(function()
        if not pg then pg = lp:WaitForChild("PlayerGui", 10) end
        if pg then sg.Parent = pg end
        pcall(function()
            local CoreGui = game:GetService("CoreGui")
            if CoreGui then sg.Parent = CoreGui end
        end)
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
        exploits = "rbxassetid://16149155528",
        config = "rbxassetid://130521044774541",
        general = "rbxassetid://7733765398",
        appearance = "rbxassetid://7347408509",
        performance = "rbxassetid://13321880274",
        keyboard = "rbxassetid://7734022107",
        fire = "rbxassetid://14502433595",
        protection = "rbxassetid://73332630842054",
        skin = "rbxassetid://81837937089566",
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
            -- Animate SIZE instead of transparency — knob and fill move together at exactly the same speed
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
        if iconImage == ICON.aim or iconImage == ICON.players then
            iconSize = 28
            iconX = 2
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
    local catKeys = { ICON.general, ICON.appearance, ICON.performance, ICON.keyboard, ICON.players }
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
        ci.Size = UDim2.new(0, 24, 0, 24)
        ci.Position = UDim2.new(0, 10, 0.5, -12)
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
        hcIco.Size = UDim2.new(0, 16, 0, 16)
        hcIco.Position = UDim2.new(0, 6, 0.5, -8)
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
    
    -- Players tab UI
    do
        local pScroll = settingsTabs["Players"]
        if pScroll then
            pScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
            pScroll.ScrollBarThickness = 3
            pScroll.ScrollBarImageColor3 = C.ACCENT
            
            _G._MenuFriends = _G._MenuFriends or {}
            local friendList = _G._MenuFriends
            
            local function saveFriends()
                local data = {}
                for name, userId in pairs(friendList) do
                    data[name] = userId
                end
                _G._MenuFriends = data
                if writefile then
                    pcall(function()
                        if makefolder and not isfolder("MenuLibConfigs") then makefolder("MenuLibConfigs") end
                        writefile("MenuLibConfigs/" .. tostring(lp.UserId) .. "_friends.json", HttpService:JSONEncode(data))
                    end)
                end
            end
            
            pcall(function()
                if isfile and isfile("MenuLibConfigs/" .. tostring(lp.UserId) .. "_friends.json") then
                    local ok, data = pcall(function() return HttpService:JSONDecode(readfile("MenuLibConfigs/" .. tostring(lp.UserId) .. "_friends.json")) end)
                    if ok and data then
                        for k, v in pairs(data) do friendList[k] = v end
                    end
                end
            end)
            
            local function isFriend(name)
                for n in pairs(friendList) do
                    if n:lower() == name:lower() then return true end
                end
                return false
            end
            
            local mainRow = fr(pScroll, UDim2.new(1, 0, 1, 0), nil, C.CONTENT, 1, 0)
            
            local leftPanel = fr(mainRow, UDim2.new(0.5, -4, 1, 0), UDim2.new(0, 0, 0, 0), C.SEL, 0, 10)
            local rightPanel = fr(mainRow, UDim2.new(0.5, -4, 1, 0), UDim2.new(0.5, 4, 0, 0), C.SEL, 0, 10)
            
            -- Title
            lbl(leftPanel, "Players", UDim2.new(1, -16, 0, 24), UDim2.new(0, 10, 0, 6), 14, C.TEXT, Enum.Font.GothamBold)
            lbl(rightPanel, "Friends", UDim2.new(1, -16, 0, 24), UDim2.new(0, 10, 0, 6), 14, C.TEXT, Enum.Font.GothamBold)
            
            -- Search bars
            local leftSearch = Instance.new("TextBox")
            leftSearch.Size = UDim2.new(1, -20, 0, 28)
            leftSearch.Position = UDim2.new(0, 10, 0, 34)
            leftSearch.BackgroundColor3 = C.DARK
            leftSearch.TextColor3 = C.DIM
            leftSearch.TextSize = 12
            leftSearch.Font = Enum.Font.Gotham
            leftSearch.PlaceholderText = "Search players..."
            leftSearch.PlaceholderColor3 = C.DIM
            leftSearch.ClearTextOnFocus = false
            leftSearch.Parent = leftPanel
            Instance.new("UICorner", leftSearch).CornerRadius = UDim.new(0, 6)
            local lStroke = Instance.new("UIStroke")
            lStroke.Color = C.DIV
            lStroke.Thickness = 1
            lStroke.Parent = leftSearch
            
            local rightSearch = Instance.new("TextBox")
            rightSearch.Size = UDim2.new(1, -20, 0, 28)
            rightSearch.Position = UDim2.new(0, 10, 0, 34)
            rightSearch.BackgroundColor3 = C.DARK
            rightSearch.TextColor3 = C.DIM
            rightSearch.TextSize = 12
            rightSearch.Font = Enum.Font.Gotham
            rightSearch.PlaceholderText = "Search friends..."
            rightSearch.PlaceholderColor3 = C.DIM
            rightSearch.ClearTextOnFocus = false
            rightSearch.Parent = rightPanel
            Instance.new("UICorner", rightSearch).CornerRadius = UDim.new(0, 6)
            local rStroke = Instance.new("UIStroke")
            rStroke.Color = C.DIV
            rStroke.Thickness = 1
            rStroke.Parent = rightSearch
            
            -- Scroll lists
            local playerScroller = Instance.new("ScrollingFrame")
            playerScroller.Size = UDim2.new(1, -8, 1, -72)
            playerScroller.Position = UDim2.new(0, 4, 0, 68)
            playerScroller.BackgroundTransparency = 1
            playerScroller.BorderSizePixel = 0
            playerScroller.ScrollBarThickness = 3
            playerScroller.ScrollBarImageColor3 = C.ACCENT
            playerScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
            playerScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
            playerScroller.Parent = leftPanel
            pad(playerScroller, 4, 4, 4, 4)
            local pLayout = Instance.new("UIListLayout")
            pLayout.SortOrder = Enum.SortOrder.LayoutOrder
            pLayout.Padding = UDim.new(0, 2)
            pLayout.Parent = playerScroller
            
            local friendScroller = Instance.new("ScrollingFrame")
            friendScroller.Size = UDim2.new(1, -8, 1, -72)
            friendScroller.Position = UDim2.new(0, 4, 0, 68)
            friendScroller.BackgroundTransparency = 1
            friendScroller.BorderSizePixel = 0
            friendScroller.ScrollBarThickness = 3
            friendScroller.ScrollBarImageColor3 = C.ACCENT
            friendScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
            friendScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
            friendScroller.Parent = rightPanel
            pad(friendScroller, 4, 4, 4, 4)
            local fLayout = Instance.new("UIListLayout")
            fLayout.SortOrder = Enum.SortOrder.LayoutOrder
            fLayout.Padding = UDim.new(0, 2)
            fLayout.Parent = friendScroller
            
            local function renderPlayerList(query)
                for _, child in ipairs(playerScroller:GetChildren()) do
                    if child:IsA("Frame") then child:Destroy() end
                end
                local q = query and query:lower() or ""
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp then
                        local name = p.Name
                        local display = p.DisplayName
                        if q == "" or name:lower():find(q, 1, true) or display:lower():find(q, 1, true) then
                            local row = fr(playerScroller, UDim2.new(1, 0, 0, 32), nil, C.HEADER, 0.8, 6)
                            local isFren = isFriend(name)
                            local icon = Instance.new("ImageLabel")
                            icon.Size = UDim2.new(0, 24, 0, 24)
                            icon.Position = UDim2.new(0, 6, 0.5, -12)
                            icon.BackgroundTransparency = 1
                            icon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
                            icon.Parent = row
                            Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 12)
                            local thumbOk, thumbUrl = pcall(function() return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
                            if thumbOk then icon.Image = thumbUrl end
                            
                            lbl(row, name, UDim2.new(0, 120, 1, 0), UDim2.new(0, 36, 0, 0), 12, C.TEXT, Enum.Font.GothamBold)
                            
                            local displayLbl = lbl(row, display, UDim2.new(0, 120, 1, 0), UDim2.new(0, 36, 0, 0), 10, C.DIM)
                            displayLbl.TextXAlignment = Enum.TextXAlignment.Left
                            displayLbl.TextYAlignment = Enum.TextYAlignment.Bottom
                            
                            local statusColor = isFren and C.GREEN or C.DIM
                            local statusLbl = lbl(row, isFren and "FRIEND" or "ADD", UDim2.new(0, 50, 0, 20), UDim2.new(1, -60, 0.5, -10), 10, statusColor, Enum.Font.GothamBold)
                            statusLbl.TextXAlignment = Enum.TextXAlignment.Center
                            
                            local statusBg = Instance.new("TextButton")
                            statusBg.Size = UDim2.new(0, 50, 0, 22)
                            statusBg.Position = UDim2.new(1, -56, 0.5, -11)
                            statusBg.BackgroundColor3 = isFren and C.GREEN or C.ACCENT
                            statusBg.Text = ""
                            statusBg.AutoButtonColor = false
                            statusBg.Parent = row
                            Instance.new("UICorner", statusBg).CornerRadius = UDim.new(0, 4)
                            if not isFren then
                                local grad = Instance.new("UIGradient", statusBg)
                                grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C.ACCENT), ColorSequenceKeypoint.new(1, C.ACCENT2)})
                                grad.Rotation = 90
                            end
                            
                            statusBg.MouseButton1Click:Connect(function()
                                if isFren then
                                    friendList[name] = nil
                                    saveFriends()
                                else
                                    friendList[name] = p.UserId
                                    saveFriends()
                                end
                                renderPlayerList(leftSearch.Text)
                                renderFriendList(rightSearch.Text)
                            end)
                        end
                    end
                end
            end
            
            local function renderFriendList(query)
                for _, child in ipairs(friendScroller:GetChildren()) do
                    if child:IsA("Frame") then child:Destroy() end
                end
                local q = query and query:lower() or ""
                local hasFriends = false
                for name, userId in pairs(friendList) do
                    if q == "" or name:lower():find(q, 1, true) then
                        hasFriends = true
                        local row = fr(friendScroller, UDim2.new(1, 0, 0, 32), nil, C.HEADER, 0.8, 6)
                        local icon = Instance.new("ImageLabel")
                        icon.Size = UDim2.new(0, 24, 0, 24)
                        icon.Position = UDim2.new(0, 6, 0.5, -12)
                        icon.BackgroundTransparency = 1
                        icon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
                        icon.Parent = row
                        Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 12)
                        local thumbOk, thumbUrl = pcall(function() return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
                        if thumbOk then icon.Image = thumbUrl end
                        
                        lbl(row, name, UDim2.new(1, -70, 1, 0), UDim2.new(0, 36, 0, 0), 12, C.TEXT, Enum.Font.GothamBold)
                        
                        local removeBtn = Instance.new("TextButton")
                        removeBtn.Size = UDim2.new(0, 50, 0, 22)
                        removeBtn.Position = UDim2.new(1, -56, 0.5, -11)
                        removeBtn.BackgroundColor3 = C.RED
                        removeBtn.Text = "X"
                        removeBtn.TextColor3 = C.TEXT
                        removeBtn.TextSize = 12
                        removeBtn.Font = Enum.Font.GothamBold
                        removeBtn.AutoButtonColor = false
                        removeBtn.Parent = row
                        Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 4)
                        
                        removeBtn.MouseButton1Click:Connect(function()
                            friendList[name] = nil
                            saveFriends()
                            renderPlayerList(leftSearch.Text)
                            renderFriendList(rightSearch.Text)
                        end)
                    end
                end
                if not hasFriends then
                    lbl(friendScroller, "No friends added yet", UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 4), 12, C.DIM).TextXAlignment = Enum.TextXAlignment.Left
                end
            end
            
            leftSearch:GetPropertyChangedSignal("Text"):Connect(function()
                renderPlayerList(leftSearch.Text)
            end)
            rightSearch:GetPropertyChangedSignal("Text"):Connect(function()
                renderFriendList(rightSearch.Text)
            end)
            
            table.insert(conns, Players.PlayerAdded:Connect(function()
                renderPlayerList(leftSearch.Text)
                renderFriendList(rightSearch.Text)
            end))
            table.insert(conns, Players.PlayerRemoving:Connect(function()
                renderPlayerList(leftSearch.Text)
                renderFriendList(rightSearch.Text)
            end))
            
            renderPlayerList("")
            renderFriendList("")
        end
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
            lbl(row, "Tab layout", UDim2.new(1, -170, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)

            local layoutOptions = {"Vertical", "Horizontal"}
            local selectedIdx = 1
            local ddOpen = false
            local DROP_W = 150

            local layoutDropBtn = Instance.new("TextButton")
            layoutDropBtn.Size = UDim2.new(0, DROP_W, 0, 30)
            layoutDropBtn.Position = UDim2.new(1, -(DROP_W + 10), 0.5, -15)
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
        -- Settings access removed for stability
    end, false)
    
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
                keyText = key.Name:gsub("MouseButton", "MB"):gsub("MouseWheel", "Scroll")
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
                elseif inp.UserInputType and inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch and inp.UserInputType ~= Enum.UserInputType.Focus then
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
    
    local function openSettings()
        if inSettings then return end
        inSettings = true
        _G._MenuOpen = true
        tw(homeBtn, { Rotation = homeBtn.Rotation + 360 }, 0.5)
        tw(homeBtnIcon1, { ImageTransparency = 1 }, 0.25)
        tw(homeBtnIcon2, { ImageTransparency = 0 }, 0.25)
        
        tw(win, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.2)
        task.delay(0.1, function() win.Visible = false end)
        
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
    end
    
    local function closeSettings()
        if not inSettings then return end
        inSettings = false
        _G._MenuOpen = true
        tw(homeBtn, { Rotation = homeBtn.Rotation - 360 }, 0.5)
        tw(homeBtnIcon1, { ImageTransparency = 0 }, 0.25)
        tw(homeBtnIcon2, { ImageTransparency = 1 }, 0.25)
        
        tw(settingsPanel, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.2)
        task.delay(0.1, function() settingsPanel.Visible = false end)
        
        win.Size = UDim2.new(0, 0, 0, 0)
        win.Position = UDim2.new(0.5, 0, 0.5, 0)
        win.Visible = true
        tw(win, { Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2) }, 0.25)
    end
    
    closeMenu = function()
        if not win.Visible and not settingsPanel.Visible then return end
        isOpen = false
        _G._MenuOpen = false
        -- Restore CoreGui elements
        pcall(function()
            local CoreGui = game:GetService("CoreGui")
            local menuGui = CoreGui and CoreGui:FindFirstChild("RobloxGui") and CoreGui.RobloxGui:FindFirstChild("MenuGui")
            if menuGui then
                menuGui.Enabled = true
            end
            local topbar = CoreGui and CoreGui:FindFirstChild("RobloxGui") and CoreGui.RobloxGui:FindFirstChild("Topbar")
            if topbar then
                topbar.Enabled = true
            end
        end)
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
            tw(settingsPanel, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.15)
            task.delay(0.15, function()
                settingsPanel.Visible = false
                unlockInput()
            end)
        else
            tw(win, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.15)
            task.delay(0.15, function()
                win.Visible = false
                unlockInput()
            end)
        end
    end
    
    openMenu = function()
        if not win or not settingsPanel then return end
        if win.Visible or settingsPanel.Visible then return end
        isOpen = true
        _G._MenuOpen = true
        lockInput()
        if hudBar then hudBar.Visible = true end
        -- Try to block Roblox escape menu from appearing on top
        pcall(function()
            local CoreGui = game:GetService("CoreGui")
            local menuGui = CoreGui and CoreGui:FindFirstChild("RobloxGui") and CoreGui.RobloxGui:FindFirstChild("MenuGui")
            if menuGui then
                menuGui.Enabled = false
            end
            local topbar = CoreGui and CoreGui:FindFirstChild("RobloxGui") and CoreGui.RobloxGui:FindFirstChild("Topbar")
            if topbar then
                topbar.Enabled = false
            end
        end)
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
    
    toggleMenu = function()
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
        local nameWidth = math.max(nameLbl.AbsoluteSize.X, nameLbl.TextBounds.X)
        local spacing = 16
        local currentX = baseX

        if nameWidth > 0 then 
            currentX = currentX + math.max(70, nameWidth + 8) + spacing 
        else
            currentX = currentX + 100 + spacing
        end

        local function applyLayout(obj, isVisible, targetX, yOffset)
            if not obj then return targetX end
            if isVisible then
                obj.Visible = true
                local w = obj.AbsoluteSize.X
                if obj:IsA("TextLabel") then 
                    w = math.max(w, obj.TextBounds.X)
                    -- If text is still loading ("...") or reported as 0, use safe defaults
                    if w == 0 or obj.Text == "..." then
                        if obj == fpsLbl or obj == pingLbl then w = 48
                        elseif obj == timeLbl then w = 68
                        end
                    end
                end

                if w == 0 then
                    if obj == badge then w = 32
                    elseif obj == homeBtn then w = 30
                    end
                end

                if animate then
                    tw(obj, { Position = UDim2.new(0, targetX, 0.5, yOffset or -10) }, 0.2)
                else
                    obj.Position = UDim2.new(0, targetX, 0.5, yOffset or -10)
                end
                return targetX + (w or 0) + spacing
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
            currentX = applyLayout(timeLbl, true, currentX, -10)
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
            pcall(function() fpsLbl.Text = tostring(math.round(fpsN / fpsT)) .. " FPS" end)
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
    local function keyMatches(inp, key)
        if typeof(key) ~= "EnumItem" then return false end
        if key.EnumType == Enum.KeyCode then
            return inp.KeyCode == key
        elseif key.EnumType == Enum.UserInputType then
            return inp.UserInputType == key
        end
        return inp.KeyCode == key
    end
    
    table.insert(conns, UserInputService.InputBegan:Connect(function(inp, gpe)
        local toggleKey = _G._MenuToggleKey or Enum.KeyCode.Insert
        local unloadKey = _G._UnloadKey or Enum.KeyCode.Delete
        
        -- Escape closes menu if open (prevents Roblox escape menu overlap)
        if isOpen and inp.KeyCode == Enum.KeyCode.Escape then
            closeMenu()
            return
        end
        
        if keyMatches(inp, toggleKey) and not _G._SettingKeybind then
            toggleMenu()
        elseif keyMatches(inp, unloadKey) and not _G._SettingKeybind then
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
            UserInputService.MouseIconEnabled = origMouseIconEnabled

            -- Restore lighting
            if _G._OriginalBrightness then
                Lighting.Brightness = _G._OriginalBrightness
                Lighting.ClockTime = _G._OriginalClockTime
            end

            -- Restore quality
            -- Settings access removed for stability
            
            -- Destroy blur
            if blurPart then pcall(function() blurPart:Destroy() end) blurPart = nil end

            -- Destroy the entire GUI
            pcall(function() sg:Destroy() end)

            -- Restore CoreGui
            pcall(function()
                local CoreGui = game:GetService("CoreGui")
                local menuGui = CoreGui and CoreGui:FindFirstChild("RobloxGui") and CoreGui.RobloxGui:FindFirstChild("MenuGui")
                if menuGui then menuGui.Enabled = true end
                local topbar = CoreGui and CoreGui:FindFirstChild("RobloxGui") and CoreGui.RobloxGui:FindFirstChild("Topbar")
                if topbar then topbar.Enabled = true end
            end)

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

    API.AddToggle = function(tabName, label, callback, default, side)
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end

        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1, 0, 0, 40), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        lbl(row, label, UDim2.new(1, -70, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)
        local toggle = mkToggle(row, -56, default or false, callback)
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
        
        local sliderObj = { Get = function() return value end, Set = function(v) value = math.clamp(v, min, max) updateVisuals(true) if callback then callback(value) end end }
        if not _G._MenuSliders then _G._MenuSliders = {} end
        _G._MenuSliders[label] = sliderObj
        return sliderObj
    end
    
    API.AddColorPicker = function(tabName, label, callback, defaultColor, side)
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end

        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1, 0, 0, 40), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        
        lbl(row, label, UDim2.new(1, -70, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)
        
        local color = defaultColor or Color3.fromRGB(255, 255, 255)
        local alpha = 1
        local preview = fr(row, UDim2.new(0, 36, 0, 24), UDim2.new(1, -50, 0.5, -12), color, 0, 6)
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 26)
        btn.Position = UDim2.new(1, -56, 0.5, -13)
        btn.BackgroundColor3 = C.BTN
        btn.Text = "Pick"
        btn.TextColor3 = C.TEXT
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.Parent = row
        Instance.new("UICorner").Parent = btn
        
        btn.MouseEnter:Connect(function() tw(btn, { BackgroundColor3 = C.BTNHOV }, 0.12) end)
        btn.MouseLeave:Connect(function() tw(btn, { BackgroundColor3 = C.BTN }, 0.12) end)
        
        local pickerFrame = nil
        local pickerCloseConn = nil
        
        local function closePicker()
            if pickerCloseConn then pickerCloseConn:Disconnect() pickerCloseConn = nil end
            if pickerFrame then
                tw(pickerFrame, {Size = UDim2.new(0, 200, 0, 0)}, 0.15)
                local pf = pickerFrame
                pickerFrame = nil
                task.delay(0.2, function() if pf then pf:Destroy() end end)
            end
        end
        table.insert(activeDropdownClosers, closePicker)
        
        btn.MouseButton1Click:Connect(function()
            if pickerFrame then closePicker() return end
            
            local PW, PH = 260, 300
            pickerFrame = fr(sg, UDim2.new(0, PW, 0, 0), UDim2.new(0.5, -PW/2, 0.5, -PH/2), C.HEADER, 0, 12)
            pickerFrame.ZIndex = 1000
            pickerFrame.ClipsDescendants = true
            local pStroke = Instance.new("UIStroke")
            pStroke.Color = C.ACCENT
            pStroke.Thickness = 1.5
            pStroke.Transparency = 0.4
            pStroke.Parent = pickerFrame
            tw(pickerFrame, {Size = UDim2.new(0, PW, 0, PH)}, 0.2, Enum.EasingStyle.Quint)
            
            -- Current HSV
            local h, s, v = color:ToHSV()
            
            local function updateColor()
                color = Color3.fromHSV(h, s, v)
                preview.BackgroundColor3 = color
                if callback then callback(color, alpha) end
            end
            
            -- Hue bar (vertical, right side)
            local hueBar = fr(pickerFrame, UDim2.new(0, 20, 0, 150), UDim2.new(0, PW - 34, 0, 10), C.DARK, 0, 4)
            hueBar.ZIndex = 1001
            for i = 0, 5 do
                local seg = fr(hueBar, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, i * 25), Color3.fromHSV(i/6, 1, 1), 0, 0)
                seg.ZIndex = 1001
                local g = Instance.new("UIGradient")
                g.Color = ColorSequence.new(Color3.fromHSV(i/6, 1, 1), Color3.fromHSV(math.min((i+1)/6, 1), 1, 1))
                g.Rotation = 90
                g.Parent = seg
            end
            local hueKnob = fr(hueBar, UDim2.new(1, 4, 0, 4), UDim2.new(0, -2, 0, h * 150 - 2), C.TEXT, 0, 2)
            hueKnob.ZIndex = 1003
            
            local hueBtn = Instance.new("TextButton")
            hueBtn.Size = UDim2.new(1, 0, 1, 0)
            hueBtn.BackgroundTransparency = 1
            hueBtn.Text = ""
            hueBtn.ZIndex = 1002
            hueBtn.Parent = hueBar
            
            -- SV canvas
            local canvasSize = PW - 50
            local svCanvas = fr(pickerFrame, UDim2.new(0, canvasSize, 0, 150), UDim2.new(0, 10, 0, 10), Color3.fromHSV(h, 1, 1), 0, 4)
            svCanvas.ZIndex = 1001
            -- White gradient left-right
            local wGrad = Instance.new("UIGradient")
            wGrad.Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromHSV(h, 1, 1))
            wGrad.Parent = svCanvas
            -- Dark overlay top-bottom
            local darkOverlay = fr(svCanvas, UDim2.new(1, 0, 1, 0), nil, Color3.new(0,0,0), 0, 4)
            darkOverlay.ZIndex = 1001
            local dGrad = Instance.new("UIGradient")
            dGrad.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0))
            dGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
            dGrad.Rotation = 90
            dGrad.Parent = darkOverlay
            
            local svKnob = fr(svCanvas, UDim2.new(0, 8, 0, 8), UDim2.new(0, s * canvasSize - 4, 0, (1-v) * 150 - 4), C.TEXT, 0, 4)
            svKnob.ZIndex = 1003
            local svKnobStroke = Instance.new("UIStroke")
            svKnobStroke.Color = Color3.new(0,0,0)
            svKnobStroke.Thickness = 1
            svKnobStroke.Parent = svKnob
            
            local svBtn = Instance.new("TextButton")
            svBtn.Size = UDim2.new(1, 0, 1, 0)
            svBtn.BackgroundTransparency = 1
            svBtn.Text = ""
            svBtn.ZIndex = 1002
            svBtn.Parent = svCanvas
            
            -- Alpha slider
            lbl(pickerFrame, "A", UDim2.new(0, 14, 0, 16), UDim2.new(0, 10, 0, 168), 11, C.DIM, Enum.Font.GothamBold).ZIndex = 1001
            local alphaTrack = fr(pickerFrame, UDim2.new(0, PW - 50, 0, 12), UDim2.new(0, 28, 0, 170), C.DARK, 0, 3)
            alphaTrack.ZIndex = 1001
            local alphaFill = fr(alphaTrack, UDim2.new(alpha, 0, 1, 0), nil, C.ACCENT, 0, 3)
            alphaFill.ZIndex = 1001
            gradV(alphaFill, C.ACCENT, C.ACCENT2)
            local alphaKnob = fr(alphaTrack, UDim2.new(0, 8, 0, 16), UDim2.new(alpha, -4, 0.5, -8), C.TEXT, 0, 4)
            alphaKnob.ZIndex = 1003
            local alphaBtn = Instance.new("TextButton")
            alphaBtn.Size = UDim2.new(1, 0, 1, 0)
            alphaBtn.BackgroundTransparency = 1
            alphaBtn.Text = ""
            alphaBtn.ZIndex = 1002
            alphaBtn.Parent = alphaTrack
            
            -- RGBA inputs
            local inputY = 195
            local labels = {"R", "G", "B", "A"}
            local boxes = {}
            for i, l in ipairs(labels) do
                local ix = 10 + (i-1) * 62
                lbl(pickerFrame, l, UDim2.new(0, 12, 0, 20), UDim2.new(0, ix, 0, inputY), 11, C.DIM, Enum.Font.GothamBold).ZIndex = 1001
                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0, 42, 0, 22)
                box.Position = UDim2.new(0, ix + 14, 0, inputY)
                box.BackgroundColor3 = C.DARK
                box.TextColor3 = C.TEXT
                box.TextSize = 11
                box.Font = Enum.Font.GothamBold
                box.Text = ""
                box.ClearTextOnFocus = true
                box.Parent = pickerFrame
                box.ZIndex = 1002
                Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
                boxes[i] = box
            end
            
            local function refreshInputs()
                local r = math.round(color.R * 255)
                local g = math.round(color.G * 255)
                local b = math.round(color.B * 255)
                boxes[1].Text = tostring(r)
                boxes[2].Text = tostring(g)
                boxes[3].Text = tostring(b)
                boxes[4].Text = tostring(math.round(alpha * 255))
            end
            refreshInputs()
            
            local function refreshVisuals()
                svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                wGrad.Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromHSV(h, 1, 1))
                svKnob.Position = UDim2.new(0, s * canvasSize - 4, 0, (1-v) * 150 - 4)
                hueKnob.Position = UDim2.new(0, -2, 0, h * 150 - 2)
                alphaFill.Size = UDim2.new(alpha, 0, 1, 0)
                alphaKnob.Position = UDim2.new(alpha, -4, 0.5, -8)
                refreshInputs()
            end
            
            -- Preset swatches row
            local presets = {
                Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255),
                Color3.fromRGB(255,255,0), Color3.fromRGB(255,0,255), Color3.fromRGB(0,255,255),
                Color3.fromRGB(255,105,180), Color3.fromRGB(255,165,0), Color3.fromRGB(128,0,128),
                Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0), Color3.fromRGB(120,40,240)
            }
            local swatchY = 228
            for i, pc in ipairs(presets) do
                local sx = 10 + (i-1) * 20
                local sw = Instance.new("TextButton")
                sw.Size = UDim2.new(0, 16, 0, 16)
                sw.Position = UDim2.new(0, sx, 0, swatchY)
                sw.BackgroundColor3 = pc
                sw.Text = ""
                sw.Parent = pickerFrame
                sw.ZIndex = 1001
                Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 3)
                sw.MouseButton1Click:Connect(function()
                    color = pc
                    h, s, v = color:ToHSV()
                    updateColor()
                    refreshVisuals()
                end)
            end
            
            -- OK button
            local okBtn = Instance.new("TextButton")
            okBtn.Size = UDim2.new(1, -20, 0, 28)
            okBtn.Position = UDim2.new(0, 10, 0, 258)
            okBtn.BackgroundColor3 = C.ACCENT
            okBtn.Text = "Done"
            okBtn.TextColor3 = C.TEXT
            okBtn.TextSize = 12
            okBtn.Font = Enum.Font.GothamBold
            okBtn.Parent = pickerFrame
            okBtn.ZIndex = 1001
            Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0, 6)
            local okGrad = Instance.new("UIGradient", okBtn)
            okGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C.ACCENT), ColorSequenceKeypoint.new(1, C.ACCENT2)})
            okGrad.Rotation = 90
            okBtn.MouseButton1Click:Connect(closePicker)
            
            -- Interaction: SV canvas
            local svDragging = false
            svBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = true end
            end)
            table.insert(conns, UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
            end))
            table.insert(conns, UserInputService.InputChanged:Connect(function(inp)
                if svDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local ax = math.clamp((inp.Position.X - svCanvas.AbsolutePosition.X) / canvasSize, 0, 1)
                    local ay = math.clamp((inp.Position.Y - svCanvas.AbsolutePosition.Y) / 150, 0, 1)
                    s = ax
                    v = 1 - ay
                    updateColor()
                    refreshVisuals()
                end
            end))
            svBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    local ax = math.clamp((inp.Position.X - svCanvas.AbsolutePosition.X) / canvasSize, 0, 1)
                    local ay = math.clamp((inp.Position.Y - svCanvas.AbsolutePosition.Y) / 150, 0, 1)
                    s = ax
                    v = 1 - ay
                    updateColor()
                    refreshVisuals()
                end
            end)
            
            -- Interaction: Hue bar
            local hueDragging = false
            hueBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueDragging = true
                    h = math.clamp((inp.Position.Y - hueBar.AbsolutePosition.Y) / 150, 0, 1)
                    updateColor()
                    refreshVisuals()
                end
            end)
            table.insert(conns, UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
            end))
            table.insert(conns, UserInputService.InputChanged:Connect(function(inp)
                if hueDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    h = math.clamp((inp.Position.Y - hueBar.AbsolutePosition.Y) / 150, 0, 1)
                    updateColor()
                    refreshVisuals()
                end
            end))
            
            -- Interaction: Alpha slider
            local alphaDragging = false
            alphaBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    alphaDragging = true
                    alpha = math.clamp((inp.Position.X - alphaTrack.AbsolutePosition.X) / alphaTrack.AbsoluteSize.X, 0, 1)
                    updateColor()
                    refreshVisuals()
                end
            end)
            table.insert(conns, UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then alphaDragging = false end
            end))
            table.insert(conns, UserInputService.InputChanged:Connect(function(inp)
                if alphaDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    alpha = math.clamp((inp.Position.X - alphaTrack.AbsolutePosition.X) / alphaTrack.AbsoluteSize.X, 0, 1)
                    updateColor()
                    refreshVisuals()
                end
            end))
            
            -- RGBA text input handling
            for i, box in ipairs(boxes) do
                box.FocusLost:Connect(function()
                    local val = tonumber(box.Text)
                    if not val then refreshInputs() return end
                    val = math.clamp(math.round(val), 0, 255)
                    if i == 1 then
                        color = Color3.fromRGB(val, math.round(color.G*255), math.round(color.B*255))
                    elseif i == 2 then
                        color = Color3.fromRGB(math.round(color.R*255), val, math.round(color.B*255))
                    elseif i == 3 then
                        color = Color3.fromRGB(math.round(color.R*255), math.round(color.G*255), val)
                    elseif i == 4 then
                        alpha = val / 255
                    end
                    h, s, v = color:ToHSV()
                    updateColor()
                    refreshVisuals()
                end)
            end
        end)
        
        return { 
            Get = function() return color, alpha end, 
            Set = function(c, a) color = c if a then alpha = a end preview.BackgroundColor3 = c if callback then callback(c, alpha) end end 
        }
    end
    
    -- ============================================================
    -- FIX 2+3+4: Dropdown — rolls DOWN, text centered, smooth anim
    -- ============================================================
    API.AddDropdown = function(tabName, label, options, callback, defaultIndex, side)
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end

        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1, 0, 0, 40), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)
        
        lbl(row, label, UDim2.new(1, -205, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)
        
        local selectedIndex = defaultIndex or 1
        local ddIsOpen = false
        local DROP_W = 180

        -- FIX: Wider button (180px), centered text, right padding to not overlap chevron
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

            local targetHeight = math.min(#options * 30 + 12, 200)
            
            -- Shadow (slight offset for depth)
            shadow = fr(sg, UDim2.new(0, DROP_W, 0, 0),
                UDim2.new(0, dropX + 2, 0, dropY + 2), Color3.fromRGB(0, 0, 0), 0.7, 8)
            shadow.ZIndex = 998
            
            -- Main dropdown frame — starts at height 0, grows DOWNWARD
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
            
            -- FIX: Animate DOWNWARD — top stays fixed, height grows to targetHeight
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
        
        local ddObj = { 
            Get = function() return options[selectedIndex], selectedIndex end, 
            Set = function(idx) selectedIndex = idx dropdownBtn.Text = options[idx] if callback then callback(options[idx], idx) end end,
            GetOptions = function() return options end,
            SetOptions = function(newOpts) options = newOpts selectedIndex = 1 dropdownBtn.Text = options[1] or "Select" end
        }
        if not _G._MenuDropdowns then _G._MenuDropdowns = {} end
        _G._MenuDropdowns[label] = ddObj
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
        
        -- Rename/Delete button connections (outside loop, uses selectedConfig)
        renameBtnBottom.MouseButton1Click:Connect(function()
            if selectedConfig and _G._ConfigList then
                renameOldName = selectedConfig
                showPopup("rename", "Rename Config", selectedConfig)
            end
        end)
        
        delBtnBottom.MouseButton1Click:Connect(function()
            if selectedConfig and _G._ConfigList and _G._ConfigList[selectedConfig] then
                _G._ConfigList[selectedConfig] = nil
                SaveConfigsToFile()
                local oldRow = selectedRow
                selectedConfig = nil
                selectedRow = nil
                updateBottomActions()
                if oldRow then
                    tw(oldRow, {Size = UDim2.new(1, 0, 0, 0)}, 0.15)
                    task.delay(0.15, function() if oldRow then oldRow:Destroy() end end)
                end
                RefreshConfigList()
            end
        end)
        
        createBtn.MouseButton1Click:Connect(function()
            if selectedConfig and _G._ConfigList and _G._ConfigList[selectedConfig] then
                local name = selectedConfig
                if _G.GetConfigData then
                    _G._ConfigList[name] = _G.GetConfigData()
                    SaveConfigsToFile()
                    RefreshConfigList()
                end
            else
                showPopup("create", "Save New Config", "")
            end
        end)
        
        popupConfirm.MouseButton1Click:Connect(function()
            local name = popupBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if name == "" then
                hidePopup()
                return
            end
            
            if not _G._ConfigList then _G._ConfigList = {} end
            
            if popupMode == "create" then
                if _G._ConfigList[name] then
                    -- Config already exists, do nothing silently
                else
                    if _G.GetConfigData then
                        _G._ConfigList[name] = _G.GetConfigData()
                        SaveConfigsToFile() -- SAVE TO FILE
                        RefreshConfigList()
                    end
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
        
        -- Store all toggle/slider references for config loading (don't reset, may already be populated)
        if not _G._MenuToggles then _G._MenuToggles = {} end
        if not _G._MenuSliders then _G._MenuSliders = {} end
        if not _G._MenuDropdowns then _G._MenuDropdowns = {} end
        
        -- Generic config save/load using _G._MenuToggles and custom hooks
        if not _G.GetConfigData then
            _G.GetConfigData = function()
                local data = {}
                data._MenuSettings = {
                    BlurEnabled = _G._BlurEnabled,
                    LightingDimEnabled = _G._LightingDimEnabled,
                    MenuToggleKey = tostring(_G._MenuToggleKey),
                    UnloadKey = tostring(_G._UnloadKey),
                    SmoothAnimations = _G._SmoothAnimations,
                }
                -- Collect toggles
                if _G._MenuToggles then
                    data._ToggleStates = {}
                    for label, toggle in pairs(_G._MenuToggles) do
                        data._ToggleStates[label] = toggle.Get and toggle.Get() or false
                    end
                end
                -- Collect sliders
                if _G._MenuSliders then
                    data._SliderStates = {}
                    for label, slider in pairs(_G._MenuSliders) do
                        data._SliderStates[label] = slider.Get and slider.Get() or 0
                    end
                end
                -- Collect dropdowns
                if _G._MenuDropdowns then
                    data._DropdownStates = {}
                    for label, dd in pairs(_G._MenuDropdowns) do
                        local _, idx = nil, 1
                        if dd.Get then _, idx = dd.Get() end
                        data._DropdownStates[label] = idx or 1
                    end
                end
                return data
            end
        end
        
        if not _G.LoadConfigData then
            _G.LoadConfigData = function(data)
                if not data then return end
                if data._MenuSettings then
                    local s = data._MenuSettings
                    _G._BlurEnabled = s.BlurEnabled
                    _G._LightingDimEnabled = s.LightingDimEnabled
                    _G._SmoothAnimations = s.SmoothAnimations
                    if s.MenuToggleKey then pcall(function() _G._MenuToggleKey = Enum.KeyCode[s.MenuToggleKey] end) end
                    if s.UnloadKey then pcall(function() _G._UnloadKey = Enum.KeyCode[s.UnloadKey] end) end
                end
                -- Restore toggles
                if data._ToggleStates and _G._MenuToggles then
                    for label, val in pairs(data._ToggleStates) do
                        local toggle = _G._MenuToggles[label]
                        if toggle and toggle.Set then
                            toggle.Set(val)
                        end
                    end
                end
                -- Restore sliders
                if data._SliderStates and _G._MenuSliders then
                    for label, val in pairs(data._SliderStates) do
                        local slider = _G._MenuSliders[label]
                        if slider and slider.Set then
                            slider.Set(val)
                        end
                    end
                end
                -- Restore dropdowns
                if data._DropdownStates and _G._MenuDropdowns then
                    for label, idx in pairs(data._DropdownStates) do
                        local dd = _G._MenuDropdowns[label]
                        if dd and dd.Set then
                            dd.Set(idx)
                        end
                    end
                end
                _G._ConfigLoaded = tick()
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
