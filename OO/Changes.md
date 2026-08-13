# 测试库基准线变更记录

记录以 `tbcmangosdev`（测试库）为基准建立新基准线过程中，从各数据源同步过去的数据变更，以及后续 bug 修复、upstream 合并记录。跟 `fix.sql`（单条内容/bug修复）分开记录。

## 基准线同步（2026-08-04，已完成）

- **locale 全量同步**：`tbcmangosdev` 从旧生产库 `tbcmangos` 同步 12 张 `locales_*` 表（`mysqldump --no-create-info --replace`，按主键 REPLACE INTO），全部通过 `CHECKSUM TABLE` 核对一致。`tbcmangosdev` 独有的 6 张新版本表（`locales_area`/`locales_areatrigger`/`locales_broadcast_text`/`locales_faction`/`locales_spell`/`locales_taxi_node`）未受影响。✅
- **gameobject 中文名不显示**：根因是官方迁移 `s2485_01_mangos_closing_text.sql` 在 `tbcmangosdev` 上只做了一半——`gameobject_template` 已改，但 `locales_gameobject` 的 `castbarcaption_loc1..8` 没跟着改名成 `opening_text_loc1..8`（代码本身没问题，一度误判去改代码，已改回原样）。已在 `tbcmangosdev` 补跑迁移，验证 173216/180511 的 `name_loc4` 中文数据能正确读取。`mangos-tbc`(v2)/`tbcmangos2`/旧库 `tbcmangos` 仍有同样缺陷，本次未处理。✅

## Bug 修复记录

### SpellCastArgs 未初始化成员崩溃（2026-08-04）
生产服崩溃日志定位到 Mana Tombs Pandemonius "Void Blast" 连锁施法：`Spell.h` 的 `SpellCastArgs()` 构造函数漏初始化 `m_itemSet`/`m_itemTarget`，栈垃圾值被误判为"已设置物品目标"，下游解引用野指针崩溃。非 Pandemonius 专属，是通用类缺陷，`mangos-tbc` 同样有此问题，本次只修 `Nmangos-tbc`。
修复：`Spell.h` 构造函数初始化列表补 `m_itemSet(false), m_itemTarget(nullptr)`。
**状态**：✅ 代码已改，需重新编译部署。

### 合并 origin/master 两个提交到 v3（2026-08-05）
`6217a6039`（修复交换队伍连发 `SMSG_GROUP_LIST` 导致客户端崩溃）+ `9c1c4121a`（Gnomeregan boss_thermaplugg 空指针判断 + Karazhan"主人的露台门"未跟随舞台事件解锁）。两者都与本地此前独立所做的修复内容重合/等价，`git merge origin/master --no-ff` 合并，`Group.h/.cpp`+`GroupHandler.cpp` 冲突手动解决（保留本地更规范的默认参数写法，功能等价）。
**状态**：✅ 已合并到本地 `v3`（合并提交 `88cbc5c86`），**尚未 push 到 `roowow/v3`**；Karazhan 门修复尚未编译部署。

### 暗影迷宫"暗影新星"伤害过高（2026-08-07）
恶毒导师（entry 18848，spell 33501）携带 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`（`spellLevel=20`），70 级施法者按生物基础伤害比例放大原始 148 点伤害约 21.6 倍，实测命中 3200-3700，远超预期；且普通/英雄难度共用同一法术 ID，是本副本内唯一没有拆分难度的技能（根因经 5 处调试日志实锤）。数值参考经过多个 AI 独立交叉验证（普通 1000-1500 有三方引用支撑；英雄区间为推算值，非查证事实）。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 新增 `case 33501`，按 `IsRegularDifficulty()` 直接覆盖伤害为 `urand(1000,1500)`（普通）/ `urand(2000,2500)`（英雄，用户在推算值 1500-2000 基础上手动上调），不改动法术 ID / 数据库。
Grandmaster Vorpil 自己的暗影新星（33846）有同样"不分难度"问题，但无 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`（固定值 1157~1343，已接近正常值），是否一并处理待定。
**状态**：✅ 代码已实施（纯代码，无 SQL），等待编译部署 + 实测反馈，英雄数值尤其需要玩家实测校准。

### 悲伤沼泽钓鱼"技能不足，无法下杆"（2026-08-11）
玩家反馈"钓鱼专家纳特·帕格"任务链（6607）在悲伤沼泽·芦苇海滩（zone 8 / area 300）钓 Misty Reed Mahi Mahi 时始终提示技能不足，满技能+装备（495）也无法下杆。定位到 `Spell.cpp` 里按地图/区域硬编码的最低钓鱼技能表（**Nmangos-tbc 自有机制，upstream 没有这套代码**）漏配置了悲伤沼泽，落入代码里特意设置的"未处理区域"哨兵值 500（高于任何可能达到的技能值），经调试日志实锤（`minimumRequiredSkill=500`）。
核实：DB 表 `skill_fishing_base_level` 及同任务另外两个钓鱼点（Desolace/Stranglethorn）的代码配置均为 130，未采纳网上某 AI 给出的"225"（系混淆了任务接取门槛与钓鱼区域门槛两个不同字段）。
修复：`case 33/45`（藏宝海湾/艾拉希高地）同档加入 `case 8`，值 130。
**状态**：✅ 代码已实施，等待编译部署 + 实测。

