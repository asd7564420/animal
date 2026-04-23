CanevineLogic = {}
local cache_roots = {}


function CanevineLogic:parse_canevine_data( canevine_data )

end

function CanevineLogic:get_canevine_len( canevine_data )
	return canevine_data.len
end


function CanevineLogic:get_canevine_direction( canevine_data )
	return lua_switch(canevine_data.direction) {
		[1] = DefaultDirConfig.kUp,
		[2] = DefaultDirConfig.kDown,
		[3] = DefaultDirConfig.kLeft,
		[4] = DefaultDirConfig.kRight,
	}
end

function CanevineLogic:_is_valid_data( canevine_data )
	return (not table.isEmpty(canevine_data))
end

function CanevineLogic:get_status( canevine_data )
	return '' .. canevine_data.level .. ':' .. tostring(canevine_data.hit)
end


function CanevineLogic:is_occupy( gameItemData )
	return self:get_canevine_root(gameItemData) ~= false
end

function CanevineLogic:_hit( canevine_data )
	canevine_data.hit = canevine_data.hit + 1
end

function CanevineLogic:levelup( gameItemData )
	gameItemData.canevine_data.level = gameItemData.canevine_data.level + 1
	gameItemData.canevine_data.hit = 0
end

function CanevineLogic:can_levelup( canevine_data )
	return with(canevine_data, function ( ... )

		return CanevineLogic:get_level(canevine_data) == 0 
				and CanevineLogic:get_canevine_len(canevine_data) == CanevineLogic:get_hit(canevine_data)
	end)
end

-- 再受多少下攻击可以升级
function CanevineLogic:getHitNeededToLevelUp(canevine_data)
	if not canevine_data then return 0 end
	local currHit = CanevineLogic:get_hit(canevine_data)
	local currLength = CanevineLogic:get_canevine_len(canevine_data)
	local hitNeeded = math.max(currLength - currHit, 0)
	return hitNeeded
end

function CanevineLogic:clear_cache( ... )
	cache_roots = {}
end

function CanevineLogic:attack_canevine( mainLogic, root_item, scoreScale, noScore )

	scoreScale = scoreScale or 1
	local len = CanevineLogic:get_canevine_len(root_item.canevine_data)
	local hit = CanevineLogic:get_hit(root_item.canevine_data)

	if hit >= len then return false end

	CanevineLogic:_hit(root_item.canevine_data)

	local action = GameBoardActionDataSet:createAs(
	 		GameActionTargetType.kGameItemAction,
	 		GameItemActionType.kItem_Canevine_Open_Flower,
	 		IntCoord:create(root_item.x, root_item.y),
	 		nil,
	 		GamePlayConfig_GameItemCanevineOpenFlower_CD)
	action.addInt = CanevineLogic:get_level(root_item.canevine_data)
	action.addInt2 = CanevineLogic:get_hit(root_item.canevine_data)
	action.addInt3 = CanevineLogic:get_canevine_direction(root_item.canevine_data)
	mainLogic:addDestroyAction(action)

	return true

end

function CanevineLogic:clear( mainLogic, gameItemData )


	local pos_list = {}

	local head = CanevineLogic:get_head_rc(gameItemData)

	for r = gameItemData.y, head.r, math.sign1(head.r - gameItemData.y) do
		for c = gameItemData.x, head.c, math.sign1(head.c - gameItemData.x) do
			table.insert(pos_list, {r, c})
		end
	end

	gameItemData:cleanAnimalLikeData()

	cache_roots = {}

	for _, pos in ipairs(pos_list) do
		mainLogic:checkItemBlock(pos[1], pos[2])
	end
end

function CanevineLogic:can_bomb( canevine_data )
	return with(canevine_data, function ( ... )
		return CanevineLogic:get_level(canevine_data) == 1 
				and CanevineLogic:get_canevine_len(canevine_data) == CanevineLogic:get_hit(canevine_data)
	end)
end

