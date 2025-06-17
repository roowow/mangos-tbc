-- 训练假人
replace into creature_template(`Entry`,`Name`,`SubName`,`IconName`,`MinLevel`,`MaxLevel`,`HeroicEntry`,`DisplayId1`,`DisplayId2`,`DisplayId3`,`DisplayId4`,`DisplayIdProbability1`,`DisplayIdProbability2`,`DisplayIdProbability3`,`DisplayIdProbability4`,`Faction`,`Scale`,`Family`,`CreatureType`,`InhabitType`,`RegenerateStats`,`RacialLeader`,`NpcFlags`,`UnitFlags`,`DynamicFlags`,`ExtraFlags`,`CreatureTypeFlags`,`StaticFlags1`,`StaticFlags2`,`StaticFlags3`,`StaticFlags4`,`SpeedWalk`,`SpeedRun`,`Detection`,`CallForHelp`,`Pursuit`,`Leash`,`Timeout`,`UnitClass`,`Rank`,`Expansion`,`HealthMultiplier`,`PowerMultiplier`,`DamageMultiplier`,`DamageVariance`,`ArmorMultiplier`,`ExperienceMultiplier`,`StrengthMultiplier`,`AgilityMultiplier`,`StaminaMultiplier`,`IntellectMultiplier`,`SpiritMultiplier`,`MinLevelHealth`,`MaxLevelHealth`,`MinLevelMana`,`MaxLevelMana`,`MinMeleeDmg`,`MaxMeleeDmg`,`MinRangedDmg`,`MaxRangedDmg`,`Armor`,`MeleeAttackPower`,`RangedAttackPower`,`MeleeBaseAttackTime`,`RangedBaseAttackTime`,`DamageSchool`,`MinLootGold`,`MaxLootGold`,`LootId`,`PickpocketLootId`,`SkinningLootId`,`KillCredit1`,`KillCredit2`,`MechanicImmuneMask`,`SchoolImmuneMask`,`ResistanceHoly`,`ResistanceFire`,`ResistanceNature`,`ResistanceFrost`,`ResistanceShadow`,`ResistanceArcane`,`PetSpellDataId`,`MovementType`,`TrainerType`,`TrainerSpell`,`TrainerClass`,`TrainerRace`,`TrainerTemplateId`,`VendorTemplateId`,`EquipmentTemplateId`,`GossipMenuId`,`InteractionPauseTimer`,`CorpseDecay`,`SpellList`,`CharmedSpellList`,`StringId1`,`StringId2`,`AIName`,`ScriptName`) values 
    (94952,'超级训练假人',null,null,'73','73',0,3019,0,0,0,100,0,0,0,1095,1,'0','9','2','14','0','0','0','0','131074','0','0','0','0','0',1,1,'18','0','15000','0','0','1','0','0',110,1,1,1,1.33333,1,1,1,1,1,1,'1000000','1000000','0','0',0,0,0,0,0,'0',0,'0','0','0',0,0,0,0,0,'0','0','0','0',0,0,0,0,0,0,0,'0','0',0,'0','0',0,0,0,0,-1,'0',0,0,'0','0','','')
  , (94953,'高级训练假人',null,null,'50','50',0,3019,0,0,0,100,0,0,0,1095,1,'0','9','2','14','0','0','0','0','131074','0','0','0','0','0',1,1,'18','0','15000','0','0','1','0','0',330,1,1,1,1.33333,1,1,1,1,1,1,'1000000','1000000','0','0',0,0,0,0,0,'0',0,'0','0','0',0,0,0,0,0,'0','0','0','0',0,0,0,0,0,0,0,'0','0',0,'0','0',0,0,0,0,-1,'0',0,0,'0','0','','')
  , (94954,'训练假人 ',null,null,'30','30',0,3019,0,0,0,100,0,0,0,1095,1,'0','9','2','14','0','0','0','0','131074','0','0','0','0','0',1,1,'18','0','15000','0','0','1','0','0',55,1,1,1,1.33333,1,1,1,1,1,1,'1000000','1000000','0','0',0,0,0,0,0,'0',0,'0','0','0',0,0,0,0,0,'0','0','0','0',0,0,0,0,0,0,0,'0','0',0,'0','0',0,0,0,0,-1,'0',0,0,'0','0','','');

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


