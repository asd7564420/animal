require("zoo.util.HapticsKitUtil")
require("zoo.data.MetaManager")

GamePlayHapticsPlayer = class{}

local hapticsType = {
	"line_bomb",
	"wrap_bomb",
	"line_line_swap",
	"line_wrap_swap",
	"wrap_wrap_swap",
	"bird_animal_shake",
	"bird_line_change",
	"bird_wrap_change",
	"bird_bird_swap",
	"bird_bird_bomb",
	"step_to_line",
	"bird_wrap_bomb",
	"bird_line_bomb",
	"bonus_line_bomb",
}

local instance = nil

-- local function getRemoteCode(fileName, callback)
--     local url =  "http://ci.kxxxl.com/ciservice/file_tmp/"..tostring(fileName)
--     local request = HttpRequest:createGet(url)
--     local function onRequestFinished( response )
--         if response.httpCode ~= 200 then 
--             if _G.isLocalDevelopMode then printx(0, "get config error") end   
--             CommonTip:showTip("获取失败~~~"..tostring(response.httpCode))
--             if callback then callback(nil) end
--         else
--             RemoteDebug:uploadLogWithTag(fileName, response.body)
--             if callback then callback(response.body) end
--         end
--     end
--     HttpClient:getInstance():sendRequest(onRequestFinished, request)
-- end

function GamePlayHapticsPlayer:ctor()
	
end

function GamePlayHapticsPlayer:getInstance()
	if instance == nil then
		instance = GamePlayHapticsPlayer.new()
	end
	return instance
end

function GamePlayHapticsPlayer:initKit( ... )
	HapticsKitUtil:initKit()

	-- self:tryLoadConfig()

	self.isHapticsSupport = HapticsKitUtil:isSupport()
	self.isHapticsEnabled = HapticsKitUtil:isEnabled()
	self.isGuide1CanShow = false

	-- printx(15,"self.isSupport,self.isHapticsEnabled",self.isSupport,self.isHapticsEnabled)
end

function GamePlayHapticsPlayer:playEffect(scene)
	-- if self:isSupport() and self:isEnabled() then
		-- self.isGuide1CanShow = true
	-- end
	local playEffectSuccess = HapticsKitUtil:playEffect(scene)
	self.isGuide1CanShow = playEffectSuccess
end

function GamePlayHapticsPlayer:isSupport()
	-- printx(15,"GamePlayHapticsPlayer:isSupport",self.isHapticsSupport)
	return self.isHapticsSupport
end

function GamePlayHapticsPlayer:isEnabled()
	return self.isHapticsEnabled
end

function GamePlayHapticsPlayer:setEnabled(enable)
	self.isHapticsEnabled = enable
	HapticsKitUtil:setEnabled(enable)
end

function GamePlayHapticsPlayer:switchState( isOn, source )
	if not self.isHapticsSupport then
		-- CommonTip:showTip("不支持振动")
		return
	end
	self.isGuide1CanShow = false
	-- self.isHapticsEnabled = not self.isHapticsEnabled
	self.isHapticsEnabled = isOn
	HapticsKitUtil:setEnabled(self.isHapticsEnabled)

	local subCategory = ''

	if source == 1 then --关卡内
		subCategory = 'level_haptics_click'
	else 	--关卡外
		subCategory = 'switch_haptics_click'
	end

	if self.isHapticsEnabled then
		-- CommonTip:showTip("振动开启")
		DcUtil:UserTrack({category = 'stage', sub_category = subCategory, t1 = 2})
	else
		-- CommonTip:showTip("振动关闭")
		DcUtil:UserTrack({category = 'stage', sub_category = subCategory, t1 = 1})
	end
end

