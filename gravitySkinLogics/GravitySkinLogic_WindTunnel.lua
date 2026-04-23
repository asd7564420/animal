GravitySkinLogic_WindTunnel = class()

WindTunnelSkinType = table.const{
	kFG = 1,
	kMG = 2,
	kBG = 3,
}

function GravitySkinLogic_WindTunnel:create( gravitySkinViewLogic )
	local logic = GravitySkinLogic_WindTunnel.new()
	logic:init( gravitySkinViewLogic )

	return logic
end

function GravitySkinLogic_WindTunnel:init( gravitySkinViewLogic )
	self.gravitySkinViewLogic = gravitySkinViewLogic
end

function GravitySkinLogic_WindTunnel:clearItemSprite( itemView )

	local itemSprite = itemView.itemSprite

	if itemSprite[ItemSpriteType.kGravitySkinTop] then
		itemSprite[ItemSpriteType.kGravitySkinTop]:removeFromParentAndCleanup(true)
		itemSprite[ItemSpriteType.kGravitySkinTop] = nil
	end

	if itemSprite[ItemSpriteType.kGravitySkinMiddle] then
		itemSprite[ItemSpriteType.kGravitySkinMiddle]:removeFromParentAndCleanup(true)
		itemSprite[ItemSpriteType.kGravitySkinMiddle] = nil
	end

	if itemSprite[ItemSpriteType.kGravitySkinBottom] then
		itemSprite[ItemSpriteType.kGravitySkinBottom]:removeFromParentAndCleanup(true)
		itemSprite[ItemSpriteType.kGravitySkinBottom] = nil
	end
end


function GravitySkinLogic_WindTunnel:changeSkinAt( r , c , mode )

end

function GravitySkinLogic_WindTunnel:buildSkinAt( r , c , itemView  )
	-- printx(11, "= = = GravitySkinLogic_WindTunnel:buildSkinAt", r , c)
	self:clearItemSprite( itemView )

	local mainLogic = self.gravitySkinViewLogic.gameBoardLogic
	if not mainLogic or not mainLogic.boardmap or not mainLogic.boardmap[r] or not mainLogic.boardmap[r][c] then return end

	local targetBoardData = mainLogic.boardmap[r][c]
	local windTunnelDir = targetBoardData.windTunnelDir
	local windTunnelIsActive = targetBoardData.windTunnelActive
	if not windTunnelDir then return end 

	local itemSprite = itemView.itemSprite

	local spriteTop = TileGravitySkin_WindTunnel:create(WindTunnelSkinType.kFG, windTunnelDir, windTunnelIsActive, r, c)
	local posTop = itemView:getBasePosition(itemView.x, itemView.y)
	spriteTop:setPosition(posTop)
	itemSprite[ItemSpriteType.kGravitySkinTop] = spriteTop
	-- if not windTunnelIsActive then
	-- 	spriteTop:playBreathingAnim()
	-- end

	local spriteMiddle = TileGravitySkin_WindTunnel:create(WindTunnelSkinType.kMG, windTunnelDir, windTunnelIsActive, r, c, self.groupIDMap)
	local posMid = itemView:getBasePosition(itemView.x, itemView.y)
	spriteMiddle:setPosition(posMid)
	itemSprite[ItemSpriteType.kGravitySkinMiddle] = spriteMiddle

	local spriteBottom = TileGravitySkin_WindTunnel:create(WindTunnelSkinType.kBG, windTunnelDir, windTunnelIsActive, r, c)
	local pos = itemView:getBasePosition(itemView.x, itemView.y)
	spriteBottom:setPosition(pos)
	itemSprite[ItemSpriteType.kGravitySkinBottom] = spriteBottom

	local itemMap = mainLogic:getItemMap()
	local item = itemMap[r][c]
	itemView:upDatePosBoardDataPos( item , true )----------更新Item的显示位置-------
end

function GravitySkinLogic_WindTunnel:clearSkinAt( r , c , itemView  )
	self:clearItemSprite( itemView )
end

function GravitySkinLogic_WindTunnel:playChangeGravityAnimationAt(r , c , itemView)
	local itemSprite = itemView.itemSprite
	if not itemSprite then return end

	local spriteMiddle = itemSprite[ItemSpriteType.kGravitySkinMiddle]
	if not spriteMiddle or spriteMiddle.isDisposed then return end

	spriteMiddle:playChangeGravityEffectAnim()
end

function GravitySkinLogic_WindTunnel:updateSkinDisplayDataMap()
	self.groupIDMap = WindTunnelLogic:getAllWindTunnelGroupAreas()
	if not self.groupIDMap then self.groupIDMap = {} end
end
