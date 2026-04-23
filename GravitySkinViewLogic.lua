require "zoo.gamePlay.gravitySkinLogics.GravitySkinLogic_Water"
require "zoo.gamePlay.gravitySkinLogics.GravitySkinLogic_WindTunnel"

GravitySkinViewLogic = class{}

function GravitySkinViewLogic:create( gameBoardView )
	local logic = GravitySkinViewLogic.new()
	logic:init( gameBoardView )

	return logic
end

function GravitySkinViewLogic:init( gameBoardView )
	self.gameBoardLogic = gameBoardView.gameBoardLogic

	self.needBuildGravitySkinMap = {}
	self.lastGravitySkinMap = {}
	self.logics = {}

	
	-- self.viewData
end

function GravitySkinViewLogic:initByBoardMap( boardmap )
	
	for r , v1 in ipairs( boardmap ) do

		self.lastGravitySkinMap[r] = {}

		for c , v2 in ipairs( v1 ) do
			local board = boardmap[r][c]
			local info = {}
			info.gravitySkin = board:getGravitySkinType()
			info.gravity = board:getGravity()
			info.specialGravityActive = board:getNonDefaultGravityActive()

			if info.gravitySkin == BoardGravitySkinType.kWater then
				local waterLogic = self:getLogic( BoardGravitySkinType.kWater )
				if waterLogic then
					waterLogic:updateHorizontalLineInfo( r , c )
				end
			end

			self.lastGravitySkinMap[r][c] = info
		end
	end
end


function GravitySkinViewLogic:createLogic( skinType )
	--这个方法返回一个特定的Logic，用来处理一种特定的重力皮肤的视图更新逻辑
	--每种类型的重力皮肤，都应该有一个与之对应的Logic

	if skinType == BoardGravitySkinType.kWater then
		return GravitySkinLogic_Water:create( self )
	elseif skinType == BoardGravitySkinType.kWindTunnel then
		return GravitySkinLogic_WindTunnel:create( self )
	elseif skinType == BoardGravitySkinType.kNone then
		return nil
	end
end

function GravitySkinViewLogic:getLogic( skinType )
	--这个方法返回一个特定的Logic，用来处理一种特定的重力皮肤的视图更新逻辑
	--每种类型的重力皮肤，都应该有一个与之对应的Logic

	if not self.logics[ skinType ] then
		self.logics[ skinType ] = self:createLogic( skinType )
	end

	return self.logics[ skinType ]
end

function GravitySkinViewLogic:buildMultipleGravitySkinBySkinType( skinType )
	--有些重力皮肤不是单个格子独立更新的，而是一旦更新，所有的同类型格子都要重绘（比如有复杂的拼接效果）
	--这样的逻辑都放到 buildMultipleGravitySkinBySkinType 里处理
	if not self.gameBoardLogic or not self.gameBoardLogic.boardmap then return end

	self:updateSkinDisplayHelpMap(skinType)

	local boardMap = self.gameBoardLogic.boardmap
	for r = 1, #boardMap do 
        for c = 1, #boardMap[r] do 
            local boardData = boardMap[r][c]
            local boardSkinType = boardData:getGravitySkinType()

            if boardSkinType == skinType then
            	local playChangeGravityAnim = false

            	local ignoreChangeAnim = self:getIgnoreGravitySkinChangeAnimAt(r, c)
            	local info = self.lastGravitySkinMap[r][c]
            	if not ignoreChangeAnim and info then
            		local lastGravity = info.gravity
            		local lastGravityActive = info.specialGravityActive
            		if (lastGravity ~= boardData:getGravity()) 
            			or (lastGravityActive ~= boardData:getNonDefaultGravityActive()) 
            			then
            			-- 重力方向有变化，根据需要可播放重力转换动画
            			playChangeGravityAnim = true
            		end
            	end

            	self:buildGravitySkinAt(r, c, playChangeGravityAnim)
            end
        end
    end
end

