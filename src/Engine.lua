local folder = script.Parent
local ParseXML = require(folder:WaitForChild("XML_Parser.lua"))
local dom = require(folder:WaitForChild("DOM.lua"))
local TextRenderer = require(folder:WaitForChild("Text_Renderer.lua"))

local Version = "0.1"

local function SplitNumbers(str)
	local t = str:gsub(' ',''):split(',')
	for i,c in ipairs(t) do
		t[i] = tonumber(c)
	end
	return t
end
local function toColor3(str)
	if not str then return end
	return Color3.fromRGB(unpack(SplitNumbers(str)))
end
local function toCFrame(str)
	if not str then return end
	return CFrame.new(unpack(SplitNumbers(str)))
end
local function toVector3(str)
	if not str then return end
	return Vector3.new(unpack(SplitNumbers(str)))
end

local TW = game:GetService("TweenService")

local Game_mt = {
	SetAssetFolder = function(self,folder)
		self.AssetsFolder = folder
	end,
	SetGui = function(self,frame)
		if frame then
			self.Frame = frame
		else
			if not self.Builder then
				self.Builder = require(folder:WaitForChild("GUI_Builder.lua"))()
			end
			self.Frame = self.Builder:BuildAll()
		end
		
		local db = self.Frame.DialogBox
		self._frameInputConnection = db.InputBegan:Connect(function(io)
			if io.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			self:_advanceInput()
		end)			
		
		local txt = db.Text
		local x,y = 1280,720
		x = x * db.Size.X.Scale
		y = y * db.Size.Y.Scale
		db.SpeakerName.Size = UDim2.new(1,0,self.Font.Size/y,0)
		x = x * txt.Size.X.Scale
		y = y * txt.Size.Y.Scale
		self._textFramePixelSize = Vector2.new(x,y)
		self.DialogBox = TextRenderer(self,self.Frame.DialogBox.Text,self.Font,x,y)
	end,
	GameTick = function(self,dt)
		self.DialogBox:GameTick(dt)
	end,
	SetTick = function(self,event)
		event:Connect(function(dt)
			self:GameTick(dt)
		end)
	end,
	_advanceInput = function(self)
		local thread = self._waitingThread
		if thread then
			assert(coroutine.resume(thread))
		elseif self.DialogBox.Drawing then
			self.DialogBox:SkipTextDrawing()
		end
	end,
	WaitForInput = function(self)
		self._waitingThread = coroutine.running()
		coroutine.yield()
		self._waitingThread = nil
	end,
	SetVariables = function(self,vars)
		self.Variables = vars
	end,
	SetFunctions = function(self,funcs)
		self.Functions = funcs
	end,
	FormatVariables = function(self,txt)
		return txt:gsub("{([%w-_]+)}",function(var)
			local v = self.Variables[var]
			if type(v)=='function' then
				return v(self,var)
			end
			return v or "[MISSING_VARIABLE]"
		end)
	end,
	ChangeSpeaker = function(self,name,clr)
		local db = self.Frame.DialogBox
		db.BackgroundColor3 = clr
		db.SpeakerName.TextColor3 = clr
		if not name then
			db.SpeakerName.Visible = false
			return
		else
			db.SpeakerName.Visible = true
		end
		db.SpeakerName.Font = self.Font.Bold
		db.SpeakerName.Text = self:FormatVariables(name)
	end,
	_clearButtons = function(self,prompt)
		local bp = self.Frame.ButtonPrompt
		for _,c in pairs(bp:GetChildren()) do
			if c:IsA("TextButton") then
				c:Destroy()
			end
		end
	end,
	RunFunction = function(self,obj,...)
		local f = dom.getAttribute(obj,'func')
		if f then
			f = self.Functions[f]
			if f then
				f(self,obj,...)
				return true
			end
		end
		return false
	end,
	PromptButtons = function(self,prompt)
		local bp = self.Frame.ButtonPrompt
		self:_clearButtons()
		local thread = coroutine.running()
		for i,btn in pairs(dom.getElementsByTagName(prompt,'button')) do
			local txt = self:FormatVariables(dom.getText(btn))
			local a = dom.getAttributes(btn)
			local b = self.Builder:BuildPromptButton(dom.getText(btn),toColor3(a.BackgroundColor3),toColor3(a.TextColor3),self.Font.Normal,i)
			b.Parent = bp
			b.MouseButton1Click:Connect(function()
				if coroutine.status(thread)=='suspended' then
					assert(coroutine.resume(thread,btn))
				end
			end)
		end
		bp.Visible = true
		local selected = coroutine.yield()
		self:_clearButtons()
		bp.Visible = false
		self:RunFunction(selected,prompt)
		self:RunFunction(prompt,selected)
		return selected
	end,
	ProcessScene = function(self,scene)
		local m = dom.getAttribute(scene,'clear')
		if m then
			if m=="fadeout" then
				local t = dom.getAttribute(scene,'time')
				t = t and tonumber(t) or 1
				for i,c in pairs(self.Scene) do
					local tween = TW:Create(c,TweenInfo.new(t),{
						ImageTransparency = 1
					})
					tween.Completed:Connect(function()
						c:Destroy()	
					end)
					tween:Play()
					self.Scene[i] = nil
				end
				wait(t)
			else
				for i,c in pairs(self.Scene) do
					c:Destroy()
					self.Scene[i] = nil
				end
			end
			return
		end
		local wt
		for i,c in pairs(dom.getElementsByTagName(scene,'obj',true)) do
			local ca = dom.getAttributes(c)
			local asset = self.Assets[ca.id] or error(("Asset %s not found"):format(ca.id))
			if not self.Scene[ca.id] then
				local model = dom.getAttributes(dom.getElementByTagName(asset,'model'))
				local camera = dom.getAttributes(dom.getElementByTagName(asset,'camera'))
				local frame = dom.getAttributes(dom.getElementByTagName(asset,'frame'))
				local vf = Instance.new("ViewportFrame")
				vf.BackgroundTransparency = 1
				vf.ZIndex = tonumber(ca.z) or 1
				vf.AnchorPoint = Vector2.new(0.5,0.5)
				vf.Size = UDim2.new((tonumber(frame.XScale) or 1),0,(tonumber(frame.YScale) or 1),0)
				vf.Position = UDim2.new(0.5 + (tonumber(frame.XOffset) or 0),0,0.5 + (tonumber(frame.YOffset) or 0),0)
				vf.Ambient = toColor3(frame.Ambient) or Color3.new(1,1,1)
				vf.LightColor = toColor3(frame.LightColor) or Color3.new(1,1,1)
				vf.LightDirection = toVector3(frame.LightDirection) or Vector3.new(-1,-1,-1)
				local cam = Instance.new("Camera")
				cam.CameraType = Enum.CameraType.Scriptable
				cam.FieldOfView = tonumber(camera.FieldOfView) or 70
				cam.CFrame = toCFrame(camera.CFrame) or CFrame.new()
				cam.Parent = vf
				vf.CurrentCamera = cam
				local model = self.AssetsFolder:FindFirstChild(model.path):Clone()
				model.Parent = vf
				vf.Parent = self.Frame
				self.Scene[ca.id] = vf
			end
			local vf = self.Scene[ca.id]
			if ca.effect then
				if ca.effect == 'fadein' then
					vf.ImageTransparency = 1
					local t = tonumber(ca.time) or 1
					local tween = TW:Create(vf,TweenInfo.new(t),{
						ImageTransparency = 0
					})
					tween:Play()
					wt = math.max(wt or 0,t)
				elseif ca.effect == 'fadeout' then
					vf.ImageTransparency = 0
					local t = tonumber(ca.time) or 1
					local tween = TW:Create(vf,TweenInfo.new(t),{
						ImageTransparency = 1
					})
					tween:Play()
					wt = math.max(wt or 0,t)
				end
			end
		end
		if wt then
			wait(wt)
		end
	end,
	AdvanceDialog = function(self)
		local dg = self.CurrentDialog
		local index = self.CurrentDialogIndex
		local obj = dom.getChildren(dg)[index]
		if not obj then
			return false
		end
		local tag = dom.getTag(obj)
		if tag=='scene' then
			self:ProcessScene(obj)
		elseif tag=='prompt' then
			local btn = self:PromptButtons(obj)
			if not btn then error("No button was selected") end
			local a = dom.getAttributes(btn)
			if a.to then
				return self:LoadDialog(a.to)
			end
		elseif tag=='switch' then
			for _,case in pairs(dom.getElementsByTagName(obj,'case')) do
				local a = dom.getAttributes(case)
				local vars = self.Variables
				local check = true
				for k,v in pairs(a) do
					if k=='to' then continue end
					if v~=tostring(vars[k]) then
						check = false
						break
					end
				end
				if check then
					self.NextDialogId = a.to
					return false
				end
			end
		elseif tag=='text' then
			local sp = dom.getAttribute(obj,'speaker')
			if sp=='none' then
				self:ChangeSpeaker(nil,Color3.new(1,1,1))
			elseif sp then
				local char = self.Characters[sp]
				local name,clr
				if not char then
					name,clr = sp,dom.getAttribute(obj,'color')
				else
					name,clr = dom.getAttribute(obj,'namehidden') and '???' or dom.getAttribute(char,'name'),dom.getAttribute(char,'color')
				end
				self:ChangeSpeaker(name or "MISSING_NAME",toColor3(clr) or Color3.new(1,1,1))
			end
			self.DialogBox:DrawText(obj)
			self:WaitForInput()
		end
		return true
	end,
	LoadDialog = function(self)
		if not self.NextDialogId then return false end
		local dg = self.Dialogs[self.NextDialogId]
		self.NextDialogId = dom.getAttribute(dg,'to')
		if not dg then return false end
		self.CurrentDialog = dg
		self.CurrentDialogIndex = 1
		return dg
	end,
	GameLoop = function(self,dialogStartId)
		self.GameLoopRunning = true
		self.NextDialogId = dialogStartId
		while self:LoadDialog() do
			while self:AdvanceDialog() do
				self.CurrentDialogIndex = self.CurrentDialogIndex + 1
			end
		end
		self.GameLoopRunning = false
	end
}
Game_mt.__index = Game_mt

