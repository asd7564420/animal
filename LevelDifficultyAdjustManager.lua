-- require "zoo.gamePlay.LevelTargetProgressData"
require "zoo.gamePlay.InLevelDynamicDiffAdjustManager"
require "zoo.gamePlay.FuuuDiffAdjustManager"
require "zoo.gamePlay.FarmStarFuuuPlayLevelCounter"
require "zoo.gamePlay.HardLevelAdjustLogic"
require "zoo.gamePlay.LowActiveAdjustLogic"
require "zoo.gamePlay.PayUserAdjustLogic"

local NewReturnAndLowActiveAdjustLogic = require "zoo.gamePlay.NewReturnAndLowActiveAdjustLogic"


AdjustUnactivateReason = {
	
	kMaintenanceUnavailable = 1 ,
	kNotMainLevel = 2 ,
	kTooCloseToMaxLevel = 3 ,
	kNotTopLevel = 4 ,
	kStarNotZero = 5 ,

	kIOSPayUser = 8 ,
	kAndroidPayUser = 9 ,

	kReason1002 = 1002,
	kReason20 = 20,
	kReason21 = 21,
	kReason22 = 22,
	kReason6 = 6,
	kReason7 = 7,

	kTooManyStar = 31, --
	kTopLevel = 32,
	kNoLevelTargetProgress = 33,
	kAskForHelpMode = 34,
	kUnlucky = 35, 
	kNoCollectStarEffective = 36,
	kBlockByTsumBuff = 37,
	kTravelFailNotEnough = 38,

	kHardLevelZeroDS = 40,
	kFarmFuuuSwitchOff = 41,

	kDiffTooLow = 50,
	kLow100Level = 51,

	kGuideLevel = 99,

	kActMagicCrystalBall = 1000 --活动：魔力泡泡球
}

LevelDifficultyAdjustReason = {
	kAICore = 'ai_core',
}


LevelDifficultyAdjustManager = {}

function LevelDifficultyAdjustManager:getNewReturnAndLowActiveAdjustLogic()
	return NewReturnAndLowActiveAdjustLogic
end


LevelDifficultyAdjustTopLevelLength = 15


local currFuuuInlevelDecisionExpName = "FuuuInlevelDecisionExpN1" 
local currFuuuDecreaseColorExpName = "FuuuDecreaseColorExp1" 
local hardLevelAdjustExpName = "LevelDifficultyAdjustForHardLevel"
local lowActiveAdjustExpName = "LevelDifficultyAdjustForLowActive"
local payUserAdjustExpName = "LevelDifficultyAdjustForPayUser2020"
local fuuuExpName = "FuuuAdjustExp1"
local newReturnAndLowActiveExpName = "LevelDifficultyAdjustForBackandLowV1"

local currExpName = "FuuuExp23" 
-- local oldExpName = "FuuuExp18" -- 此处不要修改，AI组用户永远锁定到该分组
local oldExpName = currExpName -- 需求又改回去了-。-

local farmStarGroupNames = {'A1', 'A2', 'A3', 'A4', 'B1' , 'None'}

function LevelDifficultyAdjustManager:getExpName()
	if HEAICore:getUserGroupId(true) == 2 then
		return oldExpName
	else
		return currExpName
	end
end

function LevelDifficultyAdjustManager:getFuuuExpName()
	return fuuuExpName
end

function LevelDifficultyAdjustManager:getFuuuInlevelDecisionExpName()
	return currFuuuInlevelDecisionExpName
end

function LevelDifficultyAdjustManager:getFuuuDecreaseColorExpName()
	return currFuuuDecreaseColorExpName
end

function LevelDifficultyAdjustManager:getHardLevelAdjustExpName()
	return hardLevelAdjustExpName
end

function LevelDifficultyAdjustManager:getLowActiveAdjustExpName()
	return lowActiveAdjustExpName
end

function LevelDifficultyAdjustManager:getPayUserAdjustExpName()
	return payUserAdjustExpName
end

LevelDifficultyAdjustManager.DAManager = InLevelDynamicDiffAdjustManager:create()
LevelDifficultyAdjustManager.FuuuManager = FuuuDiffAdjustManager:create( LevelDifficultyAdjustManager )
local kTriggerGroupLimit = 30
local localDataKey = "LDA"
local localLevelDataKey = "LDB"

local function getCurrUid()
	return UserManager:getInstance():getUID() or "12345"
end

local function getLocalFilePath()
	return localDataKey .. "_" .. tostring(getCurrUid()) .. ".ds"
end

local function getLocalLevelDataFilePath()
	return localLevelDataKey .. "_" .. tostring(getCurrUid()) .. ".ds"
end

function LevelDifficultyAdjustManager:onGameLaunch()
	if NewReturnAndLowActiveAdjustLogic then
		NewReturnAndLowActiveAdjustLogic:onGameLaunch()
	end
end

if GlobalEventDispatcher then
	GlobalEventDispatcher:getInstance():addEventListener( kGlobalEvents.kUserDataInit , function () LevelDifficultyAdjustManager:onGameLaunch() end )
end

function LevelDifficultyAdjustManager:onActPassLevel( passLevelData )
	if NewReturnAndLowActiveAdjustLogic then
		NewReturnAndLowActiveAdjustLogic:onPassLevel( true , passLevelData.levelId , passLevelData.strategyID )
	end
end

function LevelDifficultyAdjustManager:onActFailLevel( failLevelData )
	if NewReturnAndLowActiveAdjustLogic then
		NewReturnAndLowActiveAdjustLogic:onPassLevel( false , failLevelData.levelId , failLevelData.strategyID )
	end
end

function LevelDifficultyAdjustManager:onActPassDay()
	if NewReturnAndLowActiveAdjustLogic then
		NewReturnAndLowActiveAdjustLogic:onPassDay()
	end
end


function LevelDifficultyAdjustManager:getDAManager()
	return self.DAManager
end

function LevelDifficultyAdjustManager:getFuuuManager()
	return self.FuuuManager
end

function LevelDifficultyAdjustManager:getRandomIndex()
	if not self.randomIndex then
		self.randomIndex = math.random(1, 5)
	end

	--[[
	self.randomIndex = self.randomIndex + math.random(1, 4)

	if self.randomIndex > 5 then
		self.randomIndex = self.randomIndex - 5
	end
	]]
	self.randomIndex = self.randomIndex + 1
	if self.randomIndex > 5 then
		self.randomIndex = 1
	end


	local path = getLocalFilePath()
	
	local localData = Localhost:readFromStorage(path)
	if localData then
		localData.randomIndex = self.randomIndex
	end

	Localhost:writeToStorage(localData, path)
	--Localhost:safeWriteStringToFile( table.serialize(localData) , path .. "2" )

	return self.randomIndex
end

function LevelDifficultyAdjustManager:getMD5ByLevelMeta(meta)

	if meta then
		--printx( 1 , "LevelDifficultyAdjustManager:loadAndInitConfig 2 " .. tostring(i) .. " meta =" , table.tostring(meta)   )

		local function getmd5(t)
			local txt = table.tostring(meta)
			return HeMathUtils:md5( txt )
		end

		local md5str = nil
   		
   		local function doaction()
   			if meta.contentTable[1] then
				md5str = meta.contentTable[1]--HeMathUtils:md5( table.serialize( meta.contentTable ) )
			end
   		end
		
		local function doamf3()
			local str1 = meta.contentTable[2]--amf3.encode( meta.contentTable )
			local str2 = mime.b64(str1)
			md5str = HeMathUtils:md5( str2 ) 
		end
		pcall( doaction )

		if not md5str then
			pcall( doamf3 )
		end

		return md5str
	end
end

function LevelDifficultyAdjustManager:isActivationUser()
	local activationTag = self.context.fixedActivationTag
	DiffAdjustQAToolManager:print( 1 , "RRR" , "isActivationUser activationTag" , activationTag )
	if activationTag and 
		( activationTag == UserTagValueMap[UserTagNameKeyFullMap.kActivation].kWillLose 
			or activationTag == UserTagValueMap[UserTagNameKeyFullMap.kActivation].kReturnBack ) then 
		return true
	end
	return false
end

function LevelDifficultyAdjustManager:clearBefourStartLevel()
	-- DiffAdjustQAToolManager:print( 1 , "LevelDifficultyAdjustManager:clearBefourStartLevel" )
	self:clearContext()
	self:clearStrategyIDList()
	self:clearStrategyData()
	self:clearCurrStrategyID()
	self:clearLastUnactivateReason()
	self:clearLastFuuuUnactivateReason()
	self.DAManager:reset()
	self.FuuuManager:reset()
	ReplayDataManager:clearCurrLevelReplayData()
	ProductItemDiffChangeLogic:endLevel()
end

function LevelDifficultyAdjustManager:loadLevelTargetProgerssData( levelId , callback )
	if not self.localLevelData then 
		if callback then callback(false) end
		return 
	end

	if levelId <= 15 then 
		if callback then callback(false) end
		return 
	end

	local levelTargetProgress = self.localLevelData.levelTargetProgress or {}
	if levelTargetProgress[tostring(levelId)] then
		if callback then callback(false) end
		return
	end

	local http = GetPassLevelDataHttp.new(false)    
	http:addEventListener(Events.kComplete, function ( evt )
		if evt and evt.data and evt.data.levelTargetProgress then
			local result = self:getFuuuManager():buildLevelTargetProgressByRespData( evt.data.levelTargetProgress )
			self:mergeLevelTargetProgressData(result)
			
			local levelTargetProgress = self.localLevelData.levelTargetProgress or {}
			if levelTargetProgress[tostring(levelId)] then
				Localhost:writeToStorage(self.localLevelData, getLocalLevelDataFilePath() )
			end

			if callback then callback(true) end
		else
			if callback then callback(false) end
		end
	end)
	http:addEventListener(Events.kError, function ( ... )
		-- body
		if callback then callback(false) end
	end)
	http:syncLoad( {} , {} , {} , {} , {} , {levelId})
end

function LevelDifficultyAdjustManager:hasLevelTargetProgressData( levelId )
	if not self.localLevelData then return false end
	local curDatas = self.localLevelData.levelTargetProgress or {}
	return curDatas[tostring(levelId)] ~= nil
end

function LevelDifficultyAdjustManager:mergeLevelTargetProgressData( newDatas )
	if not self.localLevelData then return end
	local curDatas = self.localLevelData.levelTargetProgress or {}
	for k, v in pairs(newDatas or {}) do
		curDatas[k] = v
	end
	self.localLevelData.levelTargetProgress = curDatas
end

function LevelDifficultyAdjustManager:loadSingleLevelTargetProgerssDataByAI( levelId , callback )

	-- local log = {}
 --    log.method = "loadSingleLevelTargetProgerssDataByAI  p1 " .. tostring(levelId)
 --    ReplayDataManager:addMctsLogs("N3",log)

    if not self.localLevelData then
		self.localLevelData = Localhost:readFromStorage( getLocalLevelDataFilePath() )

		-- local log = {}
	 --    log.method = "loadSingleLevelTargetProgerssDataByAI  p2 " .. getLocalLevelDataFilePath()
	 --    ReplayDataManager:addMctsLogs("N3",log)

		if not self.localLevelData then
			self.localLevelData = self:createDefaultLocalLevelData()
		end
	end

	if self.localLevelData and self.localLevelData.levelTargetProgress and self.localLevelData.levelTargetProgress[tostring(levelId)] then
		
		-- local log = {}
	 --    log.method = "loadSingleLevelTargetProgerssDataByAI  p3 "
	 --    ReplayDataManager:addMctsLogs("N3",log)

		if callback then callback(true) end
	else
		-- local url = "http://10.130.137.97/devService?type=levelTargetProgress"
		local url = "http://10.2.0.8/devService?type=levelTargetProgress"
		local params = string.format("&levelId=" .. tostring(levelId))
		url = url .. params

		-- local log = {}
	 --    log.method = "loadSingleLevelTargetProgerssDataByAI  p4 " .. url
	 --    ReplayDataManager:addMctsLogs("N3",log)

		local request = HttpRequest:createGet(url)

	  	local connection_timeout = 2

	    request:setConnectionTimeoutMs(connection_timeout * 1000)
	    request:setTimeoutMs(30 * 1000)
	   
	    local function onLoaded( response )

	    	if response.httpCode ~= 200 then 

	    		-- local log = {}
			    -- log.method = "loadSingleLevelTargetProgerssDataByAI  p5 " .. table.tostring(response)
			    -- ReplayDataManager:addMctsLogs("N3",log)

		        if callback then callback(false) end
	    	else
	    		local message = response.body
	    		local metaDatas = table.deserialize( message )
	    		
	    		if metaDatas then

	    			-- local log = {}
				    -- log.method = "loadSingleLevelTargetProgerssDataByAI  p6 "
				    -- ReplayDataManager:addMctsLogs("N3",log)

	    			local datas = {}
	    			datas.levelTargetProgress = metaDatas
	    			self:updateLevelData( datas , "aiMode" )

			        if callback then callback(true) end
		    	else
		    		-- local log = {}
				    -- log.method = "loadSingleLevelTargetProgerssDataByAI  p7 "
				    -- ReplayDataManager:addMctsLogs("N3",log)

			        if callback then callback(false) end
		    	end
	    	end
	    end

	    HttpClient:getInstance():sendRequest(onLoaded, request)
	end
end

