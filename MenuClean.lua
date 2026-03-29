local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")
local _guid = tostring(tick() * 100000 % 1e12)
pcall(function()
	_guid = HttpService:GenerateGUID(false)
end)
local RS_BIND_INP = "MenuGuiInp_" .. _guid
local RS_BIND_CAM = "MenuGuiCam_" .. _guid

-- Global Settings
_G._MenuAutoRefresh = true
_G._BlurEnabled = false
_G._LightingDimEnabled = false
_G._OriginalBrightness = nil
_G._OriginalClockTime = nil
_G._OriginalQualityLevel = nil
_G._MenuToggleKey = Enum.KeyCode.Insert
_G._UnloadKey = Enum.KeyCode.Delete
_G._SmoothAnimations = true

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
}

local function normalizeIconId(id)
	if type(id) ~= "string" and type(id) ~= "number" then return nil end
	local s = tostring(id):gsub("^%s+", ""):gsub("%s+$", "")
	if s == "" then return nil end
	if s:match("^rbxassetid://") or s:match("^rbxasset://") or s:match("^http://") or s:match("^https://") then
		return s
	end
	if s:match("^%d+$") then return "rbxassetid://" .. s end
	return s
end

local controls = nil
local savedCamType = Enum.CameraType.Custom
local frozenCF = CFrame.new()
local isOpen = false
local prevMouseBehavior = Enum.MouseBehavior.Default
local prevMouseIconEnabled = true