### 蒸汽地窖"盘牙先知"冰霜震击伤害过高（2026-08-12）
玩家反馈蒸汽地窖（The Steamvault，map 545）精英怪盘牙先知（entry 17803）"冰霜震击"（法术22582普通/37865英雄）单次命中7772点冰霜伤害。根因与"暗影新星"完全同一种模式：法术携带 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`（`spellLevel=20`），70级施法者按生物基础伤害比例放大约21.6倍（`CLSPowerCreature=261.316/CLSPowerSpell=12.103`，与恶毒导师那次系数逐位一致，因为都是UnitClass=2）；且普通/英雄两个法术ID数据完全相同，无难度区分。经4处调试日志实锤，全程无额外因素（resist/absorb/block均为0，链路上数值未被二次改动）。
数值参考：英雄难度找到 `Schaka/TBC-research` issue #9 的 Corecraft 观测值"Frost Shock for 3214"（作者标注为"Educated Guess"，未与WDB客户端数据核对，可信度中等）；普通难度完全没有查到可靠数字（另一个疑似线索 issue #21 的"1092-1543"经核实是近战物理伤害区间，非本技能数据，已排除）。最终按英雄锚点3214反推：普通 `urand(1700,2100)`、英雄 `urand(2900,3500)`，均为推算区间，非查证事实。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 新增 `case 22582: case 37865:`，同暗影新星模式按难度覆盖伤害，不改动法术ID/数据库。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。

### 蒸汽地窖"盘牙巫师"寒冰箭伤害过高（2026-08-12）
玩家反馈同一副本另一个精英怪盘牙巫师（entry 17722）"寒冰箭"（法术12675普通/37930英雄）伤害过高，跟"冰霜震击"是同一批系统性排查（204个技能清单）里已经标记过的条目，同一种 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL` 根因（`Attributes=589824` 含该属性位，`spellLevel=20`，UnitClass=2，Expansion=1，跟前两次系数一致）。
**与前两次不同的一点**：这次普通(12675)和英雄(37930)的原始 `EffectBasePoints1`/`EffectDieSides1` 数据库字段本身就有约2倍的差异关系（142/51 vs 285/101），不是完全共用同一套数据——说明这个技能原本是有难度区分设计的，只是两边都还是被同一个缩放公式放大到失控。
数值参考：英雄难度同样在 `Schaka/TBC-research` issue #9 查到"Frostbolt for 2580-3520"（Corecraft观测的Educated Guess，可信度中等）；普通难度没有独立信源，但这次没有凭空推算比例，而是用数据库里实打实的2倍原始数据比例反推（缩放前后比例不变）：普通 = 英雄 ÷ 2 ≈ `urand(1290,1760)`。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 新增 `case 12675: case 37930:`，按法术ID直接区分伤害（两个ID本身已经是难度专属，不需要再查地图难度），不改动法术ID/数据库。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。

### 蒸汽地窖"泥沼主宰"毒液箭伤害过高（2026-08-12）
玩家反馈同一副本精英怪泥沼主宰（entry 21694，`UnitClass=1`，与前两个精英怪UnitClass=2不同，但查表确认20级/70级的 `BaseDamage` 缩放比例同样是21.593倍，两个职业曲线数值相同）"毒液箭"（法术37272普通/37862英雄）单次命中7590自然伤害，同一根因（`Attributes=524288` 含 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`，`spellLevel=20`）。
技能结构：Effect1直接伤害（受缩放bug影响）+ Effect2自然DoT（5秒/跳，普通29点/英雄59点）。
普通(37272)/英雄(37862)原始基数同样是干净的2倍关系（112/75 vs 224/151）。
数值参考：`Schaka/TBC-research` issue #9 查到"Poison Bolt for 2000-3350 and DoT ticking 587 per stack"（Corecraft观测Educated Guess，可信度中等，量级与截图7590吻合）；普通难度按数据库2倍比例反推 ≈ `urand(1000,1675)`。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 新增 `case 37272: case 37862:`，按法术ID直接区分伤害，不改动法术ID/数据库。

**⚠️ 后续订正（2026-08-12，排查"火焰之雨"时发现）**：最初判断"Effect2自然DoT不受缩放bug影响、无需处理"是**错的**。深挖 `Object.cpp` 缩放公式发现，判断逻辑是**优先看 `EffectApplyAuraName`**——如果这个效果挂的光环类型是 `SPELL_AURA_PERIODIC_DAMAGE`（持续伤害），照样会被同一套缩放放大，跟"是不是光环"无关。毒液箭的DoT（`EffectApplyAuraName2=3`=`PERIODIC_DAMAGE`）正好命中这个分支，之前完全没处理。已核实其他几个已修复的技能（寒冰箭/闪电箭的第二效果是"减速"`MOD_DECREASE_SPEED`，不在缩放判定列表里，确实不受影响，判断没错，只有毒液箭这个是漏的）。
补充修复：由于这个DoT效果不走 `EffectSchoolDMG`（该函数只处理直接伤害类效果），改在 `Object.cpp` 的 `CalculateSpellEffectValue`（缩放公式本身发生的地方）针对 `spellProto->Id`+`effect_index==EFFECT_INDEX_1` 直接覆盖。数值按DoT基数占初始命中基数的比例（约26%，29/112≈0.259，59/224≈0.263）套用到已定的初始命中目标值反推：普通每跳 `irand(260,436)`，英雄每跳 `irand(520,871)`（英雄区间恰好包含 Schaka 参考的587，互相印证）。跳2次（5秒间隔，共10秒）。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。

### 蒸汽地窖"盘牙海妖"闪电箭伤害过高（2026-08-12）
玩家反馈同一副本精英怪盘牙海妖（entry 17801，`UnitClass=2`，70级，`Expansion=1`）"闪电箭"（法术15234普通/37664英雄）伤害过高，同一根因，`Attributes=589824` 含 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`，`spellLevel=20`。原始 `EffectBasePoints1`/`EffectDieSides1` 数据（142/51 普通、285/101 英雄）跟"寒冰箭"完全相同，应是同一套技能模板复用、只换了法术学派。
数值参考：`Schaka/TBC-research` issue #9 查到"Lightning Bolt for 2400-3500"（英雄，Corecraft观测Educated Guess，可信度中等）；普通按数据库2倍比例反推 ≈ `urand(1200,1750)`。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 新增 `case 15234: case 37664:`，按法术ID直接区分伤害，不改动法术ID/数据库。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。

