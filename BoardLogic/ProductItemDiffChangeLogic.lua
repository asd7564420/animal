ProductItemDiffChangeLogic = {}

ProductItemDiffChangeMode = {
	kNone = 0 ,
	kDropEff = 1 ,
	kDropEffAndBird = 2 ,
	kAddColor = 3 ,
	kAIAddColor = 4 ,
	kAICoreAddColor = 5,
	kDecreaseColor = 6,
	kAIDecreaseColor = 7,
	kAIADColor = 8,
}

local changeColorMode = {
	[ ProductItemDiffChangeMode.kAddColor ] = true ,
	[ ProductItemDiffChangeMode.kAIAddColor ] = true ,
	[ ProductItemDiffChangeMode.kAICoreAddColor ] = true ,
	[ ProductItemDiffChangeMode.kDecreaseColor ] = true ,
	[ ProductItemDiffChangeMode.kAIDecreaseColor ] = true ,
	[ ProductItemDiffChangeMode.kAIADColor ] = true ,
}

local testConfig = {

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 70,
				ruleA_n2 = 5,
				ruleA_m2 = 65,
				ruleA_n3 = 10,
				ruleA_m3 = 60,
				ruleA_n4 = 9999,
				ruleA_m4 = 50,

				--ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 5,
				ruleB_n2 = 10,
				ruleB_m2 = 7,
				ruleB_n3 = 15,
				ruleB_m3 = 10,
				ruleB_n4 = 20,
				ruleB_m4 = 15,

				--ruleC 全局掉落口，最近n步之内，目标色（C色）的干预次数不超过m个
				ruleC_n1 = 1,
				ruleC_m1 = 20,
				ruleC_n2 = 2,
				ruleC_m2 = 30,
				ruleC_n3 = 3,
				ruleC_m3 = 40,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,
			}

require "zoo.gamePlay.config.ProductItemDiffChangeFalsifyConfig"
local FalsifyConfig = nil
local defaultLevelLeftMovesAdjust = 5
local AIColorAdjustRate_firstStep = 0.2
local AIColorAdjustRate_secondStep = 0.3
local AIColorAdjustRate_thirdStep = 0.55
local AIColorAdjustRate_default = 0.55

ProductItemDiffChangeLogic.modes = {}

local testFlag = false

function ProductItemDiffChangeLogic:getModeName(mode)

	local nameStr = "未知"
	if mode == 0 then
		nameStr = "默认不修正"
	elseif mode == 1 then
		nameStr = "全局随机掉落特效"
	elseif mode == 2 then
		nameStr = "全局随机掉落特效和魔力鸟"
	elseif mode == 3 then
		nameStr = "全局增加单色概率"
	elseif mode == 4 then
		nameStr = "智能增加单色概率"
	elseif mode == 6 then
		nameStr = "固定负向干预"
	elseif mode == 7 then
		nameStr = "动态负向干预"
	elseif mode == 8 then
		nameStr = "正负颜色干预"
	end

	return nameStr
end

function ProductItemDiffChangeLogic:getDataVerName(dataVer)

	local nameStr = ""
	if dataVer == 0 then
		nameStr = ""
	elseif dataVer == 1 then
		nameStr = "（一级）"
	elseif dataVer == 2 then
		nameStr = "（二级）"
	elseif dataVer == 3 then
		nameStr = "（三级）"
	elseif dataVer == 4 then
		nameStr = "（四级）"
	elseif dataVer == 5 then
		nameStr = "（五级）"
	elseif dataVer == 6 then
		nameStr = "（2.5级）"
	elseif dataVer == 7 then
		nameStr = "（6级）"
	end

	return nameStr
end

function ProductItemDiffChangeLogic:testUseOldVersion()

	--[[
	if self.useOldVersion then
		self.useOldVersion = false
	else
		self.useOldVersion = true
	end
	
	CommonTip:showTip( "使用旧版addColor逻辑 " .. tostring(self.useOldVersion) , "negative", nil, 3)
	]]
end

function ProductItemDiffChangeLogic:getTestFlag()
	return testFlag
end

function ProductItemDiffChangeLogic:testChangeMode()

	if not __WIN32 then
		return
	end

	if not self.modes[1] then self.modes[1] = {} end

	local modeData = self.modes[1]

	if not modeData.mode then modeData.mode = 0 end

	if not modeData.dataVer then modeData.dataVer = 0 end

	if modeData.mode == 0 then
		modeData.mode = 3
		modeData.dataVer = 1
	else
		modeData.dataVer = modeData.dataVer + 1
	end

	if modeData.mode == 3 and modeData.dataVer > 7 then
		modeData.mode = 4
		modeData.dataVer = 1
	elseif modeData.mode == 4 and modeData.dataVer > 1 then
		modeData.mode = 6
		modeData.dataVer = 1
	elseif modeData.mode == 6 and modeData.dataVer > 5 then
		modeData.mode = 7
		modeData.dataVer = 1
	elseif modeData.mode == 7 and modeData.dataVer > 1 then
		modeData.mode = 8
		modeData.dataVer = 1
	elseif modeData.mode == 8 and modeData.dataVer > 1 then
		modeData.mode = 0
		modeData.dataVer = 0
	end

	local str = self:getDataVerName(modeData.dataVer) 
	if modeData.mode == 0 then
		str = ""
	end

	CommonTip:showTip( self:getModeName(modeData.mode) .. str .. " Actived" , "negative", nil, 3)

	LevelDifficultyAdjustManager:updateCurrStrategyID( {mode = modeData.mode , ds = modeData.dataVer} , nil )

	testFlag = true

end

function ProductItemDiffChangeLogic:addMode( mode , dataVer )

	for k,v in ipairs(self.modes) do
		if v.mode == mode then
			return
		end
	end

	local modeData = {}
	modeData.mode = mode
	modeData.dataVer = dataVer

	table.insert( self.modes , modeData )

end

function ProductItemDiffChangeLogic:getCurrDS()
	return self.currds
end

function ProductItemDiffChangeLogic:setCurrDS(value)
	self.currds = value
end

function ProductItemDiffChangeLogic:changeMode( mode , dataVer )
	-- printx( 1 , "ProductItemDiffChangeLogic:changeMode  ~~~~~~~~~~~~~~~~~~~~~~~  mode , dataVer =" , mode , dataVer )
	if testFlag then return false end

	local oldMode = nil
	local oldDtaVer = nil

	for k,v in ipairs(self.modes) do
		if v.mode == mode then
			oldMode = mode
			oldDtaVer = v.dataVer
			break
		end
	end

	local dataHasChanged = true

	if mode == oldMode and dataVer == oldDtaVer then
		dataHasChanged = false
	else
		--仅在数据变化时才设置
		self.modes = {} -- 永远清空，不再支持同时激活多mode的情况
		self.aiCareMode = nil
		self:addMode( mode , dataVer )
	end

	return dataHasChanged
	
	--[[
	local modedata = nil

	for k,v in ipairs(self.modes) do
		if v.mode == mode then
			modedata = v
			break
		end
	end

	if modedata then
		modedata.mode = mode
		modedata.dataVer = dataVer
	else
		self:addMode( mode , dataVer )
	end
	]]
end

function ProductItemDiffChangeLogic:removeMode( mode )
	if testFlag then return end

	local idx = nil
	for k,v in ipairs(self.modes) do
		if v.mode == mode then
			idx = k
			break
		end
	end

	if idx then
		return table.remove( self.modes , idx )
	end
end

function ProductItemDiffChangeLogic:removeModeByIndex( idx )
	if testFlag then return end

	if idx <= #self.modes then
		return table.remove( self.modes , idx )
	end
end

function ProductItemDiffChangeLogic:getMode()
	if not self.mode then self.mode = 0 end

	return self.mode
end

function ProductItemDiffChangeLogic:countBoardColors( mainLogic )
	if mainLogic then

		local currStepColorNumMap = {}
		local currStepColorNumList = {}

		for r = 1, #mainLogic.gameItemMap do
			for c = 1, #mainLogic.gameItemMap[r] do
				local item = mainLogic.gameItemMap[r][c]
				if item and item.ItemType ~= GameItemType.kDrip and item:isColorful() and (not item:hasCoveredByBlock()) then
					if item._encrypt.ItemColorType ~= AnimalTypeConfig.kNone then

						local colorIndex = AnimalTypeConfig.convertColorTypeToIndex( item._encrypt.ItemColorType )

						if colorIndex --[[and self.context.availableColorList[colorIndex] ]] then

							if not currStepColorNumMap[ colorIndex ] then
								currStepColorNumMap[ colorIndex ] = 0
							end

							currStepColorNumMap[ colorIndex ] = currStepColorNumMap[ colorIndex ] + 1
						end
						
					end
				end
			end
		end
		-- printx( 1 , "countBoardColors  currStepColorNumMap = " , table.tostring(currStepColorNumMap) )
		currStepColorNumMap[0] = 0

		local _flagMap = {}
		for k , v in pairs( currStepColorNumMap ) do
			if k > 0 then
				table.insert( currStepColorNumList , { colorIndex = k , count = v } )
				_flagMap[k] = true
			end
		end

		-- printx( 1 , "countBoardColors  availableColorList = " , table.tostring(self.context.availableColorList) )
		for k,v in pairs(self.context.availableColorList) do
			if not _flagMap[k] then
				table.insert( currStepColorNumList , { colorIndex = k , count = 0 } )
			end
		end

		-- table.sort( currStepColorNumList , 
		-- 			function ( a, b )
		-- 				return a.count < b.count
		-- 			end
		-- )

		return currStepColorNumMap , currStepColorNumList
	end
