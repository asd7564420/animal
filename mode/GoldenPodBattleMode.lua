GoldenPodBattleMode = class(GameMode)

GoldenPodBattleConsts =
{
	kDefaultStepPerPlayer = 2,		--每个玩家每轮默认可操作次数
	-- kMaxRoundAmount = 10,			--游戏总轮数（每个玩家各算一轮）
	-- kPlayerRealmDividingRow = 5,	--本行以上为玩家2收集区域，以下为玩家1收集区域
}

function GoldenPodBattleMode:initModeSpecial(config)
	self.needCheckSwitchPlayerByMove = false
	self.needCheckSwitchPlayerByTime = false

	-- self.mainLogic.timeTotalLimit = config.timeLimit

	if not self.mainLogic.goldenPodBattleData then
		self.mainLogic.goldenPodBattleData = GoldenPodBattleLogic:getInitGoldenPodBattleData(self.mainLogic)
	end
	local battleData = self.mainLogic.goldenPodBattleData

	battleData.maxRound = config.moveLimit
	battleData.currPlayerID = 1
	battleData.currRound = 1
	battleData.currOperID = 0
	battleData.currPlayerStepLeft = GoldenPodBattleConsts.kDefaultStepPerPlayer
	battleData.stepBonusGotten = false
	battleData.trophyCount = {}

	battleData.lastCheckedTophyGenerateStep = 0
	battleData.switchPlayerGenerateCheck = false

	local configBattleData = config.goldenPodBattleConfig
	-- printx(11, "configBattleData?", configBattleData)
	if configBattleData then
		self.mainLogic.timeTotalLimit = configBattleData.time or 25 --toReplace
		battleData.trophyMaxBoardAmount = configBattleData.maxCount
		battleData.trophyMinBoardAmount = configBattleData.minCount
		battleData.stepBonusAvailableForEachStep = configBattleData.stepBonusAvailableForEachStep
		-- battleData.stopTimeFlowInFalling = configBattleData.stopTimeFlowInFalling
		if configBattleData.groupDatas then
			for _, groupData in pairs(configBattleData.groupDatas) do
				if groupData.round and groupData.round > 0 and groupData.count and groupData.count > 0 then
					if not battleData.trophyGenerateQueue then
						battleData.trophyGenerateQueue = {}
					end
					battleData.trophyGenerateQueue[groupData.round] = groupData.count
				end
			end
		end

		-- 暂时，将来考虑断面恢复时需要调整
		battleData.isReverseView = false
		battleData.battleContext = PVPGameManager:getInstance().goldenPodBattleContext
		-- if battleData.battleContext and (battleData.battleContext.selfPlayerID ~= battleData.currPlayerID) then
		if battleData.battleContext and battleData.battleContext.reverseView then
			battleData.isReverseView = true
		end
	end
	-- printx(11, "Battle Data initialized!", table.tostringByKeyOrder(battleData))
end

function GoldenPodBattleMode:onGameInit()
	-- 旋转视角
	local selfInReverseView = GoldenPodBattleLogic:playerInReverseView(self.mainLogic)
	if selfInReverseView then
		GameBoardUtil:boardViewUpsideDown()
	end

	-- 设定初始重力
	local initGravity = GoldenPodBattleLogic:getGravityOnCurrRound(self.mainLogic)
	GoldenPodBattleLogic:flipGravity(self.mainLogic, initGravity)

	-- -- 设定操作限制
	-- if GoldenPodBattleLogic:inSelfActiveTurn(self.mainLogic) then
	-- 	self.mainLogic.inObservingMode = false
	-- else
	-- 	self.mainLogic.inObservingMode = true
	-- end

	printx(11, "============= onGAMEInit: TIME FREEZED!")
	-- 初始要与服务器通信才能确认开始，屏蔽一切操作
	self.timeFreezedByInit = true
	self.mainLogic.inObservingMode = true

	GameMode.onGameInit(self)
end

