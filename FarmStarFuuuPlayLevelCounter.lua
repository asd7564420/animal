local CacheIO = require 'zoo.localActivity.common.CacheIO'

-- 刷星FUUU专用的，有独特的计数规则

_G.FarmStarFuuuPlayLevelCounter = {}

local cacheKey = 'FarmStarFuuuPlayLevelCounter'

function FarmStarFuuuPlayLevelCounter:setTotalPlayCount( count )
	CacheIO.new(cacheKey):set('totalPlayCount', count)
end

function FarmStarFuuuPlayLevelCounter:getTotalPlayLevelCount( ... )
	local totalPlayCount = CacheIO.new(cacheKey):get('totalPlayCount') or 0
	return totalPlayCount
end

function FarmStarFuuuPlayLevelCounter:inc( ... )
	self:setTotalPlayCount(self:getTotalPlayLevelCount() + 1)
end

function FarmStarFuuuPlayLevelCounter:afterStartNewLevel( levelId )
	local levelType = LevelType:getLevelTypeByLevelId( levelId )
	if levelType == GameLevelType.kMainLevel then

		local topLevelId = UserManager.getInstance().user:getTopLevelId() or 0
		if levelId >= topLevelId then 
			return 
		end 

		--[[
		local farmStarGroup
		local collectStarEffective
		local needInc = false
		local context = LevelDifficultyAdjustManager:getContext()
		if context and context.userGroupInfo then
			farmStarGroup = context.userGroupInfo.farmStarGroup or ''
			collectStarEffective = context.collectStarEffective
			if farmStarGroup == 'A1' then
			elseif farmStarGroup == 'A2' then
				needInc = true
			elseif farmStarGroup == 'A3'  then
				needInc = not collectStarEffective
			elseif farmStarGroup == 'A4' then
				needInc = collectStarEffective
			end
		end
		if needInc then
			self:inc()
		end
		]]
		self:inc()
	end
end

return FarmStarFuuuPlayLevelCounter