pcall(function()
	local PM = require(lp:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	controls = PM:GetControls()
end)

local function lockInput()
	prevMouseBehavior = UserInputService.MouseBehavior
	prevMouseIconEnabled = UserInputService.MouseIconEnabled
	isOpen = true
	pcall(function() controls:Disable() end)
	local cam = workspace.CurrentCamera
	if cam then savedCamType = cam.CameraType end
	pcall(function()
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = frozenCF
	end)
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

local function unlockInput()
	isOpen = false
	pcall(function() controls:Enable() end)
	local cam = workspace.CurrentCamera
	if cam then cam.CameraType = savedCamType end
	UserInputService.MouseBehavior = prevMouseBehavior
	UserInputService.MouseIconEnabled = prevMouseIconEnabled
end

RunService:BindToRenderStep(RS_BIND_INP, Enum.RenderPriority.Input.Value + 1, function()
	if not isOpen then return end
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	UserInputService.MouseIconEnabled = true
end)

RunService:BindToRenderStep(RS_BIND_CAM, Enum.RenderPriority.Camera.Value - 1, function()
	if not isOpen then return end
	local cam = workspace.CurrentCamera
	if cam and cam.CameraType == Enum.CameraType.Scriptable then
		cam.CFrame = frozenCF
	end
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

local WIN_W = 680
local WIN_H = 420
local SIDE_W = 160
local HUD_W = 520

local function refreshLayout()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	WIN_W = math.floor(math.clamp(vs.X * 0.38, 580, 820))
	WIN_H = math.floor(math.clamp(vs.Y * 0.48, 380, 560))
	SIDE_W = math.floor(math.clamp(WIN_W * 0.23, 140, 200))
end

refreshLayout()
local mainSideBase = SIDE_W

local function fr(parent, size, pos, col, trans, rad)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos or UDim2.new(0, 0, 0, 0)
	f.BackgroundColor3 = col or C.BG
	f.BackgroundTransparency = trans or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	if rad ~= nil and rad ~= false then
		local ty = typeof(rad)
		if ty == "number" and rad <= 0 then return f end
		local c = Instance.new("UICorner")
		if ty == "UDim2" then
			local o = rad.X.Offset
			if o == 0 then o = rad.Y.Offset end
			c.CornerRadius = UDim.new(0, math.max(0, math.floor(o)))
		elseif ty == "UDim" then c.CornerRadius = rad
		elseif ty == "number" then c.CornerRadius = UDim.new(0, rad)
		else c:Destroy() return f end
		c.Parent = f
	end
	return f
end

local function lbl(parent, txt, size, pos, ts, col, font, xa)
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos or UDim2.new(0, 0, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = col or C.TEXT
	l.TextSize = ts or 11
	l.Font = font or Enum.Font.Gotham
	l.TextXAlignment = xa or Enum.TextXAlignment.Left
	l.BorderSizePixel = 0
	l.RichText = false
	l.TextWrapped = true
	l.Parent = parent
	return l
end

local function gradH(parent, c1, c2)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2) })
	g.Rotation = 0
	g.Parent = parent
	return g
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
	TweenService:Create(obj, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local blurPart = nil

local function mkSmallBtn(parent, txt, size, pos, fn)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos or UDim2.new(0, 0, 0, 0)
	b.BackgroundColor3 = C.BTN
	b.BorderSizePixel = 0
	b.Text = txt
	b.TextColor3 = C.TEXT
	b.TextSize = 11
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = false
	b.Parent = parent
	local uc = Instance.new("UICorner")
	uc.CornerRadius = UDim.new(0, 8)
	uc.Parent = b
	b.MouseEnter:Connect(function() tw(b, { BackgroundColor3 = C.BTNHOV }, 0.12) end)
	b.MouseLeave:Connect(function() tw(b, { BackgroundColor3 = C.BTN }, 0.12) end)
	if fn then b.MouseButton1Click:Connect(fn) end
	return b
end

local function mkToggle(parent, posX, initState, onToggle)
	local track = fr(parent, UDim2.new(0, 44, 0, 24), UDim2.new(1, posX, 0.5, -12), Color3.fromRGB(18, 8, 36), 0, 12)
	track.ZIndex = 2
	local fill = fr(track, UDim2.new(1, 0, 1, 0), nil, C.ACCENT, 1, 12)
	gradH(fill, C.ACCENT, C.ACCENT2)
	local knob = fr(track, UDim2.new(0, 18, 0, 18), UDim2.new(0, 3, 0.5, -9), C.TEXT, 0, 9)
	knob.ZIndex = 4
	local togBtn = Instance.new("TextButton")
	togBtn.Size = UDim2.new(1, 0, 1, 0)
	togBtn.BackgroundTransparency = 1
	togBtn.Text = ""
	togBtn.ZIndex = 15
	togBtn.Parent = track
	local state = initState
	local function apply(anim, silent)
		tw(fill, { BackgroundTransparency = state and 0 or 1 }, anim and 0.12 or 0)
		local dest = state and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
		if anim then tw(knob, { Position = dest }, 0.14) else knob.Position = dest end
		if onToggle and not silent then task.defer(function() onToggle(state) end) end
	end
	apply(false, true)
	togBtn.MouseButton1Click:Connect(function()
		state = not state
		apply(true, false)
	end)
	return function(v)
		if v ~= nil and v ~= state then state = v apply(true, false)
		elseif v == nil then return state end
		return state
	end
end

-- ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "MenuGui_v4"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true
sg.DisplayOrder = 2147483647
sg.Parent = pg

-- HUD Bar
local hudBar = fr(sg, UDim2.new(0, HUD_W, 0, 44), UDim2.new(0.5, -HUD_W / 2, 0, 10), C.DARK, 0, 18)
hudBar.ClipsDescendants = true
hudBar.ZIndex = 5

-- Avatar
local av = fr(hudBar, UDim2.new(0, 32, 0, 32), UDim2.new(0, 10, 0.5, -16), Color3.fromRGB(36, 14, 68), 0, 16)
local avImg = Instance.new("ImageLabel")
avImg.Size = UDim2.new(1, -4, 1, -4)
avImg.Position = UDim2.new(0, 2, 0, 2)
avImg.BackgroundTransparency = 1
avImg.ScaleType = Enum.ScaleType.Fit
avImg.Parent = av
local auc = Instance.new("UICorner")
auc.CornerRadius = UDim.new(0, 14)
auc.Parent = avImg
task.spawn(function()
	local ok, url = pcall(function()
		return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
	end)
	if ok and url then avImg.Image = url end
end)

-- HUD Labels
lbl(hudBar, "Welcome back,", UDim2.new(0, 140, 0, 14), UDim2.new(0, 48, 0, 6), 9, C.DIM)
local nameLbl = lbl(hudBar, lp.Name, UDim2.new(0, 0, 0, 16), UDim2.new(0, 48, 0, 20), 12, C.TEXT, Enum.Font.GothamBold)
nameLbl.AutomaticSize = Enum.AutomaticSize.X

-- FPS/Ping/Time Labels
local div1Frame = fr(hudBar, UDim2.new(0, 1, 0.55, 0), UDim2.new(0, 240, 0.22, 0), C.DIV)
local div2Frame = fr(hudBar, UDim2.new(0, 1, 0.55, 0), UDim2.new(0, 330, 0.22, 0), C.DIV)
local fpsLbl = lbl(hudBar, "...", UDim2.new(0, 80, 0, 20), UDim2.new(0, 248, 0, 14), 14, C.ACCENT, Enum.Font.GothamBold)
local pingLbl = lbl(hudBar, "...", UDim2.new(0, 80, 0, 20), UDim2.new(0, 340, 0, 14), 14, C.GREEN, Enum.Font.GothamBold)
local timeLbl = lbl(hudBar, "00:00 AM", UDim2.new(0, 90, 0, 16), UDim2.new(0, 556, 0, 12), 14, C.TEXT, Enum.Font.GothamBold)

-- Home/Settings Button
local homeBtn = Instance.new("ImageButton")
homeBtn.Size = UDim2.new(0, 30, 0, 30)
homeBtn.Position = UDim2.new(0, 420, 0.45, -15)
homeBtn.BackgroundColor3 = Color3.fromRGB(24, 10, 48)
homeBtn.BackgroundTransparency = 0.2
homeBtn.Image = ICON.settings
homeBtn.ScaleType = Enum.ScaleType.Fit
homeBtn.ImageColor3 = C.TEXT
homeBtn.AutoButtonColor = false
homeBtn.Parent = hudBar
local homeBtnCorner = Instance.new("UICorner")
homeBtnCorner.CornerRadius = UDim.new(0, 12)
homeBtnCorner.Parent = homeBtn

local homeBtnIcon2 = Instance.new("ImageLabel")
homeBtnIcon2.Size = UDim2.new(1, 0, 1, 0)
homeBtnIcon2.BackgroundTransparency = 1
homeBtnIcon2.Image = ICON.home
homeBtnIcon2.ScaleType = Enum.ScaleType.Fit
homeBtnIcon2.ImageColor3 = C.TEXT
homeBtnIcon2.ImageTransparency = 1
homeBtnIcon2.Parent = homeBtn

-- Fire Button
local badge = fr(hudBar, UDim2.new(0, 32, 0, 28), UDim2.new(0, 670, 0.5, -14), C.ACCENT, 0, 8)
gradH(badge, C.ACCENT, C.ACCENT2)
local fireI = Instance.new("ImageLabel")
fireI.Size = UDim2.new(0, 18, 0, 18)
fireI.Position = UDim2.new(0.5, -9, 0.5, -9)
fireI.BackgroundTransparency = 1
fireI.Image = ICON.fire
fireI.ScaleType = Enum.ScaleType.Fit
fireI.ImageColor3 = Color3.fromRGB(255, 255, 255)
fireI.Parent = badge
gradH(fireI, C.ACCENT, C.ACCENT2)
local fireClick = Instance.new("TextButton")
fireClick.Size = UDim2.new(1, 0, 1, 0)
fireClick.BackgroundTransparency = 1
fireClick.Text = ""
fireClick.ZIndex = 10
fireClick.Parent = badge

-- Main Window
local win = fr(sg, UDim2.new(0, WIN_W, 0, WIN_H), UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2), C.BG, 0, 20)
win.ClipsDescendants = true
win.ZIndex = 1
win.Visible = false

