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

### ⚠️ 系统性发现：`SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL` 缩放溢出是批量问题，不止个案（2026-08-12）
排查冰霜震击时用 SQL 批量筛查"带 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL` 属性 + `spellLevel` 远低于实际施法怪物等级（差值≥30级）"这个特征，一次性查出 **204个不同法术、涉及247个不同怪物**存在同一种缩放溢出隐患，覆盖奥金顿、蒸汽地窖、赛斯克大厅、卡拉波神殿、影月谷野外怪、旧希尔斯布莱德等大量副本和野外区域（已确认的"暗影新星""冰霜震击"都在这份清单里，验证了排查逻辑正确）。
**结论**：不适合继续用"发现一个、手动查资料、加一个`case`"这种一对一方式处理，204个技能逐个查证不现实。

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