### 影月谷"火红岗哨之战"伊利达雷大领主烈焰风暴伤害过高（2026-08-12）
玩家反馈任务"火红岗哨之战"（Battle of the Crimson Watch，quest 10781，影月谷）里召唤出来的伊利达雷大领主（entry 19797，71级精英，`UnitClass=2`，靠 `creature_ai_scripts` 定时释放，不走 `creature_spell_list`）"烈焰风暴"（法术16102）单次命中8238火焰伤害。同一根因（`Attributes` 含 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`，`spellLevel=20`，71级缩放系数约21.97倍，比70级略高）。
**这次情况比前四次更复杂，需要特别注意**：
1. **法术ID被多个不同等级的怪物共用**——`creature_ai_scripts` 里查到至少6个怪在用同一个 spell 16102："Illidari Highlord"(71级，本次目标)、"Bladespire Battlemage"(67级)、"Bone Mage"(60级)、"Rage Talon Flamescale"(58级)、"Gordok Mage-Lord"(57级)等，横跨经典旧世界到TBC内容。**不能像前四次那样单纯按法术ID覆盖**，必须同时判断施法者是不是这个怪（`m_caster->GetEntry() == 19797`），否则会连带影响57-67级那几个完全不相关的怪物。
2. **完全没有外部参考数据**——问了两个独立AI都明确查不到这个技能的实测伤害（这是野外任务遭遇战，不在 `Schaka/TBC-research` 覆盖范围内，也没有其他信源），两边都正确拒绝编数字。
3. **场景是单人/小队野外任务遭遇战**，非副本，且该任务第3波会同时召唤4个大领主，玩家可能同时面对多个在放这个技能的怪。
数值：由于完全没有依据，**用户结合"单人任务场景、非副本、可能同时面对4个"这些因素直接给出保守估计 `urand(1500,2200)`**，明确是纯人工判断，不是查证/推算出来的数字，上线后需要玩家实测反馈校准，风险比前四次更高。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 新增 `case 16102:`，内部判断 `m_caster->GetEntry() == 19797` 才覆盖伤害，其他共用同一法术ID的怪物不受影响，不改动法术ID/数据库。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈（这条的数值置信度最低，重点关注玩家反馈）。

### 影月谷"库斯卡海妖"水箭伤害过高（2026-08-12）
玩家反馈影月谷（Shadowmoon Valley，map 530，库斯卡角/Coilskar Point一带，18个固定野外刷新点）库斯卡海妖（entry 19768，68-69级，**`Rank=0`普通小怪、非精英**，`UnitClass=2`，靠 `creature_ai_scripts` 施放）"水箭"（法术32011）伤害过高。同一根因（`Attributes=524288` 含 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`，`spellLevel=20`；68/69级缩放系数分别约16.4/18.8倍，比之前几个70+级怪略低但仍然远超合理范围）。
**排查过程中的一处订正**：一开始误以为玩家说的"暗影迷宫"指向副本内容，核实发现 entry 19768 全部18个刷新点都在 map 530 开放世界，跟暗影迷宫（map 555）对不上；玩家确认是记错了，实际位置是影月谷野外，核实通过。
**跟"烈焰风暴"同一类复杂情况——法术ID被共用**：`creature_ai_scripts` 查到 Coilskar Sorceress(19767)、Keeper of the Cistern(20795)、Lakaan(21416)、Skettis Surger(21728)、Bloodscale Wavecaller(20089) 都在用同一个 spell 32011，同样只能精确判断施法者是这个怪（`m_caster->GetEntry() == 19768`），不能笼统按法术ID覆盖。
数值：同样完全没有外部参考数据（`Schaka/TBC-research` 只覆盖副本/团本，不涉及野外怪）。**用户结合"这是普通小怪、不是精英，正常刷图不该被打这么疼"给出保守估计 `urand(400,700)`**，明显低于本轮其他几个精英怪的修复数值，符合"普通怪强度应该更低"的直觉，纯人工判断，上线后需要玩家实测反馈校准。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 新增 `case 32011:`，内部判断 `m_caster->GetEntry() == 19768` 才覆盖伤害，其他共用同一法术ID的怪物不受影响，不改动法术ID/数据库。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。

