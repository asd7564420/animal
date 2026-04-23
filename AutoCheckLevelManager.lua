require "zoo.panel.AutoPlayCheckToolbar"
require "zoo.panel.AutoPlayCheckResultPanel"
require "zoo.panel.AutoPlayCheckProgressPanel"

AutoCheckLevelManager = {}

-- 错误原因。这里加完后需要在 http://dev.kxxxl.com/ai-manager/resultSchema.html 添加对应的 resultCode释义
AutoCheckLevelFinishReason = {
	
	kFinished = 1 , --正常结束
	kCrash = 2 , --系统级闪退（强杀进程）
	kLuaCrash = 3 , --代码闪退（有bug）
	kOverTooMushStep = 4 , --超过最大步数且没有过关
	kReplay_Crash = 5 , --重放时系统级闪退（强杀进程）
	kReplay_LuaCrash = 6 , --重放时代码闪退（有bug）
	kReplay_ConsistencyError = 7 , --重放结束但结果和原始情况不一致
	kFinishedButNotReachOneStar = 11 , --关卡结束但未达到一星
	kFinishedButHasNoSwap = 12 , --没有可交换的物体，关卡失败
	kFinishedButHasNoVenom = 13 , --没有毒液，关卡失败
	kEndlessLoopByPortal = 14 , --无限掉落(传送门循环)
	kEndlessLoopByColor = 15 , --无限掉落（无限三消）
	kUnexpectedStoped = 16 , --意外停止，原因不明
	kUnexpectedSwap = 17 , --非预期的指定交换
	kQASwapErr = 18 , --QA干预框架要求执行的交换动作执行失败
	kQAPropErr = 19 , --QA干预框架要求执行的道具使用动作执行失败
	kQAStartLevelErr = 20 , --QA干预框架失败
	kQANextLevelErr = 21 , --QA干预框架失败
	kQAEndLevelErr = 22 , --QA干预框架失败
	kCNNConfigErr = 23 , --打关启动参数解析失败
	kUnexpectedAISwap = 24, --AI做出了非预期的指定交换
	kUsePropWhenActionRunning = 25, --GameBoardLogic:useProp时Action队列不为空
	kHasNoOplog = 26, --oplog不存在
	kReplayFinButNotOver = 27, --replay重放步骤已经播完，关卡未结束
	kBeforeWaitingState = 28, --BeforeWaitingState 太久
}

MACRO_DEV_START()

AutoCheckLevelEvent = {
	LEVEL_SUCCESS = "AutoCheckLevel_success" ,
	LEVEL_FAILED = "AutoCheckLevel_failed" ,
	ALL_LEVEL_CHECK_FINISHED = "AutoCheckLevel_all_finished" ,
}

local localCheckContextFilePath = HeResPathUtils:getUserDataPath() .. "/AutoCheckContext.ds"
local localFilePath = HeResPathUtils:getUserDataPath() .. "/AutoCheckResult.ds"

if __ANDROID then
	localFilePath = "//sdcard/AutoCheckResult.txt"
end

function AutoCheckLevelManager:check( startLevel , endLevel , checkCount , checkParameter , finCallback , errorCallback )
	_G.isQAAutoPlayMode = true
	
	local localData = LocalBox:getData( AutoPlayCheckToolbar.localBoxKey ) or AutoPlayCheckToolbar:createDefaultLocalData()
	localData.currCheckContext = {}
	localData.currCheckContext.startLevel = startLevel
	localData.currCheckContext.endLevel = endLevel
	localData.currCheckContext.checkCount = checkCount
	localData.currCheckContext.checkParameter = checkParameter
	localData.currCheckContext.startTime = Localhost:timeInSec()
	LocalBox:setData( AutoPlayCheckToolbar.localBoxKey , localData )

	self.currLevelId = startLevel
	self.endLevelId = endLevel
	self.currCheckCount = 1
	self.maxCount = checkCount
	self.checkParameter = checkParameter
	self.finCallback = finCallback
	self.errorCallback = errorCallback

	self:flushContext()
	self:clearResultData()
	self.resultData = {}

	self.eventDispatcher = EventDispatcher.new()
	local checkData = self:createNextLevelCheckData()

	self:__doCheck( checkData , function () end , function () end )