-- 玛拉顿节杖不能完成的问题
UPDATE `gameobject_template` SET `flags` = '64' WHERE `gameobject_template`.`entry` = 178963;
replace INTO dbscripts_on_go_template_use (`id`, `delay`, `priority`, `command`, `datalong`, `comments`)
VALUES (178965, 6000, 0, 15, 21917, 'Incantation of Celebras - cast quest complete spell');

-- 科卡尔召雷师不应该触发 召唤维罗戈
delete from creature_ai_scripts cas where cas.id = 327306 and cas.creature_id = 3273;

-- 诅咒之地增加黑色屠戮者
DELETE from creature where id = 5982;
REPLACE INTO creature(id,map,`spawnMask`,position_x,position_y,position_z,orientation,spawntimesecsmin,spawntimesecsmax,spawndist,`MovementType`) values 
    (5982,0,'1',-11489.70000000000000000000,-3277.69000000000000000000,12.84230000000000000000,1.07379000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11511.50000000000000000000,-3251.22000000000000000000,9.22722000000000000000,0.55541800000000000000,'300','300',5,'1')
  , (5982,0,'1',-11440.00000000000000000000,-3249.91000000000000000000,11.08380000000000000000,0.51223200000000000000,'300','300',5,'1')
  , (5982,0,'1',-11388.10000000000000000000,-3264.25000000000000000000,7.44927000000000000000,4.98509000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11243.70000000000000000000,-3350.09000000000000000000,9.57555000000000000000,1.21515000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11207.50000000000000000000,-3326.23000000000000000000,8.27919000000000000000,5.65266000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11379.60000000000000000000,-3152.13000000000000000000,14.68840000000000000000,2.84329000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11384.60000000000000000000,-3218.22000000000000000000,11.63200000000000000000,4.77929000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11388.70000000000000000000,-3037.51000000000000000000,-3.89802000000000000000,2.17570000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11423.40000000000000000000,-3000.24000000000000000000,3.22682000000000000000,1.98956000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11375.40000000000000000000,-2922.87000000000000000000,5.64368000000000000000,1.11384000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11320.20000000000000000000,-2778.63000000000000000000,12.58220000000000000000,0.63081900000000000000,'300','300',5,'1')
  , (5982,0,'1',-11050.10000000000000000000,-2780.01000000000000000000,5.44158000000000000000,5.11152000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11001.10000000000000000000,-2771.52000000000000000000,4.19075000000000000000,0.19570300000000000000,'300','300',5,'1')
  , (5982,0,'1',-10997.70000000000000000000,-2830.45000000000000000000,9.76229000000000000000,4.06381000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11049.50000000000000000000,-2877.14000000000000000000,9.45582000000000000000,4.13057000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11028.70000000000000000000,-2884.26000000000000000000,8.73721000000000000000,0.54523200000000000000,'300','300',5,'1')
  , (5982,0,'1',-11010.90000000000000000000,-2875.90000000000000000000,9.31094000000000000000,6.25901000000000000000,'300','300',5,'1')
  , (5982,0,'1',-10970.60000000000000000000,-2880.67000000000000000000,7.52950000000000000000,5.96449000000000000000,'300','300',5,'1')
  , (5982,0,'1',-10955.70000000000000000000,-2870.50000000000000000000,5.43700000000000000000,0.58528900000000000000,'300','300',5,'1')
  , (5982,0,'1',-10963.90000000000000000000,-2893.65000000000000000000,5.97133000000000000000,2.70587000000000000000,'300','300',5,'1')
  , (5982,0,'1',-10982.60000000000000000000,-2858.05000000000000000000,7.48535000000000000000,1.92439000000000000000,'300','300',5,'1')
  , (5982,0,'1',-10976.00000000000000000000,-2829.86000000000000000000,9.66810000000000000000,1.23717000000000000000,'300','300',5,'1')
  , (5982,0,'1',-10934.40000000000000000000,-2898.43000000000000000000,10.26640000000000000000,4.19814000000000000000,'300','300',5,'1')
  , (5982,0,'1',-10967.50000000000000000000,-2923.99000000000000000000,10.75020000000000000000,0.89554800000000000000,'300','300',5,'1')
  , (5982,0,'1',-11259.10000000000000000000,-3318.38000000000000000000,21.31510000000000000000,3.37609000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11399.60000000000000000000,-3314.00000000000000000000,8.25842000000000000000,4.10651000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11491.50000000000000000000,-3179.49000000000000000000,13.46000000000000000000,1.38118000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11502.70000000000000000000,-3157.69000000000000000000,7.59285000000000000000,2.63782000000000000000,'300','300',5,'1')
  , (5982,0,'1',-11505.30000000000000000000,-3113.05000000000000000000,-1.07898000000000000000,5.71266000000000000000,'300','300',5,'1');