### 特罗凯森林"斯克提斯唤魂者"暗影箭伤害过高（2026-08-12）
玩家反馈特罗凯森林斯克提斯（Skettis，map 530，阿拉卡尔鸦人日常任务区）唤魂者（entry 21911，70-71级，**`Rank=0`普通小怪、非精英**，`UnitClass=2`，走 `creature_ai_scripts`）"暗影箭"（法术20298）伤害过高，同一根因（`Attributes` 含 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`，`spellLevel=20`，70-71级缩放系数约21.6-22倍）。
同样是法术ID被共用：`creature_ai_scripts` 查到 Dreadmaul Warlock、Outcast Necromancer、Gordunni Warlock 等好几个等级差很大的旧世界怪都在用同一个 spell 20298，只判断施法者是这个怪（`m_caster->GetEntry() == 21911`）才覆盖。
数值：同样没有外部参考数据。参照"库斯卡海妖"（同为非精英野怪，68-69级给了400-700）的档位，按等级略高给 `urand(500,800)`，纯人工判断。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 新增 `case 20298:`，内部判断施法者entry，其他共用同一法术ID的怪物不受影响，不改动法术ID/数据库。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。

### 特罗凯森林"斯克提斯风行者"奥术箭伤害过高（2026-08-13）
玩家反馈同一区域（Skettis，map 530）风行者（entry 21649，70-71级，`Rank=0`非精英，`UnitClass=2`，走 `creature_ai_scripts`）"奥术箭"（法术13901）伤害过高，跟"斯克提斯唤魂者"是**同一区域、同一等级档、同一非精英强度**的怪，同一根因。法术ID同样被 Vir'aani Arcanist、Warp Monstrosity、Lady Shav'rar、Sunfury Summoner、Netherwing Ally、Darkcrest Sorceress 等好几个不相关怪物共用，只判断施法者entry才覆盖。
数值：没有外部参考数据，直接沿用"斯克提斯唤魂者"同一档位的 `urand(500,800)`，保持同区域怪物强度一致。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 新增 `case 13901:`，内部判断 `m_caster->GetEntry() == 21649` 才覆盖，不改动法术ID/数据库。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。

### 影月谷"暗影议会术士"暗影箭伤害过高（2026-08-13）
玩家反馈影月谷暗影议会术士（entry 21302，67级，`Rank=0`非精英，`UnitClass=2`，走 `creature_ai_scripts`，map 530）"暗影箭"（法术9613）伤害过高，同一根因。
**这是目前遇到过共用范围最广的法术ID**：`creature_ai_scripts` 查到 60+ 个完全不相关的怪物在用同一个 spell 9613，横跨经典旧世界（藏宝海湾/祖尔法拉/通灵学院等）到TBC全区域（奈瑟匿域/太阳之井/奥金顿等），只判断施法者是这个怪（`m_caster->GetEntry() == 21302`）才覆盖，其余全部不动。
数值：网上搜到"544-607"的说法核实后发现是**另一个法术ID(27209，玩家职业技能版本)**的数据，不是这个NPC通用模板，没有采用，避免张冠李戴。没有可用外部参考。按同一非精英野怪档位、67级比之前几个68-71级的略低，给 `urand(350,600)`，保持等级递进关系。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 新增 `case 9613:`，内部判断施法者entry才覆盖，不改动法术ID/数据库。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。

### 影月谷"死亡熔炉召唤者"+"愤怒的火灵"+"愤怒的地灵"伤害过高（2026-08-13，一次性提交3条）
玩家一次反馈了3个同区域（影月谷 quest 10458"愤怒的火与土之魂"，用图腾捕获元素魂魄的任务，map 530）的怪，均68-69级、`Rank=0`非精英、走 `creature_ai_scripts`，同一根因：
1. **死亡熔炉召唤者（20872）暗影箭 = 法术9613**——就是上面"暗影议会术士"那个60+共用的法术ID，直接在已有的 `case 9613:` 里追加 `m_caster->GetEntry() == 20872` 判断，沿用同一数值 `urand(350,600)`。
2. **愤怒的火灵（21061）邪能火球 = 法术36247**——法术ID被 "Incandescent Fel Spark"（22323，70-71级，另一区域）共用，该怪没人反馈过，不动，只判断 `m_caster->GetEntry() == 21061`。没有外部参考数据，按非精英野怪档位给 `urand(400,700)`（跟"库斯卡海妖"同档）。
3. **愤怒的地灵（21050）火焰投石 = 法术38498**——**未被任何其他怪物共用**，唯一使用者，无需entry判断，直接按法术ID覆盖，同样给 `urand(400,700)`。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 里 `case 9613:` 追加一个entry条件，新增 `case 36247:`（entry判断）和 `case 38498:`（无需entry判断，唯一使用者），均不改动法术ID/数据库。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。

### 影月谷"日蚀法师"+"大型魔火双帆龙"伤害过高（2026-08-13）
同区域另外两个反馈，均68-69级、`Rank=0`非精英：
1. **日蚀法师（19796）"上古之火"，玩家给的法术是37986，但排查后发现要修的其实是37988**——37986本身是一个"每4秒触发另一个法术"的周期光环（`EffectApplyAuraName1=23`=`PERIODIC_TRIGGER_SPELL`），这个光环类型**不在缩放判定的"伤害类光环"名单里**（判定名单是 `PERIODIC_DAMAGE`/`PERIODIC_LEECH`/`SCHOOL_ABSORB`/`POWER_BURN_MANA`/`PERIODIC_TRIGGER_SPELL_WITH_VALUE`/`PERIODIC_MANA_LEECH` 这6种，`PERIODIC_TRIGGER_SPELL` 不含"_WITH_VALUE"后缀，不在其中），所以37986自己不受影响；真正造成伤害的是它触发的**法术37988**（同名"Ancient Fire"，独立的直接命中效果，自己带 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`），这个才是bug真正发生的地方。未被共用，直接按法术ID覆盖，同档给 `urand(400,700)`。
2. **大型魔火双帆龙（21462）邪能火球 = 法术37945**——跟"愤怒的火灵"的36247是完全相同的原始数值模板（只是ID不同），未被共用，沿用同一数值 `urand(400,700)`。
修复：`SpellEffects.cpp` `EffectSchoolDMG` 新增 `case 37988:` 和 `case 37945:`，均无需entry判断（唯一使用者），不改动法术ID/数据库。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。

