local dom = require(script.Parent:WaitForChild("DOM.lua"))
local TS = game:GetService("TextService")

local FontHeights = {}
local function GetFontHeight(size,font)
	if FontHeights[font] and FontHeights[font][size] then
		return FontHeights[font][size]
	end
	local s = TS:GetTextSize('',size,font,Vector2.new(150,150)).Y
	local t = FontHeights[font]
	if not t then
		t = {}
		FontHeights[font] = t
	end
	t[size] = s
	return s
end

local CharWaitingTime = {
	--[" "] = 2,
	[","] = 3,
	[";"] = 6,
	["."] = 6,
	["!"] = 6,
	["?"] = 6,
	["\n"] = 10
}

local mt = {
	_createLabel = function(self,text,size,pos,font,color)
		local tl = Instance.new("TextLabel")
		tl.BackgroundTransparency = 1
		tl.TextColor3 = color or self.Font.Color or Color3.new(1,1,1)
		tl.Position = UDim2.new(pos.X/self.XSize,0,pos.Y/self.YSize,0)
		tl.Size = UDim2.new(size.X/self.XSize,10,size.Y/self.YSize,0)
		tl.Font = font
		tl.Text = text
		tl.TextScaled = true
		tl.TextWrapped = true
		tl.TextXAlignment = Enum.TextXAlignment.Left
		tl.TextYAlignment = Enum.TextYAlignment.Top
		tl.Parent = self.Frame
		return tl
	end,
	ProcessText = function(self,textObj)
		local lines = {}
		local default = {Font=self.Font.Normal,Color=self.Font.Color,Size=self.Font.Size}
		local stack = {}
		local currentLine = {default}
		local maxheight = 0
		local xoffset = 0
		local function NextLine()
			table.insert(lines,currentLine)
			table.insert(lines,maxheight)
			currentLine = {}
			xoffset = 0
		end
		local function recursive(obj)
			for i,ch in pairs(obj) do
				if type(ch)=='string' then
					local words = ch:split(' ')
					local props = stack[#stack] or default
					local size,font = props.Size or default.Size,props.Font or default.Font
					local fontheight = GetFontHeight(size,font)
					maxheight = math.max(maxheight,fontheight)
					local loopover
					repeat
						local size = TS:GetTextSize(table.concat(words,' '),size,font,Vector2.new(self.XSize-xoffset,1000))
						if size.Y > fontheight then
							if not loopover then loopover = {} end
							table.insert(loopover,1,table.remove(words))
							if #words == 0 then
								if xoffset == 0 then
									words,loopover = loopover,nil
								end
								break
							end
						else
							xoffset = xoffset + size.X
							break
						end
					until not loopover
					table.insert(currentLine,table.concat(words,' '))
					if loopover then
						NextLine()
						recursive({table.concat(loopover,' ')})
					end
				else
					local tag = dom.getTag(ch)
					if tag=='br' then
						NextLine()
						table.insert(lines,'\n')
						continue
					elseif tag=='wait' then
						local t = tonumber(dom.getAttribute(ch,'t')) or 0
						table.insert(currentLine,{Wait=t})
						continue
					end
					local pt = stack[#stack] or default
					local t = {Font=pt.Font,Color=pt.Color,Size=pt.Size}
					if tag=='b' then
						t.Font = self.Font.Bold
					elseif tag=='i' then
						t.Font = self.Font.Italic
					elseif tag=='mark' then
						t.Color = self.Font.MarkedColor
					end
					table.insert(currentLine,t)
					table.insert(stack,t)
					recursive(dom.getChildren(ch))
					table.remove(stack)
					table.insert(currentLine,pt)
				end
			end
		end
		recursive(dom.getChildren(textObj))
		NextLine()
		return lines
	end,
	ClearText = function(self)
		self.Frame:ClearAllChildren()
	end,
	SetText = function(self,textObj)
		self:DrawText(textObj,true)
	end,
	GameTick = function(self,dt)
		if self.Drawing then
			self.DrawingDeltaTime = self.DrawingDeltaTime + dt
			local thread = self.DrawingThread
			if not thread then return end
			while self.DrawingDeltaTime >= self.DrawSpeed do
				coroutine.resume(thread)
				if not self.Drawing then break end
				self.DrawingDeltaTime = self.DrawingDeltaTime - self.DrawSpeed
			end
		end
	end,
	SkipTextDrawing = function(self)
		if not self.Drawing then return end
		self.SkipDrawing = true
		local thread = self.DrawingThread
		if not thread then return end
		if coroutine.status(thread)=='suspended' then
			coroutine.resume(thread)
		end
	end,
	DrawText = function(self,textObj,skip)
		self:ClearText()
		local lines = self:ProcessText(textObj)
		local xoffset,yoffset = 0,0
		local props
		local skipped = false
		if not skip then
			self.Drawing = true
			self.SkipDrawing = false
			self.DrawingDeltaTime = 0
			self.DrawingThread = coroutine.running()
		else
			skipped = true
		end
		local function twait(ticks)
			if skipped or self.SkipDrawing then return end
			for i=1,ticks do
				if not self.SkipDrawing then
					coroutine.yield()
				else
					skipped = true
					break
				end
			end
		end
		for i,line in pairs(lines) do
			if type(line)=='number' then
				yoffset = yoffset + line
				xoffset = 0
				continue
			end
			if line=='\n' then
				twait(CharWaitingTime['\n'] or 15)
				continue
			end
			for i,c in pairs(line) do
				if type(c)=='table' then
					if c.Wait then
						local t = c.Wait
						if t == 0 then
							local dt = self.DrawingThread
							self.DrawingThread = nil
							self.Game:WaitForInput()
							self.DrawingThread = dt
						else
							twait(t)
						end
						continue
					end
					props = c
					continue
				end
				if self.Game then
					c = self.Game:FormatVariables(c)
				end
				local size = TS:GetTextSize(c,props.Size,props.Font,Vector2.new(2000,2000))
				local tl = self:_createLabel(skipped and c or '',size,Vector2.new(xoffset,yoffset),props.Font,props.Color)
				xoffset = xoffset + size.X
				if skipped then continue end
				for i=1,#c do
					tl.Text = c:sub(1,i)
					twait(CharWaitingTime[c:sub(i,i)] or 1)
				end
			end
		end
		if not skip then
			self.DrawingThread = nil
			self.SkipDrawing = nil
			self.DrawingDeltaTime = nil
			self.Drawing = false
		end
	end
}
mt.__index = mt

return function(Game,frame,font,xsize,ysize)
	return setmetatable({
		Game = Game,
		Frame = frame,
		XSize = xsize,
		YSize = ysize,
		Font = font,
		Drawing = false,
		DrawSpeed = 0.05,
		Text = nil
	},mt)
end