function CanevineLogic:get_head_rc( gameItemData )
	local len = CanevineLogic:get_canevine_len(gameItemData.canevine_data)
	return lua_switch(CanevineLogic:get_canevine_direction(gameItemData.canevine_data)) {
		[DefaultDirConfig.kUp] = {r = gameItemData.y - (len - 1), c = gameItemData.x},
		[DefaultDirConfig.kDown] = {r = gameItemData.y + (len - 1), c = gameItemData.x},
		[DefaultDirConfig.kLeft] = {r = gameItemData.y, c = gameItemData.x - (len - 1)},
		[DefaultDirConfig.kRight] = {r = gameItemData.y, c = gameItemData.x + (len - 1)},
	}
end


function CanevineLogic:get_canevine_root( gameItemData )

	if cache_roots[gameItemData] == nil then
		local root = CanevineLogic:_find_canevine_root(gameItemData)

		if root then
			cache_roots[gameItemData] = root
		else
			cache_roots[gameItemData] = false
		end
	end

	return cache_roots[gameItemData]
end

function CanevineLogic:_find_canevine_root( gameItemData )
	
	local mainLogic = GameBoardLogic:getCurrentLogic()
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local rootGameItemData = mainLogic.gameItemMap[r][c]

			if CanevineLogic:is_canevine_root(rootGameItemData) then
				if CanevineLogic:is_belong_to(gameItemData, rootGameItemData) then
					return {r = rootGameItemData.y, c = rootGameItemData.x}
				end
			end
		end
	end

end

function CanevineLogic:get_hit( canevine_data )
	return canevine_data.hit
end

function CanevineLogic:get_level( canevine_data )
	return canevine_data.level
end

function CanevineLogic:is_canevine_root( rootGameItemData )
	return rootGameItemData and rootGameItemData.ItemType == GameItemType.kCanevine and CanevineLogic:_is_valid_data(rootGameItemData.canevine_data)
end

function CanevineLogic:destroy( mainLogic, rootGameItemData )
	rootGameItemData.canevine_data.level = 1
	rootGameItemData.canevine_data.hit = rootGameItemData.canevine_data.len
	mainLogic:setNeedCheckFalling()
end

function CanevineLogic:is_belong_to( gameItemData, rootGameItemData)
	local len = CanevineLogic:get_canevine_len(rootGameItemData.canevine_data)
	local result = lua_switch(CanevineLogic:get_canevine_direction(rootGameItemData.canevine_data)){
		[DefaultDirConfig.kUp] = function ( ... )
			return rootGameItemData.y - gameItemData.y + 1 <= len and  rootGameItemData.y >= gameItemData.y and gameItemData.x == rootGameItemData.x
		end,

		[DefaultDirConfig.kDown] = function ( ... )
			return gameItemData.y - rootGameItemData.y + 1 <= len and  rootGameItemData.y <= gameItemData.y and gameItemData.x == rootGameItemData.x
		end,

		[DefaultDirConfig.kLeft] = function ( ... )
			return rootGameItemData.x - gameItemData.x + 1 <= len and  rootGameItemData.x >= gameItemData.x and gameItemData.y == rootGameItemData.y
		end,

		[DefaultDirConfig.kRight] = function ( ... )
			return gameItemData.x - rootGameItemData.x + 1 <= len and  rootGameItemData.x <= gameItemData.x and gameItemData.y == rootGameItemData.y
		end,
	}


	return result
end









function CanevineLogic:create_line_effect( node, callback )
	-- local timePerFrame = 1/30
	-- local sprite, animate = SpriteUtil:buildAnimatedSprite(timePerFrame, 'canevine-static/CDBZ_%02d.png', 0, 35)
	-- local actionSeq = CCArray:create()
	-- actionSeq:addObject(animate)
	-- sprite:play(CCSequence:create(actionSeq), 0, 1, callback)
	-- node:addChild(sprite)
	-- return sprite


	local sprite = Sprite:createWithSpriteFrameName(self:getResPath()..'/CDBZ_00.png')
	sprite:setFramesFormat(self:getResPath()..'/CDBZ_%02d.png', 0, 35)
	node:addChild(sprite)
	sprite:playFrameAnim(1, 36, 1/30, callback)
	return sprite
end

function CanevineLogic:getResPath( ... )
	local resPath = 'canevine-static'
	local mainLogic = GameBoardLogic:getCurrentLogic()
	local levelID = mainLogic.level
	if LevelType:isMothersDay2020Level(levelID) then
		resPath = resPath..'-skin'
	end
	return resPath
end




return CanevineLogic