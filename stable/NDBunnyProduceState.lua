NDBunnyProduceState = class(BaseStableState)

function NDBunnyProduceState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function NDBunnyProduceState:create(context)
	local v = NDBunnyProduceState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function NDBunnyProduceState:getNextState()
	return self.context.blocker199State
end

function NDBunnyProduceState:getClassName()
	return "NDBunnyProduceState"
end

function NDBunnyProduceState:checkTransition()
    return self.nextState
end

function NDBunnyProduceState:onExit()
	BaseStableState.onExit(self)

	self.nextState = nil
end

function NDBunnyProduceState:onEnter()
	BaseStableState.onEnter(self)
	local context = self
    if not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.NDBunnyProduce] then
    	printx(0, '!skip')
		self:changeToNextState()
        return
    end

	self.nextState = nil
	self:_tryProduceNDBunny()

end


function NDBunnyProduceState:_tryProduceNDBunny()
	local finalStepList = {}
	local finalMinList = {}
	local allNDBunnyProducer = NationalDayBunnyLogic:getAllNDBunnyProducer(self.mainLogic)
	if #allNDBunnyProducer > 0 then
		finalStepList, finalMinList = NationalDayBunnyLogic:getProduceBunnyList(self.mainLogic)
	end

    if #finalStepList > 0 or #finalMinList > 0 then
    	self:_produceNDBunny(finalStepList, finalMinList)
    else
    	self:changeToNextState()
	end
end

function NDBunnyProduceState:_produceNDBunny(finalStepList, finalMinList)
	local function actionCallback()
    	self:changeToNextState()
	end

	local action = GameBoardActionDataSet:createAs(
	        GameActionTargetType.kGameItemAction,
	        GameItemActionType.kItem_NDBunny_produce, 
	        nil,
	        nil,
	        GamePlayConfig_MaxAction_time
	        )
    action.finalStepList = finalStepList
    action.finalMinList = finalMinList
    action.completeCallback = actionCallback
    self.mainLogic:addDestroyAction(action)
	self.mainLogic:setNeedCheckFalling()
end

function NDBunnyProduceState:changeToNextState()
	self.nextState = self:getNextState()
end