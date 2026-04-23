local UBFConfig = {}

local TestItemConfig = {

	id = 1 ,
	name = "鸡窝" ,
	canFall = false ,
	canSwap = false ,
	canMatch = false ,
	canBlockLineEffect = false ,
	size = { r = 0 , c = 0 , width = 1 , height = 1 },
	layer = "ItemLayer" ,
	color = -1 ,
	level = 3 , 
	state = 1 ,
	fsm = "TestFSM" ,

	features = {

		[1] = {
			--#FeatureObject#
			eventTrigger = "onHit" ,
			conditions = {

				[1] = {
					--#ConditionGroup#
					mode = "AND" ,
					list = {

						[1] = {
							--#ConditionObject#
							conditionKey = { "eventContext" , "atkObject" , "attackSource" } ,
							op = "Equal" ,
							targetValue = "match"
						} ,

						[2] = {
							--#ConditionObject#
							conditionKey = { "eventContext" , "atkObject" , "attackType" } ,
							op = "Equal" ,
							targetValue = "around"
						}

					}
				}
			} ,
			atctions = {

				[1] = {
					atctionType = "setLevel" ,
					op = "ReduceEqual" ,
					value = 1
				}
			}
		} ,

		[2] = {
			--#FeatureObject#
			eventTrigger = "onFSMEnter" ,
			conditions = {

				[1] = {
					--#ConditionGroup#
					mode = "AND" ,
					list = {

						[1] = {
							--#ConditionObject#
							cdtKey = { "level" } ,
							op = "LessOrEqual" ,
							targetValue = 0
						}

					}
				}
			} ,
			atctions = {

				[1] = {
					atctionType = "createSameItems" ,
					op = "AddAndReplace" ,
					item = {} ,
					randomSelect = "config1" ,
					posList = nil
				}
			}
		}

	}
}

return UBFConfig