--[[
	
####################################################################################################
#####################################################LLLLjj#########################################
##################################################iiiiLLLLLLj#######################################
################################################ft  ttLLLLLLLj######################################
###############################################LttttGGGGLLLLLff#####################################
###############################################jjjjGGGGGGGGGGff#####################################
##############################################DjjjDDDGGGGGGGfff#####################################
##############################################GffDDDDDDDDDDLLL######################################
##############################################EGGEEEDDDDDLLL########################################
##############################################EGGEEEEEEGG###########################################
############################################,.:DDEEEEDG::,##########################################
#########################################,.:::::EEEED.::::::########################################
#######################################:.::::::::EEE.:::::::::######################################
#####################################.::::::::::::;:::::::::::::####################################
###################################.:::::::. ::::::::::::::::::::,##################################
#################################:::,:::     ::::::::::::::::::::::#################################
###############################:::,,,,      :::::::::::::::::::,,,,::###############################
#############################,.:,,,,       ::::::::::::::::,,,,,,,,,::,#############################
############################.::,,,       :::::::::::::::::::,,,,,,,,,,::############################
##########################,::,,,,       :::::::::::::::::::::,,,,,,,,,,::###########################
#########################.:,,,,....   :::::::::::::::::::::::::,,,,,,,,,::,#########################
#######################,::,,,........:::::::::::::::::::::::::::,,,,,,,,,,::########################
######################.:,;,,::::...::::::::::::::::::::::::::::::,,,,,,,,,,,:#######################
####################,:,;;;:::::...:::::::::::::::::::::::::::::::::,,,,,,,;;,:,#####################
###################.,,;;;,,,,:::iiiii:::::::::::::::::::::::::iiii,:;;;;;;;;;,,,####################
##################:,,;;,,,,,,::::::::::::::::::::::::::::::::::::::::;;;;;;;;;,,,###################
################,,,;;;;;;,,,:,,:::::::::::::::::::::::::::::::::::::::;;;;;;;;;,,,##################
###############:,,;;;;;;;;;:ffEDDDff::::::::::::::::::::::::::::ffEEDDff;;;;;;;;,,,#################
##############:;,;;;;;;;;;ff   ###GGf,,,,,:::::::ii::::::::::,,f   ###GGff;;;;;;;;,,,###############
#############:;;ii;i;;;;;,fED######GLf,,,,,,,,,i;;,ii,,,,,,,,,fED######GLf;;;;;;;;;,,,##############
############,;;iiiiiiiii,,fDD#####jLLf,,,,,,,t;;,,,tttt,,,,,,,fDD#####KLLf;;;;;;ii;;;;,#############
##########,;;;iiiiiiiii;;;;fGGG##LLLf,,,,,,j;,,,,..ttttt,,,,,,,fGGG##LLLf;,iiiiiiiii;;;;############
#########,;;;iiiiiiiiii;;;;;fffLLfff,,,,,,jjj,,,,  jjjjjji,,,,,,ffLLLLff;;;;iiiiiiiii;;;;###########
########,;;;iiiiiiiitiiiiii;;;;;,,,,,,,,,,;ffDDDDDDDDDLjj,,,,,,,;;;;;;;;;;;;;iiiiiiiii;;;;##########
########,i;iiiiiiiiitiiiiiii;;;;;;;;;;,,,,,fftttttttttfff,,,,,;;;;;iiiiiiiii;iiiiiiiii;;;;,#########
#######:iiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;ffftiiiiffff;;;;;;;;;;;iiiiiiiii;;iiiiiiiii;;;i#########
#######;iiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;tttttttttt;;;;;;;;;;;;;;;iiiii;;;;iiiiiiii;;;,i########
######,iiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;iiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;iiiiiiii;;;,i########
######,iiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;iiiiiiii;;;,,########
#######iiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;iiiiiiiiiiiii;;;,,########
#######iiittiiiiiiiiiiiiiiiiiiiiiiii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;iiiiiiiiiiiiiiiiiii;;;,,,########
########iiittttttttiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;,,,,########
#########iiittttttttttttiiittttiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;;;,,,,#########
###########iiitttttttttttttttttttttttttttiiiiiittttiiiiiiiiiiiiiiiittttttttttiiiiii;;;,,,###########
#############,tiiittttttttttttttttttttttttttttttttiittttttttttttttttttttttiiiiii;;;;;,;#############
##################;tiiiiittttttttttttttttttttttttttttttttttttttttttttiiiiiiii;;;;;;#################
##########################,,;itttttiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;,,#########################
####################################################################################################
####################################################################################################

]]