function GoldenPodBattleMode:update(dt)
	local curScene = Director:sharedDirector():getRunningScene()
	if not curScene then return end
	-- if curScene and not curScene:is(GamePlaySceneUI) then
	-- 	return
	-- end

	local mainLogic = self.mainLogic
	if mainLogic.theGamePlayStatus == GamePlayStatus.kNormal then
		if mainLogic.isGamePaused == false and not self.stopTimeFlow then 
			if mainLogic.timeTotalLimit > 0 then
				local totalTime = mainLogic:getTotalLimitTime()
				if mainLogic.timeTotalUsed >= totalTime then
					return
				end

				-- demo用临时处理，将来不会用update来计算时间
				local currSpeedScale = 1
				if GameSpeedManager then
					currSpeedScale = GameSpeedManager:getCurSpeedScale() or 1
				end
				local dtConsiderSpeed = dt / currSpeedScale
				mainLogic.timeTotalUsed = mainLogic.timeTotalUsed + dtConsiderSpeed
				local timeleft = totalTime - mainLogic.timeTotalUsed
				if timeleft <= 0 then timeleft = 0 end -- 修正-0的结果

				if timeleft <= 0 and mainLogic.flyingAddTime <= 0 then
					-- printx(11, "===== Time's up =====", self.mainLogic.goldenPodBattleData.currRound)
					-- 切换玩家操作
					-- mainLogic.timeTotalUsed = 0
					-- mainLogic.isGamePaused = true
					if self:allRoundsFinished() then
						-- printx(11, "~~~ End of Game ~~~")
						if mainLogic.isWaitingOperation then
							mainLogic:setGamePlayStatus(GamePlayStatus.kEnd)
						end
					else
						-- printx(11, "+++ Change Player!!! +++")
						self.needCheckSwitchPlayerByTime = true
						if mainLogic.isWaitingOperation then
							self:tryCheckEndRound()
						end
					end
				end

				timeleft = math.ceil(timeleft) 
				if not self.lastTimeLeft or self.lastTimeLeft ~= timeleft then
					if mainLogic.PlayUIDelegate then
						mainLogic.PlayUIDelegate:setMoveOrTimeCountCallback(timeleft, false)
					end
					self.lastTimeLeft = timeleft
				end
			end
		end
	end
end

function GoldenPodBattleMode:reachEndCondition()
	local function timeUsedUp()
		if self.mainLogic.timeTotalUsed >= self.mainLogic:getTotalLimitTime() 
			and self.mainLogic.flyingAddTime <= 0 then
			return true
		end
		return false
	end

	local function moveUsedUp()
		if self.mainLogic.goldenPodBattleData and self.mainLogic.goldenPodBattleData.currPlayerStepLeft == 0 then
			return true
		end
		return false
	end

	if self:allRoundsFinished() and ( timeUsedUp() or moveUsedUp() ) then
		-- printx(11, ".................... MODE:reachEndCondition?      TRUE")
		return true
	end
	-- printx(11, ".................... MODE:reachEndCondition?      FALSE")
	return false
end

function GoldenPodBattleMode:reachTarget()
	return self:reachEndCondition() and self:getScoreStarLevel() > 0
end

function GoldenPodBattleMode:allRoundsFinished()
	-- if self.mainLogic and self.mainLogic.battleRound == GoldenPodBattleConsts.kMaxRoundAmount then
	if self.mainLogic and self.mainLogic.goldenPodBattleData 
		and self.mainLogic.goldenPodBattleData.currRound == self.mainLogic.goldenPodBattleData.maxRound then
		return true
	end
	return false
end

function GoldenPodBattleMode:canChangeMoveToStripe()
	return false
end

function GoldenPodBattleMode:saveDataForRevert(saveRevertData)
	local mainLogic = self.mainLogic
	if mainLogic.goldenPodBattleData then
		saveRevertData.goldenPodBattleData = table.clone(mainLogic.goldenPodBattleData)
	end

	GameMode.saveDataForRevert(self, saveRevertData)
end

function GoldenPodBattleMode:revertDataFromBackProp()
	local mainLogic = self.mainLogic
	mainLogic.goldenPodBattleData = mainLogic.saveRevertData.goldenPodBattleData

	GameMode.revertDataFromBackProp(self)
end

function GoldenPodBattleMode:revertUIFromBackProp()
	local mainLogic = self.mainLogic
	if mainLogic.PlayUIDelegate then
		mainLogic.PlayUIDelegate.scoreProgressBar:revertScoreTo(mainLogic.totalScore)
	end
end

function GoldenPodBattleMode:afterFail()
	--FUUUManager:update(self)
	-- GameExtandPlayLogic:showAddTimePanel(self)
end

function GoldenPodBattleMode:addTime(addTime)
	local mainLogic = self.mainLogic
	mainLogic:addExtraTime(addTime)
	if mainLogic.PlayUIDelegate then
		local timeleft = mainLogic:getTotalLimitTime() - mainLogic.timeTotalUsed
		if timeleft <= 0 then timeleft = 0 end
		mainLogic.PlayUIDelegate:setMoveOrTimeCountCallback(math.ceil(timeleft), false)
	end
end

function GoldenPodBattleMode:onModeStartWaitingState()
	self.inWaitingState = true

	printx(11, "============= ENTER waiting state!")
	-- 初始化完毕，告知服务器
	if self.timeFreezedByInit then
		GoldenPodBattleLogic:sendReadyToStartBattle(self.mainLogic)
	else
		GoldenPodBattleLogic:checkSendSnapshot(self.mainLogic)
		
		local inSyncProcedure = GoldenPodBattleLogic:checkSyncDataIfNeeded()
		if not inSyncProcedure then
			local dealWithPendingOperation = GoldenPodBattleLogic:checkOperationList()
			if not dealWithPendingOperation then
				self:tryCheckEndRound()
			end
		end
	end

	self:updateTimeFlowStatus()
