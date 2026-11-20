-- Consolidate locals to fix 'Out of local registers' error
local S = {
    Players = game:GetService('Players'),
    Workspace = game:GetService('Workspace'),
    ReplicatedStorage = game:GetService('ReplicatedStorage'),
    RunService = game:GetService('RunService'),
    TweenService = game:GetService('TweenService'),
    UserInputService = game:GetService('UserInputService'),
    HttpService = game:GetService('HttpService'),
    TeleportService = game:GetService('TeleportService'),
    Lighting = game:GetService('Lighting'),
    EncodingService = game:GetService('EncodingService')
}
local Players = S.Players
local LocalPlayer = S.Players.LocalPlayer
local Workspace = S.Workspace
local ReplicatedStorage = S.ReplicatedStorage
local RunService = S.RunService
local TweenService = S.TweenService
local UserInputService = S.UserInputService
local TeleportService = S.TeleportService
local Lighting = S.Lighting
local EncodingService = S.EncodingService

WallComboName = "WallCombo"
-- Register optimization: local LocalPlayer = game:GetService("Players").LocalPlayer
-- Register optimization: local EncodingService = game:GetService("EncodingService")
-- Register optimization: local UserInputService = game:GetService("UserInputService")
-- Register optimization: local RunService = game:GetService("RunService")
-- Register optimization: local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Register optimization: local Workspace = game:GetService("Workspace")
-- Register optimization: local Players = game:GetService("Players")
-- Register optimization: local LocalPlayer = Players.LocalPlayer
local playerChar = LocalPlayer.Character
local head = playerChar:FindFirstChild("Head")
-- Register optimization: local TeleportService = game:GetService("TeleportService")
-- Register optimization: local Lighting = game:GetService("Lighting")
-- Register optimization: local TweenService = game:GetService("TweenService")
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
-- Register optimization: local Players = game:GetService("Players")
-- Register optimization: local LocalPlayer = Players.LocalPlayer
-- Register optimization: local Players = game:GetService("Players")
local function renameObject(parent, oldName, newName)
    local object = parent:FindFirstChild(oldName)
    if object then
        object.Name = newName
    end
end
local function removeFriends(targets)
    if not targets or type(targets) ~= "table" then return end

    for i = #targets, 1, -1 do
        local targetPlayer = Players:FindFirstChild(targets[i])
        if targetPlayer and LocalPlayer:IsFriendsWith(targetPlayer.UserId) then
            table.remove(targets, i)
        end
    end
end
local function rejoinCurrentServer()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
end



local function resetCharacterForced()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if typeof(replicatesignal) == "function" and LocalPlayer.Kill then
        replicatesignal(LocalPlayer.Kill)
    elseif humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    else
        character:BreakJoints()
    end
end

FriendExcludeList = {}
local TARGET_USER_ID = game.Players.LocalPlayer.UserId

local function checkPlayerFriendship(player)
	if player == LocalPlayer then return end
	
	local success, isFriend = pcall(function()
		return player:IsFriendsWith(TARGET_USER_ID)
	end)
	
	if success and isFriend then
		if not table.find(FriendExcludeList, player) then
			table.insert(FriendExcludeList, player)
		end
	else
		local index = table.find(FriendExcludeList, player)
		if index then
			table.remove(FriendExcludeList, index)
		end
	end
end

local function checkAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		checkPlayerFriendship(player)
	end
end


task.spawn(checkAllPlayers)


task.spawn(function()
	while true do
		task.wait(1)
		checkAllPlayers()
	end
end)


Players.PlayerAdded:Connect(function(player)
	task.wait(0.5) 
	checkPlayerFriendship(player)
end)


Players.PlayerRemoving:Connect(function(player)
	local index = table.find(FriendExcludeList, player)
	if index then
		table.remove(FriendExcludeList, index)
	end
end)


local function isExcludedCharacter(character)
	if not character then return false end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return false end
	return table.find(FriendExcludeList, player) ~= nil
end

-- Register optimization: local Players = game:GetService("Players")
-- Register optimization: local LocalPlayer = Players.LocalPlayer


local TrackedConnections = {}

local BlockedIncomingRemotes = {}


local function argsContainText(args, searchText)
    if not searchText or searchText == "" then return true end
    
    for _, arg in pairs(args) do
        local argString = ""
        
        if typeof(arg) == "Instance" then
            argString = arg.Name
        elseif type(arg) == "string" or type(arg) == "number" then
            argString = tostring(arg)
        end

        
        if argString ~= "" and string.find(argString, tostring(searchText), 1, true) then
            return true
        end

        
        if type(arg) == "table" then
            if argsContainText(arg, searchText) then
                return true
            end
        end
    end
    return false
end


local function SetIncomingTrafficState(remoteInstance, shouldBlock, textFilter)
    if not remoteInstance:IsA("RemoteEvent") and not remoteInstance:IsA("UnreliableRemoteEvent") then 
        return 
    end

    if shouldBlock then
        local connections = getconnections(remoteInstance.OnClientEvent)
        
        if #connections > 0 then
            TrackedConnections[remoteInstance] = TrackedConnections[remoteInstance] or {}
            
            for _, connection in ipairs(connections) do
                if connection.Enabled then
                    
                    if not textFilter or textFilter == "" then
                        connection:Disable()
                        table.insert(TrackedConnections[remoteInstance], { Connection = connection, Type = "FullBlock" })
                    else
                        
                        local originalFunction = connection.Function
                        if originalFunction then
                            connection:Disable() 
                            
                            local filteredConnection = remoteInstance.OnClientEvent:Connect(function(...)
                                local args = {...}
                                
                                if not argsContainText(args, textFilter) then
                                    originalFunction(...)
                                end
                            end)

                            table.insert(TrackedConnections[remoteInstance], { 
                                OriginalConnection = connection, 
                                FilteredConnection = filteredConnection,
                                Type = "FilteredBlock" 
                            })
                        end
                    end
                end
            end
        end
    else
        
        local savedData = TrackedConnections[remoteInstance]
        if savedData then
            for _, item in ipairs(savedData) do
                if item.Type == "FullBlock" then
                    item.Connection:Enable()
                elseif item.Type == "FilteredBlock" then
                    item.FilteredConnection:Disconnect()
                    item.OriginalConnection:Enable()
                end
            end
            TrackedConnections[remoteInstance] = nil
        end
    end
end


game.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("RemoteEvent") or descendant:IsA("UnreliableRemoteEvent") then
        local config = BlockedIncomingRemotes[descendant.Name]
        if config then
            task.wait(0.1)
            SetIncomingTrafficState(descendant, true, config.TextFilter)
        end
    end
end)




local function BlockIncomingRemote(remoteName, textFilter)
    BlockedIncomingRemotes[remoteName] = { TextFilter = textFilter }
    
    for _, descendant in ipairs(game:GetDescendants()) do
        if descendant.Name == remoteName then
            SetIncomingTrafficState(descendant, true, textFilter)
        end
    end
end


local function UnblockIncomingRemote(remoteName)
    BlockedIncomingRemotes[remoteName] = nil
    
    for _, descendant in ipairs(game:GetDescendants()) do
        if descendant.Name == remoteName then
            SetIncomingTrafficState(descendant, false)
        end
    end
end
BlockIncomingRemote("EmoteStop", LocalPlayer.Name)
-- Register optimization: local Players = game:GetService("Players")
-- Register optimization: local RunService = game:GetService("RunService")

-- Register optimization: local LocalPlayer = Players.LocalPlayer
local MAX_DISTANCE = 20000 
local antiSLEnabled = false 


local PlayerCache = {}


local function InitializePlayerCache(player)
    if not PlayerCache[player] then
        PlayerCache[player] = {
            IsPhantom = false,
            OriginalTransparencies = {},
            OriginalDisplayType = Enum.HumanoidDisplayDistanceType.Viewer
        }
    end
end


local function MakePlayerPhantom(player, character)
    local data = PlayerCache[player]
    if not data or data.IsPhantom then return end
    data.IsPhantom = true
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        data.OriginalDisplayType = humanoid.DisplayDistanceType
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.Anchored = true
    end
    
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if not data.OriginalTransparencies[descendant] then
                data.OriginalTransparencies[descendant] = descendant.Transparency
            end
            descendant.Transparency = 1
        end
    end
end


local function RemovePlayerPhantom(player, character)
    local data = PlayerCache[player]
    if not data or not data.IsPhantom then return end
    data.IsPhantom = false
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = data.OriginalDisplayType or Enum.HumanoidDisplayDistanceType.Viewer
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.Anchored = false
    end
    
    for descendant, originalValue in pairs(data.OriginalTransparencies) do
        if descendant and descendant.Parent then
            descendant.Transparency = originalValue
        end
    end
    data.OriginalTransparencies = {}
end


local function SetAntiSLEnabled(state)
   antiSLEnabled = state
    
    if not antiSLEnabled then
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                RemovePlayerPhantom(player, player.Character)
            end
        end
        PlayerCache = {}
    end
end


RunService.RenderStepped:Connect(function()
    
    if not antiSLEnabled then return end
    
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then return end
    local localRoot = localCharacter.HumanoidRootPart
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer then
            local otherCharacter = otherPlayer.Character
            
            if otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart") then
                local otherRoot = otherCharacter.HumanoidRootPart
                
                InitializePlayerCache(otherPlayer)
                
                local distance = (localRoot.Position - otherRoot.Position).Magnitude
                local data = PlayerCache[otherPlayer]
                
                if distance > MAX_DISTANCE then
                    if not data.IsPhantom then
                        MakePlayerPhantom(otherPlayer, otherCharacter)
                    end
                else
                    if data.IsPhantom then
                        RemovePlayerPhantom(otherPlayer, otherCharacter)
                    end
                end
            end
        end
    end
end)


Players.PlayerRemoving:Connect(function(player)
    PlayerCache[player] = nil
end)


function TargetSystem_GetPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then 
            table.insert(names, p.Name) 
        end
    end
    table.sort(names, function(a, b) 
        return a < b
    end)
    return names
end
function excludeDeadPlayers(nameTable)
    local aliveOnly = {}
    
    for _, playerName in ipairs(nameTable) do
        
        local playerObj = Players:FindFirstChild(playerName)
        
        if playerObj then
            local character = playerObj.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                
                if humanoid and humanoid.Health > 0 then
                    table.insert(aliveOnly, playerName)
                end
            end
        end
    end
    
    return aliveOnly
end
-- Register optimization: local Players = game:GetService("Players")
-- Register optimization: local LocalPlayer = Players.LocalPlayer

local function filterAndSortPlayers(playerNamesTable, maxRange)
    if not playerNamesTable or type(playerNamesTable) ~= "table" then return {} end
    maxRange = maxRange or 100 
    
    local validTargets = {}
    local localCharacter = LocalPlayer.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

    
    for _, name in ipairs(playerNamesTable) do
        local targetPlayer = Players:FindFirstChild(name)
        
        if targetPlayer and targetPlayer ~= LocalPlayer and targetPlayer.Character then
            local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if localRoot and targetRoot then
                local distance = (localRoot.Position - targetRoot.Position).Magnitude
                
                
                if distance <= maxRange then
                    table.insert(validTargets, {
                        Name = name,
                        Distance = distance
                    })
                end
            end
        end
    end

    
    table.sort(validTargets, function(a, b)
        return a.Distance < b.Distance
    end)

    
    local sortedNames = {}
    for _, data in ipairs(validTargets) do
        table.insert(sortedNames, data.Name)
    end

    return sortedNames
end

function GetCharacterAbility(charName,folderName,Number)
    local characterFolder = ReplicatedStorage.Characters[charName]
    
    
    local targetFolder = characterFolder:FindFirstChild(folderName)
    if targetFolder then
        return targetFolder:FindFirstChild(Number)
    end
    return nil
end
function GetCurrentCharacter()
    local ok, res = pcall(function()
        return LocalPlayer.Data.Character.Value
    end)
    if ok and res then return res end
end
function generateActionNumber()
        return "Action" .. math.random(1000, 9999)
end
function getServerTime()
     return workspace:GetServerTimeNow()
end




ThemeManager:SetLibrary(Library)


ThemeManager:SetDefaultTheme({
    BackgroundColor = Color3.fromRGB(12, 12, 24),   
    MainColor = Color3.fromRGB(24, 24, 43),         
    OutlineColor = Color3.fromRGB(143, 107, 155),      
    
    
    AccentColor = Color3.fromRGB(238, 183, 255),     
    FontColor = Color3.fromRGB(255, 255, 255),       
    
    FontFace = "Code"                               
})

local Window = Library:CreateWindow({
    Title = "Nat Hub",
    Footer = "premium",
    Icon = 111109638259407,
    IconSize = UDim2.fromOffset(40, 40),
    BackgroundImage = "rbxassetid://135360458970142", 
    NotifySide = "Right",
    ShowCustomCursor = false,
})
-- Register optimization: local UserInputService = game:GetService("UserInputService")
local Tabs = {
    Main = Window:AddTab("Main", "triangle"),
    Legit = Window:AddTab("Legit", "user"),
    Extra = Window:AddTab("Extra", "plus"),
    Client = Window:AddTab("Client", "circle-user-round"),
    ["Configurations"] = Window:AddTab("Configurations", "settings"),
}
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()


SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

SaveManager:SetFolder("zxcintel")
SaveManager:SetSubFolder("zxc")

SaveManager:BuildConfigSection(Tabs["Configurations"])

-- ==========================================
-- MODIFICACIONES: ZETA HUB (Solución Definitiva)
-- ==========================================
local Options = Library.Options
local Toggles = Library.Toggles

local ConfigGroup = Tabs["Configurations"]:AddLeftGroupbox("Ajustes Zeta Hub", "settings")

-- Hotkey Nativo
ConfigGroup:AddLabel("Menú Hotkey"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})
Library.ToggleKeybind = Options.MenuKeybind

-- Selector de Temas con Reset de Motor de Temas
ConfigGroup:AddDropdown("ThemeColorSelector", {
    Values = { "Morado", "Rojo", "Azul", "Verde", "Amarillo", "Rosa", "Cian", "Blanco" },
    Default = 1,
    Text = "Color de la UI",
    Tooltip = "Fuerza el cambio de color de toda la interfaz",
    Callback = function(Value)
        local colors = {
            ["Morado"] = Color3.fromRGB(238, 183, 255),
            ["Rojo"] = Color3.fromRGB(255, 50, 50),
            ["Azul"] = Color3.fromRGB(0, 150, 255),
            ["Verde"] = Color3.fromRGB(0, 255, 120),
            ["Amarillo"] = Color3.fromRGB(255, 200, 0),
            ["Rosa"] = Color3.fromRGB(255, 150, 200),
            ["Cian"] = Color3.fromRGB(0, 255, 255),
            ["Blanco"] = Color3.fromRGB(255, 255, 255),
        }
        
        local selectedColor = colors[Value]
        if selectedColor then
            -- 1. Actualizar AccentColor global
            Library.AccentColor = selectedColor
            
            -- 2. FORZAR RE-APLICACIÓN TOTAL DEL TEMA
            pcall(function()
                ThemeManager:SetDefaultTheme({
                    BackgroundColor = Color3.fromRGB(12, 12, 24),
                    MainColor = Color3.fromRGB(24, 24, 43),
                    OutlineColor = Color3.fromRGB(143, 107, 155),
                    AccentColor = selectedColor,
                    FontColor = Color3.fromRGB(255, 255, 255),
                    FontFace = "Code"
                })
                ThemeManager:ApplyTheme(ThemeManager.Theme)
            end)
            
            -- 3. Barrido manual de objetos
            if Library.Registry then
                for _, object in next, Library.Registry do
                    for property, colorIdx in next, object.Properties do
                        if colorIdx == "AccentColor" then
                            object.Instance[property] = selectedColor
                        end
                    end
                end
            end
            
            Library:Notify("Zeta Hub: Color " .. Value .. " aplicado", 3)
        end
    end,
})

-- Botón de Cierre Total
ConfigGroup:AddButton({
    Text = "Cerrar Script",
    Func = function()
        Library:Unload()
    end,
    DoubleClick = true,
    Tooltip = "Cierra Zeta Hub permanentemente"
})

ConfigGroup:AddLabel("Usa RightShift para ocultar la UI.")


local TogglesGroupBox = Tabs.Main:AddLeftGroupbox("Toggles", "boxes")
local invulnerabilityModesActive = false



function wallcombodummy(Target)
    local function findUltimateBum()
        local characters = Workspace:FindFirstChild("Characters")
        if not characters then return nil end

        local npcs = characters:FindFirstChild("NPCs")
        if not npcs then return nil end

        local ultimateBum = npcs:FindFirstChild(Target)
        if ultimateBum and ultimateBum:IsA("Model") then
            return ultimateBum
        end
        return nil
    end

    
    local charName = GetCurrentCharacter()
    
    
    local wallComboAbility = ReplicatedStorage.Characters[charName]:FindFirstChild(WallComboName)
    if not wallComboAbility then 
        return false 
    end

    
    local ultimateBum = findUltimateBum()
    if ultimateBum == nil then 
        return false
    end

    
    local actionNumber = generateActionNumber()
    local serverTime = getServerTime()
    local randomId = math.random(100000, 999999)

    
    local remoteArgs = {
        wallComboAbility,
        
        "Characters:" .. charName .. ":" .. WallComboName,
        1,
        randomId,
        {
            HitboxCFrames = {nil},
            BestHitCharacter = ultimateBum,
            HitCharacters = {ultimateBum},
            Ignore = {[actionNumber] = {ultimateBum}},
            DeathInfo = {},
            Actions = {[actionNumber] = {}},
            HitInfo = {
                Blocked = false,
                IsFacing = true,
                IsInFront = true
            },
            BlockedCharacters = {},
            ServerTime = serverTime,
            FromCFrame = nil
        },
        "Action" .. math.random(1000, 9999)
    }

    
    local remote1Success = pcall(function()
        ReplicatedStorage.Remotes.Abilities.Ability:FireServer(wallComboAbility, randomId)
    end)

    local remote2Success = pcall(function()
        ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(remoteArgs))
    end)

    return true
end
TogglesGroupBox:AddToggle("HideWallcombo", {
    Text = "Hide Wallcombo",
    Tooltip = "Hides your WallCombo from everyone (and hides other people wallcombo too)",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        if Value then
            renameObject(game:GetService("ReplicatedStorage").Characters.Gon,"WallCombo","wall")
            renameObject(game:GetService("ReplicatedStorage").Characters.Nanami,"WallCombo","wall")
            renameObject(game:GetService("ReplicatedStorage").Characters.Mob,"WallCombo","wall")
            WallComboName = "wall"
        else
            renameObject(game:GetService("ReplicatedStorage").Characters.Gon,"wall","WallCombo")
            renameObject(game:GetService("ReplicatedStorage").Characters.Nanami,"wall","WallCombo")
            renameObject(game:GetService("ReplicatedStorage").Characters.Mob,"wall","WallCombo")
            WallComboName = "WallCombo"
        end
    end,
})
TogglesGroupBox:AddToggle("invulnerability", {
    Text = "invulnerability method 1",
    Tooltip = "grabs all dummies",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        
        if Value then
            startsinvulnerabilityMode()
        else
            stopsinvulnerabilityMode()
        end
    end,
})
function startsinvulnerabilityMode()
if invulnerabilityModesActive then return end
invulnerabilityModesActive = true

