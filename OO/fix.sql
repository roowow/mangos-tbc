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