function LevelDifficultyAdjustManager:loadLevelTargetProgerssDataByAI( callback )

	local function hasNetwork()

        local url = NetworkConfig.maintenanceURL
		--http://10.130.137.97/config?name=maintenance&uid=12345&_v=nil
		local params = string.format("?name=level_target_progress")
		url = url .. params
		
		local request = HttpRequest:createGet(url)

	  	local connection_timeout = 2

	    request:setConnectionTimeoutMs(connection_timeout * 1000)
	    request:setTimeoutMs(30 * 1000)
	   
	    local function onLoaded( response )

	    	if response.httpCode ~= 200 then 
		        if callback then callback(false) end
	    	else
	    		local message = response.body
	    		local metaXML = xml.eval(message) 
	    		if metaXML then

	    			local datas = {}
	    			datas.levelTargetProgress = metaXML
	    			self:updateLevelData( datas , "aiMode" )

			        if callback then callback(true) end
		    	else

			        if callback then callback(false) end
		    	end
	    	end
	    end

	    HttpClient:getInstance():sendRequest(onLoaded, request)
	end

	local function hasNoNetwork()

		if callback then callback(false) end
	end

	if not self.localLevelData then
		self.localLevelData = Localhost:readFromStorage( getLocalLevelDataFilePath() )

		if not self.localLevelData then
			self.localLevelData = self:createDefaultLocalLevelData()
		end
	end

	if self.localLevelData and self.localLevelData.levelTargetProgress and self.localLevelData.levelTargetProgress["1"] then
		if callback then callback(true) end
	else
		PaymentNetworkCheck:getInstance():check( hasNetwork , hasNoNetwork )
	end
end

function LevelDifficultyAdjustManager:loadAndInitConfig()

	local userData = UserManager:getInstance():getUserRef()
	local topLevel = userData:getTopLevelId()

	
	local needLevelNum = 0

	local levelKeyMap = {}

	local propSeedLevelKeys = nil
	local propSeedLogLevelKeys = nil
	local virtualSeedLevelKeys = nil
	local levelLeftMoves = nil
	local levelTargetProgress = nil

	local uid = getCurrUid()

	local passLevelDataKeys = {}

	for i = topLevel , topLevel + 30 do
		--[[
		local meta = LevelMapManager.getInstance():getMeta(i)
		if meta then
			local md5str = self:getMD5ByLevelMeta(meta)
			table.insert( passLevelDataKeys , { first = md5str , second = i } )
		end
		]]

		table.insert( passLevelDataKeys , { first = "0" , second = i } ) --后端已经不区分关卡配置版本号
	end
	if #passLevelDataKeys == 0 then passLevelDataKeys = nil end


	if MaintenanceManager:getInstance():isEnabled("VirtualSeed") 
		and not MaintenanceManager:getInstance():isEnabledInGroup("VirtualSeed" , "G3" , uid) 
		and not MaintenanceManager:getInstance():isEnabledInGroup("VirtualSeed" , "G0" , uid) then
		needLevelNum = 20

		local startLevelId = topLevel

		local levelIds = {}

		for i = startLevelId , startLevelId + (needLevelNum - 1) do
			levelIds[i] = true
		end

		propSeedLevelKeys = {}

		for k , v in pairs(levelIds) do

			if levelKeyMap[k] then
				table.insert( propSeedLevelKeys , { first = levelKeyMap[k] , second = k } )
			else
				local meta = LevelMapManager.getInstance():getMeta(k)
				if meta then
					local md5str = self:getMD5ByLevelMeta(meta)
					table.insert( propSeedLevelKeys , { first = md5str , second = k } )
					levelKeyMap[k] = md5str
				end
			end
		end

		propSeedLogLevelKeys = {}
		table.insert( propSeedLogLevelKeys , topLevel )


		virtualSeedLevelKeys = {}
		table.insert( virtualSeedLevelKeys , topLevel )

	end

	local levelDifficultyAdjustV2Group = 0

	for i = 1 , kTriggerGroupLimit do
		if MaintenanceManager:getInstance():isEnabledInGroup( self:getExpName()  , "A" .. tostring(i) , uid) then
			levelDifficultyAdjustV2Group = i
			break
		end
	end

	if levelDifficultyAdjustV2Group > 0 then
		
		levelLeftMoves = {}

		for i = topLevel , topLevel + (LevelDifficultyAdjustTopLevelLength - 1) do

			-- local realLevelId = LevelMapManager.getInstance():getMetaLevelId( i )
			-- table.insert( levelLeftMoves , realLevelId )
			table.insert( levelLeftMoves , i )

		end

		levelTargetProgress = {}
		for i = topLevel , topLevel + (LevelDifficultyAdjustTopLevelLength - 1) do
			table.insert( levelTargetProgress , i )
		end
	end

	local function onSuccess(evt)

		if evt and evt.data and evt.data.passLevelDatas then
			--printx( 1 , "LevelDifficultyAdjustManager:loadAndInitConfig   onSuccess  " , table.tostring(evt.data) )
			self:updateLevelData( evt.data )
		end
		
	end

	local function onFail(evt)
		--self:init( localData )
	end

	local function onUserLogin()
		local http = GetPassLevelDataHttp.new(false)	
		http:addEventListener(Events.kComplete, onSuccess)
	    http:addEventListener(Events.kError, onFail)
	    http:setIsLoading( true )
		http:syncLoad( passLevelDataKeys , propSeedLevelKeys , propSeedLogLevelKeys , virtualSeedLevelKeys , levelLeftMoves , levelTargetProgress )
		--GetPassLevelDataHttp:load(passLevelDataKeys , propSeedLevelIds , propSeedLogLevelIds , virtualModeLogLevelIds)
	end

	local function hasNoNetwork()
		--self:init( localData )
	end
	
	local localLevelData = Localhost:readFromStorage( getLocalLevelDataFilePath() )
	if not localLevelData then
		localLevelData = self:createDefaultLocalLevelData()
	end

	if type(localLevelData) ~= "table" then
		localLevelData = self:createDefaultLocalLevelData()
	end

	self.localLevelData = localLevelData

	if passLevelDataKeys or propSeedLevelKeys or propSeedLogLevelKeys or virtualSeedLevelKeys or levelLeftMoves or levelTargetProgress then
		
		RequireNetworkAlert:callFuncWithLogged(onUserLogin, hasNoNetwork , nil , kRequireNetworkAlertTipType.kNoTip )
		
		-- PaymentNetworkCheck:getInstance():check( hasNetwork , hasNoNetwork )
	end

end

function LevelDifficultyAdjustManager:createDefaultLocalLevelData()
	local data = {}

	data.levelDifficulty = {}
	data.easySeeds = {}
	data.propSeeds = {}
	data.seedUsedLog = {}
	data.virtualSeedUsedLog = {}
	data.levelLeftMoves = {}

	return data
end

function LevelDifficultyAdjustManager:getLocalLevelData()
	return self.localLevelData
end

function LevelDifficultyAdjustManager:getPropSeedList(levelId)
	levelId = tostring(levelId)

	if self.localLevelData and self.localLevelData.propSeeds and self.localLevelData.propSeeds[levelId] then
		return self.localLevelData.propSeeds[levelId]
	end

	return {}
end

function LevelDifficultyAdjustManager:getPropSeedUsedLog(levelId)
	levelId = tostring(levelId)

	if self.localLevelData and self.localLevelData.seedUsedLog and self.localLevelData.seedUsedLog[levelId] then
		return self.localLevelData.seedUsedLog[levelId]
	end

	return {}
end

function LevelDifficultyAdjustManager:addPropSeedUsedLog(levelId , usedseed)
	levelId = tostring(levelId)

	if self.localLevelData and self.localLevelData.seedUsedLog then

		if not self.localLevelData.seedUsedLog[levelId] then
			self.localLevelData.seedUsedLog[levelId] = {}
		end

		local list = self.localLevelData.seedUsedLog[levelId]
		table.insert( list , usedseed )

		Localhost:writeToStorage(self.localLevelData, getLocalLevelDataFilePath() )
	end
end

function LevelDifficultyAdjustManager:getVirtualSeedUsedLog(levelId)
	levelId = tostring(levelId)

	if self.localLevelData and self.localLevelData.virtualSeedUsedLog and self.localLevelData.virtualSeedUsedLog[levelId] then
		return self.localLevelData.virtualSeedUsedLog[levelId]
	end
	return {}
end

function LevelDifficultyAdjustManager:addVirtualSeedUsedLog(levelId , modeIndex)
	levelId = tostring(levelId)

	if self.localLevelData and self.localLevelData.virtualSeedUsedLog then
		if not self.localLevelData.virtualSeedUsedLog[levelId] then
			self.localLevelData.virtualSeedUsedLog[levelId] = {}
		end
		local list = self.localLevelData.virtualSeedUsedLog[levelId]
		table.insert( list , modeIndex )

		Localhost:writeToStorage(self.localLevelData, getLocalLevelDataFilePath() )
	end
end

function LevelDifficultyAdjustManager:updateLevelData( datas , mode )

	local passLevelDatas = datas.passLevelDatas

	if passLevelDatas then

		if not self.localLevelData.levelDifficulty then
			self.localLevelData.levelDifficulty = {}
		end

		if not self.localLevelData.easySeeds then
			self.localLevelData.easySeeds = {}
		end

		for i = 1 , #passLevelDatas do
			local data = passLevelDatas[i]
			local levelId = tonumber(data.levelId)

			if data.difficulty then
				self.localLevelData.levelDifficulty[ tostring(levelId) ] = data.difficulty
			end

			if data.easySeeds then
				self.localLevelData.easySeeds[ tostring(levelId) ] = data.easySeeds
			end
		end
	end

	local propSeeds = datas.propSeeds

	if propSeeds then
		for i = 1 , #propSeeds do
			local data = propSeeds[i]
			local levelId = tostring(data.first)
			if data.second then
				if not self.localLevelData.propSeeds then
					self.localLevelData.propSeeds = {}
				end
				self.localLevelData.propSeeds[ tostring(levelId) ] = data.second
			end
		end
	end

	local propSeedLogs = datas.propSeedLogs

	if propSeedLogs then
		for i = 1 , #propSeedLogs do
			local data = propSeedLogs[i]
			local levelId = tostring(data.first)

			if data.second then
				local oringinLog = self.localLevelData.seedUsedLog[ tostring(levelId) ] or {}
				local oringinLogMap = {}
				for k,v in ipairs(oringinLog) do
					oringinLogMap[v] = true
				end

				for k,v in ipairs(data.second) do
					oringinLogMap[v] = true
				end

				local newList = {}
				for k,v in pairs(oringinLogMap) do
					table.insert( newList , k )
				end

				self.localLevelData.seedUsedLog[ tostring(levelId) ] = newList
			end
		end
	end

	local virtualModeLogs = datas.virtualModeLogs

	if virtualModeLogs then
		for i = 1 , #virtualModeLogs do
			local data = virtualModeLogs[i]
			local levelId = tostring(data.first)

			if data.second then
				local oringinLog = self.localLevelData.virtualSeedUsedLog[ tostring(levelId) ] or {}
				local oringinLogMap = {}
				for k,v in ipairs(oringinLog) do
					oringinLogMap[v] = true
				end

				for k,v in ipairs(data.second) do
					oringinLogMap[v] = true
				end

				local newList = {}
				for k,v in pairs(oringinLogMap) do
					table.insert( newList , k )
				end

				self.localLevelData.virtualSeedUsedLog[ tostring(levelId) ] = newList
			end
		end
	end

	local levelLeftMoves = datas.levelLeftMoves

	if levelLeftMoves then
		for i = 1 , #levelLeftMoves do
			local data = levelLeftMoves[i]
			local levelId = tostring(data.first)
			if data.second then
				if not self.localLevelData.levelLeftMoves then
					self.localLevelData.levelLeftMoves = {}
				end
				self.localLevelData.levelLeftMoves[ tostring(levelId) ] = tonumber(data.second)
			end
		end
	end
	

	local levelTables = self:getFuuuManager():buildLevelTargetProgressByRespData( datas.levelTargetProgress , mode )
	if not self.localLevelData.levelTargetProgress then
		self.localLevelData.levelTargetProgress = {}
	end
	self:mergeLevelTargetProgressData(levelTables)

	Localhost:writeToStorage(self.localLevelData, getLocalLevelDataFilePath() )
end

function LevelDifficultyAdjustManager:getLevelStaticDifficulty( levelId )

	if self.localLevelData and self.localLevelData.levelDifficulty then

		return self.localLevelData.levelDifficulty[ tostring(levelId) ]
	end
end

function LevelDifficultyAdjustManager:getLevelTargetProgressData( levelId , step , isReplay )

	local datas = nil

	if isReplay then
		if self.levelTargetProgressDataForReplay then
			datas = self.levelTargetProgressDataForReplay
			if datas.steps and datas.steps["s" .. tostring(step)] then
				local tarDataList = datas.steps["s" .. tostring(step)]
				return tarDataList , datas.staticTotalSteps
			end
		end
	end

	if not datas then
		if self.localLevelData and self.localLevelData.levelTargetProgress then
			datas = self.localLevelData.levelTargetProgress
		end
	end

	if datas then

		-- levelId = LevelMapManager.getInstance():getMetaLevelId( levelId )

		if datas[ tostring(levelId) ] and datas[ tostring(levelId) ].steps and datas[ tostring(levelId) ].steps["s" .. tostring(step)] then
			local tarDataList = datas[ tostring(levelId) ].steps["s" .. tostring(step)]
			return tarDataList , datas[ tostring(levelId) ].staticTotalSteps
		end
	end
	return nil