### 影月谷"军团要塞"玛卡扎顿火焰之雨伤害过高（2026-08-12）
玩家反馈影月谷军团要塞（Legion Hold）任务精英玛卡扎顿（entry 21501，68-69级，`Rank=1`精英，`UnitClass=1`，两个深渊魔王之一，走 `creature_ai_scripts`）"火焰之雨"（法术38741）伤害异常。同一根因（`Attributes` 含 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`，`spellLevel=20`）。
**这次跟之前几个的关键区别——技能本身就是持续伤害光环，不走 `EffectSchoolDMG`**：`Effect1=27`(PERSIST_AREA_AURA) + `EffectApplyAuraName1=3`(PERIODIC_DAMAGE，每3秒跳一次)，是纯粹的地面持续伤害区域，不是"直接命中"类效果，所以完全不会经过前8次用来修复的 `Spell::EffectSchoolDMG` 函数。**修复位置改在缩放公式本身发生的地方**（`Object.cpp` 的 `CalculateSpellEffectValue`，针对 `spellProto->Id`+`effect_index` 直接覆盖），这也是排查这条时才发现"毒液箭DoT遭漏修"这个问题的契机（见上面订正）。
同样是法术ID被共用：`creature_ai_scripts` 查到 Morgroron(21500,68-69级)、Azaloth(21506,70级)、Throne-Guard Champion(22302,72级) 也在用同一个 spell 38741，只判断施法者是这个怪（`unitCaster->GetEntry() == 21501`）才覆盖。
数值：Wowhead 技能描述显示"每3秒50点火焰伤害"，但这应该是客户端按现代参照等级重算的展示值（不是数据库原始 `EffectBasePoints1=167`），不能直接当目标值用。这个技能是"可走位躲开的地面AoE"设计（不是无法躲避的爆发伤害），如果每跳定得跟单次爆发技能一样高，多跳不躲会变得过于致命，不符合机制设计意图。用户按此判断给出保守估计 `irand(300,600)`/跳，纯人工判断。
修复：`Object.cpp` `CalculateSpellEffectValue` 补充判断 `effect_index==EFFECT_INDEX_0 && spellProto->Id==38741 && unitCaster->GetEntry()==21501` 才覆盖，其他共用同一法术ID的怪物不受影响，不改动法术ID/数据库。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。

### 英雄奴隶围栏"荒土奴隶"寒冰箭+冰霜新星伤害过高（2026-08-13）
玩家反馈英雄奴隶围栏（Slave Pens Heroic，Coilfang Reservoir）荒土奴隶（玩家给的entry 17963 是**普通**难度实体，62-63级；实际触发这两个法术的是它的英雄版 **entry 19902 "Wastewalker Slave (1)"，70-71级**，`creature_spell_list Id=1990201`）"寒冰箭"（法术**12675**）+"冰霜新星"（法术**15531**）伤害过高。
**排查中发现一个之前遗漏的严重问题——早前几次"蒸汽地窖"修复的共用检查不完整**：当时对 22582/37865（冰霜震击）、37272/37862（毒液箭）确实查过 `creature_spell_list` 确认专属，但对 **12675/37930（寒冰箭）和 15234/37664（闪电箭）没有反查这几个法术ID是否被其他 `creature_spell_list` 复用**。这次反查全部8个已修复的蒸汽地窖法术ID，发现：
- `12675` 被 **5个** spell_list 引用（其中2个是有效怪物：Coilfang Sorceress普通=17722、**Wastewalker Slave英雄=19902**，其余3个是孤儿数据、未被任何怪物实际使用）
- `15234` 被 **3个** spell_list 引用（Coilfang Siren普通=17801、Coilfang Enchantress普通=17961，另1个孤儿）
- `37664` 被 **2个** spell_list 引用（Coilfang Enchantress英雄=19887、Coilfang Siren英雄=20623）
- `22582`/`37865`/`37272`/`37862` 确认仍然是单一专属，之前的核实没问题

**修复**：
1. **寒冰箭数值不用改**——巧的是 `Schaka/TBC-research` issue #8（"Slave Pens Heroic pre-nerf"）独立记录荒土奴隶(英雄)寒冰箭为"1300-1780"，跟我们已经定的普通盘牙巫师数值（1290-1760）几乎完全一致，两个不同副本不同难度的怪碰巧是同一强度层级。代码逻辑上补了注释说明这个ID被两边共用，不需要额外的施法者判断（因为两边用同一个值都对）。
2. **新增"冰霜新星"（15531）针对荒土奴隶(19902)的覆盖**：`urand(1040,1180)`，同样来自 issue #8 的荒土奴隶记录。这个法术还被 Coilfang Sorceress(英雄)自己的技能组、Tidal Surger(普通/英雄) 共用，都还没有玩家反馈/没研究过，特意加了 `m_caster->GetEntry()==19902` 判断，不动其他几个未经研究的怪。
3. **补上"闪电箭"（15234/37664）的施法者判断**：加了 `m_caster->GetEntry()==17801 || ==20623`（只精确命中 Coilfang Siren 普通/英雄），Coilfang Enchantress（17961普通/19887英雄）没人反馈过，故意不去动它，避免用研究给Coilfang Siren的数值去套一个完全没验证过的怪。
**状态**：✅ 代码已实施，等待编译部署 + 实测反馈。以后核对204个清单剩余技能时，`creature_spell_list` 的共用检查要对每一个法术ID都做，不能假设"看起来像专属的就是专属"。

### ⚠️ 系统性发现：`SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL` 缩放溢出是批量问题，不止个案（2026-08-12）
排查冰霜震击时用 SQL 批量筛查"带 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL` 属性 + `spellLevel` 远低于实际施法怪物等级（差值≥30级）"这个特征，一次性查出 **204个不同法术、涉及247个不同怪物**存在同一种缩放溢出隐患，覆盖奥金顿、蒸汽地窖、赛斯克大厅、卡拉波神殿、影月谷野外怪、旧希尔斯布莱德等大量副本和野外区域（已确认的"暗影新星""冰霜震击"都在这份清单里，验证了排查逻辑正确）。
**结论**：不适合继续用"发现一个、手动查资料、加一个`case`"这种一对一方式处理，204个技能逐个查证不现实。

