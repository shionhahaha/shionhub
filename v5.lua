local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "カスタムツール V13.0 (Official Full Version)",
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

-- --- 全変数管理 ---
local TargetSpeed = 16
local TargetHitboxSize = 2
local HitboxEnabled = false
local TracersEnabled = false
local NamesEnabled = false
local Flying = false
local VFlying = false
local FlySpeed = 50 
local SelectedPlayer = ""
local TargetServerID = ""
local SelectedServerID = ""
local ServerListData = {}
local SelectedRemote = nil
local MonitorEnabled = false

-- --- タブ作成 ---
local MainTab = Window:CreateTab("メイン設定", 4483362458)
local TPTab = Window:CreateTab("プレイヤーTP", 4483362458)
local DebugTab = Window:CreateTab("リモートデバッグ", 4483362458)
local LogTab = Window:CreateTab("通信ログ表示", 4483362458)
local ServerTab = Window:CreateTab("サーバー設定", 4483362458)

-- --- メインタブ：移動・攻撃・ビジュアル設定 ---
MainTab:CreateSection("⚠️ 使用上の注意")
MainTab:CreateLabel("・このスクリプトの使用は自己責任でお願いします。")
MainTab:CreateLabel("・過度なスピードや飛行はBANのリスクがあります。")
MainTab:CreateLabel("・表示されているPingは全員の平均値です。")

MainTab:CreateSection("移動・攻撃設定")
MainTab:CreateInput({
   Name = "歩行スピード",
   PlaceholderText = "16",
   Callback = function(Text)
      TargetSpeed = tonumber(Text) or 16
   end,
})

MainTab:CreateButton({
   Name = "スピードを適用",
   Callback = function()
      local char = game.Players.LocalPlayer.Character
      if char and char:FindFirstChild("Humanoid") then
         char.Humanoid.WalkSpeed = TargetSpeed
      end
   end,
})

MainTab:CreateInput({
   Name = "ヒットボックスサイズ",
   PlaceholderText = "2",
   Callback = function(Text)
      TargetHitboxSize = tonumber(Text) or 2
   end,
})

MainTab:CreateToggle({
   Name = "ヒットボックス自動更新",
   CurrentValue = false,
   Callback = function(Value)
      HitboxEnabled = Value
   end,
})

MainTab:CreateSection("飛行設定")
MainTab:CreateInput({
   Name = "飛行スピード",
   PlaceholderText = "50",
   Callback = function(Text)
      FlySpeed = tonumber(Text) or 50
   end,
})

MainTab:CreateToggle({
   Name = "Fly (プレイヤー飛行)",
   CurrentValue = false,
   Callback = function(Value)
      Flying = Value
   end,
})

MainTab:CreateToggle({
   Name = "VFly (乗り物飛行)",
   CurrentValue = false,
   Callback = function(Value)
      VFlying = Value
   end,
})

MainTab:CreateSection("ビジュアル・最適化")
MainTab:CreateToggle({
   Name = "トレーサー (線)",
   CurrentValue = false,
   Callback = function(Value)
      TracersEnabled = Value
   end,
})

MainTab:CreateToggle({
   Name = "ネームタグ",
   CurrentValue = false,
   Callback = function(Value)
      NamesEnabled = Value
   end,
})