ProductItemDiffChangeFalsifyConfig = {
	
	[ProductItemDiffChangeMode.kDropEff] = {
		--全局随机掉落特效

		kNormalLevel = {
			[1] = {
				n0 = 30 ,
				m1 = 2 ,
				n1 = 5 ,
				m2 = 3 ,
				n2 = 1 ,
				m3 = 4 ,
				n3 = 0 ,
				m4 = 9999 ,
				n4 = 0 ,
			} ,

			[2] = {
				n0 = 50 ,
				m1 = 2 ,
				n1 = 20 ,
				m2 = 3 ,
				n2 = 1 ,
				m3 = 4 ,
				n3 = 0 ,
				m4 = 9999 ,
				n4 = 0 ,
			} ,

			[3] = {
				n0 = 100 ,
				m1 = 2 ,
				n1 = 50 ,
				m2 = 3 ,
				n2 = 1 ,
				m3 = 4 ,
				n3 = 0 ,
				m4 = 9999 ,
				n4 = 0 ,
			} ,
		}
		
	} ,
	
	[ProductItemDiffChangeMode.kDropEffAndBird] = {
		--全局随机掉落特效和魔力鸟

		kNormalLevel = {
			[1] = {
				n1 = 20 ,
				m1 = 1 ,
			} ,

			[2] = {
				n1 = 20 ,
				m1 = 1 ,
			} ,

			[3] = {
				n1 = 60 ,
				m1 = 1 ,
			} ,
		}
		
	} ,
	
	[ProductItemDiffChangeMode.kAddColor] = {
		--全局增加单色概率

		kNormalLevel = {
			[1] = {
			    n1 = 20 ,

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 30,
				ruleA_n2 = 5,
				ruleA_m2 = 25,
				ruleA_n3 = 10,
				ruleA_m3 = 20,
				ruleA_n4 = 9999,
				ruleA_m4 = 20,

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
				ruleC_m1 = 10,
				ruleC_n2 = 2,
				ruleC_m2 = 15,
				ruleC_n3 = 3,
				ruleC_m3 = 20,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,

			} ,

			[2] = {
				n1 = 30 ,

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 40,
				ruleA_n2 = 5,
				ruleA_m2 = 35,
				ruleA_n3 = 10,
				ruleA_m3 = 30,
				ruleA_n4 = 9999,
				ruleA_m4 = 30,

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
				ruleC_m1 = 10,
				ruleC_n2 = 2,
				ruleC_m2 = 15,
				ruleC_n3 = 3,
				ruleC_m3 = 30,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,
			} ,

			[3] = {
				n1 = 40 ,

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 60,
				ruleA_n2 = 5,
				ruleA_m2 = 55,
				ruleA_n3 = 10,
				ruleA_m3 = 50,
				ruleA_n4 = 9999,
				ruleA_m4 = 40,

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
				ruleC_m1 = 15,
				ruleC_n2 = 2,
				ruleC_m2 = 20,
				ruleC_n3 = 3,
				ruleC_m3 = 40,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,
			} ,

			[4] = {

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 65,
				ruleA_n2 = 5,
				ruleA_m2 = 60,
				ruleA_n3 = 10,
				ruleA_m3 = 50,
				ruleA_n4 = 9999,
				ruleA_m4 = 40,

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
				ruleC_m2 = 25,
				ruleC_n3 = 3,
				ruleC_m3 = 40,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,
			} ,

			[5] = {

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
			} ,

			[6] = {

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 50,
				ruleA_n2 = 5,
				ruleA_m2 = 45,
				ruleA_n3 = 10,
				ruleA_m3 = 40,
				ruleA_n4 = 9999,
				ruleA_m4 = 35,

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
				ruleC_m1 = 12,
				ruleC_n2 = 2,
				ruleC_m2 = 18,
				ruleC_n3 = 3,
				ruleC_m3 = 35,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,
			} ,

			[7] = {

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 85,
				ruleA_n2 = 5,
				ruleA_m2 = 75,
				ruleA_n3 = 10,
				ruleA_m3 = 65,
				ruleA_n4 = 9999,
				ruleA_m4 = 50,

				--ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 5,
				ruleB_n2 = 10,
				ruleB_m2 = 8,
				ruleB_n3 = 15,
				ruleB_m3 = 10,
				ruleB_n4 = 20,
				ruleB_m4 = 15,

				--ruleC 全局掉落口，最近n步之内，目标色（C色）的干预次数不超过m个
				ruleC_n1 = 1,
				ruleC_m1 = 35,
				ruleC_n2 = 2,
				ruleC_m2 = 50,
				ruleC_n3 = 3,
				ruleC_m3 = 70,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,
			} ,
		},


		kOldVersion = {
			[1] = {

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 10,
				ruleA_m1 = 20,
				ruleA_n2 = 15,
				ruleA_m2 = 20,
				ruleA_n3 = 20,
				ruleA_m3 = 20,
				ruleA_n4 = 9999,
				ruleA_m4 = 20,

				--ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 9999,
				ruleB_n2 = 10,
				ruleB_m2 = 9999,
				ruleB_n3 = 15,
				ruleB_m3 = 9999,
				ruleB_n4 = 20,
				ruleB_m4 = 9999,

				--ruleC 全局掉落口，最近n步之内，目标色（C色）的干预次数不超过m个
				ruleC_n1 = 1,
				ruleC_m1 = 99999,
				ruleC_n2 = 2,
				ruleC_m2 = 99999,
				ruleC_n3 = 3,
				ruleC_m3 = 99999,
				ruleC_n4 = 5,
				ruleC_m4 = 99999,

			} ,

			[2] = {
				n1 = 30 ,

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 10,
				ruleA_m1 = 30,
				ruleA_n2 = 15,
				ruleA_m2 = 30,
				ruleA_n3 = 20,
				ruleA_m3 = 30,
				ruleA_n4 = 9999,
				ruleA_m4 = 30,

				--ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 9999,
				ruleB_n2 = 10,
				ruleB_m2 = 9999,
				ruleB_n3 = 15,
				ruleB_m3 = 9999,
				ruleB_n4 = 20,
				ruleB_m4 = 9999,

				--ruleC 全局掉落口，最近n步之内，目标色（C色）的干预次数不超过m个
				ruleC_n1 = 1,
				ruleC_m1 = 99999,
				ruleC_n2 = 2,
				ruleC_m2 = 99999,
				ruleC_n3 = 3,
				ruleC_m3 = 99999,
				ruleC_n4 = 5,
				ruleC_m4 = 99999,
			} ,

			[3] = {
				n1 = 40 ,

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 10,
				ruleA_m1 = 40,
				ruleA_n2 = 15,
				ruleA_m2 = 40,
				ruleA_n3 = 20,
				ruleA_m3 = 40,
				ruleA_n4 = 9999,
				ruleA_m4 = 40,

				--ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 9999,
				ruleB_n2 = 10,
				ruleB_m2 = 9999,
				ruleB_n3 = 15,
				ruleB_m3 = 9999,
				ruleB_n4 = 20,
				ruleB_m4 = 9999,

				--ruleC 全局掉落口，最近n步之内，目标色（C色）的干预次数不超过m个
				ruleC_n1 = 1,
				ruleC_m1 = 99999,
				ruleC_n2 = 2,
				ruleC_m2 = 99999,
				ruleC_n3 = 3,
				ruleC_m3 = 99999,
				ruleC_n4 = 5,
				ruleC_m4 = 99999,
			} ,
		}
	} ,

	[ProductItemDiffChangeMode.kAIAddColor] = {
		--智能增加单色概率

		kNormalLevel = {
			[1] = {--弱
			    n1 = 15 ,

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 30,
				ruleA_n2 = 5,
				ruleA_m2 = 20,
				ruleA_n3 = 7,
				ruleA_m3 = 15,
				ruleA_n4 = 9999,
				ruleA_m4 = 15,

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
				ruleC_m1 = 10,
				ruleC_n2 = 2,
				ruleC_m2 = 15,
				ruleC_n3 = 3,
				ruleC_m3 = 20,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,

			} ,

			[2] = {--中
				n1 = 40 ,

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 60,
				ruleA_n2 = 5,
				ruleA_m2 = 50,
				ruleA_n3 = 10,
				ruleA_m3 = 40,
				ruleA_n4 = 9999,
				ruleA_m4 = 40,

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
				ruleC_m1 = 15,
				ruleC_n2 = 2,
				ruleC_m2 = 20,
				ruleC_n3 = 3,
				ruleC_m3 = 40,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,
			} ,

			[3] = {--强
				n1 = 50 ,

				--ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 80,
				ruleA_n2 = 5,
				ruleA_m2 = 70,
				ruleA_n3 = 10,
				ruleA_m3 = 60,
				ruleA_n4 = 9999,
				ruleA_m4 = 60,

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
				ruleC_m1 = 15,
				ruleC_n2 = 2,
				ruleC_m2 = 20,
				ruleC_n3 = 3,
				ruleC_m3 = 40,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,
			} ,
		},


		kOldVersion = {},
	} ,

	[ProductItemDiffChangeMode.kDecreaseColor] = {
		--智能增加单色概率

		kNormalLevel = {
			[1] = {--弱
			    
			    --ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,
				--[[
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,
				]]

				--ruleD 
				ruleD_weight_a1 = 10,
				ruleD_weight_a2 = 10,
				ruleD_weight_b2 = {2,1},
				ruleD_weight_b3 = {3,2,1},
				ruleD_weight_b4 = {4,3,2,1},
				ruleD_weight_b5 = {5,4,3,2,1},
				ruleD_weight_b6 = {6,5,4,3,2,1},

				--ruleE  采样率，数字越小，开销越大，效果越强
				ruleE = 20,

			} ,

			[2] = {--较弱
			    
			    --ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,

				--ruleD 
				ruleD_weight_a1 = 12,
				ruleD_weight_a2 = 10,
				ruleD_weight_b2 = {2,1},
				ruleD_weight_b3 = {3,2,1},
				ruleD_weight_b4 = {4,3,2,1},
				ruleD_weight_b5 = {5,4,3,2,1},
				ruleD_weight_b6 = {6,5,4,3,2,1},

				--ruleE  采样率，数字越小，开销越大，效果越强
				ruleE = 15,

			} ,

			[3] = {--中
			    
			    --ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,

				--ruleD 
				ruleD_weight_a1 = 15,
				ruleD_weight_a2 = 10,
				ruleD_weight_b2 = {2,1},
				ruleD_weight_b3 = {3,2,1},
				ruleD_weight_b4 = {4,3,2,1},
				ruleD_weight_b5 = {5,4,3,2,1},
				ruleD_weight_b6 = {6,5,4,3,2,1},

				--ruleE  采样率，数字越小，开销越大，效果越强
				ruleE = 10,

			} ,

			[4] = {--较强
			    
			    --ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,

				--ruleD 
				ruleD_weight_a1 = 18,
				ruleD_weight_a2 = 10,
				ruleD_weight_b2 = {2,1},
				ruleD_weight_b3 = {3,2,1},
				ruleD_weight_b4 = {4,3,2,1},
				ruleD_weight_b5 = {5,4,3,2,1},
				ruleD_weight_b6 = {6,5,4,3,2,1},

				--ruleE  采样率，数字越小，开销越大，效果越强
				ruleE = 5,

			} ,

			[5] = {--强
			    
			    --ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,

				--ruleD 
				ruleD_weight_a1 = 20,
				ruleD_weight_a2 = 10,
				ruleD_weight_b2 = {2,1},
				ruleD_weight_b3 = {3,2,1},
				ruleD_weight_b4 = {4,3,2,1},
				ruleD_weight_b5 = {5,4,3,2,1},
				ruleD_weight_b6 = {6,5,4,3,2,1},

				--ruleE  采样率，数字越小，开销越大，效果越强
				ruleE = 0,

			} ,
		},
	} ,

	[ProductItemDiffChangeMode.kAIDecreaseColor] = {
		--智能增加单色概率

		kNormalLevel = {
			[1] = {--弱
			    
			    --ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,

				--ruleD 
				ruleD_weight_a1 = 10,
				ruleD_weight_a2 = 10,
				ruleD_weight_b2 = {2,1},
				ruleD_weight_b3 = {3,2,1},
				ruleD_weight_b4 = {4,3,2,1},
				ruleD_weight_b5 = {5,4,3,2,1},
				ruleD_weight_b6 = {6,5,4,3,2,1},

				--ruleE  采样率，数字越小，开销越大，效果越强
				ruleE = 20,

			} ,

			[2] = {--中
			    
			    --ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,

				--ruleD 
				ruleD_weight_a1 = 15,
				ruleD_weight_a2 = 10,
				ruleD_weight_b2 = {2,1},
				ruleD_weight_b3 = {3,2,1},
				ruleD_weight_b4 = {4,3,2,1},
				ruleD_weight_b5 = {5,4,3,2,1},
				ruleD_weight_b6 = {6,5,4,3,2,1},

				--ruleE  采样率，数字越小，开销越大，效果越强
				ruleE = 10,

			} ,

			[3] = {--强
			    
			    --ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,

				--ruleD 
				ruleD_weight_a1 = 20,
				ruleD_weight_a2 = 10,
				ruleD_weight_b2 = {2,1},
				ruleD_weight_b3 = {3,2,1},
				ruleD_weight_b4 = {4,3,2,1},
				ruleD_weight_b5 = {5,4,3,2,1},
				ruleD_weight_b6 = {6,5,4,3,2,1},

				--ruleE  采样率，数字越小，开销越大，效果越强
				ruleE = 0,

			} ,
		},
	} ,

	[ProductItemDiffChangeMode.kAIADColor] = {
		--智能增加单色概率

		kNormalLevel = {
			[1] = {--弱
			    
			    --ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 30,
				ruleA_n2 = 5,
				ruleA_m2 = 20,
				ruleA_n3 = 7,
				ruleA_m3 = 15,
				ruleA_n4 = 9999,
				ruleA_m4 = 15,

				--ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,

				--ruleC 全局掉落口，最近n步之内，目标色（C色）的干预次数不超过m个
				ruleC_n1 = 1,
				ruleC_m1 = 10,
				ruleC_n2 = 2,
				ruleC_m2 = 15,
				ruleC_n3 = 3,
				ruleC_m3 = 20,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,

				--ruleD 
				ruleD_weight_a1 = 10,
				ruleD_weight_a2 = 10,
				ruleD_weight_b2 = {2,1},
				ruleD_weight_b3 = {3,2,1},
				ruleD_weight_b4 = {4,3,2,1},
				ruleD_weight_b5 = {5,4,3,2,1},
				ruleD_weight_b6 = {6,5,4,3,2,1},

				--ruleE  采样率，数字越小，开销越大，效果越强
				ruleE = 20,

			} ,

			[2] = {--中
			    
			    --ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 60,
				ruleA_n2 = 5,
				ruleA_m2 = 50,
				ruleA_n3 = 10,
				ruleA_m3 = 40,
				ruleA_n4 = 9999,
				ruleA_m4 = 40,

				--ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,

				--ruleC 全局掉落口，最近n步之内，目标色（C色）的干预次数不超过m个
				ruleC_n1 = 1,
				ruleC_m1 = 15,
				ruleC_n2 = 2,
				ruleC_m2 = 20,
				ruleC_n3 = 3,
				ruleC_m3 = 40,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,

				--ruleD 
				ruleD_weight_a1 = 15,
				ruleD_weight_a2 = 10,
				ruleD_weight_b2 = {2,1},
				ruleD_weight_b3 = {3,2,1},
				ruleD_weight_b4 = {4,3,2,1},
				ruleD_weight_b5 = {5,4,3,2,1},
				ruleD_weight_b6 = {6,5,4,3,2,1},

				--ruleE  采样率，数字越小，开销越大，效果越强
				ruleE = 10,

			} ,

			[3] = {--强
			    
			    --ruleA 每次掉落一个有颜色的元素时，如果本回合已经掉落的目标色（C色）小于等于n，则有m的概率将其强行变为目标色（C色）
				ruleA_n1 = 3,
				ruleA_m1 = 80,
				ruleA_n2 = 5,
				ruleA_m2 = 70,
				ruleA_n3 = 10,
				ruleA_m3 = 60,
				ruleA_n4 = 9999,
				ruleA_m4 = 60,

				--ruleB 单个掉落口，每掉落n个元素，目标色（C色）的数量不超过m个
				ruleB_n1 = 5,
				ruleB_m1 = 3,
				ruleB_n2 = 10,
				ruleB_m2 = 5,
				ruleB_n3 = 15,
				ruleB_m3 = 8,
				ruleB_n4 = 20,
				ruleB_m4 = 12,

				--ruleC 全局掉落口，最近n步之内，目标色（C色）的干预次数不超过m个
				ruleC_n1 = 1,
				ruleC_m1 = 15,
				ruleC_n2 = 2,
				ruleC_m2 = 20,
				ruleC_n3 = 3,
				ruleC_m3 = 40,
				ruleC_n4 = 5,
				ruleC_m4 = 9999,

				--ruleD 
				ruleD_weight_a1 = 20,
				ruleD_weight_a2 = 10,
				ruleD_weight_b2 = {2,1},
				ruleD_weight_b3 = {3,2,1},
				ruleD_weight_b4 = {4,3,2,1},
				ruleD_weight_b5 = {5,4,3,2,1},
				ruleD_weight_b6 = {6,5,4,3,2,1},

				--ruleE  采样率，数字越小，开销越大，效果越强
				ruleE = 0,

			} ,
		},
	} ,

}

