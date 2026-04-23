ShellGiftState = class(BaseStableState)

-- function ShellGiftState:dispose()
	-- BaseStableState.dipose(self)
-- end

function ShellGiftState:create(context)
	local v = ShellGiftState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	-- printx(13,"ShellGiftState:create",v,v.checkdFirstEnter)
	return v
end

function ShellGiftState:getNextState()
	return self.context.ActivityCollectionItemStateInLoop
end

function ShellGiftState:checkTransition()
	return self.nextState
end

function ShellGiftState:getClassName()
	return "ShellGiftState"
end

function ShellGiftState:onExit()
	-- printx(13,"ShellGiftState:onExit()")
	BaseStableState.onExit(self)
	self.nextState = nil
end

function ShellGiftState:onEnter()
	-- printx(13,"ShellGiftState:onEnter()-self.checkdFirstEnter",self.checkdFirstEnter)
	-- printx(13,"ShellGiftState:onEnter()-self.checkdFirstEnter",self.checkdFirstEnter,debug.traceback())
	BaseStableState.onEnter(self)

	if not ShellGiftLogic.isEnabled() then
		self.nextState = self:getNextState()
		return
	end
	self.isOver = false
	self.isNeedLoopCheck = false

	print("ShellGiftState:onEnter()self.boardView& self.mainLogic--",self.boardView,self.mainLogic,self.mainLogic.boardView)

	ShellGiftLogic.stateCheckStart(self.mainLogic.boardView,function(isNeedLoopCheck)
		printx(13,"ShellGiftState:onEnter()callback",isNeedLoopCheck)
		self.isOver = true
		self.isNeedLoopCheck = isNeedLoopCheck
	end)
end

function ShellGiftState:update(dt)
	if self.isOver then
		self.isOver = false
		if self.isNeedLoopCheck then
			-- 有礼包被销毁，需要掉落
			self.context.needLoopCheck = true
		end
		self.mainLogic:setNeedCheckFalling()
		self.nextState = self:getNextState()
	end
end

ShellGiftStateInBonus = class(ShellGiftState)
function ShellGiftStateInBonus:create( context )
	local v = ShellGiftStateInBonus.new()
	v.context = context
	v.mainLogic = context.mainLogic
	v.boardView = v.mainLogic.boardView
	return v
end

function ShellGiftStateInBonus:getNextState( ... )
	return self.context.bonusLastBombState
end

function ShellGiftStateInBonus:getClassName( ... )
	return "ShellGiftStateInBonus"
end