PayUserAdjustLogic = {}

function PayUserAdjustLogic:checkEnableAdjust( context )
	local payUserAdjustExpGroup = context.userGroupInfo.payUserAdjustExpGroup

	if payUserAdjustExpGroup == 0 then
		--对照组不激活
		return nil
	end

	if not context.isPayUser then
		--非付费用户不激活
		return nil
	end

	if not ( context.isMainLevel and context.levelId <= context.maxLevelId - LevelDifficultyAdjustTopLevelLength ) then
		--非主线关，顶部15以内关 不激活
		return nil
	end

	local failCounts = context.failCount + 1
	local resultData = nil

	if payUserAdjustExpGroup == 1 then

		if failCounts >= 70 then

			resultData = { 
							levelId = context.levelId ,
							mode = ProductItemDiffChangeMode.kAddColor , 
							ds = 5 , 
							reason = "payUserAdjustExp_" .. tostring(payUserAdjustExpGroup) .. "_" .. tostring(context.diffTag) 
						}

			return resultData

		elseif failCounts >= 60 then

			resultData = { 
							levelId = context.levelId ,
							mode = ProductItemDiffChangeMode.kAddColor , 
							ds = 4 , 
							reason = "payUserAdjustExp_" .. tostring(payUserAdjustExpGroup) .. "_" .. tostring(context.diffTag) 
						}

			return resultData

		elseif failCounts >= 50 then

			resultData = { 
							levelId = context.levelId ,
							mode = ProductItemDiffChangeMode.kAddColor , 
							ds = 3 , 
							reason = "payUserAdjustExp_" .. tostring(payUserAdjustExpGroup) .. "_" .. tostring(context.diffTag) 
						}

			return resultData

		end

	end

	return nil
	
end