end

function LevelDifficultyAdjustManager:getLevelTargetProgressDataStrForReplay( levelId )
	-- RemoteDebug:uploadLogWithTag( "LevelDifficultyAdjustManager" , "getLevelTargetProgressDataStrForReplay !!!!!!!!!!!!!!!!!!  levelId" , levelId )
	-- levelId = LevelMapManager.getInstance():getMetaLevelId( levelId )
	local datastr , staticTotalSteps = self:getFuuuManager():getLevelTargetProgressDataStrForReplay( self.localLevelData , levelId )
	return datastr , staticTotalSteps
end

function LevelDifficultyAdjustManager:buildLevelTargetProgressDataByReplayDataStr( datastr , staticTotalSteps )
	-- RemoteDebug:uploadLogWithTag( "LevelDifficultyAdjustManager" , "buildLevelTargetProgressDataByReplayDataStr !!!!!!!!!!!!!!!!!! " )
	-- printx(1 , "LevelDifficultyAdjustManager:buildLevelTargetProgressDataByReplayDataStr  datastr =" , datastr , "\nstaticTotalSteps =" , staticTotalSteps)
	local leveldata = self:getFuuuManager():buildLevelTargetProgressDataByReplayDataStr( datastr , staticTotalSteps )
	self.levelTargetProgressDataForReplay = leveldata
end

function LevelDifficultyAdjustManager:tryCreateUserGroupInfo(levelId)
	--self.context.userGroupInfo的数据可能被mock的，但是self.userGroupInfo的数据一定是玩家当前帐号的实际分组数据
	if not self.userGroupInfo then
		self.userGroupInfo = {}

		local uid = getCurrUid()

		local mainSwitch = MaintenanceManager:getInstance():isEnabledInGroup("LevelDifficultyAdjust" , "B2" , uid) or false

		local levelDifficultyAdjustV2Group = 9
		local levelDifficultyAdjustV2AlgorithmId = "DifficultyAdjustV2_v1"

		local diffTagLogicGroup = 0
		local diffTagLogicGroupAlgorithmId = nil

		local fuuuInlevelDecisionExpGroup = 1
		local fuuuInlevelDecisionExpAlgorithmId = nil

		local fuuuDecreaseColorExpGroup = 0
		local fuuuDecreaseColorExpAlgorithmId = nil

		local hardLevelAdjustExpGroup = 0
		local hardLevelAdjustExpAlgorithmId = nil

		local lowActiveAdjustExpGroup = 0
		local lowActiveAdjustExpAlgorithmId = nil

		local payUserAdjustExpGroup = 0
		local payUserAdjustExpAlgorithmId = nil

		
		-- for i = 1 , kTriggerGroupLimit do
		-- 	local enabled , expName = MaintenanceManager:getInstance():isEnabledInGroup( self:getExpName() , "A" .. tostring(i) , uid)
		-- 	if enabled then
		-- 		diffTagLogicGroup = i
		-- 		diffTagLogicGroupAlgorithmId = expName
		-- 		break
		-- 	end
		-- end
		diffTagLogicGroup = 17
		diffTagLogicGroupAlgorithmId = "fuuu_a17_v1"


		for i = 1 , kTriggerGroupLimit do
			local enabled2 , expName2 = MaintenanceManager:getInstance():isEnabledInGroup( self:getFuuuInlevelDecisionExpName() , "G" .. tostring(i) , uid)
			if enabled2 then
				fuuuInlevelDecisionExpGroup = i
				fuuuInlevelDecisionExpAlgorithmId = expName2
				break
			end
		end

		for i = 1 , kTriggerGroupLimit do
			local enabled3 , expName3 = MaintenanceManager:getInstance():isEnabledInGroup( self:getFuuuDecreaseColorExpName() , "G" .. tostring(i) , uid)
			if enabled3 then
				fuuuDecreaseColorExpGroup = i
				fuuuDecreaseColorExpAlgorithmId = expName3
				break
			end
		end

		for i = 0 , 6 do
			local enabled4 , expName4 = MaintenanceManager:getInstance():isEnabledInGroup( self:getHardLevelAdjustExpName() , "G" .. tostring(i) , uid)
			if enabled4 then
				hardLevelAdjustExpGroup = i
				hardLevelAdjustExpAlgorithmId = expName4
				break
			end
		end

		-- for i = 0 , 4 do
		-- 	local enabled5 , expName5 = MaintenanceManager:getInstance():isEnabledInGroup( self:getLowActiveAdjustExpName() , "G" .. tostring(i) , uid)
		-- 	if enabled5 then
		-- 		lowActiveAdjustExpGroup = i
		-- 		lowActiveAdjustExpAlgorithmId = expName5
		-- 		break
		-- 	end
		-- end

		lowActiveAdjustExpGroup = 1

		for i = 0 , 2 do
			local enabled6 , expName6 = MaintenanceManager:getInstance():isEnabledInGroup( self:getPayUserAdjustExpName() , "G" .. tostring(i) , uid)
			if enabled6 then
				payUserAdjustExpGroup = i
				payUserAdjustExpAlgorithmId = expName6
				break
			end
		end
		
		self.userGroupInfo.fuuuExpGroup = 0
		for i = 0 , 2 do
			local enabled7 , expName7 = MaintenanceManager:getInstance():isEnabledInGroup( self:getFuuuExpName() , "G" .. tostring(i) , uid)
			if enabled7 then
				self.userGroupInfo.fuuuExpGroup = i
				break
			end
		end


		self.userGroupInfo.newReturnAndLowActiveExpGroup = 0
		for i = 0 , 5 do
			local enabled8 , expName8 = MaintenanceManager:getInstance():isEnabledInGroup( newReturnAndLowActiveExpName , "G" .. tostring(i) , uid)
			if enabled8 then
				self.userGroupInfo.newReturnAndLowActiveExpGroup = i
				break
			end
		end
		
		


		if levelDifficultyAdjustV2Group == 0 then
			local enabled , expName = MaintenanceManager:getInstance():isEnabledInGroup( self:getExpName() , "None" , uid)
			if expName then
				levelDifficultyAdjustV2AlgorithmId = expName
			end
		end

		local returnUsersRetentionTestGroup = 0

		if MaintenanceManager:getInstance():isEnabledInGroup("ReturnUsersRetentionTest" , "N51" , uid)
			or MaintenanceManager:getInstance():isEnabledInGroup("ReturnUsersRetentionTest" , "N52" , uid) then

			returnUsersRetentionTestGroup = 5

		elseif MaintenanceManager:getInstance():isEnabledInGroup("ReturnUsersRetentionTest" , "N61" , uid)
			or MaintenanceManager:getInstance():isEnabledInGroup("ReturnUsersRetentionTest" , "N62" , uid) then

			returnUsersRetentionTestGroup = 6
		end
		returnUsersRetentionTestGroup = 5




		self.userGroupInfo.mainSwitch = mainSwitch
		self.userGroupInfo.diffV2 = levelDifficultyAdjustV2Group
		self.userGroupInfo.diffV2AlgorithmId = levelDifficultyAdjustV2AlgorithmId

		self.userGroupInfo.diffTagLogicGroup = diffTagLogicGroup
		self.userGroupInfo.diffTagLogicGroupAlgorithmId = diffTagLogicGroupAlgorithmId
		

		self.userGroupInfo.fuuuInlevelDecisionGroup = fuuuInlevelDecisionExpGroup
		self.userGroupInfo.fuuuInlevelDecisionAlgorithmId = fuuuInlevelDecisionExpAlgorithmId

		self.userGroupInfo.fuuuDecreaseColorExpGroup = fuuuDecreaseColorExpGroup
		self.userGroupInfo.fuuuDecreaseColorExpAlgorithmId = fuuuDecreaseColorExpAlgorithmId

		self.userGroupInfo.hardLevelAdjustExpGroup = hardLevelAdjustExpGroup
		self.userGroupInfo.hardLevelAdjustExpAlgorithmId = hardLevelAdjustExpAlgorithmId

		self.userGroupInfo.lowActiveAdjustExpGroup = lowActiveAdjustExpGroup
		self.userGroupInfo.lowActiveAdjustExpAlgorithmId = lowActiveAdjustExpAlgorithmId

		self.userGroupInfo.payUserAdjustExpGroup = payUserAdjustExpGroup
		self.userGroupInfo.payUserAdjustExpAlgorithmId = payUserAdjustExpAlgorithmId

		self.userGroupInfo.retention = returnUsersRetentionTestGroup

		self.userGroupInfo.farmStarGroup = 'None'
		for _, groupName in ipairs( farmStarGroupNames ) do
			if MaintenanceManager:getInstance():isEnabledInGroup('LevelDifficultyAdjustFarmStar', groupName, uid) then
				self.userGroupInfo.farmStarGroup = groupName
				break
			end
		end

		-- RemoteDebug:uploadLogWithTag( "RRR" , "tryCreateUserGroupInfo mainSwitch" , mainSwitch , "diffV2" , levelDifficultyAdjustV2Group , "retention" , returnUsersRetentionTestGroup )
		DiffAdjustQAToolManager:print( 1 , "RRR" , "tryCreateUserGroupInfo mainSwitch" , mainSwitch , "diffV2" , diffTagLogicGroup , "retention" , returnUsersRetentionTestGroup )
	end
	self.userGroupInfo.forbidByAI = false
	return self.userGroupInfo
end

function LevelDifficultyAdjustManager:isFarmStarFuuu( farmStarGroup )
	if self.context.userGroupInfo.farmStarGroup ~= "None" and farmStarGroupNames then
		return table.includes( farmStarGroupNames , farmStarGroup or '')
	end

	return false
end

function LevelDifficultyAdjustManager:getUserGroupInfo()
	if self.context then
	return self.context.userGroupInfo
	end
	return nil
end

function LevelDifficultyAdjustManager:getUserGroupInfoForReplay()

	if self.context and self.context.userGroupInfo then
		local tab = {}
		local hasData = false

		for k,v in pairs(self.context.userGroupInfo) do
			tab[k] = v
			hasData = true
		end

		if hasData then
			return tab
		end
	end
	return nil
end

function LevelDifficultyAdjustManager:resumeUserGroupInfoByReplay(groupInfo)

	if not self.context then self.context = {} end

	self.context.userGroupInfo = {}
	self.context.userGroupInfo.mainSwitch = groupInfo.mainSwitch
	self.context.userGroupInfo.diffV2 = groupInfo.diffV2
	self.context.userGroupInfo.diffV2AlgorithmId = groupInfo.diffV2AlgorithmId
	self.context.userGroupInfo.retention = groupInfo.retention
	self.context.userGroupInfo.forbidByAI = groupInfo.forbidByAI
	self.context.userGroupInfo.fuuuInlevelDecisionGroup = groupInfo.fuuuInlevelDecisionGroup
end

function LevelDifficultyAdjustManager:getCurrStrategyID()
	return self.currStrategyID
end

function LevelDifficultyAdjustManager:clearCurrStrategyID()
	-- DiffAdjustQAToolManager:print( 1 , "LevelDifficultyAdjustManager:clearCurrStrategyID" )
	if ProductItemDiffChangeLogic:getTestFlag() then return end
	self.currStrategyID = 0
end

function LevelDifficultyAdjustManager:setAICoreInfo(aiCoreInfo)
	self.aiCoreInfo = aiCoreInfo
end

function LevelDifficultyAdjustManager:getAICoreInfo()
	return self.aiCoreInfo
end

function LevelDifficultyAdjustManager:clearAICoreInfo()
	self.aiCoreInfo = nil
end

function LevelDifficultyAdjustManager:getAIColorProbs()
	return self.aiCoreInfo and self.aiCoreInfo.colorProbs
end

function LevelDifficultyAdjustManager:getDcAIColorProbsRec()
	local interveneSeq = nil --'null'
	local colorProbs = self:getAIColorProbs()
	if colorProbs then
		local colorProbsNum = #colorProbs
		if colorProbsNum > 0 then 
			for i=1, colorProbsNum do
				local interveneValue = colorProbs[i]
				if interveneValue then 
					if i == 1 then
						interveneSeq = interveneValue .. ''
					else
						interveneSeq = interveneSeq .. '_' .. interveneValue
					end 
				end
			end
		end
	end
	return interveneSeq
end

function LevelDifficultyAdjustManager:getDcAIInterveneInfo()
	local costStepsSeq
	local leftStepsSeq 
	local interveneSeqUsed
	local repeatSeq
	local costStepsArr, leftStepsArr, interveneArr, repeatArr = GamePlayContext:getInstance():getAIInterveneLog()
	local function _tostring(arr)
		local str
		if arr then 
			local list = {}
			local maxn = table.maxn(arr)
			for k = 1, maxn do
				if arr[k] then
					for i,v in ipairs(arr[k]) do
						table.insert(list, v)
					end
				else
					table.insert(list, "e")
				end
			end
			if #list > 0 then
				str = table.join(list, '_')
			end
		end
		return str
	end
	if costStepsArr and leftStepsArr and interveneArr and repeatArr then
		costStepsSeq = _tostring(costStepsArr)
		leftStepsSeq = _tostring(leftStepsArr)
		interveneSeqUsed = _tostring(interveneArr)
		repeatSeq = _tostring(repeatArr)
	end

	-- printx(0, "costStepsArr", costStepsSeq, table.tostring(costStepsArr))
	-- printx(0, "leftStepsArr", leftStepsSeq, table.tostring(leftStepsArr))
	-- printx(0, "interveneArr", interveneSeqUsed, table.tostring(interveneArr))
	-- printx(0, "repeatArr", repeatSeq, table.tostring(repeatArr))

	return costStepsSeq, leftStepsSeq, interveneSeqUsed, repeatSeq