local mainLayer = fr(win, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), C.BG, 1, 0)
mainLayer.ZIndex = 2

-- Drag Handle
local dragHandle = Instance.new("TextButton")
dragHandle.Name = "MenuDrag"
dragHandle.Size = UDim2.new(1, 0, 0, 28)
dragHandle.Position = UDim2.new(0, 0, 0, 2)
dragHandle.BackgroundTransparency = 1
dragHandle.Text = ""
dragHandle.ZIndex = 30
dragHandle.Parent = mainLayer

-- Body
local bodyShell = fr(mainLayer, UDim2.new(1, 0, 1, -32), UDim2.new(0, 0, 0, 32), C.BG, 1, 0)
bodyShell.ZIndex = 2

-- Sidebar
local sidebar = fr(bodyShell, UDim2.new(0, SIDE_W, 1, -4), UDim2.new(0, 0, 0, 4), C.SIDEBAR, 0, 14)
sidebar.ZIndex = 2

local sideDiv = fr(bodyShell, UDim2.new(0, 1, 1, -4), UDim2.new(0, SIDE_W, 0, 4), C.DIV)

-- Content Area
local contentArea = fr(bodyShell, UDim2.new(1, -SIDE_W - 2, 1, -32), UDim2.new(0, SIDE_W + 2, 0, 4), C.CONTENT, 0, 16)
contentArea.ClipsDescendants = true
contentArea.ZIndex = 2

-- Status Bar
local statusBar = fr(bodyShell, UDim2.new(1, -SIDE_W - 2, 0, 28), UDim2.new(0, SIDE_W + 2, 1, -32), C.DARK, 0, 12)
mkSmallBtn(statusBar, "Refresh", UDim2.new(0, 72, 0, 20), UDim2.new(1, -82, 0.5, -10), function()
	refreshLayout()
	mainSideBase = SIDE_W
end)

-- Sidebar Nav
local navHolder = fr(sidebar, UDim2.new(1, 0, 1, 0), nil, C.SIDEBAR, 1, 0)
local navScroll = Instance.new("ScrollingFrame")
navScroll.Size = UDim2.new(1, 0, 1, 0)
navScroll.ZIndex = 2
navScroll.BackgroundTransparency = 1
navScroll.BorderSizePixel = 0
navScroll.ScrollBarThickness = 0
navScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
navScroll.ClipsDescendants = true
navScroll.ScrollingDirection = Enum.ScrollingDirection.Y
navScroll.Parent = navHolder
pad(navScroll, 8, 10, 12, 10)

local navList = Instance.new("UIListLayout")
navList.SortOrder = Enum.SortOrder.LayoutOrder
navList.Padding = UDim.new(0, 6)
navList.Parent = navScroll

-- Tab System
local activeTab = nil
local allTabs = {}
local layoutOrd = 0
local function nextOrd()
	layoutOrd = layoutOrd + 1
	return layoutOrd
end

