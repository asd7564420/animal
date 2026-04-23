ChangeBoardScrollState = class(BaseStableState)

function ChangeBoardScrollState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function ChangeBoardScrollState:create(context)
	local v = ChangeBoardScrollState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function ChangeBoardScrollState:onEnter()
	BaseStableState.onEnter(self)
	self.nextState = nil
	self.needCheckingContinuously = false

	local needScroll = self:checkChangeBoard()

	if not needScroll then
		self.nextState = self:getNextState()
	end
end

function ChangeBoardScrollState:checkChangeBoard()
	-- printx(1, "ChangeBoardScrollState ~~~ checkChangeBoard")
	local function onScrollComplete()
		-- printx(1, "ChangeBoardScrollState ~~~ ~~~ ~~~ onScrollComplete")
		self.context.needLoopCheck = true
		self.nextState = self:getNextState()
		self.mainLogic:setNeedCheckFalling()

		if self.mainLogic.theGamePlayType == GameModeTypeId.TRAVEL_MODE_ID then
			TravelLogic:playHeroDebutAnimation(self.mainLogic)
			ActCollectionLogic:refreshProgressBarPosition()

			if self.mainLogic.PlayUIDelegate.topArea.updateScoreProgressBar then
				self.mainLogic.PlayUIDelegate.topArea:updateScoreProgressBar()
			end
		end

		if self.mainLogic.theGamePlayType == GameModeTypeId.WEEKLY_RACE_2020_MODE_ID then
			self.mainLogic.PlayUIDelegate:afterDigGroudScroll(self.mainLogic)
		end

		if self.mainLogic.theGamePlayType == GameModeTypeId.ANGRY_BIRD_MODE_ID then
			AngryBirdLogic:refreshUIafterChangeBoard(self.mainLogic)
		end
	end

	local needScroll = false
	if self.mainLogic.theGamePlayType == GameModeTypeId.TRAVEL_MODE_ID
		or self.mainLogic.theGamePlayType == GameModeTypeId.WEEKLY_RACE_2020_MODE_ID
		or self.mainLogic.theGamePlayType == GameModeTypeId.ANGRY_BIRD_MODE_ID
		then
		-- printx(1, "------------ Check change board. nextLevelID:", self.mainLogic.nextBoardLevelID)
		--[[
		if self.mainLogic:isReplayMode() and self.mainLogic.replayMode == ReplayMode.kMcts and _G.useNewAIAutoCheck and not _G.AIAutoCheckReplayCheck then
			-- self.mainLogic:setGamePlayStatus( GamePlayStatus.kWin )
			local function onAIGamePlayManagerEndLevel()
				local function quitScene()
					local function didQuitGamePlayScene()
						ReplayDataManager:clearMctsLogs()
						AIGamePlayManager:startLevel()
					end
					self.mainLogic.PlayUIDelegate:forceQuitPlay(didQuitGamePlayScene)
				end

				setTimeOut( quitScene , 0.1)
			end

			AIGamePlayManager:endLevel( true , nil , self.mainLogic.totalScore , 1 , nil , onAIGamePlayManagerEndLevel )
			return false
		end
		]]

		if self.mainLogic.nextBoardLevelID and self.mainLogic.nextBoardLevelID > 0 then
			needScroll = true
			if self:_hasNoActionInRunning() then
				-- printx(1, "Okay, go changing!")
				self.needCheckingContinuously = false

				if self.mainLogic.theGamePlayType == GameModeTypeId.WEEKLY_RACE_2020_MODE_ID then
					WeeklyRace2020Logic:dcWeeklyRace2020(self.mainLogic, "20weeklyrace_map_end", 1, true)
				

				elseif self.mainLogic.theGamePlayType == GameModeTypeId.ANGRY_BIRD_MODE_ID then
					AngryBird2020Manager.getInstance():dcBeforeChangeBoard(self.mainLogic)
					if self.mainLogic.PlayUIDelegate.topArea.baojiState == 1 then
						self.mainLogic.PlayUIDelegate.topArea.baojiState = -1
					end
					self.mainLogic.PlayUIDelegate.topArea.closeDie = false
					self.mainLogic.needResetPropUseTimes = true
					-- printx(15,"切屏！！！！！！！！！！！！！！！！！！！！！！",self.mainLogic.PlayUIDelegate.topArea.baojiState)
				end

				local nextLevelID = self.mainLogic.nextBoardLevelID
				self.mainLogic.nextBoardLevelID = nil --删除滚屏标记
				self.mainLogic:getInstance().PlayUIDelegate:inLevelChangeBoard(nextLevelID, onScrollComplete)
			else
				self.needCheckingContinuously = true
			end
		end
	end
	return needScroll
end

function ChangeBoardScrollState:update(dt)
    if self.needCheckingContinuously then
    	self:checkChangeBoard()
    end
end

-- 转场时，须确保没有任何其他的action（能剩下的只有 gameAction 和 globalCoreAction）在运行
function ChangeBoardScrollState:_hasNoActionInRunning()
	-- printx(11, "check has action in running??", self.mainLogic.hasGlobalCoreAction, self.mainLogic:getGlobalCoreActionListCount(), self.mainLogic:getActionListCount())
	-- if not self.mainLogic.hasGlobalCoreAction and self.mainLogic:getActionListCount() == 0 then
	if self.mainLogic:getGlobalCoreActionListCount() == 0 and self.mainLogic:getActionListCount() == 0 then
		return true
	end
	return false
end

function ChangeBoardScrollState:getNextState()
	return self.context.checkNeedLoopState --请不要改这里。切屏希望在loop的最后来处理。
end

function ChangeBoardScrollState:onExit()
	-- printx(11, "=== ChangeBoardScrollState Exit ===", debug.traceback())
	BaseStableState.onExit(self)
	self.nextState = nil
	self.needCheckingContinuously = false
end

function ChangeBoardScrollState:checkTransition()
	return self.nextState
end

function ChangeBoardScrollState:getClassName()
	return "ChangeBoardScrollState"
end