LevelDiffcultyAdjustScoreLimitConfig_old = {
			--连消加成
			comboScaleThreshold = 10 ,
			comboScaleAttenuation = 18 ,
			--小动物
			numCountThreshold = 3 ,
			numCountAttenuation = 6 ,
			--冰块
			lightCountThreshold = 8 ,
			lightCountAttenuation = 14 ,
			--水晶球
			numCountCrystalThreshold = 6 ,
			numCountCrystalAttenuation = 10 ,
			--气球
			numCountBalloonThreshold = 3 ,
			numCountBalloonAttenuation = 6 ,
			--流沙
			numSandThreshold = 3 ,
			numSandAttenuation = 6 ,
			--闪电鸟
			numTotemsThreshold = 3 ,
			numTotemsAttenuation = 6 ,
			--兔子
			numCountRabbitThreshold = 3 ,
			numCountRabbitAttenuation = 6 ,
			--火箭
			numRocketThreshold = 3 ,
			numRocketAttenuation = 6 ,
		}

LevelDiffcultyAdjustScoreLimitConfig = {
	
	[1] = {
		[1] = {
			--连消加成
			comboScaleThreshold = 28 ,
			comboScaleAttenuation = 40 ,
			--小动物
			numCountThreshold = 10 ,
			numCountAttenuation = 15 ,
			--冰块
			lightCountThreshold = 22 ,
			lightCountAttenuation = 32 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 20 ,
			--气球
			numCountBalloonThreshold = 6 ,
			numCountBalloonAttenuation = 12 ,
			--流沙
			numSandThreshold = 6 ,
			numSandAttenuation = 12 ,
			--闪电鸟
			numTotemsThreshold = 6 ,
			numTotemsAttenuation = 12 ,
			--兔子
			numCountRabbitThreshold = 6 ,
			numCountRabbitAttenuation = 12 ,
			--火箭
			numRocketThreshold = 6 ,
			numRocketAttenuation = 12 ,
		} ,	
		[2] = {
			--连消加成
			comboScaleThreshold = 28 ,
			comboScaleAttenuation = 40 ,
			--小动物
			numCountThreshold = 10 ,
			numCountAttenuation = 15 ,
			--冰块
			lightCountThreshold = 22 ,
			lightCountAttenuation = 32 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 20 ,
			--气球
			numCountBalloonThreshold = 6 ,
			numCountBalloonAttenuation = 12 ,
			--流沙
			numSandThreshold = 6 ,
			numSandAttenuation = 12 ,
			--闪电鸟
			numTotemsThreshold = 6 ,
			numTotemsAttenuation = 12 ,
			--兔子
			numCountRabbitThreshold = 6 ,
			numCountRabbitAttenuation = 12 ,
			--火箭
			numRocketThreshold = 6 ,
			numRocketAttenuation = 12 ,
		} ,	
		[3] = {
			--连消加成
			comboScaleThreshold = 28 ,
			comboScaleAttenuation = 40 ,
			--小动物
			numCountThreshold = 10 ,
			numCountAttenuation = 15 ,
			--冰块
			lightCountThreshold = 22 ,
			lightCountAttenuation = 32 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 20 ,
			--气球
			numCountBalloonThreshold = 6 ,
			numCountBalloonAttenuation = 12 ,
			--流沙
			numSandThreshold = 6 ,
			numSandAttenuation = 12 ,
			--闪电鸟
			numTotemsThreshold = 6 ,
			numTotemsAttenuation = 12 ,
			--兔子
			numCountRabbitThreshold = 6 ,
			numCountRabbitAttenuation = 12 ,
			--火箭
			numRocketThreshold = 6 ,
			numRocketAttenuation = 12 ,
		} ,	
	} ,


	[2] = {
		[1] = {
			--连消加成
			comboScaleThreshold = 20 ,
			comboScaleAttenuation = 35 ,
			--小动物
			numCountThreshold = 6 ,
			numCountAttenuation = 12 ,
			--冰块
			lightCountThreshold = 18 ,
			lightCountAttenuation = 28 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 18 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 10 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 10 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 10 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 10 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 10 ,
		} ,	
		[2] = {
			--连消加成
			comboScaleThreshold = 20 ,
			comboScaleAttenuation = 35 ,
			--小动物
			numCountThreshold = 6 ,
			numCountAttenuation = 12 ,
			--冰块
			lightCountThreshold = 18 ,
			lightCountAttenuation = 28 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 18 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 10 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 10 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 10 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 10 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 10 ,
		} ,	
		[3] = {
			--连消加成
			comboScaleThreshold = 20 ,
			comboScaleAttenuation = 35 ,
			--小动物
			numCountThreshold = 6 ,
			numCountAttenuation = 12 ,
			--冰块
			lightCountThreshold = 18 ,
			lightCountAttenuation = 28 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 18 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 10 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 10 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 10 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 10 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 10 ,
		} ,	
	} ,


	[3] = {
		[1] = {
			--连消加成
			comboScaleThreshold = 15 ,
			comboScaleAttenuation = 27 ,
			--小动物
			numCountThreshold = 4 ,
			numCountAttenuation = 9 ,
			--冰块
			lightCountThreshold = 12 ,
			lightCountAttenuation = 21 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 15 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 9 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 9 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 9 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 9 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 9 ,
		} ,	
		[2] = {
			--连消加成
			comboScaleThreshold = 15 ,
			comboScaleAttenuation = 27 ,
			--小动物
			numCountThreshold = 4 ,
			numCountAttenuation = 9 ,
			--冰块
			lightCountThreshold = 12 ,
			lightCountAttenuation = 21 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 15 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 9 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 9 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 9 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 9 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 9 ,
		} ,	
		[3] = {
			--连消加成
			comboScaleThreshold = 15 ,
			comboScaleAttenuation = 27 ,
			--小动物
			numCountThreshold = 4 ,
			numCountAttenuation = 9 ,
			--冰块
			lightCountThreshold = 12 ,
			lightCountAttenuation = 21 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 15 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 9 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 9 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 9 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 9 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 9 ,
		} ,	
	} ,


	[4] = {
		[1] = {
			--连消加成
			comboScaleThreshold = 12 ,
			comboScaleAttenuation = 22 ,
			--小动物
			numCountThreshold = 4 ,
			numCountAttenuation = 7 ,
			--冰块
			lightCountThreshold = 10 ,
			lightCountAttenuation = 17 ,
			--水晶球
			numCountCrystalThreshold = 8 ,
			numCountCrystalAttenuation = 13 ,
			--气球
			numCountBalloonThreshold = 4 ,
			numCountBalloonAttenuation = 7 ,
			--流沙
			numSandThreshold = 4 ,
			numSandAttenuation = 7 ,
			--闪电鸟
			numTotemsThreshold = 4 ,
			numTotemsAttenuation = 7 ,
			--兔子
			numCountRabbitThreshold = 4 ,
			numCountRabbitAttenuation = 7 ,
			--火箭
			numRocketThreshold = 4 ,
			numRocketAttenuation = 7 ,
		} ,	
		[2] = {
			--连消加成
			comboScaleThreshold = 12 ,
			comboScaleAttenuation = 22 ,
			--小动物
			numCountThreshold = 4 ,
			numCountAttenuation = 7 ,
			--冰块
			lightCountThreshold = 10 ,
			lightCountAttenuation = 17 ,
			--水晶球
			numCountCrystalThreshold = 8 ,
			numCountCrystalAttenuation = 13 ,
			--气球
			numCountBalloonThreshold = 4 ,
			numCountBalloonAttenuation = 7 ,
			--流沙
			numSandThreshold = 4 ,
			numSandAttenuation = 7 ,
			--闪电鸟
			numTotemsThreshold = 4 ,
			numTotemsAttenuation = 7 ,
			--兔子
			numCountRabbitThreshold = 4 ,
			numCountRabbitAttenuation = 7 ,
			--火箭
			numRocketThreshold = 4 ,
			numRocketAttenuation = 7 ,
		} ,	
		[3] = {
			--连消加成
			comboScaleThreshold = 12 ,
			comboScaleAttenuation = 22 ,
			--小动物
			numCountThreshold = 4 ,
			numCountAttenuation = 7 ,
			--冰块
			lightCountThreshold = 10 ,
			lightCountAttenuation = 17 ,
			--水晶球
			numCountCrystalThreshold = 8 ,
			numCountCrystalAttenuation = 13 ,
			--气球
			numCountBalloonThreshold = 4 ,
			numCountBalloonAttenuation = 7 ,
			--流沙
			numSandThreshold = 4 ,
			numSandAttenuation = 7 ,
			--闪电鸟
			numTotemsThreshold = 4 ,
			numTotemsAttenuation = 7 ,
			--兔子
			numCountRabbitThreshold = 4 ,
			numCountRabbitAttenuation = 7 ,
			--火箭
			numRocketThreshold = 4 ,
			numRocketAttenuation = 7 ,
		} ,	
	} ,


	[5] = {
		[1] = {
			--连消加成
			comboScaleThreshold = 10 ,
			comboScaleAttenuation = 18 ,
			--小动物
			numCountThreshold = 3 ,
			numCountAttenuation = 6 ,
			--冰块
			lightCountThreshold = 8 ,
			lightCountAttenuation = 14 ,
			--水晶球
			numCountCrystalThreshold = 6 ,
			numCountCrystalAttenuation = 10 ,
			--气球
			numCountBalloonThreshold = 3 ,
			numCountBalloonAttenuation = 6 ,
			--流沙
			numSandThreshold = 3 ,
			numSandAttenuation = 6 ,
			--闪电鸟
			numTotemsThreshold = 3 ,
			numTotemsAttenuation = 6 ,
			--兔子
			numCountRabbitThreshold = 3 ,
			numCountRabbitAttenuation = 6 ,
			--火箭
			numRocketThreshold = 3 ,
			numRocketAttenuation = 6 ,
		} ,	
		[2] = {
			--连消加成
			comboScaleThreshold = 10 ,
			comboScaleAttenuation = 18 ,
			--小动物
			numCountThreshold = 3 ,
			numCountAttenuation = 6 ,
			--冰块
			lightCountThreshold = 8 ,
			lightCountAttenuation = 14 ,
			--水晶球
			numCountCrystalThreshold = 6 ,
			numCountCrystalAttenuation = 10 ,
			--气球
			numCountBalloonThreshold = 3 ,
			numCountBalloonAttenuation = 6 ,
			--流沙
			numSandThreshold = 3 ,
			numSandAttenuation = 6 ,
			--闪电鸟
			numTotemsThreshold = 3 ,
			numTotemsAttenuation = 6 ,
			--兔子
			numCountRabbitThreshold = 3 ,
			numCountRabbitAttenuation = 6 ,
			--火箭
			numRocketThreshold = 3 ,
			numRocketAttenuation = 6 ,
		} ,	
		[3] = {
			--连消加成
			comboScaleThreshold = 10 ,
			comboScaleAttenuation = 18 ,
			--小动物
			numCountThreshold = 3 ,
			numCountAttenuation = 6 ,
			--冰块
			lightCountThreshold = 8 ,
			lightCountAttenuation = 14 ,
			--水晶球
			numCountCrystalThreshold = 6 ,
			numCountCrystalAttenuation = 10 ,
			--气球
			numCountBalloonThreshold = 3 ,
			numCountBalloonAttenuation = 6 ,
			--流沙
			numSandThreshold = 3 ,
			numSandAttenuation = 6 ,
			--闪电鸟
			numTotemsThreshold = 3 ,
			numTotemsAttenuation = 6 ,
			--兔子
			numCountRabbitThreshold = 3 ,
			numCountRabbitAttenuation = 6 ,
			--火箭
			numRocketThreshold = 3 ,
			numRocketAttenuation = 6 ,
		} ,	
	} ,

	[6] = {
		[1] = {
			--连消加成
			comboScaleThreshold = 18 ,
			comboScaleAttenuation = 31 ,
			--小动物
			numCountThreshold = 5 ,
			numCountAttenuation = 10 ,
			--冰块
			lightCountThreshold = 15 ,
			lightCountAttenuation = 25 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 16 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 10 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 10 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 10 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 10 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 10 ,
		} ,	
		[2] = {
			--连消加成
			comboScaleThreshold = 18 ,
			comboScaleAttenuation = 31 ,
			--小动物
			numCountThreshold = 5 ,
			numCountAttenuation = 10 ,
			--冰块
			lightCountThreshold = 15 ,
			lightCountAttenuation = 25 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 16 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 10 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 10 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 10 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 10 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 10 ,
		} ,	
		[3] = {
			--连消加成
			comboScaleThreshold = 18 ,
			comboScaleAttenuation = 31 ,
			--小动物
			numCountThreshold = 5 ,
			numCountAttenuation = 10 ,
			--冰块
			lightCountThreshold = 15 ,
			lightCountAttenuation = 25 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 16 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 10 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 10 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 10 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 10 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 10 ,
		} ,	
	} ,

	[7] = {
		[1] = {
			--连消加成
			comboScaleThreshold = 18 ,
			comboScaleAttenuation = 31 ,
			--小动物
			numCountThreshold = 5 ,
			numCountAttenuation = 10 ,
			--冰块
			lightCountThreshold = 15 ,
			lightCountAttenuation = 25 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 16 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 10 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 10 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 10 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 10 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 10 ,
		} ,	
		[2] = {
			--连消加成
			comboScaleThreshold = 18 ,
			comboScaleAttenuation = 31 ,
			--小动物
			numCountThreshold = 5 ,
			numCountAttenuation = 10 ,
			--冰块
			lightCountThreshold = 15 ,
			lightCountAttenuation = 25 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 16 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 10 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 10 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 10 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 10 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 10 ,
		} ,	
		[3] = {
			--连消加成
			comboScaleThreshold = 18 ,
			comboScaleAttenuation = 31 ,
			--小动物
			numCountThreshold = 5 ,
			numCountAttenuation = 10 ,
			--冰块
			lightCountThreshold = 15 ,
			lightCountAttenuation = 25 ,
			--水晶球
			numCountCrystalThreshold = 10 ,
			numCountCrystalAttenuation = 16 ,
			--气球
			numCountBalloonThreshold = 5 ,
			numCountBalloonAttenuation = 10 ,
			--流沙
			numSandThreshold = 5 ,
			numSandAttenuation = 10 ,
			--闪电鸟
			numTotemsThreshold = 5 ,
			numTotemsAttenuation = 10 ,
			--兔子
			numCountRabbitThreshold = 5 ,
			numCountRabbitAttenuation = 10 ,
			--火箭
			numRocketThreshold = 5 ,
			numRocketAttenuation = 10 ,
		} ,	
	} ,
}

