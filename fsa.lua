-- PartSizeEditor (LocalScript) - StarterPlayerScripts に入れてください
-- Workspaceを再帰的に探してパーツ/モデルをリスト表示、均等スケールで変更できる

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ===========================
-- ユーティリティ
-- ===========================

-- Workspaceを再帰的に探してBasePart/Modelを収集
local function collectObjects(parent, results, depth)
	depth = depth or 0
	results = results or {}
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("BasePart") or child:IsA("Model") then
			table.insert(results, { obj = child, depth = depth })
		end
		collectObjects(child, results, depth + 1)
	end
	return results
end

-- オブジェクトの「代表サイズ」を返す
-- Modelの場合はPrimaryPartまたはGetExtentsSize、Partの場合はSize
local function getSize(obj)
	if obj:IsA("Model") then
		if obj.PrimaryPart then
			return obj.PrimaryPart.Size
		else
			local cf, size = obj:GetBoundingBox()
			return size
		end
	else
		return obj.Size
	end
end

-- オブジェクトにサイズを適用（均等スケール）
local function applyScale(obj, scale)
	if obj:IsA("Model") then
		-- Modelの子パーツをすべてスケール
		local cf, baseSize = obj:GetBoundingBox()
		local center = cf.Position
		for _, part in ipairs(obj:GetDescendants()) do
			if part:IsA("BasePart") then
				local offset = part.Position - center
				part.Size = part.Size * scale
				part.Position = center + offset * scale
			end
		end
	elseif obj:IsA("BasePart") then
		obj.Size = obj.Size * scale
	end
end

-- ===========================
-- UI生成
-- ===========================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PartSizeEditorGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = player.PlayerGui

-- メインウィンドウ
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 480)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- タイトルバー
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- タイトルバー下部の角を消すためのカバー
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🔧 Part Size Editor"
titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- 最小化ボタン
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 22)
minimizeBtn.Position = UDim2.new(1, -38, 0, 9)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "－"
minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minimizeBtn.TextSize = 14
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = minimizeBtn

-- コンテンツエリア
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, 0, 1, -40)
content.Position = UDim2.new(0, 0, 0, 40)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- 検索バー
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -20, 0, 30)
searchBox.Position = UDim2.new(0, 10, 0, 8)
searchBox.BackgroundColor3 = Color3.fromRGB(42, 42, 55)
searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "🔍 名前で検索..."
searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(220, 220, 220)
searchBox.TextSize = 12
searchBox.Font = Enum.Font.Gotham
searchBox.ClearTextOnFocus = false
searchBox.Parent = content

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 7)
searchCorner.Parent = searchBox

-- 更新ボタン
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(1, -20, 0, 26)
refreshBtn.Position = UDim2.new(0, 10, 0, 44)
refreshBtn.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
refreshBtn.BorderSizePixel = 0
refreshBtn.Text = "🔄 リスト更新"
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.TextSize = 12
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.Parent = content

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 7)
refreshCorner.Parent = refreshBtn

-- パーツリスト（スクロール）
local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "PartList"
listFrame.Size = UDim2.new(1, -20, 0, 200)
listFrame.Position = UDim2.new(0, 10, 0, 76)
listFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 5
listFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Parent = content

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 7)
listCorner.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = listFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 4)
listPadding.PaddingBottom = UDim.new(0, 4)
listPadding.PaddingLeft = UDim.new(0, 4)
listPadding.PaddingRight = UDim.new(0, 4)
listPadding.Parent = listFrame

-- 選択中パーツ情報
local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1, -20, 0, 28)
selectedLabel.Position = UDim2.new(0, 10, 0, 284)
selectedLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
selectedLabel.BorderSizePixel = 0
selectedLabel.Text = "選択: なし"
selectedLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
selectedLabel.TextSize = 12
selectedLabel.Font = Enum.Font.GothamBold
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = content

local selCorner = Instance.new("UICorner")
selCorner.CornerRadius = UDim.new(0, 7)
selCorner.Parent = selectedLabel

local selPadding = Instance.new("UIPadding")
selPadding.PaddingLeft = UDim.new(0, 8)
selPadding.Parent = selectedLabel

-- 現在のサイズ表示
local sizeLabel = Instance.new("TextLabel")
sizeLabel.Size = UDim2.new(1, -20, 0, 22)
sizeLabel.Position = UDim2.new(0, 10, 0, 318)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "現在のサイズ: -"
sizeLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
sizeLabel.TextSize = 11
sizeLabel.Font = Enum.Font.Gotham
sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
sizeLabel.Parent = content

-- スケール倍率表示
local scaleValueLabel = Instance.new("TextLabel")
scaleValueLabel.Size = UDim2.new(1, -20, 0, 22)
scaleValueLabel.Position = UDim2.new(0, 10, 0, 342)
scaleValueLabel.BackgroundTransparency = 1
scaleValueLabel.Text = "スケール: 1.0x"
scaleValueLabel.TextColor3 = Color3.fromRGB(255, 210, 100)
scaleValueLabel.TextSize = 12
scaleValueLabel.Font = Enum.Font.GothamBold
scaleValueLabel.TextXAlignment = Enum.TextXAlignment.Left
scaleValueLabel.Parent = content