local function addSection(name)
	local s = lbl(navScroll, name, UDim2.new(1, -4, 0, 26), nil, 12, C.SEC, Enum.Font.GothamBold)
	s.ZIndex = 3
	s.LayoutOrder = nextOrd()
	s.TextXAlignment = Enum.TextXAlignment.Left
	pad(s, 6, 0, 6, 0)
end

local function addTab(name, iconImage, buildFn)
	local tf = fr(contentArea, UDim2.new(1, 0, 1, 0), nil, C.CONTENT, 1, 0)
	tf.Visible = false
	tf.ZIndex = 5
	if buildFn then buildFn(tf) end

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -8, 0, 38)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.LayoutOrder = nextOrd()
	btn.AutoButtonColor = false
	btn.ZIndex = 2
	btn.Parent = navScroll
	local uc = Instance.new("UICorner")
	uc.CornerRadius = UDim.new(0, 12)
	uc.Parent = btn

	local selBg = fr(btn, UDim2.new(1, 0, 1, 0), nil, C.SEL, 1, 12)
	selBg.ZIndex = 1
	local selLine = fr(btn, UDim2.new(0, 4, 0.5, 0), UDim2.new(1, -5, 0.25, 0), C.ACCENT, 1, 4)
	gradV(selLine, C.ACCENT, C.ACCENT2)
	selLine.ZIndex = 2

	local iconSize = 24
	local iconX = 6
	if iconImage == ICON.aim or iconImage == ICON.players then
		iconSize = 28
		iconX = 2
	elseif iconImage == ICON.world then
		iconSize = 20
	end

	local icoL = Instance.new("ImageLabel")
	icoL.Size = UDim2.new(0, iconSize, 0, iconSize)
	icoL.Position = UDim2.new(0, iconX, 0.5, -iconSize / 2)
	icoL.BackgroundTransparency = 1
	icoL.Image = normalizeIconId(iconImage) or ""
	icoL.ScaleType = Enum.ScaleType.Fit
	icoL.ImageColor3 = C.DIM
	icoL.ZIndex = 4
	icoL.Parent = btn

	local namL = lbl(btn, name, UDim2.new(1, -52, 1, 0), UDim2.new(0, 44, 0, 0), 12, C.DIM)
	namL.ZIndex = 4

	local entry = { btn = btn, frame = tf, bg = selBg, line = selLine, ico = icoL, lbl = namL, iconSize = iconSize, iconX = iconX }
	table.insert(allTabs, entry)

	local function deselect()
		tw(tf, { Position = UDim2.new(0, -30, 0, 0), BackgroundTransparency = 1 }, 0.35, Enum.EasingStyle.Quart)
		tw(selBg, { BackgroundTransparency = 1 }, 0.25)
		tw(selLine, { BackgroundTransparency = 1, Size = UDim2.new(0, 4, 0, 0) }, 0.2, Enum.EasingStyle.Quart)
		tw(namL, { TextColor3 = C.DIM }, 0.2)
		tw(icoL, { ImageColor3 = C.DIM, Position = UDim2.new(0, iconX, 0.5, -iconSize / 2) }, 0.25, Enum.EasingStyle.Quart)
		task.delay(0.35, function() tf.Visible = false end)
	end

	local function select()
		tf.Visible = true
		tf.Position = UDim2.new(0, 30, 0, 0)
		tf.BackgroundTransparency = 1
		tw(tf, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.4, Enum.EasingStyle.Quint)
		tw(selBg, { BackgroundTransparency = 0 }, 0.3)
		tw(selLine, { BackgroundTransparency = 0, Size = UDim2.new(0, 4, 0.5, 0) }, 0.35, Enum.EasingStyle.Quint)
		tw(namL, { TextColor3 = C.TEXT }, 0.25)
		tw(icoL, { ImageColor3 = C.TEXT, Position = UDim2.new(0, iconX + 4, 0.5, -iconSize / 2) }, 0.3, Enum.EasingStyle.Quint)
	end

	btn.MouseEnter:Connect(function()
		if activeTab ~= entry then tw(selBg, { BackgroundTransparency = 0.5 }) end
	end)
	btn.MouseLeave:Connect(function()
		if activeTab ~= entry then tw(selBg, { BackgroundTransparency = 1 }) end
	end)
	btn.MouseButton1Click:Connect(function()
		if activeTab and activeTab ~= entry then
			activeTab._des()
			activeTab.frame.Visible = false
		end
		activeTab = entry
		entry.frame.Visible = true
		select()
	end)

	entry._des = deselect
	entry._sel = select
	return entry
end

