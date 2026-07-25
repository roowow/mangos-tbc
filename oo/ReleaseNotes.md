# Release Notes

## 数据库信息
WorldDatabase.Info              = "s1.oowow.world;3446;cmangos; cManGos2025;tbcmangosdev"
CharactersDatabase.Info              = "s1.oowow.world;3446;cmangos; cManGos2025;tbccharactersdev"
C:\Program Files\MySQL\MySQL Server 8.4\bin

### 开发测试数据库
tbcmangosdev
tbccharactersdev

### 数据库版本对照（回滚后，2026-07-25 核实）

代码回滚到 `30d21668a6` 的同时数据库也一起回滚了。下表是测试库当前版本，及其对应 `tbc-db` 仓库的位置：

| 数据库 | 版本标记 | 对应 tbc-db 内容 |
|---|---|---|
| `tbcmangosdev`（世界库，内容） | `content_0616_ptr_vendor` | 停在 `Updates/0616_ptr_vendor.sql`（提交 `de6acac8`，2025-07-30） |
| `tbcmangosdev`（世界库，核心 schema） | `required_s2487_01_mangos_dbscript_breaking_change` | 对应 mangos-tbc 核心仓库 `sql/updates/mangos/s2487`，跟回滚代码版本一致（今天补齐） |
| `tbccharactersdev`（角色库） | `required_s2473_01_characters_item_instance_text_id_fix` | 对应 mangos-tbc 核心仓库 `sql/updates/character/s2473`，与 tbc-db 内容无关 |

**差距**：tbc-db 仓库当前 HEAD 是 `7111bc0e`（2026-07-04），比测试库新了约 100+ 个内容更新文件，从 `Updates/0617_heroic_displayids.sql`（2025-08-01）开始，一直到最新的 `0735_midsummer_fire_festival_schedule_fix.sql`/`9999_Final_Misc_Cleanup_Queries.sql`，测试库都还没有。

## 2026-07-25 — v2 分支：从回滚前的 master 合并可用改动

背景：`master` 分支曾合并 upstream 后出现较多问题，于是新建 `v2` 分支，代码回滚到合并 upstream 之前（`30d21668a640dbb2a9603c6363432d8266768245`）。回滚前的 master（对应 `origin/master`，tip `765e1fd89`）上还有一批在回滚点之后做的自定义修复，逐条审查后把合理的部分合并回了 `v2`。

### 已合并（13 个提交，`30d21668a..v2`）

**猎人宠物训练系统修复**（5 个提交，迭代修复同一问题）
- `GetTrainerSpellState` 原来对宠物技能（如野兽训练）错误检查玩家自己的技能簿而非宠物的，导致训练师界面状态显示错误，还可能超额扣宠物训练点
- 修了宠物只保留最高阶技能、导致低阶前置技能检测误判的问题
- `.pet level`（忠诚度）GM 命令强制升级失效的修复
- `HandleTrainerBuySpellOpcode` 补上协议规定但从未真正发送的 `SMSG_TRAINER_BUY_FAILED` 失败回执，替代早期"直接关闭训练窗口"的临时方案

**Warden 反作弊踢人后未清计时器**
- `KickPlayer()` 只标记会话待关闭，没调用 `StopTimeoutClock()`，导致关闭前的每个 tick 重复踢人/重复记日志

**矿石侦查（Prospecting）复制漏洞修复 + spell 20741 冷却修复**
- 根因：`HandleAutostoreLootItemOpcode` 对无效/已消耗的战利品槽位请求统一调用 `SendReleaseFor()`（只清玩家自己的拾取标记），跳过了 `LOOT_PROSPECTING` 真正销毁矿石的收尾逻辑；快速双击或高延迟时会导致矿石不消失就能拿到宝石
- 修复：仅当 `IsLootedFor(_player)` 为真时才调用完整的 `Release()`，否则忽略无效请求、保持窗口开着
- 附带修复 spell 20741（暗言术箭雨）没有冷却导致心控刷怪的问题（10 秒冷却）
- **⚠ 需要数据库更新**：spell 20741 的冷却是 SQL 改的，不是代码，对应 `oofixed/fix.sql` **FIX-18**。代码合并到 v2 只是修好了漏洞本身（矿石消失逻辑），FIX-18 还要单独在目标数据库（测试库/生产库）执行一遍才算完整生效，不会随代码自动生效。

**Gnomeregan Thermaplugg 炸弹脚本空指针防护**
- `ActivateBombThermaplugg::OnEffectExecute` 补上 `target` 为空的检查

**运维**
- 新增 `deploy.sh` 部署脚本（拉取代码、构建、替换二进制、重启服务）
- `fix.sql` 补齐历史修复记录的验证状态注释（都是之前已经执行过的旧记录补状态，不是新增的数据库改动，不需要重新执行）

### 本次合并涉及的数据库改动一览

除了随代码一起生效的部分（宠物训练、Warden、矿石侦查窗口逻辑、Thermaplugg 空指针防护，这些都是纯 C++ 改动，代码部署后即生效，不需要额外跑 SQL），**唯一需要单独在数据库执行的是**：

| 代码修复 | fix.sql 编号 |
|---|---|
| spell 20741 冷却修复（矿石侦查那一节里附带的） | **FIX-18** |

### 明确跳过

- `4cb89fa40` / `96ef4f96e`（旧版 `anticheat.conf`）—— 已被 v2 当前版本取代（含 2026-07-24 的 FastJump/JumpSpeedChange/OverspeedZ/WaterWalk TickCount 误踢修复调优）
- `765e1fd89` 中的**卡拉赞"午夜/阿塔麦"(Attumen the Huntsman) 团队本战斗脚本重写**（`boss_midnight.cpp` + `karazhan.cpp`，参考 Nmangos-tbc 的 `a79667498` 移植，把社区版数据驱动的阶段切换回退为硬编码计时器，并补上阿塔麦缺失的技能）——该改动在原提交的 fix.sql 注释里明确标注"尚未提交/部署，需要等代码改动上线测试服验证过之后再对 DB 执行"，属于未验证状态，按决定暂不合并，留待单独验证后再处理