MainTab:CreateButton({
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

MainTab:CreateSection("操作設定")
MainTab:CreateKeybind({
   Name = "UIの表示/非表示キー",
   CurrentKeybind = "RightControl",
   HoldToInteract = false,
   Flag = "UIToggleKey", 
   Callback = function(Key)
      local gui = game:GetService("CoreGui"):FindFirstChild("Rayfield") or game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("Rayfield")
      if gui then gui.Enabled = not gui.Enabled end
   end,
})

MainTab:CreateButton({
   Name = "UIを完全に削除",
   Callback = function()
      Rayfield:Destroy()
   end,
})

-- --- リモートデバッグ：送信・受信分離スキャン ---
DebugTab:CreateSection("🔍 リモートスキャナー (RemoteEvent専用)")

local SendDropdown = DebugTab:CreateDropdown({
   Name = "送信リモート (Fire用)",
   Options = {"スキャンしてください"},
   CurrentOption = "",
   Callback = function(Option)
      local name = type(Option) == "table" and Option[1] or Option
      for _, v in pairs(game:GetDescendants()) do
          if v.Name == name and v:IsA("RemoteEvent") then
              SelectedRemote = v
              break
          end
      end
   end,
})

local ReceiveDropdown = DebugTab:CreateDropdown({
   Name = "受信リモート (監視用)",
   Options = {"スキャンしてください"},
   CurrentOption = "",
   Callback = function(Option)
      local name = type(Option) == "table" and Option[1] or Option
      for _, v in pairs(game:GetDescendants()) do
          if v.Name == name and v:IsA("RemoteEvent") then
              SelectedRemote = v
              break
          end
      end
   end,
})

DebugTab:CreateButton({
   Name = "🔍 送信/受信を判別してスキャン",
   Callback = function()
      local sendEvents = {}
      local receiveEvents = {}
      for _, v in pairs(game:GetDescendants()) do
         if v:IsA("RemoteEvent") then
            local lowName = v.Name:lower()
            -- 名前から受信・送信を推測して振り分け
            if lowName:find("receive") or lowName:find("on") or lowName:find("client") or lowName:find("update") or lowName:find("notify") then
               table.insert(receiveEvents, v.Name)
            else
               table.insert(sendEvents, v.Name)
            end
         end
      end
      SendDropdown:Refresh(sendEvents, true)
      ReceiveDropdown:Refresh(receiveEvents, true)
      Rayfield:Notify({Title = "スキャン完了", Content = "送信: " .. #sendEvents .. " / 受信: " .. #receiveEvents})
   end,
})

DebugTab:CreateButton({
   Name = "📋 全イベントのパスをコピー",
   Callback = function()
      local list = "-- REMOTE EVENT PATH LIST --\n"
      for _, v in pairs(game:GetDescendants()) do
         if v:IsA("RemoteEvent") then
            list = list .. string.format("[Event] %s\n", v:GetFullName())
         end
      end
      setclipboard(list)
      Rayfield:Notify({Title = "コピー成功", Content = "クリップボードに保存しました"})
   end,
})

DebugTab:CreateSection("⚙️ 実行テスト")
DebugTab:CreateButton({
   Name = "選択中のリモートを実行 (FireServer)",
   Callback = function()
      if SelectedRemote and SelectedRemote:IsA("RemoteEvent") then
         SelectedRemote:FireServer()
         Rayfield:Notify({Title = "送信完了", Content = SelectedRemote.Name .. " を送信しました"})
      else
         Rayfield:Notify({Title = "エラー", Content = "イベントをリストから選んでください"})
      end
   end,
})

-- --- 通信ログ表示：UIへリアルタイム出力 ---
LogTab:CreateSection("📡 サーバー受信ログ (Hook不要監視)")

LogTab:CreateToggle({
   Name = "受信ログをUIに表示",
   CurrentValue = false,
   Callback = function(Value)
      MonitorEnabled = Value
      if Value then
          Rayfield:Notify({Title = "モニター開始", Content = "通信を検知すると以下に表示されます"})
          for _, v in pairs(game:GetDescendants()) do
              if v:IsA("RemoteEvent") then
                  v.OnClientEvent:Connect(function(...)
                      if MonitorEnabled then
                          local args = {...}
                          local argStr = ""
                          for i, a in pairs(args) do 
                             argStr = argStr .. tostring(a) .. " (" .. type(a) .. "), " 
                          end
                          LogTab:CreateLabel("📩 [" .. v.Name .. "]: " .. argStr)
                      end
                  end)
              end
          end
      end
   end,
})

-- --- プレイヤーTPタブ ---
TPTab:CreateSection("プレイヤーテレポート")

local PlayerDropdown = TPTab:CreateDropdown({
   Name = "ターゲット選択",
   Options = {"更新してください"},
   CurrentOption = "",
   Callback = function(Option)
      SelectedPlayer = type(Option) == "table" and Option[1] or Option
   end,
})

TPTab:CreateButton({
   Name = "プレイヤーリストを更新",
   Callback = function()
      local p = {}
      for _, v in pairs(game.Players:GetPlayers()) do
         if v ~= game.Players.LocalPlayer then table.insert(p, v.Name) end
      end
      PlayerDropdown:Refresh(p, true)
      Rayfield:Notify({Title = "更新", Content = #p .. " 名のプレイヤーを検出"})
   end,
})

TPTab:CreateButton({
   Name = "選択した相手へテレポート",
   Callback = function()
      local target = game.Players:FindFirstChild(SelectedPlayer)
      if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
         game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
      else
         Rayfield:Notify({Title = "エラー", Content = "対象が見つかりません"})
      end
   end,
})

-- --- サーバー設定タブ ---
ServerTab:CreateSection("サーバー情報")
ServerTab:CreateButton({
   Name = "現在のサーバーIDをコピー",
   Callback = function()
      setclipboard(tostring(game.JobId))
      Rayfield:Notify({Title = "完了", Content = "JobIdをコピーしました"})
   end,
})

ServerTab:CreateButton({
   Name = "再接続 (Rejoin)",
   Callback = function()
      game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
   end,
})

ServerTab:CreateSection("サーバーブラウザ (Ping順)")
local ServerDropdown = ServerTab:CreateDropdown({
   Name = "サーバーを選択",
   Options = {"更新してください"},
   CurrentOption = "",
   Callback = function(Option)
      local label = type(Option) == "table" and Option[1] or Option
      if ServerListData[label] then SelectedServerID = ServerListData[label] end
   end,
})

ServerTab:CreateButton({
   Name = "🌏 サーバーリストを取得",
   Callback = function()
      local Http = game:GetService("HttpService")
      local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=50"
      local Raw = game:HttpGet(Api)
      local Data = Http:JSONDecode(Raw)
      local tempTable = {}
      local options = {}
      ServerListData = {}
      
      if Data and Data.data then
         for _, s in pairs(Data.data) do
            if s.id ~= game.JobId then table.insert(tempTable, s) end
         end
         table.sort(tempTable, function(a, b) return (a.ping or 999) < (b.ping or 999) end)
         for _, s in pairs(tempTable) do
            local label = (s.ping and s.ping < 120 and "✅" or "🌐") .. " [" .. (s.playing or 0) .. "/" .. (s.maxPlayers or 0) .. "] Ping: " .. (s.ping or "???")
            table.insert(options, label)
            ServerListData[label] = s.id
         end
         ServerDropdown:Refresh(options, true)
      end
   end,
})

ServerTab:CreateButton({
   Name = "選択したサーバーにテレポート",
   Callback = function()
      if SelectedServerID ~= "" then
         game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, SelectedServerID, game.Players.LocalPlayer)
      end
   end,
})

-- --- 常駐ループ：Fly / VFly エンジン ---
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

-- --- 常駐ループ：ESP / ヒットボックス ---
spawn(function()
   while wait(0.5) do
      pcall(function()
         local lplr = game.Players.LocalPlayer
         for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= lplr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
               local hrp = player.Character.HumanoidRootPart
               
               -- ヒットボックス処理
               if HitboxEnabled then
                  hrp.Size = Vector3.new(TargetHitboxSize, TargetHitboxSize, TargetHitboxSize)
                  hrp.Transparency = 0.7
                  hrp.BrickColor = BrickColor.new("Really red")
                  hrp.CanCollide = false
               else
                  hrp.Size = Vector3.new(2, 2, 1)
                  hrp.Transparency = 1
               end

               -- トレーサー処理
               if TracersEnabled then
                  local tracer = hrp:FindFirstChild("TracerLine")
                  if not tracer then
                     tracer = Instance.new("Beam", hrp)
                     tracer.Name = "TracerLine"
                     local a0 = Instance.new("Attachment", lplr.Character.HumanoidRootPart)
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

               -- ネームタグ処理
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