**排查范围有缺口，实际受影响数量可能更多**：本轮后续修复"烈焰风暴"（16102）、"水箭"（32011）时发现，这两个都是通过老式 `creature_ai_scripts` 系统施法（`creature_template.SpellList=0`），而当初排查204个用的 SQL 只 JOIN 了 `creature_spell_list`（新版系统），完全没覆盖走 `creature_ai_scripts` 的这批怪——204这个数字只是"新系统"部分，"老系统"部分还没排查过，实际总数会更多。以后系统性修复时需要把这条路径也覆盖进筛查 SQL。

**另一处缺口——判定逻辑不是只看"效果类型"，还要看"光环类型"，且不是所有受影响效果都走同一个下游函数**：排查"毒液箭"时发现，缩放判定优先看 `EffectApplyAuraName`（光环类型是 `PERIODIC_DAMAGE`/`PERIODIC_LEECH`/`SCHOOL_ABSORB`/`POWER_BURN_MANA`/`PERIODIC_TRIGGER_SPELL_WITH_VALUE`/`PERIODIC_MANA_LEECH` 这几种照样会被缩放），只有查不到光环类型时才退回看"效果类型"（`SCHOOL_DAMAGE`等）。之前几次修复只处理了"直接命中"这一种（走 `Spell::EffectSchoolDMG`），漏了"持续伤害光环"这一种（`Effect=27`纯光环技能如"火焰之雨"完全不经过 `EffectSchoolDMG`，必须在 `CalculateSpellEffectValue` 本身覆盖）——204个清单里可能还有别的技能是这种"纯光环"或"直接命中+被忽略的DoT"结构，逐个核对时要把 `EffectApplyAuraName1/2/3` 也纳入检查，不能只看 `Effect1/2/3` 的表面类型。

**第三处缺口——法术ID可能只是"容器"，真正的伤害来自它触发的另一个法术**：排查"日蚀法师"上古之火时发现，玩家反馈的法术ID（37986）本身是 `PERIODIC_TRIGGER_SPELL`（光环类型23，纯粹"每N秒触发一次另一个法术"，不在缩放判定名单里，自己不受影响），真正带 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`、造成伤害的是它 `EffectTriggerSpell1` 指向的另一个独立法术ID（37988）。以后核对204清单/处理新反馈时，如果法术本身查出来"没有缩放属性"或"效果类型对不上"，要顺着 `EffectTriggerSpell1/2/3` 再查一层，不能看到"没问题"就直接放过。

**根因定位到公式本身**：`Object.cpp` 的 `CalculateSpellEffectValue`，`value = value * (CLSPowerCreature / CLSPowerSpell)`，`CLSPower*` 来自 `creature_template_classlevelstats.BaseDamage`——这张表按等级增长是陡峭曲线而非线性（同职业20级→70级差21.6倍），公式本身没有任何"等级差过大就封顶/失效"的保护，导致被套用到"20级模板 vs 70级施法者"这种远超设计初衷的极端场景时直接崩坏。**已核实这段代码（含 `// TODO: Drastically beter than before, but still needs some additional aura scaling research` 这条注释）在 upstream mangos-tbc 里逐字节一致存在**——不是 Nmangos-tbc 自己的问题，是继承自官方仓库的共享缺陷，官方自己也承认这块"还需要进一步研究"，不是我们独有的坑。

