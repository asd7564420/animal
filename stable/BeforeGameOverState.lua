BeforeGameOverState = class(BaseStableState)

function BeforeGameOverState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end

function BeforeGameOverState:create(context)
	local v = BeforeGameOverState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function BeforeGameOverState:onEnter()
	if _G.isLocalDevelopMode then printx(-1, "BeforeGameOverState---->>>> before game over state enter") end
	BaseStableState.onEnter(self)
	self.nextState = nil

	local actionList = {}
	local actionMap = {}
	local totalCount = 0
	local current = 0

	local function eachCallback( ctx )
		if not actionMap[ctx] then
			printx(15,"Error!! remove empty action???",debug.traceback())
			return
		end
		actionMap[ctx] = nil
		current = current + 1
		if current >= totalCount then
			self.nextState = self:getNextState()
			self.mainLogic:setNeedCheckFalling()
		end
	end

    -- 如果有需要监听此事件，需要调用一次 onActionStart(ctx) 之后，在完成时调用 onActionEnd(ctx)
	local params = {}
	params.onActionEnd = eachCallback
	params.onActionStart = function(ctx)
		local info = {}
		info.context = ctx
		info.trace = debug.traceback()
		table.insert(actionList,info)
		actionMap[ctx] = info
	end

	LocalActCoreModel.getOrCreateInstance():notify(ActInterface.kBeforeGameOver, params)

	totalCount = #actionList
	-- printx(15,"totalCount",totalCount)
	if totalCount==0 then
		self.nextState = self:getNextState()
		return
	end
end

function BeforeGameOverState:onExit()
	if _G.isLocalDevelopMode then printx(-1, "BeforeGameOverState----<<<< before game over state exit") end

	BaseStableState.onExit(self)
	self.nextState = nil
end

function BeforeGameOverState:checkTransition()
	return self.nextState
end

function BeforeGameOverState:getNextState( ... )
	-- body
	printx(15,"BeforeGameOverState:getNextState")
	return self.context.gameOverState
end

function BeforeGameOverState:getClassName()
	return "BeforeGameOverState"
end