-- 修复费伍德换药膏任务 第一次任务都正常给经验
update quest_template qt SET qt.RewMoneyMaxLevel = 3660 where qt.entry in (5882,5883,5884,5885,5886,5887,5888,5889,5890,5891) 
-- 后续任务都不给经验
update quest_template qt SET qt.RewMoneyMaxLevel = 0 where qt.entry in (4103,4104,4105,4106,4107,4108,4109,4110,4111,4112) 


-- 奥山装备 加声望 道具限制
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=512 and item= 19308;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=512 and item= 19309;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=512 and item= 19310;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=512 and item= 19311;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=512 and item= 19312;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=512 and item= 19315;
UPDATE npc_vendor_template SET ExtendedCost=460  WHERE entry=512 and item= 19316;
UPDATE npc_vendor_template SET ExtendedCost=460  WHERE entry=512 and item= 19317;
UPDATE npc_vendor_template SET ExtendedCost=532  WHERE entry=512 and item= 19319;
UPDATE npc_vendor_template SET ExtendedCost=532  WHERE entry=512 and item= 19320;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=512 and item= 19321;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=512 and item= 19323;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=512 and item= 19324;
UPDATE npc_vendor_template SET ExtendedCost=489  WHERE entry=512 and item= 19325;
UPDATE npc_vendor_template SET ExtendedCost=489  WHERE entry=512 and item= 21563;
UPDATE npc_vendor_template SET ExtendedCost=1005  WHERE entry=513 and item= 19029;
UPDATE npc_vendor_template SET ExtendedCost=1003  WHERE entry=513 and item= 19031;
UPDATE npc_vendor_template SET ExtendedCost=1002  WHERE entry=513 and item= 19046;
UPDATE npc_vendor_template SET ExtendedCost=532  WHERE entry=513 and item= 19083;
UPDATE npc_vendor_template SET ExtendedCost=532  WHERE entry=513 and item= 19085;
UPDATE npc_vendor_template SET ExtendedCost=428  WHERE entry=513 and item= 19087;
UPDATE npc_vendor_template SET ExtendedCost=428  WHERE entry=513 and item= 19088;
UPDATE npc_vendor_template SET ExtendedCost=428  WHERE entry=513 and item= 19089;
UPDATE npc_vendor_template SET ExtendedCost=428  WHERE entry=513 and item= 19090;
UPDATE npc_vendor_template SET ExtendedCost=533  WHERE entry=513 and item= 19095;
UPDATE npc_vendor_template SET ExtendedCost=533  WHERE entry=513 and item= 19096;
UPDATE npc_vendor_template SET ExtendedCost=496  WHERE entry=513 and item= 19099;
UPDATE npc_vendor_template SET ExtendedCost=497  WHERE entry=513 and item= 19101;
UPDATE npc_vendor_template SET ExtendedCost=496  WHERE entry=513 and item= 19103;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=513 and item= 19308;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=513 and item= 19309;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=513 and item= 19310;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=513 and item= 19311;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=513 and item= 19312;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=513 and item= 19315;
UPDATE npc_vendor_template SET ExtendedCost=460  WHERE entry=513 and item= 19316;
UPDATE npc_vendor_template SET ExtendedCost=460  WHERE entry=513 and item= 19317;
UPDATE npc_vendor_template SET ExtendedCost=532  WHERE entry=513 and item= 19319;
UPDATE npc_vendor_template SET ExtendedCost=532  WHERE entry=513 and item= 19320;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=513 and item= 19321;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=513 and item= 19323;
UPDATE npc_vendor_template SET ExtendedCost=702  WHERE entry=513 and item= 19324;
UPDATE npc_vendor_template SET ExtendedCost=489  WHERE entry=513 and item= 19325;
UPDATE npc_vendor_template SET ExtendedCost=489  WHERE entry=513 and item= 21563;
UPDATE npc_vendor_template SET ExtendedCost=1005  WHERE entry=512 and item= 19030;
UPDATE npc_vendor_template SET ExtendedCost=1003  WHERE entry=512 and item= 19032;
UPDATE npc_vendor_template SET ExtendedCost=1002  WHERE entry=512 and item= 19045;
UPDATE npc_vendor_template SET ExtendedCost=532  WHERE entry=512 and item= 19084;
UPDATE npc_vendor_template SET ExtendedCost=532  WHERE entry=512 and item= 19086;
UPDATE npc_vendor_template SET ExtendedCost=428  WHERE entry=512 and item= 19091;
UPDATE npc_vendor_template SET ExtendedCost=428  WHERE entry=512 and item= 19092;
UPDATE npc_vendor_template SET ExtendedCost=428  WHERE entry=512 and item= 19093;
UPDATE npc_vendor_template SET ExtendedCost=428  WHERE entry=512 and item= 19094;
UPDATE npc_vendor_template SET ExtendedCost=533  WHERE entry=512 and item= 19097;
UPDATE npc_vendor_template SET ExtendedCost=533  WHERE entry=512 and item= 19098;
UPDATE npc_vendor_template SET ExtendedCost=496  WHERE entry=512 and item= 19100;
UPDATE npc_vendor_template SET ExtendedCost=497  WHERE entry=512 and item= 19102;
UPDATE npc_vendor_template SET ExtendedCost=496  WHERE entry=512 and item= 19104;

