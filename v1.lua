local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "カスタムツール V6.0 (Key System)",
   LoadingTitle = "読み込み中...",
   LoadingSubtitle = "by User",
   ConfigurationSaving = { Enabled = false },
   KeySystem = true, 
   KeySettings = {
      Title = "認証が必要",
      Subtitle = "Key System",
      Note = "アクセスするにはキーを入力してください",
      FileName = "CustomScriptKey", 
      SaveKey = true, 
      GrabKeyFromSite = false, 
      Key = {"しおんさまさいきょう"}
   }
})

local Tab = Window:CreateTab("メイン設定", 4483362458)

local TargetSpeed = 16
local TargetHitboxSize = 2
local HitboxEnabled = false
local TracersEnabled = false
local NamesEnabled = false

-- Fly/VFly 用の変数
local Flying = false
local VFlying = false
local FlySpeed = 50 -- 初期速度

-- --- スピード設定 (歩行) ---
Tab:CreateInput({
   Name = "スピードの値を入力",
   PlaceholderText = "例: 50",
   Callback = function(Text) TargetSpeed = tonumber(Text) or 16 end,
})

Tab:CreateButton({
   Name = "スピードを適用する",
   Callback = function()
      local char = game.Players.LocalPlayer.Character
      if char and char:FindFirstChild("Humanoid") then
         char.Humanoid.WalkSpeed = TargetSpeed
      end
   end,
})

-- --- ヒットボックス設定 ---
Tab:CreateInput({
   Name = "ヒットボックスの値を入力",
   PlaceholderText = "標準は 2",
   Callback = function(Text) TargetHitboxSize = tonumber(Text) or 2 end,
})

Tab:CreateToggle({
   Name = "ヒットボックス自動更新",
   CurrentValue = false,
   Callback = function(Value) HitboxEnabled = Value end,
})

-- --- 飛行速度設定 (追加分) ---
Tab:CreateInput({
   Name = "飛行スピード (Fly/VFly) を入力",
   PlaceholderText = "デフォルト: 50",
   Callback = function(Text) 
      local num = tonumber(Text)
      if num then
         FlySpeed = num
      end
   end,
})

-- --- 飛行機能 (Fly / VFly) ---
Tab:CreateToggle({
   Name = "Fly (プレイヤー飛行)",
   CurrentValue = false,
   Callback = function(Value)
      Flying = Value
      if not Value then
         local char = game.Players.LocalPlayer.Character
         if char and char:FindFirstChild("HumanoidRootPart") then
            if char.HumanoidRootPart:FindFirstChild("FlyBV") then char.HumanoidRootPart.FlyBV:Destroy() end
            if char.HumanoidRootPart:FindFirstChild("FlyBG") then char.HumanoidRootPart.FlyBG:Destroy() end
         end
      end
   end,
})

Tab:CreateToggle({
   Name = "VFly (乗り物飛行)",
   CurrentValue = false,
   Callback = function(Value)
      VFlying = Value
   end,
})

-- --- ESP・描画系 ---
Tab:CreateToggle({
   Name = "プレイヤーと自分を線で結ぶ",
   CurrentValue = false,
   Callback = function(Value) TracersEnabled = Value end,
})

Tab:CreateToggle({
   Name = "ネームタグを表示",
   CurrentValue = false,
   Callback = function(Value) NamesEnabled = Value end,
})

-- --- 最適化 ---
Tab:CreateButton({
   Name = "超低画質モード (色のみにする)",
   Callback = function()
      game:GetService("Lighting").GlobalShadows = false
      game:GetService("Lighting").FogEnd = 9e9
      settings().Rendering.QualityLevel = "Level01"
      for i, v in pairs(game:GetDescendants()) do
         if v:IsA("Decal") or v:IsA("Texture") then v:Destroy()
         elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v:Destroy()
         elseif v:IsA("BasePart") or v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
         elseif v:IsA("SpecialMesh") then v.TextureId = ""
         end
      end
      Rayfield:Notify({Title = "最適化完了", Content = "すべての描画を削除しました"})
   end,
})

--- 飛行制御ロジック (Fly & VFly) ---
game:GetService("RunService").RenderStepped:Connect(function()
    local player = game.Players.LocalPlayer
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    local camera = workspace.CurrentCamera
    
    if Flying or VFlying then
        local target = VFlying and (char:FindFirstChildOfClass("Humanoid").SeatPart or root) or root
        if not target then return end

        local bv = target:FindFirstChild("FlyBV") or Instance.new("BodyVelocity", target)
        local bg = target:FindFirstChild("FlyBG") or Instance.new("BodyGyro", target)
        
        bv.Name = "FlyBV"
        bg.Name = "FlyBG"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = camera.CFrame
        
        local dir = Vector3.new(0,0,0)
        local uis = game:GetService("UserInputService")
        
        if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        
        bv.Velocity = dir * FlySpeed
    else
        if root:FindFirstChild("FlyBV") then root.FlyBV:Destroy() end
        if root:FindFirstChild("FlyBG") then root.FlyBG:Destroy() end
    end
end)

--- 更新用ループ (1秒周期) ---
spawn(function()
   while wait(1) do
      local lplr = game.Players.LocalPlayer
      local char = lplr.Character
      local root = char and char:FindFirstChild("HumanoidRootPart")

      for _, player in pairs(game:GetService("Players"):GetPlayers()) do
         if player ~= lplr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            if HitboxEnabled then
               hrp.Size = Vector3.new(TargetHitboxSize, TargetHitboxSize, TargetHitboxSize)
               hrp.Transparency = 0.7
               hrp.BrickColor = BrickColor.new("Really red")
               hrp.CanCollide = false
            else
               hrp.Size = Vector3.new(2, 2, 1)
               hrp.Transparency = 1
            end
            if TracersEnabled and root then
               if not hrp:FindFirstChild("TracerBeam") then
                  local att0 = Instance.new("Attachment", root)
                  local att1 = Instance.new("Attachment", hrp)
                  att1.Name = "TracerAttachment"
                  local beam = Instance.new("Beam", hrp)
                  beam.Name = "TracerBeam"
                  beam.Attachment0 = att0
                  beam.Attachment1 = att1
                  beam.Width0 = 0.1
                  beam.Width1 = 0.1
                  beam.FaceCamera = true
                  beam.Color = ColorSequence.new(Color3.new(1, 0, 0))
               end
            else
               if hrp:FindFirstChild("TracerBeam") then hrp.TracerBeam:Destroy() end
               if hrp:FindFirstChild("TracerAttachment") then hrp.TracerAttachment:Destroy() end
            end
            if NamesEnabled then
               if not hrp:FindFirstChild("NameTagGui") then
                  local bbg = Instance.new("BillboardGui", hrp)
                  bbg.Name = "NameTagGui"
                  bbg.AlwaysOnTop = true
                  bbg.Size = UDim2.new(0, 100, 0, 50)
                  bbg.ExtentsOffset = Vector3.new(0, 3, 0)
                  local lbl = Instance.new("TextLabel", bbg)
                  lbl.BackgroundTransparency = 1
                  lbl.Size = UDim2.new(1, 0, 1, 0)
                  lbl.Text = player.Name
                  lbl.TextColor3 = Color3.new(1, 1, 1)
                  lbl.TextSize = 14
               end
            else
               if hrp:FindFirstChild("NameTagGui") then hrp.NameTagGui:Destroy() end
            end
         end
      end
   end
end)