end

function LevelDifficultyAdjustManager:getAISeedValue()
	return self.aiCoreInfo and self.aiCoreInfo.seed --or 'null'
end

function LevelDifficultyAdjustManager:getAIEventID()
	return self.aiCoreInfo and self.aiCoreInfo.eventId --or 'null'
end

function LevelDifficultyAdjustManager:getAIAlgorithmTag()
	return self.aiCoreInfo and self.aiCoreInfo.algorithmId --or 'null'
end

function LevelDifficultyAdjustManager:__countCurrStrategyID(strategyData , adjustSeed)
	if not strategyData then return 0 end

	local id1 = 0
	local id2 = 0

	if adjustSeed then
		if strategyData.seed and #strategyData.seed > 0 then
			id1 = 10000 + adjustSeed
		end
	else
		if strategyData.propSeed and strategyData.propSeed > 0 then
			id1 = 20000 + strategyData.propSeed
		elseif strategyData.aiSeed and strategyData.aiSeed > 0 then
			id1 = 30000 + strategyData.aiSeed
		end
	end

	if strategyData.mode and strategyData.ds then
		id2 = (1000000 * tonumber(strategyData.mode)) + (100000 * tonumber(strategyData.ds))
	end
	
	local ver = 10000000
	local strategyId = id1 + id2 + ver

	return strategyId
end

function LevelDifficultyAdjustManager:updateCurrStrategyID(strategyData , adjustSeed , fromReplay)

	self.currStrategyID = self:__countCurrStrategyID( strategyData , adjustSeed ) or 0
	-- DiffAdjustQAToolManager:print( 1 , "LevelDifficultyAdjustManager:updateCurrStrategyID" , self.currStrategyID )
	self.levelTargetProgressDataForReplay = nil

	if not fromReplay then
		self:addStrategyIDList( self.currStrategyID , "PreStart" )
	end
	
end

function LevelDifficultyAdjustManager:getStrategyReplayDataByStrategyID(strategyID)
	local data = nil
	local ver = 10000000

	if strategyID and type(strategyID) == "number" then
		if strategyID == 0 or strategyID == ver then
			return nil
		end

		data = {}
		
		if strategyID > ver then
			strategyID = strategyID - ver
		end

		if strategyID < 39999 then
			if strategyID < 19999 then
				data.seed = tonumber(strategyID - 10000)
			elseif strategyID < 29999 then
				data.propSeed = tonumber(strategyID - 20000)
			else
				data.aiSeed = tonumber(strategyID - 30000)
			end
		else
			data.mode = math.floor( strategyID / 1000000 )
			local m = strategyID - ( 1000000 * tonumber(data.mode) )
			data.ds = math.floor( m / 100000 )
			local n = strategyID - ( 1000000 * tonumber(data.mode) ) - ( 100000 * tonumber(data.ds) )

			if n > 0 and n < 39999 then
				if strategyID < 19999 then
					data.seed = tonumber(n - 10000)
				elseif strategyID < 29999 then
					data.propSeed = tonumber(n - 20000)
				else
					data.aiSeed = tonumber(n - 30000)
				end
			end
		end
	end

	return data
end

function LevelDifficultyAdjustManager:getLevelDifficulty(levelId)
	if self.cacheData and self.cacheData.difficultyMap then
		return self.cacheData.difficultyMap[tostring(levelId)] or 0
	end
	return 0
end

function LevelDifficultyAdjustManager:getLevelEasySeed(levelId , ds)
	if self.cacheData and self.cacheData.seedMap and self.cacheData.seedMap[tostring(levelId)] then
		return self.cacheData.seedMap[tostring(levelId)][tostring(ds)]
	end
	return nil
end

function LevelDifficultyAdjustManager:checkNeedLockDS(levelId)
	--printx( 1 , "LevelDifficultyAdjustManager:checkNeedLockDS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ levelId" , levelId  )
	local levelConfig = LevelDataManager.sharedLevelData():getLevelConfigByID(levelId)
	--printx( 1 , "LevelDifficultyAdjustManager:checkNeedLockDS levelConfig =",levelConfig , "levelConfig.orderMap =" , levelConfig.orderMap )
	for k,v in pairs(levelConfig) do
		printx( 1 , "k =" , k , "v =" , v )
	end

	if levelConfig and levelConfig.orderMap then

		local orderMap = levelConfig.orderMap
		printx( 1 , "orderMap =" , table.tostring(orderMap) )

		for k,v in pairs(orderMap) do
			printx( 1 , "k" , k , "v" , v )
		end

	end

	return nil
end

function LevelDifficultyAdjustManager:checkAdjustSatisfyPreconditions(levelId, checkType)

	checkType = checkType or {}

	local isFarmStarFuuu = checkType.isFarmStarFuuu

	local mainSwitch = false
	if self.context.userGroupInfo then
		mainSwitch = self.context.userGroupInfo.mainSwitch or false
	end

	if not mainSwitch then --开关未打开
		return false , AdjustUnactivateReason.kMaintenanceUnavailable
	end

	if not self.context.isMainLevel then --不是主线关
		return false , AdjustUnactivateReason.kNotMainLevel
	end

	if self.context.askForHelpIsInMode then --代打模式不激活任何调整
		return false , AdjustUnactivateReason.kAskForHelpMode
	end

	if (not isFarmStarFuuu) and self.context.levelStar > 0 then
		return false , AdjustUnactivateReason.kStarNotZero
	end

	-- 不再限制必须是topLevel，只要星级是0的关卡都可以，也就是回去刷跳过或者代打的关卡也可以激活
	-- if (not isFarmStarFuuu) and levelId < self.context.topLevel then
	-- 	return false , AdjustUnactivateReason.kNotTopLevel
	-- end

	if isFarmStarFuuu then

		if levelId >= self.context.topLevel then
			return false, AdjustUnactivateReason.kTopLevel
		end
		if not self.context.hasLevelTargetProgressData then
			return false, AdjustUnactivateReason.kNoLevelTargetProgress
		end


		if self.context.levelStar >= 3 then
			return false, AdjustUnactivateReason.kTooManyStar
		end

		if not self.context.farmStarFuuuPlayLevelCounter then
			 self.context.farmStarFuuuPlayLevelCounter = 0
		end

		local staticDiff = self.context.staticDiff or 9999


		if checkType.farmStarGroup == "None" then
			return false , AdjustUnactivateReason.kFarmFuuuSwitchOff
		elseif checkType.farmStarGroup == "B1" then
			local maxLevelId = self.context.maxLevelId
			if self.context.topLevel >= maxLevelId then
				--满级
				local last60DayPayAmount = self.context.last60DayPayAmount

				if last60DayPayAmount >= 240 then
					if self.context.userTotalStar > self.context.totalStar - 600 then
						return false, AdjustUnactivateReason.kTooManyStar
					end

					if staticDiff <= 6 then
						return false, AdjustUnactivateReason.kDiffTooLow
					else
						if self.context.collectStarEffective then
						else
							if self.context.farmStarFuuuPlayLevelCounter % 2 == 0 then
							else
								return false, AdjustUnactivateReason.kUnlucky
							end 
						end
					end

				elseif last60DayPayAmount >= 13 then
					if self.context.userTotalStar > self.context.totalStar - 200 then
						return false, AdjustUnactivateReason.kTooManyStar
					end

					if staticDiff <= 6 then
						return false, AdjustUnactivateReason.kDiffTooLow
					else
						if self.context.collectStarEffective then
						else
							if self.context.farmStarFuuuPlayLevelCounter % 2 == 0 then
							else
								return false, AdjustUnactivateReason.kUnlucky
							end 
						end
					end
				else
					if self.context.userTotalStar > self.context.totalStar - 200 then
						return false, AdjustUnactivateReason.kTooManyStar
					end

					if self.context.collectStarEffective then
					else
						if self.context.farmStarFuuuPlayLevelCounter % 2 == 0 then
						else
							return false, AdjustUnactivateReason.kUnlucky
						end 
					end
				end

			else
				--非满级
				if self.context.userTotalStar > self.context.totalStar - 200 then
					return false, AdjustUnactivateReason.kTooManyStar
				end

				if self.context.collectStarEffective then
				else
					if self.context.farmStarFuuuPlayLevelCounter % 2 == 0 then
					else
						return false, AdjustUnactivateReason.kUnlucky
					end 
				end
			end
		else
			if self.context.userTotalStar > self.context.totalStar - 200 then
				return false, AdjustUnactivateReason.kTooManyStar
			end

			if self.context.collectStarEffective then
			else
				if self.context.farmStarFuuuPlayLevelCounter % 2 == 0 then
				else
					return false, AdjustUnactivateReason.kUnlucky
				end 
			end
		end

		--[[
		if checkType.farmStarGroup == 'A1' then
			if self.context.userTotalStar > self.context.totalStar - 200 then
				return false, AdjustUnactivateReason.kTooManyStar
			end

			if self.context.collectStarEffective then
			else
				if self.context.farmStarFuuuPlayLevelCounter % 2 == 0 then
				else
					return false, AdjustUnactivateReason.kUnlucky
				end 
			end
		elseif checkType.farmStarGroup == 'A2' then
			if self.context.userTotalStar > self.context.totalStar - 600 then
				return false, AdjustUnactivateReason.kTooManyStar
			end

			if self.context.collectStarEffective then
			else
				if self.context.farmStarFuuuPlayLevelCounter % 2 == 0 then
				else
					return false, AdjustUnactivateReason.kUnlucky
				end 
			end
		elseif checkType.farmStarGroup == 'A3' then
			if self.context.userTotalStar > self.context.totalStar - 200 then
				return false, AdjustUnactivateReason.kTooManyStar
			end

			if staticDiff <= 6 then
				return false, AdjustUnactivateReason.kDiffTooLow
			else
				if self.context.collectStarEffective then
				else
					if self.context.farmStarFuuuPlayLevelCounter % 2 == 0 then
					else
						return false, AdjustUnactivateReason.kUnlucky
					end 
				end
			end

			
		elseif checkType.farmStarGroup == 'A4' then
			if self.context.userTotalStar > self.context.totalStar - 600 then
				return false, AdjustUnactivateReason.kTooManyStar
			end

			if staticDiff <= 6 then
				return false, AdjustUnactivateReason.kDiffTooLow
			else
				if self.context.collectStarEffective then
				else
					if self.context.farmStarFuuuPlayLevelCounter % 2 == 0 then
					else
						return false, AdjustUnactivateReason.kUnlucky
					end 
				end
			end
		end
		]]
	end

	if levelId > self.context.maxLevelId - 60 then
		-- return false , AdjustUnactivateReason.kTooCloseToMaxLevel --注意，这个判断必须位于最后面

		--【1.65版本动更】关卡难度自动调整，游戏最高关-60的玩家进行干预策略
		--http://jira.happyelements.net/browse/MA-20385
		--不在判断是否在顶部60关以内，最新版本中，全关卡都有可能触发颜色调整策略
		return true , AdjustUnactivateReason.kTooCloseToMaxLevel
	end

	return true

end

function LevelDifficultyAdjustManager:useTestContext()
	local _PLATFORM = 1 --【1】安卓【2】苹果【3】Win32
	local _maxLevelId = 2000
	local _top15 = _maxLevelId - 14
	local _top60 = _maxLevelId - 59
	local _nottop = _maxLevelId - 60

	local context = {
    --（满级-60，满级】  非付费用户，空白对照组    用例关键字段：diffTag，activationTag, failCount
    mockData = {
    uid = "50000",          --玩家uid，现在没什么用
    --必须
    maxLevelId = 2000,    --当前配置最高关卡（top==true）  
    topLevel = 2000 - 59,           --玩家最高关卡
    levelId = 2000 - 59,        --当前关卡，一般闯topLevel关就配成topLevel，触发刷星fuuu才配成非topLevel
    levelStar = 0,           --当前关卡星级
    failCount = 1,          --topLevel的合理失败次数，不用于标签判断，diffTag是标签，用于比如每n+1次触发fuuu
    isPayUser = false,         --是否是付费用户
    last60DayPayAmount = 0,
    
    userGroupInfo = {          --分组信息
      forbidByAI = false,      --是否启用AI
        retention = 5,        --回流用户活动分组，线上全都在5
        mainSwitch = true,      --主开关，永远是true
        diffV2 = 9,            --难度调整分组
        isFarmStarFuuu = true,    --在不在刷星FUUU的分组里
    },
    --回流活动触发条件
    today = 2,            --今天是几号（影响回流用户每间隔一天强度减1的逻辑），见totalDays备注
    dateLogTable = {
        totalDays = 1,        --回流已经几天，today在log中有对应的则不变，没对应的表示今天首次登录，那么totalDays+1
        log = {
            d2 = true,        --d + day，可以不连续，每次会检测d+today是否存在，不存在则强度-1
        },
        activationTagStartTime = "1551457391138",   ---活跃标签的生效时间
      },
    todayPlayCount = 3,                --当前关今天的打关次数，如A12每天前3次闯关不触发fuuu干预
    diffTag = 2,                  --难度标签的值
    activationTag = 3,                --活跃标签的原始值
    fixedActivationTag = 3,              --活跃标签的修正值
    activationTagToplevelId = 2000 - 59,        --活跃标签激活时的topLevelId
    --以下几个条件暂时用不到
    activationTagTopLevelIdLength = 1,        --活跃标签在离线时可以激活的关卡范围，目前没用，默认配1
    activationTagStartTime = 1551457391138,      --活跃标签的生效时间
    activationTagChangeTime = 1552879294731,    --活跃标签的更变时间
    activationTagEndTime = 1554293775,        --活跃标签的预期结束时间
    activationTagUpdateTime = 1554207375,      --活动标签的上次更新时间
    hasInitBuffFromPreBuffAct = false,        --是否激活了Buff活动且进关卡应用了Buff
    preBuffLogicCanUseFUUU = false,          --buff活动是否可以使用Fuuu
    askForHelpIsInMode = false,            --是否为好友帮助模式

    userTotalStar = 4000,              --用户当前的总星星数（包含隐藏关）
    totalStar = 5000,                --整个藤蔓的星星总数（包含隐藏关）
    --互斥
    platform = 1,              --【1】安卓【2】苹果【3】Win32
    --可选
  },
  result = {mode = 3, ds = 2},
  }

	self:setContext( context.mockData )