task.spawn(function()
        while invulnerabilityModesActive do
            wallcombodummy("The Ultimate Bum")
            wallcombodummy("Blocking Bum")
            wallcombodummy("Attacking Bum")
            task.wait(0.01)
        end
    end)
end

function stopsinvulnerabilityMode()
    invulnerabilityModesActive = false
end
local invulnerabilityMode2loop = false
local invulnerabilityMode2connection = nil
function invulnerabilityMode2start()
    if invulnerabilityMode2connection then return end 
    
    invulnerabilityMode2loop = true
    
    invulnerabilityMode2connection = RunService.Heartbeat:Connect(function()
        if not invulnerabilityMode2loop then
            if invulnerabilityMode2connection then
                invulnerabilityMode2connection:Disconnect()
                invulnerabilityMode2connection = nil
            end
            return
        end
        task.spawn(function()
            for i = 1,10 * 4 do
               fullcustom3(-9e9,90000,9e9)
                end
        end)
    end)
end


function invulnerabilityMode2stop()
    invulnerabilityMode2loop = false
    if invulnerabilityMode2connection then
        invulnerabilityMode2connection:Disconnect()
        invulnerabilityMode2connection = nil
    end
end
TogglesGroupBox:AddToggle("invulnerabilityModes2", {
    Text = "invulnerability method 2",
    Tooltip = "Makes you mostly unable to be hit (some stuff get disabled when enabled)",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        if Value then
            invulnerabilityMode2start()
            TargetSystemGroupBox:Hide()
            serverbullyingtoggle:SetVisible(false)
        else
            invulnerabilityMode2stop()
            TargetSystemGroupBox:Show()
            serverbullyingtoggle:SetVisible(true)
        end
    end,
})
Killfarmloop = false
Killfarmconnection = nil
function killFarmstart()
    if Killfarmconnection then return end
Killfarmloop = true
local Targetnumber = 1
local processingAttack = false
local deadBlacklist = {} 

Killfarmconnection = RunService.Heartbeat:Connect(function()
    if not Killfarmloop or processingAttack then return end
    
    local targets = TargetSystem_GetPlayerNames()
    local alivetargets = excludeDeadPlayers(targets)
    
    
    local strictlyAliveTargets = {}
    for _, name in ipairs(alivetargets) do
        if not deadBlacklist[name] then
            table.insert(strictlyAliveTargets, name)
        end
    end
    
    local targetsnumber = #strictlyAliveTargets
    
    if targetsnumber == 0 then 
        Targetnumber = 1
        return 
    end 
    
    if Targetnumber > targetsnumber then
        Targetnumber = 1
    end

    local targetName = strictlyAliveTargets[Targetnumber]
    local target = Players:FindFirstChild(targetName)
    
    
    local isTargetAlive = false
    if target and target.Character then
        local th = target.Character:FindFirstChild("Humanoid")
        if th then
            local hp = th:GetAttribute("Health") or th.Health
            if hp > 0 then
                isTargetAlive = true
            end
        end
    end

    if isTargetAlive then
        
        processingAttack = true
        
        fullcustom(target, 0)
        task.wait()
        adminAbuseWallcombo(target, 2)
        
        
        Targetnumber = Targetnumber + 1
        processingAttack = false
    else
        
        deadBlacklist[targetName] = true
        
        task.delay(3, function()
            deadBlacklist[targetName] = nil
        end)
        
        
        Targetnumber = Targetnumber + 1
        if Targetnumber > targetsnumber then
            Targetnumber = 1
        end
    end
end)
end
		
function killFarmstop()
if Killfarmconnection then
        Killfarmconnection:Disconnect()
        Killfarmconnection = nil
    end
    Killfarmloop = false
end
TogglesGroupBox:AddToggle("KillFarm", {
    Text = "Kill Farm[Beta]",
    Tooltip = "farms kills",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        
        if Value then
            killFarmstart()
        else
            killFarmstop()
        end
    end,
})
TargetSystemGroupBox = Tabs.Main:AddRightGroupbox("TargetSystem", "boxes")
local TargetSystemDropdown = TargetSystemGroupBox:AddDropdown("TargetSystemTarget", {
    Text = "Target",
    Values = TargetSystem_GetPlayerNames(),
    Default = 1,
    Multi = false,
})
task.spawn(function()
    while true do
        local updatedNames = TargetSystem_GetPlayerNames()
        TargetSystemDropdown:SetValues(updatedNames)
        task.wait(1) 
    end
end)
function SetlocalPlayerCFrame()
    local p = LocalPlayer
    local q = p and p.Character and p.Character.HumanoidRootPart and p.Character.HumanoidRootPart.CFrame or CFrame.new()
	localPlayerCFrame = q + Vector3.new(0,20,0)
end
function GetTargetCFrame(Target)
    local p = Target
    local q = p and p.Character and p.Character.HumanoidRootPart and p.Character.HumanoidRootPart.CFrame or CFrame.new()
	return q
end
function fullcustom(Target,Y)
    local targetCF =  GetTargetCFrame(Target)
	local servertime = workspace:GetServerTimeNow()
	local args = {
    servertime,
    targetCF + Vector3.new(0,Y,0),
    false,
	nil,
    [5] = game:GetService("Players").LocalPlayer.Character
	}
	ReplicatedStorage.Remotes.Replication.FullCustomReplicationUnreliable:FireServer(unpack(args, 1, 5))
end
function fullcustom2()
    local targetCF = localPlayerCFrame
	local servertime = workspace:GetServerTimeNow()
	local args = {
    servertime,
    targetCF,
    false,
	nil,
    [5] = game:GetService("Players").LocalPlayer.Character
	}
	ReplicatedStorage.Remotes.Replication.FullCustomReplicationUnreliable:FireServer(unpack(args, 1, 5))
end
function TargetsystemKillAura(Target)
		local charName = GetCurrentCharacter()
		local target = Target
        if not target then return end
		local actionNumber = generateActionNumber()
		local randomId = math.random(100000, 999999)
		local targetChar = target.Character
        local th = target.Character:FindFirstChild("Humanoid")
		if th then
		local hp = th:GetAttribute("Health")
			if hp > 0 then
		pcall(function() SetlocalPlayerCFrame() end)
		task.wait()
		pcall(function() fullcustom(Target,0) end)
		task.wait()
		pcall(function()
			local targetCF = GetTargetCFrame(Target)
			local servertime = getServerTime()
			local ability = ReplicatedStorage.Characters[charName]:FindFirstChild(WallComboName)
			local remoteArgs = {
			ability,
			"Characters:" .. charName .. ":" .. WallComboName,
			2,
			randomId,
			{
				HitboxCFrames = {targetCF,targetCF,targetCF,targetCF,targetCF,targetCF},
				BestHitCharacter = targetChar,
				HitCharacters = {targetChar,targetChar,targetChar},
				Ignore = {},
				DeathInfo = {},
				BlockedCharacters = {},
				HitInfo = {
					IsFacing = true,
					IsInFront = true
				},
				ServerTime = servertime,
				Actions = {},
				FromCFrame = targetCF
			},
			actionNumber,
			0
			}
			

			
			local remote1Success = pcall(function()
				ReplicatedStorage.Remotes.Abilities.Ability:FireServer(ability, randomId)
			end)

			local remote2Success = pcall(function()
				ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(remoteArgs))
			end)
		end)
		task.wait()
		pcall(function() fullcustom2() end)
    end
    end
end
function TargetSystemwallcombo(Target)

   local charName = GetCurrentCharacter()

		local target = Target
		if not target then return end

		local actionNumber = generateActionNumber()
		local randomId = math.random(100000, 999999)
        local th = target.Character:FindFirstChild("Humanoid")
		if th then
		local hp = th:GetAttribute("Health")
			if hp <= 0 then
				pcall(function() SetlocalPlayerCFrame() end)
				task.wait()
				pcall(function() fullcustom(Target,20) end)
				task.wait()
				local servertime = getServerTime()
				local ability = ReplicatedStorage.Characters[charName]:FindFirstChild(WallComboName)
				local remoteArgs = {
				ability,
				"Characters:" .. charName .. ":" .. WallComboName,
				1,
				randomId,
				{
					HitboxCFrames = {nil},
					BestHitCharacter = target.Character,
					HitCharacters = {target.Character},
					Ignore = {[actionNumber] = {target.Character}},
					DeathInfo = {},
					Actions = {[actionNumber] = {}},
					HitInfo = {
						Blocked = false,
						IsFacing = true,
						IsInFront = true
					},
					BlockedCharacters = {},
					ServerTime = servertime,
					FromCFrame = nil
				},
				actionNumber
			}

				
				local remote1Success = pcall(function()
					ReplicatedStorage.Remotes.Abilities.Ability:FireServer(ability, randomId)
				end)

				local remote2Success = pcall(function()
					ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(remoteArgs))
				end)
				task.wait()
				pcall(function() fullcustom2() end)
		end
	end
end
function UseAbilitiesTargetSystem(Target,Ability,Number)
		local charName = GetCurrentCharacter()
		local target = Target
		if not target then return end
		local targetChar = target.Character
		local targetCF = GetTargetCFrame(Target)
        local th = target.Character:FindFirstChild("Humanoid")
		if th then
		local hp = th:GetAttribute("Health")
			if hp > 0 then
                pcall(function() SetlocalPlayerCFrame() end)
                task.wait()
                pcall(function() fullcustom(Target,0) end)
                task.wait()
                 pcall(function()
                    local ability = GetCharacterAbility(charName,Ability,Number)
                    ReplicatedStorage.Remotes.Abilities.Ability:FireServer(ability,9000000)
                    local servertime = workspace:GetServerTimeNow()

                    local actions = {377,380,383,384,385,387,389}
                for i=1,7 do
                    local args = {
                        ability,
                        charName..":"..Ability..":"..Number,
                        i,
                        9000000,
                        {
                            HitboxCFrames = {targetCF,targetCF},
                            BestHitCharacter = targetChar,
                            HitCharacters = {targetChar},
                            Ignore = i>2 and {ActionNumber1={targetChar}} or {},
                            DeathInfo = {},
                            BlockedCharacters = {},
                            HitInfo = {
                                IsFacing = not (i==1 or i==2),
                                IsInFront = i<=2,
                                Blocked = i>2 and false or nil
                            },
                            ServerTime = servertime,
                            Actions = i>2 and {ActionNumber1={}} or {},
                            FromCFrame = targetCF
                        },
                        "Action"..actions[i],
                        i==2 and 0.1 or nil
                    }

                    if i==7 then
                        args[5].RockCFrame = targetCF
                        args[5].Actions = {
                            ActionNumber1 = {
                                [target.Name] = {
                                    StartCFrameStr = tostring(targetCF.X)..","..tostring(targetCF.Y)..","..tostring(targetCF.Z)..",0,0,0,0,0,0,0,0,0",
                                    ImpulseVelocity = Vector3.new(1901,-25000,291),
                                    AbilityName = "4",
                                    RotVelocityStr = "0,0,0",
                                    VelocityStr = "1.900635,0.010867,0.291061",
                                    Duration = 2,
                                    RotImpulseVelocity = Vector3.new(5868,-6649,-7414),
                                    Seed = math.random(1,1e6),
                                    LookVectorStr = "0.988493,0,0.151268"
                                }
                            }
                        }
                    end

                    ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(args))
                    end
                    pcall(function()
                    ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(
                        GetCharacterAbility(charName,Ability,Number)
                    )
                    end)
                end)
                task.wait()
                pcall(function() fullcustom2() end)
            end
            end
	end
TargetsystemKillloop = false
TargetsystemKillconnection = nil
function killaurastart()
	if TargetsystemKillconnection then return end
    TargetsystemKillloop = true
    TargetsystemKillconnection = RunService.Heartbeat:Connect(function()
        if not TargetsystemKillloop then return end
        TargetsystemKillAura(Players:FindFirstChild(TargetSystemDropdown.Value))
    end)
end
		
function killaurastop()
if TargetsystemKillconnection then
        TargetsystemKillconnection:Disconnect()
        TargetsystemKillconnection = nil
    end
    TargetsystemKillloop = false
end
targetSystemGrabloop = false
function targetSystemGrabloopstart()
	if targetSystemGrabloop then return end
	targetSystemGrabloop = true
	while targetSystemGrabloop do
        pcall(function() TargetSystemwallcombo(Players:FindFirstChild(TargetSystemDropdown.Value)) end)
		task.wait(0.01)
	end
end
		
function targetSystemGrabloopstop()
    targetSystemGrabloop = false
end
TargetSystemGroupBox:AddToggle("killthengrab", {
    Text = "Kill then grab",
    Tooltip = "Kills then keeps the target in an inf loop of wallcombos (makes you invulnerable while grabbing)",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
           if Value then
                killaurastart()
                targetSystemGrabloopstart()
           else
                killaurastop()
                targetSystemGrabloopstop()
           end
    end,
})
local function followTick()
			local targetPlayer = Players:FindFirstChild(TargetSystemDropdown.Value)
			local myChar = LocalPlayer.Character
			local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if not myRoot then return end
			local targetCF = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0.1, 4)
			pcall(function()
				require(LocalPlayer.PlayerScripts.Character.FullCustomReplication).Override(myChar, targetCF)
			end)
		end
Targetsystemtelportloop = false
Targetsystemtelportconnection = nil
function telportstart()
	if Targetsystemtelportconnection then return end
    Targetsystemtelportloop = true
    Targetsystemtelportconnection = RunService.Heartbeat:Connect(function()
        if not Targetsystemtelportloop then return end
        followTick()
    end)
end
		
function telportstop()
if Targetsystemtelportconnection then
        Targetsystemtelportconnection:Disconnect()
        Targetsystemtelportconnection = nil
    end
    Targetsystemtelportloop = false
end
TargetSystemGroupBox:AddToggle("telporttotarget", {
    Text = "telport to target",
    Tooltip = "telports behind the person",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
			if Value then
                telportstart()
            else
                telportstop()
            end
    end,
})
TargetSystemGroupBox:AddToggle("AbilitiesSpamTargetSystem", {
    Text = "Abilities Spam",
    Tooltip = "uses any move/moves you have chosen on them (works with Ultimate)",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
           if Value then
            AbilitiesSpamloopTargetSystemstart()
           else
            AbilitiesSpamloopTargetSystemstop()
           end
    end,
})
local AbilitiesTargetSystemDropdown = TargetSystemGroupBox:AddDropdown("AbilitiesTargetSystem", {
    Text = "Abilities",
    Values = { "Ability 1", "Ability 2", "Ability 3", "Ability 4" },
    Default = 1,
    Multi = true,
})
local DelayAbilitesspamTargetSystemSlider = TargetSystemGroupBox:AddSlider("DelayAbilitesspamTargetSystem", {
    Text = "Delay",
    Default = 0.01,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
})
AbilitiesSpamloopTargetSystems = false
function AbilitiesSpamloopTargetSystemstart()
	if AbilitiesSpamloopTargetSystems then return end
	AbilitiesSpamloopTargetSystems = true
	while AbilitiesSpamloopTargetSystems do
       local targetPlayer = Players:FindFirstChild(TargetSystemDropdown.Value)
        if not targetPlayer then
            task.wait(0.01) 
            continue       
        end
       local selected = AbilitiesTargetSystemDropdown.Value
       if selected["Ability 1"] then
        UseAbilitiesTargetSystem(targetPlayer,"Abilities",1)
        UseAbilitiesTargetSystem(targetPlayer,"Ultimates",1)
        task.wait(DelayAbilitesspamTargetSystemSlider.Value)
       end
       if selected["Ability 2"] then
        UseAbilitiesTargetSystem(targetPlayer,"Abilities",2)
        UseAbilitiesTargetSystem(targetPlayer,"Ultimates",2)
        task.wait(DelayAbilitesspamTargetSystemSlider.Value)
       end
       if selected["Ability 3"] then
        UseAbilitiesTargetSystem(targetPlayer,"Abilities",3)
        UseAbilitiesTargetSystem(targetPlayer,"Ultimates",3)
        task.wait(DelayAbilitesspamTargetSystemSlider.Value)
       end
       if selected["Ability 4"] then
        UseAbilitiesTargetSystem(targetPlayer,"Abilities",4)
        UseAbilitiesTargetSystem(targetPlayer,"Ultimates",4)
        task.wait(DelayAbilitesspamTargetSystemSlider.Value)
       end
    task.wait()
	end
end
		
function AbilitiesSpamloopTargetSystemstop()
    AbilitiesSpamloopTargetSystems = false
end
local AdminAbuseGroupBox = Tabs.Main:AddLeftGroupbox("Admin Abuse", "boxes")
function setGravity(enabled)
			local char = LocalPlayer.Character
			if not char then return end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = not enabled
					if not enabled then
						part.Velocity = Vector3.new(0, 0, 0)
						part.RotVelocity = Vector3.new(0, 0, 0)
					end
				end
			end
		end
function teleportupwards()
			local PlayerRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not PlayerRoot then return false end
			local upPos = PlayerRoot.Position + Vector3.new(0, 80, 0)
			pcall(function()
				require(LocalPlayer.PlayerScripts.Character.FullCustomReplication).Override(LocalPlayer.Character, CFrame.new(upPos))
			end)
			return true
		end
Serverbullyingloop = false
IgrnoreFriendsAdminAbuse = false
function Serverbullyingloopstart()
	if Serverbullyingloop then return end
	Serverbullyingloop = true
	while Serverbullyingloop do
       local Targets = TargetSystem_GetPlayerNames()
       if IgrnoreFriendsAdminAbuse then
        removeFriends(Targets)
       end
       local maxLimit = math.min(14, #Targets)
        for i=1,maxLimit do
        for j=1,20 do
        TargetsystemKillAura(Players:FindFirstChild(Targets[i]))
        end
        TargetSystemwallcombo(Players:FindFirstChild(Targets[i]))
		task.wait(0.01)
    end
    task.wait()
	end
end
		
function Serverbullyingloopstop()
    Serverbullyingloop = false
end
serverbullyingtoggle = AdminAbuseGroupBox:AddToggle("ServerBullying", {
    Text = "Server Bullying",
    Tooltip = "kills the entire server and keeps them in an inf loop of wallcombos (doesn't give you good invulnerability)",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
           if Value then
            teleportupwards()
            setGravity(false)
            Serverbullyingloopstart()
           else
            setGravity(true)
            Serverbullyingloopstop()
           end
    end,
})
AdminAbuseGroupBox:AddLabel("======================================", false)

function UseAbilities(Target,Ability,Number)
		local charName = GetCurrentCharacter()
		local target = Target
		if not target then return end
		local targetChar = target.Character
		local targetCF = GetTargetCFrame(Target)
        local th = target.Character:FindFirstChild("Humanoid")
                pcall(function()
                    local ability = GetCharacterAbility(charName,Ability,Number)
                    ReplicatedStorage.Remotes.Abilities.Ability:FireServer(ability,9000000)
                    local servertime = workspace:GetServerTimeNow()

                    local actions = {377,380,383,384,385,387,389}
                for i=1,7 do
                    local args = {
                        ability,
                        charName..":"..Ability..":"..Number,
                        i,
                        9000000,
                        {
                            HitboxCFrames = {targetCF,targetCF},
                            BestHitCharacter = targetChar,
                            HitCharacters = {targetChar},
                            Ignore = i>2 and {ActionNumber1={targetChar}} or {},
                            DeathInfo = {},
                            BlockedCharacters = {},
                            HitInfo = {
                                IsFacing = not (i==1 or i==2),
                                IsInFront = i<=2,
                                Blocked = i>2 and false or nil
                            },
                            ServerTime = servertime,
                            Actions = i>2 and {ActionNumber1={}} or {},
                            FromCFrame = targetCF
                        },
                        "Action"..actions[i],
                        i==2 and 0.1 or nil
                    }

                    if i==7 then
                        args[5].RockCFrame = targetCF
                        args[5].Actions = {
                            ActionNumber1 = {
                                [target.Name] = {
                                    StartCFrameStr = tostring(targetCF.X)..","..tostring(targetCF.Y)..","..tostring(targetCF.Z)..",0,0,0,0,0,0,0,0,0",
                                    ImpulseVelocity = Vector3.new(1901,-25000,291),
                                    AbilityName = "4",
                                    RotVelocityStr = "0,0,0",
                                    VelocityStr = "1.900635,0.010867,0.291061",
                                    Duration = 2,
                                    RotImpulseVelocity = Vector3.new(5868,-6649,-7414),
                                    Seed = math.random(1,1e6),
                                    LookVectorStr = "0.988493,0,0.151268"
                                }
                            }
                        }
                    end

                    ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(args))
                    end
                    pcall(function()
                    ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(
                        GetCharacterAbility(charName,Ability,Number)
                    )
                    end)
                end)
            end
