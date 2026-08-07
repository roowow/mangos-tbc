# 测试库基准线变更记录

记录以 `tbcmangosdev`（测试库）为基准建立新基准线过程中，从各数据源同步过去的数据变更。跟 `fix.sql`（单条内容/bug修复）分开记录，这里只记录"批量基准同步"性质的操作。

## 2026-08-04 — 从旧生产库 tbcmangos 同步全部 locale 翻译表

**背景**：测试库重置后，`tbcmangosdev` 的 locale 翻译数据落后于旧生产库 `tbcmangos`（包含多年积累的翻译修正）。以 `tbcmangos` 为翻译数据的权威来源，全量同步到 `tbcmangosdev`，作为新基准线的一部分。

**核对范围**：`tbcmangos` 共有 12 张 `locales_*` 表，逐一核对列结构（均与 `tbcmangosdev` 一致，可直接 REPLACE INTO），再用 `CHECKSUM TABLE` 核对内容：

| 表 | 同步前状态 | 结果 |
|---|---|---|
| locales_areatrigger_teleport | dev 为空（0 行，tbcmangos 48 行） | 已同步，48 行 |
| locales_creature | 行数一致(18814)但内容不同(checksum不同) | 已同步，checksum 一致 |
| locales_gameobject | 内容已一致(checksum相同) | 无需变更（仍重新应用，无副作用） |
| locales_gossip_menu_option | dev 为空（0 行，tbcmangos 3198 行） | 已同步，3198 行 |
| locales_item | 行数一致(25173)但内容不同 | 已同步，checksum 一致 |
| locales_item2 | 内容已一致(checksum相同) | 无需变更（仍重新应用，无副作用） |
| locales_npc_text | dev 为空（0 行，tbcmangos 5888 行） | 已同步，5888 行 |
| locales_page_text | 行数一致(1431)但内容不同 | 已同步，checksum 一致 |
| locales_points_of_interest | 行数一致(379)但内容不同 | 已同步，checksum 一致 |
| locales_quest | 行数一致(6517)但内容不同 | 已同步，checksum 一致 |
| locales_questgiver_greeting | dev 为空（0 行，tbcmangos 37 行） | 已同步，37 行 |
| locales_trainer_greeting | dev 为空（0 行，tbcmangos 661 行） | 已同步，661 行 |

**未触及的表**（`tbcmangosdev` 独有，`tbcmangos` 里不存在，属于新版本 tbc-db 引入的内容，不受此次同步影响）：`locales_area`、`locales_areatrigger`、`locales_broadcast_text`、`locales_faction`、`locales_spell`、`locales_taxi_node`。

**方法**：`mysqldump --no-create-info --replace`（按主键 REPLACE INTO，不会删除 dev 独有的行，只覆盖/补齐 tbcmangos 里存在的条目）从 `tbcmangos` 导出这 12 张表，整体导入 `tbcmangosdev`，导入后用 `CHECKSUM TABLE` 逐表核对确认与 `tbcmangos` 完全一致。

**状态**：已应用到 `tbcmangosdev`，全部 12 表 checksum 核对通过。生产库 `tbcmangos2` 未涉及，如需要请另行确认是否同步。

## 2026-08-04 — 修复 gameobject 名称不显示中文（数据库缺失 schema 迁移，非代码bug）

**现象**：抽查游戏内物体名字（"Bank of Orgrimmar" 银行、"Scroll of Scourge Magic" 卷轴），确认客户端是 zhCN 版本、DB 里 `locales_gameobject` 的 `name_loc4` 数据完全正确（两库一致），`.reload all_locales` 和整服重启都做过，仍然显示英文。

**初步误判（已撤销）**：一开始怀疑是 `src/game/Globals/ObjectMgr.cpp` 里 `ObjectMgr::LoadGameObjectLocales()` 的查询列名（`opening_text_loc1..8`/`closing_text_loc1..8`）跟表结构（`castbarcaption_loc1..8`）对不上导致查询报错（`ERROR 1054: Unknown column 'opening_text_loc1'`），一度把代码改成查 `castbarcaption_loc*`。**这个方向是错的，已经改回原样**。

**真正根因**：仓库自带的官方迁移文件 `Nmangos-tbc/sql/updates/mangos/s2485_01_mangos_closing_text.sql` 本来就是要把 `locales_gameobject` 的 `castbarcaption_loc1..8` 改名成 `opening_text_loc1..8`，并新增 `closing_text_loc1..8` 列——也就是说代码从一开始写的就是对的，对应的正是这次迁移之后应有的表结构。核查发现这次迁移在 `tbcmangosdev` 上**只做了一半**：`gameobject_template` 表已经改好（有 `OpeningText`/`ClosingText` 列），但 `locales_gameobject` 表没跟着改，还停留在旧的 `castbarcaption_loc*`。`db_version` 里的版本标记显示已经到 `s2490_01`（比这次迁移新很多），但跟实际表结构对不上，说明这个标记不可信，大概率是重置时用了不一致的数据源拼出来的库。另外确认了这不是本次重置才有的问题——连重置前的旧生产库 `tbcmangos` 也是同样停留在 `castbarcaption_loc*`，同一处迁移缺失由来已久。