end

MACRO_DEV_START()
--更新上下文，此方法将刷新self.context的值，
--此后所有的决策判断中，需要的用户数据都将从self.context中获取
MACRO_DEV_END()
function LevelDifficultyAdjustManager:updateContext(levelId, fromReplay, initActivityData)
	self.context = {}

	self.context.IS_ANDROID = __ANDROID
	self.context.IS_IOS = __IOS
	self.context.IS_WIN32 = __WIN32

	self.context.uid = getCurrUid()
	self.context.levelId = levelId
	self.context.isMainLevel = LevelType:isMainLevel(self.context.levelId)

	self.context.levelDiffcultFlag = MetaManager.getInstance():getLevelDifficultFlag( levelId )

	local lowActiveLocalData = LowActiveAdjustLogic:getLocalData() or {}
	self.context.lowActiveAdjustData = {}
	self.context.lowActiveAdjustData.enableAdjust = lowActiveLocalData.enableAdjust or false
	self.context.lowActiveAdjustData.adjustIndex = lowActiveLocalData.adjustIndex or 0
	self.context.lowActiveAdjustData.enabledTopLevelId = lowActiveLocalData.enabledTopLevelId or 0


	local levelScore = UserManager:getInstance():getUserScore(self.context.levelId)
	if levelScore and levelScore.star and levelScore.star > 0 then
		self.context.levelStar = levelScore.star
	else
		self.context.levelStar = 0
	end

	self.context.topLevel = UserManager:getInstance():getUserRef():getTopLevelId()
	-- self.context.maxLevelId = MetaManager.getInstance():getMaxNormalLevelByLevelArea()
	self.context.maxLevelId = NewAreaOpenMgr.getInstance():getCanPlayTopLevel()
	self.context.fixedActivationTag = UserTagManager:getUserTag(UserTagNameKeyFullMap.kActivation)

	self.context.active30Days = UserManager:getInstance().active30Days or 30

	local activationTag, activationTagTopLevelId, activationTagTopLevelIdLength, activationTagEndTime, activationTagUpdateTime, activationTagStartTime, activationTagChangeTime = 
			UserTagManager:getUserTagBySeries(UserTagNameKeyFullMap.kActivation)
	self.context.activationTag = activationTag
	self.context.activationTagTopLevelId = activationTagTopLevelId
	self.context.activationTagTopLevelIdLength = activationTagTopLevelIdLength
	self.context.activationTagEndTime = activationTagEndTime
	self.context.activationTagUpdateTime = activationTagUpdateTime
	self.context.activationTagStartTime = activationTagStartTime
	self.context.activationTagChangeTime = activationTagChangeTime
	self.context.diffTag = UserTagManager:getUserTag(UserTagNameKeyFullMap.kTopLevelDiff)
	self.context.staticDiff = MetaManager.getInstance().level_avg_difficulty_map[levelId] or 9999
	self.context.isPayUser = self:getDAManager():getIsPayUser()
	self.context.askForHelpIsInMode = AskForHelpManager.getInstance():isInMode()
	self.context.hasInitBuffFromPreBuffAct = GameInitBuffLogic:hasInitBuffFromPreBuffAct()
	self.context.preBuffLogicCanUseFUUU = PreBuffLogic:canUseFUUU()
	self.context.dateLogTable = LocalBox:getData(LocalBoxKeys.ReturnUserGroupTestP1)

	local nowTime = Localhost:timeInSec()
	local nowDate = os.date("*t" , nowTime)
	self.context.today = nowDate.day

	if UserManager:getInstance().mark and UserManager:getInstance().mark.createTime then
		self.context.userCreateTime = math.floor( tonumber( UserManager:getInstance().mark.createTime ) / 1000 )
	else
		self.context.userCreateTime = nowTime
	end
	

	local totalPlayCountData = LocalBox:getData( "totalPlayCount" , "LB_diffadjust" ) or {}
	if not totalPlayCountData[ tostring(self.context.today) ] then
		totalPlayCountData = {}
		totalPlayCountData[ tostring(self.context.today) ] = {}
	end
	
	local todayData = totalPlayCountData[ tostring(self.context.today) ]
	local playCount = todayData["l" .. tostring(self.context.levelId)] or 0
	self.context.todayPlayCount = playCount
	self.context.totalPlayCountData = totalPlayCountData

	
	self.context.failCount = UserTagManager:getTopLevelLogicalFailCounts() or 0
	self.context.last60DayPayAmount = UserTagManager:getLast60DayPayAmount() or 0


	self.context.userTotalStar = UserManager:getInstance().user:getTotalStar()
	self.context.totalStar = 0
	self.context.hasLevelTargetProgressData = self:hasLevelTargetProgressData(levelId)

	pcall(function ( ... )
		local maxLevel = NewAreaOpenMgr.getInstance():getLocalTopLevel()
   		local totalStar = LevelMapManager.getInstance():getTotalStar(maxLevel)
    	local totalHiddenStar = MetaModel.sharedInstance():getFullStarInHiddenRegionByMainLevelId(maxLevel-1)
    	self.context.totalStar = totalStar + totalHiddenStar
    	MACRO_DEV_START()
    	DiffAdjustQAToolManager:print( 1 , "maxLevel = " , maxLevel , "totalStar:", totalStar , "totalHiddenStar:" , totalHiddenStar , "fullStar:" , self.context.totalStar )
    	MACRO_DEV_END()
	end)

	self.context.collectStarEffective = StarBuffYEManager.getInstance():isBuffIngameEffective()
	self.context.farmStarFuuuPlayLevelCounter = FarmStarFuuuPlayLevelCounter:getTotalPlayLevelCount()

	if not fromReplay then
		self.context.userGroupInfo = self:tryCreateUserGroupInfo(self.context.levelId)

		if not self.context.askForHelpIsInMode then
			GamePlayContext:getInstance().aiSeedFirstGetTime = HeTimeUtil:getCurrentTimeMillis()
			self.context.seedFromAIServer = HEAICore:getInstance():popSeedForLevel(self.context.levelId)
		end 
	end

	self.context.isABTTestLevel = LevelConfigGroupMgr.getInstance():checkLevelInAnyTest( levelId )

	self.context.hasAnySkillCanUse = false

	self.context.failCountBeforeFirstPass_localdata = FUUUManager:getLevelFailNumBeforeFirstPass( levelId )

	self.context.isTsumBuff_fuuu = TsumBuffManager:getBuff_fuuu( levelId )

	self.context.isTravelLevel = LevelType:isTravelLevel(self.context.levelId)
	if self.context.isTravelLevel and initActivityData and initActivityData.travelData then
		self.context.travelAdjustLevel = TravelLogic:getCurrDiffAdjustLevel(initActivityData.travelData)
	end

	local newReturnAndLowActiveData = NewReturnAndLowActiveAdjustLogic:getLocalData()
	-- RemoteDebug:uploadLogWithTag("ADJUST", table.serialize( newReturnAndLowActiveData ) )
	self.context.newReturnAndLowActiveStrength = newReturnAndLowActiveData.currStrength or 0

	-- self:useTestContext()

	--魔力水晶球fuuu上下文
	--magicCrystalBallFuuuFix为true时，关闭调节。需要存在该活动，且满足关闭条件
	--http://wiki.happyelements.net/pages/viewpage.action?pageId=70815581
	local mcbmgr = MagicCrystalBallManager and MagicCrystalBallManager.getInstance and MagicCrystalBallManager:getInstance()
	if mcbmgr and mcbmgr.isEnabled and mcbmgr:isEnabled() then self.context.magicCrystalBallFuuuFix = mcbmgr.isInFuuuFix end
end

MACRO_DEV_START()
--接受外部参数，直接重置self.context的值
--这样做的目的是为了在unit test中mock整个决策环境
MACRO_DEV_END()
function LevelDifficultyAdjustManager:setContext(datas)
	self.context = datas
	self.context.isMainLevel = LevelType:isMainLevel(self.context.levelId)

	if self.context.platform then

		self.context.IS_ANDROID = false
		self.context.IS_IOS = false
		self.context.IS_WIN32 = false

		if self.context.platform == 1 then
			self.context.IS_ANDROID = true
		elseif self.context.platform == 2 then
			self.context.IS_IOS = true
		elseif self.context.platform == 3 then
			self.context.IS_WIN32 = true
		end
	end

	self.context.isMock = true
end

function LevelDifficultyAdjustManager.unitTestByContext(mockDatas, result)
	LevelDifficultyAdjustManager:setContext(mockDatas)

	local strategy , failReason = LevelDifficultyAdjustManager:checkAdjustStrategy()
	if not strategy and result then
		return false, "nil   failReason : " .. tostring( failReason )
	elseif strategy then 
		local strategyStr = table.tostring({mode = strategy.mode, ds = strategy.ds , reason = strategy.reason})
		if result then
			return strategy.mode == result.mode and strategy.ds == result.ds, strategyStr
		else
			return false, strategyStr
		end
	end

	return true
end

function LevelDifficultyAdjustManager:getContext()
	return self.context
end

function LevelDifficultyAdjustManager:clearContext()
	self.context = nil
end

