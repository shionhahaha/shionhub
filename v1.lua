local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "カスタムツール V7.5 (Full Integration)",
   LoadingTitle = "全システム・ビジュアル読み込み中...",
   LoadingSubtitle = "by User",
   ConfigurationSaving = { Enabled = false },
   KeySystem = true, 
   KeySettings = {
      Title = "認証が必要",
      Subtitle = "Key System",
      Note = "しおんさまさいきょう",
      FileName = "CustomScriptKey", 
      SaveKey = true, 
      GrabKeyFromSite = false, 
      Key = {"しおんさまさいきょう"}
   }
})

local Tab = Window:CreateTab("メイン設定", 4483362458)
local TPTab = Window:CreateTab("プレイヤーTP", 4483362458)

-- --- 変数管理 ---
local TargetSpeed = 16
local TargetHitboxSize = 2
local HitboxEnabled = false
local TracersEnabled = false
local NamesEnabled = false
local Flying = false
local VFlying = false
local FlySpeed = 50 
local SelectedPlayer = ""

-- --- メインタブ：移動・攻撃設定 ---
Tab:CreateSection("移動・攻撃設定")

Tab:CreateInput({
   Name = "歩行スピード",
   PlaceholderText = "16",
   Callback = function(Text) TargetSpeed = tonumber(Text) or 16 end,
})

Tab:CreateButton({
   Name = "スピードを適用",
   Callback = function()
      local char = game.Players.LocalPlayer.Character
      if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = TargetSpeed end
   end,
})

Tab:CreateInput({
   Name = "ヒットボックスサイズ",
   PlaceholderText = "2",
   Callback = function(Text) TargetHitboxSize = tonumber(Text) or 2 end,
})

Tab:CreateToggle({
   Name = "ヒットボックス自動更新",
   CurrentValue = false,
   Callback = function(Value) HitboxEnabled = Value end,
})

-- --- メインタブ：飛行設定 ---
Tab:CreateSection("飛行設定")

Tab:CreateInput({
   Name = "飛行スピード",
   PlaceholderText = "50",
   Callback = function(Text) FlySpeed = tonumber(Text) or 50 end,
})

Tab:CreateToggle({
   Name = "Fly (プレイヤー飛行)",
   CurrentValue = false,
   Callback = function(Value) Flying = Value end,
})

Tab:CreateToggle({
   Name = "VFly (乗り物飛行)",
   CurrentValue = false,
   Callback = function(Value) VFlying = Value end,
})

-- --- メインタブ：ビジュアル・最適化 ---
Tab:CreateSection("ビジュアル・最適化")

Tab:CreateToggle({
   Name = "トレーサー (線)",
   CurrentValue = false,
   Callback = function(Value) TracersEnabled = Value end,
})

Tab:CreateToggle({
   Name = "ネームタグ",
   CurrentValue = false,
   Callback = function(Value) NamesEnabled = Value end,
})

Tab:CreateButton({
   Name = "超低画質モード (FPS向上)",
   Callback = function()
      game:GetService("Lighting").GlobalShadows = false
      game:GetService("Lighting").FogEnd = 9e9
      settings().Rendering.QualityLevel = "Level01"
      for i, v in pairs(game:GetDescendants()) do
         if v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") then 
            v:Destroy()
         elseif v:IsA("BasePart") or v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
         end
      end
      Rayfield:Notify({Title = "最適化", Content = "描画負荷を軽減しました"})
   end,
})

-- --- メインタブ：キーバインド ---
Tab:CreateSection("操作設定（キーバインド）")

Tab:CreateKeybind({
   Name = "UIの表示/非表示キー",
   CurrentKeybind = "RightControl",
   HoldToInteract = false,
   Flag = "UIToggleKey", 
   Callback = function(Keybind)
      local gui = game:GetService("CoreGui"):FindFirstChild("Rayfield") or game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("Rayfield")
      if gui then gui.Enabled = not gui.Enabled end
   end,
})

Tab:CreateKeybind({
   Name = "Flyのオン/オフ切り替えキー",
   CurrentKeybind = "F",
   HoldToInteract = false,
   Flag = "FlyToggleKey", 
   Callback = function(Keybind)
      Flying = not Flying
      Rayfield:Notify({Title = "Fly切り替え", Content = "Fly: " .. (Flying and "ON" or "OFF"), Duration = 1.5})
   end,
})

Tab:CreateButton({
   Name = "UIを完全に削除",
   Callback = function() Rayfield:Destroy() end,
})