local function buildEmptyTab(title)
	return function(f)
		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1, 0, 1, 0)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 0
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollingDirection = Enum.ScrollingDirection.Y
		scroll.ClipsDescendants = true
		scroll.ZIndex = 6
		scroll.Parent = f
		pad(scroll, 8, 10, 8, 8)

		local card = fr(scroll, UDim2.new(1, -4, 0, 0), UDim2.new(0, 0, 0, 0), C.HEADER, 0, 16)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.ZIndex = 2
		local v = Instance.new("UIListLayout")
		v.SortOrder = Enum.SortOrder.LayoutOrder
		v.Padding = UDim.new(0, 8)
		v.Parent = card
		pad(card, 16, 16, 16, 16)
		local titleL = lbl(card, title, UDim2.new(1, 0, 0, 0), nil, 18, C.TEXT, Enum.Font.GothamBold)
		titleL.LayoutOrder = 1
		titleL.ZIndex = 3
		titleL.AutomaticSize = Enum.AutomaticSize.Y
		local sub = lbl(card, "Options for this tab live in the gear panel.", UDim2.new(1, 0, 0, 0), nil, 12, C.DIM)
		sub.TextYAlignment = Enum.TextYAlignment.Top
		sub.TextWrapped = true
		sub.LayoutOrder = 2
		sub.ZIndex = 3
		sub.AutomaticSize = Enum.AutomaticSize.Y
	end
end

-- Create Tabs
addSection("COMBAT")
local firstTab = addTab("Aimbot", ICON.aim, buildEmptyTab("Aimbot"))

addSection("VISUALS")
addTab("Players", ICON.players, buildEmptyTab("Players"))
addTab("World", ICON.world, buildEmptyTab("World"))

addSection("MISC")
addTab("Misc", ICON.misc, buildEmptyTab("Misc"))
addTab("Exploits", ICON.exploits, buildEmptyTab("Exploits"))
addTab("Configuration", ICON.config, buildEmptyTab("Configuration"))

-- Settings Panel
local settingsPanel = fr(win, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), C.BG, 0, 20)
settingsPanel.ZIndex = 10
settingsPanel.Visible = false

local settingsDrag = Instance.new("TextButton")
settingsDrag.Name = "SettingsDrag"
settingsDrag.Size = UDim2.new(1, 0, 0, 32)
settingsDrag.Position = UDim2.new(0, 0, 0, 0)
settingsDrag.BackgroundTransparency = 1
settingsDrag.Text = ""
settingsDrag.ZIndex = 50
settingsDrag.Parent = settingsPanel