end

function ProductItemDiffChangeLogic:onBoardStableHandler(mainLogic)
	-- printx( 1 , "ProductItemDiffChangeLogic:onBoardStableHandler  #self.modes =" , #self.modes , debug.traceback())
	if mainLogic and self.modes and #self.modes > 0 then

		self.currStepColorNumMap = {}
		self.currStepColorNumList = {}

		for r = 1, #mainLogic.gameItemMap do
			for c = 1, #mainLogic.gameItemMap[r] do
				local item = mainLogic.gameItemMap[r][c]
				if item and item.isUsed and not item.isEmpty and item.ItemType ~= GameItemType.kDrip and item:isColorful() then
					if item._encrypt.ItemColorType ~= AnimalTypeConfig.kNone then

						local colorIndex = AnimalTypeConfig.convertColorTypeToIndex( item._encrypt.ItemColorType )

						if colorIndex and self.context.availableColorList[colorIndex] then

							if not self.currStepColorNumMap[ colorIndex ] then
								self.currStepColorNumMap[ colorIndex ] = 0
							end

							self.currStepColorNumMap[ colorIndex ] = self.currStepColorNumMap[ colorIndex ] + 1
						end
						
					end
				end
			end
		end

		self.currStepColorNumMap[0] = 0

		--[[
		local _flagMap = {}
		for k , v in pairs( self.currStepColorNumMap ) do
			if k > 0 then
				table.insert( self.currStepColorNumList , { colorIndex = k , count = v } )
				_flagMap[k] = true
			end
		end

		for k,v in pairs(self.context.availableColorList) do
			if not _flagMap[k] then
				table.insert( self.currStepColorNumList , { colorIndex = k , count = 0 } )
			end
		end

		table.sort( self.currStepColorNumList , 
					function ( a, b )
						return a.count < b.count
					end
		)
		-- printx( 1 , "sortList =============== " , table.tostring(self.currStepColorNumList) )
		
		self.currStepMaxCountColorIndex = 0
		self.currStepMinCountColorIndex = 0

		self.currStepMaxColorCount = 0
		self.currStepMinColorCount = 0

		if #self.currStepColorNumList > 0 then
			local totalColor = #self.currStepColorNumList
			self.currStepMaxCountColorIndex = self.currStepColorNumList[ #self.currStepColorNumList ].colorIndex
			self.currStepMaxCountColorIndex = self.currStepColorNumList[ 1 ].colorIndex

			self.currStepMaxColorCount = self.currStepColorNumList[ #self.currStepColorNumList ].count
			self.currStepMinColorCount = self.currStepColorNumList[ 1 ].count
		end
		--]]
		

		-- printx( 1 , "ProductItemDiffChangeLogic:onBoardStableHandler --------------  self.currStepColorNumMap =" , table.tostring(self.currStepColorNumMap) )
		LevelDifficultyAdjustManager:getDAManager():setColorCountMap( self.currStepColorNumMap )

		if table.includes(self.modes, ProductItemDiffChangeMode.kAICoreAddColor) then return end

		local result , fuuuLogID , progressData = FUUUManager:lastGameIsFUUU(false , false)

		if progressData then
			--printx( 1 , "AnimalStageInfo:addPropsUsedInLevel  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! propId" , propId )
			-- printx( 1 , "ProductItemDiffChangeLogic:onBoardStableHandler  progressData = " , table.tostring(progressData) )

			local tarMap = {}

			for k,v in ipairs(progressData) do
				if v.orderTargetId then
					if v.cld then
						--printx(1 , "FUCK          v  = " , table.tostring(v))
						for k2,v2 in ipairs(v.cld) do

							local tp = {}

							tp.orderTargetId = v.orderTargetId * 100 + v2.k2
							tp.cv = v2.cv or 0
							tp.tv = v2.tv or 0
							table.insert( tarMap , tp )
						end
					else
						local tp = {}

						tp.orderTargetId = v.orderTargetId * 100
						tp.cv = v.cv or 0
						tp.tv = v.tv or 0
						table.insert( tarMap , tp )
					end
				end
			end

			local levelId = mainLogic.level
			local costMove = mainLogic.realCostMoveWithoutBackProp

			local isReplay = false
			if mainLogic.replayMode == ReplayMode.kNormal 
				or mainLogic.replayMode == ReplayMode.kCheck 
				or mainLogic.replayMode == ReplayMode.kStrategy 
				or mainLogic.replayMode == ReplayMode.kConsistencyCheck_Step2 
				or mainLogic.replayMode == ReplayMode.kResume 
				or mainLogic.replayMode == ReplayMode.kSectionResume 
				or mainLogic.replayMode == ReplayMode.kReview
				then
				isReplay = true
			end
			local staticProgressData , staticTotalSteps = LevelDifficultyAdjustManager:getLevelTargetProgressData( levelId , costMove , isReplay )
			if not staticProgressData then staticProgressData = {} end

			-- printx( 1 , "ProductItemDiffChangeLogic:onBoardStableHandler  costMove =" , costMove)
			-- printx( 1 , "++++++++++++++++++++ " , table.tostring(staticProgressData))

			
			local staticMove = mainLogic.staticLevelMoves
			local stepAdjust = LevelDifficultyAdjustManager:getLevelLeftMoves( levelId ) or defaultLevelLeftMovesAdjust

			--printx( 1 , "ProductItemDiffChangeLogic:onBoardStableHandler  costMove =" , costMove , "staticMove =" , staticMove , "stepAdjust = " ,stepAdjust)

			local tarNum = #tarMap
			local currStepRate = 0
			--local currStepStaticRate = (costMove - stepAdjust ) / (staticMove - stepAdjust)
			local currStepStaticMidRate = 0
			local currStepStaticLowRate = 0
			local currStepStaticMinRate = 0
			local currStepStaticHighRate = 0
			local currStepStaticVerylowRate = 0
			local currStepStaticSmallRate = 0

			local rateDiff = 0
			

			-- printx(1 , "MMP #tarMap = " , #tarMap , table.tostring(tarMap))

			for k,v in ipairs(tarMap) do
				local targetId = v.orderTargetId

				if staticProgressData[ tostring(targetId) ] then
					local tdata = staticProgressData[ tostring(targetId) ]

					local mid = v.tv - tdata.mid --已搜集个数
					local low = v.tv - tdata.low --已搜集个数
					local min = nil
					local verylow = nil
					local small = nil
					local high = nil

					if tdata.min then
						min = v.tv - tdata.min --已搜集个数
					end

					if tdata.verylow then
						verylow = v.tv - tdata.verylow --已搜集个数
					end

					if tdata.small then
						small = v.tv - tdata.small --已搜集个数
					end

					if tdata.high then
						high = v.tv - tdata.high --已搜集个数
					end

					--[[
					if v.cv <= mid then

						local currv = v.cv - low
						if currv < 0 then currv = 0 end --如果用户的搜集数量连low都没达到，则取0

						local fr = 0
						if mid - low ~= 0 then
							fr = ( currv / (mid - low) ) or 0
						end
						printx(1,"FUCK  aaa   rateDiff =" , rateDiff , fr)
						rateDiff = rateDiff + fr

					else
						printx(1,"FUCK  bbb   rateDiff =" , rateDiff)
						rateDiff = rateDiff + 1
					end
					
					--]]

					local vp = tonumber( v.cv / v.tv )
					if vp > 1 then 
						vp = 1 
					elseif vp < 0 then
						vp = 0
					end
					currStepRate = currStepRate + vp

					local sp = tonumber( mid / v.tv )
					if sp > 1 then 
						sp = 1 
					elseif sp < 0 then
						sp = 0
					end
					currStepStaticMidRate = currStepStaticMidRate + sp

					sp = tonumber( low / v.tv )
					if sp > 1 then 
						sp = 1 
					elseif sp < 0 then
						sp = 0
					end
					currStepStaticLowRate = currStepStaticLowRate + sp

					if min then
						sp = tonumber( min / v.tv )
						if sp > 1 then 
							sp = 1 
						elseif sp < 0 then
							sp = 0
						end
						currStepStaticMinRate = currStepStaticMinRate + sp
					else
						currStepStaticMinRate = currStepStaticLowRate
					end

					if verylow then
						sp = tonumber( verylow / v.tv )
						if sp > 1 then 
							sp = 1 
						elseif sp < 0 then
							sp = 0
						end
						currStepStaticVerylowRate = currStepStaticVerylowRate + sp
					else
						currStepStaticVerylowRate = currStepStaticLowRate
					end

					if small then
						sp = tonumber( small / v.tv )
						if sp > 1 then 
							sp = 1 
						elseif sp < 0 then
							sp = 0
						end
						currStepStaticSmallRate = currStepStaticSmallRate + sp
					else
						currStepStaticSmallRate = currStepStaticLowRate
					end

					if high then
						sp = tonumber( high / v.tv )
						if sp > 1 then 
							sp = 1 
						elseif sp < 0 then
							sp = 0
						end
						currStepStaticHighRate = currStepStaticHighRate + sp
					else
						currStepStaticHighRate = currStepStaticLowRate
					end
					
				end

				--[[
				local vp = tonumber( v.cv / v.tv )
				if vp > 1 then vp = 1 end
				currStepRate = currStepRate + vp
				]]
			end

			-- printx( 1 , "ProductItemDiffChangeLogic:onBoardStableHandler  currStepRate = " , currStepRate , "tarNum = " , tarNum , " ---- " , currStepStaticMidRate , currStepStaticLowRate ,currStepStaticMinRate,currStepStaticVerylowRate,currStepStaticSmallRate ,currStepStaticHighRate)

			currStepRate = currStepRate / tarNum
			currStepStaticMidRate = currStepStaticMidRate / tarNum
			currStepStaticLowRate = currStepStaticLowRate / tarNum
			currStepStaticMinRate = currStepStaticMinRate / tarNum
			currStepStaticVerylowRate = currStepStaticVerylowRate / tarNum
			currStepStaticSmallRate = currStepStaticSmallRate / tarNum
			currStepStaticHighRate = currStepStaticHighRate / tarNum
			--rateDiff = rateDiff / tarNum

			self.currStepProgressData = {}
			self.currStepProgressData.currStepRate = currStepRate

			self.currStepProgressData.currStepStaticMidRate = currStepStaticMidRate
			self.currStepProgressData.currStepStaticLowRate = currStepStaticLowRate
			self.currStepProgressData.currStepStaticMinRate = currStepStaticMinRate
			self.currStepProgressData.currStepStaticHighRate = currStepStaticHighRate
			self.currStepProgressData.currStepStaticVerylowRate = currStepStaticVerylowRate
			self.currStepProgressData.currStepStaticSmallRate = currStepStaticSmallRate

			-- printx( 1 , "ProductItemDiffChangeLogic:onBoardStableHandler  self.currStepProgressData.currStepRate = " , self.currStepProgressData.currStepRate)
			--self.currStepProgressData.currStepStaticRate = self.currStepProgressData.currStepStaticMinRate

			--costMove
			local groupData = LevelDifficultyAdjustManager:tryCreateUserGroupInfo( mainLogic.level )
			local staticDataSwitchConfig = nil
			MACRO_DEV_START()
			if _G.AIFuuuTestGroup then
				groupData.fuuuInlevelDecisionGroup = _G.AIFuuuTestGroup
			end
			MACRO_DEV_END()

			if groupData and groupData.fuuuInlevelDecisionGroup and AIAddColorConfig.staticDataSwitchExpGroup then

				if groupData.fuuuInlevelDecisionGroup == 10 then
					local adjustContext = LevelDifficultyAdjustManager:getContext()
					if adjustContext and adjustContext.last60DayPayAmount > 0 then
						staticDataSwitchConfig = AIAddColorConfig.staticDataSwitchExpGroup[ 1 ]
					else
						staticDataSwitchConfig = AIAddColorConfig.staticDataSwitchExpGroup[ 5 ]
					end
				else
					staticDataSwitchConfig = AIAddColorConfig.staticDataSwitchExpGroup[ groupData.fuuuInlevelDecisionGroup ]
				end
			end

			if not staticDataSwitchConfig then
				staticDataSwitchConfig = AIAddColorConfig.staticDataSwitch
			end

			local _staticTotalSteps = staticTotalSteps or 10000

			for k,v in ipairs(staticDataSwitchConfig) do

				local rate = costMove / _staticTotalSteps
				if rate >= v.minMovesRate and rate <= v.maxMovesRate then

					if v.progressData == "mid" then
						self.currStepProgressData.currStepStaticRate = self.currStepProgressData.currStepStaticMidRate
					elseif v.progressData == "min" then
						self.currStepProgressData.currStepStaticRate = self.currStepProgressData.currStepStaticMinRate
					elseif v.progressData == "low" then
						self.currStepProgressData.currStepStaticRate = self.currStepProgressData.currStepStaticLowRate
					elseif v.progressData == "verylow" then
						self.currStepProgressData.currStepStaticRate = self.currStepProgressData.currStepStaticVerylowRate
					elseif v.progressData == "small" then
						self.currStepProgressData.currStepStaticRate = self.currStepProgressData.currStepStaticSmallRate
					elseif v.progressData == "high" then
						self.currStepProgressData.currStepStaticRate = self.currStepProgressData.currStepStaticHighRate
					end
					
					-- printx( 1, "当前智能调整选择的期望线为：" ,v.progressData , "self.currStepProgressData.currStepStaticRate = " , self.currStepProgressData.currStepStaticRate )
					break
				end
			end

			if not self.currStepProgressData.currStepStaticRate then
				self.currStepProgressData.currStepStaticRate = self.currStepProgressData.currStepStaticLowRate
			end
			

			if self.currStepProgressData.currStepStaticRate == 0 then
				self.currStepProgressData.rateDiff = 0
			else
				self.currStepProgressData.rateDiff = (self.currStepProgressData.currStepStaticRate - currStepRate) / self.currStepProgressData.currStepStaticRate
			end
			
			-- if self.currStepProgressData.rateDiff < 0 then self.currStepProgressData.rateDiff = 0 end

			self.currStepProgressData.isFuuu = result
			self.currStepProgressData.staticTotalSteps = staticTotalSteps

			-- printx( 1 , "=======================  ProductItemDiffChangeLogic:onBoardStableHandler =========================="  )
			-- printx( 1 , "realCostMoveWithoutBackProp:" , costMove  )
			-- printx( 1 , "currStepRate:" , currStepRate  )
			-- printx( 1 , "currStepStaticRate:" , self.currStepProgressData.currStepStaticRate  )
			-- printx( 1 , "rateDiff:" , self.currStepProgressData.rateDiff  ) --距离预期的差值，无差距为0，最大为1
			-- printx( 1 , "isFuuu:" , result  )
			-- printx( 1 , "stepAdjust:" , stepAdjust  )
			-- printx( 1 , "==================================================================================================="  )
		end

		--[[
		if _G.isLocalDevelopMode then
			for k,v in ipairs(self.modes) do
				if v.mode == ProductItemDiffChangeMode.kAddColor then
					local cc = self:getCurrStepMaxNumColor()
					local str = ""

					if cc == 1 then
						str = "蓝[1]"
					elseif cc == 2 then
						str = "绿[2]"
					elseif cc == 3 then
						str = "棕[3]"
					elseif cc == 4 then
						str = "紫[4]"
					elseif cc == 5 then
						str = "红[5]"
					elseif cc == 6 then
						str = "黄[6]"
					end

					CommonTip:showTip( "当前最多颜色 " .. tostring(str) .. " 数量：" .. tostring(self.currStepColorNumMap[cc]) , "negative", nil, 2)
					break
				end
			end
		end
		--]]

	end
end

function ProductItemDiffChangeLogic:getCurrStepMaxNumColor()
	
	if self.currStepColorNumMap then

		local maxColor = nil
		local currNum = 0

		for k,v in pairs(self.currStepColorNumMap) do
			if v > currNum then
				currNum = v
				maxColor = k
			end
		end

		return maxColor
	end

	return nil
end

function ProductItemDiffChangeLogic:rand( v1 , v2 )
	if self.mainLogic then
		return self.mainLogic.randFactory:rand( v1 , v2 )
	end
	return 0
end

function ProductItemDiffChangeLogic:setStepColorNumMap(colorMap)
	self.currStepColorNumMap = colorMap
end

function ProductItemDiffChangeLogic:startLevel(mainLogic)
	self.mainLogic = mainLogic
	self.currStepColorNumMap = {}
	self.context = {}

	self.context.realCostMove = self.mainLogic.realCostMove or 0
	self.context.falsifyMap = {}
	self.context.colorLogMap = {}

	self.context.availableColorList = {}
	self.context.defaultColorList = {}
	self.context.singleDropConfig = {}
	self.context.currFrameId = 0
	--self.context.singleColorList = {}

	local _singleDropConfig = self.mainLogic:getSingleDropConfig( 0 , 0 )

	for k,v in pairs(_singleDropConfig) do
		self.context.singleDropConfig[k] = {}
		local cfg = self.context.singleDropConfig[k]
		for k2,v2 in pairs( v ) do
			local colorIndex = AnimalTypeConfig.convertColorTypeToIndex(v2)
			if colorIndex then
				cfg[colorIndex] = true
				self.context.availableColorList[colorIndex] = true
			end
		end
	end

	for k,v in pairs( self.mainLogic.mapColorList ) do
		local colorIndex = AnimalTypeConfig.convertColorTypeToIndex(v)
		if colorIndex then
			self.context.availableColorList[colorIndex] = true
			self.context.defaultColorList[colorIndex] = true
		end
	end

	self:setCurrDS(0)
end

function ProductItemDiffChangeLogic:getSingleDropConfigOfGrid(r, c)
	if not self.mainLogic then
		return self.context.singleDropConfig  	--如果取不到格子掉落配置，返回原先的默认全局配置，以免出错
	end
	if not r then r = 0 end
	if not c then c = 0 end

	local singleDropConfigOfGrid

	local _singleDropConfigOfGrid = self.mainLogic:getSingleDropConfig(r, c)
	if _singleDropConfigOfGrid then
		singleDropConfigOfGrid = {}
		for k,v in pairs(_singleDropConfigOfGrid) do
			singleDropConfigOfGrid[k] = {}
			local cfg = singleDropConfigOfGrid[k]
			for k2,v2 in pairs( v ) do
				local colorIndex = AnimalTypeConfig.convertColorTypeToIndex(v2)
				if colorIndex then
					cfg[colorIndex] = true
				end
			end
		end
	end

	-- printx(11, "singleDropConfigOfGrid: ", r, c, table.tostring(singleDropConfigOfGrid))
	if singleDropConfigOfGrid then
		return singleDropConfigOfGrid
	else
		return self.context.singleDropConfig 	--如果取不到格子掉落配置，返回原先的默认全局配置，以免出错
	end
end

function ProductItemDiffChangeLogic:onStepEnd()
	self.context.realCostMove = self.mainLogic.realCostMove or 0
end

function ProductItemDiffChangeLogic:endLevel()
	if testFlag then
		return
	end
	
	self.modes = {}
	self:setCurrDS(0)
	self.aiCareMode = nil
end

function ProductItemDiffChangeLogic:getContext()
	return self.context
end

function ProductItemDiffChangeLogic:setContext(contextdata)
	self.context = contextdata
	if not self.context.currFrameId then
		self.context.currFrameId = 0
	end
end

function ProductItemDiffChangeLogic:getFalsifyStepData(realCostMove)
	--printx( 1 , "ProductItemDiffChangeLogic:getFalsifyStepData  realCostMove" , realCostMove)
	if not self.context.falsifyMap[realCostMove] then
		--printx( 1 , "ProductItemDiffChangeLogic:getFalsifyStepData   !!!!!!!!!!!!!!!!!!!!!!!!")
		local resultColorMap = {}
		resultColorMap[1] = 0
		resultColorMap[2] = 0
		resultColorMap[3] = 0
		resultColorMap[4] = 0
		resultColorMap[5] = 0
		resultColorMap[6] = 0

		self.context.falsifyMap[realCostMove] = {
			dropEff = 0 ,
			dropBird = 0 ,
			changeColorCount = 0 ,
			resultColorMap = resultColorMap ,
			dropNum = 0 ,
		}
	end

	if self.context.falsifyMap[ realCostMove - 10 ] then
		self.context.falsifyMap[ realCostMove - 10 ] = nil
	end

	return self.context.falsifyMap[realCostMove]
end

function ProductItemDiffChangeLogic:falsify(itemdata , cannonType , cannonPos, boardData, forceForbidDiffChange)
	--if itemdata and ( itemdata.ItemType == GameItemType.kAnimal or itemdata.ItemType == GameItemType.kCrystal ) then
	if itemdata and itemdata:isColorful() and itemdata.ItemType ~= GameItemType.kDrip then
		local forbidDiffChange = false
		if forceForbidDiffChange or (boardData and boardData.forbidProduceDiffChange) then
			-- printx(11, "=== FORBID: ProductItemDiffChangeLogic:falsify === ("..boardData.y..","..boardData.x..")", forceForbidDiffChange)
			forbidDiffChange = true
		end

		if not forbidDiffChange then
			self:handleAiDcByMode()

			for k,v in ipairs(self.modes) do
				local data = v
				local fixedCannonType = ProductItemLogic:getProductItemIdByCannonType( cannonType )
				-- printx( 1 , "ProductItemDiffChangeLogic:falsify   mode" ,data.mode , "dataVer" , data.dataVer , "cannonPos" , cannonPos)
				self:__falsify( data.mode , data.dataVer , itemdata , fixedCannonType , cannonPos)
			end
		end

		local ctx = GamePlayContext:getInstance()
		if ctx.endlessLoopData and ctx.endlessLoopData.deathLoop then

			local r = cannonPos.r
			local c = cannonPos.c

			if ctx.endlessLoopData.deathLoop.loopType == DeathLoopType.kColor 
				and ctx.endlessLoopData.deathLoop.r == r
				and ctx.endlessLoopData.deathLoop.c == c then

				local colorList = nil
				local colorMap = {}

				local singleDropConfigOfGrid = self:getSingleDropConfigOfGrid(r, c)
				if singleDropConfigOfGrid then
					colorList = singleDropConfigOfGrid[cannonType]
					if colorList then
						for k , v in pairs( colorList ) do
							colorMap[k] = true
						end
					end
				end

				colorList = self.context.defaultColorList
				for k , v in pairs( colorList ) do
					colorMap[k] = true
				end

				colorList = {}
				for k , v in pairs( colorMap ) do
					table.insert( colorList , k )
				end

				if #colorList > 0 then
					colorIndex = colorList[ self:rand(1,#colorList) ]

					local color = AnimalTypeConfig.convertIndexToColorType( colorIndex )

					itemdata._encrypt.ItemColorType = color

					ctx.endlessLoopData.deathLoop.fixCount =ctx.endlessLoopData.deathLoop.fixCount + 1
					if ctx.endlessLoopData.deathLoop.fixCount > 6 then
						ctx.endlessLoopData = {}
					end
				end

			elseif ctx.endlessLoopData.deathLoop.loopType == DeathLoopType.kPortal then
				--do nothing
				--对于传送门的循环掉落，颜色干预无能为力
			end
		end
	end
end

local aiCareModes = {
	ProductItemDiffChangeMode.kAddColor,
	ProductItemDiffChangeMode.kAIAddColor,
	ProductItemDiffChangeMode.kAICoreAddColor,
	ProductItemDiffChangeMode.kDecreaseColor,
	ProductItemDiffChangeMode.kAIDecreaseColor,
	ProductItemDiffChangeMode.kAIADColor,
}
function ProductItemDiffChangeLogic:handleAiDcByMode()
	if not LevelType:isMainLevel(self.mainLogic.level) then return end
	if self.mainLogic.theGamePlayStatus ~= GamePlayStatus.kNormal then return end
	if self.aiCareMode == nil then
		self.aiCareMode = false 
		for i,v in ipairs(self.modes) do
			if table.includes(aiCareModes, v.mode) then
				self.aiCareMode = true 
				break 
			end
		end
	end

	if not self.aiCareMode then
		local realCostMove = self.mainLogic.realCostMoveWithoutBackProp
		if GamePlayContext:getInstance():getAIPropUsedIndex() then
			realCostMove = realCostMove + 1  						--道具使用时 所用策略 用下一步的
		end
		GamePlayContext:getInstance():addAIInterveneLog(realCostMove, self.mainLogic.realCostMoveWithoutBackProp, self.mainLogic.theCurMoves, 0)
	end
end

function ProductItemDiffChangeLogic:falsifyByDropEff( item , dropedNum , dataset )
	local num1 = 100
	local num2 = 0

	if dropedNum == 0 then
		num2 = dataset.n0
	elseif dropedNum <= dataset.m1 then
		num2 = dataset.n1
	elseif dropedNum <= dataset.m2 then
		num2 = dataset.n2
	elseif dropedNum <= dataset.m3 then
		num2 = dataset.n3
	elseif dropedNum <= dataset.m4 then
		num2 = dataset.n4
	end

	--printx( 1 , "falsifyByDropEff   dropedNum =" , dropedNum , " n0:" , dataset.n0 , "m1" , dataset.m1 , "n1" , dataset.n1 , "m2" , dataset.m2 , "n2"  ,dataset.n2)

	if self:rand(1,num1) <= num2 then

		local rn = self:rand(1,3)
		if rn == 1 then
			item.ItemSpecialType = AnimalTypeConfig.kLine
		elseif rn == 2 then
			item.ItemSpecialType = AnimalTypeConfig.kColumn
		elseif rn == 3 then
			item.ItemSpecialType = AnimalTypeConfig.kWrap
		end

		
		return true , item.ItemSpecialType
	end

	return false
end

function ProductItemDiffChangeLogic:tryDropEff( stepData , mode , dataVer , itemdata , cannonType , cannonPos)

	if itemdata.ItemType ~= GameItemType.kAnimal then
		return
	end

	local dataset = FalsifyConfig[mode].kNormalLevel[dataVer]
	--[[
		[1] = {
			n0 = 15 ,
			m1 = 3 ,
			n1 = 10 ,
			m2 = 8 ,
			n2 = 5 ,
			m3 = 15 ,
			n3 = 2 ,
			m4 = 9999 ,
			n4 = 0 ,
		} ,
	]]

	if self:falsifyByDropEff( itemdata , stepData.dropNum , dataset ) then
		--printx( 1 , "kDropEff ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   " ,mode , dataVer)
		stepData.dropEff = stepData.dropEff + 1
	end
	stepData.dropNum = stepData.dropNum + 1
end

function ProductItemDiffChangeLogic:tryDropBird( stepData , mode , dataVer , itemdata , cannonType , cannonPos)

	local function falsifyByDropBird( item , dropedNum , dataset )
		local num1 = 100

		if dropedNum < dataset.m1 then
			if self:rand(1,num1) <= dataset.n1 then
				item.ItemSpecialType = AnimalTypeConfig.kColor
				return true
			end
		end

		return false
	end

	if itemdata.ItemType ~= GameItemType.kAnimal then
		return
	end

	local dataset_DropEff = FalsifyConfig[ProductItemDiffChangeMode.kDropEff].kNormalLevel[dataVer]
	local dataset_DropBird = FalsifyConfig[mode].kNormalLevel[dataVer]
	--[[
		[1] = {
			n1 = 20 ,
			m1 = 2 ,
		} ,
	]]
	local dropBird = false

	if self:falsifyByDropEff( itemdata , stepData.dropNum , dataset_DropEff ) then

		if falsifyByDropBird( itemdata , stepData.dropBird , dataset_DropBird ) then
			stepData.dropBird = stepData.dropBird + 1
		else
			stepData.dropEff = stepData.dropEff + 1
		end
	end

	stepData.dropNum = stepData.dropNum + 1
end

function ProductItemDiffChangeLogic:tryGetCurrDataset( mode , dataVer )
	-- printx( 1 , "ProductItemDiffChangeLogic:tryGetCurrDataset  " , mode , dataVer)
	local dataset = nil

	if FalsifyConfig[mode] and FalsifyConfig[mode].kNormalLevel then 
		dataset = FalsifyConfig[mode].kNormalLevel[dataVer]
	end

	local realCostMove = self.mainLogic.realCostMoveWithoutBackProp
	if GamePlayContext:getInstance():getAIPropUsedIndex() then
		realCostMove = realCostMove + 1  						--道具使用时 所用策略 用下一步的
	end

	if false and mode == ProductItemDiffChangeMode.kAICoreAddColor then 
		local aiColorProbs = LevelDifficultyAdjustManager:getAIColorProbs()
		local aiColorProbsMaxNum = #aiColorProbs
		local interveneLv 
		if realCostMove > aiColorProbsMaxNum then
			-- if remaining free steps = 0
			-- game client pops the last value from the FIPO list and applies the intervention intensity for all remaining steps (steps that users have purchased)
			interveneLv = tonumber(aiColorProbs[aiColorProbsMaxNum])
		else
			interveneLv = tonumber(aiColorProbs[realCostMove])
		end

		if interveneLv then
			if self.mainLogic.theGamePlayStatus == GamePlayStatus.kNormal then 
				GamePlayContext:getInstance():addAIInterveneLog(realCostMove, self.mainLogic.realCostMoveWithoutBackProp, self.mainLogic.theCurMoves, interveneLv)
		 	end
		 	if interveneLv >= 1 and interveneLv <= 3 then 
				dataset = FalsifyConfig[ProductItemDiffChangeMode.kAIAddColor].kNormalLevel[interveneLv]
				self:setCurrDS(interveneLv)
			end
		end
	elseif ( mode == ProductItemDiffChangeMode.kAIAddColor 
			or mode == ProductItemDiffChangeMode.kAIADColor 
			or mode == ProductItemDiffChangeMode.kAIDecreaseColor ) and self.currStepProgressData then 
		
		dataset = nil

		local currStepRate = self.currStepProgressData.currStepRate
		local currStepStaticRate = self.currStepProgressData.currStepStaticRate
		local rateDiff = self.currStepProgressData.rateDiff
		local isFuuu = self.currStepProgressData.isFuuu
		local staticTotalSteps = self.currStepProgressData.staticTotalSteps or 10000
		

		local levelId = self.mainLogic.level
		--local stepAdjust = LevelDifficultyAdjustManager:getLevelLeftMoves( levelId ) or defaultLevelLeftMovesAdjust
		local costMove = self.mainLogic.realCostMoveWithoutBackProp

		local rateAdjust = AIColorAdjustRate_default
		local passAdjust = false
		local adjustPoint1 = nil
		local adjustPoint2 = nil
		local adjustPoint3 = nil
		local adjustMinusPoint1 = nil
		local adjustMinusPoint2 = nil
		local adjustMinusPoint3 = nil
		
		--[[]]----------------------------------

		
		local rateAdjustConfig = nil
		local minusRateAdjustConfig = nil

		-------------------------------------------
		local interveneLv = 0
		-- printx( 1 , "ProductItemDiffChangeLogic:tryGetCurrDataset  rateDiff" , rateDiff  )
		if rateDiff <= 0 then
			-- rateDiff <= 0意味着超出预期
			if mode == ProductItemDiffChangeMode.kAIAddColor then
				--禁用干预
				-- printx( 1 , "ProductItemDiffChangeLogic  禁用干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu )
			elseif mode == ProductItemDiffChangeMode.kAIADColor or mode == ProductItemDiffChangeMode.kAIDecreaseColor then
				--负向干预
				if AIAddColorConfig.minusRateAdjustExpGroup then
					minusRateAdjustConfig = AIAddColorConfig.minusRateAdjustExpGroup[ 1 ] --先写死，以后可能做分组测试

					if minusRateAdjustConfig then
						for k,v in ipairs(minusRateAdjustConfig) do

							local rate = costMove / staticTotalSteps
							if rate >= v.minMovesRate and rate <= v.maxMovesRate then

								adjustMinusPoint1 = v.adjustMinusPoint1
								adjustMinusPoint2 = v.adjustMinusPoint2
								adjustMinusPoint3 = v.adjustMinusPoint3
								break
							end
						end
					end
				end

				if not (adjustMinusPoint1 and adjustMinusPoint2 and adjustMinusPoint3) then
					-- printx( 1 , "ProductItemDiffChangeLogic  缺少配置，禁用负向干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu , adjustPoint1 , adjustPoint2 , adjustPoint3 )
				elseif adjustMinusPoint1 and rateDiff <= 0 and math.abs(rateDiff) <= adjustMinusPoint1 then
					-- printx( 1 , "ProductItemDiffChangeLogic  接近期望，禁用负向干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu )
				elseif adjustMinusPoint2 and math.abs(rateDiff) > adjustMinusPoint1 and math.abs(rateDiff) <= adjustMinusPoint2 then
					-- printx( 1 , "ProductItemDiffChangeLogic  开启负向弱干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu )
					dataset = FalsifyConfig[mode].kNormalLevel[1]
					self:setCurrDS( 1 )
					interveneLv = -1
				elseif adjustMinusPoint3 and math.abs(rateDiff) > adjustMinusPoint2 and math.abs(rateDiff) <= adjustMinusPoint3 then
					-- printx( 1 , "ProductItemDiffChangeLogic  开启中等干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu )
					dataset = FalsifyConfig[mode].kNormalLevel[2]
					self:setCurrDS( 3 )
					interveneLv = -2
				elseif math.abs(rateDiff) > adjustMinusPoint3 then
					-- printx( 1 , "ProductItemDiffChangeLogic  开启强干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu )
					dataset = FalsifyConfig[mode].kNormalLevel[3]
					self:setCurrDS( 4 )
					interveneLv = -3
				else
					-- printx( 1 , "ProductItemDiffChangeLogic  缺少配置2，禁用负向干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu , adjustPoint1 , adjustPoint2 , adjustPoint3 )
				end
			end

		elseif mode ~= ProductItemDiffChangeMode.kAIDecreaseColor then
			-- 正向干预
			local groupData = LevelDifficultyAdjustManager:tryCreateUserGroupInfo( levelId )
			
			MACRO_DEV_START()	
			if _G.AIFuuuTestGroup then
				groupData.fuuuInlevelDecisionGroup = _G.AIFuuuTestGroup
			end
			MACRO_DEV_END()

			if groupData and groupData.fuuuInlevelDecisionGroup and AIAddColorConfig.rateAdjustExpGroup then
				if groupData.fuuuInlevelDecisionGroup == 10 then
					local adjustContext = LevelDifficultyAdjustManager:getContext()
					if adjustContext and adjustContext.last60DayPayAmount > 0 then
						rateAdjustConfig = AIAddColorConfig.rateAdjustExpGroup[ 1 ]
					else
						rateAdjustConfig = AIAddColorConfig.rateAdjustExpGroup[ 5 ]
					end
				else
					rateAdjustConfig = AIAddColorConfig.rateAdjustExpGroup[ groupData.fuuuInlevelDecisionGroup ]
				end
			end

			if not rateAdjustConfig then
				rateAdjustConfig = AIAddColorConfig.rateAdjust
			end

			for k,v in ipairs(rateAdjustConfig) do

				local rate = costMove / staticTotalSteps
				if rate >= v.minMovesRate and rate <= v.maxMovesRate then

					adjustPoint1 = v.adjustPoint1
					adjustPoint2 = v.adjustPoint2
					adjustPoint3 = v.adjustPoint3
					-- printx( 1 , "---------- 启用第" .. tostring(k) .. "组rateAdjust配置" , 
					-- 	"adjustPoint1=" .. tostring(adjustPoint1) .. " adjustPoint2=" .. tostring(adjustPoint2) .. " adjustPoint3=" .. tostring(adjustPoint3) )
					
					break
				end
			end

			if not (adjustPoint1 and adjustPoint2 and adjustPoint3) then
				-- printx( 1 , "ProductItemDiffChangeLogic  缺少配置，禁用干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu , adjustPoint1 , adjustPoint2 , adjustPoint3 )
			elseif adjustPoint1 and rateDiff > 0 and rateDiff <= adjustPoint1 then
				-- printx( 1 , "ProductItemDiffChangeLogic  接近期望，禁用干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu )
			elseif adjustPoint2 and rateDiff > adjustPoint1 and rateDiff <= adjustPoint2 then
				-- printx( 1 , "ProductItemDiffChangeLogic  开启弱干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu )
				dataset = FalsifyConfig[mode].kNormalLevel[1]
				self:setCurrDS( 1 )
				interveneLv = 1
			elseif adjustPoint3 and rateDiff > adjustPoint2 and rateDiff <= adjustPoint3 then
				-- printx( 1 , "ProductItemDiffChangeLogic  开启中等干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu )
				dataset = FalsifyConfig[mode].kNormalLevel[2]
				self:setCurrDS( 3 )
				interveneLv = 2
			elseif rateDiff > adjustPoint3 then
				-- printx( 1 , "ProductItemDiffChangeLogic  开启强干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu )
				dataset = FalsifyConfig[mode].kNormalLevel[3]
				self:setCurrDS( 4 )
				interveneLv = 3
			else
				-- printx( 1 , "ProductItemDiffChangeLogic  缺少配置2，禁用干预" , rateDiff , currStepRate , currStepStaticRate , isFuuu )
			end
		end
		
		if self.mainLogic.theGamePlayStatus == GamePlayStatus.kNormal then
			GamePlayContext:getInstance():addAIInterveneLog(realCostMove, self.mainLogic.realCostMoveWithoutBackProp, self.mainLogic.theCurMoves, interveneLv)
		end
	elseif mode == ProductItemDiffChangeMode.kDecreaseColor then
		--do nothing
		--kDecreaseColor模式每一步都是固定强度
	end

	return dataset
end


function ProductItemDiffChangeLogic:_doChangeColor( item , colorIndex , isMaxColor , stepData , dataset , colorLogList )
	local color = AnimalTypeConfig.convertIndexToColorType( colorIndex )
	item._encrypt.ItemColorType = color

	if isMaxColor then
		stepData.changeColorCount = stepData.changeColorCount + 1
	end
	
	stepData.resultColorMap[colorIndex] = stepData.resultColorMap[colorIndex] + 1

	table.insert( colorLogList , colorIndex )
	if #colorLogList > dataset.ruleB_n4 then
		table.remove( colorLogList , 1 )
	end 

	stepData.dropNum = stepData.dropNum + 1
end

function ProductItemDiffChangeLogic:_doPassChangeColor( item , oringinColorIndex , stepData , dataset , colorLogList )
	stepData.resultColorMap[oringinColorIndex] = stepData.resultColorMap[oringinColorIndex] + 1

	table.insert( colorLogList , oringinColorIndex )
	if #colorLogList > dataset.ruleB_n4 then
		table.remove( colorLogList , 1 )
	end

	stepData.dropNum = stepData.dropNum + 1
end

function ProductItemDiffChangeLogic:_doChangeNotMaxColor( item , maxColorIndex , oringinColorIndex , cannonType, r, c , stepData , dataset , colorLogList )
	local colorIndex = nil

	if maxColorIndex ~= oringinColorIndex then

		local colorList = nil

		local singleDropConfigOfGrid = self:getSingleDropConfigOfGrid(r, c)
		if singleDropConfigOfGrid then
			colorList = singleDropConfigOfGrid[cannonType]
			if not colorList then
				colorList = self.context.defaultColorList
			end
		end

		local randomList = {}
		if colorList and #colorList > 0 then
			for k,v in pairs(colorList) do
				if k ~= maxColorIndex then
					table.insert( randomList , k )
				end
			end
		end

		if #randomList > 0 then
			colorIndex = randomList[ self:rand(1,#randomList) ]
		end
	end
	

	if colorIndex then
		self:_doChangeColor( item , colorIndex , false , stepData , dataset , colorLogList )
	else
		self:_doPassChangeColor( item , oringinColorIndex , stepData , dataset , colorLogList )
	end
end

function ProductItemDiffChangeLogic:_doChangeNotSameColor( mode , dataVer )

end

function ProductItemDiffChangeLogic:tryChangeColor( stepData , mode , dataVer , itemdata , cannonType , cannonPos)
	-- printx( 1 , "ProductItemDiffChangeLogic:tryChangeColor  " , mode , dataVer )
	local dataset = nil

	local uid = UserManager:getInstance():getUID()

	--[[
	if MaintenanceManager:getInstance():isEnabledInGroup("LevelDifficultyAdjust" , "NewColor" , uid) then --使用新版本的颜色掉落算法
		self.useOldVersion = false
	else
		self.useOldVersion = true
	end

	if self.useOldVersion then
		dataset = FalsifyConfig[mode].kOldVersion[dataVer]
	else
		dataset = FalsifyConfig[mode].kNormalLevel[dataVer]
	end
	]]

	dataset = self:tryGetCurrDataset( mode , dataVer )
	if not dataset then
		-- debug.debug()
		return
	end

	--[[
	if MaintenanceManager:isEnabledInGroup( "ReturnUsersRetentionTest" , "C" , uid) then
		if dataVer == 3 then
			dataset = testConfig
		end
	end
	]]

	local currStepColorNumMap = self.currStepColorNumMap
	local maxColorIndex = self:getCurrStepMaxNumColor()
	local maxColor = AnimalTypeConfig.convertIndexToColorType( maxColorIndex )

	local oringinColorIndex = AnimalTypeConfig.convertColorTypeToIndex( itemdata._encrypt.ItemColorType )
	local oringinColor = itemdata._encrypt.ItemColorType

	local colorLog = self.context.colorLogMap
	local cannonPosKey = tostring(cannonPos.r) .. "_" .. tostring(cannonPos.c)

	if not colorLog[cannonPosKey] then
		colorLog[cannonPosKey] = {}
	end

	local colorLogList = colorLog[cannonPosKey]

	if oringinColorIndex < 1 or oringinColorIndex > 6 then
		return --魔力鸟不做任何操作
	end

	if mode == ProductItemDiffChangeMode.kAddColor 
		or mode == ProductItemDiffChangeMode.kAIAddColor 
		or mode == ProductItemDiffChangeMode.kAICoreAddColor then 
		
		local result = self:changeColorRuleA( maxColorIndex , oringinColorIndex , cannonType , stepData , dataset, cannonPos.r, cannonPos.c)
		local isSameColor = false
		if not result.result then

			self:_doPassChangeColor( itemdata , oringinColorIndex , stepData , dataset , colorLogList )
			
			--[[
			printx( 1 , "ProductItemDiffChangeLogic:__falsify  PASS BY A   oringinColorIndex =" , oringinColorIndex )

			if result.ruleIndex then
				printx( 1 , "ruleIndex:" , result.ruleIndex , "m:" , result.m)
			else
				printx( 1 , "passByUnavailableColors:" , result.maxColorIndex )
			end
			
			printx( 1 , "--------------------------------------")
			--]]
			return
		else
			if result.isSameColor then
				-- printx( 1 , "maxColorIndex == oringinColorIndex , so ignore it")
				isSameColor = true
			end
		end

		if not isSameColor then
			result = self:changeColorRuleB( maxColorIndex , colorLogList , dataset )
			if not result.result then
				
				-- printx( 1 , "ProductItemDiffChangeLogic:__falsify  NOT MAX BY B  at" , cannonPosKey )
				-- printx( 1 , "ruleIndex:" , result.ruleIndex , "maxColorIndex:" , result.maxColorIndex , "maxColorNum:" , result.maxColorNum , "oringinColorIndex:" , oringinColorIndex)
				self:_doChangeNotMaxColor( itemdata , maxColorIndex  , oringinColorIndex , cannonType, cannonPos.r, cannonPos.c , stepData , dataset , colorLogList)
				-- printx( 1 , "--------------------------------------")
				return
			end

			result = self:changeColorRuleC( maxColorIndex , dataset )
			if not result.result then
				self:_doChangeNotMaxColor( itemdata , maxColorIndex , oringinColorIndex , cannonType, cannonPos.r, cannonPos.c , stepData , dataset , colorLogList)
				-- printx( 1 , "ProductItemDiffChangeLogic:__falsify  NOT MAX BY C" )
				-- printx( 1 , "ruleIndex:" , result.ruleIndex , "changeColorCountInSomeSteps:" , result.count)
				-- printx( 1 , "--------------------------------------")
				return
			end
		end
		

		if isSameColor then
			-- printx( 1 , "ProductItemDiffChangeLogic:__falsify  PASS BY Same Color Ignore  oringinColorIndex:" , oringinColorIndex , " oringinColorNum:" , stepData.resultColorMap[oringinColorIndex] )
			self:_doPassChangeColor( itemdata , oringinColorIndex , stepData , dataset , colorLogList )
		else
			-- printx( 1 , "ProductItemDiffChangeLogic:__falsify  doChangeColor  oringinColorIndex" , oringinColorIndex , 
			--   	"  maxColorIndex:" , maxColorIndex , "maxColorNum:"  , stepData.resultColorMap[maxColorIndex] )
			self:_doChangeColor( itemdata , maxColorIndex , true , stepData , dataset , colorLogList)
		end

	elseif mode == ProductItemDiffChangeMode.kDecreaseColor 
		or mode == ProductItemDiffChangeMode.kAIDecreaseColor then
		-- kAIDecreaseColor	
		--[[
		self.currStepColorNumList
		self.currStepMaxCountColorIndex = 0
		self.currStepMinCountColorIndex = 0

		self.currStepMaxColorCount = 0
		self.currStepMinColorCount = 0
		]]

		local currStepColorNumMap = nil
		local currStepColorNumList = nil
		local fixedCurrStepColorNumList = nil

		local currFrameId = self.context.currFrameId

		local ruleEValue = dataset.ruleE or 0

		if currFrameId and self.mainLogic.fallingMatchFrameId - currFrameId <= ruleEValue then 
		-- if self.currFrameId == self.mainLogic.fallingMatchFrameId then 
			currStepColorNumList = self.currStepColorNumList or {}
			currStepColorNumMap = self.currStepColorNumMap or {}
			fixedCurrStepColorNumList = self.fixedCurrStepColorNumList or {}
			-- printx( 1 , "ProductItemDiffChangeLogic:__falsify tryChangeColor  currFrameId" , currFrameId , "Use Cache !!!" )
		else
			self.context.currFrameId = self.mainLogic.fallingMatchFrameId
			currStepColorNumMap , currStepColorNumList = self:countBoardColors( self.mainLogic )

			if not currStepColorNumMap then currStepColorNumMap = {} end
			if not currStepColorNumList then currStepColorNumList = {} end

			self.currStepColorNumMap = currStepColorNumMap
			self.currStepColorNumList = currStepColorNumList

			
			fixedCurrStepColorNumList = {}
			local singleDropConfig = nil
			local singleDropConfigOfGrid = self:getSingleDropConfigOfGrid( cannonPos.r , cannonPos.c )
			if singleDropConfigOfGrid then
				singleDropConfig = singleDropConfigOfGrid[cannonType]
			end

			if singleDropConfig then
				for k,v in pairs( singleDropConfig ) do

					local founded = false
					for k2,v2 in ipairs( currStepColorNumList ) do
						if v2.colorIndex == k then
							table.insert( fixedCurrStepColorNumList , v2 )
							founded = true
							break
						end
					end

					if not founded then
						table.insert( currStepColorNumList , { colorIndex = k , count = 0 } )
						table.insert( fixedCurrStepColorNumList , { colorIndex = k , count = 0 } )
					end
				end
			else
				for k,v in pairs( self.context.defaultColorList ) do

					local founded = false
					for k2,v2 in ipairs( currStepColorNumList ) do
						if v2.colorIndex == k then
							table.insert( fixedCurrStepColorNumList , v2 )
							founded = true
							break
						end
					end

					if not founded then
						table.insert( currStepColorNumList , { colorIndex = k , count = 0 } )
						table.insert( fixedCurrStepColorNumList , { colorIndex = k , count = 0 } )
					end
				end
			end

			table.sort( fixedCurrStepColorNumList , 
						function ( a, b )
							return a.count < b.count
						end
			)

			self.fixedCurrStepColorNumList = fixedCurrStepColorNumList

			-- printx( 1 , "ProductItemDiffChangeLogic:__falsify tryChangeColor  currFrameId" , currFrameId , 
			-- 			"countBoardColors !!! \n" , table.tostring(fixedCurrStepColorNumList) )
		end

		local result = self:changeColorRuleD( fixedCurrStepColorNumList , oringinColorIndex , cannonType , stepData , dataset, cannonPos.r, cannonPos.c)
		local isSameColor = false
		if not result.result then
			-- printx( 1 , "ProductItemDiffChangeLogic:__falsify tryChangeColor  _doPassChangeColor 1 at " , cannonPosKey )
			self:_doPassChangeColor( itemdata , oringinColorIndex , stepData , dataset , colorLogList )
		elseif result.colorIndex and result.colorIndex > 0 and (not result.isSameColor) then

			local ruleBResult = self:changeColorRuleB( result.colorIndex , colorLogList , dataset )

			if ruleBResult.result then
				-- printx( 1 , "ProductItemDiffChangeLogic:__falsify tryChangeColor  _doChangeColor 2 at " , cannonPosKey , "result.colorIndex =" , result.colorIndex )
				self:_doChangeColor( itemdata , result.colorIndex , false , stepData , dataset , colorLogList)
			else
				-- printx( 1 , "ProductItemDiffChangeLogic:__falsify tryChangeColor  _doPassChangeColor 2 at " , cannonPosKey )
				self:_doPassChangeColor( itemdata , oringinColorIndex , stepData , dataset , colorLogList )
			end
		else
			-- printx( 1 , "ProductItemDiffChangeLogic:__falsify tryChangeColor  _doPassChangeColor 3 at " , cannonPosKey )
			self:_doPassChangeColor( itemdata , oringinColorIndex , stepData , dataset , colorLogList )
		end
	elseif mode == ProductItemDiffChangeMode.kAIADColor then 
		--to do
		self:_doPassChangeColor( itemdata , oringinColorIndex , stepData , dataset , colorLogList )
	end

	-- printx( 1 , "ProductItemDiffChangeLogic ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ mode =" , mode)
	-- printx( 1 , table.tostring(stepData.resultColorMap))
end

function ProductItemDiffChangeLogic:__falsify( mode , dataVer , itemdata , cannonType , cannonPos)
	-- printx( 1 , "ProductItemDiffChangeLogic:__falsify   -------- " , mode , dataVer )
	if not FalsifyConfig then
		FalsifyConfig = MetaManager.getInstance():getProductItemDiffChangeFalsifyConfig()	
	end

	self:setCurrDS( dataVer )
	local stepData = self:getFalsifyStepData( self.context.realCostMove )

	if mode == ProductItemDiffChangeMode.kDropEff then
		self:tryDropEff( stepData , mode , dataVer , itemdata , cannonType , cannonPos )
	elseif mode == ProductItemDiffChangeMode.kDropEffAndBird then
		self:tryDropBird( stepData , mode , dataVer , itemdata , cannonType , cannonPos )
	elseif changeColorMode[mode] then
		self:tryChangeColor( stepData , mode , dataVer , itemdata , cannonType , cannonPos )
	end
end

function ProductItemDiffChangeLogic:changeColorRuleD( fixedCurrStepColorNumList , oringinColorIndex , cannonType , currStepData , dataset, r, c)

	
	
	local result = {}
	result.result = false
	result.oringinColorIndex = oringinColorIndex
	-- printx( 1 , "ProductItemDiffChangeLogic:changeColorRuleD  " ,oringinColorIndex , cannonType ,  currStepData , dataset)
	
	local currStepMaxColorCount = 0
	if #fixedCurrStepColorNumList > 0 then
		currStepMaxColorCount = fixedCurrStepColorNumList[#fixedCurrStepColorNumList].count
	end

	local fixedMinColorList = {}
	local fixedMaxColorList = {}
	-- printx( 1 , "ProductItemDiffChangeLogic:changeColorRuleD  fixedCurrStepColorNumList" , table.tostring(fixedCurrStepColorNumList)  )
	-- printx( 1 , "ProductItemDiffChangeLogic:__falsify tryChangeColor  currStepColorNumMap" , table.tostring(currStepColorNumMap)  )
	for k,v in ipairs( fixedCurrStepColorNumList ) do
		if v.count >= currStepMaxColorCount then
			table.insert( fixedMaxColorList , v )
		else
			table.insert( fixedMinColorList , v )
		end
	end

	-- printx( 1 , "fixedMinColorList = " , table.tostring(fixedMinColorList) )
	-- printx( 1 , "fixedMaxColorList = " , table.tostring(fixedMaxColorList) )

	local fixedMinColorListLength = #fixedMinColorList
	local fixedMaxColorListLength = #fixedMaxColorList

	-- printx( 1 , "fixedMinColorList = " , table.tostring(fixedMinColorList) )
	-- printx( 1 , "fixedMaxColorList = " , table.tostring(fixedMaxColorList) )

	if fixedMinColorListLength == 0 and fixedMaxColorListLength > 0  then
		local colorObj = fixedMaxColorList[ self:rand( 1 , fixedMaxColorListLength ) ]
		result.colorIndex = colorObj.colorIndex
		colorObj.count = colorObj.count + 1
		result.result = true
	elseif fixedMaxColorListLength > 0 then
		local minColorWeight = fixedMinColorListLength * dataset.ruleD_weight_a1
		local randomCount = minColorWeight + fixedMaxColorListLength * dataset.ruleD_weight_a2
		local randnum = self:rand( 1 , randomCount )
		
		if randnum <= minColorWeight then

			local colorObj = nil

			if fixedMinColorListLength == 1 then
				colorObj = fixedMinColorList[ 1 ]
			else
				local configWeight = dataset[ "ruleD_weight_b" .. tostring(fixedMinColorListLength) ]
				local randList = {}
				local rnum = 0
				for k,v in ipairs(configWeight) do
					rnum = rnum + v
					table.insert( randList , rnum ) 
				end

				local ranresult = self:rand( 1 , rnum )
				local resultIndex = nil
				for k,v in ipairs(randList) do
					if ranresult <= v then
						resultIndex = k
						break
					end
				end

				colorObj = fixedMinColorList[ resultIndex ]
			end
			
			if colorObj then
				result.colorIndex = colorObj.colorIndex
				colorObj.count = colorObj.count + 1
				result.result = true
			end
		else
			local colorObj = fixedMaxColorList[ self:rand( 1 , fixedMaxColorListLength ) ]
			result.colorIndex = colorObj.colorIndex
			colorObj.count = colorObj.count + 1
			result.result = true
		end
	end

	if result.colorIndex == oringinColorIndex then
		result.isSameColor = true
	end
	

	return result
end


function ProductItemDiffChangeLogic:changeColorRuleA( maxColorIndex , oringinColorIndex , cannonType , currStepData , dataset, r, c)
	local result = {}
	result.result = true
	-- printx( 1 , "ProductItemDiffChangeLogic:changeColorRuleA  " , maxColorIndex ,oringinColorIndex , cannonType ,  currStepData , dataset)


	if maxColorIndex ~= oringinColorIndex then

		local passByUnavailableColors = false

		local singleDropConfigOfGrid = self:getSingleDropConfigOfGrid(r, c)
		-- printx( 11, "=== singleDropConfigOfGrid ", table.tostring(singleDropConfigOfGrid))
		-- printx( 11, "=== defaultColorList ", table.tostring(self.context.defaultColorList))
		if singleDropConfigOfGrid then
			local colorConfig = singleDropConfigOfGrid[cannonType]
			if not colorConfig then
				-- printx( 11, "set to defaultColorList ")
				colorConfig = self.context.defaultColorList
			end

			if colorConfig then
				if not colorConfig[maxColorIndex] then
					passByUnavailableColors = true
				end
			end
		end

		if not passByUnavailableColors then

			local maxColorCount = currStepData.resultColorMap[maxColorIndex] or 0
			local ruleA_m = 0
			local ri = 0
			
			for i = 1 , 4 do
				--printx( 1, "i" .. tostring(i) , "maxColorIndex = " , maxColorIndex , "maxColorCount = " , maxColorCount )
				--printx( 1 , table.tostring(currStepData.resultColorMap))
				if maxColorCount <= dataset["ruleA_n" .. tostring(i)] then
					ruleA_m = dataset["ruleA_m" .. tostring(i)]
					ri = i
					break
				end
			end
			
			local num1 = 100
			if self:rand(1,num1) <= ruleA_m then
				-- printx( 1 , "RuleA  return 111  ruleA_m =" , ruleA_m , "result.result =" , result.result)
				return result
			else
				result.result = false
				result.ruleIndex = ri
				result.m = ruleA_m
				-- printx( 1 , "RuleA  return 222  ruleA_m =" , ruleA_m , "ruleIndex =" , result.ruleIndex )
				return result
			end

		else
			result.result = false
			result.maxColorIndex = maxColorIndex
			-- printx( 1 , "RuleA  return 333  maxColorIndex =" , result.maxColorIndex )
			return result
		end
	else
		-- printx( 1 , "ProductItemDiffChangeLogic:changeColorRuleA   maxColorIndex ~= oringinColorIndex !!!!!!!!!!!!!!!!!!!!")
		result.result = true
		result.isSameColor = true
		result.oringinColorIndex = oringinColorIndex
	end

	return result
end

function ProductItemDiffChangeLogic:changeColorRuleB( maxColorIndex , colorLogList , dataset )
	-- printx( 1 , "ProductItemDiffChangeLogic:changeColorRuleB 1111" )
	local result = {}
	result.result = true

	local startIndex = #colorLogList
	local maxColorCount = 0

	for i = 1 , #colorLogList do
		
		local colorIndex = colorLogList[ startIndex - (i -1) ]
		if colorIndex == maxColorIndex then
			maxColorCount = maxColorCount + 1
		end

		-- printx( 1 , "ProductItemDiffChangeLogic:changeColorRuleB 222  maxColorCount" , maxColorCount )

		local needBreak = false
		local ri = 0 
		for ia = 1 , 4 do
			--printx( 1 , "ProductItemDiffChangeLogic:changeColorRuleB 333  i" , i ,dataset["ruleB_n" .. tostring(ia)] - 1 )
			if i <= dataset["ruleB_n" .. tostring(ia)] - 1 then
				-- printx( 1 , "ProductItemDiffChangeLogic:changeColorRuleB 444  maxColorCount" , maxColorCount , dataset["ruleB_m" .. tostring(ia)] - 1 )
				if maxColorCount >= dataset["ruleB_m" .. tostring(ia)] then
					-- printx( 1 , "ProductItemDiffChangeLogic:changeColorRuleB 333  ruleB_m" .. tostring(ia) .. " =" , dataset["ruleB_m" .. tostring(ia)] , "maxColorCount =" , maxColorCount , "Break !!!" )
					result.result = false --掉落非maxColor
					result.ruleIndex = ia
					result.maxColorIndex = maxColorIndex
					result.maxColorNum = maxColorCount
					needBreak = true
					break
				end
			end
		end

		if needBreak then
			break
		end
	end

	return result
end

function ProductItemDiffChangeLogic:changeColorRuleC( maxColorIndex , dataset )
	local result = {}
	result.result = true

	for i = 1 , 4 do

		local step = dataset["ruleC_n" .. tostring(i)]
		local maxCount = dataset["ruleC_m" .. tostring(i)]
		local maxColorCountInSomeSteps = 0

		for ia = 1 , step do
			local curStepData = self:getFalsifyStepData( self.context.realCostMove - (ia-1) )
			if curStepData then
				maxColorCountInSomeSteps = maxColorCountInSomeSteps + curStepData.changeColorCount
			end
		end
		if maxColorCountInSomeSteps >= maxCount then

			-- printx( 1 , "ProductItemDiffChangeLogic:changeColorRuleC 222  maxCount =" , maxCount , "maxColorCountInSomeSteps =" , maxColorCountInSomeSteps , "  Break!!!" )

			result.result = false --掉落非maxColor
			result.ruleIndex = i
			result.count = maxColorCountInSomeSteps
			return result 
		end
	end

	return result
end