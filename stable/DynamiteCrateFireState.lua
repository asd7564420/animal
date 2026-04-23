DynamiteCrateFireState = class(BaseStableState)

function DynamiteCrateFireState:create(context)
    local v = DynamiteCrateFireState.new()
    v.context = context
    v.mainLogic = context.mainLogic
    v.boardView = v.mainLogic.boardView
    return v
end

function DynamiteCrateFireState:dispose()
    self.mainLogic = nil
    self.boardView = nil
    self.context = nil
end

function DynamiteCrateFireState:update(dt)
end

function DynamiteCrateFireState:onEnter()
    BaseStableState.onEnter(self)
    self.nextState = nil
    self.hasItemToHandle = false
    self.mainLogic.missileHasHitPoint = {}

    if(not self.mainLogic._fieldLogicPossibility[_FIELD_LOGIC_ID[GameItemType.kDynamiteCrate]]) then
        printx(0, '!skip')
        self:setNextState()
        return
    end

    self:tryHandleFire()
end

function DynamiteCrateFireState:tryHandleFire()
    
    local function handleComplete()
        self:setNextState()
    end

    local mainLogic = self.mainLogic
    local findMissiles = DynamiteCrateLogic:checkDynamiteCrate(mainLogic)

    if (#findMissiles >0) then
        self.hasItemToHandle = true
        self.context.needLoopCheck = true
    else
        self.hasItemToHandle = false
    end

    -- if _G.isLocalDevelopMode then printx(0, "has missile will fire ? " , self.hasItemToHandle) end
    -- debug.debug()
    if (not self.hasItemToHandle) then
        handleComplete()
    else
        DynamiteCrateLogic:fireDynamiteCrates(mainLogic,findMissiles,handleComplete)
    end
end

function DynamiteCrateFireState:getClassName()
    return "DynamiteCrateFireState"
end

function DynamiteCrateFireState:checkTransition()
    return self.nextState
end

function DynamiteCrateFireState:onActionComplete()

end

function DynamiteCrateFireState:setNextState()
    -- self.nextState =  self.context.magicLampReinitState
end

function DynamiteCrateFireState:onExit()
    BaseStableState.onExit(self)
    self.mainLogic.missileHasHitPoint = {}
    self.hasItemToHandle = nil
    self.nextState = nil
end


-- ============================================


DynamiteCrateFireFirstState = class(DynamiteCrateFireState)
function DynamiteCrateFireFirstState:create(context)
    local v = DynamiteCrateFireFirstState.new()
    v.context = context
    v.mainLogic = context.mainLogic
    v.boardView = v.mainLogic.boardView
    return v 
end
function DynamiteCrateFireFirstState:getClassName()
    return "DynamiteCrateFireFirstState"
end

function DynamiteCrateFireFirstState:setNextState()
    self.nextState =  self.context.buffBoomCastingStateInSwapFirst 
    -- self.nextState =  self.context.transmissionState 
end

DynamiteCrateFireInLoopState = class(DynamiteCrateFireState)
function DynamiteCrateFireInLoopState:create(context)
    local v = DynamiteCrateFireInLoopState.new()
    v.context = context
    v.mainLogic = context.mainLogic
    v.boardView = v.mainLogic.boardView
    return v
end

function DynamiteCrateFireInLoopState:getClassName()
    return "DynamiteCrateFireInLoopState"
end

function DynamiteCrateFireInLoopState:setNextState()
    --self.nextState =  self.context.magicLampCastingStateInLoop
    self.nextState =  self.context.buffBoomCastingStateInLoop
end