-- --- プレイヤーTPタブ ---
TPTab:CreateSection("テレポート")

local PlayerDropdown = TPTab:CreateDropdown({
   Name = "相手を選択",
   Options = {"更新してください"},
   CurrentOption = "",
   Flag = "TPTarget",
   Callback = function(Option)
      if type(Option) == "table" then SelectedPlayer = Option[1] else SelectedPlayer = Option end
   end,
})

TPTab:CreateButton({
   Name = "プレイヤーリストを更新",
   Callback = function()
      local players = {}
      for _, v in pairs(game.Players:GetPlayers()) do
         if v ~= game.Players.LocalPlayer then table.insert(players, v.Name) end
      end
      PlayerDropdown:Refresh(players, true)
      Rayfield:Notify({Title = "更新成功", Content = #players .. " 人見つかりました"})
   end,
})

TPTab:CreateButton({
   Name = "選択した相手へTP",
   Callback = function()
      local target = game.Players:FindFirstChild(SelectedPlayer)
      if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
         game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
      else
         Rayfield:Notify({Title = "TPエラー", Content = "プレイヤーが見つかりません"})
      end
   end,
})

-- --- 飛行(Fly)エンジン ---
game:GetService("RunService").RenderStepped:Connect(function()
    local char = game.Players.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    
    if Flying or VFlying then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local target = (VFlying and hum and hum.SeatPart) or root
        
        local bv = target:FindFirstChild("FlyBV") or Instance.new("BodyVelocity", target)
        local bg = target:FindFirstChild("FlyBG") or Instance.new("BodyGyro", target)
        
        bv.Name = "FlyBV"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bg.Name = "FlyBG"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = workspace.CurrentCamera.CFrame
        
        local dir = Vector3.new(0,0,0)
        local uis = game:GetService("UserInputService")
        local cam = workspace.CurrentCamera
        
        if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        
        bv.Velocity = dir * FlySpeed
    else
        if root:FindFirstChild("FlyBV") then root.FlyBV:Destroy() end
        if root:FindFirstChild("FlyBG") then root.FlyBG:Destroy() end
    end
end)

-- --- ESP / トレーサー / ヒットボックス 統合ループ ---
spawn(function()
    while wait(0.5) do
        pcall(function()
            local lplr = game.Players.LocalPlayer
            local lchar = lplr.Character
            local lroot = lchar and lchar:FindFirstChild("HumanoidRootPart")

            for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                if player ~= lplr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    
                    -- ヒットボックス
                    if HitboxEnabled then
                        hrp.Size = Vector3.new(TargetHitboxSize, TargetHitboxSize, TargetHitboxSize)
                        hrp.Transparency = 0.7
                        hrp.BrickColor = BrickColor.new("Really red")
                        hrp.CanCollide = false
                    else
                        hrp.Size = Vector3.new(2, 2, 1)
                        hrp.Transparency = 1
                    end

                    -- トレーサー
                    if TracersEnabled and lroot then
                        local tracer = hrp:FindFirstChild("TracerLine")
                        if not tracer then
                            tracer = Instance.new("Beam", hrp)
                            tracer.Name = "TracerLine"
                            local a0 = Instance.new("Attachment", lroot)
                            local a1 = Instance.new("Attachment", hrp)
                            tracer.Attachment0 = a0
                            tracer.Attachment1 = a1
                            tracer.Width0 = 0.1
                            tracer.Width1 = 0.1
                            tracer.Color = ColorSequence.new(Color3.new(1, 0, 0))
                            tracer.FaceCamera = true
                        end
                    else
                        if hrp:FindFirstChild("TracerLine") then hrp.TracerLine:Destroy() end
                    end

                    -- ネームタグ
                    if NamesEnabled then
                        local tag = hrp:FindFirstChild("ESPNameTag")
                        if not tag then
                            tag = Instance.new("BillboardGui", hrp)
                            tag.Name = "ESPNameTag"
                            tag.AlwaysOnTop = true
                            tag.Size = UDim2.new(0, 200, 0, 50)
                            tag.ExtentsOffset = Vector3.new(0, 3, 0)
                            local label = Instance.new("TextLabel", tag)
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.Text = player.Name
                            label.TextColor3 = Color3.new(1, 1, 1)
                            label.TextStrokeTransparency = 0
                            label.TextSize = 14
                        end
                    else
                        if hrp:FindFirstChild("ESPNameTag") then hrp.ESPNameTag:Destroy() end
                    end
                end
            end
        end)
    end
end)
