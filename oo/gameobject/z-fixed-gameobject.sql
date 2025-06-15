-- 之前修复过的任务bug。汇总到这里，需要重新执行一遍。
UPDATE `gameobject_template` SET `type` = '2', `faction` = '35', `data0` = '0', `data3` = '10219', `data22` = '0' WHERE `gameobject_template`.`entry` = 181606;
UPDATE `gameobject_template` SET `data2` = '1966080' WHERE `gameobject_template`.`entry` = 181928;
UPDATE `gameobject_template` SET `data2` = '24618320' WHERE `gameobject_template`.`entry` = 186287;
UPDATE `gameobject_template` SET `data1` = '10861' WHERE `gameobject_template`.`entry` = 185210;
UPDATE `gameobject_template` SET `data1` = '10861' WHERE `gameobject_template`.`entry` = 185211;