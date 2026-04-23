# animal
一、爆炸障碍类型
这个游戏包含多种爆炸障碍：
类型	用途	特点
kDynamiteCrate (85)	愤怒的炸药箱	血量归零时引爆
kMissile (41)	冰封导弹	同样机制
kBuffBoom (50)	Buff炸弹	活动专用
kFirecracker (62)	爆竹	节日活动
二、数据结构设计
物品数据 (GameItemData.lua) 包含爆炸相关字段：
self.missileLevel = 0      -- 血量等级self.bombRes = nil         -- 爆炸来源记录self.isItemLock = false    -- 防止重复引爆的锁
炸药箱核心逻辑 (DynamiteCrateLogic.lua)：
function DynamiteCrateLogic:checkDynamiteCrate(mainLogic)    -- 血量为0时可以引爆    if item.missileLevel == 0 then        table.insert(crates, item)    endend
三、爆炸流程链
玩家操作 (Swap/Match)    ↓特效检测 (SpecialMatchLogic)    ↓特效生成 (kLine/kColumn/kWrap/kColor)    ↓BombItemLogic:BombItem()  ← 核心爆炸入口    ↓创建 GameBoardAction    ↓DestroyItemLogic 销毁判定    ↓StableStateMachine 状态机处理    ↓TileDynamiteCrate:playVanishAnimation() 动画播放
四、状态机设计
核心状态机 (StableStateMachine.lua) 管理爆炸流程：
DynamiteCrateFireFirstState - 炸药箱发射初始状态
DynamiteCrateFireInLoopState - 循环检测状态
MissileFireState - 导弹发射状态
onEnter() → tryHandleFire() → fireDynamiteCrates()
五、视觉表现
爆炸动画定义在 TileDynamiteCrate.lua：
动画名	触发时机
idle_X	待机动画 (X=等级)
stimulate	被击中动画
blast	爆炸消失动画
六、关键代码文件
功能	文件
爆炸核心逻辑	BoardLogic/BombItemLogic.lua
炸药箱逻辑	BoardLogic/CertainPlayLogic/DynamiteCrateLogic.lua
动画表现	animation/TileDynamiteCrate.lua
销毁执行	BoardLogic/DestroyItemLogic.lua
状态机	stable/StableStateMachine.lua
总结：这是一个典型的观察者模式 + 状态机的设计。爆炸障碍触发后，先通过 BombItemLogic 计算爆炸范围，然后通过 DestroyItemLogic 标记待销毁物品，最后由状态机驱动动画播放和音效反馈。
