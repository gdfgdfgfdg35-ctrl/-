local MenuLib = {}

function MenuLib:Init(config)
    config = config or {}

    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local HttpService = game:GetService("HttpService")

    for _ = 1, 100 do if Players.LocalPlayer then break end task.wait(0.1) end
    local lp = Players.LocalPlayer
    local pg = lp:WaitForChild("PlayerGui")
    local _guidCounter = 0
    local _guid = nil
    local okGuid, guidResult = pcall(function() return HttpService:GenerateGUID(false) end)
    if okGuid and guidResult then
        _guid = guidResult
    else
        _guidCounter = _guidCounter + 1
        _guid = tostring(math.random(1, 999999)) .. "_" .. tostring(tick()) .. "_" .. tostring(_guidCounter)
    end
    local RS_BIND_INP = "MenuGuiInp_" .. _guid

    _G._MenuLib = _G._MenuLib or {}
    local M = _G._MenuLib
    M.AutoRefresh = true
    M.BlurEnabled = false
    M.LightingDimEnabled = false
    M.OriginalBrightness = nil
    M.OriginalClockTime = nil
    M.OriginalQualityLevel = nil
    M.MenuToggleKey = Enum.KeyCode.Insert
    M.UnloadKey = Enum.KeyCode.End
    M.SmoothAnimations = true
    M.ESPColour = Color3.fromRGB(120, 40, 240)

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

    local PLAYERS_TAB_ICON_SIZE = 20

    local FONT = Enum.Font.Gotham
    local FONT_BOLD = Enum.Font.GothamBold

    local Z = {
        BASE = 1, CONTENT = 2, SIDEBAR = 3, TAB = 5, HUD = 5,
        DRAG = 30, SETTINGS_DRAG = 50, RESIZER = 50,
        OVERLAY = 100, DROPDOWN = 1000, DROPDOWN_SHADOW = 998,
        POPUP = 1000, POPUP_CONTENT = 101, INPUT_BLOCKER = -10,
    }

    local DROP_W = 130
    local DROP_OPTION_H = 30
    local DROP_PADDING = 12
    local DROP_MAX_H = 150
    local PICKER_W = 254
    local PICKER_H = 324
    local TAB_LABEL_CHAR_W = 7
    local TAB_LABEL_MIN_W = 28
    local FIELD_GAP = 6

    local function normalizeIconId(id)
        if type(id) ~= "string" and type(id) ~= "number" then return nil end
        local s = tostring(id):gsub("^%s+", ""):gsub("%s+$", "")
        if s == "" then return nil end
        if s:match("^rbxassetid://") or s:match("^rbxasset://") or s:match("^rbxthumb://") or s:match("^http://") or s:match("^https://") then return s end
        if s:match("^%d+$") then return "rbxassetid://" .. s end
        return s
    end

    local controls = nil
    local isOpen = false
    local controlsDisabledByUs = false
    local behaviorAssertUntil = 0
    local unloaded = false
    local prevMouseBehavior = Enum.MouseBehavior.Default
    local prevMouseIconEnabled = UserInputService.MouseIconEnabled
    local behaviorTarget = nil
    local win, settingsPanel, toggleMenu, fpsT, fpsN

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
    inputBlocker.ZIndex = Z.INPUT_BLOCKER
    inputBlocker.Parent = sg

    local function getControls()
        if controls then return controls end
        pcall(function()
            local pl = game:GetService("Players").LocalPlayer
            if pl then
                local ps = pl:FindFirstChild("PlayerScripts")
                if ps then
                    local pm = ps:FindFirstChild("PlayerModule")
                    if pm then
                        local okPM, PM = pcall(function() return require(pm) end)
                        if okPM and PM and PM.GetControls then
                            local okCtrl, ctrl = pcall(PM.GetControls, PM)
                            if okCtrl and ctrl then controls = ctrl end
                        end
                    end
                end
            end
        end)
        return controls
    end

    getControls()

    local function ensureControls()
        return getControls()
    end

    local function lockInput()
        -- Guard on controlsDisabledByUs, NOT isOpen: openMenu sets isOpen = true
        -- before calling this, so an isOpen guard never samples anything and the
        -- restore on close has nothing to put back.
        if not controlsDisabledByUs then
            pcall(function()
                prevMouseIconEnabled = UserInputService.MouseIconEnabled
                prevMouseBehavior = UserInputService.MouseBehavior
            end)
        end
        controlsDisabledByUs = true
        isOpen = true
        if inputBlocker then inputBlocker.Visible = true end
        local ctrl = ensureControls()
        if ctrl then pcall(function() ctrl:Disable() end) end
        pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
        pcall(function() UserInputService.MouseIconEnabled = true end)
    end

    local function gameWantsLockedMouse()
        local locked = nil
        pcall(function()
            local okCH, CH = pcall(function()
                return require(game:GetService("ReplicatedStorage").Modules.Handlers.CameraHandler)
            end)
            if okCH and CH then
                if CH.freeMouseState == true then
                    locked = false
                elseif CH.firstPerson == true then
                    locked = true
                end
            end
        end)
        return locked
    end

    local function applyGameMouseState()
        local locked = gameWantsLockedMouse()
        if locked == nil then
            locked = (prevMouseBehavior == Enum.MouseBehavior.LockCenter)
        end
        behaviorTarget = locked and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
        pcall(function() UserInputService.MouseBehavior = behaviorTarget end)
        pcall(function() UserInputService.MouseIconEnabled = not locked end)
        behaviorAssertUntil = os.clock() + 1.5
    end

    local function unlockInput()
        isOpen = false
        controlsDisabledByUs = false
        if inputBlocker then pcall(function() inputBlocker.Visible = false end) end
        local ctrl = ensureControls()
        if ctrl then pcall(function() ctrl:Enable() end) end
        pcall(function()
            local ctrl2 = getControls()
            if ctrl2 then pcall(ctrl2.Enable, ctrl2) end
        end)
        applyGameMouseState()
    end

    local function menuIsVisible()
        if not win or not settingsPanel then return false end
        local okW, winVisible = pcall(function() return win.Visible end)
        local okS, panelVisible = pcall(function() return settingsPanel.Visible end)
        return (okW and winVisible) or (okS and panelVisible) or false
    end

    local function ensureUnlocked()
        if menuIsVisible() then return end
        if isOpen or controlsDisabledByUs then pcall(unlockInput) end
    end


    RunService:BindToRenderStep(RS_BIND_INP, Enum.RenderPriority.Last.Value, function()
        if not isOpen then return end
        if not win or not settingsPanel then return end
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
        if not parent then return nil end
        local f = Instance.new("Frame")
        f.Size = size
        f.Position = pos or UDim2.new(0, 0, 0, 0)
        f.BackgroundColor3 = col or C.BG
        f.BackgroundTransparency = trans ~= nil and trans or 0
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
        if not parent then return nil end
        local l = Instance.new("TextLabel")
        l.Size = size
        l.Position = pos or UDim2.new(0, 0, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = txt
        l.TextColor3 = col or C.TEXT
        l.TextSize = ts ~= nil and ts or 11
        l.Font = font or FONT
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextWrapped = true
        l.Parent = parent
        return l
    end

    local function gradV(parent, c1, c2)
        if not parent then return nil end
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2) })
        g.Rotation = 90
        g.Parent = parent
        return g
    end

    local function pad(parent, l, r, t, b)
        if not parent then return nil end
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, l ~= nil and l or 0)
        p.PaddingRight = UDim.new(0, r ~= nil and r or 0)
        p.PaddingTop = UDim.new(0, t ~= nil and t or 0)
        p.PaddingBottom = UDim.new(0, b ~= nil and b or 0)
        p.Parent = parent
        return p
    end

    local function tw(obj, props, t, style)
        if not obj then return end
        TweenService:Create(obj, TweenInfo.new(t ~= nil and t or 0.15, style or Enum.EasingStyle.Quint), props):Play()
    end

    local blurPart = nil
    local activeDropdownClosers = {}
    local conns = {}

    local reassertClock = 0
    table.insert(conns, RunService.Heartbeat:Connect(function(dt)
        if unloaded then return end
        if menuIsVisible() then return end

        if isOpen or controlsDisabledByUs then
            pcall(unlockInput)
            return
        end

        -- Hold the restored lock briefly: the game's camera controller can take a
        -- few frames to resume, and anything it does in that window wins afterwards.
        if os.clock() < behaviorAssertUntil and behaviorTarget ~= nil then
            pcall(function()
                if UserInputService.MouseBehavior ~= behaviorTarget then
                    UserInputService.MouseBehavior = behaviorTarget
                end
            end)
        end

        reassertClock = reassertClock + dt
        if reassertClock < 0.5 then return end
        reassertClock = 0
        local ctrl = getControls()
        if ctrl then pcall(ctrl.Enable, ctrl) end
        if inputBlocker then
            local okV, visible = pcall(function() return inputBlocker.Visible end)
            if okV and visible then pcall(function() inputBlocker.Visible = false end) end
        end
    end))

    local function mkToggle(parent, posX, initState, onToggle)
        local track = fr(parent, UDim2.new(0, 44, 0, 24), UDim2.new(1, posX, 0.5, -12), Color3.fromRGB(18, 8, 36), 0, 12)
        track.ClipsDescendants = true
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
            local fillDest = state and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 1, 0)
            local dest = state and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            if anim then
                tw(fill, { Size = fillDest }, 0.35)
                tw(knob, { Position = dest }, 0.35)
            else
                fill.Size = fillDest
                knob.Position = dest
            end
            if onToggle and not silent then pcall(function() task.defer(function() pcall(onToggle, state) end) end) end
        end
        apply(false, true)
        table.insert(conns, togBtn.MouseButton1Click:Connect(function()
            state = not state
            apply(true, false)
        end))
        return { Get = function() return state end, Set = function(v) if v ~= state then state = v apply(true, false) end end }
    end

    table.insert(conns, UserInputService.WindowFocusReleased:Connect(function()
        if isOpen then
            pcall(toggleMenu)
        end
        pcall(ensureUnlocked)
    end))

    table.insert(conns, UserInputService.WindowFocused:Connect(function()
        pcall(ensureUnlocked)
    end))
    local settingKeybind = false


    local hudBar = fr(sg, UDim2.new(0, HUD_W, 0, 44), UDim2.new(0.5, -HUD_W / 2, 0, 10), C.DARK, 0, 18)
    hudBar.ZIndex = Z.HUD

    local av = fr(hudBar, UDim2.new(0, 32, 0, 32), UDim2.new(0, 10, 0.5, -16), Color3.fromRGB(36, 14, 68), 0, 16)
    local avImg = Instance.new("ImageLabel")
    avImg.Size = UDim2.new(1, -4, 1, -4)
    avImg.Position = UDim2.new(0, 2, 0, 2)
    avImg.BackgroundTransparency = 1
    avImg.Parent = av
    Instance.new("UICorner").Parent = avImg
    task.spawn(function()
        pcall(function()
            local ok, url = pcall(function()
                return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
            end)
            if ok and url and not unloaded then avImg.Image = url end
        end)
    end)

    lbl(hudBar, "Welcome back,", UDim2.new(0, 140, 0, 14), UDim2.new(0, 48, 0, 6), 9, C.DIM)
    local nameLbl = lbl(hudBar, lp.Name, UDim2.new(0, 0, 0, 16), UDim2.new(0, 48, 0, 20), 12, C.TEXT, FONT_BOLD)
    nameLbl.AutomaticSize = Enum.AutomaticSize.X

    local fpsLbl = lbl(hudBar, "...", UDim2.new(0, 0, 0, 20), UDim2.new(0, 248, 0, 14), 14, C.ACCENT, FONT_BOLD)
    fpsLbl.AutomaticSize = Enum.AutomaticSize.X
    local pingLbl = lbl(hudBar, "...", UDim2.new(0, 0, 0, 20), UDim2.new(0, 340, 0, 14), 14, C.GREEN, FONT_BOLD)
    pingLbl.AutomaticSize = Enum.AutomaticSize.X
    local timeLbl = lbl(hudBar, "12:00 PM", UDim2.new(0, 0, 0, 16), UDim2.new(0, 556, 0, 12), 14, C.TEXT, FONT_BOLD)
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
    fireClick.ZIndex = Z.HUD + 5
    fireClick.Parent = badge

    win = fr(sg, UDim2.new(0, WIN_W, 0, WIN_H), UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2), C.BG, 0, 20)
    win.ClipsDescendants = true
    win.ZIndex = Z.BASE
    win.Visible = false

    local mainLayer = fr(win, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), C.BG, 1, 0)
    mainLayer.ZIndex = Z.CONTENT

    local dragHandle = Instance.new("TextButton")
    dragHandle.Size = UDim2.new(1, 0, 0, 36)
    dragHandle.Position = UDim2.new(0, 0, 0, 0)
    dragHandle.BackgroundTransparency = 1
    dragHandle.Text = ""
    dragHandle.ZIndex = Z.DRAG
    dragHandle.Active = true
    dragHandle.AutoButtonColor = false
    dragHandle.Parent = mainLayer

    local bodyShell = fr(mainLayer, UDim2.new(1, 0, 1, -12), UDim2.new(0, 0, 0, 12), C.BG, 1, 0)
    bodyShell.ZIndex = Z.CONTENT

    local sidebar = fr(bodyShell, UDim2.new(0, SIDE_W, 1, -4), UDim2.new(0, 0, 0, 4), C.SIDEBAR, 0, 14)
    sidebar.ZIndex = Z.CONTENT
    sidebar.ClipsDescendants = true

    local sidebarDivider = fr(bodyShell, UDim2.new(0, 1, 1, -4), UDim2.new(0, SIDE_W, 0, 4), C.DIV)

    local TAB_BAR_H = 42
    local tabBarIsHorizontal = false

    local topTabBar = fr(bodyShell, UDim2.new(1, -4, 0, TAB_BAR_H), UDim2.new(0, 2, 0, 4), C.SIDEBAR, 0, 14)
    topTabBar.ZIndex = Z.SIDEBAR
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
    contentArea.ZIndex = Z.CONTENT

    local statusBar = fr(bodyShell, UDim2.new(1, -SIDE_W - 2, 0, 28), UDim2.new(0, SIDE_W + 2, 1, -32), C.DARK, 0, 12)

    local function mkSmallBtn(parent, txt, size, pos, fn)
        local b = Instance.new("TextButton")
        b.Size = size
        b.Position = pos
        b.BackgroundColor3 = C.BTN
        b.Text = txt
        b.TextColor3 = C.TEXT
        b.TextSize = 11
        b.Font = FONT_BOLD
        b.AutoButtonColor = false
        b.Parent = parent
        Instance.new("UICorner").Parent = b
        table.insert(conns, b.MouseEnter:Connect(function() tw(b, { BackgroundColor3 = C.BTNHOV }, 0.12) end))
        table.insert(conns, b.MouseLeave:Connect(function() tw(b, { BackgroundColor3 = C.BTN }, 0.12) end))
        if fn then b.MouseButton1Click:Connect(fn) end
        return b
    end

    local navHolder = fr(sidebar, UDim2.new(1, 0, 1, 0), nil, C.SIDEBAR, 1, 0)
    local navScroll = Instance.new("ScrollingFrame")
    navScroll.Size = UDim2.new(1, 0, 1, 0)
    navScroll.ZIndex = Z.CONTENT
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
        local s = lbl(navScroll, name, UDim2.new(1, -4, 0, 22), nil, 11, C.SEC, FONT_BOLD)
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.LayoutOrder = nextNavOrd()
        pad(s, 10, 0, 2, 0)
        table.insert(sectionLabels, s)
        if navSectionCount > 1 then
            local vdiv = fr(topTabScroll, UDim2.new(0, 1, 0, 22), nil, C.DIV, 1, 0)
            vdiv.BackgroundTransparency = 0.4
            vdiv.LayoutOrder = nextTopOrd()
        end
        local hs = lbl(topTabScroll, name, UDim2.new(0, math.max(28, #name * 7), 0, 28), nil, 10, C.SEC, FONT_BOLD)
        hs.TextYAlignment = Enum.TextYAlignment.Center
        hs.LayoutOrder = nextTopOrd()
    end

    local function selectTab(entry)
        local isCompact = (SIDE_W <= 100)
        local tf = entry.frame
        tf.Visible = true
        tf.Position = UDim2.new(0, 30, 0, 0)
        tw(tf, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.4)
        tw(entry.bg, { BackgroundTransparency = 0 }, 0.3)
        tw(entry.line, { BackgroundTransparency = isCompact and 1 or 0, Size = UDim2.new(0, 4, 0.5, 0) }, 0.35)
        tw(entry.lbl, { TextColor3 = C.TEXT }, 0.25)
        tw(entry.ico, { ImageColor3 = C.TEXT, Position = isCompact and UDim2.new(0.5, -entry.iconSize/2, 0.5, -entry.iconSize/2) or UDim2.new(0, entry.iconX + 4, 0.5, -entry.iconSize / 2) }, 0.3)
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
        tw(entry.bg, { BackgroundTransparency = 1 }, 0.25)
        tw(entry.line, { BackgroundTransparency = 1, Size = UDim2.new(0, 4, 0, 0) }, 0.2)
        tw(entry.lbl, { TextColor3 = C.DIM }, 0.2)
        tw(entry.ico, { ImageColor3 = C.DIM, Position = isCompact and UDim2.new(0.5, -entry.iconSize/2, 0.5, -entry.iconSize/2) or UDim2.new(0, entry.iconX, 0.5, -entry.iconSize / 2) }, 0.25)
        task.delay(0.35, function() pcall(function() tf.Visible = false end) end)
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

    local ICON_SIZES = {
        [ICON.aim] = { size = 29, x = 2 },
        [ICON.players] = { size = 28, x = 2 },
        [ICON.performance] = { size = 28, x = 2 },
        [ICON.sfx] = { size = 22, x = 6.5 },
        [ICON.world] = { size = 20, x = 6 },
        [ICON.skin] = { size = 28, x = 4 },
    }

    local function addTab(name, iconImage, buildFn)
        if type(name) ~= "string" or name == "" then return nil, nil end
        local tf = fr(contentArea, UDim2.new(1, 0, 1, 0), nil, C.CONTENT, 1, 0)
        tf.Visible = false
        tf.ZIndex = Z.TAB
        if buildFn then pcall(buildFn, tf) end

        local navOrd = nextNavOrd()
        local topOrd = nextTopOrd()

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

        local iconCfg = ICON_SIZES[iconImage] or { size = 24, x = 6 }
        local iconSize = iconCfg.size
        local iconX = iconCfg.x

        local icoL = Instance.new("ImageLabel")
        icoL.Size = UDim2.new(0, iconSize, 0, iconSize)
        icoL.Position = UDim2.new(0, iconX, 0.5, -iconSize / 2)
        icoL.BackgroundTransparency = 1
        icoL.Image = normalizeIconId(iconImage) or ""
        icoL.ScaleType = Enum.ScaleType.Fit
        icoL.ImageColor3 = C.DIM
        icoL.Parent = btn

        local namL = lbl(btn, name, UDim2.new(1, -52, 1, 0), UDim2.new(0, 44, 0, 0), 12, C.DIM)

        local hBtnW = math.max(#name * TAB_LABEL_CHAR_W + 42, 70)
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

        local hLbl = lbl(hBtn, name, UDim2.new(1, -34, 1, 0), UDim2.new(0, 30, 0, 0), 11, C.DIM, FONT_BOLD)

        local entry = {
            btn = btn, frame = tf, bg = selBg, line = selLine, ico = icoL, lbl = namL,
            iconSize = iconSize, iconX = iconX,
            hBtn = hBtn, hBg = hBg, hLine = hLine, hIco = hIco, hLbl = hLbl
        }
        table.insert(allTabs, entry)
        tabContents[name] = tf

        entry._des = function() deselectTab(entry) end
        entry._sel = function() selectTab(entry) end

        table.insert(conns, btn.MouseEnter:Connect(function() if activeTab ~= entry then tw(selBg, { BackgroundTransparency = 0.5 }) end end))
        table.insert(conns, btn.MouseLeave:Connect(function() if activeTab ~= entry then tw(selBg, { BackgroundTransparency = 1 }) end end))
        table.insert(conns, btn.MouseButton1Click:Connect(function() doTabSwitch(entry) end))

        table.insert(conns, hBtn.MouseEnter:Connect(function() if activeTab ~= entry then tw(hBg, { BackgroundTransparency = 0.5 }) end end))
        table.insert(conns, hBtn.MouseLeave:Connect(function() if activeTab ~= entry then tw(hBg, { BackgroundTransparency = 1 }) end end))
        table.insert(conns, hBtn.MouseButton1Click:Connect(function() doTabSwitch(entry) end))

        return entry, tf
    end

    local applySettingsLayout = nil
    local compactEnabled = false

    local function setTabLayout(horizontal, animate)
        tabBarIsHorizontal = horizontal
        local t = animate and 0.35 or 0
        local ease = Enum.EasingStyle.Quint

        if horizontal then
            tw(sidebar, { Size = UDim2.new(0, 0, 1, -4) }, t, ease)
            tw(sidebarDivider, { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 4) }, t, ease)
            task.delay(t, function() pcall(function()
                sidebar.Visible = false
                sidebarDivider.Visible = false
            end) end)
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
            local targetW = compactEnabled and 52 or 160
            SIDE_W = targetW
            sidebar.Visible = true
            sidebarDivider.Visible = true
            tw(sidebar, { Size = UDim2.new(0, targetW, 1, -4) }, t, ease)
            tw(sidebarDivider, { BackgroundTransparency = 0, Position = UDim2.new(0, targetW, 0, 4) }, t, ease)
            tw(topTabBar, { BackgroundTransparency = 1 }, t, ease)
            tw(topTabDivider, { BackgroundTransparency = 1 }, t, ease)
            task.delay(t, function() pcall(function()
                topTabBar.Visible = false
                topTabDivider.Visible = false
            end) end)
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

    settingsPanel = fr(sg, UDim2.new(0, WIN_W, 0, WIN_H), UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2), C.BG, 0, 20)
    settingsPanel.ClipsDescendants = true
    settingsPanel.ZIndex = Z.OVERLAY
    settingsPanel.Visible = false

    local settingsMainLayer = fr(settingsPanel, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), C.BG, 1, 0)
    settingsMainLayer.ZIndex = Z.CONTENT

    local settingsDrag = Instance.new("TextButton")
    settingsDrag.Size = UDim2.new(1, 0, 0, 36)
    settingsDrag.Position = UDim2.new(0, 0, 0, 0)
    settingsDrag.BackgroundTransparency = 1
    settingsDrag.Text = ""
    settingsDrag.ZIndex = Z.SETTINGS_DRAG
    settingsDrag.Active = true
    settingsDrag.AutoButtonColor = false
    settingsDrag.Parent = settingsMainLayer

    local settingsBodyShell = fr(settingsMainLayer, UDim2.new(1, 0, 1, -12), UDim2.new(0, 0, 0, 12), C.BG, 1, 0)
    settingsBodyShell.ZIndex = Z.CONTENT

    local settingsLeft = fr(settingsBodyShell, UDim2.new(0, SIDE_W, 1, -4), UDim2.new(0, 0, 0, 4), C.SIDEBAR, 0, 14)
    settingsLeft.ZIndex = Z.CONTENT
    settingsLeft.ClipsDescendants = true

    local settingsDivider = fr(settingsBodyShell, UDim2.new(0, 1, 1, -4), UDim2.new(0, SIDE_W, 0, 4), C.DIV)

    local catItems = { "General", "Appearance", "Performance", "Keybinds", "Players" }
    local catKeys = { ICON.general, ICON.appearance, ICON.performance, ICON.keyboard, ICON.playerTab }
    local catScroll = Instance.new("ScrollingFrame")
    catScroll.Size = UDim2.new(1, 0, 1, 0)
    catScroll.ZIndex = Z.CONTENT
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

    local function updateSettingTabVisuals(idx, isActive)
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
        local CAT_ICON_SIZES = {
            ["Players"] = { size = PLAYERS_TAB_ICON_SIZE },
            ["Performance"] = { size = 27 },
        }
        local ciCfg = CAT_ICON_SIZES[cat] or { size = 24 }
        local ciSize = ciCfg.size
        local ciOffset = 10 + math.floor((24 - ciSize) / 2)
        ci.Size = UDim2.new(0, ciSize, 0, ciSize)
        ci.Position = UDim2.new(0, ciOffset, 0.5, -math.floor(ciSize / 2))
        ci.BackgroundTransparency = 1
        ci.Image = normalizeIconId(catKeys[i]) or ""
        ci.ImageColor3 = C.DIM
        ci.Parent = cb

        local namL = lbl(cb, cat, UDim2.new(1, -44, 1, 0), UDim2.new(0, 40, 0, 0), 12, C.DIM)
        catBtns[i] = { btn = cb, icon = ci, lbl = namL, bg = selBg, line = selLine }

        table.insert(conns, cb.MouseEnter:Connect(function()
            if activeSettingTab ~= i then
                tw(selBg, { BackgroundTransparency = 0.5 }, 0.15)
            end
        end))

        table.insert(conns, cb.MouseLeave:Connect(function()
            if activeSettingTab ~= i then
                tw(selBg, { BackgroundTransparency = 1 }, 0.15)
            end
        end))

        table.insert(conns, cb.MouseButton1Click:Connect(function()
            if activeSettingTab ~= i then
                local oldIdx = activeSettingTab
                local newContent = settingsTabContents[i]
                local oldContent = settingsTabContents[oldIdx]

                updateSettingTabVisuals(oldIdx, false)
                updateSettingTabVisuals(i, true)

                if oldContent then
                    tw(oldContent, { Position = UDim2.new(0, -15, 0, 0) }, 0.12, Enum.EasingStyle.Quad)
                    oldContent.Visible = false
                end

                newContent.Visible = true
                newContent.Position = UDim2.new(0, 15, 0, 0)
                tw(newContent, { Position = UDim2.new(0, 0, 0, 0) }, 0.15, Enum.EasingStyle.Quad)

                activeSettingTab = i
            end
        end))
    end

    local sRight = fr(settingsBodyShell, UDim2.new(1, -SIDE_W - 2, 1, -32), UDim2.new(0, SIDE_W + 2, 0, 4), C.CONTENT, 0, 16)
    sRight.ZIndex = Z.CONTENT

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

        for _, s in ipairs(sectionLabels or {}) do
            if isCompact then
                tw(s, {TextTransparency = 1}, tatn)
                task.delay(tatn, function() pcall(function() if s then s.Visible = false end end) end)
            else
                s.Visible = true
                tw(s, {TextTransparency = 0}, tatn)
            end
        end

        for _, t in ipairs(allTabs or {}) do
            if t.lbl then
                if isCompact then
                    tw(t.lbl, {TextTransparency = 1}, tatn)
                    task.delay(tatn, function() pcall(function() if t.lbl then t.lbl.Visible = false end end) end)
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
                    task.delay(tatn, function() pcall(function() if t.lbl then t.lbl.Visible = false end end) end)
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
    lbl(titleRow, "Settings", UDim2.new(1, -16, 1, 0), UDim2.new(0, 14, 0, 0), 16, C.TEXT, FONT_BOLD)

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
        local HC_ICON_SIZES = { ["Performance"] = 19 }
        local hcSize = HC_ICON_SIZES[cat] or 16
        hcIco.Size = UDim2.new(0, hcSize, 0, hcSize)
        hcIco.Position = UDim2.new(0, 6, 0.5, -math.floor(hcSize / 2))
        hcIco.BackgroundTransparency = 1
        hcIco.Image = normalizeIconId(catKeys[i]) or ""
        hcIco.ScaleType = Enum.ScaleType.Fit
        hcIco.ImageColor3 = C.DIM
        hcIco.Parent = hcBtn
        local hcLbl = lbl(hcBtn, cat, UDim2.new(1, -28, 1, 0), UDim2.new(0, 26, 0, 0), 11, C.DIM, FONT_BOLD)
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
        table.insert(conns, hc.btn.MouseEnter:Connect(function()
            if activeSettingTab ~= i then tw(hc.bg, { BackgroundTransparency = 0.5 }, 0.12) end
        end))
        table.insert(conns, hc.btn.MouseLeave:Connect(function()
            if activeSettingTab ~= i then tw(hc.bg, { BackgroundTransparency = 1 }, 0.12) end
        end))
        table.insert(conns, hc.btn.MouseButton1Click:Connect(function()
            if activeSettingTab ~= i then
                local oldContent = settingsTabContents[activeSettingTab]
                local newContent = settingsTabContents[i]
                local oldIdx = activeSettingTab
                activeSettingTab = i

                updateSettingTabVisuals(oldIdx, false)
                updateSettingTabVisuals(i, true)
                updateHCatVisuals()

                if oldContent then
                    tw(oldContent, { Position = UDim2.new(0, -15, 0, 0) }, 0.12)
                    oldContent.Visible = false
                end
                newContent.Visible = true
                newContent.Position = UDim2.new(0, 15, 0, 0)
                tw(newContent, { Position = UDim2.new(0, 0, 0, 0) }, 0.15)
            end
        end))
    end

    local sHolder = fr(sRight, UDim2.new(1, 0, 1, -46), UDim2.new(0, 0, 0, 40), C.CONTENT, 1, 0)

    for i = 1, 5 do
        local sScroll = Instance.new("ScrollingFrame")
        sScroll.Size = UDim2.new(1, 0, 1, 0)
        sScroll.ZIndex = Z.CONTENT
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
            task.delay(t, function() pcall(function()
                settingsLeft.Visible = false
                settingsDivider.Visible = false
            end) end)
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
            task.delay(t, function() pcall(function() settingsCatBar.Visible = false end) end)
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
            if not _G._MenuToggles then _G._MenuToggles = {} end
            _G._MenuToggles[tabName .. "_" .. labelText] = toggle
            return toggle
        end
        return row
    end

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
            local LAYOUT_DROP_W = 110

            local layoutDropBtn = Instance.new("TextButton")
            layoutDropBtn.Size = UDim2.new(0, LAYOUT_DROP_W, 0, 26)
            layoutDropBtn.Position = UDim2.new(1, -(LAYOUT_DROP_W + 10), 0.5, -13)
            layoutDropBtn.BackgroundColor3 = C.DARK
            layoutDropBtn.Text = "Vertical"
            layoutDropBtn.TextColor3 = C.TEXT
            layoutDropBtn.TextSize = 11
            layoutDropBtn.Font = FONT_BOLD
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

            table.insert(conns, layoutDropBtn.MouseEnter:Connect(function()
                tw(layoutDropBtn, { BackgroundColor3 = C.BTN }, 0.12)
                tw(ddStroke, { Color = C.ACCENT, Transparency = 0.3 }, 0.12)
            end))
            table.insert(conns, layoutDropBtn.MouseLeave:Connect(function()
                tw(layoutDropBtn, { BackgroundColor3 = C.DARK }, 0.12)
                tw(ddStroke, { Color = C.DIV, Transparency = 0.5 }, 0.12)
            end))

            local dropFrame = nil
            local dropShadow = nil
            local closeConn = nil

            local function closeDrop()
                ddOpen = false
                if closeConn then closeConn:Disconnect() closeConn = nil end
                tw(chevron, { Rotation = 0 }, 0.2)
                if dropFrame then
                    tw(dropFrame, { Size = UDim2.new(0, LAYOUT_DROP_W, 0, 0), BackgroundTransparency = 1 }, 0.2)
                    local cf = dropFrame
                    local cs = dropShadow
                    dropFrame = nil
                    dropShadow = nil
                    task.delay(0.25, function() pcall(function()
                        if cf then cf:Destroy() end
                        if cs then cs:Destroy() end
                    end) end)
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

                dropShadow = fr(sg, UDim2.new(0, LAYOUT_DROP_W, 0, 0), UDim2.new(0, dropX + 2, 0, dropY + 2), Color3.new(0, 0, 0), 0.7, 8)
                dropShadow.ZIndex = Z.DROPDOWN_SHADOW

                dropFrame = fr(sg, UDim2.new(0, LAYOUT_DROP_W, 0, 0), UDim2.new(0, dropX, 0, dropY), C.DARK, 0, 8)
                dropFrame.ZIndex = Z.DROPDOWN
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
                    optBtn.Font = FONT_BOLD
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

                    table.insert(conns, optBtn.MouseEnter:Connect(function()
                        if i ~= selectedIdx then tw(optBtn, { BackgroundColor3 = C.BTN, TextColor3 = C.TEXT }, 0.12) end
                    end))
                    table.insert(conns, optBtn.MouseLeave:Connect(function()
                        if i ~= selectedIdx then tw(optBtn, { BackgroundColor3 = C.DARK, TextColor3 = C.DIM }, 0.12) end
                    end))
                    table.insert(conns, optBtn.MouseButton1Click:Connect(function()
                        tw(optBtn, { BackgroundColor3 = C.ACCENT }, 0.08)
                        pcall(function() task.delay(0.14, function() pcall(function()
                            selectedIdx = i
                            layoutDropBtn.Text = opt
                            setTabLayout(opt == "Horizontal", true)
                            closeDrop()
                        end) end) end)
                    end))
                end

                tw(dropShadow, { Size = UDim2.new(0, LAYOUT_DROP_W, 0, targetH) }, 0.25, Enum.EasingStyle.Quint)
                tw(dropFrame, { Size = UDim2.new(0, LAYOUT_DROP_W, 0, targetH) }, 0.25, Enum.EasingStyle.Quint)

                if closeConn then closeConn:Disconnect() closeConn = nil end
                closeConn = UserInputService.InputBegan:Connect(function(input)
                    if not ddOpen then if closeConn then closeConn:Disconnect() closeConn = nil end return end
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
            end

            table.insert(conns, layoutDropBtn.MouseButton1Click:Connect(openDrop))

            if not _G._MenuDropdowns then _G._MenuDropdowns = {} end
            _G._MenuDropdowns["Appearance_Tab layout"] = {
                Get = function() return layoutOptions[selectedIdx], selectedIdx end,
                Set = function(idx)
                    idx = tonumber(idx)
                    if not idx or not layoutOptions[idx] then return end
                    selectedIdx = idx
                    layoutDropBtn.Text = layoutOptions[idx]
                    setTabLayout(layoutOptions[idx] == "Horizontal", false)
                end,
                GetOptions = function() return layoutOptions end,
            }
        end
    end

    addSettingOption("Appearance", "Blur background", true, function(on)
        M.BlurEnabled = on
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
            pcall(function() task.delay(0.25, function() pcall(function() if currentBlur and not M.BlurEnabled then currentBlur:Destroy() if blurPart == currentBlur then blurPart = nil end end end) end) end)
        end
    end, false)

    addSettingOption("Performance", "Lighting preset dim", true, function(on)
        M.LightingDimEnabled = on
        if on then
            if not M.OriginalBrightness then
                M.OriginalBrightness = Lighting.Brightness
                M.OriginalClockTime = Lighting.ClockTime
            end
            Lighting.Brightness = 0.3
            Lighting.ClockTime = 0
        elseif M.OriginalBrightness then
            Lighting.Brightness = M.OriginalBrightness
            Lighting.ClockTime = M.OriginalClockTime
        end
    end, false)
    addSettingOption("Performance", "Low quality mode", true, function(on)
        if on then
            if not M.OriginalQualityLevel then M.OriginalQualityLevel = settings().Rendering.QualityLevel end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        elseif M.OriginalQualityLevel then
            settings().Rendering.QualityLevel = M.OriginalQualityLevel
        end
    end, false)

    do
        local playersScroll = settingsTabs["Players"]
        if playersScroll then
            if not _G._FriendsList then _G._FriendsList = {} end

            local friendsFolder = "MenuLibConfigs"
            local friendsFile = friendsFolder .. "/" .. tostring(lp.UserId):gsub("[^%w]", "_") .. "_friends.json"

            local function SaveFriendsToFile()
                if makefolder and isfolder and not isfolder(friendsFolder) then
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

            local columnsRow = fr(playersScroll, UDim2.new(1, -10, 1, -10), nil, C.CONTENT, 1, 0)
            columnsRow.LayoutOrder = 1

            local leftCol = fr(columnsRow, UDim2.new(0.5, -4, 1, 0), UDim2.new(0, 0, 0, 0), C.HEADER, 0, 12)

            local leftHeader = fr(leftCol, UDim2.new(1, 0, 0, 36), nil, C.DARK, 0, UDim.new(0, 12))
            lbl(leftHeader, "Players", UDim2.new(0, 80, 1, 0), UDim2.new(0, 12, 0, 0), 14, C.TEXT, FONT_BOLD)
            local playerCountLbl = lbl(leftHeader, "0", UDim2.new(0, 30, 0, 18), UDim2.new(0, 80, 0.5, -9), 10, C.ACCENT, FONT_BOLD)
            playerCountLbl.BackgroundColor3 = C.SEL
            playerCountLbl.BackgroundTransparency = 0
            playerCountLbl.TextXAlignment = Enum.TextXAlignment.Center
            Instance.new("UICorner", playerCountLbl).CornerRadius = UDim.new(0, 6)

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
            playerSearchBox.Font = FONT
            playerSearchBox.ClearTextOnFocus = false
            playerSearchBox.TextXAlignment = Enum.TextXAlignment.Left
            playerSearchBox.Parent = playerSearchBar

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

            local rightCol = fr(columnsRow, UDim2.new(0.5, -4, 1, 0), UDim2.new(0.5, 4, 0, 0), C.HEADER, 0, 12)

            local rightHeader = fr(rightCol, UDim2.new(1, 0, 0, 36), nil, C.DARK, 0, UDim.new(0, 12))
            lbl(rightHeader, "Friends", UDim2.new(0, 80, 1, 0), UDim2.new(0, 12, 0, 0), 14, C.TEXT, FONT_BOLD)
            local friendCountLbl = lbl(rightHeader, "0", UDim2.new(0, 30, 0, 18), UDim2.new(0, 80, 0.5, -9), 10, C.GREEN, FONT_BOLD)
            friendCountLbl.BackgroundColor3 = C.SEL
            friendCountLbl.BackgroundTransparency = 0
            friendCountLbl.TextXAlignment = Enum.TextXAlignment.Center
            Instance.new("UICorner", friendCountLbl).CornerRadius = UDim.new(0, 6)

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
            friendSearchBox.Font = FONT
            friendSearchBox.ClearTextOnFocus = false
            friendSearchBox.TextXAlignment = Enum.TextXAlignment.Left
            friendSearchBox.Parent = friendSearchBar

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

            local refreshPlayerList, refreshFriendList

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

                        local avFrame = fr(row, UDim2.new(0, 26, 0, 26), UDim2.new(0, 6, 0.5, -13), C.DARK, 0, 13)
                        local avFImg = Instance.new("ImageLabel")
                        avFImg.Size = UDim2.new(1, -4, 1, -4)
                        avFImg.Position = UDim2.new(0, 2, 0, 2)
                        avFImg.BackgroundTransparency = 1
                        avFImg.Parent = avFrame
                        Instance.new("UICorner", avFImg).CornerRadius = UDim.new(1, 0)

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

                        local fNameLbl = lbl(row, friendName, UDim2.new(1, -100, 1, 0), UDim2.new(0, 38, 0, 0), 11, C.TEXT, FONT_BOLD)
                        fNameLbl.TextTruncate = Enum.TextTruncate.AtEnd

                        local isOnline = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p.Name == friendName then isOnline = true break end
                        end
                        local onlineDot = fr(row, UDim2.new(0, 8, 0, 8), UDim2.new(0, 38, 0, 4), isOnline and C.GREEN or C.RED, 0, 4)

                        local removeBtn = Instance.new("TextButton")
                        removeBtn.Size = UDim2.new(0, 60, 0, 24)
                        removeBtn.Position = UDim2.new(1, -66, 0.5, -12)
                        removeBtn.BackgroundColor3 = C.RED
                        removeBtn.Text = "Remove"
                        removeBtn.TextColor3 = C.TEXT
                        removeBtn.TextSize = 10
                        removeBtn.Font = FONT_BOLD
                        removeBtn.AutoButtonColor = false
                        removeBtn.Parent = row
                        Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 6)
                        local remGrad = Instance.new("UIGradient", removeBtn)
                        remGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C.RED), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 45, 45))})
                        remGrad.Rotation = 90

                        table.insert(conns, removeBtn.MouseEnter:Connect(function() tw(removeBtn, {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}, 0.12) end))
                        table.insert(conns, removeBtn.MouseLeave:Connect(function() tw(removeBtn, {BackgroundColor3 = C.RED}, 0.12) end))

                        table.insert(conns, removeBtn.MouseButton1Click:Connect(function()
                            for idx, fn in ipairs(_G._FriendsList) do
                                if fn == friendName then
                                    table.remove(_G._FriendsList, idx)
                                    break
                                end
                            end
                            SaveFriendsToFile()
                            tw(row, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.15)
                            pcall(function() task.delay(0.15, function() pcall(function()
                                row:Destroy()
                                refreshFriendList(friendSearchBox.Text)
                                refreshPlayerList(playerSearchBox.Text)
                            end) end) end)
                        end))

                        local rowBtn = Instance.new("TextButton")
                        rowBtn.Size = UDim2.new(1, -70, 1, 0)
                        rowBtn.BackgroundTransparency = 1
                        rowBtn.Text = ""
                        rowBtn.Parent = row
                        table.insert(conns, rowBtn.MouseEnter:Connect(function() tw(row, {BackgroundColor3 = C.BTNHOV}, 0.1) end))
                        table.insert(conns, rowBtn.MouseLeave:Connect(function() tw(row, {BackgroundColor3 = C.SEL}, 0.1) end))
                    end
                end
                friendCountLbl.Text = tostring(count)
            end

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

                        local pNameLbl = lbl(row, pName, UDim2.new(1, -100, 1, 0), UDim2.new(0, 38, 0, 0), 11, C.TEXT, FONT_BOLD)
                        pNameLbl.TextTruncate = Enum.TextTruncate.AtEnd

                        if player == lp then
                            local youBadge = lbl(row, "YOU", UDim2.new(0, 28, 0, 14), UDim2.new(1, -96, 0.5, -7), 9, C.ACCENT, FONT_BOLD)
                            youBadge.BackgroundColor3 = C.SEL
                            youBadge.BackgroundTransparency = 0
                            youBadge.TextXAlignment = Enum.TextXAlignment.Center
                            Instance.new("UICorner", youBadge).CornerRadius = UDim.new(0, 4)
                        end

                        local isFriend = false
                        for _, fn in ipairs(_G._FriendsList or {}) do
                            if fn == pName then isFriend = true break end
                        end

                        if player ~= lp then
                            if isFriend then
                                local addedLbl = lbl(row, "✓ Friend", UDim2.new(0, 56, 0, 24), UDim2.new(1, -62, 0.5, -12), 10, C.GREEN, FONT_BOLD)
                                addedLbl.TextXAlignment = Enum.TextXAlignment.Center
                            else
                                local addBtn = Instance.new("TextButton")
                                addBtn.Size = UDim2.new(0, 46, 0, 24)
                                addBtn.Position = UDim2.new(1, -52, 0.5, -12)
                                addBtn.BackgroundColor3 = C.ACCENT
                                addBtn.Text = "✓"
                                addBtn.TextColor3 = C.TEXT
                                addBtn.TextSize = 10
                                addBtn.Font = FONT_BOLD
                                addBtn.AutoButtonColor = false
                                addBtn.Parent = row
                                Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 6)
                                local addGrad = Instance.new("UIGradient", addBtn)
                                addGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C.ACCENT), ColorSequenceKeypoint.new(1, C.ACCENT2)})
                                addGrad.Rotation = 90

                                table.insert(conns, addBtn.MouseEnter:Connect(function() tw(addBtn, {BackgroundColor3 = Color3.fromRGB(140, 50, 255)}, 0.12) end))
                                table.insert(conns, addBtn.MouseLeave:Connect(function() tw(addBtn, {BackgroundColor3 = C.ACCENT}, 0.12) end))

                                table.insert(conns, addBtn.MouseButton1Click:Connect(function()
                                    table.insert(_G._FriendsList, pName)
                                    SaveFriendsToFile()
                                    tw(addBtn, {BackgroundColor3 = C.GREEN}, 0.1)
                                    addBtn.Text = "✓"
                                    task.delay(0.3, function() pcall(function()
                                        refreshPlayerList(playerSearchBox.Text)
                                        refreshFriendList(friendSearchBox.Text)
                                    end) end)
                                end))
                            end
                        end

                        local rowBtn = Instance.new("TextButton")
                        rowBtn.Size = UDim2.new(1, -56, 1, 0)
                        rowBtn.BackgroundTransparency = 1
                        rowBtn.Text = ""
                        rowBtn.Parent = row
                        table.insert(conns, rowBtn.MouseEnter:Connect(function() tw(row, {BackgroundColor3 = C.BTNHOV}, 0.1) end))
                        table.insert(conns, rowBtn.MouseLeave:Connect(function() tw(row, {BackgroundColor3 = C.SEL}, 0.1) end))
                    end
                end
                playerCountLbl.Text = tostring(count)
            end

            table.insert(conns, playerSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                refreshPlayerList(playerSearchBox.Text)
            end))
            table.insert(conns, friendSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                refreshFriendList(friendSearchBox.Text)
            end))

            table.insert(conns, Players.PlayerAdded:Connect(function()
                pcall(function() task.delay(0.5, function() pcall(refreshPlayerList, playerSearchBox.Text) end) end)
            end))
            table.insert(conns, Players.PlayerRemoving:Connect(function()
                pcall(function() task.delay(0.1, function() pcall(refreshPlayerList, playerSearchBox.Text) pcall(refreshFriendList, friendSearchBox.Text) end) end)
            end))

            refreshPlayerList("")
            refreshFriendList("")

            _G._SaveFriendsList = SaveFriendsToFile
            _G._RefreshFriendsList = function()
                pcall(refreshFriendList, "")
                pcall(refreshPlayerList, "")
            end
        end
    end

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
        keyBtn.Font = FONT_BOLD
        keyBtn.Parent = row
        Instance.new("UICorner").Parent = keyBtn

        local currentKey = key

        local function displayFor(k)
            if typeof(k) == "EnumItem" then
                if k.EnumType == Enum.KeyCode then return k.Name end
                if k.EnumType == Enum.UserInputType then return (k.Name:gsub("MouseButton", "MB")) end
            end
            return tostring(k)
        end

        local function assignKey(k, fire)
            if typeof(k) ~= "EnumItem" then return end
            currentKey = k
            keyText = displayFor(k)
            keyBtn.Text = keyText
            keyBtn.BackgroundColor3 = C.SEL
            if fire ~= false then pcall(onChange, k) end
        end

        local kb = {
            Get = function()
                if typeof(currentKey) == "EnumItem" then
                    return { t = tostring(currentKey.EnumType), n = currentKey.Name }
                end
                return nil
            end,
            Set = function(v)
                if type(v) ~= "table" or not v.n then return end
                local resolved = nil
                if v.t == "Enum.UserInputType" then
                    resolved = Enum.UserInputType[v.n]
                else
                    resolved = Enum.KeyCode[v.n]
                end
                if resolved then assignKey(resolved, true) end
            end,
            GetKey = function() return currentKey end,
            SetKey = function(k) assignKey(k, true) end,
        }
        if not _G._MenuKeybinds then _G._MenuKeybinds = {} end
        _G._MenuKeybinds[tabName .. "_" .. label] = kb
        table.insert(conns, keyBtn.MouseButton1Click:Connect(function()
            keyBtn.Text = "..."
            keyBtn.BackgroundColor3 = C.ACCENT
            settingKeybind = true
            local conn
            local timeoutToken
            local function cleanup()
                pcall(function() if conn then conn:Disconnect() end end)
                if timeoutToken then pcall(function() task.cancel(timeoutToken) end) end
                settingKeybind = false
            end
            conn = UserInputService.InputBegan:Connect(function(inp, gpe)
                if gpe then return end
                if inp.KeyCode == Enum.KeyCode.Escape then
                    cleanup()
                    keyBtn.Text = keyText
                    keyBtn.BackgroundColor3 = C.SEL
                    return
                end
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
                    cleanup()
                    assignKey(selectedKey, true)
                end
            end)
            timeoutToken = task.delay(5, function()
                pcall(cleanup)
                keyBtn.Text = keyText
                keyBtn.BackgroundColor3 = C.SEL
            end)
        end))
        return kb
    end

    addKeybindOption("Keybinds", "Toggle menu key", M.MenuToggleKey, function(k) M.MenuToggleKey = k end)
    addKeybindOption("Keybinds", "Unload script key", M.UnloadKey, function(k) M.UnloadKey = k end)

    local inSettings = false
    local isTransitioning = false

    local function openSettings()
        if inSettings or isTransitioning then return end
        inSettings = true
        isTransitioning = true
        tw(homeBtn, { Rotation = homeBtn.Rotation + 360 }, 0.5)
        tw(homeBtnIcon1, { ImageTransparency = 1 }, 0.25)
        tw(homeBtnIcon2, { ImageTransparency = 0 }, 0.25)

        tw(win, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.2)
        pcall(function() task.delay(0.2, function() pcall(function() win.Visible = false end) end) end)

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
        pcall(function() task.delay(0.25, function() isTransitioning = false end) end)
    end

    local function closeSettings()
        if not inSettings or isTransitioning then return end
        inSettings = false
        isTransitioning = true
        tw(homeBtn, { Rotation = homeBtn.Rotation - 360 }, 0.5)
        tw(homeBtnIcon1, { ImageTransparency = 0 }, 0.25)
        tw(homeBtnIcon2, { ImageTransparency = 1 }, 0.25)

        tw(settingsPanel, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.2)
        pcall(function() task.delay(0.2, function() pcall(function()
            settingsPanel.Visible = false
        end) end) end)

        win.Size = UDim2.new(0, 0, 0, 0)
        win.Position = UDim2.new(0.5, 0, 0.5, 0)
        win.Visible = true
        tw(win, { Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2) }, 0.25)
        pcall(function() task.delay(0.25, function() isTransitioning = false end) end)
    end

    local function closeMenu()
        if not win.Visible and not settingsPanel.Visible then
            pcall(ensureUnlocked)
            return
        end
        isOpen = false
        for _, closer in ipairs(activeDropdownClosers) do
            pcall(closer)
        end
        table.clear(activeDropdownClosers)
        if blurPart and M.BlurEnabled then
            tw(blurPart, {Size = 0}, 0.15)
            local currentBlur = blurPart
            pcall(function() task.delay(0.15, function() pcall(function() if currentBlur then currentBlur:Destroy() if blurPart == currentBlur then blurPart = nil end end end) end) end)
        end
        if inSettings then
            unlockInput()
            tw(settingsPanel, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.15)
            pcall(function() task.delay(0.15, function() pcall(function() settingsPanel.Visible = false end) end) end)
        else
            unlockInput()
            tw(win, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.15)
            pcall(function() task.delay(0.15, function() pcall(function() win.Visible = false end) end) end)
        end
    end

    local function openMenu()
        if not win or not settingsPanel then return end
        if win.Visible or settingsPanel.Visible then return end
        isOpen = true
        fpsT = 0
        fpsN = 0
        lockInput()
        if hudBar then hudBar.Visible = true end
        if M.BlurEnabled then
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

    function toggleMenu()
        if isOpen then
            closeMenu()
        else
            openMenu()
        end
    end

    table.insert(conns, fireClick.MouseButton1Click:Connect(toggleMenu))

    table.insert(conns, homeBtn.MouseButton1Click:Connect(function()
        if inSettings then
            closeSettings()
        else
            openSettings()
        end
    end))

    table.insert(conns, homeBtn.MouseEnter:Connect(function() tw(homeBtn, { BackgroundTransparency = 0.05 }, 0.12) end))
    table.insert(conns, homeBtn.MouseLeave:Connect(function() tw(homeBtn, { BackgroundTransparency = 0.2 }, 0.12) end))

    local dragging = false
    local dragOrig = Vector2.zero
    local winOrig = UDim2.new()
    local settingsOrig = UDim2.new()
    local dragTarget = nil
    local guiInset = Vector2.new(0, 0)
    pcall(function()
        local gi = game:GetService("GuiService"):GetGuiInset()
        guiInset = Vector2.new(gi.X, gi.Y)
    end)

    table.insert(conns, dragHandle.InputBegan:Connect(function(inp)
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
    end))

    table.insert(conns, dragHandle.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragTarget = nil
        end
    end))

    table.insert(conns, settingsDrag.InputBegan:Connect(function(inp)
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
    end))

    table.insert(conns, settingsDrag.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragTarget = nil
        end
    end))

    table.insert(conns, UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and dragging and dragTarget then
            local mp = UserInputService:GetMouseLocation()
            if dragTarget == "settings" and settingsPanel then
                pcall(function()
                    settingsPanel.Position = UDim2.new(0, settingsOrig.X.Offset + (mp.X - dragOrig.X), 0, settingsOrig.Y.Offset + (mp.Y - dragOrig.Y))
                end)
            elseif dragTarget == "main" and win then
                pcall(function()
                    win.Position = UDim2.new(0, winOrig.X.Offset + (mp.X - dragOrig.X), 0, winOrig.Y.Offset + (mp.Y - dragOrig.Y))
                end)
            end
        end
    end))

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

    task.defer(function() pcall(function() updateHudLayout(false) end) end)
    table.insert(conns, nameLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, fpsLbl:GetPropertyChangedSignal("Text"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, fpsLbl:GetPropertyChangedSignal("Visible"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, fpsLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, pingLbl:GetPropertyChangedSignal("Visible"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, timeLbl:GetPropertyChangedSignal("Visible"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, pingLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))
    table.insert(conns, timeLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end))

    fpsT, fpsN = 0, 0

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

        if M.LightingDimEnabled then
            pcall(function()
                if Lighting.Brightness ~= 0.3 then Lighting.Brightness = 0.3 end
                if Lighting.ClockTime ~= 0 then Lighting.ClockTime = 0 end
            end)
        end

    end))

    table.insert(conns, UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        local toggleKey = M.MenuToggleKey or Enum.KeyCode.Insert
        local unloadKey = M.UnloadKey or Enum.KeyCode.End

        if inp.KeyCode == unloadKey then
            settingKeybind = false
            unloaded = true

            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
            table.clear(conns)

            pcall(function() RunService:UnbindFromRenderStep(RS_BIND_INP) end)

            isOpen = false
            controlsDisabledByUs = false
            if inputBlocker then
                pcall(function() inputBlocker.Visible = false end)
            end
            local ctrl = ensureControls()
            if ctrl then pcall(function() ctrl:Enable() end) end
            pcall(function() UserInputService.MouseIconEnabled = (prevMouseIconEnabled ~= false) end)
            pcall(applyGameMouseState)
            pcall(function()
                task.delay(0.5, function()
                    pcall(applyGameMouseState)
                end)
            end)
            pcall(function()
                local lp = game:GetService("Players").LocalPlayer
                if lp then
                    local ps = lp:FindFirstChild("PlayerScripts")
                    if ps then
                        local pm = ps:FindFirstChild("PlayerModule")
                        if pm then
                            local okPM, PM = pcall(function() return require(pm) end)
                            if okPM and PM and PM.GetControls then
                                local okCtrl, ctrl2 = pcall(PM.GetControls, PM)
                                if okCtrl and ctrl2 then pcall(ctrl2.Enable, ctrl2) end
                            end
                        end
                    end
                end
            end)

            if M.OriginalBrightness then
                Lighting.Brightness = M.OriginalBrightness
                Lighting.ClockTime = M.OriginalClockTime
            end

            if M.OriginalQualityLevel then
                settings().Rendering.QualityLevel = M.OriginalQualityLevel
            end

            if blurPart then pcall(function() blurPart:Destroy() end) blurPart = nil end

            pcall(function() sg:Destroy() end)

            M.AutoRefresh = nil
            M.BlurEnabled = nil
            M.LightingDimEnabled = nil
            M.OriginalBrightness = nil
            M.OriginalClockTime = nil
            M.OriginalQualityLevel = nil
            M.MenuToggleKey = nil
            M.UnloadKey = nil
            M.SmoothAnimations = nil
            M.ESPColour = nil
            _G._MenuLib = nil
            _G._MenuToggles = nil
            _G._MenuSliders = nil
            _G._MenuDropdowns = nil
            _G._MenuColorPickers = nil
            _G._MenuTextBoxes = nil
            _G._ConfigList = nil
            _G._CurrentConfig = nil
            _G._ConfigLoaded = nil
            _G._FriendsList = nil
            _G._MenuKeybinds = nil
            _G._ConfigExtensions = nil
            _G._ConfigLoading = nil
            _G._SaveConfigList = nil
            _G._SaveFriendsList = nil
            _G._RefreshFriendsList = nil
            _G.GetConfigData = nil
            _G.LoadConfigData = nil
            settingKeybind = false
        elseif inp.KeyCode == toggleKey and not settingKeybind then
            toggleMenu()
        end
    end))

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

    local tabPanels = {}

    local function getContainer(tabName, side)
        local tf = tabContents[tabName]
        if not tf then return nil, false end
        local panels = tabPanels[tabName]
        if panels then
            local panel = (side == "right") and panels.rightPanel or panels.leftPanel
            return panel, true
        end
        local scroll = tf:FindFirstChildWhichIsA("ScrollingFrame") or tf
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChildWhichIsA("UIListLayout") then
                return child, false
            end
        end
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
        if type(tabName) ~= "string" or type(label) ~= "string" then return nil end
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
        toggle.SetVisible = function(visible) pcall(function() row.Visible = visible and true or false end) end
        if not _G._MenuToggles then _G._MenuToggles = {} end
        _G._MenuToggles[tabName .. "_" .. label] = toggle
        return toggle
    end

    API.AddSlider = function(tabName, label, min, max, callback, default, side)
        if type(tabName) ~= "string" or type(label) ~= "string" then return nil end
        if type(min) ~= "number" or type(max) ~= "number" or min >= max then return nil end
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end

        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1, 0, 0, 50), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)

        lbl(row, label, UDim2.new(1, -20, 0, 20), UDim2.new(0, 14, 0, 4), 12, C.TEXT)
        local valueLbl = lbl(row, tostring(default or min), UDim2.new(0, 40, 0, 20), UDim2.new(1, -50, 0, 4), 12, C.ACCENT, FONT_BOLD)
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
        table.insert(conns, track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                local absX = inp.Position.X - track.AbsolutePosition.X
                local percent = math.clamp(absX / track.AbsoluteSize.X, 0, 1)
                value = min + (percent * range)
                updateVisuals(true)
                if callback then pcall(callback, value) end
            end
        end))

        table.insert(conns, UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local absX = inp.Position.X - track.AbsolutePosition.X
                local percent = math.clamp(absX / track.AbsoluteSize.X, 0, 1)
                value = min + (percent * range)
                updateVisuals(true)
                if callback then pcall(callback, value) end
            end
        end))

        table.insert(conns, UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end))

        local sl = { Get = function() return value end, Set = function(v) value = math.clamp(v, min, max) updateVisuals(true) if callback then pcall(callback, value) end end }
        sl.Row = row
        sl.SetVisible = function(visible) pcall(function() row.Visible = visible and true or false end) end
        if not _G._MenuSliders then _G._MenuSliders = {} end
        _G._MenuSliders[tabName .. "_" .. label] = sl
        return sl
    end

    API.AddColorPicker = function(tabName, label, callback, defaultColor, side, compact)
        local compactMode = type(compact) == "table" and compact.Row ~= nil
        if not compactMode and (type(tabName) ~= "string" or type(label) ~= "string") then return nil end
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
        btn.Font = FONT_BOLD
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
            table.insert(conns, btn.MouseEnter:Connect(function() tw(btn, { BackgroundColor3 = C.BTNHOV }, 0.12) end))
            table.insert(conns, btn.MouseLeave:Connect(function() tw(btn, { BackgroundColor3 = C.BTN }, 0.12) end))
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
                pcall(function() task.delay(0.16, function() pcall(function() if closingFrame then closingFrame:Destroy() end end) end) end)
            end
        end
        table.insert(activeDropdownClosers, closePicker)

        table.insert(conns, btn.MouseButton1Click:Connect(function()
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
            pickerFrame.ZIndex = Z.DROPDOWN
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
                if input and input.Position then
                    return Vector2.new(input.Position.X, input.Position.Y)
                end
                return UserInputService:GetMouseLocation()
            end

            local header = z(fr(pickerFrame, UDim2.new(1, 0, 0, 34), nil, C.DARK, 0.05, 12), 1001)
            local title = lbl(header, label, UDim2.new(1, -92, 1, 0), UDim2.fromOffset(14, 0), 12, C.TEXT, FONT_BOLD)
            title.ZIndex = 1002
            title.TextTruncate = Enum.TextTruncate.AtEnd

            local livePreview = z(fr(header, UDim2.fromOffset(22, 22), UDim2.new(1, -58, 0.5, -11), color, 0, 11), 1002)
            roundedStroke(livePreview, 11, Color3.fromRGB(245, 245, 255), 0.25, 1)

            local closeButton = Instance.new("TextButton")
            closeButton.Size = UDim2.fromOffset(24, 24)
            closeButton.Position = UDim2.new(1, -30, 0.5, -12)
            closeButton.BackgroundColor3 = C.BTN
            closeButton.BackgroundTransparency = 0.15
            closeButton.Text = "×"
            closeButton.TextColor3 = C.SEC
            closeButton.TextSize = 18
            closeButton.Font = FONT_BOLD
            closeButton.AutoButtonColor = false
            closeButton.ZIndex = 1004
            closeButton.Parent = header
            roundedStroke(closeButton, 7, Color3.fromRGB(255, 255, 255), 0.88, 1)
            table.insert(pickerConnections, closeButton.MouseEnter:Connect(function()
                tw(closeButton, { BackgroundColor3 = C.BTNHOV, TextColor3 = C.TEXT }, 0.1)
            end))
            table.insert(pickerConnections, closeButton.MouseLeave:Connect(function()
                tw(closeButton, { BackgroundColor3 = C.BTN, TextColor3 = C.SEC }, 0.1)
            end))
            table.insert(pickerConnections, closeButton.MouseButton1Click:Connect(closePicker))

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

            local alphaLabel = lbl(pickerFrame, "Opacity", UDim2.fromOffset(54, 16), UDim2.fromOffset(CANVAS_X, 188), 10, C.DIM, FONT_BOLD)
            alphaLabel.ZIndex = 1001
            local alphaValue = lbl(pickerFrame, "100%", UDim2.fromOffset(45, 16), UDim2.new(1, -57, 0, 188), 10, C.SEC, FONT_BOLD)
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
                UDim2.new(0, alpha * CANVAS_W - 6, 0.5, -9),
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

                local channelLabel = lbl(field, channel, UDim2.fromOffset(14, 26), UDim2.fromOffset(8, 0), 10, C.DIM, FONT_BOLD)
                channelLabel.ZIndex = 1002

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(1, -27, 1, 0)
                box.Position = UDim2.fromOffset(24, 0)
                box.BackgroundTransparency = 1
                box.TextColor3 = C.TEXT
                box.PlaceholderColor3 = C.DIM
                box.TextSize = 11
                box.Font = FONT_BOLD
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
                table.insert(pickerConnections, swatch.MouseEnter:Connect(function()
                    tw(swatch, { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(swatchX - 1, swatchY - 1) }, 0.1)
                end))
                table.insert(pickerConnections, swatch.MouseLeave:Connect(function()
                    tw(swatch, { Size = UDim2.fromOffset(14, 14), Position = swatchPosition }, 0.1)
                end))
                table.insert(pickerConnections, swatch.MouseButton1Click:Connect(function()
                    color = presetColor
                    h, s, v = color:ToHSV()
                    if openRefresh then openRefresh(true) end
                end))
            end

            local doneButton = Instance.new("TextButton")
            doneButton.Size = UDim2.fromOffset(CANVAS_W, 24)
            doneButton.Position = UDim2.fromOffset(CANVAS_X, 290)
            doneButton.BackgroundColor3 = C.ACCENT
            doneButton.Text = "Done"
            doneButton.TextColor3 = C.TEXT
            doneButton.TextSize = 11
            doneButton.Font = FONT_BOLD
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
            table.insert(pickerConnections, doneButton.MouseEnter:Connect(function() tw(doneButton, { BackgroundTransparency = 0.08 }, 0.1) end))
            table.insert(pickerConnections, doneButton.MouseLeave:Connect(function() tw(doneButton, { BackgroundTransparency = 0 }, 0.1) end))
            table.insert(pickerConnections, doneButton.MouseButton1Click:Connect(closePicker))

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
                alphaKnob.Position = UDim2.new(0, alpha * CANVAS_W - 6, 0.5, -9)
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

            table.insert(pickerConnections, svButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    beginControlDrag("sv", input)
                end
            end))
            table.insert(pickerConnections, hueButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    beginControlDrag("hue", input)
                end
            end))
            table.insert(pickerConnections, alphaButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    beginControlDrag("alpha", input)
                end
            end))

            table.insert(pickerConnections, headerDrag.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    popupDragging = true
                    popupDragStart = getPointerPosition(input)
                    popupStartPosition = Vector2.new(pickerFrame.AbsolutePosition.X, pickerFrame.AbsolutePosition.Y)
                end
            end))

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
                table.insert(pickerConnections, box.FocusLost:Connect(function()
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
                end))
            end
        end))

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
        _G._MenuColorPickers[tabName .. "_" .. label] = cp
        return cp
    end


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

    API.AddDropdown = function(tabName, label, options, callback, defaultIndex, side)
        if type(tabName) ~= "string" or type(label) ~= "string" then return nil end
        if type(options) ~= "table" or #options == 0 then return nil end
        local container, isPanel = getContainer(tabName, side)
        if not container then return nil end

        local rowBg = isPanel and C.HEADER or C.SEL
        local row = fr(container, UDim2.new(1, 0, 0, 40), nil, rowBg, 0, 10)
        row.LayoutOrder = #container:GetChildren()
        local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
        gradV(stripe, C.ACCENT, C.ACCENT2)

        lbl(row, label, UDim2.new(1, -155, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)

        local selectedIndex = defaultIndex or 1
        local ddIsOpen = false
        local DROP_W = 130

        local dropdownBtn = Instance.new("TextButton")
        dropdownBtn.Size = UDim2.new(0, DROP_W, 0, 28)
        dropdownBtn.Position = UDim2.new(1, -(DROP_W + 8), 0.5, -14)
        dropdownBtn.BackgroundColor3 = C.DARK
        dropdownBtn.Text = options[selectedIndex] or "Select"
        dropdownBtn.TextColor3 = C.TEXT
        dropdownBtn.TextSize = 11
        dropdownBtn.Font = FONT_BOLD
        dropdownBtn.TextXAlignment = Enum.TextXAlignment.Center
        dropdownBtn.TextTruncate = Enum.TextTruncate.AtEnd
        dropdownBtn.Parent = row
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = dropdownBtn

        local btnPad = Instance.new("UIPadding")
        btnPad.PaddingRight = UDim.new(0, 18)
        btnPad.PaddingLeft = UDim.new(0, 4)
        btnPad.Parent = dropdownBtn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = C.DIV
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.5
        btnStroke.Parent = dropdownBtn

        local chevron = Instance.new("ImageLabel")
        chevron.Size = UDim2.new(0, 10, 0, 10)
        chevron.Position = UDim2.new(1, -16, 0.5, -5)
        chevron.BackgroundTransparency = 1
        chevron.Image = "rbxassetid://6031091004"
        chevron.ImageColor3 = C.ACCENT
        chevron.Parent = dropdownBtn

        table.insert(conns, dropdownBtn.MouseEnter:Connect(function()
            tw(dropdownBtn, { BackgroundColor3 = C.BTN }, 0.15)
            tw(btnStroke, { Color = C.ACCENT, Transparency = 0.3 }, 0.15)
        end))
        table.insert(conns, dropdownBtn.MouseLeave:Connect(function()
            tw(dropdownBtn, { BackgroundColor3 = C.DARK }, 0.15)
            tw(btnStroke, { Color = C.DIV, Transparency = 0.5 }, 0.15)
        end))

        local dropdownFrame = nil
        local shadow = nil
        local closeConn = nil
        local optionButtons = {}

        local function closeDropdown()
            ddIsOpen = false
            if closeConn then pcall(function() closeConn:Disconnect() end) closeConn = nil end
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
                pcall(function() task.delay(0.25, function() pcall(function() if capturedFrame then capturedFrame:Destroy() end if capturedShadow then capturedShadow:Destroy() end end) end) end)
            end
            optionButtons = {}
        end

        local function openDropdown()
            if ddIsOpen then closeDropdown() return end
            ddIsOpen = true

            tw(chevron, { Rotation = 180 }, 0.2)

            local btnAbsPos = dropdownBtn.AbsolutePosition
            local btnAbsSize = dropdownBtn.AbsoluteSize

            local dropY = btnAbsPos.Y + btnAbsSize.Y + 4
            local dropX = btnAbsPos.X

            local targetHeight = math.min(#options * 30 + 12, 150)

            shadow = fr(sg, UDim2.new(0, DROP_W, 0, 0),
                UDim2.new(0, dropX + 2, 0, dropY + 2), Color3.fromRGB(0, 0, 0), 0.7, 8)
            shadow.ZIndex = Z.DROPDOWN_SHADOW

            dropdownFrame = fr(sg, UDim2.new(0, DROP_W, 0, 0),
                UDim2.new(0, dropX, 0, dropY), C.DARK, 0, 8)
            dropdownFrame.ZIndex = Z.DROPDOWN
            dropdownFrame.ClipsDescendants = true

            local dropStroke = Instance.new("UIStroke")
            dropStroke.Color = C.ACCENT
            dropStroke.Thickness = 1.5
            dropStroke.Transparency = 0.4
            dropStroke.Parent = dropdownFrame

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
                optBtn.BackgroundColor3 = (i == selectedIndex) and Color3.fromRGB(40, 20, 70) or C.DARK
                optBtn.Text = opt
                optBtn.TextColor3 = (i == selectedIndex) and C.TEXT or C.DIM
                optBtn.TextSize = 11
                optBtn.Font = FONT_BOLD
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

                table.insert(conns, optBtn.MouseEnter:Connect(function()
                    if i ~= selectedIndex then
                        tw(optBtn, { BackgroundColor3 = C.BTN, TextColor3 = C.TEXT }, 0.12)
                    end
                end))
                table.insert(conns, optBtn.MouseLeave:Connect(function()
                    if i ~= selectedIndex then
                        tw(optBtn, { BackgroundColor3 = C.DARK, TextColor3 = C.DIM }, 0.12)
                    end
                end))

                table.insert(conns, optBtn.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        tw(optBtn, { BackgroundColor3 = C.ACCENT }, 0.08)
                        pcall(function() task.delay(0.14, function() pcall(function()
                            selectedIndex = i
                            dropdownBtn.Text = opt
                            if callback then pcall(callback, opt, i) end
                            closeDropdown()
                        end) end) end)
                    end
                end))

                table.insert(optionButtons, optBtn)
            end

            tw(shadow, { Size = UDim2.new(0, DROP_W, 0, targetHeight) }, 0.25, Enum.EasingStyle.Quint)
            tw(dropdownFrame, { Size = UDim2.new(0, DROP_W, 0, targetHeight) }, 0.25, Enum.EasingStyle.Quint)

            if not ddIsOpen then return end
            if closeConn then pcall(function() closeConn:Disconnect() end) closeConn = nil end
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
        end

        table.insert(conns, dropdownBtn.MouseButton1Click:Connect(openDropdown))
        table.insert(activeDropdownClosers, closeDropdown)

        local dd = {
            Element = dropdownBtn,
            Get = function() return options[selectedIndex], selectedIndex end,
            Set = function(idx) selectedIndex = idx if options[idx] then dropdownBtn.Text = options[idx] end if callback then callback(options[idx], idx) end end,
            GetOptions = function() return options end,
            SetOptions = function(newOpts) options = newOpts selectedIndex = 1 dropdownBtn.Text = options[1] or "Select" end,
            SetText = function(text) dropdownBtn.Text = tostring(text or "") end,
            Row = row,
            SetVisible = function(visible) pcall(function() row.Visible = visible and true or false end) end
        }
        if not _G._MenuDropdowns then _G._MenuDropdowns = {} end
        _G._MenuDropdowns[tabName .. "_" .. label] = dd
        return dd
    end

    API.AddSetting = function(tabName, label, toggleCallback, default)
        return addSettingOption(tabName, label, true, toggleCallback, default)
    end

    API.RegisterConfigExtension = function(name, getter, setter)
        if type(name) ~= "string" or type(getter) ~= "function" or type(setter) ~= "function" then return nil end
        _G._ConfigExtensions = _G._ConfigExtensions or {}
        _G._ConfigExtensions[name] = { Get = getter, Set = setter }
        return _G._ConfigExtensions[name]
    end

    API.SaveCurrentConfig = function()
        if _G._CurrentConfig and _G.GetConfigData and _G._SaveConfigList and _G._ConfigList then
            _G._ConfigList[_G._CurrentConfig] = _G.GetConfigData()
            return _G._SaveConfigList()
        end
        return false
    end

    API.AddKeybindOption = function(tabName, label, key, onChange)
        return addKeybindOption(tabName, label, key, onChange)
    end

    API.AddButton = function(tabName, label, callback)
        if type(tabName) ~= "string" or type(label) ~= "string" then return nil end
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
        btn.Font = FONT_BOLD
        btn.Parent = row
        btn.AutoButtonColor = false
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        local btnGrad = Instance.new("UIGradient")
        btnGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.ACCENT), ColorSequenceKeypoint.new(1, C.ACCENT2) })
        btnGrad.Rotation = 90
        btnGrad.Parent = btn

        table.insert(conns, btn.MouseEnter:Connect(function()
            tw(btn, { BackgroundColor3 = Color3.fromRGB(140, 50, 255) }, 0.12)
        end))
        table.insert(conns, btn.MouseLeave:Connect(function()
            tw(btn, { BackgroundColor3 = C.ACCENT }, 0.12)
        end))

        table.insert(conns, btn.MouseButton1Click:Connect(function()
            if callback then
                pcall(callback)
            end
        end))

        return { Click = function() pcall(callback) end }
    end

    API.AddTextBox = function(tabName, label, callback, defaultText, side)
        if type(tabName) ~= "string" or type(label) ~= "string" then return nil end
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
        tb.Font = FONT
        tb.TextXAlignment = Enum.TextXAlignment.Left
        tb.ClearTextOnFocus = false
        tb.Parent = txtBg

        local entry = { Type = "TextBox", Value = tb.Text, Element = tb, Container = row }
        entry.Get = function() return tb.Text end
        entry.Set = function(v)
            tb.Text = tostring(v or "")
            entry.Value = tb.Text
            if callback then pcall(callback, tb.Text) end
        end
        table.insert(conns, tb.FocusLost:Connect(function()
            if callback then pcall(callback, tb.Text) end
        end))
        table.insert(conns, tb:GetPropertyChangedSignal("Text"):Connect(function()
            entry.Value = tb.Text
        end))
        if not _G._MenuTextBoxes then _G._MenuTextBoxes = {} end
        _G._MenuTextBoxes[tabName .. "_" .. label] = entry

        return entry
    end


    API.Shutdown = function()
        if unloaded then return end
        pcall(unlockInput)
        unloaded = true
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        table.clear(conns)
        pcall(function() RunService:UnbindFromRenderStep(RS_BIND_INP) end)
        isOpen = false
        if blurPart then pcall(function() blurPart:Destroy() end) blurPart = nil end
        pcall(function() sg:Destroy() end)
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

        local card = fr(scroll, UDim2.new(1, -4, 0, 0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
        lbl(card, "Aimbot", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, FONT_BOLD)

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
        lbl(leftPanel, "Main", UDim2.new(1, 0, 0, 0), nil, 14, C.TEXT, FONT_BOLD)

        local rightPanel = fr(mainRow, UDim2.new(0.5, -4, 0, 0), UDim2.new(0.5, 4, 0, 0), C.SEL, 0, 10)
        rightPanel.AutomaticSize = Enum.AutomaticSize.Y
        rightPanel.LayoutOrder = 2
        local rightV = Instance.new("UIListLayout")
        rightV.SortOrder = Enum.SortOrder.LayoutOrder
        rightV.Padding = UDim.new(0, 8)
        rightV.Parent = rightPanel
        pad(rightPanel, 12, 12, 12, 12)
        lbl(rightPanel, "Silent Aim", UDim2.new(1, 0, 0, 0), nil, 14, C.TEXT, FONT_BOLD)

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

        local card = fr(scroll, UDim2.new(1, -4, 0, 0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local v = Instance.new("UIListLayout")
        v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Padding = UDim.new(0, 8)
        v.Parent = card
        pad(card, 16, 16, 16, 16)
        lbl(card, "Visuals", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, FONT_BOLD)

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
        lbl(card, "World", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, FONT_BOLD)
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
        lbl(card, "Misc", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, FONT_BOLD)
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
        lbl(card, "Protections", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, FONT_BOLD)
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
        lbl(card, "Exploits", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, FONT_BOLD)
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
        lbl(card, "Sound Effects", UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, FONT_BOLD)
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

        local card = fr(scroll, UDim2.new(1, 0, 0, 0), nil, C.HEADER, 0, 16)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local cardLayout = Instance.new("UIListLayout")
        cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
        cardLayout.Padding = UDim.new(0, 8)
        cardLayout.Parent = card

        local titleRow = fr(card, UDim2.new(1, 0, 0, 28), nil, C.HEADER, 1, 0)
        titleRow.LayoutOrder = 0
        lbl(titleRow, "Configurations", UDim2.new(1, -20, 1, 0), UDim2.new(0, 14, 0, 0), 14, C.TEXT, FONT_BOLD)

        local mainRow = fr(card, UDim2.new(1, 0, 0, 340), nil, C.HEADER, 1, 0)
        mainRow.LayoutOrder = 1

        local leftPanel = fr(mainRow, UDim2.new(0.5, -6, 1, 0), UDim2.new(0, 0, 0, 0), C.SEL, 0, 10)
        local rightPanel = fr(mainRow, UDim2.new(0.5, -6, 1, 0), UDim2.new(0.5, 6, 0, 0), C.SEL, 0, 10)

        local function makeBtn(parent, text, yPos, col, col2)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -16, 0, 30)
            btn.Position = UDim2.new(0, 8, 0, yPos)
            btn.BackgroundColor3 = col
            btn.Text = text
            btn.TextColor3 = C.TEXT
            btn.TextSize = 12
            btn.Font = FONT_BOLD
            btn.AutoButtonColor = false
            btn.Parent = parent
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            local grad = Instance.new("UIGradient", btn)
            grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, col), ColorSequenceKeypoint.new(1, col2 or col)})
            grad.Rotation = 90
            return btn
        end

        local saveBtn = makeBtn(leftPanel, "Save", 10, C.ACCENT, C.ACCENT2)
        local loadBtn = makeBtn(leftPanel, "Load", 48, C.GREEN, Color3.fromRGB(35, 180, 75))
        local renameBtn = makeBtn(leftPanel, "Rename", 86, C.YELLOW, Color3.fromRGB(230, 160, 20))
        local deleteBtn = makeBtn(leftPanel, "Delete", 124, C.RED, Color3.fromRGB(190, 45, 45))
        local importBtn = makeBtn(leftPanel, "Import from Clipboard", 162, Color3.fromRGB(40, 100, 200), Color3.fromRGB(30, 70, 160))
        local exportBtn = makeBtn(leftPanel, "Export to Clipboard", 200, Color3.fromRGB(180, 60, 200), Color3.fromRGB(140, 40, 170))

        local listTitle = lbl(rightPanel, "Saved Configs", UDim2.new(1, -16, 0, 20), UDim2.new(0, 10, 0, 8), 12, C.TEXT, FONT_BOLD)

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

        local configFolder = "MenuLibConfigs"
        local configFile = configFolder .. "/" .. tostring(lp.UserId):gsub("[^%w]", "_") .. "_configs.json"
        local autoLoadFile = configFolder .. "/" .. tostring(lp.UserId):gsub("[^%w]", "_") .. "_autoload.json"

        local selectedConfig = nil
        local selectedRow = nil

        local function LoadConfigsFromFile()
            if isfile and isfile(configFile) then
                local ok, content = pcall(function() return readfile(configFile) end)
                if ok and content then
                    local ok2, decoded = pcall(function() return HttpService:JSONDecode(content) end)
                    if ok2 and decoded then
                        _G._ConfigList = decoded
                        return true
                    end
                end
            end
            _G._ConfigList = _G._ConfigList or {}
            return false
        end

        local function SaveConfigsToFile()
            if not _G._ConfigList then return false end
            if makefolder and isfolder and not isfolder(configFolder) then
                pcall(function() makefolder(configFolder) end)
            end
            local ok, encoded = pcall(function() return HttpService:JSONEncode(_G._ConfigList) end)
            if ok and encoded and writefile then
                local wok = pcall(function() writefile(configFile, encoded) end)
                return wok
            end
            return false
        end

        local function GetAutoLoadConfig()
            if isfile and isfile(autoLoadFile) then
                local ok, content = pcall(function() return readfile(autoLoadFile) end)
                if ok and content then
                    local ok2, name = pcall(function() return HttpService:JSONDecode(content) end)
                    if ok2 and type(name) == "string" then return name end
                end
            end
            return nil
        end

        local function SetAutoLoadConfig(name)
            if makefolder and isfolder and not isfolder(configFolder) then
                pcall(function() makefolder(configFolder) end)
            end
            if writefile then
                pcall(function() writefile(autoLoadFile, HttpService:JSONEncode(name)) end)
            end
        end

        LoadConfigsFromFile()
        _G._SaveConfigList = SaveConfigsToFile

        local popupOverlay = fr(sg, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0), 0.6, 0)
        popupOverlay.Visible = false
        popupOverlay.ZIndex = Z.POPUP

        local popupFrame = fr(popupOverlay, UDim2.new(0, 280, 0, 120), UDim2.new(0.5, -140, 0.5, -60), C.HEADER, 0, 16)
        popupFrame.ZIndex = Z.POPUP_CONTENT

        local popupTitle = lbl(popupFrame, "Enter Config Name", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, 12), 14, C.TEXT, FONT_BOLD)
        popupTitle.TextXAlignment = Enum.TextXAlignment.Center

        local popupBox = Instance.new("TextBox")
        popupBox.Size = UDim2.new(1, -20, 0, 28)
        popupBox.Position = UDim2.new(0, 10, 0, 44)
        popupBox.BackgroundColor3 = C.SEL
        popupBox.TextColor3 = C.TEXT
        popupBox.TextSize = 12
        popupBox.Font = FONT
        popupBox.PlaceholderText = "Config name..."
        popupBox.ClearTextOnFocus = false
        popupBox.Parent = popupFrame
        popupBox.ZIndex = 102
        Instance.new("UICorner", popupBox).CornerRadius = UDim.new(0, 8)

        local popupBtnRow = fr(popupFrame, UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0, 80), C.HEADER, 1, 0)
        popupBtnRow.ZIndex = 102

        local popupConfirm = Instance.new("TextButton")
        popupConfirm.Size = UDim2.new(0.48, 0, 1, 0)
        popupConfirm.BackgroundColor3 = C.GREEN
        popupConfirm.Text = "OK"
        popupConfirm.TextColor3 = C.TEXT
        popupConfirm.TextSize = 12
        popupConfirm.Font = FONT_BOLD
        popupConfirm.Parent = popupBtnRow
        popupConfirm.ZIndex = 103
        Instance.new("UICorner", popupConfirm).CornerRadius = UDim.new(0, 6)

        local popupCancel = Instance.new("TextButton")
        popupCancel.Size = UDim2.new(0.48, 0, 1, 0)
        popupCancel.Position = UDim2.new(0.52, 0, 0, 0)
        popupCancel.BackgroundColor3 = C.BTN
        popupCancel.Text = "Cancel"
        popupCancel.TextColor3 = C.DIM
        popupCancel.TextSize = 12
        popupCancel.Font = FONT_BOLD
        popupCancel.Parent = popupBtnRow
        popupCancel.ZIndex = 103
        Instance.new("UICorner", popupCancel).CornerRadius = UDim.new(0, 6)
        local cancelStroke = Instance.new("UIStroke")
        cancelStroke.Color = C.DIM
        cancelStroke.Thickness = 1
        cancelStroke.Transparency = 0.5
        cancelStroke.Parent = popupCancel

        local popupMode = "create"
        local renameOldName = nil
        local deleteTargetName = nil

        local function showPopup(mode, title, defaultText)
            if mode ~= "create" and mode ~= "rename" and mode ~= "delete" then return end
            popupMode = mode
            popupTitle.Text = title
            if mode == "delete" then
                popupBox.Visible = false
                popupTitle.Text = "Delete '" .. (defaultText or "?") .. "'?"
                popupTitle.Size = UDim2.new(1, -20, 0, 48)
                popupTitle.Position = UDim2.new(0, 10, 0, 20)
                popupBtnRow.Position = UDim2.new(0, 10, 0, 76)
                popupConfirm.BackgroundColor3 = C.RED
                popupConfirm.Text = "Delete"
            else
                popupBox.Visible = true
                popupTitle.Size = UDim2.new(1, -20, 0, 24)
                popupTitle.Position = UDim2.new(0, 10, 0, 12)
                popupBtnRow.Position = UDim2.new(0, 10, 0, 80)
                popupBox.Text = defaultText or ""
                popupConfirm.BackgroundColor3 = C.GREEN
                popupConfirm.Text = "OK"
            end
            popupOverlay.Visible = true
            popupOverlay.BackgroundTransparency = 1
            popupFrame.Size = UDim2.new(0, 200, 0, 100)
            popupFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
            tw(popupOverlay, {BackgroundTransparency = 0.6}, 0.2)
            tw(popupFrame, {Size = UDim2.new(0, 280, 0, 120), Position = UDim2.new(0.5, -140, 0.5, -60)}, 0.25, Enum.EasingStyle.Back)
            if mode ~= "delete" then
                pcall(function() task.delay(0.15, function() pcall(function() popupBox:CaptureFocus() end) end) end)
            end
        end

        local function hidePopup()
            tw(popupFrame, {Size = UDim2.new(0, 200, 0, 100), Position = UDim2.new(0.5, -100, 0.5, -50)}, 0.2)
            tw(popupOverlay, {BackgroundTransparency = 1}, 0.2)
            pcall(function() task.delay(0.2, function() pcall(function() popupOverlay.Visible = false end) end) end)
        end

        local RefreshConfigList
        RefreshConfigList = function()
            for _, child in ipairs(configScroll:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            selectedConfig = nil
            selectedRow = nil
            if not _G._ConfigList then _G._ConfigList = {} end
            local autoLoadName = GetAutoLoadConfig()
            local sortedNames = {}
            for name in pairs(_G._ConfigList) do sortedNames[#sortedNames+1] = name end
            table.sort(sortedNames)
            for _, name in ipairs(sortedNames) do
                local row = fr(configScroll, UDim2.new(1, 0, 0, 36), nil, C.SEL, 0.8, 6)
                row.LayoutOrder = #configScroll:GetChildren()
                local nameLbl = lbl(row, name, UDim2.new(1, -50, 1, 0), UDim2.new(0, 12, 0, 0), 12, C.TEXT, FONT_BOLD)
                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                local stripe = fr(row, UDim2.new(0, 4, 0.6, 0), UDim2.new(0, 0, 0.2, 0), C.ACCENT, 1, 2)
                gradV(stripe, C.ACCENT, C.ACCENT2)
                local isAutoLoad = (autoLoadName == name)
                local autoLbl = lbl(row, "Auto-Load", UDim2.new(0, 60, 0, 16), UDim2.new(1, -88, 0.5, -8), 10, isAutoLoad and C.GREEN or C.DIM, FONT_BOLD)
                autoLbl.TextXAlignment = Enum.TextXAlignment.Right
                local autoBox = Instance.new("TextButton")
                autoBox.Size = UDim2.new(0, 20, 0, 20)
                autoBox.Position = UDim2.new(1, -26, 0.5, -10)
                autoBox.BackgroundColor3 = isAutoLoad and C.GREEN or C.BTN
                autoBox.Text = isAutoLoad and "X" or ""
                autoBox.TextColor3 = C.TEXT
                autoBox.TextSize = 14
                autoBox.Font = FONT_BOLD
                autoBox.AutoButtonColor = false
                autoBox.Parent = row
                Instance.new("UICorner", autoBox).CornerRadius = UDim.new(0, 4)
                local autoStroke = Instance.new("UIStroke")
                autoStroke.Color = isAutoLoad and C.GREEN or C.DIM
                autoStroke.Thickness = 2
                autoStroke.Transparency = 0.1
                autoStroke.Parent = autoBox
                local clickBtn = Instance.new("TextButton")
                clickBtn.Size = UDim2.new(1, -95, 1, 0)
                clickBtn.BackgroundTransparency = 1
                clickBtn.Text = ""
                clickBtn.Parent = row
                local function selectThis()
                    selectedConfig = name
                    selectedRow = row
                    for _, child in ipairs(configScroll:GetChildren()) do
                        if child:IsA("Frame") then
                            tw(child, {BackgroundTransparency = 1}, 0.15)
                            local sInd = child:FindFirstChildOfClass("Frame")
                            if sInd then tw(sInd, {BackgroundTransparency = 1}, 0.15) end
                        end
                    end
                    tw(row, {Size = UDim2.new(1, 0, 0, 36)}, 0.2, Enum.EasingStyle.Back)
                    tw(row, {BackgroundColor3 = C.ACCENT, BackgroundTransparency = 0.3}, 0.2)
                    tw(stripe, {BackgroundTransparency = 0}, 0.25)
                end
                table.insert(conns, clickBtn.MouseButton1Click:Connect(selectThis))
                table.insert(conns, autoBox.MouseButton1Click:Connect(function()
                    local current = GetAutoLoadConfig()
                    local turningOn = (current ~= name)
                    if turningOn then
                        SetAutoLoadConfig(name)
                    else
                        SetAutoLoadConfig(nil)
                    end
                    autoBox.Text = turningOn and "X" or ""
                    tw(autoBox, {BackgroundColor3 = turningOn and C.GREEN or C.BTN}, 0.15)
                    tw(autoStroke, {Color = turningOn and C.GREEN or C.DIM}, 0.15)
                    tw(autoLbl, {TextColor3 = turningOn and C.GREEN or C.DIM}, 0.15)
                    pcall(function() task.delay(0.2, function() pcall(RefreshConfigList) end) end)
                end))
                table.insert(conns, clickBtn.MouseEnter:Connect(function()
                    if selectedConfig ~= name then
                        tw(row, {BackgroundColor3 = Color3.fromRGB(35, 20, 60)}, 0.1)
                    end
                end))
                table.insert(conns, clickBtn.MouseLeave:Connect(function()
                    if selectedConfig ~= name then
                        tw(row, {BackgroundTransparency = 1}, 0.1)
                    end
                end))
            end
        end

        local function confirmPopup()
            if popupMode == "delete" then
                if deleteTargetName and _G._ConfigList then
                    _G._ConfigList[deleteTargetName] = nil
                    SaveConfigsToFile()
                    local autoLoadName = GetAutoLoadConfig()
                    if autoLoadName == deleteTargetName then SetAutoLoadConfig(nil) end
                    deleteTargetName = nil
                    selectedConfig = nil
                    selectedRow = nil
                    RefreshConfigList()
                end
                hidePopup()
                return
            end
            local name = popupBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if name == "" then hidePopup() return end
            if not _G._ConfigList then _G._ConfigList = {} end
            if popupMode == "create" then
                if _G.GetConfigData then
                    _G._ConfigList[name] = _G.GetConfigData()
                    SaveConfigsToFile()
                    RefreshConfigList()
                end
            elseif popupMode == "rename" and renameOldName then
                if name ~= renameOldName and not _G._ConfigList[name] then
                    _G._ConfigList[name] = _G._ConfigList[renameOldName]
                    _G._ConfigList[renameOldName] = nil
                    local autoLoadName = GetAutoLoadConfig()
                    if autoLoadName == renameOldName then SetAutoLoadConfig(name) end
                    SaveConfigsToFile()
                    RefreshConfigList()
                end
            end
            hidePopup()
        end

        table.insert(conns, saveBtn.MouseButton1Click:Connect(function()
            if selectedConfig and _G._ConfigList[selectedConfig] then
                if _G.GetConfigData then
                    local configData = _G.GetConfigData()
                    if configData and type(configData) == "table" then
                        _G._ConfigList[selectedConfig] = configData
                        SaveConfigsToFile()
                    end
                end
            else
                showPopup("create", "Create New Config", "")
            end
        end))

        table.insert(conns, loadBtn.MouseButton1Click:Connect(function()
            if selectedConfig and _G._ConfigList[selectedConfig] then
                if _G.LoadConfigData then
                    pcall(_G.LoadConfigData, _G._ConfigList[selectedConfig])
                    _G._CurrentConfig = selectedConfig
                end
            end
        end))

        table.insert(conns, renameBtn.MouseButton1Click:Connect(function()
            if selectedConfig then
                renameOldName = selectedConfig
                showPopup("rename", "Rename Config", selectedConfig)
            end
        end))

        table.insert(conns, deleteBtn.MouseButton1Click:Connect(function()
            if selectedConfig and _G._ConfigList then
                deleteTargetName = selectedConfig
                showPopup("delete", "Delete Config", selectedConfig)
            end
        end))

        table.insert(conns, popupConfirm.MouseButton1Click:Connect(confirmPopup))
        table.insert(conns, popupCancel.MouseButton1Click:Connect(hidePopup))
        table.insert(conns, popupBox.FocusLost:Connect(function(enter)
            if enter then confirmPopup() end
        end))

        local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local function b64encode(data)
            if HttpService.Base64Encode then
                local ok, result = pcall(function() return HttpService:Base64Encode(data) end)
                if ok and result then return result end
            end
            local result = {}
            local len = #data
            local i = 1
            while i <= len do
                local a = data:byte(i) or 0
                local b = (i + 1 <= len) and data:byte(i + 1) or 0
                local c = (i + 2 <= len) and data:byte(i + 2) or 0
                local hasB = (i + 1 <= len)
                local hasC = (i + 2 <= len)
                local idx1 = math.floor(a / 4) + 1
                local idx2 = ((a % 4) * 16) + math.floor(b / 16) + 1
                local idx3 = hasB and ((b % 16) * 4 + math.floor(c / 64) + 1) or 1
                local idx4 = hasC and (c % 64 + 1) or 1
                result[#result+1] = b64chars:sub(idx1, idx1)
                result[#result+1] = b64chars:sub(idx2, idx2)
                result[#result+1] = hasB and b64chars:sub(idx3, idx3) or "="
                result[#result+1] = hasC and b64chars:sub(idx4, idx4) or "="
                i = i + 3
            end
            return table.concat(result)
        end

        local function b64decode(data)
            if HttpService.Base64Decode then
                local ok, result = pcall(function() return HttpService:Base64Decode(data) end)
                if ok and result then return result end
            end
            data = data:gsub("[^A-Za-z0-9%+%/]", "")
            if #data % 4 ~= 0 then return nil end
            local result = {}
            local len = #data
            local i = 1
            while i <= len do
                local c1 = data:sub(i, i)
                local c2 = data:sub(i+1, i+1)
                local c3 = data:sub(i+2, i+2)
                local c4 = data:sub(i+3, i+3)
                if c1 == "" or c2 == "" then break end
                local v1 = b64chars:find(c1) - 1
                local v2 = b64chars:find(c2) - 1
                local v3 = (c3 ~= "" and c3 ~= "=") and (b64chars:find(c3) - 1) or 0
                local v4 = (c4 ~= "" and c4 ~= "=") and (b64chars:find(c4) - 1) or 0
                result[#result+1] = string.char((v1 * 4) + math.floor(v2 / 16))
                if c3 ~= "" and c3 ~= "=" then
                    result[#result+1] = string.char(((v2 % 16) * 16) + math.floor(v3 / 4))
                end
                if c4 ~= "" and c4 ~= "=" then
                    result[#result+1] = string.char(((v3 % 4) * 64) + v4)
                end
                i = i + 4
            end
            return table.concat(result)
        end

        local function notifyImport(msg)
            if _G._MenuLib and _G._MenuLib.Notify then
                pcall(_G._MenuLib.Notify, msg)
            end
        end
        table.insert(conns, importBtn.MouseButton1Click:Connect(function()
            local clipText = nil
            if getclipboard then clipText = getclipboard()
            elseif cb then clipText = cb()
            end
            if not clipText or clipText == "" then notifyImport("Clipboard is empty") return end
            local ok, jsonStr = pcall(function() return b64decode(clipText) end)
            if not ok or not jsonStr then notifyImport("Invalid base64 data") return end
            local ok2, configData = pcall(function() return HttpService:JSONDecode(jsonStr) end)
            if not ok2 or type(configData) ~= "table" then notifyImport("Invalid config format") return end
            if not _G._ConfigList then _G._ConfigList = {} end
            local name = "Imported_" .. os.date("%H%M%S")
            local baseName = name
            local counter = 1
            while _G._ConfigList[name] do
                name = baseName .. "_" .. counter
                counter = counter + 1
            end
            _G._ConfigList[name] = configData
            SaveConfigsToFile()
            RefreshConfigList()
        end))

        table.insert(conns, exportBtn.MouseButton1Click:Connect(function()
            if not selectedConfig or not _G._ConfigList[selectedConfig] then return end
            local ok, jsonStr = pcall(function() return HttpService:JSONEncode(_G._ConfigList[selectedConfig]) end)
            if not ok or not jsonStr then return end
            local encoded = b64encode(jsonStr)
            if setclipboard then
                pcall(function() setclipboard(encoded) end)
            elseif toclipboard then
                pcall(function() toclipboard(encoded) end)
            end
        end))

        _G._MenuToggles = _G._MenuToggles or {}
        _G._MenuSliders = _G._MenuSliders or {}
        _G._MenuDropdowns = _G._MenuDropdowns or {}
        _G._MenuColorPickers = _G._MenuColorPickers or {}
        _G._MenuTextBoxes = _G._MenuTextBoxes or {}
        _G._MenuKeybinds = _G._MenuKeybinds or {}
        _G._ConfigExtensions = _G._ConfigExtensions or {}

        local function keyToTable(k)
            if typeof(k) == "EnumItem" then
                return { t = tostring(k.EnumType), n = k.Name }
            end
            return nil
        end

        local function tableToKey(v)
            if type(v) == "table" and v.n then
                if v.t == "Enum.UserInputType" then return Enum.UserInputType[v.n] end
                return Enum.KeyCode[v.n]
            end
            if type(v) == "string" then
                local name = v:gsub("^Enum%.KeyCode%.", ""):gsub("^Enum%.UserInputType%.", "")
                return Enum.KeyCode[name] or Enum.UserInputType[name]
            end
            return nil
        end

        if not _G.GetConfigData then
            _G.GetConfigData = function()
                local data = {
                    Version = 2,
                    Toggles = {},
                    Sliders = {},
                    Dropdowns = {},
                    ColorPickers = {},
                    TextBoxes = {},
                    Keybinds = {},
                    Extras = {},
                }
                for label, tog in pairs(_G._MenuToggles or {}) do
                    if not tog.NoSave then
                        local ok, v = pcall(tog.Get)
                        if ok then data.Toggles[label] = v end
                    end
                end
                for label, sl in pairs(_G._MenuSliders or {}) do
                    if not sl.NoSave then
                        local ok, v = pcall(sl.Get)
                        if ok then data.Sliders[label] = v end
                    end
                end
                for label, dd in pairs(_G._MenuDropdowns or {}) do
                    if not dd.NoSave then
                        local ok, opt, idx = pcall(dd.Get)
                        if ok then data.Dropdowns[label] = { i = idx, v = (type(opt) == "string") and opt or nil } end
                    end
                end
                for label, cp in pairs(_G._MenuColorPickers or {}) do
                    if not cp.NoSave then
                        local ok, c, a = pcall(cp.Get)
                        if ok and typeof(c) == "Color3" then
                            data.ColorPickers[label] = { r = c.R, g = c.G, b = c.B, a = a or 1 }
                        end
                    end
                end
                for label, tb in pairs(_G._MenuTextBoxes or {}) do
                    if not tb.NoSave then
                        local v = tb.Value
                        if v == nil and tb.Element then v = tb.Element.Text end
                        if v ~= nil then data.TextBoxes[label] = tostring(v) end
                    end
                end
                for label, kb in pairs(_G._MenuKeybinds or {}) do
                    if not kb.NoSave then
                        local ok, v = pcall(kb.Get)
                        if ok and v then data.Keybinds[label] = v end
                    end
                end
                for name, ext in pairs(_G._ConfigExtensions or {}) do
                    if type(ext) == "table" and type(ext.Get) == "function" then
                        local ok, v = pcall(ext.Get)
                        if ok and v ~= nil then data.Extras[name] = v end
                    end
                end

                local friends = {}
                for _, name in ipairs(_G._FriendsList or {}) do
                    friends[#friends + 1] = tostring(name)
                end

                data._MenuSettings = {
                    MenuToggleKey = keyToTable(M.MenuToggleKey),
                    UnloadKey = keyToTable(M.UnloadKey),
                    SmoothAnimations = M.SmoothAnimations,
                    AutoRefresh = M.AutoRefresh,
                    BlurEnabled = M.BlurEnabled,
                    LightingDimEnabled = M.LightingDimEnabled,
                    ESPColour = (typeof(M.ESPColour) == "Color3")
                        and { r = M.ESPColour.R, g = M.ESPColour.G, b = M.ESPColour.B } or nil,
                    WindowWidth = WIN_W,
                    WindowHeight = WIN_H,
                    SidebarWidth = SIDE_W,
                    Friends = friends,
                }
                return data
            end
        end

        if not _G.LoadConfigData then
            _G.LoadConfigData = function(data)
                if type(data) ~= "table" then return end
                _G._ConfigLoading = true

                for label, val in pairs(data.Toggles or {}) do
                    local w = (_G._MenuToggles or {})[label]
                    if w then pcall(w.Set, val and true or false) end
                end
                for label, val in pairs(data.Sliders or {}) do
                    local w = (_G._MenuSliders or {})[label]
                    if w and tonumber(val) then pcall(w.Set, tonumber(val)) end
                end
                for label, val in pairs(data.Dropdowns or {}) do
                    local w = (_G._MenuDropdowns or {})[label]
                    if w then
                        local idx, text
                        if type(val) == "table" then idx, text = tonumber(val.i), val.v else idx = tonumber(val) end
                        if text and w.GetOptions then
                            local ok, opts = pcall(w.GetOptions)
                            if ok and type(opts) == "table" then
                                for i, opt in ipairs(opts) do
                                    if opt == text then idx = i break end
                                end
                            end
                        end
                        if idx then
                            pcall(w.Set, idx)
                            if text and w.SetText then pcall(w.SetText, text) end
                        end
                    end
                end
                for label, val in pairs(data.ColorPickers or {}) do
                    local w = (_G._MenuColorPickers or {})[label]
                    if w and type(val) == "table" and val.r then
                        pcall(w.Set, Color3.new(val.r, val.g, val.b), val.a)
                    end
                end
                for label, val in pairs(data.TextBoxes or {}) do
                    local w = (_G._MenuTextBoxes or {})[label]
                    if w then
                        if type(w.Set) == "function" then
                            pcall(w.Set, tostring(val))
                        elseif w.Element then
                            pcall(function()
                                w.Element.Text = tostring(val)
                                w.Value = tostring(val)
                            end)
                        end
                    end
                end
                for label, val in pairs(data.Keybinds or {}) do
                    local w = (_G._MenuKeybinds or {})[label]
                    if w then pcall(w.Set, val) end
                end

                local s = data._MenuSettings
                if type(s) == "table" then
                    if s.SmoothAnimations ~= nil then M.SmoothAnimations = s.SmoothAnimations end
                    if s.AutoRefresh ~= nil then M.AutoRefresh = s.AutoRefresh end
                    if s.BlurEnabled ~= nil then M.BlurEnabled = s.BlurEnabled end
                    if s.LightingDimEnabled ~= nil then M.LightingDimEnabled = s.LightingDimEnabled end
                    if s.ESPColour and s.ESPColour.r then
                        M.ESPColour = Color3.new(s.ESPColour.r, s.ESPColour.g, s.ESPColour.b)
                    end
                    local mk = tableToKey(s.MenuToggleKey)
                    if mk then M.MenuToggleKey = mk end
                    local uk = tableToKey(s.UnloadKey)
                    if uk then M.UnloadKey = uk end
                    if tonumber(s.WindowWidth) and tonumber(s.WindowHeight) then
                        WIN_W = math.max(600, tonumber(s.WindowWidth))
                        WIN_H = math.max(380, tonumber(s.WindowHeight))
                        pcall(function()
                            if win then win.Size = UDim2.new(0, WIN_W, 0, WIN_H) end
                            if settingsPanel then settingsPanel.Size = UDim2.new(0, WIN_W, 0, WIN_H) end
                        end)
                    end
                    if tonumber(s.SidebarWidth) then
                        pcall(setSidebarWidth, tonumber(s.SidebarWidth), false)
                    end
                    if type(s.Friends) == "table" then
                        _G._FriendsList = _G._FriendsList or {}
                        table.clear(_G._FriendsList)
                        for _, name in ipairs(s.Friends) do
                            _G._FriendsList[#_G._FriendsList + 1] = tostring(name)
                        end
                        if _G._SaveFriendsList then pcall(_G._SaveFriendsList) end
                        if _G._RefreshFriendsList then pcall(_G._RefreshFriendsList) end
                    end
                end

                for name, val in pairs(data.Extras or {}) do
                    local ext = (_G._ConfigExtensions or {})[name]
                    if type(ext) == "table" and type(ext.Set) == "function" then
                        pcall(ext.Set, val)
                    end
                end

                _G._ConfigLoading = false
                _G._ConfigLoaded = tick()
            end
        end

        RefreshConfigList()

        local autoLoadName = GetAutoLoadConfig()
        if autoLoadName and _G._ConfigList[autoLoadName] and _G.LoadConfigData then
            task.spawn(function()
                local function widgetCount()
                    local n = 0
                    for _, reg in ipairs({ _G._MenuToggles, _G._MenuSliders, _G._MenuDropdowns,
                        _G._MenuColorPickers, _G._MenuTextBoxes, _G._MenuKeybinds }) do
                        for _ in pairs(reg or {}) do n = n + 1 end
                    end
                    return n
                end
                local last = -1
                local stable = 0
                local deadline = tick() + 15
                while tick() < deadline do
                    task.wait(0.25)
                    local n = widgetCount()
                    if n == last and n > 0 then
                        stable = stable + 1
                        if stable >= 4 then break end
                    else
                        stable = 0
                        last = n
                    end
                end
                pcall(function()
                    _G.LoadConfigData(_G._ConfigList[autoLoadName])
                    _G._CurrentConfig = autoLoadName
                end)
            end)
        end
    end)

    if firstTab and firstTab.Select then
        local success, err = pcall(function()
            firstTab:Select()
        end)
        if not success then
            warn("Menu init error: " .. tostring(err))
        end
    end

    local resizer = Instance.new("TextButton")
    resizer.Size = UDim2.new(0, 24, 0, 24)
    resizer.Position = UDim2.new(1, -24, 1, -24)
    resizer.BackgroundTransparency = 1
    resizer.Text = ""
    resizer.ZIndex = Z.RESIZER
    resizer.Active = true
    resizer.AutoButtonColor = false
    resizer.Parent = win

    local settingsResizer = Instance.new("TextButton")
    settingsResizer.Size = UDim2.new(0, 24, 0, 24)
    settingsResizer.Position = UDim2.new(1, -24, 1, -24)
    settingsResizer.BackgroundTransparency = 1
    settingsResizer.Text = ""
    settingsResizer.ZIndex = Z.RESIZER
    settingsResizer.Active = true
    settingsResizer.AutoButtonColor = false
    settingsResizer.Parent = settingsPanel

    local isResizing = false
    local resizeTarget = nil
    local resizeStartMouse = nil
    local resizeStartW = 0
    local resizeStartH = 0
    local resizeStartPos = UDim2.new()

    local function beginResize(target)
        return function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isResizing = true
                resizeTarget = target
                resizeStartMouse = UserInputService:GetMouseLocation()
                resizeStartW = WIN_W
                resizeStartH = WIN_H
                if target == "main" and win then
                    resizeStartPos = win.Position
                elseif target == "settings" and settingsPanel then
                    resizeStartPos = settingsPanel.Position
                end
            end
        end
    end
    table.insert(conns, resizer.InputBegan:Connect(beginResize("main")))
    table.insert(conns, settingsResizer.InputBegan:Connect(beginResize("settings")))

    table.insert(conns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isResizing = false
            resizeTarget = nil
        end
    end))

    table.insert(conns, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and isResizing then
            local currMouse = UserInputService:GetMouseLocation()
            local delta = currMouse - resizeStartMouse
            local newW = math.max(600, resizeStartW + delta.X)
            local newH = math.max(380, resizeStartH + delta.Y)
            WIN_W = newW
            WIN_H = newH
            if resizeTarget == "main" and win then
                win.Size = UDim2.new(0, newW, 0, newH)
            elseif resizeTarget == "settings" and settingsPanel then
                settingsPanel.Size = UDim2.new(0, newW, 0, newH)
            end
            setSidebarWidth(SIDE_W, false)
        end
    end))

    return API
end

return MenuLib
