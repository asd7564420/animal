ActivityCollectionItemState = class(BaseStableState)

function ActivityCollectionItemState:create( context )
	-- body
	local v = ActivityCollectionItemState.new()
	v.context = context
	v.mainLogic = context.mainLogic  --gameboardlogic
	v.boardView = v.mainLogic.boardView

	return v
end

function ActivityCollectionItemState:onEnter()
	BaseStableState.onEnter(self)
	self.nextState = nil

    if(not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.ActivityCollectionItem]) then
        printx(0, '!skip')
		self:handleComplete()
        return
    end

	self.hasItemToHandle = false

	self:handleComplete()
end

function ActivityCollectionItemState:handleComplete( ... )
	self.nextState = self:getNextState()
	if self.hasItemToHandle then
		self.mainLogic:setNeedCheckFalling()
	end
end

function ActivityCollectionItemState:onExit()
	BaseStableState.onExit(self)
	self.nextState = nil
	self.hasItemToHandle = false
end

function ActivityCollectionItemState:checkTransition()
	return self.nextState
end

function ActivityCollectionItemState:getClassName()
	return "ActivityCollectionItemState"
end

function ActivityCollectionItemState:getNextState( ... )
	-- body
end


---步数转换
ActivityCollectionItemStateInLoop = class(ActivityCollectionItemState)
function ActivityCollectionItemStateInLoop:create(context)
	local v = ActivityCollectionItemStateInLoop.new()
	v.context = context
	v.mainLogic = context.mainLogic  --gameboardlogic
	v.boardView = v.mainLogic.boardView
	return v
end

function ActivityCollectionItemStateInLoop:getClassName()
	return "ActivityCollectionItemStateInLoop"
end

function ActivityCollectionItemStateInLoop:getNextState()
	return self.context.dripCastingStateInLast_B
end

--bonus转换
ActivityCollectionItemStateInBonus = class(ActivityCollectionItemState)
function ActivityCollectionItemStateInBonus:create(context)
	local v = ActivityCollectionItemStateInBonus.new()
	v.context = context
	v.mainLogic = context.mainLogic  --gameboardlogic
	v.boardView = v.mainLogic.boardView
	return v
end

function ActivityCollectionItemStateInBonus:onEnter()
	BaseStableState.onEnter(self)
	self.nextState = nil

    if(not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID.ActivityCollectionItem]) then
        printx(0, '!skip')
		self:handleComplete()
        return
    end

	self.hasItemToHandle = false


	self:handleComplete()
end

function ActivityCollectionItemStateInBonus:getClassName()
	return "ActivityCollectionItemStateInBonus"
end

function ActivityCollectionItemStateInBonus:getNextState()
	return self.context.bonusStepToLineState
end