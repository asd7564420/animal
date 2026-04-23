BeforeWaitingState = class(BaseStableState)


function BeforeWaitingState:create(context)
	local v = BeforeWaitingState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	v.totalCount = 0
	return v
end

function BeforeWaitingState:onEnter()
	BaseStableState.onEnter(self)
	self.nextState = nil
	if self.totalCount and self.totalCount>0 then
		-- 当前有action正在执行中，等待action结束
		return
	end
	self.frameCount = 0
	self.totalCount = 0
	local actionMap = {}
	local current = 0
	self.actionMap = actionMap

	local function eachCallback( ctx )
		-- print("BeforeWaitingState:onActionEnd",ctx,actionMap and actionMap[ctx],current , self.totalCount)
		-- print("BeforeWaitingState:onActionEnd",debug.traceback())
		if not actionMap[ctx] then
			print("Error!! BeforeWaitingState remove empty action???",debug.traceback())
			return
		end
		actionMap[ctx] = nil
		current = current + 1
		if current >= self.totalCount then
			print("BeforeWaitingState:onActionEnd()Over!")
			self:getNextState()
			self.mainLogic:setNeedCheckFalling()
		end
	end

    -- 如果有需要监听此事件，需要调用一次 onActionStart(ctx) 之后，在完成时调用 onActionEnd(ctx)
	local params = {}
	params.onActionEnd = eachCallback
	params.onActionStart = function(ctx)
		print("BeforeWaitingState:onActionStart",ctx)
		-- print("BeforeWaitingState:onActionStart",debug.traceback())

		local info = {}
		info.context = ctx
		info.trace = debug.traceback()
		actionMap[ctx] = info
		self.totalCount = self.totalCount+1
	end
	Notify:dispatch("onBeforeWaitingState",params)

	if self.totalCount==0 then
		self:getNextState()
		return
	end
end

function BeforeWaitingState:update()
	self.frameCount = self.frameCount+1
	if _G.AI_CHECK_ON then
		if self.frameCount == 1200 then
			local msgList = {}
			if self.actionMap then
				for k,v in pairs(self.actionMap) do
					table.insert(msgList,v.trace)
				end
			end
			local msg = table.concat(msgList," --- ")
	        AIGamePlayManager:endLevelByErrorAndReboot( AutoCheckLevelFinishReason.kBeforeWaitingState , msg )
	    end
	end
end

function BeforeWaitingState:getNextState()
	self.nextState  = self.context.actCollectionState
end

function BeforeWaitingState:checkTransition()
	return self.nextState
end

function BeforeWaitingState:getClassName()
	return "BeforeWaitingState"
end

function BeforeWaitingState:onExit()
	BaseStableState.onExit(self)
	self.nextState = nil
	self.totalCount = 0
end

function BeforeWaitingState:dispose()
	self.mainLogic = nil
	self.boardView = nil
	self.context = nil
end