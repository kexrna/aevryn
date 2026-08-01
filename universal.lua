--[[ hi this has been made by kexrna]]















































local RS = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local GuiService = cloneref(game:GetService("GuiService"))
local Lighting = cloneref(game:GetService("Lighting"))
local Uis = cloneref(game:GetService("UserInputService"))
local ProxPromptService = cloneref(game:GetService("ProximityPromptService"))

--
local hex = Color3.fromHex
local Client = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = Client:GetMouse()
local CMouse = cloneref(Client:GetMouse())
--
local Combat, Target, Sleep, ClientTool
local Script = {Functions = {}, Friends = {}, Connections = {}, Cache = {}, BeizerManager = {}, BeizerCurve = {}, Desync = {}}
local library, themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/kexrna/aevryn/refs/heads/main/ui.lua"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/kexrna/aevryn/refs/heads/main/ESP%20lib.lua"))()

local prison_life, hood_custom = game.PlaceId == 155615604, (game.PlaceId == 9825515356 or game.PlaceId == 138995385694035)
local flags = library.flags
ESP.flags = flags
local function CreateFov()
    local internal = {
        Visible = false,
        Radius = 100,
        Position = Vector2.new(500, 500),
        Color = Color3.new(1, 1, 1),
        Transparency = 0,
        Fill = true,
        OutlineColor = Color3.new(1, 1, 1),
        OutlineTransparency = 0,
        OutlineThickness = 1,
        Gradient = false,
        GradientColor1 = Color3.new(1, 0, 0),
        GradientColor2 = Color3.new(0, 1, 0),
        Rotation = 0,
    }

    local FovUI = Instance.new("ScreenGui")
    FovUI.Name = "FOVCircle"
    FovUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
    FovUI.ResetOnSpawn = false
    FovUI.IgnoreGuiInset = true
    FovUI.Parent = game:GetService("CoreGui")

    local Circle = Instance.new("Frame")
    Circle.BackgroundTransparency = 1
    Circle.BorderSizePixel = 0
    Circle.AnchorPoint = Vector2.new(0.5, 0.5)
    Circle.Position = UDim2.fromOffset(0, 0)
    Circle.Size = UDim2.fromOffset(0, 0)
    Circle.Visible = false
    Circle.Parent = FovUI

    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

    local Stroke = Instance.new("UIStroke", Circle)
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Gradient = Instance.new("UIGradient", Circle)
    Gradient.Enabled = false

    local function update()
        Circle.Visible = internal.Visible
        Circle.Position = UDim2.fromOffset(internal.Position.X, internal.Position.Y)
        Circle.Size = UDim2.fromOffset(internal.Radius * 2, internal.Radius * 2)
        Circle.BackgroundTransparency = internal.Fill and internal.Transparency or 1
        Circle.BackgroundColor3 = internal.Color

        Stroke.Color = internal.OutlineColor
        Stroke.Transparency = internal.OutlineTransparency
        Stroke.Thickness = internal.OutlineThickness
        Gradient.Rotation = internal.Rotation

        if internal.Gradient then
            Gradient.Enabled = true
            Gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, internal.GradientColor1),
                ColorSequenceKeypoint.new(0.50, internal.GradientColor2),
                ColorSequenceKeypoint.new(1.00, internal.Color),
            })
        else
            Gradient.Enabled = false
        end
    end

    local fovCircle = {}
    setmetatable(fovCircle, {
        __index = function(_, k)
            return internal[k]
        end,
        __newindex = function(_, k, v)
            internal[k] = v
            update()
        end
    })

    update()
    return fovCircle
end

local SilentFovCircle = CreateFov()
local AimAssistFovCircle = CreateFov()
local TracerLine = Drawing.new("Line")
TracerLine.Thickness = 1

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

--
Script.BeizerManager.__index = Script.BeizerManager

Script.BeizerManager.New = function()
    local self = setmetatable({}, Script.BeizerManager)
    
    self.T = 0
    self.T_Threshold = 0.99995
    self.StartPoint = Vector2.new()
    self.EndPoint = Vector2.new()
    self.CurvePoints = {Vector2.new(0,0), Vector2.new(0,0)}
    self.Active = false
    self.Smoothness = 0.0025
    self.Function = function(self, X, Y)
        mousemoverel(X, Y)
    end
    self.Started = false

    return self
end

Script.BeizerManager.ChangeData = function(self, Data)
    self.StartPoint = (self.GetStartPoint() or Data.StartPoint)
    self.EndPoint = Data.TargetPosition
    self.Smoothness = Data.Smoothness or self.Smoothness
    self.CurvePoints = Data.CurvePoints or self.CurvePoints
    self.Method = Data.Method or "Cubic"

    self.T = 0
    self.Active = true
end

Script.BeizerManager.CubicCurve = function(T, StartPoint, EndPoint, ControlPointA, ControlPointB)
    local T1 = (1 - T)

    local A = T1^3 * StartPoint
    local B = 3 * T1^2 * T * ControlPointA
    local C = 3 * T1 * T^2 * ControlPointB
    local D = T^3 * EndPoint
    
    return A + B + C + D
end

Script.BeizerManager.DoControlPoint = function(StartPoint, EndPoint, ControlPointA, ControlPointB)
    local Change = (EndPoint - StartPoint)

    local A = StartPoint + (Change * ControlPointA)
    local B = StartPoint + (Change * ControlPointB)
    return A, B
end

Script.BeizerManager.DoIteration = function(self)
    if (self.Active == false) then
        return
    end
    local T = self.T
    while (T <= 1 and self.Active) do RS.RenderStepped:Wait()
        local CurvePosition
        if self.Method == "Linear" then
            CurvePosition = self.StartPoint:Lerp(self.EndPoint, T)
        else
            local ControlPointA, ControlPointB = self.DoControlPoint(self.StartPoint, self.EndPoint, self.CurvePoints[1], self.CurvePoints[2])
            CurvePosition = self.CubicCurve(T, self.StartPoint, self.EndPoint, ControlPointA, ControlPointB)
        end

        local CurrentPosition = self.GetStartPoint()
        local Delta = CurvePosition - CurrentPosition
        self.Function(self, Delta.X, Delta.Y)
        T = T + self.Smoothness
        self.T = T
    end
    self.Active = false
end

Script.BeizerManager.Start = function(self)
    self.Started = true
    local Thread = coroutine.resume(coroutine.create(function()
        while self.Started do
            self:DoIteration()
            RS.RenderStepped:Wait()
        end
    end))
    return Thread
end

Script.BeizerManager.Stop = function(self)
    self.Started = false
end

Script.BeizerManager.StopCurrent = function(self)
    self.Active = false
    self.T = 0
end

Script.BeizerManager.GetStartPoint = function()
    return Uis:GetMouseLocation()
end

Script.BeizerManager.MouseMode = function(self)
    self.GetStartPoint = Script.BeizerManager.GetStartPoint
    self.Function = function(self, X, Y)
        mousemoverel(X, Y)
    end
    self.DrawPathFunc = Script.BeizerManager.DrawPathFunc
end

local Manager = Script.BeizerManager.New()
Manager:MouseMode()
Manager:Start()

do
    local response = request({
        Url = ("https://friends.roblox.com/v1/users/%d/friends"):format(Client.UserId),
        Method = "GET"
    })

    if response.Success then
        local data = game:GetService("HttpService"):JSONDecode(response.Body)
        for _, friend in ipairs(data.data) do
            pcall(function (...)
                Script.Friends[Players:GetNameFromUserIdAsync(friend.id)] = true
            end)
        end
    end
end

local function isFriend(username)
    return Script.Friends[username] == true or (library.playerlist_data[username] and string.lower(library.playerlist_data[username].priority) == "friendly") or false
end

function GetFocusedTextBox()
    return Uis:GetFocusedTextBox()
end