**修复**：
1. 撤销了 `Nmangos-tbc/src/game/Globals/ObjectMgr.cpp` 里的误改，代码恢复成原样（跟 mangos-tbc 原始代码逐字节一致），**无需重新编译**。
2. 在 `tbcmangosdev` 上补跑了这次迁移里 `locales_gameobject` 缺失的那部分（`gameobject_template` 那部分已经做过，未重复执行）：8列改名 `castbarcaption_loc1..8` → `opening_text_loc1..8`，新增 8列 `closing_text_loc1..8`（新列，暂时是空的，后续有对应内容再补）。
3. 用原始未改动的代码查询语句实测跑通，确认能正确取到 173216/180511 的 `name_loc4` 中文数据。

**状态**：✅ `tbcmangosdev` 的 schema 已修复，数据完整无损（改名保留了原有数据，新增列不影响现有数据）。`mangos-tbc`（v2）和生产库 `tbcmangos2`/旧备份库 `tbcmangos` 都有同样的迁移缺失，本次未处理，如果之后用到再排期。

## 2026-08-04 — 修复 SpellCastArgs 未初始化成员导致的崩溃（Mana Tombs / Pandemonius Void Blast）

**现象**：生产服崩溃日志 `crash2228.txt`，SIGSEGV，崩溃点 `SpellCastTargets::setItemTarget`（Spell.cpp:184，`item->GetObjectGuid()`），调用链最终追到 Mana Tombs 副本 BOSS Pandemonius 的 Void Blast 连锁施法脚本 `boss_pandemonius.cpp:84-86`（`VoidBlast::OnCast`）。

**根因**：`src/game/Spells/Spell.h` 的 `SpellCastArgs` 类默认构造函数（第318行）漏初始化了两个私有成员 `m_itemSet`（bool）和 `m_itemTarget`（Item*），构造出来的对象里这两个字段是栈上的垃圾值。Pandemonius 的 Void Blast 脚本只调用了 `.SetScriptValue(...)`，从没调用 `.SetItemTarget(...)`，于是这两个字段一直是垃圾数据；崩溃日志里刚好显示 `m_itemSet = 193`（非0，被判定为"已设置"）、`m_itemTarget` 是个乱指针。下游 `Unit::CastSpell`（Unit.cpp:1832-1833）看到 `IsItemTargetSet()` 为 true，就拿这个垃圾指针去调用 `setItemTarget()`，最终解引用崩溃。

**关键点**：这不是 Pandemonius 专属的 bug，是 `SpellCastArgs` 通用类本身的缺陷——任何代码构造它又不设置物品目标，都有几率触发（取决于当时栈内存里恰好是什么），概率性发作，不容易复现。核实过 `mangos-tbc` 和 `Nmangos-tbc` 两边这段代码完全一样，都有这个问题；按决定本次只修 `Nmangos-tbc`。

**修复**：在 `Nmangos-tbc/src/game/Spells/Spell.h` 的 `SpellCastArgs()` 构造函数初始化列表补上 `m_itemSet(false), m_itemTarget(nullptr)`。

**状态**：⚠️ 代码已改，**尚未编译部署**，需要重新编译 `mangosd` 并重启才能生效。`mangos-tbc`（v2）有同样的问题，本次按决定未同步修复。

## 2026-08-04 — 补合并 boss_thermaplugg.cpp 的空指针判断（gnomeregan）

**背景**：之前在 `mangos-tbc`/v2 已经合并过一次"thermaplugg null-check"修复（早前会话记录），逐字节对比两个仓库的 `boss_thermaplugg.cpp` 发现 `Nmangos-tbc` 一直没有跟上这处修复。

**问题**：`ActivateBombThermaplugg::OnEffectExecute`（spell 11511/11795，"Activate Bomb A/B"，负责随机激活一个炸弹脸）里，`Unit* target = spell->GetUnitTarget();` 取到的目标直接被拿去调用 `target->GetInstanceData()`，如果 `GetUnitTarget()` 在某些边界情况下返回空指针，会直接空指针解引用崩溃。`mangos-tbc` 早就补了 `if (!target) return;`，`Nmangos-tbc` 一直没有。（同文件里 `GOUse_go_gnomeface_button` 那处判空两边都已经有，不受影响。）

**修复**：在 `Nmangos-tbc/src/game/AI/ScriptDevAI/scripts/eastern_kingdoms/gnomeregan/boss_thermaplugg.cpp` 的 `ActivateBombThermaplugg::OnEffectExecute` 里补上 `if (!target) return;`，现在跟 `mangos-tbc` 逐字节一致。

**状态**：✅ 代码已改，**尚未编译部署**，需要重新编译 `mangosd` 才能生效。