function LevelDifficultyAdjustManager:checkAdjustStrategy()

	self.userGroup = 1--锁死A1组
	local levelId = self.context.levelId
	DiffAdjustQAToolManager:updateUserGroup(self.context.userGroupInfo) 

	--AI干预
	-- local seedFromAIServer = self.context.seedFromAIServer
	-- if false and seedFromAIServer then --关闭AI调关服务
	-- 	local aiCoreInfo = {}
	-- 	aiCoreInfo.seed = seedFromAIServer.seed
	-- 	aiCoreInfo.eventId = seedFromAIServer.eventId
	-- 	aiCoreInfo.algorithmId = seedFromAIServer.algorithmId
	-- 	--ai颜色干预可能穿空字段或空list
	-- 	if seedFromAIServer.colorProbs and type(seedFromAIServer.colorProbs) == 'table' and #seedFromAIServer.colorProbs > 0 then
	-- 		aiCoreInfo.colorProbs = seedFromAIServer.colorProbs
	-- 	end
	-- 	LevelDifficultyAdjustManager:setAICoreInfo(aiCoreInfo)

	-- 	if aiCoreInfo.colorProbs then
	-- 		return {levelId = levelId, mode = ProductItemDiffChangeMode.kAICoreAddColor, 
	-- 				aiSeed = seedFromAIServer.seed, ds = 1, reason = LevelDifficultyAdjustReason.kAICore}
	-- 	end
	-- end

	local seedFromAIServer = self.context.seedFromAIServer
	if seedFromAIServer then --重开 LOE 接口调用，但关闭AI调关服务
		local aiCoreInfo = {}
		aiCoreInfo.seed = seedFromAIServer.seed
		aiCoreInfo.eventId = seedFromAIServer.eventId
		aiCoreInfo.algorithmId = seedFromAIServer.algorithmId
		--ai颜色干预可能穿空字段或空list
		if seedFromAIServer.colorProbs and type(seedFromAIServer.colorProbs) == 'table' and #seedFromAIServer.colorProbs > 0 then
			aiCoreInfo.colorProbs = seedFromAIServer.colorProbs
		end
		LevelDifficultyAdjustManager:setAICoreInfo(aiCoreInfo)
	end

	LowActiveAdjustLogic:onStartLevel()

	if self.context.userGroupInfo.fuuuDecreaseColorExpGroup and self.context.userGroupInfo.fuuuDecreaseColorExpGroup > 0 then
		MACRO_DEV_START()
		--负向干预
		MACRO_DEV_END()
		local groupid = self.context.userGroupInfo.fuuuDecreaseColorExpGroup

		if groupid == 1 then
			return { levelId = levelId , mode = ProductItemDiffChangeMode.kAIDecreaseColor , ds = 1 , reason = "AIDecreaseColor" }
		end
	end

	--魔力泡泡取消正向干预
	if self.context.magicCrystalBallFuuuFix then
		self:setLastUnactivateReason(AdjustUnactivateReason.kActMagicCrystalBall)
		DcUtil:DifficultyAdjustUnactivate(levelId, self.lastUnactivateReason , self.context.userGroupInfo)
		return nil, self.lastUnactivateReason
	end

	local satisfyPreconditionsResult, satisfyPreconditionsReason = self:checkAdjustSatisfyPreconditions(levelId)
	LevelDifficultyAdjustManager:getDAManager():setIsSatisfyPreconditions(satisfyPreconditionsResult)

	local levelDifficultyAdjustV2Group = self.context.userGroupInfo.diffV2 or 0
	DiffAdjustQAToolManager:print(1, "LevelDifficultyAdjustManager", "levelDifficultyAdjustV2Group =", levelDifficultyAdjustV2Group)

	local diffTag = self.context.diffTag or 0
	local fixedActivationTag = self.context.fixedActivationTag
	local activationTag = self.context.activationTag
	local activationTagTopLevelId = self.context.activationTagTopLevelId
	local activationTagTopLevelIdLength = self.context.activationTagTopLevelIdLength
	local activationTagEndTime = self.context.activationTagEndTime
	local activationTagUpdateTime = self.context.activationTagUpdateTime
	local activationTagStartTime = self.context.activationTagStartTime
	local activationTagChangeTime = self.context.activationTagChangeTime
	local now = Localhost:timeInSec()

	DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategy" , "fixedActivationTag =" .. tostring(fixedActivationTag) , "now =" , now )
	DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategy" , "activationTag" , activationTag , "activationTagEndTime" , activationTagEndTime , 
							"activationTagTopLevelId" , activationTagTopLevelId , "activationTagTopLevelIdLength" , activationTagTopLevelIdLength ,
							"levelId" , levelId )

	local closeToMaxLevel = satisfyPreconditionsReason and satisfyPreconditionsReason == AdjustUnactivateReason.kTooCloseToMaxLevel

	if levelId <= 100 then
		self:setLastUnactivateReason(AdjustUnactivateReason.kLow100Level)
		DcUtil:DifficultyAdjustUnactivate(levelId, self.lastUnactivateReason , self.context.userGroupInfo)
		return nil, self.lastUnactivateReason
	end

	if self.context.isTravelLevel then
		if self.context.isPayUser then
			if self.context.IS_ANDROID or self.context.IS_WIN32 then
				self:setLastUnactivateReason(AdjustUnactivateReason.kAndroidPayUser)
			elseif self.context.IS_IOS then 
				self:setLastUnactivateReason(AdjustUnactivateReason.kIOSPayUser)
			end
			DcUtil:DifficultyAdjustUnactivate(levelId, self.lastUnactivateReason , self.context.userGroupInfo)
			return nil, self.lastUnactivateReason
		elseif self.context.travelAdjustLevel and self.context.travelAdjustLevel > 0 then
			local travelAdjustLevel = self.context.travelAdjustLevel
			local reasonText = "travel_diff"..travelAdjustLevel
			return {levelId = levelId, mode = ProductItemDiffChangeMode.kAddColor, ds = travelAdjustLevel, diffTag = diffTag, reason = reasonText}
		else
			self:setLastUnactivateReason(AdjustUnactivateReason.kTravelFailNotEnough)
			DcUtil:DifficultyAdjustUnactivate(levelId, self.lastUnactivateReason , self.context.userGroupInfo)
			return nil, self.lastUnactivateReason
		end
	end

	if satisfyPreconditionsResult then
		if self.context.levelId ~= self.context.topLevel and self.context.levelStar == 0 then
			if not self.context.failCountBeforeFirstPass_localdata then self.context.failCountBeforeFirstPass_localdata = 0 end
			if self.context.failCountBeforeFirstPass_localdata <= 15 then
				return { levelId = levelId , mode = ProductItemDiffChangeMode.kAIAddColor , ds = 1 , reason = "SZ_Fuuu" }
			elseif self.context.failCountBeforeFirstPass_localdata <= 25 then
				return { levelId = levelId , mode = ProductItemDiffChangeMode.kAddColor , ds = 3 , diffTag = diffTag  , reason = "SZ_Diff3" }
			elseif self.context.failCountBeforeFirstPass_localdata <= 40 then
				return { levelId = levelId , mode = ProductItemDiffChangeMode.kAddColor , ds = 4 , diffTag = diffTag  , reason = "SZ_Diff4" }
			else
				return { levelId = levelId , mode = ProductItemDiffChangeMode.kAddColor , ds = 5 , diffTag = diffTag  , reason = "SZ_Diff5" }
			end
		end
	end


	--召回干预
	local canUseReturnUserGroupTest = true
	if closeToMaxLevel then
		canUseReturnUserGroupTest = false --2018.9.27修改  作用等级：【玩家等级，满级-60）
	end

	canUseReturnUserGroupTest = canUseReturnUserGroupTest and satisfyPreconditionsResult

	local newReturnAndLowActiveAdjustResult = NewReturnAndLowActiveAdjustLogic:checkEnableAdjust( self.context )

	if newReturnAndLowActiveAdjustResult then
		MACRO_DEV_START()
		--新的关卡难度调节策略优化 @亚飞 2020.7
		--http://wiki.happyelements.net/pages/viewpage.action?pageId=65248647
		-- printx( 1 , "newReturnAndLowActiveAdjustResult ================ " , table.tostring(newReturnAndLowActiveAdjustResult) )
		MACRO_DEV_END()
		return newReturnAndLowActiveAdjustResult
	else
		if canUseReturnUserGroupTest and activationTag == UserTagValueMap[UserTagNameKeyFullMap.kActivation].kReturnBack then
			local returnUsersRetentionTestGroup = self.context.userGroupInfo.retention or 0
			if returnUsersRetentionTestGroup == 5 then --用户尾号满足回流测试分组
				local maxLevelId = self.context.maxLevelId
				if levelId <= maxLevelId - 30 then --不在顶部15关以内
					local datas = self:checkByReturnUserGroupTest( returnUsersRetentionTestGroup ,
							levelId , diffTag , activationTag , activationTagTopLevelId , activationTagTopLevelIdLength , activationTagEndTime , activationTagUpdateTime , activationTagStartTime )
					if datas then
						return datas
					end
				end
			end
		end


		local lowActiveAdjustResult = LowActiveAdjustLogic:checkEnableAdjust( self.context )

		if lowActiveAdjustResult then
			MACRO_DEV_START()
			--低活跃玩家难度调节
			--http://wiki.happyelements.net/pages/viewpage.action?pageId=54154554
			MACRO_DEV_END()
			return lowActiveAdjustResult
		end
	end

	

	if satisfyPreconditionsResult then
		local payUserAdjustResult = PayUserAdjustLogic:checkEnableAdjust( self.context )
		if payUserAdjustResult then
			--付费玩家难度调节
			--http://wiki.happyelements.net/pages/resumedraft.action?draftId=60852951&draftShareId=bb877aa8-5d11-4452-8905-99aae0a4f3ea&
			return payUserAdjustResult
		end
	end
	
	

	-- local realLevelId = LevelMapManager.getInstance():getMetaLevelId( levelId )
	local hardLevelAdjustExpGroup = self.context.userGroupInfo.hardLevelAdjustExpGroup

	local levelDiffcultFlag = self.context.levelDiffcultFlag

	local maxTop15Level = true --是否为顶部15关
	if levelId <= self.context.maxLevelId - 15 then
		maxTop15Level = false
	end

	local hardLevelStrengthMap , hardLevelAdjustUnactiveReason = HardLevelAdjustLogic:getStrengthMap( 
										hardLevelAdjustExpGroup , 
										levelDiffcultFlag ,
										maxTop15Level ,
										self.context.last60DayPayAmount
									)

	local canEnableFuuuByHardLevelAdjust = false
	if hardLevelStrengthMap then
		if hardLevelAdjustExpGroup == 3 or hardLevelAdjustExpGroup == 6 then
			canEnableFuuuByHardLevelAdjust = true
		end
	else
		canEnableFuuuByHardLevelAdjust = true
	end
	
	-- MA-22721 【1.71版本】松松活动主线关有开局buff的时候禁用fuuu和自动调关  [1.81] 松松三期，非头部玩家仅关闭fuuu，其他不处理
	if self.context.isTsumBuff_fuuu then
		-- self:setLastUnactivateReason( AdjustUnactivateReason.kBlockByTsumBuff )
		-- DcUtil:DifficultyAdjustUnactivate( levelId , self.lastUnactivateReason , self.context.userGroupInfo )
		-- return nil , self.lastUnactivateReason
		canEnableFuuuByHardLevelAdjust = false
	end

	--非ABTest关卡  且  无法使用铁路大亨技能的关卡  才能激活FUUU调整
	if canEnableFuuuByHardLevelAdjust and (not self.context.isABTTestLevel) and (not self.context.hasAnySkillCanUse) then 
		-- 回刷关卡FUUU
		local isFarmStarFuuu = self:isFarmStarFuuu(self.context.userGroupInfo.farmStarGroup)
		if isFarmStarFuuu then
			local farmStarFuuuditionsResult, farmStarFuuuditionsReason = self:checkAdjustSatisfyPreconditions(levelId, {
				isFarmStarFuuu = true,
				farmStarGroup = self.context.userGroupInfo.farmStarGroup,
			})


			if farmStarFuuuditionsResult then
				local checkFuuuResult = self:checkFUUU(levelId, closeToMaxLevel, levelDifficultyAdjustV2Group, true)
				DiffAdjustQAToolManager:print( 1 , "checkFUUU  111" , "isFarmStarFuuu  checkFuuuResult " , checkFuuuResult )
				if checkFuuuResult then return checkFuuuResult end
			else
				if farmStarFuuuditionsReason == AdjustUnactivateReason.kNoLevelTargetProgress then
					DcUtil:log(AcType.kExpire30Days, {category = "FarmFuuuUnactive", t1 = 'kNoLevelTargetProgress'})
				end

				DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategy" , "FarmStarFuuuUnactiveReason :" , tostring(farmStarFuuuditionsReason) )
			end
		else
			DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategy" , "FarmStarFuuuUnactiveReason : return 2  G:" , tostring(self.context.userGroupInfo.farmStarGroup) )
		end

		--fuuu干预 
		if satisfyPreconditionsResult then
			local checkFuuuResult = self:checkFUUU(levelId, closeToMaxLevel, levelDifficultyAdjustV2Group, false)
			DiffAdjustQAToolManager:print( 1 , "checkFUUU  222" , "Fuuu  checkFuuuResult " , checkFuuuResult )
			if checkFuuuResult then return checkFuuuResult end
		end
	else
		DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategy" , "FarmStarFuuuUnactiveReason : return 1" )
	end

	if levelDifficultyAdjustV2Group == 0 and closeToMaxLevel then
		self:setLastUnactivateReason( AdjustUnactivateReason.kTooCloseToMaxLevel )
		DcUtil:DifficultyAdjustUnactivate(levelId, self.lastUnactivateReason , self.context.userGroupInfo)
		return nil , self.lastUnactivateReason
	end

	if not satisfyPreconditionsResult then
		self:setLastUnactivateReason(satisfyPreconditionsReason)
		DcUtil:DifficultyAdjustUnactivate(levelId, self.lastUnactivateReason , self.context.userGroupInfo)
		return nil , self.lastUnactivateReason
	end


	--其它干预
	if levelDifficultyAdjustV2Group == 2 then
		local checkResult = self.DAManager:checkAdjustStrategyByPayUserV2(levelId)
		if checkResult then

			if hardLevelStrengthMap then

				local oldds = checkResult.ds
				checkResult.ds = hardLevelStrengthMap[ checkResult.ds ]

				checkResult.reason = checkResult.reason .. "_hardLevelStrength_" .. tostring(oldds) .. "_" .. tostring(checkResult.ds)
			end

			if checkResult.ds > 0 then
				return checkResult
			end
		end
		self:setLastUnactivateReason(AdjustUnactivateReason.kReason1002)
		DcUtil:DifficultyAdjustUnactivate( levelId , self.lastUnactivateReason , self.context.userGroupInfo )
		return nil , self.lastUnactivateReason
	elseif levelDifficultyAdjustV2Group ~= 7 then --A7分组即时是付费用户也会触发tag难度调整
		if self.context.isPayUser then
			if self.context.IS_ANDROID or self.context.IS_WIN32 then
				self:setLastUnactivateReason(AdjustUnactivateReason.kAndroidPayUser)
			elseif self.context.IS_IOS then 
				self:setLastUnactivateReason(AdjustUnactivateReason.kIOSPayUser)
			end
			DcUtil:DifficultyAdjustUnactivate(levelId, self.lastUnactivateReason , self.context.userGroupInfo )
			return nil , self.lastUnactivateReason
		end
	end

	-- local propSeed = self:getTestPropSeed(levelId)
	local propSeed = nil --虚拟种子已经被禁用了

	
	DiffAdjustQAToolManager:print( 1 , "DiffAdjust" , "diffTag ========================== " , diffTag )

	local doActivationStrategy = false
	if self:isActivationUser() then
		doActivationStrategy = true
	else
		--RemoteDebug:uploadLog( "DiffAdjust break not activation user"  )
	end
	DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategy" , "doActivationStrategy " , doActivationStrategy )

	local function passByHardLevelZeroDS( ds )
		if ds == 0 then
			self:setLastUnactivateReason( AdjustUnactivateReason.kHardLevelZeroDS )
			DcUtil:DifficultyAdjustUnactivate( levelId , self.lastUnactivateReason , self.context.userGroupInfo )
			return true
		end
		return false
	end

	local diffValueMap = UserTagValueMap[UserTagNameKeyFullMap.kTopLevelDiff]
	if diffTag == diffValueMap.kHighDiff5 then
		local ds = 5
		local reasonStr = "Diff5"
		if hardLevelStrengthMap then
			ds = hardLevelStrengthMap[ ds ]
			if passByHardLevelZeroDS( ds ) then
				return nil , self.lastUnactivateReason
			end
			reasonStr = reasonStr .. "_hardLevelStrength_5_" .. tostring(ds)
		end
		return { levelId = levelId , mode = ProductItemDiffChangeMode.kAddColor , ds = ds , diffTag = diffTag , propSeed = propSeed , reason = reasonStr }
	elseif diffTag == diffValueMap.kHighDiff4 then
		local ds = 4
		local reasonStr = "Diff4"
		if hardLevelStrengthMap then
			ds = hardLevelStrengthMap[ ds ]
			if passByHardLevelZeroDS( ds ) then
				return nil , self.lastUnactivateReason
			end
			reasonStr = reasonStr .. "_hardLevelStrength_4_" .. tostring(ds)
		end
		return { levelId = levelId , mode = ProductItemDiffChangeMode.kAddColor , ds = ds , diffTag = diffTag , propSeed = propSeed , reason = reasonStr }
	elseif doActivationStrategy then
		local now = Localhost:timeInSec()
		DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategy now" , now , "activationTagEndTime" , activationTagEndTime , 
			"activationTagTopLevelId" , activationTagTopLevelId , "activationTagTopLevelIdLength" , activationTagTopLevelIdLength ,
			"levelId" , levelId )
		if activationTag == UserTagValueMap[UserTagNameKeyFullMap.kActivation].kWillLose then --濒临流失
			if levelId >= tonumber(activationTagTopLevelId) and levelId <= tonumber(activationTagTopLevelId) + 2 then
				local ds = 3
				local reasonStr = "WillLose1"
				if hardLevelStrengthMap then
					ds = hardLevelStrengthMap[ ds ]
					if passByHardLevelZeroDS( ds ) then
						return nil , self.lastUnactivateReason
					end
					reasonStr = reasonStr .. "_hardLevelStrength_3_" .. tostring(ds)
				end
				return { levelId = levelId ,mode = ProductItemDiffChangeMode.kAddColor , ds = ds , diffTag = diffTag , propSeed = propSeed , reason = reasonStr }
			else
				local ds = 2
				local reasonStr = "WillLose2"
				if hardLevelStrengthMap then
					ds = hardLevelStrengthMap[ ds ]
					if passByHardLevelZeroDS( ds ) then
						return nil , self.lastUnactivateReason
					end
					reasonStr = reasonStr .. "_hardLevelStrength_2_" .. tostring(ds)
				end
				return { levelId = levelId ,mode = ProductItemDiffChangeMode.kAddColor , ds = ds , diffTag = diffTag , propSeed = propSeed , reason = reasonStr }
			end
		elseif activationTag == UserTagValueMap[UserTagNameKeyFullMap.kActivation].kReturnBack then --回流用户

			local maxLevelId = self.context.maxLevelId
			if levelId <= maxLevelId - 30 then --不在顶部30关以内
				local group = self.context.userGroupInfo.retention or 5
				local datas = self:checkByReturnUserGroupTest( 
						group , levelId , diffTag , activationTag , activationTagTopLevelId , activationTagTopLevelIdLength , activationTagEndTime , activationTagUpdateTime , activationTagStartTime )
				if datas then

					if hardLevelStrengthMap then
						local oldds = datas.ds
						datas.ds = hardLevelStrengthMap[ datas.ds ]
						if passByHardLevelZeroDS( datas.ds ) then
							return nil , self.lastUnactivateReason
						end

						datas.reason = datas.reason .. "_hardLevelStrength_3_" .. tostring(oldds) .. "_" .. tostring(datas.ds)
					end

					return datas
				end
			end
		end
	else
		if diffTag == 0 then
			--RemoteDebug:uploadLog( "DiffAdjust break difficulty unactive"  )
		elseif diffTag == diffValueMap.kHighDiff1 then
			local ds = 1
			local reasonStr = "Diff1"
			if hardLevelStrengthMap then
				ds = hardLevelStrengthMap[ ds ]
				if passByHardLevelZeroDS( ds ) then
					return nil , self.lastUnactivateReason
				end
				reasonStr = reasonStr .. "_hardLevelStrength_1_" .. tostring(ds)
			end
			return { levelId = levelId ,mode = ProductItemDiffChangeMode.kAddColor , ds = ds , diffTag = diffTag , propSeed = propSeed , reason = reasonStr }
		elseif diffTag == diffValueMap.kHighDiff2 then
			local ds = 2
			local reasonStr = "Diff2"
			if hardLevelStrengthMap then
				ds = hardLevelStrengthMap[ ds ]
				if passByHardLevelZeroDS( ds ) then
					return nil , self.lastUnactivateReason
				end
				reasonStr = reasonStr .. "_hardLevelStrength_2_" .. tostring(ds)
			end
			return { levelId = levelId ,mode = ProductItemDiffChangeMode.kAddColor , ds = ds , diffTag = diffTag , propSeed = propSeed , reason = reasonStr }
		elseif diffTag == diffValueMap.kHighDiff3 then
			--三阶难度临时改为和二阶难度相同的策略
			local ds = 3
			local reasonStr = "Diff3"
			if hardLevelStrengthMap then
				ds = hardLevelStrengthMap[ ds ]
				if passByHardLevelZeroDS( ds ) then
					return nil , self.lastUnactivateReason
				end
				reasonStr = reasonStr .. "_hardLevelStrength_3_" .. tostring(ds)
			end
			return { levelId = levelId ,mode = ProductItemDiffChangeMode.kAddColor , ds = ds , diffTag = diffTag , propSeed = propSeed , reason = reasonStr }
		elseif propSeed then
			self:setLastUnactivateReason( AdjustUnactivateReason.kReason20 )
			return { levelId = levelId , diffTag = diffTag , propSeed = propSeed }
		end
	end
	self:setLastUnactivateReason( AdjustUnactivateReason.kReason7 )
	DcUtil:DifficultyAdjustUnactivate( levelId , self.lastUnactivateReason , self.context.userGroupInfo )
	return nil , self.lastUnactivateReason
