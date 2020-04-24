local test_xml = [[
<?xml version="1.0" encoding="UTF-8"?>
<!--
Even though the current parser doesn't parse this XML specification,
the file still should have it.
-->
<game version="0.1">
	<!-- Game Data -->
	<title>Test game</title>
	<font
		size = "48"
		normal = "SourceSans"
		bold = "SourceSansBold"
		italic = "SourceSansItalic"
	/>
	<!-- End of Game Data -->

	<!-- Characters -->
	<character
		id = "dummy"
		name = "Dummy"
		color = "200,200,200"
	/>
	<character
		id = "plr"
		name = "{PLAYERNAME}"
		color = "255,255,255"
	/>
	<!-- End of characters -->

	<!-- Assets -->
	<asset id="background1">
		<model path="background1"/>
		<camera
			CFrame="-9.21824265, 4.86032915, 4.61861849, -0.907585382, -0.0116323158, -0.419706434, -0, 0.999616206, -0.0277047232, 0.419867605, -0.0251444019, -0.907237053"
			FieldOfView="35"
		/>
		<frame
			Ambient="204, 204, 204"
			LightColor="150, 150, 150"
			LightDirection = "-1,-1,-1"
			XScale = "1"
			YScale = "1"
			XOffset = "0"
			YOffset = "0"
		/>
	</asset>
	<asset id="dummy1">
		<model path="Dummy"/>
		<camera
			CFrame="-42, 3.5999999, 55.0999985, 0.999952495, 0.000418075128, 0.00974503346, 2.91038305e-11, 0.999081135, -0.042861931, -0.00975399744, 0.0428598933, 0.999033511"
			FieldOfView="10"
		/>
		<frame
			Ambient="200, 200, 200"
			LightColor="140, 140, 140"
			LightDirection = "-1,-1,-1"
			XScale = "0.5"
			YScale = "0.8"
			XOffset = "0"
			YOffset = "0.1"
		/>
	</asset>
	<!-- End of assets -->
	
	<dialog id="start">
		<text>No speakername at start</text>
		<text speaker="CustomName" color="255,150,150">Speaker named "CustomName" with red color which is not an existing character</text>
		<text>Continuation of previous speaker.</text>
		<text speaker="none">Empty speaker, text and background should be white.</text>
		<text><b>Bold text.</b> <i>Italic text.</i> <mark>Marked text.</mark> <b><mark><i>Bold, Marked and Italic text at once (unless BoldItalic font exists, should show Italic font).</b></mark></i></text>
		<scene>
			<obj id="background1" effect="fadein" z="0" time="2"/>
		</scene>
		<text>Scene change, should fade in background in 2 seconds.</text>
		<scene>
			<obj id="dummy1"/>
		</scene>
		<text>Scene change, a simple Part should immediately pop up in front of the background.</text>
		<text speaker="dummy">Speaker name should change to "Dummy", color changed to gray.</text>
		<text speaker="plr">Speaker name should change to LocalPlayer.Name, color changed to white.</text>
		<text speaker="none">Text waiting test: <wait t="20"/>20 ticks<br/>Waiting for user input: <wait/>input recieved.</text>
		<text>Button prompt test:</text>
		<prompt func="prompt">
			<button>Option 1</button>
			<button>Option 2</button>
			<button>Option 3</button>
		</prompt>
		<text>You have chosen {option}</text>
		<text>Dialog pick based on a variable:</text>
		<switch>
			<case option="Option 1" to="option1"/>
			<case option="Option 2" to="option2"/>
			<case option="Option 3" to="option3"/>
		</switch>
		<text>If you see this, then prompt or switch didn't execute correctly.</text>
	</dialog>
	<dialog id="option1" to="end">
		<text>This is first option dialog</text>
	</dialog>
	<dialog id="option2" to="end">
		<text>This is second option dialog</text>
	</dialog>
	<dialog id="option3" to="end">
		<text>This is third option dialog</text>
	</dialog>
	<dialog id="end">
		<text>This is the last dialog</text>
	</dialog>
</game>
]]

local plr = game:GetService("Players").LocalPlayer
local assets = Instance.new("Folder")

local m = Instance.new("Model",assets)
m.Name = "background1"

local p = Instance.new("Part",m)
p.Anchored = true
p.BrickColor = BrickColor.new("Dark stone grey")
p.Size = Vector3.new(244, 1, 241)
p.CFrame = CFrame.new(89, 0.5, 122.5)
p.BottomSurface = Enum.SurfaceType.Inlet
p.TopSurface = Enum.SurfaceType.Studs

m = Instance.new("Model",assets)
m.Name = "Dummy"
p = Instance.new("Part",m)
p.Anchored = true
p.BrickColor = BrickColor.new("Medium stone grey")
p.Size = Vector3.new(4, 1, 2)
p.CFrame = CFrame.new(-42,5.5,16,0.766044974,-0.454519629,-0.454518497,0,0.707105994,-0.707107663,0.64278698,0.541676283,0.541674972)
p.BottomSurface = Enum.SurfaceType.Inlet
p.TopSurface = Enum.SurfaceType.Studs

local GameEngineFolder = script:WaitForChild("src")
local Game = require(GameEngineFolder:WaitForChild("Engine.lua"))(test_xml)
local dom = require(GameEngineFolder:WaitForChild("DOM.lua"))
local Variables = {
	PLAYERNAME = plr.Name,
	option = "[NOT SELECTED]"
}
local Functions = {
	prompt = function(Game,prompt,button)
		Variables.option = dom.getText(button)
	end
}
Game:SetAssetFolder(assets)
Game:SetVariables(Variables)
Game:SetFunctions(Functions)
Game:SetGui()
local sg = Instance.new("ScreenGui",plr.PlayerGui)
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Game.Frame.Parent = sg
Game:SetTick(game:GetService("RunService").RenderStepped)
Game:GameLoop('start')
print("Game finished.")
