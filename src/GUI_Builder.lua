local function Create(cn)
	local i = type(cn)=='string' and Instance.new(cn) or cn:Clone()
	return function(t)
		local signals,funcs
		for k,v in pairs(t) do
			if k=='Parent' then continue end
			if type(k)=='number' then
				if type(v)=='function' then
					if not funcs then funcs={} end
					table.insert(funcs,v)
				else
					v.Parent = i
				end
				continue
			elseif typeof(i[k])=='RBXScriptSignal' then
				if not signals then signals={} end
				signals[k] = v
			end
			i[k] = v
		end
		if t.Parent then
			i.Parent = t.Parent
		end
		if signals then
			for k,v in pairs(signals) do
				i[k]:Connect(v)
			end
		end
		if funcs then
			for _,f in pairs(funcs) do
				f(i)
			end
		end
		return i
	end
end

local mt = {
	BuildPromptButton = function(self,text,bc3,tc3,font,lo)
		return Create"TextButton"{
			BorderSizePixel = 0,
			Size = UDim2.new(1,0,0.1,0),
			BackgroundColor3 = bc3 or Color3.new(1,1,1),
			TextScaled = true,
			TextColor3 = tc3 or Color3.new(0,0,0),
			Font = font or Enum.Font.SourceSans,
			Text = text,
			LayoutOrder = lo
		}
	end,
	BuildButtonPrompt = function(self)
		return Create"Frame"{
			Name = "ButtonPrompt",
			AnchorPoint = Vector2.new(0.5,0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5,0,0.35,0),
			Size = UDim2.new(0.4,0,0.6,0),
			ZIndex = 8,
			
			Create"UIListLayout"{
				Padding = UDim.new(0.05,0),
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder
			}
		}
	end,
	BuildSystemButtons = function(self)
		local c = self.Configuration
		local r = c.Resolution
		local m = c.DialogBoxMargin
		local p = c.DialogBoxPadding
		local sizeX = r.X - m.X * 2
		local sizeY = c.DefaultTextSize*c.DialogBoxTextLines+c.DialogBoxPadding.Y*2
		local sx = c.SystemButtonSize.X * 3 + c.SystemButtonPadding * 2
		local exitBtn = Create"TextButton"{
			Name = "Exit",
			BackgroundColor3 = Color3.new(0.25,0.25,0.25),
			BorderColor3 = Color3.new(0,0,0),
			BorderSizePixel = 2,
			LayoutOrder = 3,
			Size = UDim2.new(c.SystemButtonSize.X/sx,0,1,0),
			Font = Enum.Font.SourceSans,
			Text = "Exit",
			TextColor3 = Color3.new(1,1,1),
			TextScaled = true
		}
		return Create"Frame"{
			Name = "Buttons",
			AnchorPoint = Vector2.new(1,1),
			BackgroundTransparency = 1,
			Position = UDim2.new(1-(c.SystemButtonsMargin.X/sizeX),0,-(c.SystemButtonsMargin.Y/sizeY),0),
			Size = UDim2.new(sx/sizeX,0,c.SystemButtonSize.Y/sizeY,0),
			ZIndex = 10,
			
			Create"UIListLayout"{
				Padding = UDim.new(c.SystemButtonPadding/sx,0),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder
			},
			
			exitBtn,
			
			Create(exitBtn){
				Name = "Save",
				LayoutOrder = 2,
				Text = "Save"
			},
			
			Create(exitBtn){
				Name = "Load",
				LayoutOrder = 1,
				Text = "Load"
			}
		}
	end,
	BuildTextFrame = function(self)
		local c = self.Configuration
		local r = c.Resolution
		local m = c.DialogBoxMargin
		local p = c.DialogBoxPadding
		local sizeX = r.X - m.X * 2
		local sizeY = c.DefaultTextSize*c.DialogBoxTextLines+c.DialogBoxPadding.Y*2
		return Create"Frame"{
			Name = "Text",
			AnchorPoint = Vector2.new(0.5,0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5,0,0.5,0),
			Size = UDim2.new(1-(p.X/sizeX),0,1-(p.Y/sizeY),0),
		}
	end,
	BuildSpeakerName = function(self)
		local c = self.Configuration
		local r = c.Resolution
		local m = c.DialogBoxMargin
		local sizeX = r.X - m.X * 2
		local sizeY = c.DefaultTextSize*c.DialogBoxTextLines+c.DialogBoxPadding.Y*2
		return Create"TextLabel"{
			Name = "SpeakerName",
			AnchorPoint = Vector2.new(0,1),
			BackgroundTransparency = 1,
			Position = UDim2.new(c.SpeakerNameMargin.X/sizeX,0,-(c.SpeakerNameMargin.Y/sizeY),0),
			Size = UDim2.new(0.5,0,c.SpeakerNameTextSize/sizeY,0),
			Font = Enum.Font.SourceSansBold,
			Text = "PLACEHOLDER",
			TextColor3 = Color3.new(1,1,1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			ZIndex = 7
		}
	end,
	BuildDialogBox = function(self)
		local c = self.Configuration
		local r = c.Resolution
		local m = c.DialogBoxMargin
		local sizeY = c.DefaultTextSize*c.DialogBoxTextLines+c.DialogBoxPadding.Y*2
		return Create"Frame"{
			Name = "DialogBox",
			Active = true,
			AnchorPoint = Vector2.new(0.5,1),
			BackgroundTransparency = 0.35,
			Position = UDim2.new(0.5,0,1-(m.Y / r.Y),0),
			Size = UDim2.new(1-((m.X * 2) / r.X),0,sizeY/r.Y,0),
			ZIndex = 2,
			
			self:BuildSystemButtons(),
			self:BuildTextFrame(),
			self:BuildSpeakerName(),
		}
	end,
	BuildAll = function(self)
		local c = self.Configuration
		return Create"Frame"{
			Name = "Main",
			AnchorPoint = Vector2.new(0.5,0.5),
			BackgroundColor3 = Color3.new(0,0,0),
			BorderSizePixel = 0,
			Position = UDim2.new(0.5,0,0.5,0),
			Size = UDim2.new(1,0,1,0),
			ClipsDescendants = true,
			
			Create"UIAspectRatioConstraint"{
				AspectRatio = c.Resolution.X / c.Resolution.Y,
				AspectType = Enum.AspectType.FitWithinMaxSize,
				DominantAxis = Enum.DominantAxis.Width
			},
			
			Create"UISizeConstraint"{
				MaxSize = c.Resolution,
				MinSize = c.Resolution / 2
			},
			
			self:BuildButtonPrompt(),
			self:BuildDialogBox()
		}
	end
}
mt.__index = mt

local Default_Configuration = {
	Resolution = Vector2.new(1280,720),
	DialogBoxMargin = Vector2.new(15,15),
	DialogBoxPadding = Vector2.new(5,5),
	DefaultTextSize = 48,
	DialogBoxTextLines = 4,
	SpeakerNameTextSize = 48,
	SpeakerNameMargin = Vector2.new(5,5),
	SystemButtonSize = Vector2.new(75,20),
	SystemButtonPadding = 10,
	SystemButtonsMargin = Vector2.new(0,10)
}
Default_Configuration.__index = Default_Configuration

return function(conf)
	local Configuration = Default_Configuration
	if conf then
		Configuration = setmetatable({},Default_Configuration)
		for k,v in pairs(conf) do
			Configuration[k] = v
		end
	end
	return setmetatable({Configuration=Configuration},mt)
end