local function safeUnit(unit)
    if unit.Magnitude > 1e-8 then
        return unit
    end
    return Vector3.zero
end
--
do
	local window = library:window({name = os.date('aevryn |  - %b %d %Y'), size = UDim2.new(0, 750, 0, 782)})

	Combat = window:tab({name = "Combat"})
	local Misc = window:tab({name = "Misc"})
	local Visuals = window:tab({name = "Visuals"})

		-- Misc
		do
			local column1 = Misc:column()
			local column2 = Misc:column()

			local Mouvements = column1:section({name = "Mouvements", toggle = false})
			Mouvements:toggle({name = "CFrame Speed", flag = "Cframe_Speed"}):keybind({name = "CFrame Speed Bind", flag = "Cframe_Speed_Bind"})
			Mouvements:slider({name = "Speed", min = 1, max = 100, default = 30, interval = 1, suffix = "%", flag = "Cframe_Speed_Value"})
			Mouvements:toggle({name = "Fly", flag = "Fly"}):keybind({name = "Fly Bind", flag = "Fly_Bind"})
			Mouvements:slider({name = "Speed", min = 1, max = 100, default = 30, interval = 1, suffix = "%", flag = "Fly_Speed_Value"})
            local others = column2:section({name = "Others", toggle = false})
            others:toggle({name = "Instant interact", flag = "instant_interact"})
            others:toggle({name = "No Slowdown", flag = "NoSlowdown"})
            others:toggle({name = "No Jump Cooldown", flag = "NoJumpCooldown"})
            local macro = column1:section({name = "Macro", toggle = false})

            if hood_custom then
                local Controller = require(Client:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetCameras().activeCameraController
                macro:toggle({name = "Enabled", flag = "macro_enabled"}):keybind({name = "Macro Bind", flag = "macro_bind", callback = function ()
                    library:fold_elements("macro_enabled", {"macro_method", "macro_delay"})
                    local Controller = require(Client:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetCameras().activeCameraController
                    repeat RS.Heartbeat:Wait() -- big up to memelouse for ts that i pasted
                        if flags["macro_method"] == "FirstPerson" then
                            Controller:SetCameraToSubjectDistance(Controller.currentSubjectDistance - 1)
                            for i = 1, math.ceil(flags["macro_delay"]) do
                                RS.Heartbeat:Wait()
                            end
                            Controller:SetCameraToSubjectDistance(Controller.currentSubjectDistance + 1)
                        elseif flags["macro_method"] == "ThirdPerson" then
                            keypress(0x49)
                            for i = 1, math.ceil(flags["macro_delay"]) do
                                RS.Heartbeat:Wait()
                            end
                            keypress(0x4F)
                            for i = 1, math.ceil(flags["macro_delay"]) do
                                RS.Heartbeat:Wait()
                            end
                            keyrelease(0x49)
                            for i = 1, math.ceil(flags["macro_delay"]) do
                                RS.Heartbeat:Wait()
                            end
                            keyrelease(0x4F)
                        end
                    until not (flags["macro_enabled"] and flags["macro_bind"]["active"]) 
                end})
                macro:dropdown({name = "Method", flag = "macro_method", items = {"ThirdPerson", "FirstPerson"}, default = "FirstPerson"})
                macro:slider({name = "Macro delay", min = 0, max = 10, default = 1, interval = 1, suffix = "ms", flag = "macro_delay"})
        end
            macro:toggle({name = "Rotation (360)", flag = "macro_rotation"}):keybind({name = "Macro Rotation Bind", flag = "macro_rotation_bind", callback = function ()
                if not flags["macro_rotation"] then return end

                for i = 1, math.floor(flags['macro_rotation_degree'] / flags['macro_rotation_speed']) do
                    Camera.CoordinateFrame = Camera.CoordinateFrame * CFrame.Angles(0, math.rad(flags['macro_rotation_speed']), 0)
                    RS.Heartbeat:Wait()
                end
            end})
            macro:slider({name = "Rotation Speed", min = 1, max = 100, default = 30, interval = 1, suffix = "%", flag = "macro_rotation_speed"})
            macro:slider({name = "Rotation Degree", min = 1, max = 360, default = 360, interval = 1, suffix = "°", flag = "macro_rotation_degree"})
    
		end
		-- Combat
		do
			local column1 = Combat:column()
			local column2 = Combat:column()
				local selec, lock, assist, trigger = column1:multi_section({names = {"Selection", "Silent", "Aim Assist", "Triggerbot"}})
					selec:toggle({name = "Enabled", flag = "target_selected", tooltip = "Manages selection of the target (both lock and aim assist)"})
					:keybind({name = "Aiming", flag = "target_selected_bind", callback = function ()
						if Target then 
							Target = nil
						else
							Target = Script.Functions.GetTarget({
								FriendCheck = flags["friend_check"],
								TeamCheck = flags["team_check"],
								WallCheck = flags["wall_check"],
								DeadCheck = flags["dead_check"],
								VisibleCheck = flags["visible_check"],
								Radius = flags["fov_radius"],
								Origin = flags["distance_priority"],
                                DistanceCheck = flags["distance_check"],
							})
						end
					end})
					selec:toggle({name = "Auto Select", flag = "auto_select", tooltip = "Selects targets for you. (Edit the delay slider if you want more fps.)"})
                    selec:label({name = "Force lock"}):keybind({name = "Force lock", flag = "force_lock", tooltip = "Will ignore all checks except for fov",callback = function ()
                        if Target then 
							Target = nil
						else
							Target = Script.Functions.GetTarget({}) -- still need to add checks so auto select don't put it back to nil
						end
                    end})
					selec:toggle({name = "Only Select Enemies", flag = "enemy_priority", tooltip = "Only targets users under the priority enemy (through the playerlist)"})
					selec:dropdown({name = "Origin", flag = "distance_priority", items = {"Mouse", "Distance"}, default = "Mouse", tooltip = "Selects targets based on the origin"})
					selec:slider({name = "Delay", min = 0, max = 1000, default = 40, interval = 1, suffix = "ms", flag = "target_selector_refresh_time", tooltip = "Used for optimizing the checks and target selection. Use for lower end pcs."})
					selec:toggle({name = "Wall Check", flag = "wall_check"})
					selec:toggle({name = "Dead Check", flag = "dead_check"})
                    if hood_custom then
                        selec:toggle({name = "knocked Check", flag = "knocked_check"})
                    end
                    selec:toggle({name = "Local Dead Check", flag = "local_dead_check"})
					selec:toggle({name = "ForceField Check", flag = "forcefield_check"})
					selec:toggle({name = "Distance Check", flag = "distance_check", tooltip = "Checks if they are in the distance of the guns range", callback = function()
                        library:fold_elements("distance_check", {"max_distance"})
                    end})
					selec:slider({name = "Max Distance", min = 1, max = 1000, default = 300, interval = 1, suffix = "studs", flag = "max_distance"})
                    selec:toggle({name = "Friend Check", flag = "friend_check"})
					selec:toggle({name = "Team Check", flag = "team_check"})
                    selec:toggle({name = "Tool Check", flag = "tool_check"})
					selec:toggle({name = "Visible Check", flag = "visible_check"})
					--
					lock:toggle({name = "Enabled", flag = "silent_aim"})
					lock:toggle({name = "Auto Shoot", flag = "auto_shoot"})
                    lock:slider({name = "Shot Delay", min = 0, max = 1000, default = 40, interval = 1, suffix = "ms", flag = "auto_shoot_delay"})
					lock:dropdown({name = "Aim Bone", flag = "silent_aim_bone", items = {"HumanoidRootPart", "Head"}, default = "Head"})
					lock:dropdown({name = "Method", flag = "silent_aim_method", items = {"Mouse Hook", "ACS","Raycast Hook", "HitPart", "CastRay", "FindPartOnRay", "FindPartOnRayWithWhitelist", "FindPartOnRayWithIgnoreList",}, default = "Mouse Hook"})
					lock:toggle({name = "Prediction", flag = "silent_aim_prediction", callback = function()
						library:fold_elements("silent_aim_prediction", {"silent_aim_prediction_amount"})
					end})
					lock:slider({name = "Prediction Amount", min = 0, max = 1, default = 1, interval = 0.001, flag = "silent_aim_prediction_amount"})
					lock:toggle({name = "Hit Chance", flag = "silent_aim_hit_chance_enabled", callback = function()
						library:fold_elements("silent_aim_hit_chance_enabled", {"silent_aim_hit_chance"})
					end})
					lock:slider({name = "Hit Chance %", min = 0, max = 100, default = 100, interval = 1, flag = "silent_aim_hit_chance"})
                    lock:toggle({name = "Nearest Part", flag = "silent_aim_nearest_part", callback = function (state)
                        library:fold_elements("silent_aim_nearest_part", {"silent_aim_random_part", "silent_aim_multi_point", "silent_aim_multi_point_scale", "silent_aim_whitelist_part"})
                    end})
                    lock:dropdown({name = "Whitelisted Parts", flag = "silent_aim_whitelist_part", multi = true, items = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}, default = "Head"})
                    lock:toggle({name = "Random Part", flag = "silent_aim_random_part"})
                    lock:toggle({name = "Multi Point", flag = "silent_aim_multi_point"})
                    lock:slider({name = "Multi Point Scale", min = 0, max = 100, default = 100, interval = 1, flag = "multi_point_scale"})
                    
				local vis_other = column2:section({name = "Visuals & Other"})
					assist:toggle({name = "Enabled", flag = "aim_assist"})
					assist:dropdown({name = "Aim Part", flag = "aim_assist_bone", items = {"HumanoidRootPart", "Head"}, default = "Head"})
					assist:dropdown({name = "Curve Method", flag = "aim_assist_curve_method", items = {"Linear", "Cubic"}, default = "Cubic"})
                    assist:toggle({name = "Smooth Movement", flag = "aim_assist_smooth", default = true, callback = function()
                        library:fold_elements("aim_assist_smooth", {"aim_assist_smooth_x", "aim_assist_smooth_y"})
					end})
					assist:slider({name = "Smoothness X", min = 1, max = 100, default = 6, interval = 1, flag = "aim_assist_smooth_x"})
					assist:slider({name = "Smoothness Y", min = 1, max = 100, default = 6, interval = 1, flag = "aim_assist_smooth_y"})
                    
                    assist:toggle({name = "Prediction", flag = "aim_assist_prediction", callback = function()
						library:fold_elements("aim_assist_prediction", {"aim_pred_x", "aim_pred_y"})
					end})
					assist:slider({name = "Prediction X",  min = 0, max = 1, default = 1, interval = 0.001,  flag = "aim_pred_x"})
                    assist:slider({name = "Prediction Y", min = 0, max = 1, default = 1, interval = 0.001, flag = "aim_pred_y"})
					assist:toggle({name = "Shake", flag = "aim_assist_shake", callback = function()
						library:fold_elements("aim_assist_shake", {"aim_assist_shake_x", "aim_assist_shake_y", "aim_assist_shake_z"})
					end})

					assist:slider({name = "Shake X", min = 0, max = 10, default = 0, interval = 0.1, flag = "aim_assist_shake_x"})
					assist:slider({name = "Shake Y", min = 0, max = 10, default = 0, interval = 0.1, flag = "aim_assist_shake_y"})
					assist:slider({name = "Shake Z", min = 0, max = 10, default = 0, interval = 0.1, flag = "aim_assist_shake_z"})
					
                    assist:toggle({name = "Nearest Part", flag = "aim_assist_nearest_part", callback = function (state)
                        library:fold_elements("aim_assist_nearest_part", {"aim_assist_random_part", "aim_assist_multi_point", "aim_assist_multi_point_scale", "aim_assist_whitelist_part"})
                    end})
                    assist:dropdown({name = "Whitelisted Parts", flag = "aim_assist_whitelist_part", multi = true, items = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}, default = "Head"})
                    assist:toggle({name = "Random Part", flag = "aim_assist_random_part"})
                    assist:toggle({name = "Multi Point", flag = "aim_assist_multi_point"})
                    assist:slider({name = "Multi Point Scale", min = 0, max = 100, default = 100, interval = 1, flag = "multi_point_scale"})
                    
					trigger:toggle({name = "Enabled", flag = "aim_assist_triggerbot"})
					trigger:slider({name = "Distance", min = 1, max = 100, default = 20, interval = 1, flag = "aim_assist_triggerbot_distance"})
					trigger:slider({name = "Delay between shots", min = 1, max = 1000, default = 20, interval = 1, flag = "aim_assist_triggerbot_delay_between_shots"})

					vis_other:toggle({name = "Look At", flag = "look_at"})
					vis_other:toggle({name = "Spectate", flag = "spectate"})
					vis_other:toggle({name = "Tracer", flag = "snap_line"})
					:colorpicker({name = "Tracer Inline", flag = "snap_line_color", color = hex("#7D0DC3")})
					:colorpicker({flag = "Tracer Outline", color = hex("#000000")})
					vis_other:slider({name = "Thickness", min = 1, max = 5, default = 1, interval = 1, suffix = "°", flag = "target_snap_line_thickness"})
					vis_other:toggle({name = "Highlight", flag = "target_highlight"})
					:colorpicker({name = "Outline", flag = "target_highlight_settings", color = hex("#000000")})
					:colorpicker({name = "Fill", flag = "target_highlight_settings", color = hex("#000000")})  

					-- Silent Aim FOV
					vis_other:label({name = "Silent Aim FOV"})
					vis_other:toggle({name = "Visible", flag = "silent_fov", callback = function (state)
                        SilentFovCircle.Visible = state
                    end})   
                    vis_other:toggle({name = "Sticky FOV", flag = "silent_sticky_fov"})
					:colorpicker({name = "1st Color (Gradient)", flag = "silent_fov_1_settings", color = hex("#7D0DC3"), alpha = 0.5, callback = function(Color, alpha)
                        SilentFovCircle.Color = Color
                        SilentFovCircle.Transparency = 1 - alpha
                    end}) 
					:colorpicker({name = "2nd Color (Gradient)", flag = "silent_fov_2_settings", color = hex("#7D0DC3"), alpha = 0.5, callback = function(Color, alpha)
                        SilentFovCircle.GradientColor1 = Color
                    end}) 
					:colorpicker({name = "3rd Color (Gradient)", flag = "silent_fov_3_settings", color = hex("#7D0DC3"), alpha = 0.5, callback = function(Color, alpha)
                        SilentFovCircle.GradientColor2 = Color
                    end})
					vis_other:toggle({name = "Outline", flag = "silent_outline_fov"})  
					:colorpicker({name = "1st Color (Gradient)", flag = "silent_outline_fov_settings_1", color = hex("#000000"), alpha = 1, callback = function(Color, alpha)
                        SilentFovCircle.OutlineColor = Color
                        SilentFovCircle.OutlineTransparency = 1 - alpha
                    end}) 
					:colorpicker({name = "2nd Color (Gradient)", flag = "silent_outline_fov_settings_2", color = hex("#000000"), alpha = 1, callback = function(Color, alpha)
                        SilentFovCircle.Gradient = Color
                    end}) 
					vis_other:slider({name = "Radius", min = 0, max = 1000, default = 100, interval = 1, flag = "silent_fov_radius", callback = function (v)
                        SilentFovCircle.Radius = v
                    end})
					vis_other:slider({name = "Thickness", min = 0, max = 5, default = 1, interval = 1, flag = "silent_outline_thickness_fov", callback = function (v)
                        SilentFovCircle.OutlineThickness = v
                    end})
					vis_other:slider({name = "Custom Rotation", min = -180, max = 180, default = 0, interval = 1, flag = "silent_custom_rotation_fov", callback = function (v)
                        SilentFovCircle.Rotation = v
                    end})
					vis_other:toggle({name = "Spin", flag = "silent_spin_fov"})
					vis_other:slider({name = "Rotation Speed", min = 0, max = 100, default = 100, interval = 1, flag = "silent_spin_speed_fov"})

					-- Aim Assist FOV
					vis_other:label({name = "Aim Assist FOV"})
					vis_other:toggle({name = "Visible", flag = "assist_fov", callback = function (state)
                        AimAssistFovCircle.Visible = state
                    end})   
                    vis_other:toggle({name = "Sticky FOV", flag = "assist_sticky_fov"})
					:colorpicker({name = "1st Color (Gradient)##assist", flag = "assist_fov_1_settings", color = hex("#00FF00"), alpha = 0.5, callback = function(Color, alpha)
                        AimAssistFovCircle.Color = Color
                        AimAssistFovCircle.Transparency = 1 - alpha
                    end}) 
					:colorpicker({name = "2nd Color (Gradient)##assist", flag = "assist_fov_2_settings", color = hex("#00FF00"), alpha = 0.5, callback = function(Color, alpha)
                        AimAssistFovCircle.GradientColor1 = Color
                    end}) 
					:colorpicker({name = "3rd Color (Gradient)##assist", flag = "assist_fov_3_settings", color = hex("#00FF00"), alpha = 0.5, callback = function(Color, alpha)
                        AimAssistFovCircle.GradientColor2 = Color
                    end})
					vis_other:toggle({name = "Outline", flag = "assist_outline_fov"})  
					:colorpicker({name = "1st Color (Gradient)##assist_outline", flag = "assist_outline_fov_settings_1", color = hex("#000000"), alpha = 1, callback = function(Color, alpha)
                        AimAssistFovCircle.OutlineColor = Color
                        AimAssistFovCircle.OutlineTransparency = 1 - alpha
                    end}) 
					:colorpicker({name = "2nd Color (Gradient)##assist_outline", flag = "assist_outline_fov_settings_2", color = hex("#000000"), alpha = 1, callback = function(Color, alpha)
                        AimAssistFovCircle.Gradient = Color
                    end}) 
					vis_other:slider({name = "Radius", min = 0, max = 1000, default = 100, interval = 1, flag = "assist_fov_radius", callback = function (v)
                        AimAssistFovCircle.Radius = v
                    end})
					vis_other:slider({name = "Thickness", min = 0, max = 5, default = 1, interval = 1, flag = "assist_outline_thickness_fov", callback = function (v)
                        AimAssistFovCircle.OutlineThickness = v
                    end})
					vis_other:slider({name = "Custom Rotation", min = -180, max = 180, default = 0, interval = 1, flag = "assist_custom_rotation_fov", callback = function (v)
                        AimAssistFovCircle.Rotation = v
                    end})
					vis_other:toggle({name = "Spin", flag = "assist_spin_fov"})
					vis_other:slider({name = "Rotation Speed", min = 0, max = 100, default = 100, interval = 1, flag = "assist_spin_speed_fov"})
                local antiaim = column1:section({name = "Anti Aim", toggle = false})
                    local function restore()
                        RS.RenderStepped:Wait() RS.RenderStepped:Wait() RS.RenderStepped:Wait() RS.RenderStepped:Wait() setfflag("S2PhysicsSenderRate", 15) setfflag("PhysicsSenderMaxBandwidthBps", 38760)
                    end
                antiaim:toggle({name = "Velocity", flag = "anti_aim_velocity" }):keybind({name = "Velocity Bind", flag = "anti_aim_velocity_bind", callback = restore})
                antiaim:toggle({name = "Freeze pos", flag = "anti_aim_freeze_pos"}):keybind({name = "freeze_pos Bind", flag = "anti_aim_freeze_pos_bind", callback = restore})
                antiaim:toggle({name = "Lag Step", flag = "anti_aim_lagstep"}):keybind({name = "Lag Step Bind", flag = "anti_aim_lagstep_bind", callback = restore})
                antiaim:toggle({name = "Random", flag = "anti_aim_random"}):keybind({name = "Random Bind", flag = "anti_aim_random_bind", callback = restore})   
                antiaim:toggle({name = "Network", flag = "anti_aim_network"}):keybind({name = "Network Bind", flag = "anti_aim_network_bind", callback = restore})

                antiaim:toggle({name = "Spinbot", flag = "anti_aim_spinbot"})
                antiaim:slider({name = "Spin Speed", min = 1, max = 100, default = 50, interval = 1, flag = "anti_aim_spin_speed"})

            local esp;

			local function update_elements() if esp and esp.refresh_elements then esp.refresh_elements() end; if ESP and ESP.refresh_elements then ESP.refresh_elements() end end 
			local column = Visuals:column()
			local section = column:section({name = "General", toggle = false})
			section:toggle({name = "Enabled", flag = "ESP_Enabled", callback = update_elements})
			section:toggle({name = "Names", flag = "Names", callback = function() end}):colorpicker({flag = "Name_Color", callback = update_elements})
			local settings = section:toggle({name = "Boxes", flag = "Boxes", callback = update_elements})
			section:dropdown({name = "Box Type", flag = "Box_Type", items = {"Corner", "Full"}, default = "Corner", callback = update_elements})
			settings:colorpicker({name = "Box Color", flag = "Box_Color", callback = update_elements})
			local Skeleton = section:toggle({name = "Skeleton", flag = "Skeletons", callback = update_elements})
			Skeleton:colorpicker({name = "Skeletons Color", flag = "Skeletons_Color", callback = update_elements})
			local toggle = section:toggle({name = "Healthbar", flag = "Healthbar", callback = update_elements})
			toggle:colorpicker({name = "High HP Color", flag = "Health_High", callback = update_elements})
			toggle:colorpicker({name = "Low HP Color", flag = "Health_Low", callback = update_elements})
			section:toggle({name = "Distance", flag = "Distance", callback = update_elements})
			:colorpicker({name = "Distance Color", flag = "Distance_Color", callback = update_elements})
			section:toggle({name = "Weapon", flag = "Weapon", callback = update_elements})
			:colorpicker({name = "Weapon Color", flag = "Weapon_Color", callback = update_elements})
			esp = window.esp_section:esp_preview({})

            local column2 = Visuals:column()
            local section2 = column2:section({name = "World", toggle = false})
            section2:toggle({name = "Ambient Color", default = false, flag = "Ambient Color"}):colorpicker({flag =  "Ambient_Color", callback = function()
                task.spawn(function ()
                    pcall(function ()
                        while Wait() do 
                            if flags["Ambient Color"] then
                                Lighting.ColorCorrection.TintColor = flags["Ambient_Color"].Color
                            else
                                Lighting.ColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
                            end
                        end
                    end)
                end)
            end})
		end