## 2026-08-05 — 合并 origin/master 两个新提交到 v3

**背景**：`origin`（Nightingale9002/Nmangos-tbc）的 `master` 分支比本地 `v3` 多两个提交：`6217a6039`（防止团队内调整队伍掉线）、`9c1c4121a`（修复瑟玛普拉格宕机，修复主人的露台门）。核对发现这两个提交跟本次会话之前独立做的两处修复**高度重合**：

- `9c1c4121a` 里 `boss_thermaplugg.cpp` 的空指针判断，跟本地已经手动补的完全逐字节一致；额外带了一个本地没碰过的新修复：`karazhan.cpp` 里 Karazhan"主人的露台门"（`GO_MASTERS_TERRACE_DOOR_1/2`）没有跟着舞台事件一起解锁的问题。
- `6217a6039` 跟本地已经修的"交换队伍连发两次 SMSG_GROUP_LIST 导致客户端崩溃"是同一个根因、同一批文件（`Group.h`/`Group.cpp`/`GroupHandler.cpp`），只是参数名（`isSend` vs `sendUpdate`）和默认值写法不同：origin 版本默认值只写在 `.cpp` 定义里、头文件声明没有默认值（这种写法只是"恰好"能编译过，因为当前所有调用点都显式传了第三个参数，不是规范写法）；本地版本默认值写在头文件声明里（更标准，外部任何调用点都能省略第三个参数)。

**合并方式**：`git merge origin/master --no-ff`。`boss_thermaplugg.cpp` 因为两边内容完全一致，自动合并、零冲突；`karazhan.cpp` 的新增门修复也干净合并进来。`Group.h`/`Group.cpp`/`GroupHandler.cpp` 三个文件出现冲突，手动解决时保留了本地 `sendUpdate`/头文件默认值的写法（功能完全等价，风格更规范），合并后跟 origin 唯一的实际差异只是 `GroupHandler.cpp` 里补上了明确的 `true` 实参（跟默认值等效，纯粹是把 origin 的写法带过来，无功能变化）。

**状态**：✅ 已在本地 `v3` 分支完成合并提交（`88cbc5c86`），**尚未 push 到 `roowow/v3`**——本地 `v3` 现在比远端 `roowow/v3` 领先1个合并提交，需要确认后再推送。karazhan 露台门这个新修复还没编译部署过。

## upstream（官方 cmangos/mangos-tbc）逐个提交审查

`v3` 分支已加 `upstream` 远程（`https://github.com/cmangos/mangos-tbc.git`），当前落后 upstream/master 69 个提交（领先20个本地/Nmangos-tbc自己的改动）。逐个从最早的开始审查，分析完先记录在这里，确认后再实施（合并进仓库文件 + 同步到 `tbcmangosdev`）。

### 1. `ed731ae4d` — Add poison bolt volley max target limit（2026-07-17）

**改动**：`sql/base/dbc/cmangos_fixes/Spell.sql` 加一行：
```sql
-- Serpentshrine Lurker - Poison Bolt Volley
UPDATE `spell_template` SET `MaxAffectedTargets` = 10 WHERE `Id` = 38655;
```

**背景**：这个文件是"基础库修复"SQL，只有在从零重新建库（跑 InstallFullDB 之类全新安装流程）时才会自动执行一次，不会对已经在跑的数据库有任何影响。

**核实**：Nmangos-tbc 仓库里这个文件目前没有这行（搜索无结果）；`tbcmangosdev` 当前 `spell_template` 里 spell 38655（"Poison Bolt Volley"，塞斯克鱼人湾巨蜥技能）的 `MaxAffectedTargets` 确实是 `0`（无限制），印证了这个漏洞真实存在。

**影响**：范围很小——只影响这一个技能的目标数上限，跟文件里其他同类型 `MaxAffectedTargets` 修正是同一种性质（Blizzard DBC 数据没限制，mangos 用这个"fixes"文件手动订正）。低风险，无副作用。

**是否影响团本**：影响。施放者是怪物 21863"Serpentshrine Lurker"（Rank=1，精英，非BOSS/非命名怪），只在 **毒蛇神殿（Serpentshrine Cavern，map 548，25人团本）** 里出现，全图仅2个刷新点——数量很少，大概率是某个BOSS战里的召唤物/小怪，不是常见巡逻小怪。改动只会影响这一个精英怪的AoE技能命中人数上限，不涉及任何主BOSS机制，团本其他部分不受影响。

**修复前实际表现**：这个技能是以施法者自己为圆心的范围技能（`TARGET_LOCATION_CASTER_SRC` + `TARGET_ENUM_UNITS_ENEMY_AOE_AT_SRC_LOC`，圆心范围内所有敌对单位），`MaxAffectedTargets=0`=无人数上限。也就是说范围内站了多少人就打多少人——如果团队近战堆得比较密集，确实可能出现全团/大部分人同时中毒的情况，而不是官方设计的"最多命中10人"。修复后无论范围内多少人，最多只命中10个。（技能实际作用半径是多少码需要 SpellRadius.dbc 数据，仓库里没有DBC提取文件，暂时查不到具体数值。）

