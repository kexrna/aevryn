--[[
    ok so this is becoming more and more spagueti but wtv il call it security
    idk why my desync visualizer is not showing the right colors
]]


local RS = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local GuiService = cloneref(game:GetService("GuiService"))
local Uis = cloneref(game:GetService("UserInputService"))
local Lighting = cloneref(game:GetService("Lighting"))
local LogService = cloneref(game:GetService("LogService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local Stats = cloneref(game:GetService("Stats"))    
--
local hex = Color3.fromHex
local Client = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = Client:GetMouse()
local CMouse = cloneref(Client:GetMouse())

--
local library, themes, ESP, Aiming, Target, ClientTool
local LastShotTick = 0
local OrbitAngle = 0
local Script = {Functions = {}, Friends = {}, Connections = {}, Cache = {}, Desync = {}, BeizerManager = {}, BeizerCurve = {}, Hooks = {}, Players = {}}
if LPH_OBFUSCATED then
	library, themes = loadstring(game:HttpGet())()
	ESP = loadstring(game:HttpGet())()
else
	library, themes = loadstring(readfile("aevryn/libs/ui.lua"))()
	ESP = loadstring(readfile("aevryn/libs/ESP lib.lua"))()   
end
local signal = {}
do 
    --[[
        _                       _ 
        (_)                     | |
    ___  _   __ _  _ __    __ _ | |
    / __|| | / _` || '_ \  / _` || |
    \__ \| || (_| || | | || (_| || |
    |___/|_| \__, ||_| |_| \__,_||_|
            __/ |                 
            |___/                  
    ]]

    signal.__index = signal

    function signal.new()
        return setmetatable({connections = {}}, signal)
    end

    function signal:Fire(...)
        for _, callback in self.connections do
            spawn(callback, ...)
        end
    end

    function signal:Connect(callback)
        local connection = {}
        local connections = self.connections 

        local index = utility.insert(connections, callback)

        function connection:Disconnect()
            utility.remove(connections, "", index)
            setmetatable(connection, nil)
        end

        return connection
    end

end
local LastClosestShot = nil
local flags = library.flags
ESP.flags = flags
local SilentFovCircle = {} do
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
    FovUI.Name = "SilentAimFOV"
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

    setmetatable(SilentFovCircle, {
        __index = function(_, k)
            return internal[k]
        end,
        __newindex = function(_, k, v)
            internal[k] = v
            update()
        end
    })

    update()
end
local TracerLine = Drawing.new("Line")
TracerLine.Thickness = 1
--
do
    local response = request({
        Url = ("https://friends.roblox.com/v1/users/%d/friends"):format(Client.UserId),
        Method = "GET"
    })

    if response.Success then
        local data = game:GetService("HttpService"):JSONDecode(response.Body)
        for _, friend in ipairs(data.data) do
            pcall(function ()
                Script.Friends[Players:GetNameFromUserIdAsync(friend.id)] = true
            end)
        end
    end
end
do -- bypass openac
    local conn
    conn = RS.RenderStepped:Connect(function()
        local connections = getconnections(LogService.MessageOut)
        if #connections >= 2 then
            for _, connection in ipairs(connections) do
                        pcall(function()
            local upvals = debug.getupvalues(connection.Function)
            local OPENAC_TABLE = upvals[9]
            if type(OPENAC_TABLE) ~= "table" then return end

            local OPENAC_FUNCTION = OPENAC_TABLE[1]
            if type(OPENAC_FUNCTION) ~= "function" then return end

            debug.setupvalue(OPENAC_FUNCTION, 14, function()
                return function(args)
                    pcall(function()
                        if type(args) == "table" and type(args[1]) == "userdata" then
                            for i = 1, 4 do
                                pcall(function()
                                    args[i]:Disconnect()
                                end)
                            end
                        end
                    end)
                end
            end)

            debug.setupvalue(OPENAC_FUNCTION, 1, function()
                task.wait(200)
            end)

            hookfunction(OPENAC_FUNCTION, function()
                return {}
            end)
        end)
            end
            conn:Disconnect()
        end
    end)
end
local SelfClone = game:GetObjects("rbxassetid://8246626421")[1]; SelfClone.Humanoid:Destroy(); SelfClone.Head.Face:Destroy(); SelfClone.Parent = game.Workspace; SelfClone.HumanoidRootPart.Velocity = Vector3.new(); SelfClone.HumanoidRootPart.CFrame = CFrame.new(9999,9999,9999); SelfClone.HumanoidRootPart.Transparency = 1; SelfClone.HumanoidRootPart.CanCollide = false 
local VisualizeChams = Instance.new("Highlight"); VisualizeChams.Enabled = true; VisualizeChams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; VisualizeChams.FillColor = Color3.fromRGB(102, 60, 153); VisualizeChams.OutlineColor =  Color3.fromRGB(0, 0, 0); VisualizeChams.Adornee = SelfClone; VisualizeChams.OutlineTransparency = 0.2; VisualizeChams.FillTransparency = 0.5; VisualizeChams.Parent = CoreGui
for i,v in pairs(SelfClone:GetDescendants()) do 
    if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then 
        v.CanCollide = false 
        v.Transparency = 0
    end 
end 
Script.Cache.Guns = {}
local all_items = {}
do
    local ignored_folder = Workspace.Ignored

    local all_shop = ignored_folder.Shop:GetChildren()

    for i = 1, #all_shop do
        local shop_item = all_shop[i]
        local new_name = string.match(shop_item.Name, "%b[]")
        local head = shop_item:FindFirstChild("Head")
        if head and head.CFrame.p.Y > -35 then
            if new_name then
                new_name = new_name:sub(2, -2)
                if new_name:find("Ammo") then
                    local non_ammo = new_name:sub(1, -6)
                    if not all_items[non_ammo] then
                        all_items[non_ammo] = {
                            main = nil,
                            ammo = head
                        }
                    elseif all_items[non_ammo].ammo == nil then
                        all_items[non_ammo].ammo = head
                    end
                else
                    if not all_items[new_name] then
                        all_items[new_name] = {
                            main = head,
                            ammo = nil
                        }
                    elseif all_items[new_name].main == nil then
                        all_items[new_name].main = head
                    end
                end
            end
        end
    end

    Script.Cache.Guns = {}
    for name, _ in pairs(all_items) do
        if _.ammo then
            table.insert(Script.Cache.Guns, name)
        end
    end
    Script.Functions.PurshaceItem = (function(name, click_detector, head, click_detector2, head2)
        local pingvalue = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        local split = string.split(pingvalue,'(')
        local ping = tonumber(split[1])*3/1000
        local old_cf = Script.Desync["Old_CFrame"]
        local did_buy = false
        if not Client.Backpack:FindFirstChild(string.format("[%s]", name)) then
            did_buy = true
            Script.Desync.ForceCFrame = head.CFrame - Vector3.new(0,4,0)
            task.wait(ping)
            fireclickdetector(click_detector)
        end
        if click_detector2 then
            local ammo = 1
            if ammo > 0 then
                task.wait(did_buy and .7 + ping or 0)
                Script.Desync.ForceCFrame = head2.CFrame - Vector3.new(0,4,0)
                task.wait(ping)
                for i = 1, ammo do
                    fireclickdetector(click_detector2)
                    task.wait(i == ammo and ping or .7 + ping)
                end
            end
        end
        Script.Desync.ForceCFrame = old_cf
        task.delay(0.03, function()
            Script.Desync.ForceCFrame = nil
        end)
    end)

    local armor = all_items["High-Medium Armor"]
    local fire_armor = all_items["Fire Armor"]
    local mask = all_items["Surgeon Mask"]
    Script.Functions.PurshaceArmor = (function()
        Script.Functions.PurshaceItem("High-Medium Armor", armor.main.Parent:FindFirstChildOfClass("ClickDetector"), armor.main)
    end)

    Script.Functions.PurshaceFireArmor = (function()
        Script.Functions.PurshaceItem("Fire Armor", fire_armor.main.Parent:FindFirstChildOfClass("ClickDetector"), fire_armor.main)
    end)

    Script.Functions.PurshaceMask = (function()
        local pingvalue = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        local split = string.split(pingvalue,'(')
        local ping = tonumber(split[1])*3/1000
        local old_cf = Script.Desync["Old_CFrame"]
        repeat
            Script.Desync.ForceCFrame = mask.main.CFrame - Vector3.new(0,4,0)
            task.wait(ping)
            fireclickdetector(mask.main.Parent:FindFirstChildOfClass("ClickDetector"))
        until Client.Backpack:FindFirstChild("[Mask]")

        Script.Desync.ForceCFrame = old_cf
        task.delay(0.03, function()
            Script.Desync.ForceCFrame = nil
        end)
    end)

end

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

local ManagerA = Script.BeizerManager.New()
ManagerA:MouseMode()
ManagerA:Start()

Script.BeizerCurve.ManagerA = ManagerA
Script.BeizerCurve.AimTo = function(...)
    ManagerA:ChangeData(...)
end

function GetFocusedTextBox()
    return Uis:GetFocusedTextBox()
end

local function isFriend(username)
    return Script.Friends[username] or false
end
local function safeUnit(unit)
    if unit.Magnitude > 1e-8 then
        return unit
    end
    -- 
    return Vector3.zero
end
--
do
	local window = library:window({name = os.date('BUBU NO CORAZON |  - %b %d %Y'), size = UDim2.new(0, 750, 0, 782)})

	Aiming = window:tab({name = "Aiming"})
	local Misc = window:tab({name = "Misc"})
	local Visuals = window:tab({name = "Visuals"})

		-- Aiming
		do
			local column =  Aiming:column() 
				local selec, lock, assist  = column:multi_section({names = {"Selection", "Silent", "Aim Assist"}})
					selec:toggle({name = "Enabled", flag = "target_selected", tooltip = "Manages selection of the target (both lock and aim assist)"})
					:keybind({name = "Aiming", flag = "target_selected_bind", callback = function ()
						if Target then 
							Target = nil
                            if flags["auto_shoot"] and ClientTool then
                                ClientTool:Deactivate()
                            end
						else
							Target = Script.Functions.GetTarget({
								FriendCheck = flags["friend_check"],
								TeamCheck = flags["team_check"],
								WallCheck = flags["wall_check"],
								DeadCheck = flags["dead_check"],
								VisibleCheck = flags["visible_check"],
								Radius = flags["fov_radius"],
								Origin = flags["distance_priority"],
                                KnockedCheck = flags["knocked_check"]
							})
						end
					end})
					selec:toggle({name = "Auto Select", flag = "auto_select", tooltip = "Selects targets for you. (Edit the delay slider if you want more fps.)"})
					selec:toggle({name = "Only Select Enemies", flag = "enemy_priority", tooltip = "Only targets users under the priority enemy (through the playerlist)"})
					selec:label({name = "Add Plr to enemy"}):keybind({name = "Add Target Bind", flag = "add_target_enemy_bind", callback = function ()
                        local Plr = Script.Functions.GetTarget({
								FriendCheck = flags["friend_check"],
								TeamCheck = flags["team_check"],
								WallCheck = flags["wall_check"],
								DeadCheck = flags["dead_check"],
								VisibleCheck = flags["visible_check"],
								Radius = flags["fov_radius"],
								Origin = flags["distance_priority"],
                                KnockedCheck = flags["knocked_check"],
                                Force = true
							})
                            if not Plr then return end
                        local c = library.selected_player
                        library.selected_player = Plr.Name or c
                        library.prioritize("Enemy")
                        library.selected_player = c
                    end})
                    selec:label({name = "Remove Plr from enemy"}):keybind({name = "Remove Target Bind", flag = "remove_target_enemy_bind", callback = function ()
                        local Plr = Script.Functions.GetTarget({
                            FriendCheck = flags["friend_check"],
                            TeamCheck = flags["team_check"],
                            WallCheck = flags["wall_check"],
                            DeadCheck = flags["dead_check"],
                            VisibleCheck = flags["visible_check"],
                            Radius = flags["fov_radius"],
                            Origin = flags["distance_priority"],
                            KnockedCheck = flags["knocked_check"],
                            Force = true
                        })
                        if not Plr then return end
                        local c = library.selected_player
                        library.selected_player = Plr.Name or c
                        library.prioritize("Neutral")
                        library.selected_player = c
                    end})
                    selec:dropdown({name = "Origin", flag = "distance_priority", items = {"Mouse", "Distance"}, default = "Mouse", tooltip = "Selects targets based on the origin"})
					selec:slider({name = "Delay", min = 0, max = 1000, default = 40, interval = 1, suffix = "ms", flag = "target_selector_refresh_time", tooltip = "Used for optimizing the checks and target selection. Use for lower end pcs."})
					selec:toggle({name = "Wall Check", flag = "wall_check"})
					selec:toggle({name = "Dead Check", flag = "dead_check"})
					selec:toggle({name = "ForceField Check", flag = "forcefield_check"})
					selec:toggle({name = "Friend Check", flag = "friend_check"})
					selec:toggle({name = "Team Check", flag = "team_check"})
                    selec:toggle({name = "Tool Check", flag = "tool_check"})
					selec:toggle({name = "Visible Check", flag = "visible_check"})
                    selec:toggle({name = "Knocked Check", flag = "knocked_check"})
                    selec:toggle({name = "Distance", flag = "distance_check"})
                    selec:toggle({name = "Automatic distance", flag = "Automatic_distance"}, function ()
                        library:fold_elements("Automatic_distance", {"distance_limit"})
                    end)
                    selec:slider({name = "Distance Limit", min = 0, max = 1000, default = 250, interval = 1, suffix = " studs", flag = "distance_limit"})
					--
					lock:toggle({name = "Enabled", flag = "silent_aim"})
					lock:toggle({name = "Auto Shoot", flag = "auto_shoot"})
                    lock:toggle({name = "Rapid Fire", flag = "rapid_fire", callback = function (state)
                        if not state then
                            if Script.Cache.RapidUpvalue then
                                debug.setupvalue(Script.Cache.RapidUpvalue.Function, Script.Cache.RapidUpvalue.Index, Script.Cache.RapidUpvalue.OldValue)
                                Script.Cache.RapidUpvalue = nil
                            end
                            if Script.Cache.RapidConstant then
                                debug.setconstant(Script.Cache.RapidConstant.Function, Script.Cache.RapidConstant.Index, Script.Cache.RapidConstant.OldValue)
                                Script.Cache.RapidConstant = nil
                            end
                        end
                    end})
					lock:dropdown({name = "Aim Bone", flag = "silent_aim_bone", items = {"HumanoidRootPart", "Head", "LeftUpperLeg", "RightUpperLeg", "LeftUpperArm", "RightUpperArm"}, default = "Head"})
                    lock:toggle({name = "P Silent", flag = "PSilent", tooltip = "Basically anti aim viewer"})
                    lock:toggle({name = "Resolver", flag = "resolver", function (state)
                        if state then
                            Script.Connections.Resolver = Workspace:WaitForChild("Ignored").Siren.Radius.ChildAdded:Connect(function(object)
                            if object.Name == "BULLET_RAYS" then
                                        local BulletBeam = object:FindFirstChildOfClass("Beam")
                                        if BulletBeam then
                                            if object.GetAttribute("OwnerCharacter") == Client.Name then
                                                -- will be usefull
                                            else
                                                if not Target then return end

                                                local Data = Script.Functions.GetTargetData(Target)
                                                local Hrp = Target.Character[flags["silent_aim_bone"]]

                                                if not Hrp then  return end

                                                local Client_Hrp = Client.Character and Client.Character:FindFirstChild("HumanoidRootPart")

                                                if not Client_Hrp then return end
                                                    
                                                local old = object.Position + Hrp.CFrame.LookVector*Vector3.new(-6, 0, -6)

                                                if (Client_Hrp.Position - old).magnitude > 250 then return end

                                                LastClosestShot = old

                                                task.delay(1, function()
                                                    if LastClosestShot == old then
                                                        LastClosestShot = nil
                                                        Data.ForcePosition = nil
                                                    end
                                                end)
                                            end
                                        end
                                    end
                            end)
                        else
                            LastClosestShot = nil
                            if Script.Connections.Resolver then
                                Script.Connections.Resolver:Disconnect()
                                Script.Connections.Resolver = nil
                            end
                        end
                    end})
                    lock:toggle({name = "No Recoil", flag = "Norecoil"})
                    lock:toggle({name = "No Spread", flag = "NoSpread"})
                    lock:toggle({name = "Nearest Part", flag = "nearest_part", callback = function (state)
                        library:fold_elements("nearest_part", {"random_part", "multi_point", "multi_point_scale", "whitelist_part"})
                    end})
                    lock:dropdown({name = "Whitelisted Parts", flag = "whitelist_part", multi = true, items = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}, default = "Head"})
                    lock:toggle({name = "Random Part", flag = "random_part"})
                    lock:toggle({name = "Multi Point", flag = "multi_point"})
                    lock:slider({name = "Multi Point Scale", min = 0, max = 100, default = 100, interval = 1, flag = "multi_point_scale"})
                    
                    --
					assist:toggle({name = "Enabled", flag = "aim_assist"})
					assist:dropdown({name = "Aim Part", flag = "aim_assist_bone", items = {"HumanoidRootPart", "Head"}, default = "Head"})
					assist:dropdown({name = "Curve Method", flag = "aim_assist_curve_method", items = {"Linear", "Cubic"}, default = "Cubic"})
                    assist:toggle({name = "Smooth Movement", flag = "aim_assist_smooth", default = true, callback = function()
                        library:fold_elements("aim_assist_smooth", {"aim_assist_smooth_x", "aim_assist_smooth_y"})
					end})
					assist:slider({name = "Smoothness X", min = 1, max = 100, default = 6, interval = 1, flag = "aim_assist_smooth_x"})
					assist:slider({name = "Smoothness Y", min = 1, max = 100, default = 6, interval = 1, flag = "aim_assist_smooth_y"})
                    
					assist:toggle({name = "Shake", flag = "aim_assist_shake", callback = function()
						library:fold_elements("aim_assist_shake", {"aim_assist_shake_x", "aim_assist_shake_y", "aim_assist_shake_z"})
					end})

					assist:slider({name = "Shake X", min = 0, max = 10, default = 0, interval = 0.1, flag = "aim_assist_shake_x"})
					assist:slider({name = "Shake Y", min = 0, max = 10, default = 0, interval = 0.1, flag = "aim_assist_shake_y"})
					assist:slider({name = "Shake Z", min = 0, max = 10, default = 0, interval = 0.1, flag = "aim_assist_shake_z"})

					
			local column =  Aiming:column() 
				local vis, other  = column:multi_section({names = {"Visuals", "Other"}})
					other:toggle({name = "Look At", flag = "look_at"})
					other:toggle({name = "Spectate", flag = "spectate"})
					vis:toggle({name = "Tracer", flag = "snap_line"})
					:colorpicker({name = "Tracer Inline", flag = "snap_line_color", color = hex("#7D0DC3")})
					:colorpicker({flag = "Tracer Outline", color = hex("#000000")})
					vis:slider({name = "Thickness", min = 1, max = 5, default = 1, interval = 1, suffix = "°", flag = "target_snap_line_thickness"})
					vis:toggle({name = "Highlight", flag = "target_highlight"})
					:colorpicker({name = "Outline", flag = "target_highlight_settings", color = hex("#000000")})
					:colorpicker({name = "Fill", flag = "target_highlight_settings", color = hex("#000000")})  
					vis:toggle({name = "Field Of View", flag = "fov", callback = function (state)
                        SilentFovCircle.Visible = state
                    end})   
					:colorpicker({name = "1st Color (Gradient)", flag = "fov_1_settings", color = hex("#7D0DC3"), alpha = 0.5, callback = function(Color, alpha)
                        SilentFovCircle.Color = Color
                        SilentFovCircle.Transparency = 1 - alpha
                    end}) 
					:colorpicker({name = "2nd Color (Gradient)", flag = "fov_2_settings", color = hex("#7D0DC3"), alpha = 0.5, callback = function(Color, alpha)
                        SilentFovCircle.GradientColor1 = Color
                    end}) :colorpicker({name = "3nd Color (Gradient)", flag = "fov_3_settings", color = hex("#7D0DC3"), alpha = 0.5, callback = function(Color, alpha)
                        SilentFovCircle.GradientColor2 = Color
                    end})
					vis:toggle({name = "Outline", flag = "outline_fov", callback = function (state)
                        SilentFovCircle.OutlineThickness = state and SilentFovCircle.OutlineThickness or 0
                    end})  
					:colorpicker({name = "1st Color (Gradient)", flag = "outline_fov_settings_1", color = hex("#000000"), alpha = 1, callback = function(Color, alpha)
                        SilentFovCircle.OutlineColor = Color
                        SilentFovCircle.OutlineTransparency = 1 - alpha

                    end}) 
					:colorpicker({name = "2nd Color (Gradient)", flag = "outline_fov_settings_2", color = hex("#000000"), alpha = 1, callback = function(Color, alpha)
                        SilentFovCircle.Gradient = Color
                    end}) 
					vis:slider({name = "Radius", min = 0, max = 1000, default = 100, interval = 1, flag = "fov_radius", callback = function (v)
                        SilentFovCircle.Radius = v * 3
                    end})
					vis:slider({name = "Thickness", min = 0, max = 5, default = 1, interval = 1, flag = "outline_thickness_fov", callback = function (v)
                        SilentFovCircle.OutlineThickness = v
                    end})
					vis:slider({name = "Custom Rotation", min = -180, max = 180, default = 0, interval = 1, flag = "custom_rotation_fov", callback = function (v)
                        SilentFovCircle.Rotation = v
                    end})
					vis:toggle({name = "Spin", flag = "spin_fov"})
					vis:slider({name = "Rotation Speed", min = 0, max = 100, default = 100, interval = 1, flag = "spin_speed_fov"})
					library.config_flags["fov"](false)
         
            local Others = column:section({name = "Others", toggle = false})
                Others:toggle({name = "Auto Reload", flag = "auto_reload"})
                Others:label({name = "Target Strafe Settings"})
                Others:toggle({name = "Target Strafe", flag = "target_strafe"}):keybind({name = "Target Strafe Bind", flag = "target_strafe_bind"})
                Others:toggle({name = "Server Sided", flag = "target_strafe_server_sided"})
                Others:toggle({name = "Auto Stomp", flag = "target_strafe_auto_stomp"})
                Others:dropdown({name = "Mode", flag = "target_strafe_mode", items = {"Random", "Circle"}, default = "Circle", callback = function (state)
                    library:fold_elements("target_strafe_mode", {"target_strafe_distance", "target_strafe_min_distance", "target_strafe_max_height", "target_strafe_min_height"})
                    library:fold_elements("target_strafe_mode", {"target_strafe_radius", "target_strafe_speed","target_strafe_y_offset"})
                end})
                Others:slider({name = "Radius", min = 0, max = 100, default = 10, interval = 1, suffix = " studs", flag = "target_strafe_radius"})
                Others:slider({name = "Speed", min = 1, max = 100, default = 30, interval = 1, suffix = "%", flag = "target_strafe_speed"})
                Others:slider({name = "Y offset", min = -100, max = 100, default = 0, interval = 1, suffix = " studs", flag = "target_strafe_y_offset"})

                Others:slider({name = "Maximum Distance", min = 0, max = 1000, default = 250, interval = 1, suffix = " studs", flag = "target_strafe_distance"})
                Others:slider({name = "Minimum Distance", min = 0, max = 1000, default = 0, interval = 1, suffix = " studs", flag = "target_strafe_min_distance"})
                Others:slider({name = "Maximum height", min = 0, max = 100, default = 50, interval = 1, suffix = " studs", flag = "target_strafe_max_height"})
                Others:slider({name = "Minimum height", min = 0, max = 100, default = 0, interval = 1, suffix = " studs", flag = "target_strafe_min_height"})
                library:fold_elements("target_strafe_mode", {"target_strafe_radius", "target_strafe_speed","target_strafe_y_offset"})

		end

        -- misc
        do
            local column = Misc:column()
                local section = column:section({name = "General", toggle = false})
                    section:toggle({name = "No Slowdown", flag = "NoSlowdown"})
                    section:toggle({name = "Anti FlashBang", flag = "NoFlashbang"})
                    section:toggle({name = "No Jump Cooldown", flag = "NoJumpCooldown"})

                local section = column:section({name = "Automation", toggle = false})
                    section:dropdown({name = "Guns" , flag = 'Selected_gun', items = Script.Cache.Guns, default = Script.Cache.Guns[1]})
                    section:button_holder({})
                    section:button({name = 'buy gun', callback = function ()
                        local Value = flags["Selected_gun"]
                        local pingvalue = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                        local split = string.split(pingvalue,'(')
                        local ping = tonumber(split[1])*3/1000
                        local old_cf = Script.Desync["Old_CFrame"]
                        if not Client.Backpack:FindFirstChild(string.format("[%s]", Value)) then
                            Script.Desync.ForceCFrame = all_items[Value].main.CFrame - Vector3.new(0,4,0)
                            task.wait(ping)
                            fireclickdetector(all_items[Value].main.Parent:FindFirstChildOfClass("ClickDetector"))
                        end
                        Script.Desync.ForceCFrame = old_cf
                        task.delay(0.03, function()
                            Script.Desync.ForceCFrame = nil
                        end)
                    end})
                    section:button({name = 'buy ammo', callback = function ()
                        local pingvalue = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                        local split = string.split(pingvalue,'(')
                        local ping = tonumber(split[1])*3/1000
                        local old_cf = Script.Desync["Old_CFrame"]
                        
                        if Client.Backpack:FindFirstChild(string.format("[%s]", flags["Selected_gun"])) then
                            Script.Desync.ForceCFrame = all_items[flags["Selected_gun"]].ammo.CFrame - Vector3.new(0,4,0)
                            task.wait(ping)
                            fireclickdetector(all_items[flags["Selected_gun"]].ammo.Parent:FindFirstChildOfClass("ClickDetector"))
                        end
                        Script.Desync.ForceCFrame = old_cf
                        task.delay(0.03, function()
                            Script.Desync.ForceCFrame = nil
                        end)
                    end})
                    section:toggle({name = "Auto Buy Armor", flag = "auto_armor", callback = function ()
                        library:fold_elements("auto_armor", {"auto_buy_armor_threshold"})
                    end})
                    section:slider({name = "Auto Buy Armor Threshold", min = 0, max = 130, default = 70, interval = 1, flag = "auto_armor_threshold"})
                    section:toggle({name = "Auto Buy Fire Armor", flag = "auto_fire_armor", callback = function ()
                        library:fold_elements("auto_fire_armor", {"auto_buy_fire_armor_threshold"})
                    end})
                    section:slider({name = "Auto Buy Fire Armor Threshold", min = 0, max = 200, default = 70, interval = 1, flag = "auto_fire_armor_threshold"})
                    section:toggle({name = "Auto Mask", flag = "auto_mask"})
            local column = Misc:column()
                local Mouvements = column:section({name = "Mouvements", toggle = false})
                    Mouvements:toggle({name = "CFrame Speed", flag = "Cframe_Speed"}):keybind({name = "CFrame Speed Bind", flag = "Cframe_Speed_Bind"})
                    Mouvements:slider({name = "Speed", min = 1, max = 100, default = 30, interval = 1, suffix = "%", flag = "Cframe_Speed_Value"})

                    Mouvements:toggle({name = "Fly", flag = "Fly"}):keybind({name = "Fly Bind", flag = "Fly_Bind"})
                    Mouvements:slider({name = "Speed", min = 1, max = 100, default = 30, interval = 1, suffix = "%", flag = "Fly_Speed_Value"})
                local macro = column:section({name = "Macro", toggle = false})
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
                    
                    macro:toggle({name = "Rotation (360)", flag = "macro_rotation"}):keybind({name = "Macro Rotation Bind", flag = "macro_rotation_bind", callback = function ()
                        if not flags["macro_rotation"] then return end
                        local a = false
                        for i = 1, math.floor(flags['macro_rotation_degree'] / flags['macro_rotation_speed']) do
                            Camera.CoordinateFrame = Camera.CoordinateFrame * CFrame.Angles(0, math.rad(flags['macro_rotation_speed']), 0)
                            RS.Heartbeat:Wait()
                        end
                    end})
                    macro:slider({name = "Rotation Speed", min = 1, max = 100, default = 30, interval = 1, suffix = "%", flag = "macro_rotation_speed"})
                    macro:slider({name = "Rotation Degree", min = 1, max = 360, default = 360, interval = 1, suffix = "°", flag = "macro_rotation_degree"})
            end     
		-- Visuals
		do
		    local esp;
			local function update_elements() if esp and esp.refresh_elements then esp.refresh_elements() end; if ESP and ESP.refresh_elements then ESP.refresh_elements() end end 
			local column = Visuals:column()
			local section = column:section({name = "Esp", toggle = false})
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
            section2:toggle({name = "Ambient Color", default = false, flag = "Ambient Color", callback = Script.Functions.AmbientColor}):colorpicker({flag =  "Ambient_Color", callback = Script.Functions.AmbientColor})

            local section3 = column2:section({name = "Others", toggle = false})
        section3:toggle({name = "Visualize Desync Position", flag = "show_desync_pos"}):colorpicker({name = "Desync Position Color", flag = "desync_pos_color", color = hex("#FF0000"), callback = function(Color, Alpha) 
                VisualizeChams.FillColor = Color
                VisualizeChams.FillTransparency = 1 - Alpha
            end}):colorpicker({name = "Desync Position Outline Color", flag = "desync_pos_outline_color", color = hex("#000000"), callback = function(Color, Alpha) 
                VisualizeChams.OutlineColor = Color
                VisualizeChams.OutlineTransparency = 1 - Alpha
            end})
		end

end 
Script.Functions.AmbientColor = (function()
    if flags["Ambient Color"] then
        Lighting.ColorCorrection.TintColor = flags["Ambient_Color"].Color
    else
        Lighting.ColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
    end
end)

Script.Functions.GetTeams = function()
    local count = 0
    for _, team in pairs(game:GetService("Teams"):GetChildren()) do
        count = count + 1
    end
    return count
end

Script.Functions.GetMagnitudeFromMouse = function(Part)
    local PartPos, OnScreen = Camera:WorldToScreenPoint(Part.Position)
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

Script.Functions.WallCheck = function(ScreenPos, PartDescendant)
    local Character = Client.Character
    local Origin = Camera.CFrame.Position

    -- Create a ray from the camera through the screen position
    local Ray = Camera:ScreenPointToRay(ScreenPos.X, ScreenPos.Y)

    local RayCastParams = RaycastParams.new()
    RayCastParams.FilterType = Enum.RaycastFilterType.Blacklist
    RayCastParams.FilterDescendantsInstances = {Character, Camera}

    local Result = Workspace.Raycast(Workspace, Ray.Origin, Ray.Direction * 1000, RayCastParams)
    
    if (Result) then
        local PartHit = Result.Instance
        local Visible = (not PartHit or Instance.new("Part").IsDescendantOf(PartHit, PartDescendant))
        
        return Visible
    end
    return false
end

Script.Functions.CheckKnocked = function(Plr)
    local Grabbed = Plr.Character:FindFirstChild("GRABBING_CONSTRAINT") ~= nil
    local KoCheck = true
    if Plr.Character:FindFirstChild("BodyEffects") and Plr.Character.BodyEffects:FindFirstChild("K.O") then
        KoCheck = Plr.Character:FindFirstChild("BodyEffects"):FindFirstChild("K.O").Value
    elseif Plr.Character:FindFirstChild("BodyEffects") and Plr.Character.BodyEffects:FindFirstChild("KO") then
        KoCheck = Plr.Character:FindFirstChild("BodyEffects"):FindFirstChild("KO").Value
    end
    if KoCheck or Grabbed then
        return true
    end
    return false
end

Script.Functions.DeathCheck = (function(Plr)
    return Plr and Plr.Character and Plr.Character:FindFirstChild("BodyEffects") and Plr.Character:FindFirstChild("BodyEffects"):FindFirstChild("SDeath") and Plr.Character:FindFirstChild("BodyEffects"):FindFirstChild("SDeath").Value or false
end)

Script.Functions.GetClosest = function (Char)
    local selection = nil
    local closestDistance = math.huge
    local pos = nil
    local hitpos = CMouse.Hit.Position
    local parts = {}
    
    for _, part in ipairs(Char:GetChildren()) do -- im too lazy to make it handle whitelist part with only one part since it becomes a string
        if part:IsA("BasePart") and type(flags["whitelist_part"]) == "table" then
            local name = part.Name
            if table.find(flags["whitelist_part"], "Torso") and (name == "Torso" or name == "UpperTorso" or name == "LowerTorso") then
                table.insert(parts, part)
                continue
            end

            if table.find(flags["whitelist_part"], "Head") and name == "Head" then
                table.insert(parts, part)
                continue
            end

            if table.find(flags["whitelist_part"], "LeftArm") and (name == "Left Arm" or name == "LeftUpperArm" or name == "LeftLowerArm" or name == "LeftHand") then
                table.insert(parts, part)
                continue
            end

            if table.find(flags["whitelist_part"], "RightArm") and (name == "Right Arm" or name == "RightUpperArm" or name == "RightLowerArm" or name == "RightHand") then
                table.insert(parts, part)
                continue
            end

            if table.find(flags["whitelist_part"], "LeftLeg") and (name == "Left Leg" or name == "LeftUpperLeg" or name == "LeftLowerLeg" or name == "LeftFoot") then
                table.insert(parts, part)
                continue
            end

            if table.find(flags["whitelist_part"], "RightLeg") and (name == "Right Leg" or name == "RightUpperLeg" or name == "RightLowerLeg" or name == "RightFoot") then
                table.insert(parts, part)
                continue
            end

            if table.find(flags["whitelist_part"], "Torso") and name == "HumanoidRootPart" then
                table.insert(parts, part)
                continue
            end
        end
    end

    if #parts == 0 then table.insert(parts, Char["silent_aim_bone"]) end

    if flags["random_part"] then
        if #parts > 0 then
            selection = parts[math.random(1, #parts)]
        end
    else
        for _, part in pairs(parts) do
            if part:IsA("BasePart") then
                local distance = (part.Position - hitpos).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    selection = part
                end
            end
        end
    end
   
    if selection then
        pos = selection.Position
        if flags["multi_point"] then
            local transform = selection.CFrame:PointToObjectSpace(hitpos)
            if not transform then return pos end
            local sx, sy, sz = selection.Size.X/2, selection.Size.Y/2, selection.Size.Z/2

            pos = selection.CFrame * Vector3.new(
                math.clamp(transform.X, -sx, sx),
                math.clamp(transform.Y, -sy, sy),
                math.clamp(transform.Z, -sz, sz)
            )
        end
    end
    return pos
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
    local KnockedCheck = Settings.KnockedCheck
    local DistanceCheck = Settings.DistanceCheck
    local Teams = Script.Functions.GetTeams()
    local Origin = Settings.Origin
    local ClosestTarget = nil
    local hitpos = nil
    local ValidTargets = {}
	local Targets = {} do
        
		if flags["enemy_priority"] and not Settings.Force then
			for _, P in pairs(Players:GetPlayers()) do
				if library.playerlist_data[P.Name] and library.playerlist_data[P.Name].priority == "Enemy" then
					table.insert(Targets, P)
				end
			end
		else
			Targets = Players:GetPlayers()
            if Settings.Force then
                for _, P in pairs(Targets) do
                    if library.playerlist_data[P.Name] and library.playerlist_data[P.Name].priority == "Enemy" then
                        table.remove(Targets, table.find(Targets, P))
                    end
                end
            end
		end
	end  
    for _, v in pairs(Targets) do
        if v == Client then continue end
        
        local char = v.Character
        if not char then continue end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if KnockedCheck and Script.Functions.CheckKnocked(v) then continue end
        if DeadCheck and Script.Functions.DeathCheck(v) then continue end
        if VisibleCheck and char.Head.Transparency >= 0.4 then continue end
        if FriendCheck and not Settings.Force and isFriend(v.Name) then continue end
        if TeamCheck and not Settings.Force and v:FindFirstChild('DataFolder') and Client:FindFirstChild('DataFolder') and v.DataFolder:FindFirstChild('Information') and Client.DataFolder:FindFirstChild('Information') and Client.DataFolder:FindFirstChild('Information') and v.DataFolder.Information:FindFirstChild("Crew") and Client.DataFolder.Information:FindFirstChild("Crew") and v.DataFolder.Information:FindFirstChild("Crew").Value == Client.DataFolder.Information:FindFirstChild("Crew").Value then continue end
        if not Script.Functions.OnScreen(hrp) then continue end
        if DistanceCheck then
            local Auto = flags["Automatic_distance"] and ClientTool and ClientTool.Range.Value or false

            if Auto and (hrp.Position - Hrp.Position).Magnitude > ClientTool.Range.Value then  continue end
            if (hrp.Position - Hrp.Position).Magnitude > flags["distance_limit"] then continue end
        end  
        local distance 
        if Origin == "Mouse" then
            distance = Script.Functions.GetMagnitudeFromMouse(hrp)
            if SilentFovCircle.Radius < distance then continue end
        else
            distance = (hrp.Position - Hrp.Position).Magnitude
        end 

        if not Settings.Force and char:FindFirstChildOfClass("ForceField") then continue end
        
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
            if flags["silent_aim"] and flags["nearest_part"] then
                local Closest = Script.Functions.GetClosest(data.Character)
                if not Closest then continue end
                local screenPos = Camera:WorldToScreenPoint(Closest)
                screenPos = Vector2.new(screenPos.X, screenPos.Y + GuiService:GetGuiInset().Y)
                if not Script.Functions.WallCheck(screenPos, data.Character) then
                    continue  
                end
                hitpos = Closest
            elseif flags["aim_assist"] then
                local screenPos = Camera:WorldToScreenPoint(data.Player.Character[flags["aim_assist_bone"]].Position)
                screenPos = Vector2.new(screenPos.X, screenPos.Y + GuiService:GetGuiInset().Y)
                if not Script.Functions.WallCheck(screenPos, data.Character) then
                    continue
                end
            elseif flags["silent_aim"] then
                local screenPos = Camera:WorldToScreenPoint(data.Character[flags["silent_aim_bone"]].Position)
                screenPos = Vector2.new(screenPos.X, screenPos.Y + GuiService:GetGuiInset().Y)
                if not Script.Functions.WallCheck(screenPos, data.Character) then
                    continue
            end
        end
        ClosestTarget = data.Player
        break
    end
    if not Settings.Force then Script.Cache.CF = hitpos end
    return ClosestTarget
end

Script.Functions.DoChecks = function (Plr, Settings)
    local Char = Plr.Character
    if not Char then return false end
    
    local Hrp = Char:FindFirstChild("HumanoidRootPart")
    if not Hrp then return false end
    
    local FriendCheck = Settings.FriendCheck
    local DeadCheck = Settings.DeadCheck
    local VisibleCheck = Settings.VisibleCheck
    local KnockedCheck = Settings.KnockedCheck
    local DistanceCheck = Settings.DistanceCheck

    if Plr == Client then return false end
    if KnockedCheck and Script.Functions.CheckKnocked(Plr) then return false end
    if DeadCheck and Script.Functions.DeathCheck(Plr) then return false end
    if VisibleCheck and Char.Head.Transparency >= 0.4 then return false end
    if FriendCheck and isFriend(Plr.Name) then return false end 
    if DistanceCheck and (Hrp.Position - Script.Desync["Real_Pos"].Position).Magnitude > ((flags["Automatic_distance"] and ClientTool and ClientTool.Range.Value) or flags["distance_limit"]) then return false end
    return true
end

Script.Functions.UpdateFov = (function()    
    if not flags["fov"] then
        SilentFovCircle.Visible = false
        return
    end
    if flags["StickyFov"] and Target and Target.Character then
        local PartPos, OnScreen = Camera:WorldToViewportPoint(Target.Character.HumanoidRootPart.Position)
        if OnScreen then
            SilentFovCircle.Position = Vector2.new(PartPos.X, PartPos.Y)      
        else
            SilentFovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)
        end
    else
        SilentFovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)
    end
    if flags["spin_fov"] then
        SilentFovCircle.Rotation = (SilentFovCircle.Rotation + (flags["spin_speed_fov"] / 10)) % 360
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

Script.Functions.Rapid = (function(Child) 
    for _, connection in ipairs(getconnections(Child.Activated)) do
        local funcInfo = debug.getinfo(connection.Function)
        for i = 1, funcInfo.nups do
            local upvalue = debug.getupvalue(connection.Function, i)
            local constant = debug.getconstant(connection.Function, i)
            if type(upvalue) == "number" then
                debug.setupvalue(connection.Function, i, 0.01)
                Script.Cache.RapidUpvalue = {Function = connection.Function, Index = i, OldValue = upvalue}
            end
            if type(constant) == "number" then
                debug.setconstant(connection.Function, i, 0.01) 
                Script.Cache.RapidConstant = {Function = connection.Function, Index = i, OldValue = constant}
            end
        end
    end
end)

Script.Functions.OnChildAdded = (function(Child)
    if not Child:IsA("Tool") then return end
    ClientTool = Child
    if Script.Connections.Activated then
        Script.Connections.Activated:Disconnect()
        Script.Connections.Activated = nil
    end
    if Script.Connections.Deactivated then
        Script.Connections.Deactivated:Disconnect()
        Script.Connections.Deactivated = nil
    end
    Script.Connections.Activated = Child.Activated:Connect(function(...)
        Script.Cache.Activated = true
    end)
    Script.Connections.Deactivated = Child.Deactivated:Connect(function(...)
        Script.Cache.Activated = false
    end)
    --Script.Functions.WeaponChams(Child)
    if flags["rapid_fire"] then
        pcall(Script.Functions.Rapid, Child)
    end
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

Script.Functions.GetData = function(Plr)
    local Data = Script.Players[Plr]
    if not Data then
        Data = {}
        Data.Velocity = Vector3.new()
        if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
            Data.Position = Plr.Character.HumanoidRootPart.Position
            Data.OldPosition = Plr.Character.HumanoidRootPart.Position
        else
            Data.Position = Plr.Character.HumanoidRootPart.Position or Vector3.new()
            Data.OldPosition = Plr.Character.HumanoidRootPart.Position or Vector3.new()
        end
        Data.LastRefresh = tick()
        Data.LastSleep = 0
        Data.Positions = {}
        Data.ForcePosition = nil
        Data.LastValidPosition = nil
        Data.LastInVoid = nil
        Data.AltFlags = 0
        Script.Players[Plr] = Data
    end
    return Data
end
do -- init
	ESP.connection = RS.RenderStepped:Connect(ESP.Update)

    Script.Connections.Tracer = RS.RenderStepped:Connect(Script.Functions.UpdateTracer)
	Script.Cache.NextSelectionTime = 0
	Script.Connections.Aimbot = RS.Heartbeat:Connect(function()
		if flags["target_selected"] and flags['target_selected_bind']["active"] then
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
                        KnockedCheck = flags["knocked_check"],
                        DistanceCheck = flags["distance_check"],
					})
                    if not Target then
                        if flags["auto_shoot"] and ClientTool then
                            ClientTool:Deactivate()
                        end
                    end
				end
			end
            if (Target and Target.Character and Target.Character:FindFirstChild("HumanoidRootPart")) then 
                IsKnocked = Script.Functions.CheckKnocked(Target)
                IsDead =  Script.Functions.DeathCheck(Target)        
                if flags["auto_shoot"] and ClientTool and ClientTool:FindFirstChild("Ammo") and Target.Character:FindFirstChild(flags["silent_aim_bone"]) then
                    local CanFire =  not IsDead and not IsKnocked and (ClientTool.Name == "[Rifle]" or Target.Character:FindFirstChildOfClass("ForceField") == nil)
                    if CanFire and flags["rapid_fire"] then
                        LastShotTick = tick()
                        pcall(ClientTool.Activate, ClientTool)
                    elseif CanFire and not flags["rapid_fire"] and LastShotTick > ClientTool.ShootingCooldown.Value then
                        LastShotTick = tick()
                        pcall(ClientTool.Activate, ClientTool)
                    else
                        if Script.Cache.Activated then
                            pcall(ClientTool.Activate, ClientTool)
                            Script.Cache.Activated = false
                        end
                        pcall(ClientTool.Deactivate, ClientTool)
                    end
                end
                if Target and flags["aim_assist"] then
                    if flags["tool_check"] and not ClientTool then ManagerA:StopCurrent() return end
                    local Char = Target.Character
                    if not Char then ManagerA:StopCurrent() return end
                    local hrp = Char:FindFirstChild("HumanoidRootPart")
                    if not hrp then ManagerA:StopCurrent() return end
                    if not flags['auto_select'] then
                        if not hrp then ManagerA:StopCurrent() return end
                        if flags["visible_check"] and Char.Head.Transparency >= 0.4 then ManagerA:StopCurrent() return end
                        if flags["dead_check"] and Char:FindFirstChild("Humanoid") and Char.Humanoid.Health < 0.1 then ManagerA:StopCurrent() return end
                        if not Script.Functions.OnScreen(hrp) then ManagerA:StopCurrent() return end
                        if flags["wall_check"] then
                            if not Script.Functions.WallCheck(Char[flags["aim_assist_bone"]].Position, Char) then
                                ManagerA:StopCurrent() return  
                            end
                        end
                    end
                    local TargetCF = Char[flags["aim_assist_bone"]].Position
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
                        ManagerA:ChangeData({
                            TargetPosition = TargetPosition,
                            Smoothness = Smoothness,
                            Method = flags["aim_assist_curve_method"]
                        })
                    else
                        local CurrentPos = Uis:GetMouseLocation()
                        local Delta = TargetPosition - CurrentPos
                        mousemoverel(Delta.X, Delta.Y)
                    end
                    if flags["aim_assist_triggerbot"] and tick() - Script.Cache.LastTriggerTime > flags["aim_assist_triggerbot_delay_between_shots"] / 1000 then
                        local CurrentPos = Uis:GetMouseLocation()
                        local Distance = (TargetPosition - CurrentPos).Magnitude
                        if Distance < flags["aim_assist_triggerbot_distance"] then
                            mouse1click()
                            Script.Cache.LastTriggerTime = tick()
                        end
                    end
                else
                    if flags["aim_assist_smooth"] then
                        ManagerA:StopCurrent()
                    end
                end
                if flags["silent_aim"] and Target.Character:FindFirstChild(flags['silent_aim_bone']) then
                    if flags['resolver'] then
                        local hrp = Target.Character.HumanoidRootPart
                        local Data = Script.Functions.GetData(Target)
                        local Position = Target.Character[flags['silent_aim_bone']].Position
                        local Distance = (Data.OldPosition - Position)
                        table.insert(Data.Positions, Position)
                        local Sleeping = gethiddenproperty(hrp, "NetworkIsSleeping")
                        if Sleeping then
                            Data.LastSleep = tick()
                        end
                        Data.Velocity = Distance / (tick() - Data.LastRefresh)

                        if tick()-Data.LastSleep < 0.3 then
                            local OldClosestShoot = LastClosestShot
                            Data.ForcePosition = OldClosestShoot or nil
                            delay(0.3, function()
                                if Data.ForcePosition == OldClosestShoot then
                                    Data.ForcePosition = nil
                                end
                            end)
                        end

                        local InVoid = Position.Y > 1e5 or Position.Y < -1e3
                        if not InVoid then
                            Data.LastValidPosition = Position
                        end

                        if Data.LastInVoid ~= nil and Data.LastInVoid ~= InVoid then
                            Data.AltFlags = (Data.AltFlags or 0) + 1
                            Data.LastAlt = tick()
                        end

                        if tick() - (Data.LastAlt or 0) > 0.5 then
                            Data.AltFlags = 0
                        end
                        if (Data.AltFlags or 0) > 4 then
                            Data.ForcePosition =  Data.LastValidPosition
                        end
                        Data.LastInVoid = InVoid
                        Data.LastRefresh = tick()
                        Script.Players[Target] = Data
                    end
                end
            end
        end
	end)
    Script.Connections.Fov = RS.RenderStepped:Connect(Script.Functions.UpdateFov)

    Script.Connections.Mouvements = RS.PreSimulation:Connect(function (DeltaTime)
        if not Client.Character and Client.Character.Humanoid then return end
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
                -- 
                if Uis:IsKeyDown(Enum.KeyCode.S) then
                    z += 1
                end
                -- 
                if Uis:IsKeyDown(Enum.KeyCode.D) then
                    x += 1
                end
                -- 
                if Uis:IsKeyDown(Enum.KeyCode.A) then
                    x -= 1
                end
                -- 
                if Uis:IsKeyDown(Enum.KeyCode.Space) then
                    y += 1
                end
                -- 
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
            if humanoid and humanoid.MoveDirection.Magnitude > 0 then
                for i = 1, (flags["Cframe_Speed_Value"] / 10) * (DeltaTime * 160) do
                    if not flags["Cframe_Speed_Bind"]["active"] then
                        break
                    end
                    Client.Character:TranslateBy(humanoid.MoveDirection)
                end
            end
        end 

    end)

    Script.Connections.CFDesync = RS.Heartbeat:Connect(function (DeltaTime)
        local Character = Client and Client.Character
        if not Character then return end
        if Script.Desync.ForceCFrame then
            return
        end
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        if not RootPart then return end
        Script.Desync["Old_CFrame"] = RootPart.CFrame
        local DesyncPos
        local Debug = ""

        if flags["target_strafe"] and flags["target_strafe_bind"]["active"] and Target and Target.Character and Target.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = Target.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                IsKnocked = Script.Functions.CheckKnocked(Target)
                IsDead =  Script.Functions.DeathCheck(Target)  
                local Velocity = Script.Players[Target] and Script.Players[Target].Velocity or Vector3.new()
                local TargetMag = Velocity.Magnitude
                local clientBodyEffects = Character:FindFirstChild("BodyEffects")
                local ShouldStomp = flags["target_strafe_auto_stomp"]
                    and IsKnocked
                    and not IsDead
                    and not Target.Character:FindFirstChild("GRABBING_CONSTRAINT")
                    and not (clientBodyEffects and (clientBodyEffects.Reload.Value or clientBodyEffects.Attacking.Value))
                    and (TargetMag < 35 or Velocity.Y < 13)

                if not ShouldStomp then
                    Debug = "Strafe"
                    local newvector
                    local mode = flags["target_strafe_mode"]

                    if mode == "Random" then
                        newvector = Vector3.new(
                            math.random(-flags["target_strafe_distance"], flags["target_strafe_min_distance"]),
                            math.random(-flags["target_strafe_min_height"], flags["target_strafe_max_height"]),
                            math.random(-flags["target_strafe_distance"], flags["target_strafe_min_distance"])
                        )
                    elseif mode == "Circle" then
                        OrbitAngle = OrbitAngle + flags["target_strafe_speed"]
                        local radius = flags["target_strafe_radius"]
                        newvector = Vector3.new(
                            radius * math.cos(OrbitAngle),
                            flags["target_strafe_y_offset"],
                            radius * math.sin(OrbitAngle)
                        )
                    end

                    if newvector then
                        DesyncPos = targetHRP.CFrame + newvector
                    end
                else
                    Debug = "Stomp"
                    local Part = Target.Character:FindFirstChild("UpperTorso")
                    if Part then
                        DesyncPos = CFrame.new(Part.Position.X, Part.Position.Y + 2.7, Part.Position.Z)
                        ReplicatedStorage.MainEvent:FireServer("Stomp")
                    end
                end
            end
        end

        if flags["look_at"] and Target and Target.Character and Target.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = Target.Character.HumanoidRootPart.Position
            local lookat = CFrame.lookAt(Script.Desync["Old_CFrame"].Position, Vector3.new(targetPosition.X, Script.Desync["Old_CFrame"].Position.Y, targetPosition.Z))
            Script.Desync["Old_CFrame"] = lookat
            RootPart.CFrame = lookat
            if DesyncPos then
                DesyncPos = CFrame.lookAt(DesyncPos.Position, Vector3.new(targetPosition.X, DesyncPos.Position.Y, targetPosition.Z))
            end
        end

        if DesyncPos and not Script.Desync.ForceCFrame then
            Script.Desync["Real_Pos"] = DesyncPos
            if flags["target_strafe"] and flags["target_strafe_bind"]["active"] and not flags["target_strafe_server_sided"] and (Debug == "Strafe" or Debug == "Stomp") then
                RootPart.CFrame = DesyncPos
            else
                if flags["show_desync_pos"] then
                    SelfClone:SetPrimaryPartCFrame(DesyncPos)
                    if not VisualizeChams.Enabled then
                        VisualizeChams.Enabled = true
                    end
                end
                RootPart.CFrame = DesyncPos
                RS.RenderStepped:Wait()
                RootPart.CFrame = Script.Desync["Old_CFrame"]
            end
        else
            if flags["show_desync_pos"] and SelfClone.HumanoidRootPart.Position ~= Vector3.new(9959, 9999, 9990) then
                SelfClone:SetPrimaryPartCFrame(CFrame.new(9959, 9999, 9990))
                VisualizeChams.Enabled = false
            end
            Script.Desync["Real_Pos"] = RootPart.CFrame
        end
        
    end)

    Script.Connections.Misc = RS.RenderStepped:Connect(function ()
        if flags["NoFlashbang"] then
            local PGui = Client.PlayerGui

            if PGui then
                local MainScreenGui = PGui:FindFirstChild("MainScreenGui")
                if MainScreenGui then
                    local flashbang = MainScreenGui:FindFirstChild("whiteScreen")
                    if flashbang then flashbang:Destroy() end
                end 
            end
        end
        if Client.Character:FindFirstChild("FULLY_LOADED_CHAR") ~= nil then 
            if Script.Desync.ForceCFrame and Client.Character.HumanoidRootPart then
                local hrp = Client.Character.HumanoidRootPart
                hrp.CFrame = Script.Desync.ForceCFrame
                hrp.Velocity = Vector3.new(0,1.1,0)
                return
            end
            if flags["auto_armor"] then
                local armor = Client.Character:FindFirstChild("BodyEffects") and Client.Character:FindFirstChild("BodyEffects").Armor and Client.Character:FindFirstChild("BodyEffects").Armor.Value
                if armor < flags["auto_armor_threshold"] and Script.Desync.ForceCFrame == nil then
                    Script.Functions.PurshaceArmor()
                end
            end
        
            if flags["auto_fire_armor"] then
                local armor = Client.Character:FindFirstChild("BodyEffects") and Client.Character:FindFirstChild("BodyEffects").FireArmor and Client.Character:FindFirstChild("BodyEffects").FireArmor.Value
                if armor < flags["auto_fire_armor_threshold"] and Script.Desync.ForceCFrame == nil then
                    Script.Functions.PurshaceFireArmor()
                end
            end
            if flags["auto_mask"] then
                local mask = Client.Character:FindFirstChild("In-gameMask")
                if not mask then
                    local Mask = Client.Backpack:FindFirstChild("[Mask]") or Client.Character:FindFirstChild("[Mask]")
                    if not Mask then
                        Script.Functions.PurshaceMask()
                        local Mask = Client.Backpack:FindFirstChild("[Mask]") or Client.Character:FindFirstChild("[Mask]")
                        if Mask then
                            Client.Character.Humanoid:EquipTool(Mask)
                        end
                    else
                        Client.Character.Humanoid:EquipTool(Mask)
                    end
                end
                if Client.Character:FindFirstChild("[Mask]") then
                    Client.Character.Humanoid:UnEquipTool(Client.Character:FindFirstChild("[Mask]"))
                end
            end
            
        end
    end)

    Script.Hooks.index = hookmetamethod(game, '__index', newcclosure(function(self, index)
        if not checkcaller() then
            if index == "CFrame" then
                if self.Parent == Client.Character and tostring(self) == "HumanoidRootPart" then
                    if Script.Desync.ForceCFrame then
                        return Script.Desync.ForceCFrame 
                    end
                    return Script.Desync["Old_CFrame"]
                elseif self.Name == "Handle" and Script.Desync["Real_Pos"] then
                    local pos = Script.Desync["Real_Pos"]
                    Script.Desync["Real_Pos"] = nil
                    return pos
                end
            end
        end

        return Script.Hooks.index(self, index)
    end))

    Script.Hooks.newindex = hookmetamethod(game, '__newindex', newcclosure(function(self, key, value)
        if flags["NoSlowdown"] and key == 'WalkSpeed' then
            local MinWS = Uis:IsKeyDown(Enum.KeyCode.LeftShift) and 22 or 16
            if value < MinWS then 
                value = MinWS
            end
        end
        
        if not checkcaller() and flags["NoJumpCooldown"] and game.IsA(self, "Humanoid") and key == "JumpPower" then 
            return
        end

        if flags["Norecoil"] and tostring(getcallingscript()) == "Framework" and tostring(self):lower():find("camera") and tostring(key) == "CFrame" then
            return
        end
        
        return Script.Hooks.newindex(self, key, value)
    end))

    local vec0 = Vector3.new(0, 0, -1)
    Script.Hooks.Namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if not flags['silent_aim'] then
            return Script.Hooks.Namecall(self, ...)
        end
        local method = getnamecallmethod()
        local args = {...}
        local Event = args[1]
        if Target and Target.Character and not checkcaller() then
            if method == "FireServer" then
                if Event == "ShootGun" then
                    args[4] = Target.Character[flags["silent_aim_bone"]].Position
                    if flags["resolver"] then
                        local Data = Script.Functions.GetData(Target)
                        if Data.ForcePosition then
                            print(Data.ForcePosition)
                            args[4] = Data.ForcePosition
                        end
                    end
                    args[5] = Target.Character[flags["silent_aim_bone"]]
                    args[6] = vec0
                    return Script.Hooks.Namecall(self, unpack(args))
                elseif flags["PSilent"] and Event == "UpdateMousePosI2" then
                    args[2] = CMouse.Hit.p
                    return Script.Hooks.Namecall(self, unpack(args))
                end
            end
        end
        return Script.Hooks.Namecall(self, ...)
    end))
    
    Script.Hooks.MathR = hookfunction(getrenv().math.random, function(...)
        if checkcaller() then
            return Script.Hooks.MathR(...)
        end
        if flags["NoSpread"] and tostring(getcallingscript()):lower() == "gunclientshotgun" then
            return Script.Hooks.MathR(...) / 100000
        end
        return Script.Hooks.MathR(...)
    end)

    Script.Hooks.GetAim = hookfunction(require(ReplicatedStorage.Modules.GunHandler).getAim, function(origin, range)
        if flags["silent_aim"] and Target and Target.Character then
            local TargetPart = Target.Character:FindFirstChild(flags["silent_aim_bone"])
            if TargetPart then
                local pos = TargetPart.Position
                if flags["resolver"] then
                    local data = Script.Functions.GetData(Target)
                    if data and data.ForcePosition then
                        pos = data.ForcePosition
                    end
                end
                if flags["nearest_part"] then
                    pos = Script.Cache.CF
                end
                local vec = pos - origin
                return vec.Unit, vec.Magnitude
            end
        end

        return Script.Hooks.GetAim(origin, range)
    end)
    if Client.Character then
        Script.Functions.CharacterAdded(Client.Character)
    end
    Client.CharacterAdded:Connect(Script.Functions.CharacterAdded)
    

	for _,v in Players:GetPlayers() do 
		if v ~= Players.LocalPlayer then 
			ESP:create_object(v)
		end 
	end 

	ESP.player_added = Players.PlayerAdded:Connect(function(v)
		ESP:create_object(v)
	end)

	ESP.player_removed = Players.PlayerRemoving:Connect(function(v)
		ESP:remove_object(v)
	end)
	Aiming.open_tab() 
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
end