**候选修复方向**（都是引擎级改动，需要专门离线核算校准后再动手，不适合顺手改）：
- **方案A**：给缩放倍数本身设上限（`std::min(ratio, 上限)`）——简单，但"上限该定多少"缺乏依据，容易一刀切过头或不够。
- **方案B（倾向）**：不直接限制倍数，而是限制查表用的"等级差"（比如 `effectiveSpellLevel = max(spellProto->spellLevel, casterLevel - 20)`），让缩放曲线本身不被拉到离谱区间，同时数值来源仍然是同一套曲线，不是拍脑袋的魔法数字。
- 改动前必须用"暗影新星""冰霜震击"这两个已经手动验证过的正确答案做校准（改完公式后重新算一遍这两个技能，看结果跟目前手动 `case` 覆盖的数值是否接近），改动后要评估要不要撤掉这两个手动 `case` 覆盖（避免两套机制叠加）。

**状态**：⏸️ 待办，尚未开始处理，本次只处理了清单里已被玩家反馈的"暗影新星""冰霜震击"两个，其余202个 + 公式级修复作为独立大任务留待后续排期。排查用的 SQL：
```sql
SELECT DISTINCT s.Id, s.SpellName, s.spellLevel, ct.entry, ct.name, ct.MinLevel, ct.Rank,
       (CAST(ct.MinLevel AS SIGNED) - CAST(s.spellLevel AS SIGNED)) AS levelGap
FROM spell_template s
JOIN creature_spell_list csl ON csl.SpellId = s.Id
JOIN creature_template ct ON ct.SpellList = csl.Id
WHERE (s.Attributes & 0x80000) != 0
  AND s.spellLevel > 0
  AND (CAST(ct.MinLevel AS SIGNED) - CAST(s.spellLevel AS SIGNED)) >= 30
ORDER BY levelGap DESC;
```

---

## upstream（官方 cmangos/mangos-tbc）逐个提交审查

`v3` 分支已加 `upstream` 远程（`https://github.com/cmangos/mangos-tbc.git`），当前落后 upstream/master 69 个提交（领先 20 个本地/Nmangos-tbc 自己的改动）。逐个从最早的开始审查，一条一条处理，分析完先记录在这里，确认后再实施（合并进仓库文件 + 同步到 `tbcmangosdev`）。

**当前进度**：已审查到第 24 条（第24条改动太多，用户决定暂不合并），下次从第 25 条继续。