function GravitySkinViewLogic:buildGravitySkinAt( r , c, playChangeGravityAnim)
	--重新创建单个格子的新的重力方向特效，在格子的重力方向发生变化，或者重力皮肤类型发生变化后会调用

	local itemMap = self.gameBoardLogic:getItemMap()
	local boardMap = self.gameBoardLogic:getBoardMap()
	local baseMap = self.gameBoardLogic.boardView.baseMap

	local item = itemMap[r][c]
	local board = boardMap[r][c]
	local itemView = baseMap[r][c]
	local itemSprite = itemView.itemSprite

	--todo 这块逻辑只是个示意，以后要拆到单独的logic里去处理，基于现有数据，目标数据，重新拼接，并处理动画过渡  gravitySkinViewLogic
	local skinType = board:getGravitySkinType()

	if skinType > 0 then
		local logic = self:getLogic( skinType )
		if logic then
			logic:buildSkinAt( r , c , itemView )
			if playChangeGravityAnim and logic.playChangeGravityAnimationAt then
				logic:playChangeGravityAnimationAt(r, c, itemView)
			end

			local info = {}
			info.gravitySkin = skinType
			info.gravity = board:getGravity()
			info.specialGravityActive = board:getNonDefaultGravityActive()
			self.lastGravitySkinMap[r][c] = info
		end

	else
		local info = self.lastGravitySkinMap[r][c]
		local lastSkinType = info.gravitySkin
		-- printx(11, "currSkinType = 0, lastSkinType", lastSkinType)

		local logic = self:getLogic( lastSkinType )
		if logic then
			-- if lastSkinType == BoardGravitySkinType.kWater then
				logic:clearSkinAt( r , c , itemView )	
			-- end
		end
	end

	self:deleteNeedBuildGravitySkinAt( r , c ) 
	self:deleteIgnoreGravitySkinChangeAnimAt( r , c ) 

	itemView.isNeedUpdate = true
end


function GravitySkinViewLogic:buildAllGravitySkin()
	self:clearNeedBuildGravitySkin()
	self:clearIgnoreGravitySkinChangeAnim()
	-- printx( 1 , "GravitySkinViewLogic:buildGravitySkin ~~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	self:updateSkinDisplayHelpMap(BoardGravitySkinType.kWindTunnel) --风洞显示需要借助分析过后的数据

	local boardMap = self.gameBoardLogic:getBoardMap()
	for i=1, #boardMap do
		for j=1,#boardMap[i] do
			self:buildGravitySkinAt( i , j )
		end
	end
end

function GravitySkinViewLogic:clearNeedBuildGravitySkin()
	self.needBuildGravitySkinMap = {}
end

function GravitySkinViewLogic:setNeedBuildGravitySkinAt( value , r , c )
	if self.needBuildGravitySkinMap then
		self.needBuildGravitySkinMap[ tostring(r) .. "_" .. tostring(c) ] = { update = value , r = r , c = c }
	end
end

function GravitySkinViewLogic:deleteNeedBuildGravitySkinAt( r , c )
	if self.needBuildGravitySkinMap then
		self.needBuildGravitySkinMap[ tostring(r) .. "_" .. tostring(c) ] = nil 
	end
end

function GravitySkinViewLogic:getNeedBuildGravitySkinAt( r , c )
	if self.needBuildGravitySkinMap then
		return self.needBuildGravitySkinMap[ tostring(r) .. "_" .. tostring(c) ]
	end
end

function GravitySkinViewLogic:getNeedBuildGravitySkinMap()
	return self.needBuildGravitySkinMap
end

---------------- 重力切换动画，为了移动地格而维护一个免除动画表
function GravitySkinViewLogic:clearIgnoreGravitySkinChangeAnim()
	self.ignoreGravitySkinChangeAnimMap = {}
end

function GravitySkinViewLogic:setIgnoreGravitySkinChangeAnimAt( value , r , c )
	if self.ignoreGravitySkinChangeAnimMap then
		self.ignoreGravitySkinChangeAnimMap[ tostring(r) .. "_" .. tostring(c) ] = { update = value , r = r , c = c }
	end
end

function GravitySkinViewLogic:deleteIgnoreGravitySkinChangeAnimAt( r , c )
	if self.ignoreGravitySkinChangeAnimMap then
		self.ignoreGravitySkinChangeAnimMap[ tostring(r) .. "_" .. tostring(c) ] = nil 
	end
end

function GravitySkinViewLogic:getIgnoreGravitySkinChangeAnimAt( r , c )
	if self.ignoreGravitySkinChangeAnimMap then
		return self.ignoreGravitySkinChangeAnimMap[ tostring(r) .. "_" .. tostring(c) ]
	end
end

-- 某些视图需要借助分析后的数据来显示
function GravitySkinViewLogic:updateSkinDisplayHelpMap(skinType)
	local logic = self:getLogic(skinType)
	if logic and logic.updateSkinDisplayDataMap then
		logic:updateSkinDisplayDataMap()
	end
end