do
	local sLeft = fr(settingsPanel, UDim2.new(0, SIDE_W, 1, -4), UDim2.new(0, 0, 0, 32), C.SIDEBAR, 0, 14)
	fr(settingsPanel, UDim2.new(0, 1, 1, -4), UDim2.new(0, SIDE_W, 0, 32), C.DIV)

	local catItems = { "General", "Appearance", "Performance", "Keybinds" }
	local catKeys = { ICON.general, ICON.appearance, ICON.performance, ICON.keyboard }
	local catScroll = Instance.new("ScrollingFrame")
	catScroll.Size = UDim2.new(1, 0, 1, 0)
	catScroll.ZIndex = 2
	catScroll.BackgroundTransparency = 1
	catScroll.BorderSizePixel = 0
	catScroll.ScrollBarThickness = 0
	catScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	catScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	catScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	local cth = fr(sLeft, UDim2.new(1, 0, 1, 0), nil, C.SIDEBAR, 1, 0)
	catScroll.Parent = cth
	pad(catScroll, 8, 10, 12, 8)

	local catList = Instance.new("UIListLayout")
	catList.SortOrder = Enum.SortOrder.LayoutOrder
	catList.Padding = UDim.new(0, 4)
	catList.Parent = catScroll

	local catBtns = {}
	local tabContents = {}
	local activeSettingTab = 1

	for i, cat in ipairs(catItems) do
		local cb = Instance.new("TextButton")
		cb.Size = UDim2.new(1, -4, 0, 38)
		cb.LayoutOrder = i
		cb.BackgroundColor3 = C.SEL
		cb.BackgroundTransparency = i == 1 and 0 or 1
		cb.Text = ""
		cb.AutoButtonColor = false
		cb.Parent = catScroll
		local cuc = Instance.new("UICorner")
		cuc.CornerRadius = UDim.new(0, 10)
		cuc.Parent = cb

		local selLine = fr(cb, UDim2.new(0, 4, 0, 0), UDim2.new(0, 0, 0.5, 0), C.ACCENT, i == 1 and 0 or 1, 0)
		selLine.Position = UDim2.new(0, 0, 0.5, 0)
		local selBg = fr(cb, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), C.SEL, i == 1 and 0 or 1, 0)

		local ci = Instance.new("ImageLabel")
		ci.Size = UDim2.new(0, 24, 0, 24)
		ci.Position = UDim2.new(0, i == 1 and 14 or 10, 0.5, -12)
		ci.BackgroundTransparency = 1
		ci.Image = normalizeIconId(catKeys[i]) or ""
		ci.ImageColor3 = i == 1 and C.TEXT or C.DIM
		ci.ScaleType = Enum.ScaleType.Fit
		ci.Parent = cb

		local namL = lbl(cb, cat, UDim2.new(1, -44, 1, 0), UDim2.new(0, 40, 0, 0), 12, i == 1 and C.TEXT or C.DIM)
		catBtns[i] = { btn = cb, icon = ci, lbl = namL, bg = selBg, line = selLine }

		cb.MouseButton1Click:Connect(function()
			if activeSettingTab ~= i then
				-- Deselect old
				local old = catBtns[activeSettingTab]
				if old then
					old.bg.BackgroundTransparency = 1
					old.line.BackgroundTransparency = 1
					old.line.Size = UDim2.new(0, 4, 0, 0)
					old.lbl.TextColor3 = C.DIM
					old.icon.ImageColor3 = C.DIM
					old.icon.Position = UDim2.new(0, 10, 0.5, -12)
				end
				-- Select new
				local new = catBtns[i]
				new.bg.BackgroundTransparency = 0
				new.line.BackgroundTransparency = 0
				new.line.Size = UDim2.new(0, 4, 0.5, 0)
				new.lbl.TextColor3 = C.TEXT
				new.icon.ImageColor3 = C.TEXT
				new.icon.Position = UDim2.new(0, 14, 0.5, -12)
				-- Switch content
				for j, content in ipairs(tabContents) do
					content.Visible = (j == i)
				end
				activeSettingTab = i
			end
		end)
	end

	local sRight = fr(settingsPanel, UDim2.new(1, -SIDE_W - 2, 1, -4), UDim2.new(0, SIDE_W + 2, 0, 32), C.CONTENT, 0, 14)
	local titleRow = fr(sRight, UDim2.new(1, 0, 0, 40), nil, C.HEADER, 0, 0)
	lbl(titleRow, "Settings", UDim2.new(1, -16, 1, 0), UDim2.new(0, 14, 0, 0), 16, C.TEXT, Enum.Font.GothamBold)

	local sHolder = fr(sRight, UDim2.new(1, 0, 1, -46), UDim2.new(0, 0, 0, 40), C.CONTENT, 1, 0)

	for i = 1, 4 do
		local sScroll = Instance.new("ScrollingFrame")
		sScroll.Name = "SettingsTab" .. i
		sScroll.Size = UDim2.new(1, 0, 1, 0)
		sScroll.ZIndex = 2
		sScroll.BackgroundTransparency = 1
		sScroll.BorderSizePixel = 0
		sScroll.ScrollBarThickness = 0
		sScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		sScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		sScroll.ScrollingDirection = Enum.ScrollingDirection.Y
		sScroll.Parent = sHolder
		sScroll.Visible = (i == 1)
		pad(sScroll, 10, 18, 10, 10)
		local sLayout = Instance.new("UIListLayout")
		sLayout.SortOrder = Enum.SortOrder.LayoutOrder
		sLayout.Padding = UDim.new(0, 6)
		sLayout.Parent = sScroll
		table.insert(tabContents, sScroll)
	end

	local function addOption(scrollFrame, labelText, hasToggle, toggleCallback, initValue)
		local idx = #scrollFrame:GetChildren()
		local row = fr(scrollFrame, UDim2.new(1, -4, 0, 40), nil, C.HEADER, 0, 10)
		row.LayoutOrder = idx
		local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
		gradV(stripe, C.ACCENT, C.ACCENT2)
		lbl(row, labelText, UDim2.new(1, -70, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)
		if hasToggle then mkToggle(row, -56, initValue or false, toggleCallback) end
		return row
	end

	-- General Tab
	addOption(tabContents[1], "Show FPS counter", true, function(on) fpsLbl.Visible = on end, true)
	addOption(tabContents[1], "Show ping counter", true, function(on) pingLbl.Visible = on end, true)
	addOption(tabContents[1], "Show clock", true, function(on) timeLbl.Visible = on end, true)
	addOption(tabContents[1], "Show watermark", true, function(on) hudBar.Visible = on end, true)

	-- Appearance Tab
	addOption(tabContents[2], "Smooth animations", true, function(on) _G._SmoothAnimations = on end, true)
	addOption(tabContents[2], "Compact sidebar", true, function(on)
		SIDE_W = on and math.max(110, math.floor(WIN_W * 0.17)) or mainSideBase
	end, false)
	addOption(tabContents[2], "Blur background", true, function(on)
		_G._BlurEnabled = on
		if on and isOpen then
			if not blurPart then
				blurPart = Instance.new("BlurEffect")
				blurPart.Size = 12
				blurPart.Parent = Lighting
			end
		elseif not on and blurPart then
			blurPart:Destroy()
			blurPart = nil
		end
	end, false)

	-- Performance Tab
	addOption(tabContents[3], "Lighting preset dim", true, function(on)
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
	addOption(tabContents[3], "Low quality mode", true, function(on)
		if on then
			if not _G._OriginalQualityLevel then
				_G._OriginalQualityLevel = settings().Rendering.QualityLevel
			end
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		elseif _G._OriginalQualityLevel then
			settings().Rendering.QualityLevel = _G._OriginalQualityLevel
		end
	end, false)

	-- Keybinds Tab
	local function addKeybindOption(scrollFrame, labelText, currentKey, onChange)
		local row = fr(scrollFrame, UDim2.new(1, -4, 0, 40), nil, C.HEADER, 0, 10)
		row.LayoutOrder = #scrollFrame:GetChildren()
		local stripe = fr(row, UDim2.new(0, 3, 1, -8), UDim2.new(0, 0, 0, 4), C.ACCENT, 0, 0)
		gradV(stripe, C.ACCENT, C.ACCENT2)
		lbl(row, labelText, UDim2.new(1, -100, 1, 0), UDim2.new(0, 14, 0, 0), 12, C.TEXT)

		local keyBtn = Instance.new("TextButton")
		keyBtn.Size = UDim2.new(0, 70, 0, 26)
		keyBtn.Position = UDim2.new(1, -82, 0.5, -13)
		keyBtn.BackgroundColor3 = C.SEL
		keyBtn.Text = currentKey.Name
		keyBtn.TextColor3 = C.TEXT
		keyBtn.TextSize = 12
		keyBtn.Font = Enum.Font.GothamBold
		keyBtn.Parent = row
		Instance.new("UICorner").Parent = keyBtn

		keyBtn.MouseButton1Click:Connect(function()
			keyBtn.Text = "Press key..."
			keyBtn.BackgroundColor3 = C.ACCENT
			local conn
			conn = UserInputService.InputBegan:Connect(function(inp, gpe)
				if gpe then return end
				if inp.KeyCode and inp.KeyCode ~= Enum.KeyCode.Unknown then
					keyBtn.Text = inp.KeyCode.Name
					keyBtn.BackgroundColor3 = C.SEL
					onChange(inp.KeyCode)
					conn:Disconnect()
				end
			end)
			task.delay(5, function()
				if conn.Connected then
					conn:Disconnect()
					keyBtn.Text = currentKey.Name
					keyBtn.BackgroundColor3 = C.SEL
				end
			end)
		end)
	end

	addKeybindOption(tabContents[4], "Toggle menu key", _G._MenuToggleKey, function(newKey) _G._MenuToggleKey = newKey end)
	addKeybindOption(tabContents[4], "Unload script key", _G._UnloadKey, function(newKey) _G._UnloadKey = newKey end)
end

-- Menu Functions
local inSettings = false

local function openSettings()
	if inSettings then return end
	inSettings = true
	mainLayer.Visible = false
	settingsPanel.Visible = true
	settingsPanel.Size = UDim2.new(0, 0, 0, 0)
	settingsPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	tw(settingsPanel, { Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2) }, 0.22, Enum.EasingStyle.Quint)
end

local function closeSettings()
	if not inSettings then return end
	inSettings = false
	tw(settingsPanel, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.15, Enum.EasingStyle.Quart)
	task.delay(0.15, function()
		mainLayer.Visible = true
		settingsPanel.Visible = false
	end)
end

local function closeMenu()
	if not win then return end
	isOpen = false
	if blurPart and _G._BlurEnabled then
		blurPart:Destroy()
		blurPart = nil
	end
	tw(win, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.15, Enum.EasingStyle.Quart)
	task.delay(0.15, function()
		win.Visible = false
		unlockInput()
	end)
end

-- Button Connections
fireClick.MouseButton1Click:Connect(closeMenu)

homeBtn.MouseButton1Click:Connect(function()
	if inSettings then
		closeSettings()
		if homeBtnIcon2.ImageTransparency == 0 then
			tw(homeBtn, { ImageTransparency = 0, Rotation = 0 }, 0.4, Enum.EasingStyle.Quart)
			tw(homeBtnIcon2, { ImageTransparency = 1, Rotation = 360 }, 0.4, Enum.EasingStyle.Quart)
		end
	else
		openSettings()
		if homeBtnIcon2.ImageTransparency == 1 then
			tw(homeBtn, { ImageTransparency = 1, Rotation = -360 }, 0.4, Enum.EasingStyle.Quart)
			tw(homeBtnIcon2, { ImageTransparency = 0, Rotation = 0 }, 0.4, Enum.EasingStyle.Quart)
		end
	end
end)

homeBtn.MouseEnter:Connect(function() tw(homeBtn, { BackgroundTransparency = 0.05 }, 0.12) end)
homeBtn.MouseLeave:Connect(function() tw(homeBtn, { BackgroundTransparency = 0.2 }, 0.12) end)

-- Select first tab
activeTab = firstTab
firstTab._sel()

-- Dragging
local dragging = false
local dragOrig = Vector2.zero
local winOrig = UDim2.new()

local function dragPress(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragOrig = Vector2.new(inp.Position.X, inp.Position.Y)
		if win then
			win.Size = UDim2.new(0, win.AbsoluteSize.X, 0, win.AbsoluteSize.Y)
			win.Position = UDim2.new(0, win.AbsolutePosition.X, 0, win.AbsolutePosition.Y)
			winOrig = win.Position
		end
	end
end

local function dragRelease(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end

dragHandle.InputBegan:Connect(dragPress)
dragHandle.InputEnded:Connect(dragRelease)
settingsDrag.InputBegan:Connect(dragPress)
settingsDrag.InputEnded:Connect(dragRelease)

-- HUD Layout
local function updateHudLayout(animate)
	local baseX = 48
	local nameWidth = nameLbl.AbsoluteSize.X
	local welcomeWidth = 70
	local spacing = 12
	local currentX = baseX + welcomeWidth + spacing
	local animTime = animate and 0.15 or 0

	if nameWidth > 0 then
		currentX = baseX + math.max(welcomeWidth, nameWidth + 8) + spacing
	end

	local div1 = currentX
	tw(fpsLbl, { Position = UDim2.new(0, currentX + 12, 0, 12) }, animTime)
	tw(div1Frame, { Position = UDim2.new(0, currentX - 6, 0.22, 0) }, animTime)
	currentX = currentX + 78 + spacing

	if not fpsLbl.Visible then currentX = div1 end

	tw(pingLbl, { Position = UDim2.new(0, currentX + 12, 0, 12) }, animTime)
	tw(div2Frame, { Position = UDim2.new(0, currentX - 6, 0.22, 0) }, animTime)

	local timeDivX = currentX + 65 + spacing
	if not pingLbl.Visible then timeDivX = currentX end

	tw(timeLbl, { Position = UDim2.new(0, timeDivX, 0, 14) }, animTime)

	local toggleX = timeDivX + 65 + spacing
	if not timeLbl.Visible then toggleX = timeDivX end

	tw(homeBtn, { Position = UDim2.new(0, toggleX, 0.45, -15) }, animTime)
	tw(badge, { Position = UDim2.new(0, toggleX + 30 + spacing, 0.5, -14) }, animTime)
end

task.defer(function() updateHudLayout(false) end)
nameLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateHudLayout(true) end)
fpsLbl:GetPropertyChangedSignal("Visible"):Connect(function() updateHudLayout(true) end)
pingLbl:GetPropertyChangedSignal("Visible"):Connect(function() updateHudLayout(true) end)
timeLbl:GetPropertyChangedSignal("Visible"):Connect(function() updateHudLayout(true) end)

-- RenderStepped
local fpsT, fpsN = 0, 0
local conns = {}

table.insert(conns, RunService.RenderStepped:Connect(function(dt)
	-- FPS/Ping/Time
	fpsT += dt
	fpsN += 1
	if fpsT >= 0.5 then
		fpsLbl.Text = tostring(math.round(fpsN / fpsT)) .. " FPS"
		fpsN = 0
		fpsT = 0
	end
	pingLbl.Text = tostring(math.round(lp:GetNetworkPing() * 1000)) .. " ms"
	timeLbl.Text = os.date("%I:%M %p")

	-- Lighting
	if _G._LightingDimEnabled then
		Lighting.Brightness = 0.3
		Lighting.ClockTime = 0
	end

	-- Dragging
	if dragging and win then
		local mp = UserInputService:GetMouseLocation()
		local dx = mp.X - dragOrig.X
		local dy = mp.Y - dragOrig.Y
		win.Position = UDim2.new(winOrig.X.Scale, winOrig.X.Offset + dx, winOrig.Y.Scale, winOrig.Y.Offset + dy)
	end
end))

-- Input Handler
table.insert(conns, UserInputService.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	local toggleKey = _G._MenuToggleKey or Enum.KeyCode.Insert
	local unloadKey = _G._UnloadKey or Enum.KeyCode.Delete

	if inp.KeyCode == toggleKey then
		if not win.Visible then
			isOpen = true
			refreshLayout()
			mainSideBase = SIDE_W
			win.Size = UDim2.new(0, WIN_W, 0, WIN_H)
			win.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
			lockInput()
			local cam2 = workspace.CurrentCamera
			if cam2 then frozenCF = cam2.CFrame end
			hudBar.Visible = true
			win.Visible = true
			if _G._BlurEnabled and not blurPart then
				blurPart = Instance.new("BlurEffect")
				blurPart.Size = 12
				blurPart.Parent = Lighting
			end
			updateHudLayout(false)
			win.Size = UDim2.new(0, 0, 0, 0)
			win.Position = UDim2.new(0.5, 0, 0.5, 0)
			tw(win, { Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2) }, 0.22, Enum.EasingStyle.Quint)
		else
			closeMenu()
		end
	elseif inp.KeyCode == unloadKey then
		pcall(function() RunService:UnbindFromRenderStep(RS_BIND_INP) end)
		pcall(function() RunService:UnbindFromRenderStep(RS_BIND_CAM) end)
		unlockInput()
		if _G._OriginalQualityLevel then settings().Rendering.QualityLevel = _G._OriginalQualityLevel end
		if _G._OriginalBrightness then
			Lighting.Brightness = _G._OriginalBrightness
			Lighting.ClockTime = _G._OriginalClockTime
		end
		if blurPart then blurPart:Destroy() end
		for _, c in ipairs(conns) do c:Disconnect() end
		sg:Destroy()
	end
end))