end

function LevelDifficultyAdjustManager:checkFUUU( levelId, closeToMaxLevel, levelDifficultyAdjustV2Group, isFarmStarFuuu )
	local canUseFuuuAdjust = true
	if self.context.hasInitBuffFromPreBuffAct and (not self.context.preBuffLogicCanUseFUUU) then
		canUseFuuuAdjust = false
	end
	if canUseFuuuAdjust then
		if isFarmStarFuuu then
			return {levelId = levelId ,mode = ProductItemDiffChangeMode.kAIAddColor , ds = 1 , reason = "FarmFuuu"}
		end

		local fuuuResult , fuuuUnactivateReason = self:getFuuuManager():checkAdjustStrategyByFuuuV2(
													levelId, closeToMaxLevel, levelDifficultyAdjustV2Group , self:getContext() )

		DiffAdjustQAToolManager:print( 1 , "LevelDifficultyAdjustManager:checkFUUU  Result" , fuuuResult , "Reason" , fuuuUnactivateReason )

		if fuuuResult then
			return {levelId = levelId ,mode = ProductItemDiffChangeMode.kAIAddColor , ds = 1 , reason = "NewFuuuV2"}
		else
			self:setLastFuuuUnactivateReason( fuuuUnactivateReason or FUUUAdjustUnactivateReason.UNKNOW )
		end
	else
		DiffAdjustQAToolManager:print( 1 , "LevelDifficultyAdjustManager:checkFUUU  Result False"  , "Reason" , FUUUAdjustUnactivateReason.PreBuffAct )
		self:setLastFuuuUnactivateReason( FUUUAdjustUnactivateReason.PreBuffAct )
	end
end

function LevelDifficultyAdjustManager:checkByReturnUserGroupTest( group , levelId, diffTag, activationTag, activationTagTopLevelId, activationTagTopLevelIdLength, activationTagEndTime, activationTagUpdateTime , activationTagStartTime)

	activationTagTopLevelId = tonumber(activationTagTopLevelId)
	activationTagUpdateTime = tonumber(activationTagUpdateTime)

	local returnUsersRetentionTestGroup = group

	-- RemoteDebug:uploadLogWithTag( "RRR" , "checkByReturnUserGroupTest returnUsersRetentionTestGroup" , returnUsersRetentionTestGroup )
	DiffAdjustQAToolManager:print( 1 , "checkByReturnUserGroupTest returnUsersRetentionTestGroup" , returnUsersRetentionTestGroup )

	local function updateAndReturnLogTable()
		local today = self.context.today
		-- RemoteDebug:uploadLogWithTag( "RRR" , "today =" , today )
		DiffAdjustQAToolManager:print( 1 , "RRR" , "today =" , today )

		local logTable = self.context.dateLogTable
		-- printx( 1 , "updateAndReturnLogTable ==============  " , table.tostring(logTable) )
		local function createNewData()
			local tab = {}
			-- tab.testEndTime = tostring(activationTagStartTime)
			tab.activationTagStartTime = tostring(activationTagStartTime)
			tab.totalDays = 0
			tab.log = {}

			return tab
		end

		if not logTable then
			-- printx( 1 , "updateAndReturnLogTable FFF 1" )
			logTable = createNewData()
		elseif logTable.activationTagStartTime ~= tostring(activationTagStartTime) then
			-- if tonumber(testEndTime) - tonumber(logTable.testEndTime) > 3600*24*15 then
				if logTable.testEndTime and ( logTable.activationTagStartTime == nil or logTable.activationTagStartTime == 0 ) then
					--老版本数据迁移
					-- printx( 1 , "updateAndReturnLogTable FFF 2" )
					logTable.activationTagStartTime = tostring(activationTagStartTime)
					logTable.testEndTime = nil
				else
					-- printx( 1 , "updateAndReturnLogTable FFF 3" )
					logTable = createNewData()
				end
			-- end
		end

		-- RemoteDebug:uploadLogWithTag( "RRR" , "logTable =" , table.tostring(logTable) )
		-- DiffAdjustQAToolManager:print( 1 , "updateAndReturnLogTable  222  logTable =" , table.tostring(logTable) )

		if not logTable.log["d" .. tostring(today)] then
			logTable.totalDays = logTable.totalDays + 1
			logTable.log["d" .. tostring(today)] = true
		end

		if not self.context.isMock then
			LocalBox:setData( LocalBoxKeys.ReturnUserGroupTestP1 , logTable )
		end
		
		-- RemoteDebug:uploadLogWithTag( "RRR" , "checkByReturnUserGroupTest logTable.totalDays" , logTable.totalDays )
		DiffAdjustQAToolManager:print( 1 , "checkByReturnUserGroupTest logTable.totalDays" , logTable.totalDays )

		return logTable
	end

	if returnUsersRetentionTestGroup == 5 then
		
		local logTable = updateAndReturnLogTable()

		if logTable.totalDays > 7 then
			return nil
		end

		local td = logTable.totalDays
		if logTable.totalDays > 6 then td = 6 end

		td = math.abs( td - 6 )
		if td < 0 then td = 0 end
		if td > 5 then td = 5 end

		-- RemoteDebug:uploadLogWithTag( "RRR" , "checkByReturnUserGroupTest td" , td )
		-- printx( 1 , "logTable ================================== " , table.tostring(logTable) )
		DiffAdjustQAToolManager:print( 1 , "checkByReturnUserGroupTest td" , td )
		-- debug.debug()
		-- if td > 0 then
		-- 	return { levelId = levelId ,mode = ProductItemDiffChangeMode.kAddColor , ds = td , diffTag = diffTag , propSeed = nil , reason = tostring( "ReturnBack50" .. tostring(td) ) }
		-- end

		if td > 0 then
			local levelNumsOfTD = {20, 20, 15, 15, 10}
			local tdLevelNum = 0
			for i = 1, 5 do
				tdLevelNum = tdLevelNum + levelNumsOfTD[i]
				if (levelId < activationTagTopLevelId + tdLevelNum) then
					local useDS = math.min(6-i, td)
					DiffAdjustQAToolManager:print( 1 , "checkByReturnUserGroupTest useDS" , useDS )
					return { levelId = levelId ,mode = ProductItemDiffChangeMode.kAddColor , ds = useDS, diffTag = diffTag , propSeed = nil , reason = tostring( "ReturnBack50" .. tostring(td) ) }
				end
			end
			-- 超出调整关卡数上限
		end
	elseif returnUsersRetentionTestGroup == 6 then

		local logTable = updateAndReturnLogTable()
		local result_1 = 0

		if logTable.totalDays > 7 then
			result_1 = 0
		else
			local td = logTable.totalDays
			if logTable.totalDays > 6 then td = 6 end

			td = math.abs( td - 6 )
			if td < 0 then td = 0 end
			if td > 5 then td = 5 end

			-- RemoteDebug:uploadLogWithTag( "RRR" , "checkByReturnUserGroupTest td" , td )

			if td > 0 then
				result_1 = td	
			end
		end

		local result_2 = 0

		if levelId >= activationTagTopLevelId and levelId <= activationTagTopLevelId + 4 then
			result_2 = 5
		elseif levelId > activationTagTopLevelId + 4 and levelId <= activationTagTopLevelId + 9 then
			result_2 = 4
		elseif levelId > activationTagTopLevelId + 9 and levelId <= activationTagTopLevelId + 14 then
			result_2 = 3
		elseif levelId > activationTagTopLevelId + 14 and levelId <= activationTagTopLevelId + 19 then
			result_2 = 2
		elseif levelId > activationTagTopLevelId + 19 and levelId <= activationTagTopLevelId + 24 then
			result_2 = 1
		end

		local result_fin = math.max( result_1 , result_2 )

		if result_fin > 0 then
			local resultData = { 
							levelId = levelId ,
							mode = ProductItemDiffChangeMode.kAddColor , 
							ds = result_fin , 
							diffTag = diffTag , 
							propSeed = nil , 
							reason = "ReturnBack60" .. tostring(6 - result_2) .. "_" .. tostring(result_fin) }

			DiffAdjustQAToolManager:print( 1 , "checkByReturnUserGroupTest result_1" , result_1 , "result_2" , result_1 , "result_fin" , result_fin )

			return resultData
		end

	else

		if levelId >= tonumber(activationTagTopLevelId) and levelId <= tonumber(activationTagTopLevelId) + 4 then
			return { levelId = levelId ,mode = ProductItemDiffChangeMode.kAddColor , ds = 5 , diffTag = diffTag , propSeed = nil , reason = "ReturnBack1" }
		else
			return { levelId = levelId ,mode = ProductItemDiffChangeMode.kAddColor , ds = 2 , diffTag = diffTag , propSeed = nil , reason = "ReturnBack2" }
		end

	end

	return nil