end 


Script.Functions.GetTeams = function()
    local count = 0
    for _, team in pairs(game:GetService("Teams"):GetChildren()) do
        count = count + 1
    end
    return count
end

Script.Functions.GetMagnitudeFromMouse = function(Origin)
    local PartPos, OnScreen = Camera:WorldToScreenPoint(Origin)
    if OnScreen then
        local Magnitude = (Vector2.new(PartPos.X, PartPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
        return Magnitude
    end
    return math.huge
end

Script.Functions.OnScreen = function(Object)
    local _, OnScreen = Camera:WorldToScreenPoint(Object.Position)
    return OnScreen
end

Script.Functions.WallCheck = function(Pos, PartDescendant)
    local Character = Client.Character
    local Origin = Camera.CFrame.Position

    local RayCastParams = RaycastParams.new()
    RayCastParams.FilterType = Enum.RaycastFilterType.Blacklist
    RayCastParams.FilterDescendantsInstances = {Character, Camera}

    local Result = Workspace.Raycast(Workspace, Origin, Pos - Origin, RayCastParams)
    
    if (Result) then    
        local PartHit = Result.Instance
        local Visible = (not PartHit or Instance.new("Part").IsDescendantOf(PartHit, PartDescendant))
        
        return Visible
    end
    return false
end

Script.Functions.GetClosest = function(Char)
    local selection = nil
    local closestDistance = math.huge
    local mouse_pos = Vector2.new(CMouse.X, CMouse.Y)
    local whitelist_part = {}
    local parts = {}
    if flags["silent_aim_nearest_part"] then
        if type(flags["silent_aim_whitelist_part"]) == "string" then
            table.insert(whitelist_part, flags["silent_aim_whitelist_part"])
        else
            for _, part in ipairs(flags["silent_aim_whitelist_part"]) do
                table.insert(whitelist_part, part)
            end
        end
    end
    if flags["aim_assist_nearest_part"] then
        if type(flags["aim_assist_whitelist_part"]) == "string" then
            table.insert(whitelist_part, flags["aim_assist_whitelist_part"])
        else
            for _, part in ipairs(flags["aim_assist_whitelist_part"]) do
                table.insert(whitelist_part, part)
            end
        end
    end
    for _, part in ipairs(Char:GetChildren()) do
        if part:IsA("BasePart") then
            local name = part.Name

            if table.find(whitelist_part, "Torso") and
                (name == "Torso" or name == "UpperTorso" or name == "LowerTorso" or name == "HumanoidRootPart") then
                table.insert(parts, part)
                continue
            end

            if table.find(whitelist_part, "Head") and name == "Head" then
                table.insert(parts, part)
                continue
            end

            if table.find(whitelist_part, "LeftArm") and
                (name == "Left Arm" or name == "LeftUpperArm" or name == "LeftLowerArm" or name == "LeftHand") then
                table.insert(parts, part)
                continue
            end

            if table.find(whitelist_part, "RightArm") and
                (name == "Right Arm" or name == "RightUpperArm" or name == "RightLowerArm" or name == "RightHand") then
                table.insert(parts, part)
                continue
            end

            if table.find(whitelist_part, "LeftLeg") and
                (name == "Left Leg" or name == "LeftUpperLeg" or name == "LeftLowerLeg" or name == "LeftFoot") then
                table.insert(parts, part)
                continue
            end

            if table.find(whitelist_part, "RightLeg") and
                (name == "Right Leg" or name == "RightUpperLeg" or name == "RightLowerLeg" or name == "RightFoot") then
                table.insert(parts, part)
                continue
            end
        end
    end

    if flags["random_part"] then
        if #parts > 0 then
            selection = parts[math.random(1, #parts)]
        end
    else
        for _, part in ipairs(parts) do
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

            if onScreen then
                local screen_pos = Vector2.new(screenPos.X, screenPos.Y)
                local distance = (screen_pos - mouse_pos).Magnitude

                if distance < closestDistance then
                    closestDistance = distance
                    selection = part
                    Script.Cache.ScreenPos = screen_pos
                end
            end
        end
    end

    if selection then
        local pos = selection.Position

        if flags["multi_point"] then
            local screen_pos = Script.Cache.ScreenPos

            if not screen_pos then
                local screenPos, onScreen = Camera:WorldToViewportPoint(selection.Position)

                if not onScreen then
                    return pos
                end

                screen_pos = Vector2.new(screenPos.X, screenPos.Y)
            end

            local offset = screen_pos - mouse_pos
            local sx, sy = selection.Size.X / 2, selection.Size.Y / 2

            pos = selection.CFrame * Vector3.new(
                math.clamp(offset.X / 100, -sx, sx),
                math.clamp(offset.Y / 100, -sy, sy),
                0
            )
        end

        return pos
    end
end

Script.Functions.GetTarget = function(Settings)
	local Char = Client.Character
    if not Char then return nil end
    
    local Hrp = Char:FindFirstChild("HumanoidRootPart")
    if not Hrp then return nil end
    
    local LocalTeam = Client.Team
    local FriendCheck = Settings.FriendCheck
    local TeamCheck = Settings.TeamCheck
    local WallCheck = Settings.WallCheck
    local DeadCheck = Settings.DeadCheck
    local VisibleCheck = Settings.VisibleCheck
    local DistanceCheck = Settings.DistanceCheck
    local Teams = Script.Functions.GetTeams()
    local Origin = Settings.Origin
    local ClosestTarget = nil
    local hitpos = nil
    local ValidTargets = {}
	local Targets = {} do
		if flags["enemy_priority"] then
			for _, player in pairs(library.playerlist_data) do
				if player.priority == "Enemy" then
					table.insert(Targets, Players[tostring(player)])
				end
			end
		else
			Targets = Players:GetPlayers()
		end
	end  
    for _, v in pairs(Targets) do
        if v == Client then continue end
        
        local char = v.Character
        if not char then continue end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not (hrp and head) then continue end
        if VisibleCheck and head.Transparency >= 0.4 then continue end
        if FriendCheck and isFriend(v.Name) then continue end

        if TeamCheck and Teams > 1 and not (library.playerlist_data[v.Name] and library.playerlist_data[v.Name].priority == "Enemy") then
            if prison_life and (LocalTeam.Name:find("Criminals") or LocalTeam.Name:find("Inmates")) and (v.Team.Name:find("Criminals") or v.Team.Name:find("Inmates")) or v.Team == LocalTeam then continue end 
            if v.Team == LocalTeam then continue end
        end

        if not Script.Functions.OnScreen(hrp) then continue end
        if flags['knocked_check'] then 
            if hood_custom and char:FindFirstChild("BodyEffects") and char.BodyEffects["K.O"].Value then continue end
        end
        
        if DistanceCheck and (hrp.Position - Hrp.Position).Magnitude > flags["max_distance"] then continue end
        local distance, origin
        if (flags["silent_aim"] and flags["silent_aim_nearest_part"] or flags["aim_assist"] and flags["aim_assist_nearest_part"]) and LastTarget and v == LastTarget and Script.Cache.CF then
            origin = Script.Cache.CF
        else
            origin = hrp.Position
        end
        
		if Origin == "Mouse" then
			distance = Script.Functions.GetMagnitudeFromMouse(origin)
		else
			distance = (origin - origin).Magnitude
		end 
        local silentfov = flags["silent_aim"] and distance <= SilentFovCircle.Radius
        local assistfov = flags["aim_assist"] and distance <= AimAssistFovCircle.Radius
        if not (silentfov or assistfov) then continue end
        
        if char:FindFirstChildOfClass("ForceField") then continue end
        if DeadCheck and char:FindFirstChild("Humanoid") and char.Humanoid.Health < 1 then continue end
        
        table.insert(ValidTargets, {
            Player = v,
            Character = char,
            Distance = distance
        })
    end
    
    table.sort(ValidTargets, function(a, b)
        return a.Distance < b.Distance
    end)

    for _, data in ipairs(ValidTargets) do
        if WallCheck then
            if (flags["silent_aim"] and flags["silent_aim_nearest_part"] or flags["aim_assist"] and flags["aim_assist_nearest_part"]) then
                local Closest = Script.Functions.GetClosest(data.Character)
                if not Closest then continue end
                if not Script.Functions.WallCheck(Closest, data.Character) then
                    continue  
                end
                distance = data.Distance
                hitpos = Closest
            elseif flags["aim_assist"] and not Script.Functions.WallCheck(data.Player.Character[flags["aim_assist_bone"]].Position, data.Character) then
                continue  
            elseif not Script.Functions.WallCheck(data.Character[flags["silent_aim_bone"]].Position, data.Character) then
                continue
            end
        end
        ClosestTarget = data.Player
        break
    end
    Script.Cache.Distance = distance

    Script.Cache.CF = hitpos
    LastTarget = ClosestTarget
    return ClosestTarget
end

Script.Functions.UpdateFov = (function()
    if flags["silent_fov"] then
        SilentFovCircle.Visible = true
        if flags["silent_sticky_fov"] and Target and Target.Character then
            local PartPos, OnScreen = Camera:WorldToViewportPoint(Target.Character.HumanoidRootPart.Position)
            if OnScreen then
                SilentFovCircle.Position = Vector2.new(PartPos.X, PartPos.Y)      
            else
                SilentFovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)
            end
        else
            SilentFovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)
        end
        if flags["silent_spin_fov"] then
            SilentFovCircle.Rotation = (SilentFovCircle.Rotation + (flags["silent_spin_speed_fov"] / 10)) % 360
        end
    else
        SilentFovCircle.Visible = false
    end

    if flags["assist_fov"] then
        AimAssistFovCircle.Visible = true
        if flags["assist_sticky_fov"] and Target and Target.Character then
            local PartPos, OnScreen = Camera:WorldToViewportPoint(Target.Character.HumanoidRootPart.Position)
            if OnScreen then
                AimAssistFovCircle.Position = Vector2.new(PartPos.X, PartPos.Y + GuiService:GetGuiInset().Y)
            else
                AimAssistFovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)
            end
        else
            AimAssistFovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)
        end
        if flags["assist_spin_fov"] then
            AimAssistFovCircle.Rotation = (AimAssistFovCircle.Rotation + (flags["assist_spin_speed_fov"] / 10)) % 360
        end
    else
        AimAssistFovCircle.Visible = false
    end
end)

