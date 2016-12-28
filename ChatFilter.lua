local ChatFilter = {}

local ktDataDefault = {
  bEnabled = true,
  nMaxMessageLength = 120,
  arrWhitelist = {
    "T3",
    
    "WB",
    
    "Scorchwing",
    "SW",
    "Gargantua",
    "Garg",
    "Mechathorn",
    "Mecha",
    
    "Dreamspore",
    "DS",
    "Metal", "Maw",
    "MM",
    "King", "Honey", "Grave",
    "KHG",
    "Zoetic",
    "Zoe",
    
    "Metal", "Maw", "Prime",
    "MMP",
    "King", "Plush",
    "KP",
    "Grendelus",
    "Grend",
    "Kraggar",
    "Krag",
    
    "Matuk",
    "Kundar",
    "Frostgale",
    
    "Guardians", "Grove",
    "GotG",
    "Lightspire",
    "LS",
    
    "Veteran",
    "Adventure",
    "Dungeon",
    "Dungeons",
    "Vet",
    "Vets",
    "Fungeon",
    "Fungeons",
    
    "Genetic", "Archives",
    "GA",
    "Datascape",
    "DS",
    "Redmoon", "Terror",
    "RMT",
  },
  -- arrBlacklist = {},
}

local addonChatLog
local nRealmChannelId
local tWhitelist
-- local tBlacklist

function ChatFilter:Setup()
  addonChatLog = Apollo.GetAddon("ChatLog")
  self:FindRealmChannelId()
  self:SettingsUpdated()
  --self.xmlDoc = 
  --register xml doc loaded callback?
  Apollo.RegisterSlashCommand("cfilter", "OnSlashCommand", self)
  Apollo.RegisterSlashCommand("chatfilter", "OnSlashCommand", self)
end

function ChatFilter:FindRealmChannelId()
  for idx, channelCurrent in ipairs(ChatSystemLib.GetChannels()) do
    local eChannelType = channelCurrent:GetType()
    if eChannelType == ChatSystemLib.ChatChannel_Realm then
      nRealmChannelId = channelCurrent:GetUniqueId()
      return
    end
  end
end

function ChatFilter:SettingsUpdated()
  if addonChatLog == nil then return end
  if nRealmChannelId == nil then return end
  Apollo.RemoveEventHandler("ChatMessage", self)
  if self.tData.bEnabled then
    Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)
  end
  self:GenerateSearchLists()
end

function ChatFilter:GenerateSearchLists()
  tWhitelist = {}
  for idx, strWord in ipairs(self.tData.arrWhitelist) do
    tWhitelist[strWord:lower()] = true
  end
  -- tBlacklist = {}
  -- for idx, strWord in ipairs(self.tData.arrBlacklist) do
    -- tBlacklist[strWord:lower()] = true
  -- end
end

function ChatFilter:OnSlashCommand(strCmd, strParam)
  Print("TODO")
end

function ChatFilter:OnChatMessage(channelCurrent, tMessage)
  if channelCurrent:GetType() ~= ChatSystemLib.ChatChannel_Nexus then return end
  local strMessage = tostring(tMessage.arMessageSegments[1].strText)
  if strMessage:len() > self.tData.nMaxMessageLength then return end
  if self:SearchMessage(strMessage) then
    self:DisplayMessage(channelCurrent, tMessage)
  end
end

function ChatFilter:SearchMessage(strMessage)
  for strWord in strMessage:gmatch("%w+") do
    if tWhitelist[strWord:lower()] then
      return true
    end
  end
end

function ChatFilter:DisplayMessage(channelCurrent, tMessage)
  local tQueuedMessage = {
    tMessage = self:CloneTable(tMessage),
    eChannelType = channelCurrent:GetType(),
    strChannelName = channelCurrent:GetName(),
    strChannelCommand = channelCurrent:GetCommand(),
    idChannel = nRealmChannelId,
  }
  addonChatLog:HelperGenerateChatMessage(tQueuedMessage)
  addonChatLog:HelperQueueMessage(tQueuedMessage)
end

function ChatFilter:CloneTable(tData)
  local tClone = {}
  for k, v in pairs(tData) do
    if type(v) == "table" then
      tClone[k] = self:CloneTable(v)
    else
      tClone[k] = v
    end
  end
  setmetatable(tClone, getmetatable(tData))
  return tClone
end

function ChatFilter:OnSave(eLevel)
  if eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
    return self.tData
  end
end

function ChatFilter:OnRestore(eLevel, tSave)
  if eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
    self.tData = tSave
    self:SettingsUpdated()
  end
end

function ChatFilter:new(o)
  o = o or {
    tData = ktDataDefault,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function ChatFilter:Init()
  Apollo.RegisterAddon(self)
end

function ChatFilter:OnLoad()
  self:Setup()
end

local ChatFilterInst = ChatFilter:new()
ChatFilterInst:Init()
