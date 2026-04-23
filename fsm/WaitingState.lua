require "zoo.gamePlay.fsm.GameState"
local EndGameGiftLogic = require "zoo.panel.endGameProp.EndGameGiftLogic"

WaitingState = class(GameState)

function WaitingState:create(context)
	local v = WaitingState.new()
	v.context = context
	v.mainLogic = context.mainLogic
	return v
end

function WaitingState:onEnter()
    if(forceGcMemory) then forceGcMemory() end
    GamePlayContext:getInstance():updateAIPropUsedIndex(true)

	if _G.isLocalDevelopMode then printx( -1 , ">>>>>>>>>>>>>>>>> waiting state enter") end
	self.nextState = nil
	local shouldWaitOperation = false 
	GameExtandPlayLogic:onEnterWaitingState(self.mainLogic)
	GameExtandPlayLogic:halloweenTutorial(self.mainLogic)
	if self.mainLogic.gameMode:reachEndCondition() then
		self.mainLogic:setGamePlayStatus(GamePlayStatus.kEnd)
	else
		shouldWaitOperation = true 
	end

	ProductItemDiffChangeLogic:onBoardStableHandler(self.mainLogic)

	if self.mainLogic.replaying then
		self.mainLogic:startWaitingOperation()
		self.mainLogic:Replay()
	else
		if shouldWaitOperation then 
			ReplayDataManager:updateGameScore(false, true)
			self.mainLogic:startWaitingOperation()

			EndGameGiftLogic:onWaitState(self.mainLogic)

			-- if self.mainLogic.gameMode:is(GoldenPodBattleMode) then
			-- 	self.mainLogic.gameMode:tryCheckSwitchPlayer()
			-- end
		end
	end
end

function WaitingState:onExit()
	if _G.isLocalDevelopMode then printx( -1 , "<<<<<<<<<<<<<<<<< waiting state exit") end
	self.mainLogic:stopWaitingOperation()
	self.nextState = nil
end

function WaitingState:update(dt)
end

function WaitingState:checkTransition()
	return self.nextState
end

function WaitingState:startSwapHandler()
	self.mainLogic:stopWaitingOperation()
	self.nextState = self.context.swapState
end

function WaitingState:switchPlayerHandler()
	self.mainLogic:stopWaitingOperation()
	self.nextState = self.context.fallingMatchState
end