| # | 提交 | 摘要 | 影响 | 状态 |
|---|---|---|---|---|
| 1 | `ed731ae4d` | 塞斯克鱼人湾巨蜥"毒液箭雨"(38655) `MaxAffectedTargets` 0→10 | SSC 单个精英怪AoE命中人数上限，低风险 | ✅ 已 cherry-pick（`f2f90e184`），`tbcmangosdev`/`tbcmangos2` 已执行等效 UPDATE |
| 2 | `15c7a3ee9` | 玄冰石阶通关后逃生传送门重进不可交互 | 5人本QoL修复，低风险 | ✅ 已 cherry-pick（`463c976b2`），待编译部署 |
| 3 | `5c9580a64` | 逃生传送门法术(46841)标记为 TRIGGERED（配套#2，抓包比对） | 纯触发方式修正，低风险 | ✅ 已实施 |
| 4 | `ff681a044` | `CheckTarget` 对纯 `TARGET_FLAG_UNIT` 目标跳过友敌校验 | 核心引擎级改动，作者自述半成品（ALLY/ENEMY标记未处理），影响面广 | ⏭️ 跳过，待更多证据 |
| 5 | `ea90dbcb1` | 斯坦索姆 Maleki the Pallid"冰封墓穴"命中清空目标仇恨 | 单一5人本BOSS机制，低风险 | ✅ 已 cherry-pick（`4ff66b28d`），待编译部署 |
| 6 | `2d9e0e24a` | 地狱火脓水沼泽 Hungarfen 孢子云DoT误伤自己（可能被bug秒杀）+缩小技能漏施放 | 单一5人本BOSS核心机制修复，价值较高；需代码+`spell_scripts`绑定两步 | ⏸️ 待确认，尚未实施 |
| 7 | `aa39545ce` | 怪物"说话"广播范围按可见距离(AOI)比例放大 | 纯客户端体验层，无副作用，低风险 | ✅ 已 cherry-pick（`7279de930`），待编译部署 |
| 8 | `10b579ceb` | 补充缺失的 spell_template 数据行：32432 "Full Heal / Mana"（纯数值，无对应 Effect 类型异常） | 纯附加 INSERT，但当前 Nmangos-tbc 代码/DB 均无处引用该 ID，没有实际用途 | ⏭️ 用户判断没必要实施，已撤销（revert 提交 `e933a8b47`，`tbcmangosdev` 已删除对应行并核实） |
| 9 | `55782dc5b` | 邮件到达提醒弹窗最多显示 2 封→3 封 | 纯客户端展示，低风险 | ✅ 已 cherry-pick（`b7a3ef146`） |
| 10 | `b8e2c77ac` | `ITEM_DYNFLAG_UNK1` 重命名为 `ITEM_DYNFLAG_TRANSLATED`+注释；`SMSG_READ_ITEM_FAILED` 补两行注释（未激活代码） | 纯命名/注释澄清，零功能变化 | ✅ 已 cherry-pick（`56dfc52e9`） |
| 11 | `d01165a0c` | `SpellTargetMgr` 目标消费判定补两处 `TARGET_TYPE_NONE` 分支（针对 spell 43178/51957 实测问题） | 核心目标校验，改动小且有具体证据支撑，但波及全体法术的共用逻辑，具体影响面未逐一排查 | ⏸️ 用户决定先不合并、观察，已 revert（`40ae7c51d`） |
| 12 | `e61ca75bb` | PvP 击杀荣誉的"对方段位加成"取值改为读 `LIFETIME_MAX_PVP_RANK` 字段而非当前称号 | **本仓库这个字段从未被任何代码写入过（恒为0），且同区域 `CONDITION_PVP_RANK` 也是硬编码 `return false`——这套经典PvP段位系统在本库本来就是占位/未实现状态**。合并后段位加成会变成恒定按0计算 | ⏭️ 用户决定跳过不合并，保留现有基于称号的旧逻辑 |
| 13 | `566ea5b87` | AV 战场"地图完成"荣誉奖励漏调用 `GetBonusHonorFromKill()` 转换（同文件其他所有奖励调用点都有转换，唯独这处没有，5年老bug） | 单一战场，荣誉数值偏低，同文件交叉核对确认 | ✅ 已 cherry-pick（`4eb1ac45d`），待编译部署 |
| 14 | `fb94568ea` | `SMSG_SUMMON_REQUEST` 发送 `GetZoneId()`（区域）改为 `GetAreaId()`（子区域），修正传送确认框显示的召唤者位置 | 纯客户端显示，低风险 | ✅ 已 cherry-pick（`f7df5905b`） |
| 15 | `7bf1caee6` | `SMSG_SPELL_UPDATE_CHAIN_TARGETS`（引导技能连锁目标更新包）按抓包新证据调整结构 | 客户端视觉表现（引导法术连锁目标线），低风险 | ✅ 已 cherry-pick（`e957f270d`） |
| 16 | `a8a5701da` | 同上，第二次按更多抓包证据再调整（#15 的后续修正） | 同上 | ✅ 已 cherry-pick（`cc8f79176`），待编译部署 |
| 17 | `83135c4cb` | 新增 `Player::SendOpenContainer`，装入背包槽后自动发送 `SMSG_OPEN_CONTAINER` 弹出容器窗口 | 纯客户端 QoL 新功能，自包含，低风险 | ✅ 已 cherry-pick（`63c45a9d5`） |
| 18 | `9873b5955` | `CMSG_BUY_BANK_SLOT` 补上 slot 上限校验，防止客户端传入越界值 | 输入合法性加固，低风险 | ✅ 已 cherry-pick（`05e2a3dbd`） |
| 19 | `1209c1f93` | 修复 `SpellCastArgs` 未初始化成员 `m_itemSet`/`m_itemTarget` | 跟本仓库 2026-08-04 独立修复的 Mana Tombs 崩溃是**同一个 bug、同一处修复**，本地代码已完全一致 | ✅ 已通过本地独立修复覆盖，无需重复 cherry-pick |

| 20 | `9f4060f3c` | MinGW 编译兼容性调整（`_MSC_VER`→`_WIN32`、winmm链接位置） | 对现用的 MSVC 编译零行为差异，纯粹是给 MinGW 工具链铺路 | ✅ 已 cherry-pick（`fe48562e9`） |
| 21 | `022a8f141` | 法术14108"剧毒蛇皮毒药" `Dispel` 4→0，修正施法者对毒免疫时连自己都被误挡、放不出这个效果的问题 | `tbcmangosdev` 当前该字段已经是0，此次合并对现有数据零实际影响，只是让基础建库文件保持与upstream一致 | ✅ 已 cherry-pick（`2101d99e6`），无需对DB做任何操作 |
| 22 | `b8b83dcf4` | CppCheck 静态分析扫出的6处小问题：5处是等价写法清理（无符号数判断、冗余分支等），1处是真实小bug（`SpellCastTargets`拷贝赋值漏拷贝`m_CorpseTarget`字段） | 前5处零行为变化；第6处影响面窄（仅目标信息被复制且涉及尸体目标的法术），但是真实修复 | ✅ 已 cherry-pick（`b172b4a67`） |
| 23 | `f8926ff41` | 反作弊模块 `antispam.cpp` 两处可变参数函数补齐缺失的 `va_end`，修正未定义行为 | 只影响反作弊内部GM通知日志函数，不涉及游戏逻辑 | ✅ 已 cherry-pick（`0ab5ef6e9`） |
| 24 | `314069eeb` | CppCheck "缺失override" 批量清理，涉及32个文件：补virtual/override关键字、删空虚析构、删子类里跟父类重复的成员声明 | 改动文件数多；每类改动本身是编译器强制校验或纯清理，概念风险不高，但体量大 | ⏸️ 用户觉得改动太多，暂不合并 |

**待办**：#6 需要用户确认；#12 已跳过；#24 暂不合并；#25 及之后的提交尚未审查，继续逐条进行。