end

function LevelDifficultyAdjustManager:doAdjustStrategy(mainLogic, fromReplay)
	MACRO_DEV_START()
	--！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！
	--注意，这个方法的任何改动，请在LocalBox.lua中搜索 LevelDifficultyAdjustManager:doAdjustStrategy 并同步修改
	--！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！
	MACRO_DEV_END()

	local strategyData = mainLogic.difficultyAdjustData
	if strategyData then

		local vsMode = nil
		if strategyData.mode then
			--RemoteDebug:uploadLogWithTag( "LevelDifficultyAdjustManager" , "doAdjustStrategy 111" , strategyData.mode , strategyData.ds)
			ProductItemDiffChangeLogic:changeMode( strategyData.mode , strategyData.ds )
			if strategyData.ds == 7 then
				local ids = { 3100 , 381 , 1245 , 3051 }
				if not table.includes( ids , self.context.levelId ) then
					vsMode = 9
					GameInitDiffChangeLogic:changeMode( vsMode )
				end
			end
		end

		--levelId , userGroup , mode , ds , seed , activationTag , activationTagTopLevelId , activationTagEndTime , diff 
		if not fromReplay then
			local hasLevelTargetProgressData = false
			if self.localLevelData and self.localLevelData.levelTargetProgress then
				hasLevelTargetProgressData = true
			end

			local isAIGroup = false

			strategyData.realCostMove = "PreStart"

			DcUtil:levelDifficultyAdjustActivated( 
				strategyData.levelId ,
				self.context.userGroupInfo.diffV2 ,
				strategyData.mode , 
				strategyData.ds , 
				strategyData.adjustSeed , 
				self.context.activationTag , 
				self.context.activationTagTopLevelId , 
				self.context.activationTagEndTime , 
				strategyData.diffTag ,
				strategyData.propSeed ,
				strategyData.reason ,
				strategyData.realCostMove ,
				hasLevelTargetProgressData , 
				mainLogic.replayMode , 
				isAIGroup ,
				self.context.userGroupInfo,
				vsMode
				)

			self:addStrategyDataList( strategyData )
		end
		
		self:clearLastUnactivateReason()
		-- self:clearLastFuuuUnactivateReason()
	end
end

function LevelDifficultyAdjustManager:checkAdjustStrategyInLevelByLastLocalData()
	--RemoteDebug:uploadLogWithTag( "LevelDifficultyAdjustManager" , "checkAdjustStrategyInLevelByLastLocalData 111" )
	local list = self:getStrategyDataList()
	if list and #list > 0 then
		local strategyData = list[ #list ]
		if strategyData.mode then
			--RemoteDebug:uploadLogWithTag( "LevelDifficultyAdjustManager" , "checkAdjustStrategyInLevelByLastLocalData 222 mode" , strategyData.mode , "ds" , strategyData.ds )
			ProductItemDiffChangeLogic:changeMode( strategyData.mode , strategyData.ds )
		end
	end
end


function LevelDifficultyAdjustManager:checkAdjustStrategyInLevel( levelId , realCostMove )
	-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyInLevel" , "levelId" , levelId , "realCostMove" , realCostMove )
	local levelDifficultyAdjustV2Group = 0
	if self.context and self.context.userGroupInfo then
		levelDifficultyAdjustV2Group = self.context.userGroupInfo.diffV2
	end

	if levelDifficultyAdjustV2Group == 2 then
		local checkResult , userTestGroup = self.DAManager:checkAdjustStrategyByPayUserV2(levelId)
		if checkResult then
			self:doAdjustStrategyInLevel( realCostMove , checkResult , userTestGroup or 0 )
		end
	end
end

function LevelDifficultyAdjustManager:doAdjustStrategyInLevel( realCostMove , strategyData , userTestGroup )

	if strategyData then

		strategyData.realCostMove = realCostMove
		strategyData.testGroupS6 = userTestGroup

		if strategyData.mode and strategyData.ds then
			
			local dataHasChanged = ProductItemDiffChangeLogic:changeMode( strategyData.mode , strategyData.ds )

			-- RemoteDebug:uploadLogWithTag( "doAdjustStrategyInLevel" , "mode" , strategyData.mode , "ds" , strategyData.ds , "dataHasChanged" , dataHasChanged , "realCostMove" , realCostMove )

			if dataHasChanged then
				DcUtil:levelDifficultyAdjustActivated( 
					strategyData.levelId ,
					tonumber( 200 + userTestGroup ) ,
					strategyData.mode , 
					strategyData.ds , 
					nil , 
					nil , 
					nil , 
					nil , 
					nil ,
					nil ,
					strategyData.reason ,
					realCostMove
					)

				local newId = self:__countCurrStrategyID( strategyData ) or 0
				self:addStrategyIDList( newId , realCostMove )

				self:addStrategyDataList( strategyData )

				-- RemoteDebug:uploadLogWithTag( "doAdjustStrategyInLevel" , "!!!!!!!!!!!!!!!!!!!!!!!!! newId" , newId , "realCostMove" , realCostMove )
			end
		end
	end
end

function LevelDifficultyAdjustManager:setStrategyIDList( strategyIDList )
	--printx( 1 , "LevelDifficultyAdjustManager:setStrategyIDList  strategyIDList =" , table.tostring(strategyIDList) )
	self.strategyIDList = strategyIDList
end

function LevelDifficultyAdjustManager:addStrategyIDList( strategyID , realCostMove )
	--printx( 1 , "LevelDifficultyAdjustManager:addStrategyIDList ========== " , strategyID , realCostMove  )
	if not self.strategyIDList then 
		--printx( 1 , "LevelDifficultyAdjustManager:addStrategyIDList  self.strategyIDList = {} !!!!!!!!!!!!!!!!" )
		self.strategyIDList = {} 
	end

	table.insert( self.strategyIDList , { moves = realCostMove , id = strategyID } )
	
	if ReplayDataManager:getCurrLevelReplayData() and ReplayDataManager:getCurrLevelReplayData().strategyDCInfo then
		ReplayDataManager:getCurrLevelReplayData().strategyDCInfo.nd1 = self.strategyIDList
		--ReplayDataManager:flushReplayCache()
	end
end

function LevelDifficultyAdjustManager:getStrategyIDList()
	return self.strategyIDList or {}
end

function LevelDifficultyAdjustManager:getStrategyIDListByDCString()
	if self.strategyIDList then
		local str = ""
		--printx( 1 , "LevelDifficultyAdjustManager:getStrategyIDListByDCString  strategyIDList =" , table.tostring(self.strategyIDList) )
		for k,v in ipairs( self.strategyIDList ) do
			if str == "" then
				str = tostring(v.moves or 0) .. "-" .. tostring(v.id)
			else
				str = str .. "~" .. tostring(v.moves or 0) .. "-" .. tostring(v.id)
			end
		end
		--printx( 1 , "LevelDifficultyAdjustManager:getStrategyIDListByDCString ~~~~~~~~~~~  " , str )
		return str
	end

	return ""
end

function LevelDifficultyAdjustManager:clearStrategyIDList()
	-- DiffAdjustQAToolManager:print( 1 , "LevelDifficultyAdjustManager:clearStrategyIDList" )
	self.strategyIDList = {}
end


function LevelDifficultyAdjustManager:setStrategyDataList( strategyDataList )
	self.strategyDataList = strategyDataList
end


function LevelDifficultyAdjustManager:addStrategyDataList(strategyData)
	if not self.strategyDataList then self.strategyDataList = {} end

	table.insert( self.strategyDataList , strategyData )
	if ReplayDataManager:getCurrLevelReplayData() and ReplayDataManager:getCurrLevelReplayData().strategyDCInfo then
		ReplayDataManager:getCurrLevelReplayData().strategyDCInfo.nd2 = self.strategyDataList
		--ReplayDataManager:flushReplayCache()
	end
end

function LevelDifficultyAdjustManager:getStrategyDataList()
	return self.strategyDataList or {}
end

function LevelDifficultyAdjustManager:getStrategyDataListByDCString()
	if self.strategyDataList then
		local str = ""
		--printx( 1 , "LevelDifficultyAdjustManager:getStrategyIDListByDCString  strategyDataList =" , table.tostring(self.strategyDataList) )
		for k,v in ipairs( self.strategyDataList ) do
			if str == "" then
				str = tostring(v.realCostMove or 0) .. "-" .. tostring(v.reason)
			else
				str = str .. "~" .. tostring(v.realCostMove or 0) .. "-" .. tostring(v.reason)
			end
		end

		--printx( 1 , "LevelDifficultyAdjustManager:getStrategyDataListByDCString ~~~~~~~~~~~  " , str )
		return str
	end

	return ""
end

function LevelDifficultyAdjustManager:clearStrategyData()
	-- DiffAdjustQAToolManager:print( 1 , "LevelDifficultyAdjustManager:clearStrategyData" )
	self.strategyDataList = nil
end

function LevelDifficultyAdjustManager:setLastUnactivateReason(unactivateReason)
	--RemoteDebug:uploadLogWithTag( "setLastUnactivateReason" , "unactivateReason" , unactivateReason )
	DiffAdjustQAToolManager:print( 1 , "LevelDifficultyAdjustManager:setLastUnactivateReason" , unactivateReason )
	self.lastUnactivateReason = unactivateReason
end

function LevelDifficultyAdjustManager:getLastUnactivateReason()
	return self.lastUnactivateReason or 0
end

function LevelDifficultyAdjustManager:clearLastUnactivateReason()
	-- DiffAdjustQAToolManager:print( 1 , "LevelDifficultyAdjustManager:clearLastUnactivateReason" )
	self.lastUnactivateReason = nil
end

function LevelDifficultyAdjustManager:setLastFuuuUnactivateReason( unactivateReason )
	self.lastFuuuUnactivateReason = unactivateReason
end

function LevelDifficultyAdjustManager:getLastFuuuUnactivateReason()
	return self.lastFuuuUnactivateReason or 0
end

function LevelDifficultyAdjustManager:clearLastFuuuUnactivateReason()
	self.lastFuuuUnactivateReason = nil
end

function LevelDifficultyAdjustManager:getLevelLeftMoves(levelId)
	if self.localLevelData and self.localLevelData.levelLeftMoves then
		return self.localLevelData.levelLeftMoves[ tostring(levelId) ]
	end
	return nil
end

function LevelDifficultyAdjustManager:getTestPropSeed(levelId)

	local uid = self.context.uid

	if not MaintenanceManager:getInstance():isEnabledInGroup("VirtualSeed" , "G2" , uid) then
		--RemoteDebug:uploadLog( "getTestPropSeed break 1"  )
		return nil
	end

	local failCounts = self.context.failCount

	--[[
	setTimeOut( function () 
		CommonTip:showTip( "failCounts:" .. tostring(failCounts) , "negative" , nil , 20 )
		end , 3 )
	]]

	if failCounts % 4 ~= 3 then
		--RemoteDebug:uploadLog( "getTestPropSeed break 2 failCounts" , failCounts  )
		return nil
	end

	local ranlist = {}
	local leftlist = {}

	local seedLog = self:getPropSeedUsedLog( levelId )

	if #seedLog >= 15 then
		--RemoteDebug:uploadLog( "getTestPropSeed break 3.1 " )
		return nil
	end

	local propseeds = self:getPropSeedList( levelId )
	local seedLogMap = {}

	for i = 1 , #seedLog do
		seedLogMap[ seedLog[i] ] = true
	end

	for i = 1 , #propseeds do
		if not seedLogMap[ propseeds[i] ] then
			table.insert( leftlist , propseeds[i] )
		end
	end

	if #leftlist > 0 then

		local ranIndex = math.random( 1 , #leftlist )
		local selectedSeed = leftlist[ranIndex]

		return selectedSeed
	else
		--RemoteDebug:uploadLog( "getTestPropSeed break 3.2 " )
	end

	return nil
end