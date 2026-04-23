BattleTrophyGenerateState = class(BaseStableState)

function BattleTrophyGenerateState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function BattleTrophyGenerateState:create(context)
	local v = BattleTrophyGenerateState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function BattleTrophyGenerateState:getNextState()
	return self.context.beforeWaitingState
end

function BattleTrophyGenerateState:checkTransition()
	-- printx(11, "BattleTrophyGenerateState, checkTransition")
	return self.nextState
end

function BattleTrophyGenerateState:getClassName()
	return "BattleTrophyGenerateState"
end

function BattleTrophyGenerateState:onExit()
	-- printx(11, "BattleTrophyGenerateState onExit", debug.traceback())
	BaseStableState.onExit(self)

	self.nextState = nil
end

function BattleTrophyGenerateState:onEnter()
	-- printx(11, "BattleTrophyGenerateState onEnter", debug.traceback())
	BaseStableState.onEnter(self)
	local context = self

	self.nextState = nil

	self:_tryGenerateBattleTrophy()
end

--------------------------------------------------------------------------------------------
--										generate
--------------------------------------------------------------------------------------------
-- 调用时机：每次触发falling临近最末。
-- 如果之后有切换玩家操作，则会在切换玩家后额外多调用一次
function BattleTrophyGenerateState:_tryGenerateBattleTrophy()
	-- printx(11, "~~~~~~~~~~~~~~~~~~ _tryGenerateBattleTrophy ~~~~~~~~~~~~~~~~~~~~")
	
	-- 本次生成检测时机：切换玩家后
	local function isCheckAfterPlayerSwitched(battleData)
		return battleData.switchPlayerGenerateCheck
	end

	-- 本次生成检测时机：消耗步数后。 若马上将切换玩家，则本检测略过，等待之后马上会进行的切换玩家后的检测。
	local function isCheckAfterStepConsumed(battleData, currStep)
		-- 如果当前已没步数，意味着马上要切换玩家了
		if (battleData.lastCheckedTophyGenerateStep < currStep) and (battleData.currPlayerStepLeft > 0) then
			return true
		end
		return false
	end

	local pickedTargets = {}

	local battleData = self.mainLogic.goldenPodBattleData
	local currStep = self.mainLogic.realCostMove -- self.mainLogic.realCostMoveWithoutBackProp

	if battleData and (isCheckAfterPlayerSwitched(battleData) or isCheckAfterStepConsumed(battleData, currStep)) then
		
		local generateAmount = 0

		local trophyMaxBoardAmount = 999
		if battleData.trophyMaxBoardAmount and (battleData.trophyMaxBoardAmount > 0) then
			trophyMaxBoardAmount = battleData.trophyMaxBoardAmount
		end
		local trophyMinBoardAmount = 0
		if battleData.trophyMinBoardAmount and (battleData.trophyMinBoardAmount > 0) then
			trophyMinBoardAmount = battleData.trophyMinBoardAmount
		end

		local currGoldenPodOnBoard = GoldenPodBattleLogic:getGoldenPodAmountOnBoard(self.mainLogic)
		if currGoldenPodOnBoard >= trophyMaxBoardAmount then
			-- 收集物设置有最大数量，当前棋盘达到最大数量，不再生成
		else
			local gapToMaxAmount = trophyMaxBoardAmount - currGoldenPodOnBoard

			-- 按生成规则生成
			if isCheckAfterPlayerSwitched(battleData) then
				battleData.switchPlayerGenerateCheck = false

				local currRound = battleData.currRound
				if battleData.trophyGenerateQueue and battleData.trophyGenerateQueue[currRound] then
					local generateAmountByStepConfig = battleData.trophyGenerateQueue[currRound]
					generateAmount = math.min(generateAmountByStepConfig, gapToMaxAmount)
					-- printx(11, "+ + + generate by step config", generateAmount)
				end
			end

			-- 保底生成
			if generateAmount == 0 then
				if currGoldenPodOnBoard <= 0 then
					generateAmount = 1
					-- printx(11, "+ + + generate by none on board:  1")
				end
			end

			-- 如果生成数量不满足达到棋盘最小数量，则强行加量到最小数量
			if trophyMinBoardAmount > 0 then
				-- printx(11, "~~~ Check Min-amount")
				local expectedNewAmount = currGoldenPodOnBoard + generateAmount
				if expectedNewAmount < trophyMinBoardAmount then
					generateAmount = math.min(trophyMinBoardAmount - currGoldenPodOnBoard, gapToMaxAmount)
					-- printx(11, "+ + + generate num fixed by min-amount:", generateAmount)
				end
			end
		end

		if generateAmount > 0 then
			pickedTargets = GoldenPodBattleLogic:pickGenerateTargets(self.mainLogic, generateAmount)
		end

		battleData.lastCheckedTophyGenerateStep = currStep
	end

    -- printx(11, "_tryGenerateGoldenPod #pickedTargets", #pickedTargets)
    if #pickedTargets > 0 then
    	self:_generateBattleTrophy(pickedTargets)
    else
    	self.nextState = self:getNextState()
	end
end

function BattleTrophyGenerateState:_generateBattleTrophy(pickedTargets, generateNumByBoardMin, generateNumByStep)
	local function actionCallback()
		-- FallingItemLogic:preUpdateHelpMap(self.mainLogic)
    	self.nextState = self:getNextState()
    	self.context:onEnter()		--没有falling，强制调用来轮转state
		-- printx(11, "BattleTrophyGenerateState, action callBack. nextState:", self.nextState)
	end

	local action = GameBoardActionDataSet:createAs(
	        GameActionTargetType.kGameItemAction,
	        GameItemActionType.kItem_battle_trophy_generate, 
	        nil,
	        nil,
	        GamePlayConfig_MaxAction_time
	        )
    action.pickedTargets = pickedTargets
    action.generateNumByBoardMin = generateNumByBoardMin
    action.generateNumByStep = generateNumByStep
    action.completeCallback = actionCallback
    self.mainLogic:addGlobalCoreAction(action)
	self.mainLogic:setNeedCheckFalling()
end

