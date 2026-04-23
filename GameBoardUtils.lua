local GameBoardUtils = {}

-- 废弃。转移至GameBoardUtil
function GameBoardUtils:walk_game_item( mainLogic, func)
	local gameItemMap = mainLogic.gameItemMap
    for r = 1, #gameItemMap do
        for c = 1, #gameItemMap[r] do
            local item = gameItemMap[r][c]
            func(item, r, c)
        end
    end

end

return GameBoardUtils