end

function AutoCheckLevelManager:checkLevelList(levelList, checkCount , checkParameter , finCallback , errorCallback)
	self.levelList = levelList
	self.currLevelId = levelList[1]
	self.endLevelId = levelList[#levelList]
	self.currCheckCount = 1
	self.maxCount = checkCount
	self.checkParameter = checkParameter
	self.finCallback = finCallback
	self.errorCallback = errorCallback

	self:flushContext()
	self:clearResultData()
	self.resultData = {}

	self.eventDispatcher = EventDispatcher.new()
	local checkData = self:createNextLevelCheckData()

	self:__doCheck( checkData , function () end , function () end )
end

function AutoCheckLevelManager:getNextLevelId()
	if self.levelList then
		for i, v in ipairs(self.levelList) do
			if v == self.currLevelId then
				return self.levelList[i+1]
			end
		end
	else
		return self.currLevelId + 1
	end
end

function AutoCheckLevelManager:createNextLevelCheckData()

	local checkData = {}

	checkData.levelId = self.currLevelId
	checkData.currCheckCount = self.currCheckCount
	checkData.addSpeed = self.checkParameter.addSpeed
	checkData.useReplay = self.checkParameter.useReplay


	if self.checkParameter.preProp then
		if self.checkParameter.randomTrigger then

			if math.random() < 0.4 then
				checkData.preProp = {}
				
				if math.random() < 0.8 then table.insert(checkData.preProp , { id = 10087} ) end
	    		-- if math.random() < 0.8 then table.insert(checkData.preProp , { id = 10089} ) end -- replaced by 10099
	    		if math.random() < 0.8 then table.insert(checkData.preProp , { id = 10018} ) end
	    		if math.random() < 0.8 then table.insert(checkData.preProp , { id = 10015} ) end
	    		if math.random() < 0.8 then table.insert(checkData.preProp , { id = 10007} ) end
	    		if math.random() < 0.8 then table.insert(checkData.preProp , { id = 10099} ) end
			end
			
		else
			checkData.preProp = {}
			table.insert( checkData.preProp , { id = 10087} )
    		-- table.insert( checkData.preProp , { id = 10089} ) -- replaced by 10099
    		table.insert( checkData.preProp , { id = 10018} )
    		table.insert( checkData.preProp , { id = 10015} )
    		table.insert( checkData.preProp , { id = 10007} )
    		table.insert( checkData.preProp , { id = 10099} )
		end
	end

	if self.checkParameter.buffs then
		if self.checkParameter.randomTrigger then

			if math.random() < 0.4 then
				checkData.buffs = {}
				
				if math.random() < 0.8 then table.insert(checkData.buffs , { buffType = InitBuffType.RANDOM_BIRD } ) end
	    		if math.random() < 0.8 then table.insert(checkData.buffs , { buffType = InitBuffType.LINE} ) end
	    		if math.random() < 0.8 then table.insert(checkData.buffs , { buffType = InitBuffType.WRAP} ) end
	    		if math.random() < 0.8 then table.insert(checkData.buffs , { buffType = InitBuffType.BUFF_BOOM} ) end -- replace later
	    		-- if math.random() < 0.8 then table.insert(checkData.buffs , { buffType = InitBuffType.FIRECRACKER} ) end
			end
			
		else
			checkData.buffs = {}
			table.insert( checkData.buffs , { buffType = InitBuffType.RANDOM_BIRD} )
    		table.insert( checkData.buffs , { buffType = InitBuffType.LINE} )
    		table.insert( checkData.buffs , { buffType = InitBuffType.WRAP} )
    		table.insert( checkData.buffs , { buffType = InitBuffType.BUFF_BOOM} ) -- replace later
    		-- table.insert( checkData.buffs , { buffType = InitBuffType.FIRECRACKER} )
		end
	end

	if self.checkParameter.dropColorAdjust and self.checkParameter.dropColorAdjust > 0 then
		if self.checkParameter.randomTrigger then

			if math.random() < 0.4 then
				checkData.dropColorAdjust = {}

				if self.checkParameter.dropColorAdjust >= 31 and self.checkParameter.dropColorAdjust <= 35 then 
					table.insert(checkData.dropColorAdjust , { mode = ProductItemDiffChangeMode.kAddColor , ds = tonumber(self.checkParameter.dropColorAdjust - 30) } ) 
				elseif self.checkParameter.dropColorAdjust == 41 then
					table.insert(checkData.dropColorAdjust , { mode = ProductItemDiffChangeMode.kAIAddColor , ds = 1 } ) 
				end
			end
			
		else
			checkData.dropColorAdjust = {}
			if self.checkParameter.dropColorAdjust >= 31 and self.checkParameter.dropColorAdjust <= 35 then 
				table.insert(checkData.dropColorAdjust , { mode = ProductItemDiffChangeMode.kAddColor , ds = tonumber(self.checkParameter.dropColorAdjust - 30) } ) 
			elseif self.checkParameter.dropColorAdjust == 41 then
				table.insert(checkData.dropColorAdjust , { mode = ProductItemDiffChangeMode.kAIAddColor , ds = 1 } ) 
			end
		end
	end

	if self.checkParameter.useProp then
		if self.checkParameter.randomTrigger then

			if math.random() < 0.4 then
				checkData.useProp = {}
				
				if math.random() < 0.8 then table.insert(checkData.useProp , { propId = GamePropsType.kRefresh } ) end
	    		if math.random() < 0.8 then table.insert(checkData.useProp , { propId = GamePropsType.kBack} ) end
			end
			
		else
			checkData.useProp = {}
			table.insert(checkData.useProp , { propId = GamePropsType.kRefresh } )
			table.insert(checkData.useProp , { propId = GamePropsType.kBack } )
		end
	end

	if self.checkParameter.scoreBottle and self.checkParameter.scoreBottle > 0 then
		-- ScoreBuffBottleLogic:changeTestInitAmount()		-- 调试刷星瓶初始数值
		checkData.scoreBottle = self.checkParameter.scoreBottle
	end

	if self.checkParameter.maxstep and self.checkParameter.maxstep > 0 then
		checkData.maxstep = self.checkParameter.maxstep
	end

	return checkData
end


function AutoCheckLevelManager:__doCheck( checkData , finCallback , errorCallback )

	self.currCheckData = checkData
		
	local step = {randomSeed = 0, replaySteps = {}, level = checkData.levelId , selectedItemsData = {}}

    if checkData.preProp then
    	for k,v in ipairs(checkData.preProp) do
    		table.insert(step.selectedItemsData , { id = v.id } )
    	end
    end

    if checkData.buffs then
    	for k,v in ipairs(checkData.buffs) do
    		GameInitBuffLogic:addInitBuff( {buffType = v.buffType , createType = InitBuffCreateType.DEFAULT } )
    	end
    end

    if checkData.dropColorAdjust then
    	for k,v in ipairs(checkData.dropColorAdjust) do
    		ProductItemDiffChangeLogic:changeMode( v.mode , v.ds )
    	end
    end

    if checkData.scoreBottle then
    	require "zoo.gamePlay.BoardLogic.CertainPlayLogic.ScoreBuffBottleLogic"
		ScoreBuffBottleLogic.testInitAmount = checkData.scoreBottle
    end

    if checkData.maxstep then
    	step.maxstep = checkData.maxstep
    end

    step.addSpeed = checkData.addSpeed

	local newStartLevelLogic = NewStartLevelLogic:create( nil , step.level , step.selectedItemsData , false , {} )
	newStartLevelLogic:startWithReplay( ReplayMode.kAutoPlayCheck , step )


	if not self.resultData[ tostring( self.currCheckData.levelId ) ] then
		self.resultData[ tostring( self.currCheckData.levelId ) ] = {}
	end

	local fakeData = {}
	fakeData.levelId = self.currCheckData.levelId
	fakeData.currCheckCount = self.currCheckData.currCheckCount
	fakeData.checkResult = false
	fakeData.reason = AutoCheckLevelFinishReason.kCrash

	self.resultData[ tostring( self.currCheckData.levelId ) ][ tonumber(self.currCheckData.currCheckCount) ] = fakeData

	self:saveResultData( self.resultData )


	--setTimeOut( function () self:showProgressInfo() end , 1 )
end

function AutoCheckLevelManager:__doReplayCheck( replayData , finCallback , errorCallback )
	--kReplayConsistencyError
	local currData = self.currCheckData
	--local currData = self.resultData[ tostring( self.currCheckData.levelId ) ][ tonumber(self.currCheckData.currCheckCount) ]
	replayData.addSpeed = currData.addSpeed

	currData.checkResult = false
	currData.reason = AutoCheckLevelFinishReason.kReplay_Crash

	if not self.resultData[ tostring( currData.levelId ) ] then
		self.resultData[ tostring( currData.levelId ) ] = {}
	end

	self.resultData[ tostring( currData.levelId ) ][ tonumber( currData.currCheckCount ) ] = currData
	self.resultData[ tostring( currData.levelId ) ][ tonumber( currData.currCheckCount ) ] = currData

	self:saveResultData( self.resultData )

	local newStartLevelLogic = NewStartLevelLogic:create( nil , replayData.level , replayData.selectedItemsData , false , {} )
	newStartLevelLogic:startWithReplay( ReplayMode.kConsistencyCheck_Step2 , replayData )
end

function AutoCheckLevelManager:allLevelFinished()
	_G.isQAAutoPlayMode = false

	self:clearContext()

	local function showInfo()
		self:tryShowError( self:loadResultData() )
	end
	
	setTimeOut( showInfo , 3 )
end

function AutoCheckLevelManager:nextCheck()

	if not self.currLevelId then
		return
	end

	--printx( 1 , "AutoCheckLevelManager:nextCheck   self.currCheckData =" , table.tostring(self.currCheckData) )

	if self.currCheckData and self.currCheckData.useReplay and self.currCheckData.replay_step1 and self.currCheckData.consistencyCheckReplay then

		self:flushContext()
		self:__doReplayCheck( self.currCheckData.replay_step1 , function () end , function () end )

		return
	end

	if self.currCheckCount >= self.maxCount then

		if self.currLevelId == self.endLevelId then
			self:allLevelFinished()
			return
		else
			self.currLevelId = self:getNextLevelId()
			self.currCheckCount = 1
		end
	else
		self.currCheckCount = self.currCheckCount + 1
	end
	
	self:flushContext()
	self:__doCheck( self:createNextLevelCheckData() , function () end , function () end )
end

function AutoCheckLevelManager:compareReplayResult()
	if self.currCheckData 
		and self.currCheckData.score_step1 
		and self.currCheckData.score_step2 
		and self.currCheckData.score_step1 == self.currCheckData.score_step2 then
		return true
	end
	return false
end

function AutoCheckLevelManager:onCheckFinish( result , reason , costMoves , datas , score )

	if not self.currCheckData then return end

	self.currCheckData.checkResult = result
	self.currCheckData.reason = reason
	self.currCheckData.costMoves = costMoves
	self.currCheckData.datas = datas

	--printx( 1 , "AutoCheckLevelManager:onCheckFinish  self.currCheckData = " , table.tostring(self.currCheckData) )

	local function addReplayAndSave()
		if not result then
			self.currCheckData.replayData = ReplayDataManager:getCurrLevelReplayDataCopyWithoutSectionData() or "none"
			if self.currCheckData.replayData and type(self.currCheckData.replayData) == "table" then
				self.currCheckData.replayData.sectionData = nil
				self.currCheckData.replayData.nextSectionData = nil
			end
		end

		if not self.resultData[ tostring( self.currCheckData.levelId ) ] then
			self.resultData[ tostring( self.currCheckData.levelId ) ] = {}
		end

		self.resultData[ tostring( self.currCheckData.levelId ) ][ tonumber(self.currCheckData.currCheckCount) ] = self.currCheckData

		self:saveResultData( self.resultData )
	end

	if self.currCheckData.useReplay then

		if self.currCheckData.consistencyCheckReplay then

			if result then

				self.currCheckData.consistencyCheckReplay = false
				self.currCheckData.score_step2 = score

				if not self:compareReplayResult() then

					self.currCheckData.checkResult = false
					self.currCheckData.reason = AutoCheckLevelFinishReason.kReplay_ConsistencyError

					self.currCheckData.replayData = self.currCheckData.replay_step1
					self.currCheckData.replay_step1 = nil

					if not self.resultData[ tostring( self.currCheckData.levelId ) ] then
						self.resultData[ tostring( self.currCheckData.levelId ) ] = {}
					end

					self.resultData[ tostring( self.currCheckData.levelId ) ][ tonumber(self.currCheckData.currCheckCount) ] = self.currCheckData

					self:saveResultData( self.resultData )
					self.currCheckData = nil
				else
					self.currCheckData.replay_step1 = nil
					addReplayAndSave()
					self.currCheckData = nil
				end
			else

				if reason == AutoCheckLevelFinishReason.kCrash then
					self.currCheckData.reason = AutoCheckLevelFinishReason.kReplay_Crash
				elseif reason == AutoCheckLevelFinishReason.kLuaCrash then
					self.currCheckData.reason = AutoCheckLevelFinishReason.kReplay_LuaCrash
				end

				addReplayAndSave()
				self.currCheckData = nil

			end

		else

			if result then
				self.currCheckData.replay_step1 = ReplayDataManager:getCurrLevelReplayDataCopyWithoutSectionData() or "none"
				if self.currCheckData.replay_step1 then
					self.currCheckData.replay_step1.sectionData = nil
					self.currCheckData.replay_step1.nextSectionData = nil
				end

				self.currCheckData.score_step1 = score
				self.currCheckData.consistencyCheckReplay = true
			else
				addReplayAndSave()
				self.currCheckData = nil
			end

		end

	else
		addReplayAndSave()
		self.currCheckData = nil
	end
end

function AutoCheckLevelManager:getCurrLevelCheckData()
	return self.currCheckData
end

function AutoCheckLevelManager:loadResultData()
	local localDataText = nil
	
	local hFile, err = io.open( localFilePath , "r")
	if hFile and not err then
		localDataText = hFile:read("*a")
		io.close(hFile)
	end
	local resultData = table.deserialize(localDataText) or {}
	return resultData
end

function AutoCheckLevelManager:saveResultData( resultData )
	local str1 = table.serialize( resultData )
	Localhost:safeWriteStringToFile( str1 , localFilePath)
end

function AutoCheckLevelManager:clearResultData()
	os.remove( localFilePath )
end

function AutoCheckLevelManager:resumeContext()
	local localDataText = nil
	
	local hFile, err = io.open( localCheckContextFilePath , "r")
	if hFile and not err then
		localDataText = hFile:read("*a")
		io.close(hFile)
	end

	if localDataText then
		local contextData = table.deserialize(localDataText) or {}
		
		self.currLevelId = contextData.currLevelId
		self.endLevelId = contextData.endLevelId
		self.currCheckCount = contextData.currCheckCount
		self.maxCount = contextData.maxCount
		self.checkParameter = contextData.checkParameter

		self.resultData = self:loadResultData()

		return self.currLevelId ~= nil
	else
		return false
	end
	
end

function AutoCheckLevelManager:flushContext()
	local context = {}

	context.currLevelId = self.currLevelId
	context.endLevelId = self.endLevelId
	context.currCheckCount = self.currCheckCount
	context.maxCount = self.maxCount
	context.checkParameter = self.checkParameter

	local str1 = table.serialize( context )
	Localhost:safeWriteStringToFile( str1 , localCheckContextFilePath)
end

function AutoCheckLevelManager:clearContext()
	os.remove( localCheckContextFilePath )
end

function AutoCheckLevelManager:addEventListener()
	self.eventDispatcher:addEventListener()
end

function AutoCheckLevelManager:removeEventListener()
	self.eventDispatcher:removeEventListener()
end

function AutoCheckLevelManager:removeEventListenerByName(eventName)
	self.eventDispatcher:removeEventListenerByName(eventName)
end

function AutoCheckLevelManager:removeAllEventListeners()
	self.eventDispatcher:removeAllEventListeners()
end

function AutoCheckLevelManager:dispatchEvent(event)

	self.eventDispatcher:dispatchEvent(event)
end

function AutoCheckLevelManager:showProgressInfo()

	if self.progressInfo then
		self.progressInfo:removeFromParentAndCleanup(true)
		self.progressInfo = nil
	end

	self.progressInfo = AutoPlayCheckProgressPanel:create()

	local strHead = "关卡:"
	if self.currCheckData and self.currCheckData.useReplay and self.currCheckData.replay_step1 and self.currCheckData.consistencyCheckReplay then
		strHead = "录像:"
	end
	self.progressInfo:setLevelType( strHead )
	self.progressInfo:setLevelInfo( self.currLevelId , self.endLevelId )
	self.progressInfo:setLoopInfo( self.currCheckCount , self.maxCount )

	local failedLevels = self:buildFailedLevelData( self.resultData )

	self.progressInfo:setErrorLogInfo( failedLevels )

	local function onShowLog(evt)
		local resultPanel = AutoPlayCheckResultPanel:create()
		resultPanel:popout(function ()
			if not resultPanel or resultPanel.isDisposed then return end
			resultPanel:showLogByData( failedLevels , nil )
		end)
	end

	local function onShutdown(evt)
		self.currCheckData = nil
		self.currLevelId = nil
		self:allLevelFinished()

		if GameBoardLogic:getCurrentLogic() then
			local mainGameLogic = GameBoardLogic:getCurrentLogic()
			if mainGameLogic.PlayUIDelegate and type(mainGameLogic.PlayUIDelegate.endReplay) == "function" then
				mainGameLogic.PlayUIDelegate:endReplay()
			end
		end
		self.progressInfo = nil
	end

	self.progressInfo:addEventListener( AutoPlayCheckProgressPanelEvents.kShowLog , onShowLog )
	self.progressInfo:addEventListener( AutoPlayCheckProgressPanelEvents.kShutdown , onShutdown )

	self.progressInfo:popout()
end

function AutoCheckLevelManager:buildFailedLevelData( resuleData )
	local minLevel = 9999999
	local maxLevel = 0

	for k,v in pairs(resuleData) do
		if tonumber(k) < minLevel then
			minLevel = tonumber(k)
		end

		if tonumber(k) > maxLevel then
			maxLevel = tonumber(k)
		end
	end

	local failedLevels = {}

	for i = minLevel , maxLevel do
		local datas = resuleData[tostring(i)]
		if datas then
			for ia = 1 , #datas do
				local ldata = datas[ia]
				if ldata then --{"checkResult":true,"reason":1,"levelId":124,"costMoves":84,"currCheckCount":1}
					if not ldata.checkResult then
						ldata.loopCount = ia
						table.insert( failedLevels , ldata )
					end
				end
			end
		end
	end

	return failedLevels
end

function AutoCheckLevelManager:tryShowError( resuleData )

	local failedLevels = self:buildFailedLevelData( resuleData )

	local localData = LocalBox:getData( AutoPlayCheckToolbar.localBoxKey ) or AutoPlayCheckToolbar:createDefaultLocalData()
	local checkResultData = {}
	checkResultData.failedLevels = failedLevels
	-- printx( 1 , "AutoCheckLevelManager:tryShowError  AutoPlayCheckToolbar.localBoxKey =" , AutoPlayCheckToolbar.localBoxKey )
	-- printx( 1 , "localData =" , localData )
	-- printx( 1 , "localData.allLogDatas =" , localData.allLogDatas )
	table.insert( localData.allLogDatas , checkResultData )
	localData.currCheckContext.endTime = Localhost:timeInSec()
	LocalBox:setData( AutoPlayCheckToolbar.localBoxKey , localData )

	local resultPanel = AutoPlayCheckResultPanel:create()
	resultPanel:popout(function ()
		if not resultPanel or resultPanel.isDisposed then return end
		resultPanel:onCheckComplete()
	end)
	
	
end

MACRO_DEV_END()