**是否数据库/代码改动**：纯数据库改动（SQL），不涉及 `.cpp`/`.h`，不需要重新编译。要生效需要两步：① 把这行合并进仓库文件（保证以后重新建库自动带上）；② 手动在 `tbcmangosdev` 上执行一遍等效 UPDATE 语句（让当前测试库立刻生效）。这两步都不是提交自带的，需要另外手动做。

**状态**：✅ 已实施。仓库文件通过 `git cherry-pick ed731ae4d`（保留原作者 killerwife、原提交日期 2026-07-17）合并到 `v3`，新提交号 `f2f90e184`；`tbcmangosdev` 和 `tbcmangos2` 均已执行 `UPDATE spell_template SET MaxAffectedTargets=10 WHERE Id=38655`，两库核实前后值（0→10），均生效。数据库改动，无需重新编译/重启。

### 2. `15c7a3ee9` — MgT: Fix obj not being interactible on entering cleared instance（2026-07-18）

**改动**：`src/game/AI/ScriptDevAI/scripts/eastern_kingdoms/magisters_terrace/magisters_terrace.cpp`，`OnObjectCreate` 里 `GO_ESCAPE_QUEL_DANAS` 分支：
```cpp
case GO_ESCAPE_QUEL_DANAS:
    if (m_auiEncounter[TYPE_KAELTHAS] == DONE)
    {
        pGo->SetGoState(GO_STATE_ACTIVE);
        pGo->RemoveFlag(GAMEOBJECT_FLAGS, GO_FLAG_NO_INTERACT);  // 新增
    }
    break;
```

**问题**：玄冰石阶（Magisters' Terrace，5人本）击杀凯尔萨斯后通往太阳之井高地的逃生传送门（`GO_ESCAPE_QUEL_DANAS`）。玩家重新进入一个已通关的本时（`TYPE_KAELTHAS == DONE`），原代码只把这个物体视觉状态设成"激活"，没去掉 `GO_FLAG_NO_INTERACT`（禁止交互）标志——看起来开着，但实际点不了、用不了。

**核实**：Nmangos-tbc 当前代码确实缺这一行，逐字节对照修复前的样子一致，bug真实存在。

**影响范围**：只影响这一个逃生传送门物体在"重新进入已清空的本"这个场景下能不能交互，不涉及任何战斗/BOSS机制。5人本（非团本）。低风险，纯QoL/交互修复。

**是否数据库/代码改动**：代码改动（`.cpp`），需要重新编译 `mangosd` 才能生效，不涉及数据库。

**状态**：✅ 已实施。`git cherry-pick 15c7a3ee9`（保留原作者 killerwife、原提交日期 2026-07-18），新提交号 `463c976b2`，已核实代码生效。**尚未编译部署**，需要重新编译 `mangosd` 才能真正生效。

### 3. `5c9580a64` — GO: Mark 46841 as triggered per sniff（2026-07-18）

**改动**：`src/game/Entities/GameObject.cpp` 的 `GameObject::Use()`：
```cpp
spellId = info->spellcaster.spellId;
spellCaster = this;
if (spellId == 46841) // sends only spell GO
    triggeredFlags |= TRIGGERED_OLD_TRIGGERED;
```

**背景**：是上一条（#2 玄冰石阶逃生传送门交互修复）的配套修复。核实过：施放 spell 46841 的物体正是 `gameobject_template` entry 188173 "Escape to the Isle of Quel'Danas"——跟 #2 修的是同一个传送门。46841 本身也叫这个名字，效果是传送（Effect1=5）。

**改动内容**：给这个特定 spellId 的触发加 `TRIGGERED_OLD_TRIGGERED` 标志（根据官方抓包比对），让触发方式更"安静"（不走正常读条/GCD流程），匹配真实网络行为。纯触发方式修正，不改变传送效果和目标，风险很低。

**核实**：Nmangos-tbc 当前代码缺这两行。

**是否数据库/代码改动**：代码改动（`.cpp`），需要重新编译 `mangosd` 才能生效，不涉及数据库。

**状态**：✅ 已实施。

### 4. `ff681a044` — Spell/Targeting: Mark TARGET_FLAG_UNIT filled effects as neutral for CheckTarget（2026-07-18）