-- スライダー背景
local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, -20, 0, 16)
sliderBg.Position = UDim2.new(0, 10, 0, 368)
sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = content

local sliderBgCorner = Instance.new("UICorner")
sliderBgCorner.CornerRadius = UDim.new(0, 8)
sliderBgCorner.Parent = sliderBg

-- スライダーフィル
local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(0, 8)
sliderFillCorner.Parent = sliderFill

-- スライダーつまみ
local sliderHandle = Instance.new("Frame")
sliderHandle.Size = UDim2.new(0, 20, 0, 20)
sliderHandle.Position = UDim2.new(0.5, -10, 0.5, -10)
sliderHandle.BackgroundColor3 = Color3.fromRGB(200, 220, 255)
sliderHandle.BorderSizePixel = 0
sliderHandle.ZIndex = 2
sliderHandle.Parent = sliderBg

local handleCorner = Instance.new("UICorner")
handleCorner.CornerRadius = UDim.new(1, 0)
handleCorner.Parent = sliderHandle

-- 範囲ラベル
local rangeMinLabel = Instance.new("TextLabel")
rangeMinLabel.Size = UDim2.new(0, 50, 0, 16)
rangeMinLabel.Position = UDim2.new(0, 10, 0, 387)
rangeMinLabel.BackgroundTransparency = 1
rangeMinLabel.Text = "0.1x"
rangeMinLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
rangeMinLabel.TextSize = 10
rangeMinLabel.Font = Enum.Font.Gotham
rangeMinLabel.TextXAlignment = Enum.TextXAlignment.Left
rangeMinLabel.Parent = content

local rangeMaxLabel = Instance.new("TextLabel")
rangeMaxLabel.Size = UDim2.new(0, 50, 0, 16)
rangeMaxLabel.Position = UDim2.new(1, -60, 0, 387)
rangeMaxLabel.BackgroundTransparency = 1
rangeMaxLabel.Text = "10x"
rangeMaxLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
rangeMaxLabel.TextSize = 10
rangeMaxLabel.Font = Enum.Font.Gotham
rangeMaxLabel.TextXAlignment = Enum.TextXAlignment.Right
rangeMaxLabel.Parent = content

-- 適用ボタン
local applyBtn = Instance.new("TextButton")
applyBtn.Size = UDim2.new(1, -20, 0, 32)
applyBtn.Position = UDim2.new(0, 10, 0, 408)
applyBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
applyBtn.BorderSizePixel = 0
applyBtn.Text = "✅ サイズを適用"
applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
applyBtn.TextSize = 13
applyBtn.Font = Enum.Font.GothamBold
applyBtn.Parent = content

local applyCorner = Instance.new("UICorner")
applyCorner.CornerRadius = UDim.new(0, 8)
applyCorner.Parent = applyBtn

-- リセットボタン
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(1, -20, 0, 26)
resetBtn.Position = UDim2.new(0, 10, 0, 446)
resetBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
resetBtn.BorderSizePixel = 0
resetBtn.Text = "↩ 元のサイズに戻す"
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.TextSize = 12
resetBtn.Font = Enum.Font.GothamBold
resetBtn.Parent = content

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 8)
resetCorner.Parent = resetBtn

-- ===========================
-- ロジック
-- ===========================

local selectedObject = nil
local originalSizeMap = {} -- [object] = originalSize(Vector3)
local currentScale = 1.0   -- スライダーの現在倍率
local allObjects = {}       -- 収集したオブジェクト全リスト
local selectedButton = nil  -- 現在選択中のボタン

-- スライダー範囲: 0.1x ～ 10x、対数スケールで
local SCALE_MIN = 0.1
local SCALE_MAX = 10.0

local function scaleFromT(t)
	-- 0～1のtを対数スケールに変換
	return SCALE_MIN * (SCALE_MAX / SCALE_MIN) ^ t
end
local function tFromScale(s)
	return math.log(s / SCALE_MIN) / math.log(SCALE_MAX / SCALE_MIN)
end

-- スライダーのt値（0～1）
local sliderT = tFromScale(1.0)

local function updateSliderVisual(t)
	t = math.clamp(t, 0, 1)
	sliderFill.Size = UDim2.new(t, 0, 1, 0)
	sliderHandle.Position = UDim2.new(t, -10, 0.5, -10)
	currentScale = scaleFromT(t)
	scaleValueLabel.Text = string.format("スケール: %.2fx", currentScale)
end

-- パーツ名からアイコンを返す
local function getIcon(obj)
	if obj:IsA("Model") then return "📦" end
	return "🔷"
end