end

function GoldenPodBattleMode:onModeStopWaitingState()
	self.inWaitingState = false
	self:updateTimeFlowStatus()
end

function GoldenPodBattleMode:updateTimeFlowStatus()
	printx(11, "MODE:updateTimeFlowStatus", self.inWaitingState, self.timeFreezedByInit)
	if self.inWaitingState and not self.timeFreezedByInit then
		self.stopTimeFlow = false
	else
		self.stopTimeFlow = true
	end
end

function GoldenPodBattleMode:useMove()
	local battleData = self.mainLogic.goldenPodBattleData
	if not battleData then return end
	battleData.currPlayerStepLeft = math.max(battleData.currPlayerStepLeft - 1, 0)
	GoldenPodBattleLogic:updateLeftStepDisplay(self.mainLogic)

	if battleData.stepBonusAvailableForEachStep then
		battleData.stepBonusGotten = false
	end

	if battleData.currPlayerStepLeft == 0 then
		-- printx(11, "+++ Moves all used... Change Player!!! +++")
		self.needCheckSwitchPlayerByMove = true
	end
end

-- 检测结束本回合，时机：进入WaitingState or WaitingState中时间到了
-- 攻守双方都会检测
function GoldenPodBattleMode:tryCheckEndRound()
	local inSelfTurn = GoldenPodBattleLogic:inSelfActiveTurn(self.mainLogic)
	printx(11, "-------------- tryCheckEndRound ------------------------, selfTurn, time, move:", inSelfTurn, self.needCheckSwitchPlayerByTime, self.needCheckSwitchPlayerByMove)
	
	if not (self.needCheckSwitchPlayerByTime or self.needCheckSwitchPlayerByMove) then return end
	if not self.mainLogic then return end
	self.needCheckSwitchPlayerByTime = false
	self.needCheckSwitchPlayerByMove = false

	-- 屏蔽操作，先向服务器发送切换玩家请求），服务器确认后才正式切换玩家
	self.mainLogic.inObservingMode = true
	GoldenPodBattleLogic:checkSendEndRound(self.mainLogic)

	-- if inSelfTurn then
	-- 	if not (self.needCheckSwitchPlayerByTime or self.needCheckSwitchPlayerByMove) then return end
	-- 	if not self.mainLogic then return end
	-- 	self.needCheckSwitchPlayerByTime = false
	-- 	self.needCheckSwitchPlayerByMove = false

	-- 	-- 屏蔽操作，先向服务器发送切换玩家请求），服务器确认后才正式切换玩家
	-- 	self.mainLogic.inObservingMode = true
	-- 	GoldenPodBattleLogic:checkSendSwtichPlayer(self.mainLogic)
	-- else
	-- 	-- 非己方回合，若有挂起的（如：收到对方回合结束消息时，己方仍在掉落）切换要求，执行之
	-- 	if self.pendingNextPlayerID then
	-- 		GoldenPodBattleLogic:switchPlayer(self.mainLogic, self.pendingNextPlayerID)
	-- 		self.pendingNextPlayerID = nil
	-- 	end
	-- end
end

------------------------ pod ---------------------------
function GoldenPodBattleMode:checkDropDownCollect(r, c)
	return self:tryCollectIngredient(r, c)
end

function GoldenPodBattleMode:tryCollectIngredient(r,c)
	local mainLogic = self.mainLogic
	local board1 = mainLogic.boardmap[r][c]
	local result = false
	if board1.isCollector == true and not board1:hasChainInDirection(ChainDirConfig.kDown) and board1.colorFilterBLevel == 0 then
		local item1 = mainLogic.gameItemMap[r][c]
		if item1.ItemType == GameItemType.kIngredient and item1:isVisibleAndFree() then	
			result = true
			-----1.得分				
			item1:AddItemStatus(GameItemStatusType.kDestroy)
			item1.isCollectIngredient = true --爆炸会到导致重复收集
			local addScore = GamePlayConfigScore.DropDownIngredient
			mainLogic:addScoreToTotal(r, c, addScore)

			-----2.收集动画
			local CollectAction = GameBoardActionDataSet:createAs(
				GameActionTargetType.kGameItemAction,
				GameItemActionType.kItem_CollectIngredient,
				IntCoord:create(r,c),
				nil,
			GamePlayConfig_DropDown_Ingredient_DroppingCD)
			CollectAction.addInfo = "Pass"
			CollectAction.itemShowType = item1.showType
			mainLogic:addDestroyAction(CollectAction)
			mainLogic.toBeCollected = mainLogic.toBeCollected + 1

			GoldenPodBattleLogic:addPlayerTrophyAmount(mainLogic, r, c)
		end
	end
	return result
end
