-- 有些活动中，根据过关/切屏时的剩余步数，会有一些活动收集物的奖励
-- 不会改变棋盘
MoveBonusHarvestState = class(BaseStableState)

function MoveBonusHarvestState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function MoveBonusHarvestState:create(context)
	local v = MoveBonusHarvestState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function MoveBonusHarvestState:onEnter()
	BaseStableState.onEnter(self)
	self.nextState = nil
	self.needCheckingContinuously = false

	if self:hasMoveBonusToDisplayNow() then
		self:checkBouns()
	else
		self.nextState = self:getNextState()
	end
end

function MoveBonusHarvestState:checkBouns( ... )

	local function onHarvestActionEnded()
		self.mainLogic.PlayUIDelegate:setPauseBtnEnable(true)
		self:onHarvestEnded()
	end
	
	if LevelType:isAngryBirdLevel(self.mainLogic.level) then
		self.mainLogic.PlayUIDelegate:setPauseBtnEnable(false)
		AngryBirdLogic:handleBoardState(self.mainLogic,self,onHarvestActionEnded) 
	end
end

function MoveBonusHarvestState:hasMoveBonusToDisplayNow()
	return self:hasMoveBonus()
end

-- 调用时机：将要滚屏前 & BonusTime中，即当前屏打关已结束时
function MoveBonusHarvestState:hasMoveBonus()
	if not self.mainLogic.moveBonusHarvested then
		if LevelType:isAngryBirdLevel(self.mainLogic.level) then
			-- 未获得时也有展示动画
			-- local moveBonus = AngryBirdLogic:getCurrRewardsForMoveBonus()
			-- if moveBonus then
				return true
			-- end
		end
	end
	return false
end

function MoveBonusHarvestState:onHarvestEnded()
	self.nextState = self:getNextState()
	self.context:onEnter()
end

function MoveBonusHarvestState:onExit()
	BaseStableState.onExit(self)
	self.nextState = nil
end

function MoveBonusHarvestState:update(dt)
	-- printx(15," MoveBonusHarvestState:update")
    if self.needCheckingContinuously then
    	self:checkBouns()
    end
end

function MoveBonusHarvestState:checkTransition()
	return self.nextState
end

function MoveBonusHarvestState:getClassName( ... )
	return "MoveBonusHarvestState"  -- to be overrided
end

-- function MoveBonusHarvestState:getNextState()
--     return nil
-- end

---------------------------------  如果将要切屏，切屏前展示 -----------------------------------------
MoveBonusHarvestStateBeforeChangeBoard = class(MoveBonusHarvestState)
function MoveBonusHarvestStateBeforeChangeBoard:create(context)
    local v = MoveBonusHarvestStateBeforeChangeBoard.new()
    v.context = context
    v.mainLogic = context.mainLogic
    v.boardView = v.mainLogic.boardView
    v.inBonus = false
    return v
end

function MoveBonusHarvestStateBeforeChangeBoard:getClassName()
    return "MoveBonusHarvestStateBeforeChangeBoard"
end

function MoveBonusHarvestStateBeforeChangeBoard:getNextState()
    return self.context.changeBoardScrollState  --请不要改这里呀。结算希望在滚屏前的最后一刻来处理。
end

function MoveBonusHarvestStateBeforeChangeBoard:hasMoveBonusToDisplayNow()
	-- 若有滚屏，滚屏前结算当前屏关卡的步数奖励
	if self.mainLogic.nextBoardLevelID and self.mainLogic.nextBoardLevelID > 0 then
		if self:hasMoveBonus() then
			return true
		end
	end
	return false
end

------------------------ 没有切屏，BonusTime中展示（因为剩余步数不为0的情况下才可能会有步数bonus） --------------------------
MoveBonusHarvestStateInBonus = class(MoveBonusHarvestState)
function MoveBonusHarvestStateInBonus:create(context)
    local v = MoveBonusHarvestStateInBonus.new()
    v.context = context
    v.mainLogic = context.mainLogic
    v.boardView = v.mainLogic.boardView
    v.inBonus = false
    return v
end

function MoveBonusHarvestStateInBonus:getClassName()
    return "MoveBonusHarvestStateInBonus"
end

function MoveBonusHarvestStateInBonus:getNextState()
    return self.context.bonusEffectState
end