-- リストアイテムを生成
local function createListItem(obj, depth)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = Color3.fromRGB(42, 42, 55)
	btn.BorderSizePixel = 0
	btn.Text = string.rep("  ", depth) .. getIcon(obj) .. " " .. obj.Name
	btn.TextColor3 = Color3.fromRGB(210, 210, 210)
	btn.TextSize = 12
	btn.Font = Enum.Font.Gotham
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = false

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 5)
	btnCorner.Parent = btn

	local btnPad = Instance.new("UIPadding")
	btnPad.PaddingLeft = UDim.new(0, 8)
	btnPad.Parent = btn

	btn.MouseEnter:Connect(function()
		if selectedObject ~= obj then
			btn.BackgroundColor3 = Color3.fromRGB(55, 55, 72)
		end
	end)
	btn.MouseLeave:Connect(function()
		if selectedObject ~= obj then
			btn.BackgroundColor3 = Color3.fromRGB(42, 42, 55)
		end
	end)

	btn.MouseButton1Click:Connect(function()
		-- 前の選択を解除
		if selectedButton then
			selectedButton.BackgroundColor3 = Color3.fromRGB(42, 42, 55)
		end
		selectedObject = obj
		selectedButton = btn
		btn.BackgroundColor3 = Color3.fromRGB(60, 100, 180)

		-- 元サイズを記録（初回のみ）
		if not originalSizeMap[obj] then
			originalSizeMap[obj] = getSize(obj)
		end

		local sz = originalSizeMap[obj]
		selectedLabel.Text = "選択: " .. obj.Name
		sizeLabel.Text = string.format("元サイズ: %.2f, %.2f, %.2f", sz.X, sz.Y, sz.Z)

		-- スライダーをリセット
		sliderT = tFromScale(1.0)
		updateSliderVisual(sliderT)
	end)

	return btn
end

-- リストを構築
local function buildList(filter)
	-- 既存のアイテムを削除
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	filter = filter and filter:lower() or ""
	local count = 0
	for _, entry in ipairs(allObjects) do
		local obj = entry.obj
		if filter == "" or obj.Name:lower():find(filter, 1, true) then
			local btn = createListItem(obj, entry.depth)
			btn.LayoutOrder = count
			btn.Parent = listFrame
			count = count + 1
		end
	end
end

-- オブジェクト収集 & リスト更新
local function refreshList()
	allObjects = collectObjects(workspace)
	buildList(searchBox.Text)
	selectedObject = nil
	selectedButton = nil
	selectedLabel.Text = "選択: なし"
	sizeLabel.Text = "現在のサイズ: -"
	sliderT = tFromScale(1.0)
	updateSliderVisual(sliderT)
end

-- ===========================
-- スライダー操作
-- ===========================

local isDragging = false

sliderBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = true
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = false
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
		local absPos = sliderBg.AbsolutePosition.X
		local absSize = sliderBg.AbsoluteSize.X
		local mouseX = input.Position.X
		sliderT = math.clamp((mouseX - absPos) / absSize, 0, 1)
		updateSliderVisual(sliderT)
	end
end)

-- ===========================
-- ボタン処理
-- ===========================

refreshBtn.MouseButton1Click:Connect(function()
	refreshList()
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	buildList(searchBox.Text)
end)

applyBtn.MouseButton1Click:Connect(function()
	if not selectedObject then return end
	-- 元サイズからの倍率変化を適用
	-- まず元サイズに戻してからスケールをかける
	local orig = originalSizeMap[selectedObject]
	if not orig then return end

	if selectedObject:IsA("Model") then
		-- 一旦元に戻す
		-- (Modelは複雑なので差分スケールで処理)
		-- 現在のサイズと元サイズの比率からdeltaScaleを計算
		local currentSize = getSize(selectedObject)
		local deltaScale = (orig.X / currentSize.X) * currentScale
		applyScale(selectedObject, deltaScale)
	elseif selectedObject:IsA("BasePart") then
		selectedObject.Size = orig * currentScale
	end

	local newSz = getSize(selectedObject)
	sizeLabel.Text = string.format("元サイズ: %.2f, %.2f, %.2f", orig.X, orig.Y, orig.Z)
	selectedLabel.Text = "✅ 適用済み: " .. selectedObject.Name
end)

resetBtn.MouseButton1Click:Connect(function()
	if not selectedObject then return end
	local orig = originalSizeMap[selectedObject]
	if not orig then return end

	if selectedObject:IsA("Model") then
		local currentSize = getSize(selectedObject)
		local deltaScale = orig.X / currentSize.X
		applyScale(selectedObject, deltaScale)
	elseif selectedObject:IsA("BasePart") then
		selectedObject.Size = orig
	end

	sliderT = tFromScale(1.0)
	updateSliderVisual(sliderT)
	selectedLabel.Text = "↩ リセット済み: " .. selectedObject.Name
end)

-- 最小化
local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	content.Visible = not isMinimized
	mainFrame.Size = isMinimized
		and UDim2.new(0, 300, 0, 40)
		or UDim2.new(0, 300, 0, 480)
	minimizeBtn.Text = isMinimized and "＋" or "－"
end)

-- ===========================
-- 初期化 & 自動更新
-- ===========================

refreshList()

-- Workspaceに変化があったら自動更新（1秒ごと）
local lastChildCount = #workspace:GetDescendants()
task.spawn(function()
	while true do
		task.wait(1)
		local count = #workspace:GetDescendants()
		if count ~= lastChildCount then
			lastChildCount = count
			allObjects = collectObjects(workspace)
			buildList(searchBox.Text)
		end
	end
end)