Script.Functions.UpdateTracer = function ()
    if flags['snap_line'] and Target and Target.Character then
        local Char = Target.Character
        if not Char then 
            TracerLine.Visible = false
            return 
        end
        local hrp = Char:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            TracerLine.Visible = false
            return 
        end
        local hrpPos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
        if not onScreen then 
            TracerLine.Visible = false
            return 
        end
        TracerLine.From = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)
        TracerLine.To = Vector2.new(hrpPos.X, hrpPos.Y + GuiService:GetGuiInset().Y)
        TracerLine.Color = flags["snap_line_color"].Color
        TracerLine.Transparency = flags["snap_line_color"].Transparency
        TracerLine.Thickness = flags["target_snap_line_thickness"]
        TracerLine.Visible = true
    else
        TracerLine.Visible = false
    end
end

Script.Functions.OnChildAdded = (function(Child)
    if not Child:IsA("Tool") then return end
    ClientTool = Child
end)

Script.Functions.ChildRemoved = (function(Child)
    ClientTool = Client.Character:FindFirstChildWhichIsA("Tool")
end)

Script.Functions.CharacterAdded = function (Character)
    local con = Script.Connections.ChilAdded
    if con then
        con:Disconnect()
        Script.Connections.ChilAdded = nil
    end
    local con = Script.Connections.ChildRemoved 
    if con then
        con:Disconnect()
        Script.Connections.ChildRemoved = nil
    end
    Script.Connections.ChilAdded = Character.ChildAdded:Connect(Script.Functions.OnChildAdded)
    Script.Connections.ChildRemoved = Character.ChildRemoved:Connect(Script.Functions.ChildRemoved)
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function GetDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function Silent(Method, Arguments)
    local HitPart = Target.Character[flags.silent_aim_bone]
    if not HitPart then return end
    local CF
    if flags["silent_aim_nearest_part"] then
        CF = Script.Cache.CF
    end
    if Method == "Raycast" then
        local Origin = Arguments[2]
        Arguments[3] = GetDirection(Origin, CF or HitPart.Position)
    else
        local A_Ray = Arguments[2]
        local Origin = A_Ray.Origin
        local Direction = GetDirection(Origin, CF or HitPart.Position)
        Arguments[2] = Ray.new(Origin, Direction)
    end

    return Script.Connections.__namecall(unpack(Arguments))