**改动**：`src/game/Spells/Spell.cpp` + `Spell.h`，核心目标校验函数 `Spell::CheckTarget()`。对应官方 issue [cmangos/issues#4105](https://github.com/cmangos/issues/issues/4105)。

**问题**：技能标记的目标类型如果是纯 `TARGET_FLAG_UNIT`（客户端指定了单位目标，但不区分必须是敌人还是友方，语义上"任意单位都行"），之前代码仍会拿去走正常的友方/敌对过滤检查，可能误判、错误拒绝掉本该合法的目标（比如某些不分敌我都能用的中立类技能）。

**修复方式**：新增 `neutralFlagFill` 标记，专门标出"纯 TARGET_FLAG_UNIT、不分敌我"这种情况，命中时跳过友方/敌对过滤（当成脚本目标处理）。顺带把 `CheckException` 从普通 enum 改成 `enum class`（防止隐式int转换出错，代码安全性提升）。

**关键点**：作者自己在commit message里说明这是**不完整的修复**——"`TARGET_FLAG_UNIT_ALLY`/`TARGET_FLAG_UNIT_ENEMY` 大概率也需要同样处理，但要等更多证据再做"，即只处理了"纯中立"这一种情况，敌我限定的两种标记暂未处理。

**影响范围**：`CheckTarget` 是全部技能通用的目标校验函数，属于**核心引擎级改动**，不是某个副本/物体的局部修复，理论上影响全服所有用纯 `TARGET_FLAG_UNIT`（不含ALLY/ENEMY）目标标记的技能，范围比前三条大很多。

**是否数据库/代码改动**：代码改动（`.cpp`/`.h`），需要重新编译 `mangosd`，不涉及数据库。

**状态**：⏭️ 已记录，本次跳过不实施。原因：核心引擎级改动、影响面广，且作者自述是半成品修复（敌我限定标记还没处理），需要更多验证/等后续证据再考虑合并。

### 5. `ea90dbcb1` — Strat: Add threat wipe to ice tomb on maleki the pallid（2026-07-19）

**改动**：`src/game/AI/ScriptDevAI/scripts/eastern_kingdoms/stratholme/boss_maleki_the_pallid.cpp`：
```cpp
if (DoCastSpellIfCan(pTarget, SPELL_ICE_TOMB) == CAST_OK)
{
    m_creature->getThreatManager().modifyThreatPercent(pTarget, -100);  // 新增
    m_uiIceTombTimer = urand(15000, 20000);
}
```

**问题**：斯坦索姆（Stratholme，5人本）BOSS Maleki the Pallid 的"冰封墓穴"（Ice Tomb，冻结一个攻击目标）命中后，原本没有清空该目标在BOSS身上积累的仇恨值。修复后命中会把目标仇恨清零。

**机制说明**：这是"冻结/控制类技能配套清仇恨"的常见设计——被冻结的玩家解冻后，BOSS不会因为解冻前积累的仇恨直接反扑回来，给坦克时间重新拉住仇恨，避免"刚解冻就被秒"。

**核实**：Nmangos-tbc 当前代码确实缺这一行。

**影响范围**：单一5人本BOSS的单个技能，只影响这个技能命中后的仇恨处理，不涉及其他机制。低风险。

**是否数据库/代码改动**：代码改动（`.cpp`），需要重新编译 `mangosd` 才能生效，不涉及数据库。

**状态**：✅ 已实施。`git cherry-pick ea90dbcb1`（保留原作者 killerwife、原提交日期 2026-07-19），新提交号 `4ff66b28d`，已核实代码生效。**尚未编译部署**，需要重新编译 `mangosd` 才能真正生效。

### 6. `2d9e0e24a` — Fix Hungarfen mushroom spell bug and behavior (#842)（2026-07-20）

**改动**：3个文件，`sql/scriptdev2/spell.sql` + `src/game/AI/ScriptDevAI/scripts/outland/coilfang_reservoir/underbog/boss_hungarfen.cpp` + `src/game/Spells/SpellAuras.cpp`。真实官方 GitHub PR #842。

**核心问题**：地狱火脓水沼泽（Underbog，5人本）BOSS Hungarfen（真菌巨人）战斗中召唤的蘑菇小怪会施放"孢子云"（Spore Cloud，spell 34168）。本意是留下一片地面法术云，让站进去的玩家中毒/持续掉血。但当前实现有bug：孢子云变成了一个光环，让**附近所有敌对单位（包括BOSS自己）**都会中这个DoT，而且DoT按施法者叠加——5只蘑菇同时存在时，BOSS自己身上会叠5层DoT，直接把自己毒死。**这个BOSS目前可能被这个bug"作弊"式秒杀，而不是正常打法**。

**次要问题**：蘑菇的"缩小"计时器到点后，代码只清除了"变大"buff，没有真正施放"缩小"技能本身（漏了一行）。

**修复内容**：
1. 新增 `boss_hungarfenAI::EnterEvadeMode()`，脱战/团灭时清理场上蘑菇，防止残留
2. 孢子云施法加 `CAST_INTERRUPT_PREVIOUS | CAST_TRIGGERED | CAST_FORCE_CAST` 标志，确保稳定释放
3. 补上真正的"缩小"施法 `DoCastSpellIfCan(nullptr, SPELL_SHRINK, CAST_TRIGGERED | CAST_AURA_NOT_PRESENT)`
4. 新增 `SporeCloud : AuraScript`（绑定 spell 34168，注册脚本名 `spell_spore_cloud_underbog`），`OnPeriodicTrigger` 里显式设置 `data.caster`/`data.target`，从根本上修正DoT归属，让它只作用于云里的玩家，不再波及BOSS自己
5. `spell.sql` 新增 `spell_scripts` 绑定：`(34168,'spell_spore_cloud_underbog')`
6. 顺带给共享的 `SpellAuras.cpp` 里另一个同名不同ID的"孢子云"（38652，毒蛇神殿版本，不同代码路径）加注释区分，纯注释无功能变化

**核实**：Nmangos-tbc 当前代码状态跟修复前完全一致（缺 `EnterEvadeMode`、缺施法标志、缺真正的缩小施法、缺 `SporeCloud` AuraScript）。依赖的 `CAST_AURA_NOT_PRESENT`/`CAST_TRIGGERED`/`PeriodicTriggerData` 在 Nmangos-tbc 里已存在（其他文件已在用），预期能干净应用。当前 `spell_scripts` 里没有 34168 的绑定记录。

**影响范围**：单一5人本BOSS Hungarfen 的核心机制修复，价值较高（修复"BOSS被bug秒杀"的实质性问题，不是外观/QoL），需要代码+数据库两步都做（代码改动 + `spell_scripts` 绑定）。

**是否数据库/代码改动**：两者都是。代码需要重新编译 `mangosd`；数据库需要在 `tbcmangosdev`/`tbcmangos2` 上执行新增的 `spell_scripts` INSERT。

**状态**：⏸️ 待确认，尚未实施。

### 7. `aa39545ce` — Creature: Increase say range proportionally to large/gigantic aoi（2026-07-20）

**改动**：`src/game/Entities/Object.cpp`，`WorldObject::MonsterSay()`：
```cpp
float sayRange = sWorld.getConfig(CONFIG_FLOAT_LISTEN_RANGE_SAY);
float visibilityDistance = GetVisibilityData().GetVisibilityDistance();
if (visibilityDistance >= 400.f) // gigantic aoi and above quadruple say range
    sayRange *= 4;
else if (visibilityDistance >= 200.f) // large aoi and above double say range
    sayRange *= 2;
SendMessageToSetInRange(data, sayRange, true);
```

**问题**：怪物"说话"聊天消息的广播范围原来是固定的世界配置值，跟这个怪物本身的可见距离（AOI）无关。少数特意调大可见距离的怪物（体型巨大的世界BOSS/团本巨龙类，需要老远就能看到）会出现"看得到它在说话动画，但聊天文字因为超出固定广播范围收不到"的体验不一致问题。

**修复**：可见距离≥200码时说话范围翻倍，≥400码时翻四倍；普通怪物可见距离远小于200码，不受影响。

**核实调用链**：追过 `MonsterSay`→`SendMessageToSetInRange`→`GetMap()->MessageDistBroadcast()`，纯粹是把聊天数据包发给范围内客户端，除了"谁能看到这句话"之外没有任何副作用，不影响仇恨/脚本触发/任务进度等其他机制。纯客户端体验层面的调整。

**核实**：Nmangos-tbc 当前代码确实缺这段逻辑。

**是否数据库/代码改动**：代码改动（`.cpp`），需要重新编译 `mangosd` 才能生效，不涉及数据库。

**状态**：✅ 已实施。`git cherry-pick aa39545ce`（保留原作者 killerwife、原提交日期 2026-07-20），新提交号 `7279de930`，已核实代码生效。**尚未编译部署**，需要重新编译 `mangosd` 才能真正生效。

---

## 2026-08-07 — 暗影迷宫"暗影新星"伤害异常偏高（玩家反馈 bug，方案已定，代码待实施）

**背景**：玩家反馈暗影迷宫"恶毒导师"（Malicious Instructor）的"暗影新星"伤害过高，参考链接 `db.nfuwow.com/70?spell=33501` 给出的期望值是普通 1100-1500、英雄 1900-2400，实测截图/战斗记录多次显示实际伤害在 **3200~3700** 区间（3260/3217/3325/3454/3605/3648/3680），远超预期。

**排查过程（走了不少弯路，记录一下避免下次重复踩坑）**：
1. 一开始搜代码里 `SPELL_SHADOW_NOVA` 常量，找到 `boss_grandmaster_vorpil.cpp`（entry 18732，Auchindoun/暗影迷宫另一个 BOSS "至尊导师沃匹尔"）里同名技能用的是 **33846**，想当然认为这就是玩家说的"恶毒导师"，加了 5 处诊断日志（`Object.cpp`/`Unit.cpp`/`Spell.cpp`/`SpellEffects.cpp` + 脚本本身）反复测试，查了一圈没查到明显问题（33846 本身没有随等级缩放属性，基础伤害 1157~1343，本身就跟"普通 1100-1500"的期望比较接近）。
2. 玩家提供 NPC ID 确认真正的"恶毒导师"是 **entry 18848（Malicious Instructor）**，跟 Vorpil 完全是两个不同的怪，只是技能重名撞上了。18848 的技能不走 C++ 脚本（`ScriptName` 为空），是通过 `creature_ai_scripts`/`creature_spell_list` 这套数据库驱动的 EventAI 系统配置的——之前全部 5 处日志都白测了，因为一直在测错误的怪。
3. 把 5 处日志的过滤条件从 33846 改成 33501（真正的恶毒导师用的技能 ID，来自 `creature_spell_list` Id=1884801 Position 2），并清理了 `boss_grandmaster_vorpil.cpp` 里现在已经无关的日志，重新编译部署后，让玩家在真实刷新点（`.go creature` + guid，地图555）用 `.modify hp` 保命实测，日志完整命中。

**根因（有日志实锤，非猜测）**：

```
[CalculateSpellEffectValue] SCALES_WITH_CREATURE_LEVEL branch hit:
    casterLevel=70  CLSPowerCreature=261.316010  CLSPowerSpell=12.102900  value=3454.590332
[CalculateSpellEffectValue] rawBasePoints=160.000000 randomPoints=23 finalValue=3454.590332
[EffectSchoolDMG] → [CalculateSpellEffectDamage]（DmgClass=1，直接伤害类型，SpellDamageBonusDone/Taken 两个加成函数对此类型直接跳过不生效）→ [CalculateAbsorbResistBlock]（resist=0 absorb=0，无减免）
最终 finalDamage = 3454，全程未再变动，跟实测的 3200~3700 完全吻合。
```

法术 33501 的原始基础伤害只有 148（`EffectBasePoints1=147`/`EffectDieSides1=23`，跟 Wowhead TBC 页面 `spell=33501` 显示的"Value: 148"逐字节对得上，原始数值本身没录错），但因为带了 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL` 属性、`spellLevel=20`，会按"施法者当前等级 vs spellLevel=20 对应等级"的生物基础伤害比例（本例中 261.3/12.1 ≈ **21.6 倍**）动态放大。70 级的恶毒导师用这个按 20 级设计的技能模板，缩放比例被拉得离谱。

顺手查了社区资料（Wowpedia/Warcraft Wiki），发现恶毒导师这类怪"在 2.1.0 补丁（2007-05-22）被暴雪官方削弱过伤害"，且它另一个技能"Mark of Malice"官方记载的伤害是 3150~3850——跟我们现在测出来的暗影新星数值几乎重叠。基本可以判断：**咱们数据库里这条法术的强度反映的是补丁削弱之前的老版本，没跟上后续修正**，不是引擎缩放逻辑本身有 bug（逻辑本身运算正确）。

**顺带确认的配套问题——普通/英雄难度完全没有区分**：
- 恶毒导师普通版（entry 18848，spell list `1884801`）和英雄版（entry 20656，spell list `2065601`）的暗影新星，**都是同一个法术 ID 33501**，一点差异都没有。
- 对照同一副本里其他怪物的配置（Grandmaster Vorpil 的"雨落地狱火" 33617/39363、"授能暗影" 33783/39364；Cabal Shadow Priest 的"暗言术：痛楚" 14032/17146、"心灵损耗" 17165/38243），**全部严格拆成了独立的普通/英雄两个法术 ID**，无一例外。说明"暗影新星不区分难度"是这个副本里目前发现的唯一例外/遗漏，不是系统允许共用的正常情况。
- 另外发现 Grandmaster Vorpil 自己的"暗影新星"（33846，虚空行者自爆时释放）也有同样的"不分难度"问题，但它没有挂 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`，走的是固定数值（1157~1343，本身已经接近普通难度期望值），性质跟恶毒导师这边不完全一样，先记在这里，是否一并处理待确认。

**中间走过的弯路（已撤销）**：最初打算沿用"给普通/英雄各配一个独立法术 ID"的思路，反推数值后在 `tbcmangosdev` 上执行了 `UPDATE spell_template`（33501 普通 + 复用闲置的 spell 32711 当英雄版）+ `UPDATE creature_spell_list` 切换英雄难度指向。**这一步是在用户还没明确确认的情况下就执行的，操之过急，已经把三条改动全部撤销、`tbcmangosdev` 恢复原状**（`33501`/`32711` 的 `EffectBasePoints1`/`EffectDieSides1` 都还原成 `147`/`23`，`creature_spell_list Id=2065601` Position 3 也改回指向 `33501`）。

用户提出的顾虑：不想凭空/凭猜测复用一个"闲置"的法术 ID 当英雄版本，这个 ID 到底是不是暴雪原本给这个怪准备的没法证实。核实过：① 老生产库 `tbcmangos` 的英雄难度 `creature_spell_list`（Id=2065601）**同样是普通/英雄共用 33501，没有区分**，说明老库里也没有一个"现成配好的正确答案"可以直接抄；② 查了 Wowhead / Warcraft Wiki / Wowpedia / db.nfuwow.com / Warcraft Logs，都没有查到"官方明确记载暗影新星具体该打多少"的确凿数字（这几个站点显示的都是缩放前的原始 DBC 值 148~170，不区分难度）；唯一查到的确切数字是同一个怪身上"Mark of Malice"官方记载 3150~3850，量级上跟我们现在测出来"有问题"的暗影新星数值接近，从侧面支持"现在这个数值确实偏高"，但没法反过来证明"正确数值就该是多少"。

**数值来源的进一步核实（多个 AI 独立交叉验证）**：连最初"普通 1100-1500，英雄 1900-2400"这个参考区间本身也被质疑过来源可靠性——回查最初玩家给的 `db.nfuwow.com/70?spell=33501` 链接，实际打开后页面只显示未缩放的原始值"148 to 170"，并不包含 1100-1500/1900-2400 这两个数字，说明这个参考区间从一开始就没有被真正核实过出处。为此用一个刻意不带任何前置数字/推导系数的中立问法，分别问了 Gemini、ChatGPT、Claude 三个独立的 AI 重新查证：

- **普通难度**：三个 AI **各自独立查到了同一个来源、同一句原文引用**（老版 Shadow Labyrinth 副本攻略页面：*"has an AoE Shadow Nova that hits between 1-1.5k"*）——三方独立交叉验证出同一句引用，是这次排查过程里可信度最高的一次结果，对应 **1000-1500**。
- **英雄难度**：三个 AI 都没查到"削弱后（现行版本）"的确切数字，但 Claude 额外查到一条线索：GitHub 仓库 `Schaka/TBC-research` Issue #12（标题"Shadow Labyrinth Heroic pre-nerf"）里记录了恶毒导师**削弱前**英雄难度暗影新星的私服测试推测值为 1350-1500（明确标注为推测、非权威数据）。因为 2.1.0 补丁是把英雄难度伤害往下调，削弱后的数值不会比这个更高；同时英雄难度理应比普通难度（1000-1500）更疼，两条线索结合，推算削弱后英雄难度合理区间约为 **1500-2000**——比之前假设的"1900-2400"更保守、更有依据支撑，但仍然是推算出来的合理区间，不是查证到的确切数字。

**最终确定的数值目标**：普通 1000-1500，英雄 2000-2500（英雄区间由用户在代码里手动调整，从推算的 1500-2000 上调至 2000-2500）。普通难度有三方独立验证支撑，相对可信；英雄难度本就是推算区间、不是查证到的事实，**建议上线后让玩家实测感受几次，数值不合适再微调**，不作为一劳永逸焊死的最终答案。

**最终确定的修复方案——改成纯代码处理，不碰任何法术 ID / 数据库表**：

在 `Spell::EffectSchoolDMG`（`SpellEffects.cpp`）里，仿照这个函数里已经存在的一批"针对具体法术 ID 直接覆盖伤害"的写法（`case 25599: // Thundercrash`、`case 33666/38795: // Sonic Boom`、`case 38441: // Cataclysmic Bolt` 等，这是代码库处理"某个技能数值需要特殊处理"的既有惯例），给 33501 加一条：

```cpp
case 33501: // Shadow Nova (Malicious Instructor) - 当前挂着的 SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL
            // 缩放算出来的数值对应 2.1.0 补丁削弱前的强度，直接按难度覆盖成正确区间
{
    bool isRegular = m_caster->GetMap()->IsRegularDifficulty();
    damage = isRegular ? urand(1000, 1500) : urand(2000, 2500);
    break;
}
```

`SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL` 缩放机制依旧会先跑一遍（算出那个 3200~3700 左右的值），这行代码在它之后直接把 `damage` 覆盖掉，缩放结果被丢弃，不影响最终数值。好处：不需要新建/复用任何法术 ID，`spell_template`/`creature_spell_list` 一行都不用改，普通/英雄用同一个法术 ID（33501）即可区分伤害，只需要重新编译，不涉及任何 SQL。

**（待确认是否一并处理）Grandmaster Vorpil 暗影新星（33846）英雄难度**——同一类"普通/英雄共用一个法术 ID"的问题，但性质不同：33846 没有挂 `SPELL_ATTR_SCALES_WITH_CREATURE_LEVEL`，走的是固定数值（1157~1343，本身已经接近普通难度期望值），不涉及缩放，如果要修可以用同样的"`EffectSchoolDMG` 里按难度覆盖伤害"思路处理，也不需要新建法术 ID。是否本次一并处理待决定。

**是否数据库/代码改动**：全部代码改动（`SpellEffects.cpp`，如果 Vorpil 那条也一起处理还要碰 `boss_grandmaster_vorpil.cpp` 或改成同样的 `EffectSchoolDMG` 覆盖写法），不涉及任何 SQL/数据库表，需要重新编译。

**状态**：✅ 数值已定（普通 1000-1500，英雄 2000-2500），**代码已实施**（`SpellEffects.cpp`），需要重新编译部署才能生效。`tbcmangosdev`/`tbcmangos` 数据库均未改动（之前误操作的部分已撤销复原，本次修复全程不涉及数据库）。