return function(xml)
	local GameData = dom.getElementByTagName(ParseXML(xml),'game',true) or error("Incorrect XML")
	local game_version = dom.getAttribute(GameData,'version')
	if Version~=game_version then
		error(("Game version mismatch: Engine v%s; Game v%s"):format(Version,game_version),2)
	end
	local Game = setmetatable({
		GameData = GameData,
		Scene = {},
		Variables = {},
		Functions = {},
		Title = dom.getText(dom.getElementByTagName(GameData,'title',true)),
		Speaker = nil,
		Characters = dom.indexById(dom.getElementsByTagName(GameData,'character',true),true),
		Assets = dom.indexById(dom.getElementsByTagName(GameData,'asset',true),true),
		Dialogs = dom.indexById(dom.getElementsByTagName(GameData,'dialog',true),true)
	},Game_mt)
	local font = dom.getAttributes(dom.getElementByTagName(GameData,'font'))
	Game.Font = {
		Color = font.color and toColor3(font.color) or Color3.new(1,1,1),
		MarkedColor = font.marked and toColor3(font.marked) or Color3.new(1,1,0.2),
		Size = font.size or 36,
		Normal = Enum.Font[font.normal or "SourceSans"],
		Bold = Enum.Font[font.bold or "SourceSansBold"],
		Italic = Enum.Font[font.italic or "SourceSansItalic"]
	}
	return Game
end