function adminAbuseWallcombo(Target,number)
		local charName = GetCurrentCharacter()
		local target = Target
        if not target then return end
		local actionNumber = generateActionNumber()
		local randomId = math.random(100000, 999999)
		local targetChar = target.Character
		pcall(function()
			local targetCF = GetTargetCFrame(Target)
			local servertime = getServerTime()
			local ability = ReplicatedStorage.Characters[charName]:FindFirstChild(WallComboName)
			local remoteArgs = {
			ability,
			"Characters:" .. charName .. ":" .. WallComboName,
			number,
			randomId,
			{
				HitboxCFrames = {targetCF,targetCF,targetCF,targetCF,targetCF,targetCF},
				BestHitCharacter = targetChar,
				HitCharacters = {targetChar,targetChar,targetChar},
				Ignore = {},
				DeathInfo = {},
				BlockedCharacters = {},
				HitInfo = {
					IsFacing = true,
					IsInFront = true
				},
				ServerTime = servertime,
				Actions = {},
				FromCFrame = targetCF
			},
			actionNumber,
			0
			}
			

			
			local remote1Success = pcall(function()
				ReplicatedStorage.Remotes.Abilities.Ability:FireServer(ability, randomId)
			end)

			local remote2Success = pcall(function()
				ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(remoteArgs))
			end)
		end)
		task.wait()
end
		
function KillRangeloopstop()
    AbilitiesSpamloop = false
end
AdminAbuseGroupBox:AddToggle("KillAura", {
    Text = "KillAura",
    Tooltip = "Kills Everyone in Range with the Methods You Choose",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
           if Value then
            KillRangeloopstart()
           else
            KillRangeloopstop()
           end
    end,
})
AdminAbuseGroupBox:AddToggle("IgnoreFriendsAdminAbuse", {
    Text = "IgnoreFriends",
    Tooltip = "makes all of the function in admin abuse not target your friends",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
          IgrnoreFriendsAdminAbuse = Value
    end,
})
AdminAbuseGroupBox:AddToggle("ShowRangeCircle", {
    Text = "ShowRangeCircle",
    Tooltip = "shows the range you chosen",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
          if Value then
            startCircleTracker()
          else
             destroyCircle()
          end
    end,
})
local AdminAbuseDropdown = AdminAbuseGroupBox:AddDropdown("methodsKillAuraAdminAbuse", {
    Text = "Methods",
    Values = { "Abilities", "KillAura", "WallCombo"},
    Default = 2,
    Multi = false,
})
local KillAuraRangeSlider = AdminAbuseGroupBox:AddSlider("KillAuraRange", {
    Text = "Range",
    Default = 100,
    Min = 1,
    Max = 100,
    Rounding = 0,
})

local BringAllActive = false
local InfKillBypassActive = false

