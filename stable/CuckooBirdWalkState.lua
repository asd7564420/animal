CuckooBirdWalkState = class(BaseStableState)

function CuckooBirdWalkState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function CuckooBirdWalkState:create(context)
	local v = CuckooBirdWalkState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function CuckooBirdWalkState:check()
	if self.mainLogic and self.mainLogic:getGamePlayType() ~= GameModeTypeId.DESTINATION_MODE_ID then
		return 0
	end

	-- 因为需要等待某些被攻击的对象等到自己的state处理后续逻辑，所以暂时略过行进检测
	if self.mainLogic.skipCuckooStateType and self.mainLogic.skipCuckooStateType > 0 then
		return 0
	end

	local birdCanStartMoving = false
	if self.mainLogic.cuckooEnergy and self.mainLogic.cuckooEnergy > 0 then
		if CuckooLogic:checkCuckooBirdHasReachedEndPos(self.mainLogic) then
			self:onReachEnd(true)
		else
			birdCanStartMoving = true
		end
	end

	if birdCanStartMoving then
		-- printx( 11, "====================== ~~~ =====================")
		-- printx( 11, "====================== ~~~ =====================")
		-- printx( 11, "====================== ~~~ =====================")
		-- printx( 11, "---->>>> CuckooBirdWalkState enter: check")
		self.maxAttackTimes = nil
		self.clearEnergyAfterAttack = false
		return self:_startCheckOneAction(true)
	else
		return 0
	end
end

function CuckooBirdWalkState:_exitWalkingState()
	-- printx( 11, "---->>>> CuckooBirdWalkState exit")
	-- printx( 11, "______________________ xxx _____________________")
	-- printx( 11, "______________________ xxx _____________________")
	-- printx( 11, "______________________ xxx _____________________")
	self.maxAttackTimes = nil
	self.clearEnergyAfterAttack = false

	CuckooLogic:refreshAllBlockStateAfterCuckooBirdWalk(self.mainLogic)
	FallingItemLogic:preUpdateHelpMap(self.mainLogic)
	self.mainLogic:setNeedCheckFalling()
end

-- 检测一次行动，移动或攻击
function CuckooBirdWalkState:_startCheckOneAction(initCheck)
	-- printx(11, "CuckooBirdWalkState, _startCheckOneAction")
	local cuckooBird = CuckooLogic:getCuckooOnBoard(self.mainLogic)
	if not cuckooBird then
		CuckooLogic:clearCuckooEnergy()
		return 0
	end

	local isWalkAction = false
	local isAttackAction = false
	local isAttackChain = false
	-- local nextRow, nextCol
	local nextItem
	if cuckooBird and cuckooBird:isVisibleAndFree() and self.mainLogic.cuckooEnergy and self.mainLogic.cuckooEnergy > 0 then 
		local interactType, nextItemData, attackTimes, clearEnergyAfterAttack, blockType = CuckooLogic:checkNextGridInteractType(cuckooBird)
		if not interactType 
			or interactType == CuckooBirdInteractType.kNone
			or (interactType == CuckooBirdInteractType.kAttackBlocker and attackTimes == 0) 
			then
			-- 前路无法交互，清空能量
			CuckooLogic:clearCuckooEnergy()
		else
			if interactType == CuckooBirdInteractType.kWalk then
				isWalkAction = true
			elseif interactType == CuckooBirdInteractType.kAttackBlocker or interactType == CuckooBirdInteractType.kAttackChain then
				if not self.maxAttackTimes then
					self.maxAttackTimes = attackTimes
				end
				isAttackAction = true
				if interactType == CuckooBirdInteractType.kAttackChain then
					isAttackChain = true
				end
				if clearEnergyAfterAttack then
					-- 攻击对象是无法被消除的障碍，全部攻击完毕后清除能量
					self.clearEnergyAfterAttack = true
				end
				if blockType and blockType > 0 then
					self.mainLogic.skipCuckooStateType = blockType
				end
			end
			nextItem = nextItemData
		end
	end
	-- printx(11, "=== isWalkAction, isAttackAction, maxAttackTimes", isWalkAction, isAttackAction, self.maxAttackTimes)

	if (isWalkAction or isAttackAction) and nextItem then
		if isWalkAction then
			self:_onCuckooBirdStartWalking(cuckooBird, nextItem)
		elseif isAttackAction then
			self:_onCuckooBirdStartAttacking(cuckooBird, nextItem, isAttackChain)
		end

		if initCheck then
			return 1
		end
	else
		if initCheck then
			return 0
		else
			self:_exitWalkingState()
		end
	end
