DynamiteCrateLogic = class{}

----------- 大致同冰封导弹
function DynamiteCrateLogic:checkDynamiteCrate(mainLogic)
    local gameItemMap = mainLogic.gameItemMap

    local crates = {}
    for r = 1, #gameItemMap do
        for c = 1, #gameItemMap[r] do
            local item = gameItemMap[r][c]
            if item and item.ItemType == GameItemType.kDynamiteCrate and item:isAvailable() then
                if item.missileLevel == 0 then
                    table.insert(crates, item)
                end
            end
        end
    end
    return crates
end

function DynamiteCrateLogic:fireDynamiteCrates(mainLogic,crates,allCompleteCallback)
	-- 有可以发射的
    if (crates and #crates > 0) then
	    -- 播放完发射动画
	    local callback = function()
	        for i, crateItemData in ipairs(crates) do
	            if crateItemData then 
	                crateItemData:cleanAnimalLikeData()
	                SnailLogic:SpecialCoverSnailRoadAtPos( mainLogic, crateItemData.y, crateItemData.x )
	                -- mainLogic:setNeedCheckFalling()
	            end
	        end
	        allCompleteCallback()
	    end

	    for i, itemData in ipairs(crates) do
	    	--printx("r =" , itemData.y , " c =" , itemData.x)
	        local itemView = mainLogic.boardView:safeGetItemView(itemData.y, itemData.x)
	        if itemView then
	        	itemView:playDynamiteCrateSetOffAnimation()
	        end
	    end

	    -- 发射
	    local action = GameBoardActionDataSet:createAs(
	        GameActionTargetType.kGameItemAction,
	        GameItemActionType.kDynamiteSetOff, 
	        nil,
	        nil,
	        GamePlayConfig_MaxAction_time
	        )
	    action.crates = crates
	    action.completeCallback = callback
	    mainLogic:addDestroyAction(action)
	    mainLogic:setNeedCheckFalling()
    end
end

function DynamiteCrateLogic:hitDynamiteCrate(mainLogic, item, r, c, noScore, hitAll)
	if (mainLogic.isBonusTime) then
		return 
	end

	if item.missileLevel > 0 then 
		local hitTimes = 1
		if hitAll then
			hitTimes = item.missileLevel
		end

		item.missileLevel = item.missileLevel - hitTimes
		if item.missileLevel <= 0 then 
			item.missileLevel = 0
			mainLogic:setNeedCheckFalling()
		end

		if mainLogic.boardView then
			local itemView = mainLogic.boardView:safeGetItemView(r, c)
			if itemView then
				itemView:playStimulateDynamiteCrate()
			end
		end

		if (not noScore) then
			local addScore = GamePlayConfigScore.MatchAt_Missile
			mainLogic:addScoreToTotal(r, c, addScore)
		end
	end
end