AdminAbuseGroupBox:AddToggle("BringAllPlayers", {
    Text = "Bring All Players",
    Tooltip = "Attracts all players to your position",
    Default = false,
    Callback = function(Value)
        BringAllActive = Value
        if Value then
            task.spawn(function()
                while BringAllActive do
                    local myChar = LocalPlayer.Character
                    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                p.Character:PivotTo(myChar.HumanoidRootPart.CFrame)
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

AdminAbuseGroupBox:AddToggle("InfKillBypass", {
    Text = "Infinite Kill (Bypass)",
    Tooltip = "Kills all players infinitely bypassing invincibility",
    Default = false,
    Callback = function(Value)
        InfKillBypassActive = Value
        if Value then
            task.spawn(function()
                while InfKillBypassActive do
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then
                            -- Bypass Invincibility (ForceField)
                            local ff = p.Character:FindFirstChildOfClass("ForceField")
                            if ff then ff:Destroy() end
                            
                            -- Kill logic (using existing TargetsystemKillAura)
                            task.spawn(function()
                                TargetsystemKillAura(p)
                            end)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

local CircleColor = Color3.fromRGB(90, 208, 255)
local RingThickness = 0.8 
local RingTransparency = 0.2 


local rangeCircle = nil
local rangeAdornment = nil
local updateCircleConnection = nil


 function destroyCircle()
    if updateCircleConnection then
        updateCircleConnection:Disconnect()
        updateCircleConnection = nil
    end
    if rangeCircle then
        rangeCircle:Destroy()
        rangeCircle = nil
    end
end


 function startCircleTracker()
    destroyCircle() 
    
    
    rangeCircle = Instance.new("Part")
    rangeCircle.Size = Vector3.new(1, 1, 1)
    rangeCircle.Transparency = 1 
    rangeCircle.Anchored = true
    rangeCircle.CanCollide = false
    rangeCircle.CanQuery = false
    rangeCircle.CanTouch = false
    rangeCircle.CastShadow = false
    rangeCircle.Parent = workspace
    
    
    rangeAdornment = Instance.new("CylinderHandleAdornment")
    rangeAdornment.Adornee = rangeCircle
    rangeAdornment.AlwaysOnTop = true 
    rangeAdornment.Height = 0.05 
    rangeAdornment.Color3 = CircleColor
    rangeAdornment.Transparency = RingTransparency
    rangeAdornment.Parent = rangeCircle
    
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    
    updateCircleConnection = RunService.RenderStepped:Connect(function()
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        if not hrp then return end
        
        
        raycastParams.FilterDescendantsInstances = {character, rangeCircle}
        
        
        local rayOrigin = hrp.Position
        local rayDirection = Vector3.new(0, -50, 0)
        local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        
        local targetPosition
        if raycastResult then
            targetPosition = raycastResult.Position
        else
            targetPosition = hrp.Position - Vector3.new(0, 2.9, 0)
        end
        
        
        local currentRadius = KillAuraRangeSlider.Value
        
        
        rangeAdornment.Radius = currentRadius
        rangeAdornment.InnerRadius = currentRadius - RingThickness 
        
        
        rangeAdornment.Color3 = CircleColor
        rangeAdornment.Transparency = RingTransparency
        
        
        
        rangeCircle.CFrame = CFrame.new(targetPosition + Vector3.new(0, 0.05, 0)) * CFrame.Angles(math.rad(90), 0, 0)
    end)
end
AbilitiesSpamloop = false
function KillRangeloopstart()
	if AbilitiesSpamloop then return end
	AbilitiesSpamloop = true
	while AbilitiesSpamloop do
       local Targets = TargetSystem_GetPlayerNames()
       Targets = filterAndSortPlayers(Targets,KillAuraRangeSlider.Value)
       if IgrnoreFriendsAdminAbuse then
        removeFriends(Targets)
       end
       local maxLimit = math.min(14, #Targets)
       for i=1,maxLimit do
       local targetPlayer = Targets[i] and Players:FindFirstChild(Targets[i])
        if not targetPlayer then
            task.wait(0.01) 
            continue       
        end
       local selected = AdminAbuseDropdown.Value
       if selected == "Abilities" then
        UseAbilities(targetPlayer,"Abilities",1)
        UseAbilities(targetPlayer,"Ultimates",1)
         UseAbilities(targetPlayer,"Abilities",2)
        UseAbilities(targetPlayer,"Ultimates",2)
         UseAbilities(targetPlayer,"Abilities",3)
        UseAbilities(targetPlayer,"Ultimates",3)
         UseAbilities(targetPlayer,"Abilities",4)
        UseAbilities(targetPlayer,"Ultimates",4)
        task.wait(0.05)
       end
       if selected == "KillAura" then
        adminAbuseWallcombo(targetPlayer,2)
        task.wait()
       end
       if selected == "WallCombo" then
        adminAbuseWallcombo(targetPlayer,1)
        adminAbuseWallcombo(targetPlayer,2)
        task.wait(0.05)
       end
	end
    task.wait()
end
end
local AntiandLaggerGroupBox = Tabs.Main:AddRightGroupbox("Server Lagger & AntiSL", "boxes")
local AbilityFolder = workspace:WaitForChild("Map"):WaitForChild("Props"):WaitForChild("Ability")


local isDeletionEnabled = true 

local function cleanFolder(child)
	if isDeletionEnabled then
		child:Destroy()
	end
end


AbilityFolder.ChildAdded:Connect(cleanFolder)


for _, child in ipairs(AbilityFolder:GetChildren()) do
	if isDeletionEnabled then
		child:Destroy()
	end
end
AntiandLaggerGroupBox:AddToggle("Antilagger", {
    Text = "Anti-Serverlagger",
    Tooltip = "Counters all laggers (if you get lagged dm me with a clip)",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        if Value then
            BlockIncomingRemote("Ability")
            SetAntiSLEnabled(true)
            isDeletionEnabled = true
        else
            UnblockIncomingRemote("Ability")
            SetAntiSLEnabled(false)
            isDeletionEnabled = false
        end
    end,
})
AntiandLaggerGroupBox:AddLabel("======================================", false)
AntiandLaggerGroupBox:AddToggle("ServerLagger", {
    Text = "Serverlagger",
    Tooltip = "Lags using the methods you choose",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        if Value then
            ServerLaggerstart()
        else
            ServerLaggerstop()
        end
    end,
})
local ServerLaggerDropdown = AntiandLaggerGroupBox:AddDropdown("ServerLaggerDropdown", {
    Text = "Methods",
    Values = { "Abilities", "Dash", "WallCombo" },
    Default = 3,
    Multi = true,
})
function UseAbilitiesServerLagger(Ability,Number)
		local charName = GetCurrentCharacter()
		local target = LocalPlayer
		if not target then return end
		local targetChar = target.Character
		local targetCF = GetTargetCFrame(target)
        local th = target.Character:FindFirstChild("Humanoid")
                pcall(function()
                    local ability = GetCharacterAbility(charName,Ability,Number)
                    ReplicatedStorage.Remotes.Abilities.Ability:FireServer(ability,9000000)
                    local servertime = workspace:GetServerTimeNow()

                    local actions = {377,380,383,384,385,387,389}
                for i=1,7 do
                    local args = {
                        ability,
                        charName..":"..Ability..":"..Number,
                        i,
                        9000000,
                        {
                            HitboxCFrames = {targetCF,targetCF},
                            CustomInfo = {
                                Name = string.format("%.11f",  math.random(1000, 9999) + math.random()),
                                ProjectileCFrame =targetCF,
                                Material = Enum.Material.Ground,
                                Color = Color3.new(0.50196081399918, 0.32941177487373, 0.22745098173618),
                                CFrame = targetCF
                            },
                            HitCharacters = {},
                            Ignore = i>2 and {ActionNumber1={}} or {},
                            DeathInfo = {},
                            BlockedCharacters = {},
                            HitInfo = {},
                            ServerTime = servertime,
                            Actions = i>2 and {ActionNumber1={}} or {},
                            FromCFrame = targetCF
                        },
                        "Action"..actions[i],
                        i==2 and 0.1 or nil
                    }

                    if i==7 then
                        args[5].RockCFrame = targetCF
                        args[5].Actions = {
                            ActionNumber1 = {
                                [target.Name] = {
                                    StartCFrameStr = tostring(targetCF.X)..","..tostring(targetCF.Y)..","..tostring(targetCF.Z)..",0,0,0,0,0,0,0,0,0",
                                    ImpulseVelocity = Vector3.new(1901,-25000,291),
                                    AbilityName = "4",
                                    RotVelocityStr = "0,0,0",
                                    VelocityStr = "1.900635,0.010867,0.291061",
                                    Duration = 2,
                                    RotImpulseVelocity = Vector3.new(5868,-6649,-7414),
                                    Seed = math.random(1,1e6),
                                    LookVectorStr = "0.988493,0,0.151268"
                                }
                            }
                        }
                    end

                    ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(args))
                    end
                    pcall(function()
                    ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(
                        GetCharacterAbility(charName,Ability,Number)
                    )
                    end)
                end)
	end
local ServerLaggerSlider = AntiandLaggerGroupBox:AddSlider("ServerLaggerSlider", {
    Text = "Times Per Frame",
    Default = 1,
    Min = 1,
    Max = 10,
    Rounding = 0,
})
-- Register optimization: local RunService = game:GetService("RunService")

local UseAbilitiesServerLagger = UseAbilitiesServerLagger or function() end  
local wallcombodummy = wallcombodummy or function() end

ServerLaggerloop = false
ServerLaggerDashloop = false
ServerLaggerconnection = nil


function ServerLaggerstart()
    if ServerLaggerconnection then return end 
    
    ServerLaggerloop = true
    
    ServerLaggerconnection = RunService.Heartbeat:Connect(function()
        if not ServerLaggerloop then
            if ServerLaggerconnection then
                ServerLaggerconnection:Disconnect()
                ServerLaggerconnection = nil
            end
            return
        end
        
        
        local selected = ServerLaggerDropdown.Value
        local number = ServerLaggerSlider.Value
        task.spawn(function()
            for i = 1, number do
                if selected["Abilities"] then
                    pcall(UseAbilitiesServerLagger, "Abilities", 1)
                    pcall(UseAbilitiesServerLagger, "Abilities", 2)
                    pcall(UseAbilitiesServerLagger, "Abilities", 3)
                    pcall(UseAbilitiesServerLagger, "Abilities", 4)
                end
                
                if selected["WallCombo"] then
                    pcall(wallcombodummy, "The Ultimate Bum")
                    pcall(wallcombodummy, "Blocking Bum")
                    pcall(wallcombodummy, "Attacking Bum")
                end
                 if selected["Dash"] then
                    fullcustom3(-9e9, -5, 9e9)
                    task.wait()
                    fullcustom3(9e9, 5, -9e9)
			    end
            end
        end)
    end)
end


function ServerLaggerstop()
    ServerLaggerloop = false
    if ServerLaggerconnection then
        ServerLaggerconnection:Disconnect()
        ServerLaggerconnection = nil
    end
end
function fullcustom3(X,Y,Z)
    local hrp = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
    local targetCF = hrp.CFrame
	local servertime = workspace:GetServerTimeNow()
	local args = {
    servertime,
    targetCF + Vector3.new(X,Y,Z),
    false,
	nil,
    [5] = game:GetService("Players").LocalPlayer.Character
	}
	ReplicatedStorage.Remotes.Replication.FullCustomReplicationUnreliable:FireServer(unpack(args, 1, 5))
end
function dashlaggerLoopstart()
    if ServerLaggerDashloop then return end 
    ServerLaggerDashloop = true
    local selected = ServerLaggerDropdown.Value
    task.spawn(function()
        while ServerLaggerDashloop do
            if selected["Dash"] then
                    fullcustom3(-9e9, -5, 9e9)
                    task.wait()
                    fullcustom3(9e9, 5, -9e9)
			end
            task.wait()
        end
    end)
end

function dashlaggerLoopstop()
    ServerLaggerDashloop = false
end
local HitBoxGroupBox = Tabs.Legit:AddLeftGroupbox("Hitbox", "boxes")
HitboxToggle = HitBoxGroupBox:AddToggle("HitBoxtoggle", {
    Text = "HitboxToggle",
    Tooltip = "enables hitbox",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        toggleHitbox(Value)
    end,
})
HitboxToggle:AddKeyPicker("HitBoxKeybind", {
    Text = "HitBox Keybind",
    Default = nil,
    Mode = "Toggle",            
    SyncToggleState = true,    
})

HitBoxGroupBox:AddToggle("Enhancertoggle", {
    Text = "Enhancertoggle",
    Tooltip = "Makes hitbox work better and if you change the multipler you get higher damage",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        toggleEnhancer(Value)
    end,
})
local HitboxLegitifytoggle = HitBoxGroupBox:AddToggle("HitboxLegitify", {
    Text = "HitboxLegitify",
    Tooltip = "makes stuff legit",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 
    Callback = function(Value)
        HitboxLegitfy = false
        HitboxLegitfy = Value
    end,
})
local HitboxIgnoreFriendstoggle = HitBoxGroupBox:AddToggle("HitboxIgnoreFriends", {
    Text = "HitboxIgnoreFriends",
    Tooltip = "Makes you unable to hit your friends",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        HitboxIgnoreFriends = false
        HitboxIgnoreFriends = Value
    end,
})
local HitboxVisualizertoggle = HitBoxGroupBox:AddToggle("HitboxVisualizer", {
    Text = "HitboxVisualizer",
    Tooltip = "shows the hitboxes with a square",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        HitboxVisualizer = false
        HitboxVisualizer = Value
    end,
})
local EnhancerHitboxSlider = HitBoxGroupBox:AddSlider("EnhancerHitboxSlider", {
    Text = "EnhancerMultiplier",
    Default = 0,
    Min = 0,
    Max = 50,
    Rounding = 0,
})
local HitBoxXSlider = HitBoxGroupBox:AddSlider("HitBoxXSlider", {
    Text = "X",
    Default = 40,
    Min = 0,
    Max = 250,
    Rounding = 0,
})
local HitBoxYSlider = HitBoxGroupBox:AddSlider("HitBoxYSlider", {
    Text = "Y",
    Default = 40,
    Min = 0,
    Max = 250,
    Rounding = 0,
})
local HitBoxZSlider = HitBoxGroupBox:AddSlider("HitBoxZSlider", {
    Text = "Z",
    Default = 40,
    Min = 0,
    Max = 250,
    Rounding = 0,
})
-- Register optimization: local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Register optimization: local Players = game:GetService("Players")
-- Register optimization: local LocalPlayer = Players.LocalPlayer

local core, originalHitBox
pcall(function() core = require(ReplicatedStorage:WaitForChild("Core", 9e9)) end)

local function initializeHitbox()
    if core and not originalHitBox then
        local combat = core.Get("Combat", "Hit")
        if combat and combat.Box then originalHitBox = combat.Box end
    end
end

local function isCharacterBlocking(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and character:GetAttribute("Blocking") == true
end

function toggleHitbox(enabled)
    if not core then return end
    local combat = core.Get("Combat", "Hit")
    if not combat then return end
    
    if enabled then
        if not originalHitBox then initializeHitbox() end
        combat.Box = function(...)
            local args = {...}
            
            if not args[3] or type(args[3]) ~= "table" then
                return originalHitBox(...)
            end
            
            local modifiedParams = {}
            for k, v in pairs(args[3]) do
                modifiedParams[k] = v
            end
            
            -- Apply custom hitbox size
            local originalSize = modifiedParams.Size or Vector3.new(0, 0, 0)
            local newSize = Vector3.new(
                originalSize.X + HitBoxXSlider.Value,
                originalSize.Y + HitBoxYSlider.Value,
                originalSize.Z + HitBoxZSlider.Value
            )
            modifiedParams.Size = newSize
            
            -- Visualizer logic
            if HitboxVisualizer then
                local cf = modifiedParams.CFrame or modifiedParams.cf or modifiedParams.Frame
                if not cf and typeof(args[2]) == "CFrame" then
                    cf = args[2]
                elseif not cf and typeof(args[2]) == "Instance" and args[2]:IsA("BasePart") then
                    cf = args[2].CFrame
                end
                if not cf then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    cf = hrp and hrp.CFrame or CFrame.new()
                end
                
                local p = Instance.new("Part")
                p.Name = "HitboxVisualizer"
                p.Anchored = true
                p.CanCollide = false
                p.Material = Enum.Material.ForceField
                p.Color = Color3.fromRGB(90, 208, 255)
                p.Transparency = 0.4
                p.Size = newSize
                p.CFrame = cf
                p.CastShadow = false
                p.Parent = workspace
                
                game:GetService("Debris"):AddItem(p, 0.08)
            end
            
            -- Run original hitbox query with modified parameters
            local bestTarget, validTargets, blockedTargets = originalHitBox(args[1], args[2], modifiedParams)
            
            if not blockedTargets then
                blockedTargets = {}
            end
            
            -- Check if move is unblockable natively
            local isUnblockable = modifiedParams.RespectBlock == false or modifiedParams.Unblockable
            
            -- Safe block post-filter (Prevents "blocking from everywhere" without breaking front dashes)
            if not isUnblockable and validTargets and type(validTargets) == "table" then
                for i = #validTargets, 1, -1 do
                    local target = validTargets[i]
                    local blocked = false
                    pcall(function()
                        if type(isCharacterBlocking) == "function" then
                            blocked = isCharacterBlocking(target)
                        end
                    end)
                    
                    if blocked then
                        local isFacingYou = true
                        pcall(function()
                            if combat.IsInFront then
                                isFacingYou = combat.IsInFront(target, true, modifiedParams)
                            end
                        end)
                        
                        -- If they are blocking but NOT facing you, strip from blocked and treat as a regular hit
                        if not isFacingYou then
                            table.remove(validTargets, i)
                            local blockIdx = table.find(blockedTargets, target)
                            if blockIdx then
                                table.remove(blockedTargets, blockIdx)
                            end
                            table.insert(validTargets, target)
                        end
                    end
                end
            end
            
            -- Handle friend/exclusion filters if enabled
            if HitboxIgnoreFriends and validTargets and type(validTargets) == "table" then
                for i = #validTargets, 1, -1 do
                    if isExcludedCharacter(validTargets[i]) then
                        table.remove(validTargets, i)
                    end
                end
            end
            
            if HitboxIgnoreFriends and bestTarget and isExcludedCharacter(bestTarget) then
                bestTarget = validTargets and validTargets[1] or nil
            end
            
            return bestTarget, validTargets, blockedTargets
        end
    elseif originalHitBox then
        combat.Box = originalHitBox
    end
end

local originalHitProcess = nil

local function enableEnhancer()
    local ok_hit, hit = pcall(function() return require(Players.LocalPlayer.PlayerScripts.Combat.Hit) end)
    if not ok_hit or type(hit) ~= "table" or type(hit.Process) ~= "function" then
        return
    end
    
    if not originalHitProcess then
        originalHitProcess = hit.Process
    end
    
    hit.Process = function(...)
        local bestTarget, validTargets, blockedTargets = originalHitProcess(...)
        
        if HitboxIgnoreFriends then
            if bestTarget and isExcludedCharacter(bestTarget) then
                bestTarget = nil
            end
            if validTargets and type(validTargets) == "table" then
                for i = #validTargets, 1, -1 do
                    if isExcludedCharacter(validTargets[i]) then
                        table.remove(validTargets, i)
                    end
                end
            end
        end
        
        if not validTargets or #validTargets == 0 then
            return bestTarget, validTargets, blockedTargets
        end
        
        pcall(function()
            if EnhancerHitboxSlider.Value == 0 then
                ReplicatedStorage.Remotes.Abilities.Ability:FireServer(nil, 69)
                ReplicatedStorage.Remotes.Combat.Action:FireServer(
                    nil,
                    "",
                    4,
                    69,
                    { BestHitCharacter = nil, HitCharacters = validTargets, Ignore = {}, Actions = {} }
                )
            else
                local charName = GetCurrentCharacter()
                local wallCombo = ReplicatedStorage.Characters[charName]:FindFirstChild(WallComboName)
                if wallCombo then
                    for i = 1, EnhancerHitboxSlider.Value do
                        ReplicatedStorage.Remotes.Abilities.Ability:FireServer(wallCombo, 69)
                        ReplicatedStorage.Remotes.Combat.Action:FireServer(
                            wallCombo,
                            "",
                            4,
                            69,
                            { BestHitCharacter = nil, HitCharacters = validTargets, Ignore = {}, Actions = {} }
                        )
                    end
                end
            end
        end)
        
        return bestTarget, validTargets, blockedTargets
    end
end
		
		local function disableEnhancer()
			if originalHitProcess then
				local ok, hit = pcall(function() return require(game:GetService("Players").LocalPlayer.PlayerScripts.Combat.Hit) end)
				if ok then
					hit.Process = originalHitProcess
				end
			end
		end
		
		 function toggleEnhancer(enabled)
			if enabled then
				enableEnhancer()
			else
				disableEnhancer()
			end
		end
        toggleEnhancer(false)
local LegitTogglesGroupBox = Tabs.Legit:AddRightGroupbox("Legit Toggles", "boxes")
local DEBUG = true
local originalRunAttack = nil
local runAttackHooked = false
local targetRunAttackFunc = nil


_G.LegitKombatActive = false

local function scanner(funcname)
    local targetScript = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Combat"):WaitForChild("Dash")
    for i, v in pairs(getgc(true)) do
        if typeof(v) == "function" then
            
            local success, env = pcall(getfenv, v)
            if success and env and env.script == targetScript then
                local infoSuccess, info = pcall(debug.getinfo, v)
                if infoSuccess and info and info.name == funcname then
                    return v
                end
            end
        end
    end
    return nil
end

local punchAnimation = scanner("punchAnimation")
local vfx = scanner("vfx")


function customRunAttack(p_u_105, p_u_106, p107, p108)
    
    if not _G.LegitKombatActive then
        if originalRunAttack then
            return originalRunAttack(p_u_105, p_u_106, p107, p108)
        end
        return
    end

    local v_u_1 = require(game.ReplicatedStorage:WaitForChild("Core"))
    local v109 = v_u_1.Services.Camera.CFrame
    local v110 = os.clock()
    local v_u_111 = tostring(v110)
    local v112 = 0
    local v_u_113 = 0
    local v_u_114 = 0
    local v_u_115 = 0
    local v_u_116, v_u_117, v_u_118, v_u_119, v_u_120
    local v121, v122
    local v_u_13, v_u_12 = false, false

    local function v_u_135(p123, p124, p125, p126, p127)
        local v128 = v_u_1.Get("Combat", "Ragdoll").GetRagdollFrame(p123)
        local v129 = v_u_1.Get("Character", "FullCustomReplication").GetCFrame(p_u_105)
        local v130 = v_u_1.Get("Character", "FullCustomReplication").GetCFrame(p123)
        local v131 = not p125
        if not v131 then
            if v129 and v130 then
                local v132 = p124 + v129.Position.Y - v130.Position.Y
                v131 = math.abs(v132) < p125
            end
        end
        local v133 = not p126
        if v133 then
            v128 = v133
        elseif v128 then
            v128 = v128.Velocity.Y < 0
        end
        local v134 = not p127
        if v134 then
            v130 = v134
        elseif v129 and v130 then
            v130 = v130.Position.Y > v129.Position.Y
        end
        if v131 then
            if not v128 then
                v130 = v128
            end
        else
            v130 = v131
        end
        v_u_120 = v130
        return v_u_120
    end

    local function v140(p136, p137)
        local v138 = v_u_1.Get("Combat", "Ragdoll").GetRagdollFrame(p136)
        local v139 = v_u_1.Get("Combat", "Ragdoll").UpVelocities[p136]
        if v138 then
            if v138.Velocity.Y < 0 and v139 then
                v139 = v139 > 1 and p137.CollisionGroup ~= "NoCharacterCollisions"
            else
                v139 = false
            end
        end
        return v139
    end

    local function v148(p141, p142, p143)
        if v_u_1.Library("Instance").Exists(p_u_106) then
            local v144, v145 = v_u_1.Get("Combat", "Hit").Box(nil, p_u_105, {
                Size = p141,
                Offset = p142,
                IgnoreJump = true,
                IgnoreRagdolls = "Ground",
                IgnoreKnockback = true,
                NoBaseValidation = true,
                RequireInFront = true,
                BlockHitsThroughWalls = true,
                CustomValidation = p143
            })
            v_u_117, v_u_116 = v144, v145
            local v146, v147 = v_u_1.Get("Combat", "Hit").Box(nil, p_u_105, {
                Size = p141,
                Offset = p142,
                IgnoreJump = true,
                IgnoreRagdolls = "Ground",
                IgnoreKnockback = true,
                RequireInFront = true,
                BlockHitsThroughWalls = true,
                CustomValidation = p143
            })
            v_u_119, v_u_118 = v146, v147
            return #v_u_116 > 0
        end
    end

    local v_u_149, v150, v151, v152_val = v_u_119, v_u_114, v_u_113, v122
    local v_u_153, v_u_154, v155 = v_u_120, v121, nil
    
    local function v159(p156, p157)
        local v158 = not p156:GetAttribute("Ragdoll") or v_u_135(p156, 2, 0.25, true)
        if v158 then
            v158 = p157.CollisionGroup ~= "NoCharacterCollisions"
        end
        return v158
    end

    while true do
        task.wait()
        
        
        if not _G.LegitKombatActive then 
            break 
        end
        
        local v160 = v_u_1.Services.Camera.CFrame
        local _, v161, _ = v109:ToOrientation()
        local _, v162, _ = v160:ToOrientation()
        local v163 = v161 - v162
        local v164 = math.deg(v163)
        if v164 > 180 then
            v164 = v164 - 360
        elseif v164 < -180 then
            v164 = v164 + 360
        end

        v112 += v164
        v_u_113 = math.max(v151, v112)
        v_u_114 = math.min(v150, v112)
        v_u_115 = os.clock() - v110
        local v165 = p107 - v_u_115

        if v_u_115 > 0.2125 then
            v121 = v148(Vector3.new(1, 1, 1), CFrame.new(0, 7.5, -0.5), v140)
            v155 = v121 or v148(Vector3.new(5, 5, 4.5), CFrame.new(0, 0, -2), v159)
            v_u_154 = v121
        end

        if v155 or p108 < v_u_115 then
            local v_u_166 = v165 > 0 and true or v152_val
            local v167 = v155 or v148(Vector3.new(7.5, 5, 7), CFrame.new(0, 0, -2.75), v159)
            if v167 then
                v_u_1.Get("Character", "Move").SetJumpOverride("DashPunch", 0)
                task.delay(0.5, v_u_1.Get("Character", "Move").SetJumpOverride, "DashPunch", nil)
            end

            local function v188()
                local v182 = {
                    Guarantees = v_u_149,
                    Replace = function(p168)
                        local v169 = v_u_1.Get("Combat", "Knockback").CharacterPresets[p168] == "Uppercut" and 0.375 or 0.2625

                        local ok1, v170 = pcall(function() return v_u_1.Get("Combat", "Ragdoll").GetRagdoll(p168) end)
                        if not ok1 then v170 = nil end
                        local ok2, v170Frame = pcall(function() return v_u_1.Get("Combat", "Ragdoll").GetRagdollFrame(p168) end)
                        if not ok2 then v170Frame = nil end

                        local attrRagdoll = false
                        if p168 and p168.GetAttribute then
                            pcall(function() attrRagdoll = p168:GetAttribute("Ragdoll") end)
                        end

                        local isRagdolled = (v170 ~= nil) or (v170Frame ~= nil) or (attrRagdoll == true)

                        local v172 = nil
                        local ok4, gotCFrame = pcall(function() return p168 and v_u_1.Get("Character", "FullCustomReplication").GetCFrame(p168) end)
                        if ok4 and gotCFrame then
                            local tmp = p_u_106.CFrame:PointToObjectSpace(gotCFrame.Position)
                            local v174 = tmp.X * 180 / 2
                            v172 = p_u_106.CFrame * CFrame.Angles(0, math.rad(-math.clamp(v174, -180, 180)), 0)
                        end

                        local hasKB = false
                        if p168 and p168.GetAttribute then
                            local okKB, kbVal = pcall(function() return p168:GetAttribute("Knockback") end)
                            if okKB and kbVal then hasKB = true end
                        end

                        if isRagdolled then
                            return { ActionNumbers = {2, 6}, ForceDirection = v172 }
                        end

                        if v_u_115 < v169 then
                            if p168 and p168.SetAttribute then
                                pcall(function() p168:SetAttribute("Knockback", false) end)
                            end
                            return { ActionNumbers = {1, 6}, ForceDirection = nil }
                        end

                        local v179
                        if v_u_113 - v_u_114 > 180 then
                            v179 = not v170 or v_u_135(p168, 0, 2, nil, true)
                        else
                            v179 = false
                        end
                        local v180 = false
                        local v181 = v_u_166
                        if v181 then v181 = not v170 end

                        if v180 then
                            if v170 then v170 = v_u_154 end
                        else
                            v170 = v180
                        end
                        if v180 then v180 = not v170 end

                        if v_u_115 >= v169 then
                            pcall(function()
                                if p168 and p168.SetAttribute then p168:SetAttribute("Knockback", false) end
                            end)
                        end

                        local pick = 1
                        if hasKB then pick = 5
                        elseif v181 then pick = 4
                        elseif v180 then pick = 3
                        elseif v170 then pick = 2
                        else pick = 1
                        end

                        return { ActionNumbers = { pick, 6 }, ForceDirection = v181 and v172 }
                    end,
                    UseFromCFrame = v_u_166 and p_u_106.CFrame * CFrame.new(0, 0, -2) or nil
                }

                task.wait(0.15)
                v_u_12 = true
                local v183, v184, _, _, v185 = v_u_1.Get("Combat", "Action").Event(nil, p_u_105, "PunchDash", v_u_111, v182, 0)
                if v183 then
                    vfx("DashHit", v183, p_u_106.Position)
                    v_u_1.Get("Camera", "Shake").Shake(nil, nil, {
                        Amplitude = 1.25,
                        Frequency = 0.0875,
                        FadeInTime = 0.025,
                        FadeOutTime = 0.5
                    }, nil, p_u_105, table.unpack(v184))
                end
                local v186 = false
                for _, v187 in v185 and (v185.BlockedCharacters or {}) or {} do
                    if not table.find(v185.HitCharacters, v187) then
                        v186 = true
                    end
                end
                v_u_13 = v186
                v_u_12 = false
            end

            task.spawn(v188)
            if v165 > 0 then
                v_u_1.Services.Run.Heartbeat:Wait()
                task.wait(v165 + 0.025)
            end
            task.spawn(punchAnimation, p_u_105, v_u_111)
            return v165 > 0, v167
        end
        v150, v151, v109 = v_u_114, v_u_113, v160
    end
end


local function enableLegitKombat()
    _G.LegitKombatActive = true
    getgenv().LegitKombatEnabled = true
    
    
    if runAttackHooked then return end
    
    local targetScript = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Combat"):WaitForChild("Dash")
    for i, v in pairs(getgc(true)) do
        if typeof(v) == "function" then
            local success, env = pcall(getfenv, v)
            if success and env and env.script == targetScript then
                local infoSuccess, info = pcall(debug.getinfo, v)
                if infoSuccess and info and info.name == "runAttack" then
                    targetRunAttackFunc = v
                    originalRunAttack = hookfunction(v, customRunAttack)
                    runAttackHooked = true
                    break
                end
            end
        end
    end
end

local function disableLegitKombat()
    
    _G.LegitKombatActive = false
    getgenv().LegitKombatEnabled = false
end
DashHelperToggle = LegitTogglesGroupBox:AddToggle("Dashhelper", {
    Text = "Dashhelper",
    Tooltip = "makes loop dash easier and bone dash 100%",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        if Value then
            enableLegitKombat()
        else
            disableLegitKombat()
        end
    end,
})
DashHelperToggle:AddKeyPicker("DashHelperKeybind", {
    Text = "DashHelper Keybind",
    Default = nil,
    Mode = "Toggle",            
    SyncToggleState = true,    
})
-- Register optimization: local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActionRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("Action")
local AbilityCanceledRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Abilities"):WaitForChild("AbilityCanceled")


local RagdollPowerInstance = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Multipliers"):WaitForChild("RagdollPower")


local legitKombatEnabled2 = false
local lowRodEnabled = false
local lowRodPower = 50
local v = false
local loopThread = nil

local getnamecallmethod = getnamecallmethod
local typeof = typeof

local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    if method == "FireServer" then
        local args = {...}
        local changed = false
        
        -- Deep Surgical Low Rod for Ability 4
        if lowRodEnabled and self == ActionRemote then
            local abilityName = tostring(args[2])
            
            if string.find(abilityName, ":Abilities:4") or string.find(abilityName, ":WallCombo") then
                local mult = lowRodPower / 100
                
                local function deepModify(t)
                    if type(t) ~= "table" then return end
                    for k, v in pairs(t) do
                        if type(v) == "table" then
                            deepModify(v)
                        elseif typeof(v) == "Vector3" then
                            -- Escalar solo X y Z para mantener el "lift" (Y)
                            if string.find(tostring(k), "Velocity") or string.find(tostring(k), "Impulse") or string.find(tostring(k), "Force") then
                                t[k] = Vector3.new(v.X * mult, v.Y, v.Z * mult)
                                changed = true
                            end
                        elseif type(v) == "string" and (string.find(k, "Velocity") or string.find(k, "Impulse")) then
                            -- Modificar strings de velocidad (formato: "x,y,z")
                            local vx, vy, vz = v:match("([^,]+),([^,]+),([^,]+)")
                            if vx and vy and vz then
                                t[k] = tostring(tonumber(vx)*mult)..","..vy..","..tostring(tonumber(vz)*mult)
                                changed = true
                            end
                        end
                    end
                end

                for i = 1, #args do
                    if type(args[i]) == "table" then
                        deepModify(args[i])
                    end
                end
            end
        end

        -- Original Legit Kombat Logic
        if legitKombatEnabled2 then
            if self == ActionRemote then
                if args[2] == "Gon:Abilities:1" then
                    local data = args[5]
                    if typeof(data) == "table" and data.BestHitCharacter ~= nil then
                        v = (args[3] == 1) 
                    end
                end
            elseif self == AbilityCanceledRemote then
                local ability = args[1]
                if ability and ability.Parent and ability.Parent.Name == "Abilities" then
                    local grandParent = ability.Parent.Parent
                    if grandParent and grandParent.Name == "Gon" and ability.Name == "1" then
                        v = false
                    end
                end
            end
        end
        
        if changed then
            return old(self, unpack(args))
        end
    end

    return old(self, ...)
end)

setreadonly(mt, true)


local function enableLegitKombat2()
    if legitKombatEnabled2 then return end
    legitKombatEnabled2 = true
    v = false

    loopThread = task.spawn(function()
        while legitKombatEnabled2 do
            if RagdollPowerInstance then
                local targetValue = v and 70 or 100
                if RagdollPowerInstance.Value ~= targetValue then
                    RagdollPowerInstance.Value = targetValue
                end
            end
            task.wait(0.03) 
        end
    end)
end

local function disableLegitKombat2()
    legitKombatEnabled2 = false
    v = false
    if loopThread then
        task.cancel(loopThread)
        loopThread = nil
    end
    if RagdollPowerInstance then
        RagdollPowerInstance.Value = 100 
    end
end


lowrocktoggle = LegitTogglesGroupBox:AddToggle("Rockhelper", {
    Text = "Rockhelper",
    Tooltip = "does the low rock for you (spin to make it less obvious)",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        if Value then
            enableLegitKombat2()
        else
            disableLegitKombat2()
        end
    end,
})
lowrocktoggle:AddKeyPicker("lowrockKeybind", {
    Text = "lowrock Keybind",
    Default = nil,
    Mode = "Toggle",            
    SyncToggleState = true,    
})

LegitTogglesGroupBox:AddToggle("LowRodHelper", {
    Text = "Low Rod Helper",
    Tooltip = "Baja la fuerza solo de la Habilidad 4 para combos",
    Default = false,
    Callback = function(Value)
        lowRodEnabled = Value
    end
})

LegitTogglesGroupBox:AddSlider("LowRodPower", {
    Text = "Rod Power %",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        lowRodPower = Value
    end
})


-- Register optimization: local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local legitKombatEnabled3 = false

local function enableLegitKombat3()
    if legitKombatEnabled3 then return end
    legitKombatEnabled3 = true
    
    
    task.spawn(function()
        while legitKombatEnabled3 do
            
            local character = localPlayer.Character
            if character then
                character:SetAttribute("Block", true)
            end
            
            
            task.wait(0.03) 
        end
    end)
end

local function disableLegitKombat3()
    legitKombatEnabled3 = false
end


LegitTogglesGroupBox:AddToggle("lessEndlagonblock", {
    Text = "lessendlag block",
    Tooltip = "gives you less endlag on letting go of block (helpful)",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        if Value then
            enableLegitKombat3()
        else
            disableLegitKombat3()
        end
    end,
})
 autoDashActive = false

-- 1. Create the Toggle
 autodashtoggle = LegitTogglesGroupBox:AddToggle("autodash", {
    Text = "Auto Dash",
    Tooltip = "Spams Dashes As Long As Its On",
    Default = false, 
    Callback = function(Value)
        autoDashActive = Value
        
        if autoDashActive then
            task.spawn(function()
                local Core = require(game.ReplicatedStorage:WaitForChild("Core"))
                
                -- This loop will run as long as autoDashActive is true
                while autoDashActive do
                    Core.Library("Input").KeyDownInput("Dash")
                    task.wait()
                    Core.Library("Input").KeyUpInput("Dash")
                    task.wait() 
                end
            end)
        end
    end,
})

autodashtoggle:AddKeyPicker("AutoDashKeybind", {
    Text = "Auto Dash Keybind",
    Default = nil,
    Mode = "Hold",            
    SyncToggleState = true,    
})
LegitTogglesGroupBox:AddLabel("you hold the keybind\n to keep it going", false)
betterMovesActive = false
 uis = game:GetService("UserInputService")
 inputMovesConnection = nil

-- Create the Toggle
LegitTogglesGroupBox:AddToggle("BetterMoves", {
    Text = "Better Moves",
    Tooltip = "Makes move detection much better",
    Default = false, 
    Callback = function(Value)
        betterMovesActive = Value
        
        -- If turned ON, listen for key presses
        if betterMovesActive then
            local Core = require(game.ReplicatedStorage:WaitForChild("Core"))
            
            inputConnection = uis.InputBegan:Connect(function(input, gameProcessed)
                -- If the game is already using the chat/UI, ignore it
                if gameProcessed then return end
                
                -- Map keyboard keys 1 through 4 to their respective abilities
                local abilityMap = {
                    [Enum.KeyCode.One]   = "Ability1",
                    [Enum.KeyCode.Two]   = "Ability2",
                    [Enum.KeyCode.Three] = "Ability3",
                    [Enum.KeyCode.Four]  = "Ability4",
                }
                
                local abilityName = abilityMap[input.KeyCode]
                
                if abilityName then
                    -- Fire the down and up inputs for the matching ability
                    Core.Library("Input").KeyDownInput(abilityName)
                    task.wait()
                    Core.Library("Input").KeyUpInput(abilityName)
                end
            end)
        else
            if inputMovesConnection then
                inputMovesConnection:Disconnect()
                inputMovesConnection = nil
            end
        end
    end,
})

local ExtraSlidersGroupBox = Tabs.Extra:AddLeftGroupbox("ExtraSliders", "boxes")
local SpeedHackSlider = ExtraSlidersGroupBox:AddSlider("EnhancerHitboxSlider", {
    Text = "EnhancerMultiplier",
    Default = 1,
    Min = 1,
    Max = 4,
    Rounding = 0,
})
local function toggleSpeed(state)
        local character = LocalPlayer.Character
		local humanoid = character:WaitForChild("Humanoid")
		local rootPart = character:WaitForChild("HumanoidRootPart")
		if state then
			if character and humanoid then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
				humanoid.PlatformStand = false
			end
			speedConnection = RunService.Heartbeat:Connect(function()
				if character and rootPart then
					local moveDirection = humanoid.MoveDirection * SpeedHackSlider.Value
					rootPart.CFrame = rootPart.CFrame + moveDirection
				end
			end)
		else
			if speedConnection then speedConnection:Disconnect(); speedConnection = nil end
			if character and humanoid then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
				humanoid.PlatformStand = false
			end
		end
	end
ExtraSlidersGroupBox:AddToggle("SpeedHack", {
    Text = "SpeedHack",
    Tooltip = "self explanatory",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        toggleSpeed(Value)
    end,
})
local ExtraButtonsGroupBox = Tabs.Extra:AddRightGroupbox("ExtraButtons", "boxes")
if not _G.CurrentScriptID then
    _G.CurrentScriptID = math.random(100000, 999999)
end
local myScriptID = _G.CurrentScriptID

ExtraButtonsGroupBox:AddToggle("autoexeute", {
    Text = "auto execute on telport",
    Tooltip = "makes the script auto execute on telport",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)      
        if writefile then
            writefile("AutoExecuteConfig.txt", tostring(Value))
        end

        local queue = syn and syn.queue_on_teleport or queue_on_teleport

        
        if Value == false then
            if _G.ActiveQueueOwner == myScriptID then
                _G.ActiveQueueOwner = nil
            end
        end

        
        if queue and Value == true and _G.ActiveQueueOwner == nil then
            _G.ActiveQueueOwner = myScriptID 
            
            
            local queuePayload = [[
                local nextQueue = syn and syn.queue_on_teleport or queue_on_teleport
                if isfile and isfile("AutoExecuteConfig.txt") then
                    local savedState = readfile("AutoExecuteConfig.txt")
                    if savedState == "true" then
                        
                        if nextQueue then
                            nextQueue(...)
                        end
                        
                       loadstring(game:HttpGet(""))()
                    end
                end
            ]]

            
            queue(string.format("local payload = %q\n%s", queuePayload, queuePayload:gsub("nextQueue%(%.%.%.%)", "nextQueue(payload)")))
        end
    end,
})
ExtraButtonsGroupBox:AddToggle("autoblock", {
    Text = "auto block",
    Tooltip = "makes you always block even while m1ing",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
            local remoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("Block")
            autoblockActive = Value
			while autoblockActive do
				pcall(function()
					remoteEvent:FireServer(true)
				end)
				task.wait(0.1)
			end
    end,
})
ExtraButtonsGroupBox:AddToggle("scramblePing", {
    Text = "scramblePing",
    Tooltip = "gives you aura by making your ping skyrocket",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        scramblePingActive = Value
        
        if scramblePingActive then
            task.spawn(function()
                while scramblePingActive do
                   pcall(function()
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Services"):WaitForChild("Ping"):FireServer()
                    end)
                    task.wait(0) 
                end
            end)
        end
    end,
})
local multipliers = ReplicatedStorage.Settings.Multipliers
ExtraButtonsGroupBox:AddToggle("fast m1s", {Text = "faster m1s", Tooltip = "makes your m1 faster for trolling", Default = false, Disabled = false, Visible = true, Risky = false, Callback = function(Value) multipliers.MeleeSpeed.Value = Value and 135 or 100 end,})
ExtraButtonsGroupBox:AddToggle("NoStun", {Text = "No stun", Tooltip = "self explanatory", Default = false, Disabled = false, Visible = true, Risky = false, Callback = function(Value) ReplicatedStorage.Settings.Toggles.DisableHitStun.Value = Value end,})
ExtraButtonsGroupBox:AddToggle("LongerUltimate", {Text = "Longer Ultimate", Tooltip = "self explanatory", Default = false, Disabled = false, Visible = true, Risky = false, Callback = function(Value) ReplicatedStorage.Settings.Toggles.Endless.Value = Value end,})
ExtraButtonsGroupBox:AddToggle("instantUltimate", {Text = "instant Ultimate", Tooltip = "skips the animation of the Ultimate", Default = false, Disabled = false, Visible = true, Risky = false, Callback = function(Value) ReplicatedStorage.Settings.Toggles.InstantTransformation.Value = Value end,})
ExtraButtonsGroupBox:AddToggle("noSlowDowns", {Text = "No SlowDowns", Tooltip = "self explanatory", Default = false, Disabled = false, Visible = true, Risky = false, Callback = function(Value) ReplicatedStorage.Settings.Toggles.NoSlowdowns.Value = Value end,})
ExtraButtonsGroupBox:AddToggle("noStunOnMiss", {Text = "No StunOnMiss", Tooltip = "self explanatory", Default = false, Disabled = false, Visible = true, Risky = false, Callback = function(Value) ReplicatedStorage.Settings.Toggles.NoStunOnMiss.Value = Value end,})
ExtraButtonsGroupBox:AddToggle("AutoRagdoll", {Text = "Auto Ragdoll", Tooltip = "ragdolls on any M1", Default = false, Disabled = false, Visible = true, Risky = false, Callback = function(Value) multipliers.MeleeDamage.Value = Value and 10000000 or 100 end,})
ExtraButtonsGroupBox:AddToggle("Voidkill", {Text = "Void kill", Tooltip = "Anything that ragdolls sends to the void", Default = false, Disabled = false, Visible = true, Risky = false, Callback = function(Value) if Value then
            multipliers.RagdollPower.Value = 999999
            multipliers.KnockbackPower.Value = 10000
        else
            multipliers.RagdollPower.Value = 100
            multipliers.KnockbackPower.Value = 100
        end end,})
ExtraButtonsGroupBox:AddToggle("AutoClaimEmote", {Text = "Auto Claim Emote", Tooltip = "self explanatory", Default = false, Disabled = false, Visible = true, Risky = false, Callback = function(Value) while Value do 

local Event = game:GetService("ReplicatedStorage").Remotes.Combat.EmoteClaim
Event:FireServer() task.wait(1) end end,})
local WindowMenuKeybind = ExtraButtonsGroupBox:AddLabel("Menu bind"):AddKeyPicker("MyMenuKeybind", {
    Text = "Menu Keybind",
    Default = "RightShift",
    Mode = "Press",
    NoUI = true,
    Callback = function()
        Window:Toggle()
    end,
})

ExtraButtonsGroupBox:AddButton("ResetCharacter", function()
    resetCharacterForced()
end)
ExtraButtonsGroupBox:AddButton("RejoinServer", function()
    rejoinCurrentServer()
end)
local CustomizationGroupBox = Tabs.Client:AddLeftGroupbox("Customization", "boxes")
local AccessoriesDropDown = CustomizationGroupBox:AddDropdown("Accessories", {
    Text = "Accessories",
    Values = {
        "Frozen Gloves",
        "Chunin Exam Vest",
        "Devil's Eye",
        "Devil's Tail",
        "Devil's Wings",
        "Flower Wings",
        "Frozen Crown",
        "Frozen Tail",
        "Frozen Wings",
        "Garland Scarf",
        "Hades Helmet",
        "Halo",
        "Holiday Scarf",
        "Krampus Hat",
        "Red Kagune",
        "Rudolph Antlers",
        "Snowflake Wings",
        "Sorting Hat",
        "VIP Crown"
    },
    Default = nil,
    AllowNull = true,
    Searchable = true,
    Multi = true,
})

local player = game:GetService("Players").LocalPlayer
local accessoriesValue = player:WaitForChild("Data"):WaitForChild("AccessoriesEquipped")

AccessoriesDropDown:OnChanged(function(SelectedValues)
    local formattedAccessories = {}

    
    for item, isSelected in pairs(SelectedValues) do
        if isSelected == true then
            table.insert(formattedAccessories, "Accessories")
            table.insert(formattedAccessories, item)
        elseif type(item) == "number" and type(isSelected) == "string" then
            table.insert(formattedAccessories, "Accessories")
            table.insert(formattedAccessories, isSelected)
        end
    end

    
    local quotedList = {}
    for _, val in ipairs(formattedAccessories) do
        table.insert(quotedList, '"' .. tostring(val) .. '"')
    end

    
    accessoriesValue.Value = "[" .. table.concat(quotedList, ", ") .. "]"
end)
local AurasDropDown = CustomizationGroupBox:AddDropdown("Auras", {
    Text = "Auras",
    Values = {
        "Butterflies",
        "Blue Lightning",
        "Green Lightning",
        "Ki",
        "Northern Lights",
        "Purple Lightning",
        "Red Lightning",
        "Yellow Lightning"
    },
    Default = nil,
    AllowNull = true,
    Searchable = true,
    Multi = true,
})
local AurasValue = player:WaitForChild("Data"):WaitForChild("AurasEquipped")

AurasDropDown:OnChanged(function(SelectedValues)
    local FormattedAuras = {}

    
    for item, isSelected in pairs(SelectedValues) do
        if isSelected == true then
            table.insert(FormattedAuras, "Auras")
            table.insert(FormattedAuras, item)
        elseif type(item) == "number" and type(isSelected) == "string" then
            table.insert(FormattedAuras, "Auras")
            table.insert(FormattedAuras, isSelected)
        end
    end

    
    local quotedList = {}
    for _, val in ipairs(FormattedAuras) do
        table.insert(quotedList, '"' .. tostring(val) .. '"')
    end

    
    AurasValue.Value = "[" .. table.concat(quotedList, ", ") .. "]"
end)
local CapesDropDown = CustomizationGroupBox:AddDropdown("Capes", {
    Text = "Capes",
    Values = {
        "Christmas Lights",
        "Dracula",
        "Ice Lord",
        "Krampus",
        "Krampus Supreme",
        "Santa",
        "VIP",
        "Viking",
        "Webbed"
    },
    Default = nil,
    AllowNull = true,
    Searchable = true,
    Multi = true,
})
local CapesValue = player:WaitForChild("Data"):WaitForChild("CapesEquipped")

CapesDropDown:OnChanged(function(SelectedValues)
    local FormattedCapes = {}

    
    for item, isSelected in pairs(SelectedValues) do
        if isSelected == true then
            table.insert(FormattedCapes, "Capes")
            table.insert(FormattedCapes, item)
        elseif type(item) == "number" and type(isSelected) == "string" then
            table.insert(FormattedCapes, "Capes")
            table.insert(FormattedCapes, isSelected)
        end
    end

    
    local quotedList = {}
    for _, val in ipairs(FormattedCapes) do
        table.insert(quotedList, '"' .. tostring(val) .. '"')
    end

    
    CapesValue.Value = "[" .. table.concat(quotedList, ", ") .. "]"
end)
local localPlayer = Players.LocalPlayer

local VipColorLabel = CustomizationGroupBox:AddLabel("VipCapeColor")

VipColorLabel:AddColorPicker("VipCapeColorPicker", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "VIP Cape Color",
    Transparency = nil,
    Callback = function(Value)
        
        if not localPlayer then return end

        local characters = workspace:FindFirstChild("Characters")
        if not characters then return end

        local players = characters:FindFirstChild("Players")
        if not players then return end

        local playerChar = players:FindFirstChild(localPlayer.Name)
        if not playerChar then return end

        local capesVIP = playerChar:FindFirstChild("CapesVIP")
        if not capesVIP then return end

        local handle = capesVIP:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            handle.Color = Value
        end
    end
})
-- Register optimization: local Players = game:GetService("Players")
-- Register optimization: local LocalPlayer = Players.LocalPlayer


local function getCharacter()
    if not LocalPlayer then return nil end

    local characters = workspace:FindFirstChild("Characters")
    if characters then
        local playersFolder = characters:FindFirstChild("Players")
        if playersFolder then
            local char = playersFolder:FindFirstChild(LocalPlayer.Name)
            if char then return char end
        end
    end

    return LocalPlayer.Character
end

CustomizationGroupBox:AddInput("VIPdecalId", {
    Default = "111109638259407",
    Numeric = true,
    Finished = true,
    ClearTextOnFocus = false,
    Text = "VIP Decal ID",
    Tooltip = "Put the decal ID and press enter",
    Placeholder = "Put decal ID and press enter",

    Callback = function(Value)
        if not Value or Value == "" then return end

        task.spawn(function()
            local character = getCharacter()
            if not character then return end

            local capeModel = character:FindFirstChild("CapesVIP")
            if not capeModel then return end

            local handle = capeModel:FindFirstChild("Handle")
            if not handle then return end

            
            local textureUrl = "rbxthumb://type=Asset&id=" .. tostring(Value) .. "&w=420&h=420"

            
            for _, child in ipairs(handle:GetChildren()) do
                if child:IsA("SurfaceAppearance") or child:IsA("Texture") then
                    child:Destroy()
                elseif child:IsA("Decal") and child.Name ~= "MyCustomDecal" then
                    child.Transparency = 1
                    child.Texture = ""
                end
            end

            
            local myDecal = handle:FindFirstChild("MyCustomDecal")
            if not myDecal then
                myDecal = Instance.new("Decal")
                myDecal.Name = "MyCustomDecal"
                myDecal.Face = Enum.NormalId.Back
                myDecal.Parent = handle
            end

            myDecal.Texture = textureUrl
            myDecal.Transparency = 0
            myDecal.Color3 = Color3.fromRGB(255, 255, 255)

            
            local specialMesh = handle:FindFirstChildOfClass("SpecialMesh")
            if specialMesh then
                specialMesh.TextureId = textureUrl
            end
        end)
    end,
})
-- Register optimization: local Players = game:GetService("Players")
-- Register optimization: local LocalPlayer = Players.LocalPlayer

local isEnabled = false
local originalEmotes = ""
local emotesValue = nil


task.spawn(function()
    local dataFolder = LocalPlayer:WaitForChild("Data", 10)
    if dataFolder then
        
        emotesValue = dataFolder:WaitForChild("EmoteEquipped", 10)
    end
    
    local passesFolder = LocalPlayer:WaitForChild("Passes", 10)
    if passesFolder then
        local allEmoteSlots = passesFolder:WaitForChild("AllEmoteSlots", 10)
        if allEmoteSlots then
            allEmoteSlots.Value = true
        end
    end
end)

local EmotesandUltAurasGroupBox = Tabs.Client:AddRightGroupbox("Emotes & Ult Aura", "boxes")
local Emote1DropDown


local function applyEmotes(dropdownValue)
    if not isEnabled or not emotesValue then return end

    local selectedEmotes = {}
    if type(dropdownValue) == "table" then
        for emoteName, isSelected in pairs(dropdownValue) do
            if isSelected then
                table.insert(selectedEmotes, emoteName)
            end
        end
    end

    local formattedEntries = {}
    for slot = 1, 8 do
        local chosenEmote = selectedEmotes[slot]
        if chosenEmote then
            table.insert(formattedEntries, string.format('["Emote","%s"]', chosenEmote))
        else
            table.insert(formattedEntries, "false")
        end
    end

    emotesValue.Value = "[" .. table.concat(formattedEntries, ",") .. "]"
end


EmotesandUltAurasGroupBox:AddToggle("enableemote", {
    Text = "enable emote",
    Tooltip = "enables the emotes on the emote menu",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        isEnabled = Value

        if isEnabled then
            if emotesValue then
                originalEmotes = emotesValue.Value
            end

            if Emote1DropDown then
                applyEmotes(Emote1DropDown.Value)
            end
        else
            if originalEmotes ~= "" and emotesValue then
                emotesValue.Value = originalEmotes
            end
        end
    end,
})


Emote1DropDown = EmotesandUltAurasGroupBox:AddDropdown("Emotes", {
    Text = "Emotes",
    Values = {
        -- Original List
        "Sit",
        "Hakari Dance",
        "Griddy",
        "Rock Paper Scissors",
        "Boogie Down",
        "Shadow Boxing",
        "T-Pose",
        "Carry",
        "Heartfelt Salute",
        "Drag",
        "Spit",
        "Calculated",
        "Falling Asleep",
        "Sleepy",
        "Rambunctious",
        "Relentless Laughing",
        "Think",
        "Fancy Feet",
        "Push-Ups",
        "Stay Down",
        "Sobbing",
        "Cutthroat",
        "Mic Drop",
        "Take the L",
        "Phone Call",
        "Fright Funk",
        "Shoulder Brush",
        "Facepalm",
        "Taco Time",
        "Floss",
        "Yawn",
        "One-Armed Pickup",
        "Sorcerer Stretch",
        "Star of Hope",
        "Jingle Bell Shake",
        "Nutcracker March",
        "Cocoa Cheers",
        "Ice Trick",
        "Sleddies",
        "Nerd",
        "Popcorn",
        "Gravedigger",
        "Not Like Us",
        "Paparazzi",
        "Aurora Miracle",
        "Blizzard",
        "Candy Cane Duel",
        "Cold World",
        "Gift Exchange",
        "Ice Skating",
        "Snow Angels",
        "Snowball Barrage",
        "Snowball Juggle",
        "Snowball Throw",
        "Snowman",
        "Lojo's Finger",
        "Sad Rain",
        "Frolic",
        "Death Day",
        
        -- Script File Emotes (Extracted from file)
        "Clap",
        "Kneel",
        "Flex",
        "Bow",
        "Pay Respects",
        "Bat Laugh",
        "BOO!",
        "Broomies",
        "Loco",
        "Pumpkin Headbutt",
        "Zombie Walk",
        "Spooky Scary Skeletons",
        "Trick or Treat",
        "Poppin' Bottles",
        "Sweet Death",
        "Mog",
        "Kodo Pose",
        "Selfie",
    },
    Default = nil,
    Searchable = true,
    Multi = true,
    Max = 8,
})
Emote1DropDown:OnChanged(function(Value)
    applyEmotes(Value)
end)
local EmotesLabel = EmotesandUltAurasGroupBox:AddLabel("Don't choose more then 8\n it doesn't do anything")
-- Register optimization: local Players = game:GetService("Players")
-- Register optimization: local LocalPlayer = Players.LocalPlayer


local activeAuras = {}
local originalAuraColors = {}
local currentAuraColor = nil
local selectedAuraName = nil


local function getAuraPaths()
    local paths = {}
    local success, combat = pcall(function() 
        return LocalPlayer.PlayerScripts.Combat.Transform 
    end)
    
    if success and combat then
        for _, charName in ipairs({"Gon", "Mob", "Nanami", "Sukuna"}) do
            local charFolder = combat:FindFirstChild(charName)
            if charFolder and charFolder:FindFirstChild("Insert") then
                paths[charName] = charFolder.Insert
            end
        end
    end
    
    return paths
end

local auraPaths = getAuraPaths()


local function ClearAuras()
    for _, aura in ipairs(activeAuras) do
        if aura and aura.Parent then
            aura:Destroy()
        end
    end
    table.clear(activeAuras)
    table.clear(originalAuraColors)
end


local function ProcessAuraObject(obj, mode, targetColor)
    local function SaveColor(o)
        if o:IsA("ParticleEmitter") or o:IsA("Beam") or o:IsA("Trail") 
           or o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") 
           or o:IsA("BasePart") then
            originalAuraColors[o] = o.Color
        elseif o:IsA("Highlight") then
            originalAuraColors[o] = { Fill = o.FillColor, Outline = o.OutlineColor }
        end
    end

    local function ApplyColor(o, color)
        if o:IsA("ParticleEmitter") or o:IsA("Beam") or o:IsA("Trail") then
            o.Color = ColorSequence.new(color)
        elseif o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") or o:IsA("BasePart") then
            o.Color = color
        elseif o:IsA("Highlight") then
            o.FillColor = color
            o.OutlineColor = color
        end
    end

    local function ResetColor(o)
        local saved = originalAuraColors[o]
        if not saved then return end

        if o:IsA("Highlight") then
            o.FillColor = saved.Fill
            o.OutlineColor = saved.Outline
        else
            o.Color = saved
        end
    end

    if mode == "save" then
        SaveColor(obj)
    elseif mode == "apply" and targetColor then
        ApplyColor(obj, targetColor)
    elseif mode == "reset" then
        ResetColor(obj)
    end

    for _, child in ipairs(obj:GetChildren()) do
        ProcessAuraObject(child, mode, targetColor)
    end
end


local function ApplyAura(auraName)
    selectedAuraName = auraName
    ClearAuras()

    if not auraName or auraName == "" then return end

    local folder = auraPaths[auraName]
    if not folder then return end

    local character = LocalPlayer.Character
    if not character then return end

    for _, effectPart in ipairs(folder:GetChildren()) do
        local bodyPart = character:FindFirstChild(effectPart.Name)
        if bodyPart then
            for _, effect in ipairs(effectPart:GetChildren()) do
                local success, clone = pcall(function() return effect:Clone() end)
                if success and clone then
                    clone.Parent = bodyPart
                    table.insert(activeAuras, clone)

                    ProcessAuraObject(clone, "save")
                    if currentAuraColor then
                        ProcessAuraObject(clone, "apply", currentAuraColor)
                    end
                end
            end
        end
    end
end


local function RecolorAuras(color)
    currentAuraColor = color
    for _, aura in ipairs(activeAuras) do
        ProcessAuraObject(aura, "apply", color)
    end
end


local function ResetAurasToDefault()
    currentAuraColor = nil
    for _, aura in ipairs(activeAuras) do
        ProcessAuraObject(aura, "reset")
    end
end


LocalPlayer.CharacterRemoving:Connect(ClearAuras)




local UltAuraDropDown = EmotesandUltAurasGroupBox:AddDropdown("UltAura", {
    Text = "UltAura",
    Values = {
        "Gon",
        "Nanami",
        "Mob",
        "Sukuna"
    },
    Default = nil,
    AllowNull = true,
    Multi = false,
})

UltAuraDropDown:OnChanged(function(Value)
    ApplyAura(Value)
end)


local UltAuraColorLabel = EmotesandUltAurasGroupBox:AddLabel("UltAuraColor")

UltAuraColorLabel:AddColorPicker("UltAuraColorPicker", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "UltAura Color",
    Transparency = nil,
    Callback = function(Value)
        RecolorAuras(Value)
    end
})


EmotesandUltAurasGroupBox:AddButton("Reset Color", function()
    ResetAurasToDefault()
end)
task.spawn(function()
    
    local CC = {
        SelectedColor = Color3.fromRGB(255, 255, 255),
        Enabled = false,
        FoundCharacters = {},
        OriginalColors = {}
    }

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

    local colorPaths = {
        LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Combat"):WaitForChild("Transform", 2),
        LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Combat"):WaitForChild("Dash", 2),
        ReplicatedStorage:WaitForChild("Characters", 2)
    }

    local function FindCharacters(name)
        CC.FoundCharacters = {}
        for _, path in ipairs(colorPaths) do
            if path then
                local character = path:FindFirstChild(name)
                if character then
                    table.insert(CC.FoundCharacters, character)
                end
            end
        end
        return #CC.FoundCharacters > 0
    end

    local function StoreOriginals(obj)
        if not CC.OriginalColors[obj] then 
            CC.OriginalColors[obj] = {} 
        end
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("BasePart") then 
                CC.OriginalColors[obj][child] = {Type = "BasePart", Color = child.Color}
            elseif child:IsA("ParticleEmitter") then 
                CC.OriginalColors[obj][child] = {Type = "ParticleEmitter", Color = child.Color}
            elseif child:IsA("Trail") then 
                CC.OriginalColors[obj][child] = {Type = "Trail", Color = child.Color}
            elseif child:IsA("Beam") then 
                CC.OriginalColors[obj][child] = {Type = "Beam", Color = child.Color}
            elseif child:IsA("Highlight") then 
                CC.OriginalColors[obj][child] = {Type = "Highlight", FillColor = child.FillColor, OutlineColor = child.OutlineColor}
            elseif child:IsA("PointLight") then 
                CC.OriginalColors[obj][child] = {Type = "PointLight", Color = child.Color}
            end
        end
    end

    local function ApplyColorToObject(obj, newColor)
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("BasePart") then 
                child.Color = newColor
            elseif child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") then 
                child.Color = ColorSequence.new(newColor)
            elseif child:IsA("Highlight") then 
                child.FillColor = newColor
                child.OutlineColor = newColor
            elseif child:IsA("PointLight") then 
                child.Color = newColor
            end
        end
    end

    local function ApplyAllColors()
        if not CC.Enabled then return end
        local success, playerChar = pcall(function() 
            return LocalPlayer.Data.Character.Value 
        end)
        if success and playerChar and FindCharacters(playerChar) then
            for _, character in ipairs(CC.FoundCharacters) do
                if not CC.OriginalColors[character] then 
                    StoreOriginals(character) 
                end
                ApplyColorToObject(character, CC.SelectedColor)
                
                character.DescendantAdded:Connect(function(descendant)
                    if CC.Enabled then
                        task.wait(0.05)
                        ApplyColorToObject(character, CC.SelectedColor)
                    end
                end)
            end
        end
    end

    local function ResetAllColors()
        for _, character in ipairs(CC.FoundCharacters) do
            if CC.OriginalColors[character] then
                for child, colorData in pairs(CC.OriginalColors[character]) do
                    if child and child.Parent then
                        if colorData.Type == "Highlight" then
                            child.FillColor = colorData.FillColor
                            child.OutlineColor = colorData.OutlineColor
                        else
                            child.Color = colorData.Color
                        end
                    end
                end
            end
        end
    end

    
    
    

    EmotesandUltAurasGroupBox:AddToggle("enableEffectColorizer", {
        Text = "Enable Effect Customizer",
        Tooltip = "Dynamically recolor combat transform and dash effects",
        Default = false,
        Disabled = false,
        Visible = true,
        Risky = false,
        Callback = function(Value)
            CC.Enabled = Value
            if Value then
                ApplyAllColors()
            else
                ResetAllColors()
            end
        end,
    }):AddColorPicker("effectColorPicker", {
        Default = Color3.fromRGB(255, 255, 255),
        Title = "Effect Color",
        Callback = function(Value)
            CC.SelectedColor = Value
            if CC.Enabled then
                ApplyAllColors()
            end
        end,
    })

    EmotesandUltAurasGroupBox:AddButton({
        Text = "Reset Character Colors",
        Func = function()
            ResetAllColors()
        end,
        Tooltip = "Reverts all modified effect colors back to normal",
        Risky = false,
    })
end)
-- Register optimization: local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Register optimization: local Players = game:GetService("Players")
-- Register optimization: local Workspace = game:GetService("Workspace")
-- Register optimization: local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
-- Register optimization: local LocalPlayer = Players.LocalPlayer


local KillSoundEnabled = false
local DeathSoundEnabled = false

local CurrentKillSoundId = "rbxassetid://138123827"
local CurrentDeathSoundId = "rbxassetid://138123827"

local KillSoundVolume = 2
local DeathSoundVolume = 2

local DeathEventConnection = nil


local MIN_DISTANCE = 5
local MAX_DISTANCE = 350
local ROLLOFF_MODE = Enum.RollOffMode.InverseTapered


local function Play3DSoundAtTarget(targetInstance, soundId, volume)
    if not soundId or soundId == "" then return end

    local targetChar = targetInstance
    if targetChar and not targetChar:IsA("Model") then
        targetChar = targetChar:FindFirstAncestorOfClass("Model")
    end

    if not targetChar then return end

    local rootPart = targetChar:FindFirstChild("HumanoidRootPart") 
        or targetChar.PrimaryPart 
        or targetChar:FindFirstChildWhichIsA("BasePart")

    if not rootPart then return end

    local soundPart = Instance.new("Part")
    soundPart.Name = "SoundRotationLockedPart"
    soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
    soundPart.Transparency = 1
    soundPart.CanCollide = false
    soundPart.Anchored = true
    soundPart.CFrame = CFrame.new(rootPart.Position)
    soundPart.Parent = Workspace

    local sound = Instance.new("Sound")
    sound.Name = "3DKillSoundEffect"
    sound.SoundId = soundId
    sound.Volume = volume
    sound.RollOffMinDistance = MIN_DISTANCE
    sound.RollOffMaxDistance = MAX_DISTANCE
    sound.RollOffMode = ROLLOFF_MODE

    sound.Parent = soundPart
    sound:Play()

    local stepConnection
    stepConnection = RunService.RenderStepped:Connect(function()
        if rootPart and rootPart.Parent and soundPart and soundPart.Parent then
            soundPart.CFrame = CFrame.new(rootPart.Position)
        else
            if stepConnection then
                stepConnection:Disconnect()
            end
        end
    end)

    local function Cleanup()
        if stepConnection then
            stepConnection:Disconnect()
            stepConnection = nil
        end
        if sound then sound:Destroy() end
        if soundPart then soundPart:Destroy() end
    end

    sound.Ended:Connect(Cleanup)
    task.delay(5, Cleanup)
end


local function PlayLocalPlayerDeathSound(soundId, volume)
    if not soundId or soundId == "" then return end

    local sound = Instance.new("Sound")
    sound.Name = "3DDeathSoundEffect"
    sound.SoundId = soundId
    sound.Volume = volume
    sound.Parent = SoundService
    sound:Play()

    sound.Ended:Connect(function()
        sound:Destroy()
    end)

    task.delay(5, function()
        if sound and sound.Parent then
            sound:Destroy()
        end
    end)
end


local function OnDeathEventTriggered(arg1, arg2, arg3)
    
    local isLocalPlayerDead = (arg2 == LocalPlayer) 
        or (arg1 == LocalPlayer) 
        or (LocalPlayer.Character and arg1 == LocalPlayer.Character)

    if DeathSoundEnabled and isLocalPlayerDead then
        PlayLocalPlayerDeathSound(CurrentDeathSoundId, DeathSoundVolume)
        return
    end

    
    if KillSoundEnabled and arg3 == LocalPlayer and not isLocalPlayerDead then
        Play3DSoundAtTarget(arg1, CurrentKillSoundId, KillSoundVolume)
    end
end


local function UpdateEventConnection()
    if KillSoundEnabled or DeathSoundEnabled then
        if not DeathEventConnection then
            local deathEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("DeathEvent")
            DeathEventConnection = deathEvent.OnClientEvent:Connect(OnDeathEventTriggered)
        end
    else
        if DeathEventConnection then
            DeathEventConnection:Disconnect()
            DeathEventConnection = nil
        end
    end
end





local SoundGroupBox = Tabs.Client:AddLeftGroupbox("Kill / Death Sound", "boxes")


SoundGroupBox:AddToggle("enableKillSound", {
    Text = "Enable KillSound",
    Tooltip = "plays a sound when you kill",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        KillSoundEnabled = Value
        UpdateEventConnection()
    end,
})

SoundGroupBox:AddInput("KillSoundId", {
    Default = "",
    Numeric = true,
    Finished = true,
    ClearTextOnFocus = false,
    Text = "KillSound ID",
    Tooltip = "Put the killsound ID and press enter",
    Placeholder = "Put killsound ID and press enter",

    Callback = function(Value)
        if Value and Value ~= "" then
            local formattedId = typeof(Value) == "number" and ("rbxassetid://" .. tostring(Value)) or Value
            if not formattedId:find("rbxassetid://") then
                formattedId = "rbxassetid://" .. formattedId
            end

            CurrentKillSoundId = formattedId
        end
    end,
})

SoundGroupBox:AddSlider("KillSoundVolumeSlider", {
    Text = "KillSound Volume",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        KillSoundVolume = Value
    end,
})


SoundGroupBox:AddToggle("enableDeathSound", {
    Text = "Enable DeathSound",
    Tooltip = "Plays sound when you die",
    Default = false, 
    Disabled = false, 
    Visible = true, 
    Risky = false, 

    Callback = function(Value)
        DeathSoundEnabled = Value
        UpdateEventConnection()
    end,
})

SoundGroupBox:AddInput("DeathSoundId", {
    Default = "",
    Numeric = true,
    Finished = true,
    ClearTextOnFocus = false,
    Text = "DeathSound ID",
    Tooltip = "Put the deathsound ID and press enter",
    Placeholder = "Put deathsound ID and press enter",

    Callback = function(Value)
        if Value and Value ~= "" then
            local formattedId = typeof(Value) == "number" and ("rbxassetid://" .. tostring(Value)) or Value
            if not formattedId:find("rbxassetid://") then
                formattedId = "rbxassetid://" .. formattedId
            end

            CurrentDeathSoundId = formattedId
        end
    end,
})

SoundGroupBox:AddSlider("DeathSoundVolumeSlider", {
    Text = "DeathSound Volume",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        DeathSoundVolume = Value
    end,
})
task.spawn(function()
    
    local AC = {
        Enabled = false,
        AutoTransform = false,
        TargetId = nil
    }

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    function AC.ClearVisuals(char)
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Accessory") 
                or item:IsA("Shirt") 
                or item:IsA("Pants") 
                or item:IsA("ShirtGraphic") 
                or item:IsA("BodyColors") then
                item:Destroy()
            end
        end

        
        local head = char:FindFirstChild("Head")
        if head then
            for _, child in ipairs(head:GetChildren()) do
                if child:IsA("Decal") then
                    child:Destroy()
                end
            end
        end
    end

    function AC.AttachAccessory(char, accessory)
        local handle = accessory:FindFirstChild("Handle")
        if not handle then return end

        
        if handle:IsA("BasePart") then
            handle.CastShadow = false
        end

        local accAttachment = handle:FindFirstChildWhichIsA("Attachment")
        if not accAttachment then return end

        local targetAttachment = nil
        for _, descendant in ipairs(char:GetDescendants()) do
            if descendant:IsA("Attachment") and descendant.Name == accAttachment.Name then
                targetAttachment = descendant
                break
            end
        end

        if targetAttachment then
            local targetPart = targetAttachment.Parent
            accessory.Parent = char
            handle.CFrame = targetPart.CFrame * targetAttachment.CFrame * accAttachment.CFrame:Inverse()

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = targetPart
            weld.Parent = handle
        else
            accessory.Parent = char
        end
    end

    function AC.ApplyFace(char, targetModel)
        local head = char:FindFirstChild("Head")
        local targetHead = targetModel:FindFirstChild("Head")
        if not (head and targetHead) then return end

        local targetFace = targetHead:FindFirstChildOfClass("Decal")
        if targetFace then
            local newFace = targetFace:Clone()
            newFace.Name = "face"
            newFace.Parent = head
        end
    end

    function AC.ApplyClothingAndColors(char, targetModel)
        for _, item in ipairs(targetModel:GetChildren()) do
            if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
                item:Clone().Parent = char
            end
        end
    end

    function AC.ApplyAccessories(char, targetModel)
        for _, item in ipairs(targetModel:GetChildren()) do
            if item:IsA("Accessory") then
                AC.AttachAccessory(char, item:Clone())
            end
        end
    end

    function AC.ApplyAvatar(userId)
        if not userId or userId == 0 then return end

        local char = LocalPlayer.Character
        if not char or not char:FindFirstChildOfClass("Humanoid") then return end

        local success, targetModel = pcall(function()
            return Players:CreateHumanoidModelFromUserId(userId)
        end)

        if not success or not targetModel then return end

        AC.ClearVisuals(char)
        AC.ApplyFace(char, targetModel)
        AC.ApplyClothingAndColors(char, targetModel)
        AC.ApplyAccessories(char, targetModel)

        targetModel:Destroy()
    end

    
    if hookmetamethod and getnamecallmethod then
        local rawNamecall
        rawNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()

            if method == "FireServer" and AC.AutoTransform then
                local remoteName = self.Name
                if remoteName == "ValidateTransform" then
                    task.spawn(function()
                        if AC.TargetId then
                            AC.ApplyAvatar(AC.TargetId)
                        end
                    end)
                elseif remoteName == "TransformStop" then
                    task.spawn(function()
                        
                        if AC.Enabled and AC.TargetId then
                            AC.ApplyAvatar(AC.TargetId)
                        else
                            AC.ApplyAvatar(LocalPlayer.UserId)
                        end
                    end)
                end
            end

            return rawNamecall(self, ...)
        end)
    end

    
    LocalPlayer.CharacterAdded:Connect(function(char)
        if AC.Enabled and AC.TargetId then
            char:WaitForChild("Humanoid")
            task.wait(0.5)
            AC.ApplyAvatar(AC.TargetId)
        end
    end)

    
    local Box = Tabs.Client:AddRightGroupbox("Avatar Changer", "boxes")

    Box:AddToggle("enableAvatarChanger", {
        Text = "Change avatar",
        Tooltip = "Applies chosen user's avatar",
        Default = false,
        Disabled = false,
        Visible = true,
        Risky = false,
        Callback = function(Value)
            AC.Enabled = Value
            if Value then
                if AC.TargetId then
                    AC.ApplyAvatar(AC.TargetId)
                end
            else
                AC.ApplyAvatar(LocalPlayer.UserId)
            end
        end,
    })

    Box:AddToggle("enableAutoTransform", {
        Text = "UltimateOutfit",
        Tooltip = "Changes outfit on Ultimate and changes it back when its finshed",
        Default = false,
        Disabled = false,
        Visible = true,
        Risky = false,
        Callback = function(Value)
            AC.AutoTransform = Value
        end,
    })

    Box:AddInput("TargetUserIdInput", {
        Default = "",
        Numeric = true,
        Finished = false,
        ClearTextOnFocus = false,
        Text = "Roblox UserId",
        Tooltip = "Type a Roblox UserId to load their outfit",
        Placeholder = "Type a Roblox UserId",
        Callback = function(Value)
            local numericId = tonumber(Value)
            if numericId then
                AC.TargetId = numericId
                if AC.Enabled then
                    AC.ApplyAvatar(numericId)
                end
            end
        end,
    })
    Box:AddLabel("does not change your body type", false)
end)

-- ==================== ZETA FUNCTIONS ====================

do -- [[ SHARED ZETA UTILS ]]
RS_Z = game:GetService("ReplicatedStorage")
Players_Z = game:GetService("Players")
RunService_Z = game:GetService("RunService")
localPlayer_Z = Players_Z.LocalPlayer

local function getFCR_Z()
    return RS_Z:FindFirstChild("Remotes")
        and RS_Z.Remotes:FindFirstChild("Replication")
        and RS_Z.Remotes.Replication:FindFirstChild("FullCustomReplication")
end

local function zGetChar()
    local ok, v = pcall(function() return localPlayer_Z.Data.Character.Value end)
    if ok and v and v ~= "" then return v end
    return "Gon"
end

local function zBypass(targetChar)
    pcall(function()
        local myChar = localPlayer_Z.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP or not targetChar then return end
        local tHRP = targetChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end
        local cn = zGetChar()
        local wc = RS_Z.Characters:FindFirstChild(cn) and RS_Z.Characters[cn]:FindFirstChild("WallCombo")
            or RS_Z.Characters.Gon and RS_Z.Characters.Gon:FindFirstChild("WallCombo")
        if not wc then return end
        local tp = Players_Z:GetPlayerFromCharacter(targetChar)
        if not tp then return end
        RS_Z.Remotes.Abilities.Ability:FireServer(wc, 9000000, {}, tHRP.Position)
        RS_Z.Remotes.Combat.Action:FireServer(wc, "Characters:"..cn..":WallCombo", 2, 9000000, {
            HitboxCFrames={tHRP.CFrame,tHRP.CFrame}, BestHitCharacter=targetChar,
            HitCharacters={targetChar}, Ignore={}, DeathInfo={}, BlockedCharacters={},
            HitInfo={IsFacing=false,IsInFront=true}, ServerTime=os.time(),
            Actions={ActionNumber1={[tp.Name]={
                StartCFrameStr=tostring(myHRP.CFrame), Local=true, Collision=false,
                Animation="Punch1Hit", Preset="Punch", Velocity=Vector3.zero,
                FromPosition=tHRP.Position, Seed=math.random(1,999999)
            }}}, FromCFrame=tHRP.CFrame
        }, "Action150", 0)
    end)
end

local function zNearest()
    local myChar = localPlayer_Z.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local near, best = nil, math.huge
    for _, p in ipairs(Players_Z:GetPlayers()) do
        if p == localPlayer_Z or not p.Character then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then continue end
        local hp = hum:GetAttribute("Health") or hum.Health or 0
        if hp <= 0 then continue end
        local d = (myHRP.Position - hrp.Position).Magnitude
        if d < best then best = d; near = p end
    end
    return near
end

local function zAll()
    local list = {}
    for _, p in ipairs(Players_Z:GetPlayers()) do
        if p == localPlayer_Z or not p.Character then continue end
        local pm = p.Character:FindFirstChildOfClass("Humanoid")
        local hp = pm and (pm:GetAttribute("Health") or pm.Health or 0)
        if hp and hp > 0 then table.insert(list, p) end
    end
    return list
end

    -- ── GOD MODE RANK x NORMAL ─────────────────────────────────────────
  -- ── GOD MODE RANK x NORMAL ─────────────────────────────────────────
    local Z = {}  -- Tabla contenedora
    Z.godRank = false
    Z.godRankTh = nil
    Z.godNorm = false
    Z.godNormTh = nil
    Z.bums = {"The Ultimate Bum","Blocking Bum","Attacking Bum"}

    local function zGetBums()
        local list = {}
        local folder = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild("NPCs")
        if not folder then return list end
        for _, name in ipairs(zBums) do
            local npc = folder:FindFirstChild(name)
            if npc and npc:FindFirstChild("HumanoidRootPart") then table.insert(list, npc) end
        end
        return list
    end

    local function zStartGodNorm()
        if godNormTh then return end
        godNormTh = task.spawn(function()
            while godNorm_Z do
                local char = localPlayer_Z.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, bum in ipairs(zGetBums()) do
                        pcall(function()
                            RS_Z.Remotes.Abilities.Ability:FireServer(RS_Z.Characters.Gon.WallCombo, 33036, nil, bum, bum.HumanoidRootPart.Position)
                            RS_Z.Remotes.Combat.Action:FireServer(RS_Z.Characters.Gon.WallCombo,
                                "Characters:Gon:WallCombo", 1, 33036, {
                                    HitboxCFrames={}, BestHitCharacter=bum, HitCharacters={bum},
                                    Ignore={}, DeathInfo={}, Actions={},
                                    HitInfo={IsFacing=true,IsInFront=true},
                                    BlockedCharacters={}, ServerTime=os.clock(), FromCFrame=hrp.CFrame
                                }, "Action651", 0)
                        end)
                    end
                end
                task.wait(0.1)
            end
            godNormTh = nil
        end)
    end

    local function zStartGodRank()
        if godRankTh then return end
        godRankTh = task.spawn(function()
            while godRank_Z do
                pcall(function()
                    local pc = localPlayer_Z.Character
                    if not pc then return end
                    local cn = zGetChar()
                    local cf = RS_Z:FindFirstChild("Characters")
                    if not cf or not cf:FindFirstChild(cn) then return end
                    local wc = cf[cn]:FindFirstChild("WallCombo")
                    if not wc then return end
                    local an = "Action"..math.random(1000,9999)
                    local rid = math.random(100000,999999)
                    RS_Z.Remotes.Abilities.Ability:FireServer(wc, rid)
                    RS_Z.Remotes.Combat.Action:FireServer(wc, "Characters:"..cn..":WallCombo", 1, rid, {
                        HitboxCFrames={nil}, BestHitCharacter=pc, HitCharacters={pc},
                        Ignore={[an]={pc}}, DeathInfo={}, Actions={[an]={}},
                        HitInfo={Blocked=false,IsFacing=true,IsInFront=true},
                        BlockedCharacters={}, ServerTime=tick(), FromCFrame=nil
                    }, an)
                end)
                task.wait(0.01)
            end
            godRankTh = nil
        end)
    end

    -- ── GOD MODE V3 ────────────────────────────────────────────────────
    local V3 = {enabled=false, tc=nil, ts=nil, dc=0.03, ds=0.01}

    local function v3LoopClosest()
        while V3.enabled do
            task.wait(V3.dc)
            local t = zNearest()
            if t and t.Character and localPlayer_Z.Character then
                pcall(function()
                    RS_Z.Remotes.Abilities.Ability:FireServer(RS_Z.Characters.Gon.WallCombo, 33036, nil, t.Character, t.Character.HumanoidRootPart.Position)
                    RS_Z.Remotes.Combat.Action:FireServer(RS_Z.Characters.Gon.WallCombo,
                        "Characters:Gon:WallCombo", 1, 33036, {
                            HitboxCFrames={}, BestHitCharacter=t.Character, HitCharacters={t.Character},
                            Ignore={}, DeathInfo={}, Actions={}, HitInfo={IsFacing=true,IsInFront=true},
                            BlockedCharacters={}, ServerTime=os.clock(),
                            FromCFrame=localPlayer_Z.Character.HumanoidRootPart.CFrame
                        }, "Action651", 0)
                end)
            end
        end
    end

    local function v3LoopSelf()
        while V3.enabled do
            task.wait(V3.ds)
            pcall(function()
                local char = localPlayer_Z.Character
                if not char then return end
                local cn = zGetChar()
                local wc = RS_Z.Characters:FindFirstChild(cn) and RS_Z.Characters[cn]:FindFirstChild("WallCombo")
                if not wc then return end
                local aid = "Action"..math.random(1000,9999)
                local rid = math.random(100000,999999)
                RS_Z.Remotes.Abilities.Ability:FireServer(wc, rid)
                RS_Z.Remotes.Combat.Action:FireServer(wc, "Characters:"..cn..":WallCombo", 1, rid, {
                    HitboxCFrames={nil}, BestHitCharacter=char, HitCharacters={char},
                    Ignore={[aid]={char}}, DeathInfo={}, Actions={[aid]={}},
                    HitInfo={Blocked=false,IsFacing=true,IsInFront=true},
                    BlockedCharacters={}, ServerTime=tick(), FromCFrame=nil
                }, aid)
            end)
        end
    end

    -- ── TEST SPAM (Grab + Damage) ───────────────────────────────────────
    local TS = {enabled=false, thread=nil, delay=0.05}

    local function tsUse(abilityNum, target)
        local myChar = localPlayer_Z.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local tc  = target.Character
        local tHRP = tc and tc:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end
        
        local cn = zGetChar()
        local cf2 = RS_Z.Characters:FindFirstChild(cn)
        if not cf2 then return end
        
        -- Admin Abuse Pattern: Prep position and custom replication
        pcall(function() SetlocalPlayerCFrame() end)
        task.wait()
        pcall(function() fullcustom(target, 0) end)
        task.wait()

        local myRCF = myHRP.CFrame
        local tCF   = tHRP.CFrame
        local fakeCF = tCF * CFrame.new(0,0,-2)
        local pull = (myHRP.Position - tHRP.Position)
        local pullF = pull.Magnitude > 0 and pull.Unit*120000 or Vector3.new(0,0,-120000)
        
        -- Check invincibility attribute
        local isInvincible = tc:GetAttribute("Invincible")
        if isInvincible then pcall(zBypass, tc) end

        pcall(function()
            local wc = cf2:FindFirstChild("WallCombo") or RS_Z.Characters.Gon:FindFirstChild("WallCombo")
            if not wc then return end
            local dmg = isInvincible and 9000000 or 33036
            RS_Z.Remotes.Abilities.Ability:FireServer(wc, dmg, nil, tc, tHRP.Position)
            RS_Z.Remotes.Combat.Action:FireServer(wc, "Characters:"..cn..":WallCombo", 1, dmg, {
                HitboxCFrames={tCF,tCF,tCF,tCF,tCF,tCF}, -- Match KillAura hitbox style
                BestHitCharacter=tc, HitCharacters={tc,tc,tc},
                Ignore={}, DeathInfo={}, Actions={}, HitInfo={IsFacing=true,IsInFront=true},
                BlockedCharacters={}, ServerTime=os.clock(), FromCFrame=tCF
            }, "Action651", 0)
        end)

        if abilityNum == 1 then
            local ab = cf2:FindFirstChild("Abilities") and cf2.Abilities:FindFirstChild("1")
            if ab then
                local rid = isInvincible and 9000000 or math.random(100000,999999)
                local an  = "Action"..math.random(1000,9999)
                pcall(function()
                    RS_Z.Remotes.Abilities.Ability:FireServer(ab, rid, nil, tc, tHRP.Position)
                    RS_Z.Remotes.Combat.Action:FireServer(ab, cn..":Abilities:1", 1, rid, {
                        HitboxCFrames={tCF,tCF,tCF,tCF,tCF,tCF},
                        BestHitCharacter=tc, HitCharacters={tc,tc,tc},
                        Ignore={}, DeathInfo={}, BlockedCharacters={},
                        HitInfo={IsFacing=true,IsInFront=true,Blocked=false}, ServerTime=tick(),
                        Actions={[an]={[target.Name]={
                            StartCFrameStr=tostring(myRCF.X)..","..tostring(myRCF.Y)..","..tostring(myRCF.Z)..",1,0,0,0,1,0,0,0,1",
                            ImpulseVelocity=pullF, AbilityName="1", Seed=math.random(1,1e6)
                        }}}, FromCFrame=tCF
                    }, an, 0)
                    RS_Z.Remotes.Abilities.AbilityCanceled:FireServer(ab)
                end)
            end
        else
            local ab = cf2:FindFirstChild("Abilities") and cf2.Abilities:FindFirstChild("2")
            if ab then
                local rid = isInvincible and 9000000 or math.random(100000,999999)
                local an  = "Action"..math.random(1000,9999)
                pcall(function()
                    RS_Z.Remotes.Abilities.Ability:FireServer(ab, rid, nil, tc, tHRP.Position)
                    RS_Z.Remotes.Combat.Action:FireServer(ab, cn..":Abilities:2", 1, rid, {
                        HitboxCFrames={tCF,tCF,tCF,tCF,tCF,tCF},
                        BestHitCharacter=tc, HitCharacters={tc,tc,tc},
                        Ignore={}, DeathInfo={}, BlockedCharacters={},
                        HitInfo={IsFacing=true,IsInFront=true,Blocked=false}, ServerTime=tick(),
                        Actions={[an]={[target.Name]={
                            StartCFrameStr=tostring(fakeCF.X)..","..tostring(fakeCF.Y)..","..tostring(fakeCF.Z)..",1,0,0,0,1,0,0,0,1",
                            ImpulseVelocity=Vector3.new(0,0,0), AbilityName="2", Seed=math.random(1,1e6)
                        }}}, FromCFrame=tCF
                    }, an, 0)
                    RS_Z.Remotes.Abilities.AbilityCanceled:FireServer(ab)
                end)
            end
        end
        
        task.wait()
        pcall(function() fullcustom2() end)
    end

    -- ── KILL COMBO ─────────────────────────────────────────────────────
    local KC = {enabled=false, conns={}, conn2=nil, running=false, dv1=0.05, dv2=0.5, mode="nearest"}

    local function kcV1(target)
        local mh = localPlayer_Z.Character and localPlayer_Z.Character:FindFirstChild("HumanoidRootPart")
        if not mh then return end
        local tc = target.Character
        local th = tc and tc:FindFirstChild("HumanoidRootPart")
        if not th then return end
        if tc:GetAttribute("Invincible") then pcall(zBypass, tc); return end
        local cn = zGetChar()
        local wc = RS_Z.Characters:FindFirstChild(cn) and RS_Z.Characters[cn]:FindFirstChild("WallCombo")
            or RS_Z.Characters.Gon and RS_Z.Characters.Gon:FindFirstChild("WallCombo")
        if not wc then return end
        pcall(function()
            RS_Z.Remotes.Abilities.Ability:FireServer(wc, 1, {}, th.Position)
            RS_Z.Remotes.Combat.Action:FireServer(wc, cn..":WallCombo", 2, 1, {
                HitboxCFrames={th.CFrame,th.CFrame}, BestHitCharacter=tc, HitCharacters={tc},
                Ignore={}, DeathInfo={}, BlockedCharacters={},
                HitInfo={IsFacing=false,IsInFront=true}, ServerTime=os.time(),
                Actions={ActionNumber1={[target.Name]={
                    StartCFrameStr=tostring(mh.CFrame), Local=true, Collision=false,
                    Animation="Punch1Hit", Preset="Punch", Velocity=Vector3.zero,
                    FromPosition=th.Position, Seed=math.random(1,999999)
                }}}, FromCFrame=th.CFrame
            }, "Action150", 0)
        end)
    end

    local function kcV2(target)
        local cn = zGetChar()
        local ok, ab = pcall(function() return RS_Z.Characters:WaitForChild(cn,1).Abilities["4"] end)
        if not ok or not ab then
            ok, ab = pcall(function() return RS_Z.Characters.Gon.Abilities["4"] end)
            if not ok or not ab then return end
            cn = "Gon"
        end
        local tc  = target.Character
        local th  = tc and tc:FindFirstChild("HumanoidRootPart")
        if not th then return end
        local tcf = th.CFrame
        if tc:GetAttribute("Invincible") then pcall(zBypass, tc) end
        pcall(function()
            RS_Z.Remotes.Abilities.Ability:FireServer(ab, 9000000)
            local sa = {377,380,383,384,385,387,389}
            for i = 1, 7 do
                local cd = {
                    HitboxCFrames={tcf,tcf}, BestHitCharacter=tc, HitCharacters={tc},
                    Ignore=i>2 and {ActionNumber1={tc}} or {},
                    DeathInfo={}, BlockedCharacters={},
                    HitInfo={IsFacing=not(i==1 or i==2),IsInFront=i<=2,Blocked=i>2 and false or nil},
                    ServerTime=tick(), Actions=i>2 and {ActionNumber1={}} or {}, FromCFrame=tcf
                }
                if i == 7 then
                    cd.RockCFrame = tcf
                    cd.Actions = {ActionNumber1={[target.Name]={
                        StartCFrameStr=tostring(tcf.X)..","..tostring(tcf.Y)..","..tostring(tcf.Z)..",0,0,0,0,0,0,0,0,0",
                        ImpulseVelocity=Vector3.new(1901,-25000,291), AbilityName="4",
                        RotVelocityStr="0,0,0", VelocityStr="1.900635,0.010867,0.291061", Duration=2,
                        RotImpulseVelocity=Vector3.new(5868,-6649,-7414), Seed=math.random(1,1e6),
                        LookVectorStr="0.988493,0,0.151268"
                    }}}
                end
                if i == 2 then
                    RS_Z.Remotes.Combat.Action:FireServer(ab, cn..":Abilities:4", i, 9000000, cd, "Action"..sa[i], 0.1)
                else
                    RS_Z.Remotes.Combat.Action:FireServer(ab, cn..":Abilities:4", i, 9000000, cd, "Action"..sa[i])
                end
            end
            task.wait(0.5)
            RS_Z.Remotes.Abilities.AbilityCanceled:FireServer(ab)
        end)
    end

    -- ── GOD MODE+ MODO A / B ───────────────────────────────────────────
    local GPA = {enabled=false, conns={}, tgt="nearest", delay=0.05}
    local GPB = {enabled=false, conn=nil,  tgt="nearest"}

    local function gpaFire(target)
        local mh = localPlayer_Z.Character and localPlayer_Z.Character:FindFirstChild("HumanoidRootPart")
        if not mh then return end
        local tc = target.Character
        local th = tc and tc:FindFirstChild("HumanoidRootPart")
        if not th then return end
        local cn  = zGetChar()
        local wc  = RS_Z.Characters:FindFirstChild(cn) and RS_Z.Characters[cn]:FindFirstChild("WallCombo")
        if not wc then return end
        local dmg = tc:GetAttribute("Invincible") and 9000000 or math.random(100000,999999)
        local an  = "Action"..math.random(1000,9999)
        local an2 = "Action"..math.random(1000,9999)
        local tcf = th.CFrame
        local fcf = tcf * CFrame.new(0,0,-2)
        pcall(function()
            local fr = getFCR_Z()
            if fr then fr:FireServer(fcf) end
            RS_Z.Remotes.Abilities.Ability:FireServer(wc, dmg, {}, th.Position)
            RS_Z.Remotes.Combat.Action:FireServer(wc, "Characters:"..cn..":WallCombo", 1, dmg, {
                HitboxCFrames={tcf,tcf}, BestHitCharacter=tc, HitCharacters={tc},
                Ignore={}, DeathInfo={}, BlockedCharacters={},
                HitInfo={IsFacing=false,IsInFront=true,Blocked=false}, ServerTime=tick(),
                Actions={[an]={[target.Name]={
                    StartCFrameStr=tostring(fcf.X)..","..tostring(fcf.Y)..","..tostring(fcf.Z)..",1,0,0,0,1,0,0,0,1",
                    Local=true, Collision=false, Animation="Punch1Hit", Preset="Punch",
                    Velocity=Vector3.zero, FromPosition=th.Position, Seed=math.random(1,999999)
                }}}, FromCFrame=fcf
            }, an, 0)
            RS_Z.Remotes.Combat.Action:FireServer(wc, "Characters:"..cn..":WallCombo", 2, dmg, {
                HitboxCFrames={tcf,tcf}, BestHitCharacter=tc, HitCharacters={tc},
                Ignore={}, DeathInfo={}, BlockedCharacters={},
                HitInfo={IsFacing=true,IsInFront=false,Blocked=false}, ServerTime=tick(),
                Actions={ActionNumber1={[target.Name]={
                    StartCFrameStr=tostring(fcf.X)..","..tostring(fcf.Y)..","..tostring(fcf.Z)..",1,0,0,0,1,0,0,0,1",
                    ImpulseVelocity=Vector3.new(0,-500,0), Animation="Punch1Hit", Preset="Punch",
                    Velocity=Vector3.zero, FromPosition=th.Position, Seed=math.random(1,999999)
                }}}, FromCFrame=fcf
            }, an2, 0)
            RS_Z.Remotes.Abilities.AbilityCanceled:FireServer(wc)
            if fr then fr:FireServer(mh.CFrame) end
        end)
    end

    local function gpbFire(target)
        local cn = zGetChar()
        local ok, ab = pcall(function() return RS_Z.Characters:WaitForChild(cn,1).Abilities["4"] end)
        if not ok or not ab then return end
        local tc  = target.Character
        local th  = tc and tc:FindFirstChild("HumanoidRootPart")
        if not th then return end
        local tcf = th.CFrame
        if tc:GetAttribute("Invincible") then pcall(zBypass, tc) end
        pcall(function()
            RS_Z.Remotes.Abilities.Ability:FireServer(ab, 9000000)
            local sa = {377,380,383,384,385,387,389}
            for i = 1, 7 do
                local cd = {
                    HitboxCFrames={tcf,tcf}, BestHitCharacter=tc, HitCharacters={tc},
                    Ignore=i>2 and {ActionNumber1={tc}} or {},
                    DeathInfo={}, BlockedCharacters={},
                    HitInfo={IsFacing=not(i==1 or i==2),IsInFront=i<=2,Blocked=i>2 and false or nil},
                    ServerTime=tick(), Actions=i>2 and {ActionNumber1={}} or {}, FromCFrame=tcf
                }
                if i == 7 then
                    cd.RockCFrame = tcf
                    cd.Actions = {ActionNumber1={[target.Name]={
                        StartCFrameStr=tostring(tcf.X)..","..tostring(tcf.Y)..","..tostring(tcf.Z)..",0,0,0,0,0,0,0,0,0",
                        ImpulseVelocity=Vector3.new(1901,-25000,291), AbilityName="4",
                        RotVelocityStr="0,0,0", VelocityStr="1.900635,0.010867,0.291061", Duration=2,
                        RotImpulseVelocity=Vector3.new(5868,-6649,-7414), Seed=math.random(1,1e6),
                        LookVectorStr="0.988493,0,0.151268"
                    }}}
                end
                if i == 2 then
                    RS_Z.Remotes.Combat.Action:FireServer(ab, cn..":Abilities:4", i, 9000000, cd, "Action"..sa[i], 0.1)
                else
                    RS_Z.Remotes.Combat.Action:FireServer(ab, cn..":Abilities:4", i, 9000000, cd, "Action"..sa[i])
                end
            end
            task.wait(0.5)
            RS_Z.Remotes.Abilities.AbilityCanceled:FireServer(ab)
        end)
    end

    -- ── ABILITIES SPAM CON GRAB ────────────────────────────────────────
    local ABS = {enabled=false, thread=nil, delay=0.05, character="Gon", abilities={["1"]=true}}

    local function absFire(target, charName, abilityNum)
        local myChar = localPlayer_Z.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local tc   = target.Character
        local tHRP = tc and tc:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end
        local cf2 = RS_Z.Characters:FindFirstChild(charName)
        if not cf2 then return end
        local ab = cf2:FindFirstChild("Abilities") and cf2.Abilities:FindFirstChild(tostring(abilityNum))
        if not ab then return end
        local myRCF  = myHRP.CFrame
        local tCF    = tHRP.CFrame
        local fakeCF = tCF * CFrame.new(0,0,-2)
        local rid    = math.random(100000,999999)
        local an     = "Action"..math.random(1000,9999)
        local fr = getFCR_Z()
        if fr then fr:FireServer(fakeCF) end
        pcall(function()
            RS_Z.Remotes.Abilities.Ability:FireServer(ab, rid, nil, tc, tHRP.Position)
            RS_Z.Remotes.Combat.Action:FireServer(ab, charName..":Abilities:"..abilityNum, 1, rid, {
                HitboxCFrames={tCF,tCF}, BestHitCharacter=tc, HitCharacters={tc},
                Ignore={}, DeathInfo={}, BlockedCharacters={},
                HitInfo={IsFacing=true,IsInFront=true,Blocked=false}, ServerTime=tick(),
                Actions={[an]={[target.Name]={
                    StartCFrameStr=tostring(myRCF.X)..","..tostring(myRCF.Y)..","..tostring(myRCF.Z)..",1,0,0,0,1,0,0,0,1",
                    ImpulseVelocity=Vector3.new(0,0,0), AbilityName=tostring(abilityNum), Seed=math.random(1,1e6)
                }}}, FromCFrame=fakeCF
            }, an, 0)
            RS_Z.Remotes.Abilities.AbilityCanceled:FireServer(ab)
        end)
        if fr then fr:FireServer(myRCF) end
    end

    -- ==================== ZETA UI ====================
    local ZL = Tabs.Main:AddLeftGroupbox("Zeta God Mode", "boxes")
    local ZR = Tabs.Main:AddRightGroupbox("Zeta Combat", "boxes")

    -- God Mode Normal (dummy)
    ZL:AddToggle("ZGodNorm", {
        Text = "God Mode Dummy", Default = false,
        Callback = function(v)
            godNorm_Z = v
            if v then zStartGodNorm() end
        end,
    })

    -- God Mode Rank x Normal
    ZL:AddToggle("ZGodRank", {
        Text = "God Mode Rank x Normal", Default = false,
        Callback = function(v)
            godRank_Z = v
            if v then zStartGodRank() end
        end,
    })

    -- God Mode V3
    ZL:AddToggle("ZGodV3", {
        Text = "God Mode V3", Default = false,
        Callback = function(v)
            V3.enabled = v
            if v then
                V3.tc = task.spawn(v3LoopClosest)
                V3.ts = task.spawn(v3LoopSelf)
                Library:Notify("God Mode V3: ON", 3)
            else
                if V3.tc then task.cancel(V3.tc); V3.tc = nil end
                if V3.ts then task.cancel(V3.ts); V3.ts = nil end
                Library:Notify("God Mode V3: OFF", 3)
            end
        end,
    })
    ZL:AddSlider("ZV3DC", {Text="V3 Target Delay", Default=0.03, Min=0.001, Max=0.1, Rounding=3, Callback=function(v) V3.dc=v end})
    ZL:AddSlider("ZV3DS", {Text="V3 Self Delay",   Default=0.01, Min=0.01,  Max=0.1, Rounding=3, Callback=function(v) V3.ds=v end})
    ZL:AddDivider()

    -- TEST Spam
    ZL:AddToggle("ZTestSpam", {
        Text = "TEST (Grab + Damage Spam)", Default = false,
        Callback = function(v)
            TS.enabled = v
            if v then
                TS.thread = task.spawn(function()
                    pcall(function()
                        if zGetChar() ~= "Gon" then
                            RS_Z.Remotes.Character.ChangeCharacter:FireServer("Gon")
                            task.wait(1)
                        end
                    end)
                    while TS.enabled do
                        local t = zNearest()
                        if t then tsUse(1, t); task.wait(0.05); tsUse(2, t) end
                        task.wait(TS.delay)
                    end
                    TS.thread = nil
                end)
                Library:Notify("TEST Spam: ON", 2)
            else
                if TS.thread then pcall(task.cancel, TS.thread); TS.thread = nil end
                Library:Notify("TEST Spam: OFF", 2)
            end
        end,
    })
    ZL:AddSlider("ZTSDelay", {Text="TEST Spam Delay", Default=0.05, Min=0.01, Max=0.5, Rounding=2, Callback=function(v) TS.delay=v end})
    ZL:AddDivider()

    -- Kill Combo
    ZL:AddLabel("Kill Combo (V1+V2)")
    ZL:AddToggle("ZKC", {
        Text = "Kill Combo", Default = false,
        Callback = function(v)
            if v then
                if KC.running then return end
                KC.running = true; KC.enabled = true
                table.insert(KC.conns, task.spawn(function()
                    while KC.running do
                        local ts2 = KC.mode=="nearest" and {zNearest()} or zAll()
                        for _, t in ipairs(ts2) do if t then kcV1(t) end end
                        task.wait(KC.dv1)
                    end
                end))
                KC.conn2 = task.spawn(function()
                    while KC.running do
                        local ts2 = KC.mode=="nearest" and {zNearest()} or zAll()
                        for _, t in ipairs(ts2) do if t then kcV2(t) end end
                        task.wait(KC.dv2)
                    end
                end)
                Library:Notify("Kill Combo: ON", 3)
            else
                KC.running = false; KC.enabled = false
                for _, c in ipairs(KC.conns) do pcall(task.cancel, c) end
                KC.conns = {}
                if KC.conn2 then pcall(task.cancel, KC.conn2); KC.conn2 = nil end
                Library:Notify("Kill Combo: OFF", 2)
            end
        end,
    })
    ZL:AddDropdown("ZKCTarget", {Text="Objetivo", Values={"nearest","all"}, Default="nearest", Multi=false, Callback=function(v) KC.mode=v end})
    ZL:AddSlider("ZKCDV1", {Text="Delay V1", Default=0.05, Min=0.01, Max=0.3, Rounding=2, Callback=function(v) KC.dv1=v end})
    ZL:AddSlider("ZKCDV2", {Text="Delay V2", Default=0.5,  Min=0.1,  Max=2.0, Rounding=1, Callback=function(v) KC.dv2=v end})
    ZL:AddDivider()

    -- God Mode+ A
    ZL:AddLabel("God Mode+ Modo A (WallCombo)")
    ZL:AddToggle("ZGPA", {
        Text = "Modo A", Default = false,
        Callback = function(v)
            GPA.enabled = v
            if v then
                table.insert(GPA.conns, task.spawn(function()
                    while GPA.enabled do
                        local ts2 = GPA.tgt=="nearest" and {zNearest()} or zAll()
                        for _, t in ipairs(ts2) do if t then gpaFire(t) end end
                        task.wait(GPA.delay)
                    end
                end))
                Library:Notify("Modo A: ON", 2)
            else
                for _, c in ipairs(GPA.conns) do pcall(task.cancel, c) end
                GPA.conns = {}
                Library:Notify("Modo A: OFF", 2)
            end
        end,
    })
    ZL:AddDropdown("ZGPAT", {Text="Objetivo A", Values={"nearest","all"}, Default="nearest", Multi=false, Callback=function(v) GPA.tgt=v end})
    ZL:AddSlider("ZGPAD", {Text="Delay A", Default=0.05, Min=0.01, Max=0.5, Rounding=2, Callback=function(v) GPA.delay=v end})

    -- God Mode+ B
    ZL:AddLabel("God Mode+ Modo B (Ability4 9M)")
    ZL:AddToggle("ZGPB", {
        Text = "Modo B", Default = false,
        Callback = function(v)
            GPB.enabled = v
            if v then
                GPB.conn = task.spawn(function()
                    while GPB.enabled do
                        local ts2 = GPB.tgt=="nearest" and {zNearest()} or zAll()
                        for _, t in ipairs(ts2) do if t then gpbFire(t) end end
                        task.wait(0.1)
                    end
                end)
                Library:Notify("Modo B: ON", 2)
            else
                if GPB.conn then pcall(task.cancel, GPB.conn); GPB.conn = nil end
                Library:Notify("Modo B: OFF", 2)
            end
        end,
    })
    ZL:AddDropdown("ZGPBChar", {Text="Personaje (Ab4)", Values={"Gon","Mob","Sukuna","Nanami"}, Default="Gon", Multi=false,
        Callback=function(v) pcall(function() RS_Z.Remotes.Character.ChangeCharacter:FireServer(v) end) end})
    ZL:AddDropdown("ZGPBT", {Text="Objetivo B", Values={"nearest","all"}, Default="nearest", Multi=false, Callback=function(v) GPB.tgt=v end})
    ZL:AddLabel("Modo C = A + B → activa ambos arriba")

    -- Abilities Spam + Grab (derecha)
    ZR:AddLabel("Abilities Spam con Grab")
    ZR:AddDropdown("ZAbChar", {Text="Personaje", Values={"Gon","Mob","Sukuna","Nanami","Stark"}, Default="Gon", Multi=false,
        Callback=function(v) ABS.character=v end})
    ZR:AddDropdown("ZAbAbilities", {Text="Abilities (multi)", Values={"1","2","3","4"}, Default=1, Multi=true,
        Callback=function(v) ABS.abilities=v end})
    ZR:AddSlider("ZAbDelay", {Text="Delay", Default=0.05, Min=0.01, Max=0.5, Rounding=2, Callback=function(v) ABS.delay=v end})
    ZR:AddToggle("ZAbToggle", {
        Text = "Abilities Spam + Grab", Default = false,
        Callback = function(v)
            ABS.enabled = v
            if v then
                ABS.thread = task.spawn(function()
                    while ABS.enabled do
                        local t = zNearest()
                        if t then
                            for numStr, selected in pairs(ABS.abilities) do
                                if selected then
                                    task.spawn(absFire, t, ABS.character, numStr)
                                end
                            end
                        end
                        task.wait(ABS.delay)
                    end
                    ABS.thread = nil
                end)
                Library:Notify("Ab Spam+Grab: ON", 2)
            else
                ABS.enabled = false
                if ABS.thread then pcall(task.cancel, ABS.thread); ABS.thread = nil end
                Library:Notify("Ab Spam+Grab: OFF", 2)
            end
        end,
    })
    ZR:AddLabel("Spamea ability seleccionada con grab")

end 

SaveManager:LoadAutoloadConfig() puedes hacerme esto loadstring para usarlko en delta?
