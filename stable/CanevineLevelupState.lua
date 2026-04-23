CanevineLevelupState = class(BaseStableState)


function CanevineLevelupState:create( context )
    local v = CanevineLevelupState.new()
    v.context = context
    v.mainLogic = context.mainLogic  --gameboardlogic
    v.boardView = v.mainLogic.boardView
    return v
end

function CanevineLevelupState:update( ... )
    -- body
    printx(61, 'CanevineLevelupState:update')
end

function CanevineLevelupState:onEnter()
	GameBoardUtil:walk_game_item(self.mainLogic, function ( game_item, r, c )
		if game_item:isAvailable() then
			if game_item.ItemType == GameItemType.kCanevine then
				if CanevineLogic:can_levelup(game_item.canevine_data) then
					CanevineLogic:levelup(game_item)
				end
			end
		end
	end)

	self:handleComplete()
end

function CanevineLevelupState:getClassName()
    return "CanevineLevelupState"
end

function CanevineLevelupState:handleComplete()
    self.nextState = self:getNextState()
end

function CanevineLevelupState:getNextState( ... )
	return self.context.productSnailState
end

function CanevineLevelupState:onExit()
    printx( -1 , "----<<<< CanevineLevelupState exit")
    self.nextState = nil
end

function CanevineLevelupState:checkTransition()
    printx( -1 , "-------------------------CanevineLevelupState checkTransition", 'self.nextState', self.nextState)
    return self.nextState
end