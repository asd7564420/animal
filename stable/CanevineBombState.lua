CanevineBombState = class(BaseStableState)


function CanevineBombState:create( context )
    local v = CanevineBombState.new()
    v.context = context
    v.mainLogic = context.mainLogic  --gameboardlogic
    v.boardView = v.mainLogic.boardView
    return v
end

function CanevineBombState:update( ... )
    -- body
end

function CanevineBombState:onEnter()
    printx( -1 , "---->>>> CanevineBombState enter")

    if self:tryBomb() <= 0 then
        self:handleComplete()
    end

end

function CanevineBombState:getClassName()
    return "CanevineBombState"
end

function CanevineBombState:handleComplete(hadItemProcessed)
    self.nextState = self:getNextState()

    if hadItemProcessed then
        self.mainLogic:setNeedCheckFalling()
        self.context.needLoopCheck = true
    end
end

function CanevineBombState:getNextState( ... )
    return self.context.colorFilterAState
end

function CanevineBombState:onExit()
    printx( -1 , "----<<<< CanevineBombState exit")
    self.nextState = nil
end

function CanevineBombState:checkTransition()
    printx( -1 , "-------------------------CanevineBombState checkTransition", 'self.nextState', self.nextState)
    return self.nextState
end


function CanevineBombState:__tryBomb(callback)
    local count = 0
    GameBoardUtil:walk_game_item(self.mainLogic, function ( game_item, r, c )
        if game_item and CanevineLogic:can_bomb(game_item.canevine_data) then
            local head_rc = CanevineLogic:get_head_rc(game_item)
            local destruction = GameBoardActionDataSet:createAs(
                GameActionTargetType.kGameItemAction,
                GameItemActionType.kItem_CanevineBomb,
                IntCoord:create(c, r),
                IntCoord:create(head_rc.c, head_rc.r), 
                GamePlayConfig_MaxAction_time)
            destruction.completeCallback = callback
            destruction.addInt = CanevineLogic:get_canevine_direction(game_item.canevine_data) 
            self.mainLogic:addDestructionPlanAction(destruction)
            count = count + 1
            self.mainLogic:setNeedCheckFalling()
            self.context.needLoopCheck = true
        end
    end)

    return count
end

function CanevineBombState:tryBomb()
    local count = 0
    local callbackCount = 0
    local function callback()
        callbackCount = callbackCount + 1
        if callbackCount == count then
            self:handleComplete(true)
        end
    end
    count = self:__tryBomb(callback)
    return count
end


CanevineBombStateInLoop = class(CanevineBombState)

function CanevineBombStateInLoop:getNextState( ... )
    return self.context.colorFilterAState
end

function CanevineBombStateInLoop:create( context )
    local v = CanevineBombStateInLoop.new()
    v.context = context
    v.mainLogic = context.mainLogic  --gameboardlogic
    v.boardView = v.mainLogic.boardView
    return v
end




CanevineBombStateInSwapFirst = class(CanevineBombState)

function CanevineBombStateInSwapFirst:getNextState( ... )
    return self.context.inactiveBlockerState 
end

function CanevineBombStateInSwapFirst:create( context )
    local v = CanevineBombStateInSwapFirst.new()
    v.context = context
    v.mainLogic = context.mainLogic  --gameboardlogic
    v.boardView = v.mainLogic.boardView
    return v
end