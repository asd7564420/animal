HardLevelAdjustLogic = {}

function HardLevelAdjustLogic:getStrengthMap( hardLevelAdjustExpGroup , levelDiffcultFlag , maxTop15Level , last60DayPayAmount )

	if not last60DayPayAmount then
		return nil , 1
	end

	if last60DayPayAmount <= 13 then
		return nil , 2
	end

	if maxTop15Level
		or (not hardLevelAdjustExpGroup) 
		or (not levelDiffcultFlag) 
		or hardLevelAdjustExpGroup == 0 
		then
			return nil , 3
	end


	local dsMap = nil

	if hardLevelAdjustExpGroup <= 3 then
		if levelDiffcultFlag == LevelDiffcultFlag.kExceedinglyDifficult then

			if hardLevelAdjustExpGroup == 1 then
				--对于所有的超难关，不开启fuuu，颜色干预策略不变。
				dsMap = {
					[1] = 1 ,
					[2] = 2 ,
					[3] = 3 ,
					[4] = 4 ,
					[5] = 5 ,
					[6] = 6 
				}

				return dsMap
			elseif hardLevelAdjustExpGroup == 2 then
				-- 对于所有的超难关，禁用fuuu，且颜色干预强度普遍降一级，
				-- 即1阶过难不进行干预，2阶过难进行强度1干预，3阶过难进行强度2干预，4阶过难进行强度2.5干预，5阶过难后进行强度4级干预。
				dsMap = {
					[1] = 0 ,
					[2] = 1 ,
					[3] = 2 ,
					[4] = 6 ,
					[5] = 4 ,
					[6] = 6 
				}

				return dsMap
			elseif hardLevelAdjustExpGroup == 3 then
				-- 对于所有的超难关，fuuu策略不变，且颜色干预强度普遍降两级，
				-- 即1阶过难不进行干预，2阶过难也不进行干预，3阶过难进行强度1干预，4阶过难进行强度2干预，5阶过难后进行强度2.5级干预。
				dsMap = {
					[1] = 0 ,
					[2] = 0 ,
					[3] = 1 ,
					[4] = 2 ,
					[5] = 6 ,
					[6] = 6 
				}

				return dsMap
			end
		else
			return nil , 4
		end
	else
		if levelDiffcultFlag ~= LevelDiffcultFlag.kNormal then

			if hardLevelAdjustExpGroup == 4 then
				-- 对于所有的难关和超难关，不开启fuuu，颜色干预策略不变。
				dsMap = {
					[1] = 1 ,
					[2] = 2 ,
					[3] = 3 ,
					[4] = 4 ,
					[5] = 5 ,
					[6] = 6 
				}

				return dsMap
			elseif hardLevelAdjustExpGroup == 5 then
				-- 对于所有的难关和超难关，禁用fuuu，且颜色干预强度普遍降一级，
				-- 即1阶过难不进行干预，2阶过难进行强度1干预，3阶过难进行强度2干预，4阶过难进行强度2.5干预，5阶过难后进行强度4级干预。
				dsMap = {
					[1] = 0 ,
					[2] = 1 ,
					[3] = 2 ,
					[4] = 6 ,
					[5] = 4 ,
					[6] = 6 
				}

				return dsMap
			elseif hardLevelAdjustExpGroup == 6 then
				-- 对于所有的难关和超难关，fuuu策略不变，且颜色干预强度普遍降两级，
				-- 即1阶过难不进行干预，2阶过难也不进行干预，3阶过难进行强度1干预，4阶过难进行强度2干预，5阶过难后进行强度2.5级干预。
				dsMap = {
					[1] = 0 ,
					[2] = 0 ,
					[3] = 1 ,
					[4] = 2 ,
					[5] = 6 ,
					[6] = 6 
				}

				return dsMap
			end
		else
			return nil , 5
		end
	end

	return nil , 6
end