function GamePlayHapticsPlayer:tryLoadConfig()
	local platformName = "andriod"
    if __IOS then
        platformName = "ios"
    -- elseif PlatformConfig:isPlatform(PlatformNameEnum.kOppo) then
    -- 	platformName = "oppo"
    -- elseif PlatformConfig:isPlatform(PlatformNameEnum.kBBK) then
    -- 	platformName = "vivo"
    -- elseif PlatformConfig:isPlatform(PlatformNameEnum.kHuaWei) then
    -- 	platformName = "huawei"
    -- elseif PlatformConfig:isPlatform(PlatformNameEnum.kMI) then
    -- 	platformName = "mi"
    end
    -- printx(15,"platformName = ",platformName)
    -- platformName = "ios"
   --  getRemoteCode(fileName, function(codes)
   --      if codes then
   --          local ret = loadstring("return "..codes)
   --          printx(15,"配置ret",table.tostring(ret()))
   --          if ret then
   --              HapticsKitUtil:loadConfig(ret())
   --          end
   --          printx(15,"加载"..(ret and "成功!" or "失败~~~"))
   --      end
   -- end)

	self.allPlatformConfig = MetaManager.getInstance().haptics_config

	if not self.allPlatformConfig then return end
	
	for _,config in pairs(self.allPlatformConfig) do
		if config.configName and config.configName == platformName then
			self.tempConfig = config
			break
		end
	end

	self.config = self:convertConfigData(self.tempConfig)
	-- printx(15,"self.tempConfig",table.tostring(self.tempConfig))
   	HapticsKitUtil:loadConfig(self.config)
end

function GamePlayHapticsPlayer:convertConfigData( tempConfig )
	local configs = {}
	for _,oneConfig in pairs(hapticsType) do
		local config = {}
		config.data = {}

		if tempConfig[oneConfig] and string.len(tempConfig[oneConfig]) > 0 then
			local parts = string.split2(tempConfig[oneConfig],',')
			for _,part in pairs(parts) do
				local nums = string.split2(part,'_')
				local param = { tonumber(nums[1]) , tonumber(nums[2]) }
				if #parts == 1 then
					config.data = param
				else
					table.insert(config.data,param)
				end
			end
		end

		configs[oneConfig] = config
	end
	-- printx(15,"configs",table.tostring(configs))
	return configs
end

function GamePlayHapticsPlayer:checkGuide1()
	if UserManager.getInstance().user:getTopLevelId() <= 1 then 
		self:setGuide1()
		return false
	end

	if self.isGuide1CanShow and not UserManager.getInstance():hasGuideFlag(kGuideFlags.kHapticsGuide1) and 
		self:isSupport() and self:isEnabled() then
		return true
	else
		return false
	end
end

function GamePlayHapticsPlayer:setGuide1()
	UserLocalLogic:setGuideFlag(kGuideFlags.kHapticsGuide1)
end

function GamePlayHapticsPlayer:checkGuide2()
	return not UserManager.getInstance():hasGuideFlag(kGuideFlags.kHapticsGuide2)
end

function GamePlayHapticsPlayer:setGuide2()
	UserLocalLogic:setGuideFlag(kGuideFlags.kHapticsGuide2 )
end

function GamePlayHapticsPlayer:clearGuide2()
	UserManager.getInstance():clearGuideFlag(kGuideFlags.kHapticsGuide2)
end

function GamePlayHapticsPlayer:shouldShowReddotOutside()
	return self:isSupport() and (not CCUserDefault:sharedUserDefault():getBoolForKey("hasSeenHapticSetting", false))
end

function GamePlayHapticsPlayer:stopShowReddotOutside()
	CCUserDefault:sharedUserDefault():setBoolForKey("hasSeenHapticSetting", true)
	if HomeScene:sharedInstance().settingButton then
        HomeScene:sharedInstance().settingButton:updateDotTipStatus()
    end
end

function GamePlayHapticsPlayer:shouldShowReddotInside()
	return self:isSupport() and (not CCUserDefault:sharedUserDefault():getBoolForKey("hasDoneHapticSetting", false))
end

function GamePlayHapticsPlayer:stopShowReddotInside()
	CCUserDefault:sharedUserDefault():setBoolForKey("hasDoneHapticSetting", true)
end

function GamePlayHapticsPlayer:onActStartLevel(data) -- 每关重置
	self.isGuide1CanShow = false
end