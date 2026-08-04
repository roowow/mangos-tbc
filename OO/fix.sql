-- 卡拉赞象棋事件：spell 30253("Chess: Move to Square"，负责把棋子实际移动到目标格子)在 spell_scripts 里完全没有绑定记录，
-- 导致 ChessMoveToSquare::OnEffectExecute（真正触发棋子移动事件的代码）从未被调用，很可能是棋子不能走的根因
-- 原写法用的是 `spell_script_names`/`spell_id`，这张表/这个列名在实际库里不存在（真正被代码读取的表是 spell_scripts，列名 Id），已改正
-- [状态: 2026-08-01 已应用到测试库 tbcmangosdev，待玩家实测确认是否解决棋子不动的问题；待同步生产库]
REPLACE INTO `spell_scripts` (`Id`, `ScriptName`) VALUES
(30253, 'spell_chess_move_to_square');

-- spell 20741 (暗言术箭雨) 冷却修复，跟 mangos-tbc/oofixed/fix.sql 的 FIX-18 是同一条；测试库这段时间反复重置/切库导致又丢失，此处重新应用
-- [状态: 2026-08-01 已应用到测试库 tbcmangosdev]
UPDATE `spell_template` SET `RecoveryTime` = '10000' WHERE (`Id` = '20741');

-- 卡拉赞象棋事件：spell 30270("Chess: Face Square"，棋子移动时转向目标格子朝向)在 spell_scripts 里也完全没有绑定记录，
-- 跟 30253 是同一类缺失，同样是棋子移动流程的一环（ChessFaceSquare::OnEffectExecute，注册名 spell_chess_face_square 已核对匹配）
-- [状态: 2026-08-01 已应用到测试库 tbcmangosdev，待玩家实测确认；待同步生产库]
INSERT INTO `spell_scripts` (`id`, `ScriptName`) VALUES
(30270, 'spell_chess_face_square');

-- [FIX-01] 训练假人（从 mangos-tbc/oofixed/fix.sql 的 FIX-01 移植过来，测试服已重置切到本仓库 Nmangos-tbc，纯数据无代码依赖(AIName/ScriptName均为空)，跟代码版本无关）
-- [状态: 2026-08-04 已应用到测试库 tbcmangosdev，验证通过]
replace into creature_template(`Entry`,`Name`,`SubName`,`IconName`,`MinLevel`,`MaxLevel`,`HeroicEntry`,`DisplayId1`,`DisplayId2`,`DisplayId3`,`DisplayId4`,`DisplayIdProbability1`,`DisplayIdProbability2`,`DisplayIdProbability3`,`DisplayIdProbability4`,`Faction`,`Scale`,`Family`,`CreatureType`,`InhabitType`,`RegenerateStats`,`RacialLeader`,`NpcFlags`,`UnitFlags`,`DynamicFlags`,`ExtraFlags`,`CreatureTypeFlags`,`StaticFlags1`,`StaticFlags2`,`StaticFlags3`,`StaticFlags4`,`SpeedWalk`,`SpeedRun`,`Detection`,`CallForHelp`,`Pursuit`,`Leash`,`Timeout`,`UnitClass`,`Rank`,`Expansion`,`HealthMultiplier`,`PowerMultiplier`,`DamageMultiplier`,`DamageVariance`,`ArmorMultiplier`,`ExperienceMultiplier`,`StrengthMultiplier`,`AgilityMultiplier`,`StaminaMultiplier`,`IntellectMultiplier`,`SpiritMultiplier`,`MinLevelHealth`,`MaxLevelHealth`,`MinLevelMana`,`MaxLevelMana`,`MinMeleeDmg`,`MaxMeleeDmg`,`MinRangedDmg`,`MaxRangedDmg`,`Armor`,`MeleeAttackPower`,`RangedAttackPower`,`MeleeBaseAttackTime`,`RangedBaseAttackTime`,`DamageSchool`,`MinLootGold`,`MaxLootGold`,`LootId`,`PickpocketLootId`,`SkinningLootId`,`KillCredit1`,`KillCredit2`,`MechanicImmuneMask`,`SchoolImmuneMask`,`ResistanceHoly`,`ResistanceFire`,`ResistanceNature`,`ResistanceFrost`,`ResistanceShadow`,`ResistanceArcane`,`PetSpellDataId`,`MovementType`,`TrainerType`,`TrainerSpell`,`TrainerClass`,`TrainerRace`,`TrainerTemplateId`,`VendorTemplateId`,`EquipmentTemplateId`,`GossipMenuId`,`InteractionPauseTimer`,`CorpseDecay`,`SpellList`,`CharmedSpellList`,`StringId1`,`StringId2`,`AIName`,`ScriptName`) values
    (94952,'超级训练假人',null,null,'73','73',0,3019,0,0,0,100,0,0,0,1095,1,'0','9','3','14','0','0','0','0','131074','0','256','0','0','0',1,1,'18','0','15000','0','0','1','0','0',110,1,1,1,1.33333,1,1,1,1,1,1,'1000000','1000000','0','0',0,0,0,0,0,'0',0,'0','0','0',0,0,0,0,0,'0','0','0','0',0,0,0,0,0,0,0,'0','0',0,'0','0',0,0,0,0,-1,'0',0,0,'0','0','','')
  , (94953,'高级训练假人',null,null,'50','50',0,3019,0,0,0,100,0,0,0,1095,1,'0','9','3','14','0','0','0','0','131074','0','256','0','0','0',1,1,'18','0','15000','0','0','1','0','0',330,1,1,1,1.33333,1,1,1,1,1,1,'1000000','1000000','0','0',0,0,0,0,0,'0',0,'0','0','0',0,0,0,0,0,'0','0','0','0',0,0,0,0,0,0,0,'0','0',0,'0','0',0,0,0,0,-1,'0',0,0,'0','0','','')
  , (94954,'训练假人 ',null,null,'30','30',0,3019,0,0,0,100,0,0,0,1095,1,'0','9','3','14','0','0','0','0','131074','0','256','0','0','0',1,1,'18','0','15000','0','0','1','0','0',55,1,1,1,1.33333,1,1,1,1,1,1,'1000000','1000000','0','0',0,0,0,0,0,'0',0,'0','0','0',0,0,0,0,0,'0','0','0','0',0,0,0,0,0,0,0,'0','0',0,'0','0',0,0,0,0,-1,'0',0,0,'0','0','','');