AIAddColorConfig = {

	rateAdjust = {

		[1] = { minMovesRate = 0 , maxMovesRate = 0.15 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 },
		[2] = { minMovesRate = 0.15, maxMovesRate = 0.3 , adjustPoint1 = 0.1 , adjustPoint2 = 0.3 , adjustPoint3 = 0.4 },
		[3] = { minMovesRate = 0.3 , maxMovesRate = 0.4 , adjustPoint1 = 0.2 , adjustPoint2 = 0.3 , adjustPoint3 = 0.5 },
		[4] = { minMovesRate = 0.4 , maxMovesRate = 0.75 , adjustPoint1 = 0.1, adjustPoint2 = 0.3 , adjustPoint3 = 0.4 },
		[5] = { minMovesRate = 0.75 , maxMovesRate = 1 , adjustPoint1 = 0.08 , adjustPoint2 = 0.15 , adjustPoint3 = 0.2 },

	},

	staticDataSwitch = { 
		--【max】5分位   【high】25分位   【mid】 50分位   【low】 75分位  【min】 95分位   从左到右，水平从好到差
		--目前可用的只有 mid ， low ， min

		[1] = { minMovesRate = 0 , maxMovesRate = 0.3 , progressData = "mid" },
		[2] = { minMovesRate = 0.3, maxMovesRate = 0.75 , progressData = "low" },
		[3] = { minMovesRate = 0.75 , maxMovesRate = 0.9 , progressData = "low" },
		[4] = { minMovesRate = 0.9 , maxMovesRate = 1 , progressData = "mid" },

	},


	rateAdjustExpGroup = {

		[1] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 1 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 }
		},

		[2] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.8 , adjustPoint1 = 0.04 , adjustPoint2 = 0.08 , adjustPoint3 = 0.15 },
			[2] = { minMovesRate = 0.8 , maxMovesRate = 1 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 }
		},

		[3] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.8 , adjustPoint1 = 0.03 , adjustPoint2 = 0.06 , adjustPoint3 = 0.12 },
			[2] = { minMovesRate = 0.8 , maxMovesRate = 1 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 }
		},

		[4] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.8 , adjustPoint1 = 0.02 , adjustPoint2 = 0.04 , adjustPoint3 = 0.1 },
			[2] = { minMovesRate = 0.8 , maxMovesRate = 1 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 }
		},

		[5] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 1 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 }
		},

		[6] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.8 , adjustPoint1 = 0.04 , adjustPoint2 = 0.08 , adjustPoint3 = 0.15 },
			[2] = { minMovesRate = 0.8 , maxMovesRate = 1 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 }
		},

		[7] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.8 , adjustPoint1 = 0.03 , adjustPoint2 = 0.06 , adjustPoint3 = 0.12 },
			[2] = { minMovesRate = 0.8 , maxMovesRate = 1 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 }
		},

		[8] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.8 , adjustPoint1 = 0.02 , adjustPoint2 = 0.04 , adjustPoint3 = 0.1 },
			[2] = { minMovesRate = 0.8 , maxMovesRate = 1 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 }
		},

		[9] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.8 , adjustPoint1 = 0.01 , adjustPoint2 = 0.03 , adjustPoint3 = 0.05 },
			[2] = { minMovesRate = 0.8 , maxMovesRate = 1 , adjustPoint1 = 0.01 , adjustPoint2 = 0.05 , adjustPoint3 = 0.1 }
		},

	},
	--[[
	rateAdjustExpGroup_old = {

		[1] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 1 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 }
		},

		[2] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.15 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 },
			[2] = { minMovesRate = 0.15, maxMovesRate = 0.3 , adjustPoint1 = 0.1 , adjustPoint2 = 0.2 , adjustPoint3 = 0.3 },
			[3] = { minMovesRate = 0.3 , maxMovesRate = 0.6 , adjustPoint1 = 0.3 , adjustPoint2 = 0.4 , adjustPoint3 = 0.6 },
			[4] = { minMovesRate = 0.6 , maxMovesRate = 0.9 , adjustPoint1 = 0.4, adjustPoint2 = 0.5 , adjustPoint3 = 0.7 },
			[5] = { minMovesRate = 0.9 , maxMovesRate = 1 , adjustPoint1 = 1 , adjustPoint2 = 1 , adjustPoint3 = 1 }
		},

		[3] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.15 , adjustPoint1 = 0.1 , adjustPoint2 = 0.2 , adjustPoint3 = 0.3 },
			[2] = { minMovesRate = 0.15, maxMovesRate = 0.3 , adjustPoint1 = 0.1 , adjustPoint2 = 0.3 , adjustPoint3 = 0.4 },
			[3] = { minMovesRate = 0.3 , maxMovesRate = 0.6 , adjustPoint1 = 0.2 , adjustPoint2 = 0.3 , adjustPoint3 = 0.5 },
			[4] = { minMovesRate = 0.6 , maxMovesRate = 0.9 , adjustPoint1 = 0.2, adjustPoint2 = 0.3 , adjustPoint3 = 0.5 },
			[5] = { minMovesRate = 0.9 , maxMovesRate = 1 , adjustPoint1 = 0.8 , adjustPoint2 = 0.9 , adjustPoint3 = 0.95 }
		},

		[4] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.15 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 },
			[2] = { minMovesRate = 0.15, maxMovesRate = 0.3 , adjustPoint1 = 0.2 , adjustPoint2 = 0.3 , adjustPoint3 = 0.5},
			[3] = { minMovesRate = 0.3 , maxMovesRate = 0.4 , adjustPoint1 = 0.2 , adjustPoint2 = 0.3 , adjustPoint3 = 0.5 },
			[4] = { minMovesRate = 0.4 , maxMovesRate = 0.8 , adjustPoint1 = 0.2, adjustPoint2 = 0.3 , adjustPoint3 = 0.5 },
			[5] = { minMovesRate = 0.8 , maxMovesRate = 1 , adjustPoint1 = 0.7 , adjustPoint2 = 0.8 , adjustPoint3 = 0.9 }
		},

		[5] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.15 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 },
			[2] = { minMovesRate = 0.15, maxMovesRate = 0.3 , adjustPoint1 = 0.3 , adjustPoint2 = 0.4 , adjustPoint3 = 0.5},
			[3] = { minMovesRate = 0.3 , maxMovesRate = 0.4 , adjustPoint1 = 0.3 , adjustPoint2 = 0.4 , adjustPoint3 = 0.5 },
			[4] = { minMovesRate = 0.4 , maxMovesRate = 0.8 , adjustPoint1 = 0.1, adjustPoint2 = 0.15 , adjustPoint3 = 0.2 },
			[5] = { minMovesRate = 0.8 , maxMovesRate = 1 , adjustPoint1 = 0.8 , adjustPoint2 = 0.85, adjustPoint3 = 0.9 }
		},

		[6] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.15 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 },
			[2] = { minMovesRate = 0.15, maxMovesRate = 0.3 , adjustPoint1 = 0.1 , adjustPoint2 = 0.3 , adjustPoint3 = 0.4 },
			[3] = { minMovesRate = 0.3 , maxMovesRate = 0.4 , adjustPoint1 = 0.2 , adjustPoint2 = 0.3 , adjustPoint3 = 0.5 },
			[4] = { minMovesRate = 0.4 , maxMovesRate = 0.75 , adjustPoint1 = 0.1, adjustPoint2 = 0.3 , adjustPoint3 = 0.4 },
			[5] = { minMovesRate = 0.75 , maxMovesRate = 1 , adjustPoint1 = 0.08 , adjustPoint2 = 0.15 , adjustPoint3 = 0.2}
		},

		[7] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.15 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 },
			[2] = { minMovesRate = 0.15, maxMovesRate = 0.3 , adjustPoint1 = 0.1 , adjustPoint2 = 0.3 , adjustPoint3 = 0.4 },
			[3] = { minMovesRate = 0.3 , maxMovesRate = 0.4 , adjustPoint1 = 0.2 , adjustPoint2 = 0.3 , adjustPoint3 = 0.5 },
			[4] = { minMovesRate = 0.4 , maxMovesRate = 0.75 , adjustPoint1 = 0.1, adjustPoint2 = 0.3 , adjustPoint3 = 0.4 },
			[5] = { minMovesRate = 0.75 , maxMovesRate = 1 , adjustPoint1 = 0.08 , adjustPoint2 = 0.15 , adjustPoint3 = 0.2}
		},

		[8] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.15 , adjustPoint1 = 0.05 , adjustPoint2 = 0.1 , adjustPoint3 = 0.2 },
			[2] = { minMovesRate = 0.15, maxMovesRate = 0.3 , adjustPoint1 = 0.1 , adjustPoint2 = 0.3 , adjustPoint3 = 0.4 },
			[3] = { minMovesRate = 0.3 , maxMovesRate = 0.4 , adjustPoint1 = 0.2 , adjustPoint2 = 0.3 , adjustPoint3 = 0.5 },
			[4] = { minMovesRate = 0.4 , maxMovesRate = 0.75 , adjustPoint1 = 0.1, adjustPoint2 = 0.3 , adjustPoint3 = 0.4 },
			[5] = { minMovesRate = 0.75 , maxMovesRate = 1 , adjustPoint1 = 0.08 , adjustPoint2 = 0.15 , adjustPoint3 = 0.2}
		},

	},
	]]
	minusRateAdjustExpGroup = {

		[1] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 1 , adjustMinusPoint1 = 0.03 , adjustMinusPoint2 = 0.05 , adjustMinusPoint3 = 0.1 }
		},

	},

	staticDataSwitchExpGroup = { 
		--【small】99分位 【min】95分位 【verylow】90分位【low】 75分位 【mid】 50分位 【high】 25分位
		[1] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 1 , progressData = "mid" }
		} ,

		[2] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 1 , progressData = "mid" }
		} ,

		[3] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 1 , progressData = "mid" }
		} ,

		[4] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 1 , progressData = "mid" }
		} ,

		[5] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.8 , progressData = "high" },
			[2] = { minMovesRate = 0.8 , maxMovesRate = 1 , progressData = "mid" }
		} ,

		[6] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.8 , progressData = "high" },
			[2] = { minMovesRate = 0.8 , maxMovesRate = 1 , progressData = "mid" }
		} ,

		[7] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.8 , progressData = "high" },
			[2] = { minMovesRate = 0.8 , maxMovesRate = 1 , progressData = "mid" }
		} ,

		[8] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.8 , progressData = "high" },
			[2] = { minMovesRate = 0.8 , maxMovesRate = 1 , progressData = "mid" }
		} ,

		[9] = {
			[1] = { minMovesRate = 0.8 , maxMovesRate = 1 , progressData = "high" }
		} ,
	},
	--[[
	staticDataSwitchExpGroup_old = { 
		--【small】99分位 【min】95分位 【verylow】90分位【low】 75分位 【mid】 50分位 【high】 25分位

		[1] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 1 , progressData = "mid" }
		} ,
		
		[2] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.3 , progressData = "high" },
			[2] = { minMovesRate = 0.3, maxMovesRate = 0.6 , progressData = "high" },
			[3] = { minMovesRate = 0.6 , maxMovesRate = 0.9 , progressData = "high" },
			[4] = { minMovesRate = 0.9 , maxMovesRate = 1 , progressData = "high" }
		} ,

		[3] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.3 , progressData = "small" },
			[2] = { minMovesRate = 0.3, maxMovesRate = 0.6 , progressData = "low" },
			[3] = { minMovesRate = 0.6 , maxMovesRate = 0.9 , progressData = "mid" },
			[4] = { minMovesRate = 0.9 , maxMovesRate = 1 , progressData = "high" }
		} ,

		[4] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.3 , progressData = "mid" },
			[2] = { minMovesRate = 0.3, maxMovesRate = 0.75 , progressData = "mid" },
			[3] = { minMovesRate = 0.75 , maxMovesRate = 0.9 , progressData = "mid" },
			[4] = { minMovesRate = 0.9 , maxMovesRate = 1 , progressData = "mid" }
		} ,

		[5] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.3 , progressData = "low" },
			[2] = { minMovesRate = 0.3, maxMovesRate = 0.4 , progressData = "low" },
			[3] = { minMovesRate = 0.4 , maxMovesRate = 0.8 , progressData = "min" },
			[4] = { minMovesRate = 0.8 , maxMovesRate = 1 , progressData = "high" }
		} ,

		[6] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.3 , progressData = "mid" },
			[2] = { minMovesRate = 0.3, maxMovesRate = 0.75 , progressData = "low" },
			[3] = { minMovesRate = 0.75 , maxMovesRate = 0.9 , progressData = "low" },
			[4] = { minMovesRate = 0.9 , maxMovesRate = 1 , progressData = "mid" }
		} ,

		[7] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.3 , progressData = "low" },
			[2] = { minMovesRate = 0.3, maxMovesRate = 0.75 , progressData = "verylow" },
			[3] = { minMovesRate = 0.75 , maxMovesRate = 0.9 , progressData = "min" },
			[4] = { minMovesRate = 0.9 , maxMovesRate = 1 , progressData = "small" }
		} ,

		[8] = {
			[1] = { minMovesRate = 0 , maxMovesRate = 0.3 , progressData = "high" },
			[2] = { minMovesRate = 0.3, maxMovesRate = 0.75 , progressData = "mid" },
			[3] = { minMovesRate = 0.75 , maxMovesRate = 0.9 , progressData = "low" },
			[4] = { minMovesRate = 0.9 , maxMovesRate = 1 , progressData = "small" }
		}
	},
	]]
}