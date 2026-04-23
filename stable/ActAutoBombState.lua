ActAutoBombState = class(BaseStableState)


function ActAutoBombState:create( context )
    local v = ActAutoBombState.new()
    v.context = context
    v.mainLogic = context.mainLogic  --gameboardlogic
    v.boardView = v.mainLogic.boardView
    return v
end

function ActAutoBombState:update( ... )
    -- body
end

function ActAutoBombState:onEnter()
    if self:tryCollect() <= 0 then
        self:handleComplete()
    end
end

function ActAutoBombState:getClassName()
    return "ActAutoBombState"
end

function ActAutoBombState:handleComplete(hadItemProcessed)
    self.nextState = self:getNextState()
    if hadItemProcessed then
        self.mainLogic:setNeedCheckFalling()
        self.context.needLoopCheck = true
    end
end

function ActAutoBombState:getNextState( ... )
    -- return self.context.checkNeedLoopState
    return self.context.moveBonusHarvestStateBeforeChangeBoard
end

function ActAutoBombState:onExit()
    self.nextState = nil
end

function ActAutoBombState:checkTransition()
    return self.nextState
end

function ActAutoBombState:tryCollect()
    local function tryUseBuff()
        return 0
    end

    -- 雪怪技能 道具
    -- if GameInitBuffLogic:isSnowMonsterBuff() .hadAutoSnowMonsterBuff then
    if self.mainLogic.hadAutoSnowMonsterBuff then
        local value = tryUseBuff()
        if value>0 then
            GameInitBuffLogic:setSnowMonsterBuff(false)
        end
        return value
    end
    return 0
end

