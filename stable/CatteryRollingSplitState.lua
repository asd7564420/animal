CatteryRollingSplitState = class(BaseStableState)

function CatteryRollingSplitState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function CatteryRollingSplitState:create(context)
	local v = CatteryRollingSplitState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function CatteryRollingSplitState:getNextState()
	return self.context.balloonCheckStateInLoop
end

function CatteryRollingSplitState:checkTransition()
	return self.nextState
end

function CatteryRollingSplitState:getClassName()
	return "CatteryRollingSplitState"
end

function CatteryRollingSplitState:onExit()
	BaseStableState.onExit(self)
	self.nextState = nil

	self.allCatteryFinishedRolling = false
	self.allActiveCattery = nil
	self.rollsNumber = 0 --滚过格子数量
end

function CatteryRollingSplitState:onEnter()
	BaseStableState.onEnter(self)
	local context = self
    if not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.catteryRoll] then
    	printx(0, '!skip')
		self:changeToNextState()
        return
    end

	self.nextState = nil

	self.allCatteryFinishedRolling = false	--所有的都滚完了
	self.allActiveCattery = nil	            --所有能滚动的		
	
	self:startCheck()

end

function CatteryRollingSplitState:changeToNextState()
	self.nextState = self:getNextState()
end

--------------- 检测所有可以开滚的
function CatteryRollingSplitState:startCheck()
	self.allActiveCattery = CatteryLogic:getAllActiveOrRollingCattery(self.mainLogic,1)
	if #self.allActiveCattery == 0 then
		self:changeToNextState()
		return
	end
	self:playReadyAnim()
end

--被打击后准备滚动动画
function CatteryRollingSplitState:playReadyAnim()
	local function onAnimationFinished( ... )
		self:checkReadyEnd()
	end

	local currAction = GameBoardActionDataSet:createAs(
			 		GameActionTargetType.kGameItemAction,
			 		GameItemActionType.kItem_Cattery_Ready,
			 		nil,
			 		nil,
			 		GamePlayConfig_MaxAction_time)
	currAction.completeCallback = onAnimationFinished
	currAction.allCattery = self.allActiveCattery
	self.mainLogic:addDestroyAction(currAction)
	self.mainLogic:setNeedCheckFalling()
end

function CatteryRollingSplitState:checkReadyEnd()
	self.context.needLoopCheck = true
	self.rollsNumber = 0
	self.catteryInSplitAmount = 0
	self:startRolling()
end

function CatteryRollingSplitState:startRolling()
	self.catteryInRollingAmount = 0
	local hasRollingCattery = false
	local num = #self.allActiveCattery	
	while num > 0 do
		local cattery = self.allActiveCattery[num]
		local hasReachedEnd, nextR, nextC, posList, chainList = CatteryLogic:getNextGrid(self.mainLogic, cattery)
		self:dealLock(cattery,hasReachedEnd,posList,cattery.catteryDirection)
		self:onCatteryRollingOneGridOrSplit(cattery, nextR, nextC, hasReachedEnd, posList, chainList)
		if hasReachedEnd then
			table.remove(self.allActiveCattery,num)	--如果已经是终点，就没必要继续滚了		
			CatteryLogic:onCatterySplit(self.mainLogic, cattery)
		else
			cattery.catteryState = CatteryState.kRolling
			hasRollingCattery = true		
		end
		num = num - 1
	end
	self.rollsNumber = self.rollsNumber + 1
	if not hasRollingCattery then
		self.allCatteryFinishedRolling = true
	end
end


function CatteryRollingSplitState:checkAllEnd()
	if self.catteryInSplitAmount == 0 and self.allCatteryFinishedRolling then
		FallingItemLogic:preUpdateHelpMap(self.mainLogic)
		self.mainLogic:setNeedCheckFalling()
		self.allActiveCattery = CatteryLogic:getAllActiveOrRollingCattery(self.mainLogic, 1)
		if #self.allActiveCattery == 0 then
			self:changeToNextState()
		else
			self.allCatteryFinishedRolling = false	--所有的都滚完了并分裂
			self.allActiveCattery = nil	            --所有能滚动的		
			self:startCheck()
		end	
	end
end

function CatteryRollingSplitState:onCatteryRollingOneGridOrSplit(cattery, nextR, nextC, hasReachedEnd, posList, chainList)
	local function rollActionCallback()
		self.catteryInRollingAmount = self.catteryInRollingAmount - 1
        self:onOneRollingFinished()
    end

    local function splitActionCallback()
    	self.catteryInSplitAmount = self.catteryInSplitAmount - 1
        self:checkAllEnd()
    end
    local currAction
    if hasReachedEnd then
    	self.catteryInSplitAmount = self.catteryInSplitAmount + 1
		currAction = GameBoardActionDataSet:createAs(
								 		GameActionTargetType.kGameItemAction,
								 		GameItemActionType.kItem_Cattery_Split,
								 		IntCoord:create(cattery.x, cattery.y),
								 		nil,
								 		GamePlayConfig_MaxAction_time)
		currAction.completeCallback = splitActionCallback
	else
		self.catteryInRollingAmount = self.catteryInRollingAmount + 1
		currAction = GameBoardActionDataSet:createAs(
								 		GameActionTargetType.kGameItemAction,
								 		GameItemActionType.kItem_Cattery_Rolling,
								 		IntCoord:create(cattery.x, cattery.y),
								 		nil,
								 		GamePlayConfig_MaxAction_time)
		currAction.completeCallback = rollActionCallback
	end
	currAction.targetCattery = cattery
	currAction.nextR = nextR
	currAction.nextC = nextC
	currAction.posList = posList
	currAction.size = cattery.catterySize
	currAction.direction = cattery.catteryDirection
	currAction.rollsNumber = self.rollsNumber
	currAction.chainList = chainList

	self.mainLogic:addDestroyAction(currAction)
	self.mainLogic:setNeedCheckFalling()
end

function CatteryRollingSplitState:onOneRollingFinished()
	if self.catteryInRollingAmount == 0 then
		self:startRolling()
	end
end


function CatteryRollingSplitState:dealLock(cattery,hasReachedEnd,posList,direction)
	if self.rollsNumber == 0 or hasReachedEnd then
		for i = 1, cattery.catterySize do
			for j = 1, cattery.catterySize do
				local item = self.mainLogic.gameItemMap[cattery.y + i - 1][cattery.x + j - 1]
				if item then
					if hasReachedEnd then
						item:addMeowHitLock()
					else
						item:addMeowLock(cattery.catteryDirection)
					end
					self.mainLogic:checkItemBlock(item.y, item.x) 
				end
			end
		end
	end

	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainLogic)
	if not hasReachedEnd then
		for k,v in ipairs(posList) do
			if v.r >=1 and v.r <= rowAmount and v.c >= 1 and v.c <= colAmount then
				local item = self.mainLogic.gameItemMap[v.r][v.c]
				if item then
					item:addMeowHitLock() --先把要打的地方全都锁住 不然掉落分裂就尴尬了
					self.mainLogic:checkItemBlock(item.y, item.x) 
				end
			end

			local offset = {
				{1,0},
				{0,-1},
				{-1,0},
				{0,1},
			}
			local r = v.r + offset[direction][1]
			local c = v.c + offset[direction][2]
			local item2 = self.mainLogic.gameItemMap[r][c]
			if item2 then
				item2:removeMeowHitLock() --把上轮打过的地方解除
			end
		end
	end
end