-- 任务10861 两个模型 数据都不对
UPDATE `gameobject_template` SET `data1` = '10861' WHERE `gameobject_template`.`entry` = 185210;
UPDATE `gameobject_template` SET `data1` = '10861' WHERE `gameobject_template`.`entry` = 185211;

-- 任务11145
UPDATE `gameobject_template` SET `data2` = '24618320' WHERE `gameobject_template`.`entry` = 186287;

-- 任务 9667=
UPDATE `gameobject_template` SET `data2` = '1966080' WHERE `gameobject_template`.`entry` = 181928;

-- 修复银月城 某个npc 应该同时售卖道具 和 教授技能 ，现在只售卖道具。 
DELETE from creature_template where entry = 16366 or entry = 16367;
replace INTO `creature_template` (`Entry`, `Name`, `SubName`, `IconName`, `MinLevel`, `MaxLevel`, `HeroicEntry`, `DisplayId1`, `DisplayId2`, `DisplayId3`, `DisplayId4`, `DisplayIdProbability1`, `DisplayIdProbability2`, `DisplayIdProbability3`, `DisplayIdProbability4`, `Faction`, `Scale`, `Family`, `CreatureType`, `InhabitType`, `RegenerateStats`, `RacialLeader`, `NpcFlags`, `UnitFlags`, `DynamicFlags`, `ExtraFlags`, `CreatureTypeFlags`, `StaticFlags1`, `StaticFlags2`, `StaticFlags3`, `StaticFlags4`, `SpeedWalk`, `SpeedRun`, `Detection`, `CallForHelp`, `Pursuit`, `Leash`, `Timeout`, `UnitClass`, `Rank`, `Expansion`, `HealthMultiplier`, `PowerMultiplier`, `DamageMultiplier`, `DamageVariance`, `ArmorMultiplier`, `ExperienceMultiplier`, `StrengthMultiplier`, `AgilityMultiplier`, `StaminaMultiplier`, `IntellectMultiplier`, `SpiritMultiplier`, `MinLevelHealth`, `MaxLevelHealth`, `MinLevelMana`, `MaxLevelMana`, `MinMeleeDmg`, `MaxMeleeDmg`, `MinRangedDmg`, `MaxRangedDmg`, `Armor`, `MeleeAttackPower`, `RangedAttackPower`, `MeleeBaseAttackTime`, `RangedBaseAttackTime`, `DamageSchool`, `MinLootGold`, `MaxLootGold`, `LootId`, `PickpocketLootId`, `SkinningLootId`, `KillCredit1`, `KillCredit2`, `MechanicImmuneMask`, `SchoolImmuneMask`, `ResistanceHoly`, `ResistanceFire`, `ResistanceNature`, `ResistanceFrost`, `ResistanceShadow`, `ResistanceArcane`, `PetSpellDataId`, `MovementType`, `TrainerType`, `TrainerSpell`, `TrainerClass`, `TrainerRace`, `TrainerTemplateId`, `VendorTemplateId`, `EquipmentTemplateId`, `GossipMenuId`, `InteractionPauseTimer`, `CorpseDecay`, `SpellList`, `CharmedSpellList`, `StringId1`, `StringId2`, `AIName`, `ScriptName`) VALUES
(16366, 'Sempstress Ambershine', 'Tailoring Trainer', NULL, 15, 15, 0, 16133, 0, 0, 0, 100, 0, 0, 0, 1604, 1, 0, 7, 3, 14, 0, 145, 37376, 0, 65538, 0, 2, 0, 0, 0, 1.125, 1.14286, 18, 0, 15000, 0, 0, 8, 0, 0, 1.05, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 174, 174, 790, 790, 26, 31, 0, 0, 363, 13, 100, 2000, 2000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 1080, 140, 0, 0, -1, 0, 0, 0, 0, 0, '', ''),
(16367, 'Botanist Tyniarrel', 'Herbalism Trainer & Supplies', NULL, 15, 15, 0, 16134, 0, 0, 0, 100, 0, 0, 0, 1604, 1, 0, 7, 3, 14, 0, 145, 4608, 0, 65538, 0, 2, 0, 0, 0, 1.125, 1.14286, 18, 0, 15000, 0, 0, 8, 0, 0, 1.05, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 174, 174, 790, 790, 26, 31, 0, 0, 363, 13, 100, 2000, 2000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 1030, 128, 16367, 0, -1, 0, 0, 0, 0, 0, '', '');

