GyroGenerateState = class(BaseStableState)

function GyroGenerateState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function GyroGenerateState:create(context)
	local v = GyroGenerateState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function GyroGenerateState:getNextState()
	return self.context.GyroCreterRemoveState
end

function GyroGenerateState:checkTransition()
	-- printx(11, "GyroGenerateState, checkTransition")
	return self.nextState
end

function GyroGenerateState:getClassName()
	return "GyroGenerateState"
end

function GyroGenerateState:onExit()
	-- printx(11, "GyroGenerateState onExit")
	BaseStableState.onExit(self)

	self.nextState = nil
end

function GyroGenerateState:onEnter()
	BaseStableState.onEnter(self)
	local context = self

    if not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.gyroGenerate] then
    	printx(0, '!skip')
		self.nextState = self:getNextState()
        return
    end

	self.nextState = nil
	
	if self.mainLogic.gameDataVersion and self.mainLogic.gameDataVersion >= 1 then
		self:tryGenerateGyroNew()
	else
		self:tryGenerateGyro()
	end
end

--------------------------------------------------------------------------------------------
--										出去走走
--------------------------------------------------------------------------------------------
function GyroGenerateState:tryGenerateGyro()
	local pickedTargets = {}
	local finalgenerateList = GyroLogic:getGenerateGyroAmountIfNeeded(self.mainLogic)
	-- printx(11, "tryGeneratePacman generateNumByBoardMin, generateNumByStep", generateNumByBoardMin, generateNumByStep)
	local sumGenerateAmount = 0

	for i,v in ipairs(finalgenerateList) do
		sumGenerateAmount = sumGenerateAmount + v.generateNumByBoardMin + v.generateNumByStep
	end

    if sumGenerateAmount > 0 then
    	pickedTargets = GyroLogic:pickGenerateTargets(self.mainLogic, finalgenerateList)
    end

    if #pickedTargets > 0 then
		self.context.needLoopCheck = true	--
    	self:generateGyro(pickedTargets, finalgenerateList)
    else
    	self.nextState = self:getNextState()
	end
end

function GyroGenerateState:generateGyro(pickedTargets, finalgenerateList )
	local function actionCallback()
		FallingItemLogic:preUpdateHelpMap(self.mainLogic)
		-- GyroLogic:updateCreaterProgressDisplay(self.mainLogic)
    	self.nextState = self:getNextState()
		-- printx(11, "GyroGenerateState, action callBack. nextState:", self.nextState)
	end

	local action = GameBoardActionDataSet:createAs(
	        GameActionTargetType.kGameItemAction,
	        GameItemActionType.kItem_gyroCreater_generate, 
	        nil,
	        nil,
	        GamePlayConfig_MaxAction_time
	        )
    action.pickedTargets = pickedTargets
    action.finalgenerateList = table.clone(finalgenerateList)
    action.completeCallback = actionCallback
    self.mainLogic:addDestroyAction(action)
	self.mainLogic:setNeedCheckFalling()
end

function GyroGenerateState:tryGenerateGyroNew()
	local pickedTargets, spareTargets = GyroLogic:getGenerateGyroList(self.mainLogic)
    if #pickedTargets > 0 or #spareTargets > 0 then
    	--printx(14,"需要循环一次，",#pickedTargets,#spareTargets)
		self.context.needLoopCheck = true
    	self:generateGyroNew(pickedTargets,spareTargets)
    else
    	self.nextState = self:getNextState()
	end
end

function GyroGenerateState:generateGyroNew(pickedTargets,spareTargets)
	local function actionCallback()
		FallingItemLogic:preUpdateHelpMap(self.mainLogic)
    	self.nextState = self:getNextState()
	end

	local action = GameBoardActionDataSet:createAs(
	        GameActionTargetType.kGameItemAction,
	        GameItemActionType.kItem_gyroCreater_generate, 
	        nil,
	        nil,
	        GamePlayConfig_MaxAction_time
	        )
	action.newRule = true
    action.pickedTargets = pickedTargets
    action.spareTargets = spareTargets
    action.completeCallback = actionCallback
    self.mainLogic:addDestroyAction(action)
	self.mainLogic:setNeedCheckFalling()
end