replace into creature(id,map,`spawnMask`,position_x,position_y,position_z,orientation,spawntimesecsmin,spawntimesecsmax,spawndist,`MovementType`) values
    (94952,1,'1',1612.59000000000000000000,-4323.37000000000000000000,2.19202000000000000000,1.16080000000000000000,'300','300',0,'0')
  , (94952,0,'1',-8814.68000000000000000000,847.24100000000000000000,99.03460000000000000000,6.10239000000000000000,'300','300',0,'0')
  , (94952,0,'1',-5010.98000000000000000000,-1208.53000000000000000000,501.67900000000000000000,3.80555000000000000000,'300','300',0,'0')
  , (94952,530,'1',9578.18000000000000000000,-7262.65000000000000000000,14.26040000000000000000,4.72766000000000000000,'300','300',0,'0')
  , (94953,1,'1',1608.62000000000000000000,-4320.36000000000000000000,1.78664000000000000000,0.98800500000000000000,'300','300',0,'0')
  , (94953,0,'1',-8814.92000000000000000000,838.79500000000000000000,98.79990000000000000000,6.12987000000000000000,'300','300',0,'0')
  , (94953,0,'1',-5014.51000000000000000000,-1204.20000000000000000000,501.67800000000000000000,3.78984000000000000000,'300','300',0,'0')
  , (94953,530,'1',9584.32000000000000000000,-7262.65000000000000000000,14.27470000000000000000,4.71980000000000000000,'300','300',0,'0')
  , (94954,1,'1',1602.56000000000000000000,-4319.33000000000000000000,2.09713000000000000000,1.64382000000000000000,'300','300',0,'0')
  , (94954,0,'1',-8816.16000000000000000000,830.04800000000000000000,99.07130000000000000000,6.17700000000000000000,'300','300',0,'0')
  , (94954,0,'1',-5014.98000000000000000000,-1211.86000000000000000000,501.68400000000000000000,3.77809000000000000000,'300','300',0,'0')
  , (94954,530,'1',9590.53000000000000000000,-7262.65000000000000000000,14.27140000000000000000,4.80227000000000000000,'300','300',0,'0');

-- 双天赋(魂器34646)前置任务链：奇怪的旅行者(90576)→愿者上钩(90577)→四条平行支线(90578-90582)收集灵气，90578("涌动的异界灵气")交4个"异界灵气"(23698)后奖励魂器(34646)
-- 涉及NPC 3945/4452/5901/13816/13817/14508/15526 均为暴雪原版NPC复用，测试库重置后任务链和 creature_questrelation/involvedrelation 都丢失，此处重新应用
-- 具体 SQL 见 D:\其他\wow\Development\cmangos\mangos-tbc\oo\dualtalent.sql（quest_template/creature_questrelation/creature_involvedrelation/creature_template，此处不重复贴）
-- 配套代码见本次会话对 Player.h/Player.cpp/CharacterHandler.cpp/SkillHandler.cpp/NPCHandler.cpp/SpellHandler.cpp 的移植（魂器使用/gossip/天赋切换逻辑）
-- [状态: 2026-08-04 已应用到测试库 tbcmangosdev，验证通过；待同步生产库]

-- 魂器(34646) item_template 数据：测试库重置后该条目变回了默认占位数据("[PH] Everburning Elixir")，中文名称/描述/displayid/品质/绑定的魂器灵魂使用spell(45385)等全部丢失
-- 经核对生产库 tbcmangos2 与旧备份库 tbcmangos 一致，均为直接写在 item_template.name/description 里（未使用 locales_item/locales_item2 表，三个库该条目在locale表里都没有记录），此处按生产库数据整行 REPLACE
-- [状态: 2026-08-04 已应用到测试库 tbcmangosdev，验证通过]
REPLACE INTO `item_template` VALUES (34646,15,0,-1,'魂器',48901,4,64,1,0,0,0,-1,-1,40,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,45385,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,1,'涌动的灵气……如此纯粹，如此热烈，直击我灵魂深处！',0,0,0,0,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,'',0,0,0,0,0,0);