end

function CuckooBirdWalkState:onReachEnd(skipExitState)
	-- printx(11, "~~~~~~ CuckooBirdWalkState:onReachEnd", self.mainLogic.level, self.mainLogic.PlayUIDelegate.levelId, debug.traceback())
	CuckooLogic:clearCuckooEnergy()
	CuckooLogic:onCuckooBirdReachClock(self.mainLogic)

	if not skipExitState then
		self:_exitWalkingState()
	end
end

function CuckooBirdWalkState:_onCuckooBirdStartWalking(cuckooBird, nextItem)
	local lastItemPos = ccp(cuckooBird.x, cuckooBird.y)

	local function actionCallback()
		self:_onOneActionEnded(lastItemPos)
	end

	local heroWalkAction = GameBoardActionDataSet:createAs(
		GameActionTargetType.kGameItemAction,
		GameItemActionType.kItem_Cuckoo_Bird_Walk,
		IntCoord:create(cuckooBird.x, cuckooBird.y),
		IntCoord:create(nextItem.x, nextItem.y),
		GamePlayConfig_MaxAction_time)
	-- printx(11, "cuckooBird walk. cuckooBird, target:".."("..cuckooBird.y..","..cuckooBird.x..") , ("..nextItem.y..","..nextItem.x..")")
	heroWalkAction.cuckooBird = cuckooBird
	heroWalkAction.nextItem = nextItem
	heroWalkAction.completeCallback = actionCallback
	
	self.mainLogic:addDestroyAction(heroWalkAction)
	self.mainLogic:setNeedCheckFalling()
	if self.mainLogic.currMapTravelStep then
		self.mainLogic.currMapTravelStep = self.mainLogic.currMapTravelStep + 1
	end
end

function CuckooBirdWalkState:_onCuckooBirdStartAttacking(cuckooBird, nextItem, isAttackChain)
	local function actionCallback()
		self:_onOneActionEnded()
	end

	local heroAttackAction = GameBoardActionDataSet:createAs(
		GameActionTargetType.kGameItemAction,
		GameItemActionType.kItem_Cuckoo_Bird_Attack,
		IntCoord:create(cuckooBird.x, cuckooBird.y),
		IntCoord:create(nextItem.x, nextItem.y),
		GamePlayConfig_MaxAction_time)
	-- printx(11, "cuckooBird attack. cuckooBird, target:".."("..cuckooBird.y..","..cuckooBird.x..") , ("..nextItem.y..","..nextItem.x..")")
	heroAttackAction.cuckooBird = cuckooBird
	heroAttackAction.nextItem = nextItem
	heroAttackAction.isAttackChain = isAttackChain
	heroAttackAction.completeCallback = actionCallback
	
	self.mainLogic:addDestroyAction(heroAttackAction)
	self.mainLogic:setNeedCheckFalling()
end

function CuckooBirdWalkState:_onOneActionEnded(lastItemPos)
	CuckooLogic:consumeCuckooEnergy()
	if self.maxAttackTimes then
		self.maxAttackTimes = self.maxAttackTimes - 1
		if self.maxAttackTimes <= 0 and self.clearEnergyAfterAttack then
			CuckooLogic:clearCuckooEnergy()
		end
	end
	-- printx(11, "=== _onOneActionEnded, curr Energy, maxAttackTimes:", self.mainLogic.cuckooEnergy, self.maxAttackTimes)
	-- printx(11, "=== _onOneActionEnded, currMapTravelRouteLength, currMapTravelStep:", self.mainLogic.currMapTravelRouteLength, self.mainLogic.currMapTravelStep)
	
	if CuckooLogic:checkCuckooBirdHasReachedEndPos(self.mainLogic) then
		self:onReachEnd()
	else
		if self.mainLogic.cuckooEnergy and self.mainLogic.cuckooEnergy > 0 then
			--本轮结束，开始下一轮
			if not self.maxAttackTimes then
				self:_startCheckOneAction()
			else
				if self.maxAttackTimes > 0 then
					self:_startCheckOneAction()
				else
					-- 前物会因攻击被销毁，退出行进，执行掉落
					-- printx(11, "...Attack over Exit.")
					self:_exitWalkingState()
				end
			end
		else
			-- printx(11, "...No Energy Exit.")
			self:_exitWalkingState()
		end
	end
end