-- 任务 891
UPDATE `quest_template` SET `ReqItemId1` = '0', `ReqItemId4` = '5078', `ReqItemCount1` = '0', `ReqItemCount4` = '10', `ReqCreatureOrGOId1` = '3393', `ReqCreatureOrGOId2` = '3455', `ReqCreatureOrGOId3` = '3454', `ReqCreatureOrGOId4` = '0', `ReqCreatureOrGOCount1` = '1' WHERE `quest_template`.`entry` = 891;
-- 任务 9418
UPDATE `spell_template` SET `Effect1` = '33' WHERE `spell_template`.`Id` = 29764;
UPDATE `gameobject_template` SET `type` = '2', `faction` = '35', `data0` = '0', `data3` = '10219', `data22` = '0' WHERE `gameobject_template`.`entry` = 181606;

-- 任务9164
UPDATE quest_template SET ReqItemCount3 = 0, ReqItemCount4 = 1, ReqCreatureOrGOId3=16209,ReqCreatureOrGOId4=0,ReqCreatureOrGOCount3 = 1, ReqCreatureOrGOCount4 = 0 WHERE entry= 9164;
UPDATE locales_quest lq SET lq.ObjectiveText3_loc4="营救游侠维多兰",lq.ObjectiveText4_loc4=""  WHERE entry = 9164;


