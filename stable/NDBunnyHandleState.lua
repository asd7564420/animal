NDBunnyHandleState = class(BaseStableState)

function NDBunnyHandleState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function NDBunnyHandleState:create(context)
	local v = NDBunnyHandleState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function NDBunnyHandleState:getNextState()
	return self.context.tileTransferState
end

function NDBunnyHandleState:getClassName()
	return "NDBunnyHandleState"
end

function NDBunnyHandleState:checkTransition()
    return self.nextState
end

function NDBunnyHandleState:onExit()
	BaseStableState.onExit(self)

	self.nextState = nil
end

function NDBunnyHandleState:onEnter()
	BaseStableState.onEnter(self)
	local context = self
    if not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.NDBunnyHandle] then
    	printx(0, '!skip')
		self:changeToNextState()
        return
    end

	self.nextState = nil
	self:_tryMovingBunny()
end

function NDBunnyHandleState:_tryMovingBunny()
	local allBunny = NationalDayBunnyLogic:getAllVisibleNDBunny(self.mainLogic)
	if #allBunny > 0 then
		local moveMap, skillList = NationalDayBunnyLogic:getNDBunnyMoveMap(self.mainLogic)
		self:_MoveNDBunny(moveMap,skillList)
	else
		self:changeToNextState()
	end
	
end

function NDBunnyHandleState:_MoveNDBunny(moveMap,skillList)
	local function actionCallback()
		NationalDayBunnyLogic:refreshAllBlockStateAfterNDBunnyMove(self.mainLogic)
    	self:changeToNextState()
	end

	local action = GameBoardActionDataSet:createAs(
	        GameActionTargetType.kGameItemAction,
	        GameItemActionType.kItem_NDBunny_move, 
	        nil,
	        nil,
	        GamePlayConfig_MaxAction_time
	        )
	action.completeCallback = actionCallback
    action.moveMap = moveMap
    action.skillList = skillList
    self.mainLogic:addDestroyAction(action)
	self.mainLogic:setNeedCheckFalling()
end

function NDBunnyHandleState:changeToNextState()
	self.nextState = self:getNextState()
end