end

do -- init
	ESP.connection = RS.Heartbeat:Connect(ESP.Update)
    Script.Connections.Tracer = RS.RenderStepped:Connect(Script.Functions.UpdateTracer)
	Script.Cache.NextSelectionTime = 0
	Script.Cache.LastTriggerTime = 0
	Script.Cache.LastShootTime = 0
	Script.Connections.Aimbot = RS.RenderStepped:Connect(function()
        if flags["local_dead_check"] and (not Client.Character or not Client.Character:FindFirstChild("Humanoid") or Client.Character.Humanoid.Health <= 0.1 or (hood_custom and Client.Character:FindFirstChild("BodyEffects") and Client.Character.BodyEffects["K.O"].Value)) then
            Target = nil
            Manager:StopCurrent()
            return
        end
		if flags["target_selected"] and flags['target_selected_bind']["active"]  then
			if flags["auto_select"] then
				if (tick() - Script.Cache.NextSelectionTime) >= flags['target_selector_refresh_time'] / 1000  then
    				Script.Cache.NextSelectionTime = tick()
					Target = Script.Functions.GetTarget({
						FriendCheck = flags["friend_check"],
						TeamCheck = flags["team_check"],
						WallCheck = flags["wall_check"],
						DeadCheck = flags["dead_check"],
						VisibleCheck = flags["visible_check"],
						Radius = flags["fov_radius"],
						Origin = flags["distance_priority"],
                        DistanceCheck = flags["distance_check"]
					})
				end
			end
			if Target and flags["aim_assist"] then
                if flags["tool_check"] and not ClientTool then Manager:StopCurrent() return end
				local Char = Target.Character
				if not Char then Manager:StopCurrent() return end
				local hrp = Char:FindFirstChild("HumanoidRootPart")
				if not hrp then Manager:StopCurrent() return end
                local CurrentPos = Uis:GetMouseLocation()

				if not flags['auto_select'] then
					if not hrp then Manager:StopCurrent() return end
					if flags["visible_check"] and Char.Head.Transparency >= 0.4 then Manager:StopCurrent() return end
					if flags["dead_check"] and Char:FindFirstChild("Humanoid") and Char.Humanoid.Health < 0.1 then Manager:StopCurrent() return end
					if not Script.Functions.OnScreen(hrp) then Manager:StopCurrent() return end
					if flags["wall_check"] then
						if not Script.Functions.WallCheck(Char[flags["aim_assist_bone"]].Position, Char) then
							Manager:StopCurrent() return  
						end
					end
				end
                --- idk why ts is complaining about this 
---@diagnostic disable-next-line: unused-local
				local TargetCF = if flags["aim_assist_nearest_part"] and Script.Cache.CF then Script.Cache.CF else Char[flags["aim_assist_bone"]].Position
                
                if flags["aim_assist_prediction"] then
                    TargetCF = TargetCF + (Char.HumanoidRootPart.Velocity * Vector3.new(flags["aim_pred_x"], flags["aim_pred_y"], flags["aim_pred_x"]))
                end
				local Vec2Pos = Camera:WorldToScreenPoint(TargetCF)
				if flags["aim_assist_shake"] then
					Vec2Pos = Vec2Pos + Vector2.new(
						math.random(-flags["aim_assist_shake_x"] * 10, flags["aim_assist_shake_x"] * 10),
						math.random(-flags["aim_assist_shake_y"] * 10, flags["aim_assist_shake_y"] * 10)
					)
				end
				local TargetPosition = Vector2.new(Vec2Pos.X, Vec2Pos.Y + GuiService:GetGuiInset().Y)
				if flags["aim_assist_smooth"] then
					local Smoothness = 0.5 / ((flags["aim_assist_smooth_x"] + flags["aim_assist_smooth_y"]) / 2)
					Manager:ChangeData({
						TargetPosition = TargetPosition,
						Smoothness = Smoothness,
						Method = flags["aim_assist_curve_method"]
					})
				else
					local Delta = TargetPosition - CurrentPos
					mousemoverel(Delta.X, Delta.Y)
				end
				if flags["aim_assist_triggerbot"] and tick() - Script.Cache.LastTriggerTime > flags["aim_assist_triggerbot_delay_between_shots"] / 1000 then
					local Distance = ((Script.Cache.CF or TargetPosition) - CurrentPos).Magnitude
					if Distance < flags["aim_assist_triggerbot_distance"] then
                        mouse1click()
						Script.Cache.LastTriggerTime = tick()
					end
				end
			else
				if flags["aim_assist_smooth"] then
					Manager:StopCurrent()
				end
			end
            if flags["silent_aim"] and flags["auto_shoot"] and Target and tick() - Script.Cache.LastShootTime > flags["auto_shoot_delay"] / 1000 then
                if flags["tool_check"] and not ClientTool then return end
                mouse1press()
				Script.Cache.LastShootTime = tick()
			end
		end
	end)
    
	Script.Connections.__index = hookmetamethod(game, "__index", function(self, Index)
		if not checkcaller() then
            if flags["silent_aim"] and Target then
                if flags["silent_aim_method"] == "Mouse Hook" and self == Mouse then
                    local HitPart = Target.Character[flags["silent_aim_bone"]]
                    local CF
                    if flags["silent_aim_nearest_part"] then
                        CF = Script.Cache.CF
                    end
                    if not HitPart then
                        return Script.Connections.__index(self, Index)
                    end
                    if Index == "Hit" then
                        local Pos = CF or HitPart.Position
                        if flags["silent_aim_prediction"] then
                            Pos = Pos + Target.Character.HumanoidRootPart.Velocity * flags["silent_aim_prediction_amount"]
                        end
                        if flags["silent_aim_hit_chance_enabled"] and math.random(1, 100) > flags["silent_aim_hit_chance"] then
                            return Script.Connections.__index(self, Index)
                        end
                        return CFrame.new(Pos)
                    elseif Index == "Target" then
                        return HitPart
                    end
                elseif flags["silent_aim_method"] == "ACS" and Index == "lookVector" and typeof(self) == "CFrame" then -- ts keeps crashing idk why (prob infinite loop)
                    local Dir = (self.CFrame.Position - Target.Character[flags["silent_aim_bone"]].Position).Unit
                    if flags["silent_aim_prediction"] then
                        Dir = Dir + (Target.Character.HumanoidRootPart.Velocity * flags["silent_aim_prediction_amount"])
                    end
                    if flags["silent_aim_hit_chance_enabled"] and math.random(1, 100) > flags["silent_aim_hit_chance"] then
                        return Script.Connections.__index(self, Index)
                    end
                    return Dir
                end
            end
            if Index == "CFrame" and self.Parent == Client.Character and tostring(self) == "HumanoidRootPart" and Script.Desync.OldCFrame ~= nil then
                return Script.Desync.OldCFrame
            end
		end
		return Script.Connections.__index(self, Index)
	end)
    
    Script.Connections.newindex = hookmetamethod(game, '__newindex', newcclosure(function(self, key, value)
        if flags["NoSlowdown"] and key == 'WalkSpeed' then
            local MinWS = Uis:IsKeyDown(Enum.KeyCode.LeftShift) and 22 or 16
            if value < MinWS then 
                value = MinWS
            end
        end
        
        if not checkcaller() and flags["NoJumpCooldown"] and game.IsA(self, "Humanoid") and key == "JumpPower" then 
            return
        end
        
        return Script.Connections.newindex(self, key, value)
    end))


    Script.Connections.__namecall = hookmetamethod(game, "__namecall", function(self, ...)
        if flags['silent_aim'] and Target and not checkcaller() then
            if flags["silent_aim_hit_chance_enabled"] and math.random(1, 100) > flags["silent_aim_hit_chance"] then
                return Script.Connections.__namecall(self, ...)
            end

            local Method = getnamecallmethod()
            local Args = {...}
            if self == workspace then
                if Method == "FindPartOnRayWithIgnoreList" and flags['silent_aim_method'] == "FindPartOnRayWithIgnoreList" and ValidateArguments(Args, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                    return Silent(Method, Args)
                elseif Method == "FindPartOnRay" and flags['silent_aim_method'] == "FindPartOnRay" and ValidateArguments(Args, ExpectedArguments.FindPartOnRay) then
                    return Silent(Method, Args)
                elseif Method == "FindPartOnRayWithWhitelist" and flags['silent_aim_method'] == "FindPartOnRayWithWhitelist" and ValidateArguments(Args, ExpectedArguments.FindPartOnRayWithWhitelist) then
                    return Silent(Method, Args)
                elseif Method == "Raycast" and flags['silent_aim_method'] == "Raycast Hook" and ValidateArguments(Args, ExpectedArguments.Raycast) then
                    return Silent(Method, Args)
                end
            end
            
            if flags['silent_aim_method'] == "HitPart" and tostring(self) == "HitPart" and tostring(Method) == "FireServer" then
                local HitPart = Target.Character[flags.silent_aim_bone]
                if HitPart then
                    Args[1] = HitPart
                    Args[2] = HitPart.Position
                    return self.FireServer(self, unpack(Args))
                end
            end
        end

        return Script.Connections.__namecall(self, ...)
    end)

    if prison_life then
        local old; old = hookfunction(filtergc("function", {Name = "castRay"}, true), (function(...)        
            if not checkcaller() and flags["silent_aim"] and flags["silent_aim_method"] == "CastRay" and Target and Target.Character then
                local TargetPos = Script.Cache.CF or Target.Character[flags.silent_aim_bone].Position
                if flags["silent_aim_prediction"] then
                    TargetPos = TargetPos + Target.Character.HumanoidRootPart.Velocity * flags["silent_aim_prediction_amount"]
                end
                if flags["silent_aim_hit_chance_enabled"] and math.random(1, 100) > flags["silent_aim_hit_chance"] then
                    return old(...)
                end
                return Target.Character[flags.silent_aim_bone], TargetPos
            end
            return old(...)
        end))
    end
	Script.Connections.RaycastHook = hookfunction(Workspace.Raycast, function(self, origin, direction, params)
		if not checkcaller() and flags["silent_aim"] and flags["silent_aim_method"] == "Raycast Hook" and Target and Target.Character then
			local TargetPos = Script.Cache.CF or Target.Character[flags.silent_aim_bone].Position
			if flags["silent_aim_prediction"] then
				TargetPos = TargetPos + Target.Character.HumanoidRootPart.Velocity * flags["silent_aim_prediction_amount"]
			end
			if flags["silent_aim_hit_chance_enabled"] and math.random(1, 100) > flags["silent_aim_hit_chance"] then
				return nil
			end
			if flags["silent_aim_shake"] then
				TargetPos = TargetPos + Vector3.new(math.random(-flags["silent_aim_shake_x"], flags["silent_aim_shake_x"]), math.random(-flags["silent_aim_shake_y"], flags["silent_aim_shake_y"]), 0)
			end
			direction = (TargetPos - origin).Unit * direction.Magnitude
		end
		return Script.Connections.RaycastHook(self, origin, direction, params)
	end)
    Script.Connections.Fov = RS.RenderStepped:Connect(Script.Functions.UpdateFov)

    Script.Connections.Mouvements = RS.PreSimulation:Connect(function (DeltaTime)
        if not (Client.Character and Client.Character:FindFirstChild("HumanoidRootPart")) then return end
        if flags["Fly"] and flags["Fly_Bind"]["active"] then 
            Client.Character.HumanoidRootPart.Velocity = Vector3.zero; 
            local x = 0 
            local y = 0 
            local z = 0 
            -- 
            if not GetFocusedTextBox() then 
                if Uis:IsKeyDown(Enum.KeyCode.W) then
                    z -= 1
                end
                if Uis:IsKeyDown(Enum.KeyCode.S) then
                    z += 1
                end
                if Uis:IsKeyDown(Enum.KeyCode.D) then
                    x += 1
                end
                if Uis:IsKeyDown(Enum.KeyCode.A) then
                    x -= 1
                end
                if Uis:IsKeyDown(Enum.KeyCode.Space) then
                    y += 1
                end
                if Uis:IsKeyDown(Enum.KeyCode.LeftControl) then
                    y -= 1
                end
            end 
            -- 
            local direction = safeUnit(Camera.CFrame:VectorToWorldSpace(Vector3.new(x, 0, z)).Unit)
            Client.Character.HumanoidRootPart.CFrame += (direction + Vector3.new(0, y, 0)) * (flags["Fly_Speed_Value"] / 10) * (DeltaTime * 60)
        end 
        if flags["Cframe_Speed_Bind"]["active"] and flags["Cframe_Speed"] then
            local humanoid = Client.Character.Humanoid
            if humanoid.MoveDirection.Magnitude > 0 then
                for i = 1, (flags["Cframe_Speed_Value"] / 10) * (DeltaTime * 160) do
                    if not flags["Cframe_Speed_Bind"]["active"] then
                        break
                    end
                    Client.Character:TranslateBy(humanoid.MoveDirection)
                end
            end
        end 
    end)

    Script.Connections.AntiAim = RS.Heartbeat:Connect(function(DeltaTime)   
        if Client.Character and Client.Character:FindFirstChild("HumanoidRootPart") then
            local RootPart = Client.Character.HumanoidRootPart
            Script.Desync.OldCFrame = RootPart.CFrame
            Script.Desync.OldVelocity = RootPart.Velocity
            Script.Desync.OldLinearVelocity = RootPart.AssemblyLinearVelocity

            if flags["anti_aim_spinbot"] then
                RootPart.CFrame = RootPart.CFrame * CFrame.Angles(0, math.rad(flags["anti_aim_spin_speed"] / 10), 0)
            end

            if flags["anti_aim_velocity"] and flags["anti_aim_velocity_bind"]["active"] then
                RootPart.Velocity = Vector3.new(80, 80, 80)
                RS.RenderStepped:Wait()
                RootPart.Velocity = Script.Desync.OldVelocity
            end
            if flags["anti_aim_freeze_pos"] and flags["anti_aim_freeze_pos_bind"]["active"] then
                setfflag("S2PhysicsSenderRate", 2)
                sethiddenproperty(RootPart, "NetworkIsSleeping", Sleep)
                setfflag("PhysicsSenderMaxBandwidthBps", math.pi/3)
                RootPart.AssemblyLinearVelocity = Vector3.new(math.random(-16384, 16384), math.random(-16384, 16384), math.random(-16384, 16384))
                RootPart.Velocity = Vector3.new(math.random(-16384, 16384), math.random(-16384, 16384), math.random(-16384, 16384))

                RS.RenderStepped:Wait()

                RootPart.Velocity = Script.Desync.OldVelocity
                RootPart.AssemblyLinearVelocity = Script.Desync.OldLinearVelocity

                setfflag("S2PhysicsSenderRate", 1)
                Sleep = not Sleep
            end

            if flags["anti_aim_random"] and flags["anti_aim_random_bind"]["active"] then
                setfflag("S2PhysicsSenderRate", math.random(1, 15) == 1 and 6 or 1)
                setfflag("PhysicsSenderMaxBandwidthBps", math.random(1, 100) == 1 and math.pi/3 or 28.274333882)
                RootPart.Velocity = math.random(1, 100) == 1 and Vector3.new(math.random(-16384, 65536), math.random(-16384, 65536), math.random(-16384, 65536)) or Vector3.new(math.random(-16384, 16384), math.random(-16384, 16384), math.random(-16384, 16384))
                RootPart.AssemblyLinearVelocity = RootPart.Velocity

                RootPart.CFrame += Vector3.new(math.random(-16384, 65536), math.random(-16384, 65536), math.random(-16384, 65536)) / 60000
                RootPart.CFrame *= CFrame.Angles(0, math.rad(math.random(1, 359)), 0)
                sethiddenproperty(RootPart, "NetworkIsSleeping", Sleep)
                Sleep = not Sleep

                RS.RenderStepped:Wait()

                RootPart.CFrame = Script.Desync.OldCFrame
                RootPart.Velocity = Script.Desync.OldVelocity
                RootPart.AssemblyLinearVelocity = Script.Desync.OldLinearVelocity

                setfflag("S2PhysicsSenderRate", math.random(1, 15) == 5 and 9e9 or 1)
            end
            if flags["anti_aim_lagstep"] and flags["anti_aim_lagstep_bind"]["active"] then
                setfflag("S2PhysicsSenderRate", 1)
                sethiddenproperty(RootPart, "NetworkIsSleeping", Sleep)
                sethiddenproperty(RootPart, "NetworkIsSleeping", not Sleep)
                sethiddenproperty(RootPart, "NetworkIsSleeping", Sleep)

                setfflag("PhysicsSenderMaxBandwidthBps", 28.274333882)

                RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                RootPart.Velocity = math.random(1, 100) == 5 and Vector3.new(math.random(-16384, 65536), math.random(-16384, 65536), math.random(-16384, 65536)) or Vector3.new(0, 0, 0)

                RS.RenderStepped:Wait()

                RootPart.Velocity = Script.Desync.OldVelocity
                RootPart.AssemblyLinearVelocity = Script.Desync.OldLinearVelocity

                setfflag("S2PhysicsSenderRate", math.random(1, 5) == 5 and 15 or 1)
                setfflag("PhysicsSenderMaxBandwidthBps", math.random(1, 10) == 1 and 28.274333882 or math.pi/3)

                sethiddenproperty(RootPart, "NetworkIsSleeping", Sleep)
                Sleep = not Sleep
            end
            if flags["anti_aim_network"] and flags["anti_aim_network_bind"]["active"] then
                sethiddenproperty(RootPart, "NetworkIsSleeping", Sleep)
                Sleep = not Sleep
            end

            Script.Desync.OldCFrame = nil
            Script.Desync.OldVelocity = nil
            Script.Desync.OldLinearVelocity = nil
        end
    end)
    
    ProxPromptService.PromptButtonHoldBegan:Connect(function(Prompt, Player)
        if flags["instant_interact"] and Player == Client then 
            fireproximityprompt(Prompt)
        end
    end)

    if Client.Character then
        Script.Functions.CharacterAdded(Client.Character)
    end

    Client.CharacterAdded:Connect(Script.Functions.CharacterAdded)
    
	for _,v in Players:GetPlayers() do 
		if v ~= Players.LocalPlayer then 
            task.spawn(function()
                ESP:create_object(v)
            end)

        end 
	end 
	ESP.player_added = Players.PlayerAdded:Connect(function(v)
		ESP:create_object(v)
	end)

	ESP.player_removed = Players.PlayerRemoving:Connect(function(v)
		ESP:remove_object(v)
	end)
    

	Combat.open_tab() 
	library:config_list_update()

	for index, value in themes.preset do 
		pcall(function()
			library:update_theme(index, value)
		end)
	end
	task.wait()

	library.old_config = library:get_config()
	library:fold_elements("aim_assist_smooth", {"aim_assist_smooth_x", "aim_assist_smooth_y"})
	library:fold_elements("aim_assist_shake", {"aim_assist_shake_x", "aim_assist_shake_y", "aim_assist_shake_z"})
	
	-- Initialize FOV radii
	SilentFovCircle.Radius = flags["silent_fov_radius"] or 100
	AimAssistFovCircle.Radius = flags["assist_fov_radius"] or 100
end







































--[[ hi this has been made by kexrna]]
