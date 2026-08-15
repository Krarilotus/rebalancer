local constants = require("constants")
local addresses = require("addresses")
local templates = require("templates")

local building_names = constants.building_names
local unit_names = constants.unit_names
local military_ground_unit_names = constants.military_ground_unit_names
local resource_names = constants.resource_names
local namespace = {}

local locate_aob = core.scanForAOB

local pop_gathering_addr = locate_aob("8B 0C 85 ? ? ? ? EB 2D 8B 4E F0")
local scenario_pgr_base = locate_aob("EC FF FF FF F1 FF FF FF F4 FF FF FF F6 FF FF FF F7 FF FF FF F8 FF FF FF F9 FF FF FF FA FF FF FF FB FF FF FF FB FF FF FF 05 00 00 00 05 00 00 00")
local scenario_pgr_crowded_base = locate_aob("EC FF FF FF F1 FF FF FF F4 FF FF FF F6 FF FF FF F7 FF FF FF F8 FF FF FF F9 FF FF FF FA FF FF FF FB FF FF FF FB FF FF FF 05 00 00 00 05 00 00 00")
local skirmish_pgr_base = locate_aob("F8 FF FF FF FA FF FF FF FB FF FF FF FC FF FF FF FD FF FF FF FD FF FF FF FE FF FF FF FE FF FF FF FF FF FF FF FF FF FF FF 0A 00 00 00 0C 00 00 00")
local large_town_threshold_addr = locate_aob("83 BE ? ? ? ? 64 7E 09")+6
local min_peasants_addr = locate_aob("83 FA 04 7E 3B") + 2
local pop_reset_population_limit_addr = locate_aob("83 F9 03 7F 1F") + 2
local pop_reset_popularity_limit_addr = pop_reset_population_limit_addr + 10
local pop_reset_value_addr = pop_reset_population_limit_addr + 25
local crowding_addr_1 = locate_aob("83 F8 64 7F 04 33 C0 EB 40 83 F8 78")
local crowding_addr_2 = locate_aob("83 F8 64 7F 04 33 F6 EB 40 83 F8 78")

local unit_array_base_addr = addresses.unit_array_base_addr
local building_array_base_addr = addresses.building_array_base_addr
local unit_melee_toggles_base = addresses.unit_melee_toggles_base
local unit_jester_unfriendly_base = addresses.unit_jester_unfriendly_base
local unit_blessable_base = addresses.unit_blessable_base
local unit_allowed_on_walls_base = addresses.unit_allowed_on_walls_base
local unit_melee_immunity_base = addresses.unit_melee_immunity_base
local towers_or_gates_base = addresses.towers_or_gates_base
local unit_gold_jumplist_addr = addresses.unit_gold_jumplist_addr
local tax_popularity_offset = addresses.tax_popularity_offset

-- local scaling_code = templates.continuous_scaling_code
local scaling_code = templates.discrete_scaling_code

local archer_idx = table.find(unit_names, "European archer")
local arabbow_idx = table.find(unit_names, "Arabian archer")

local ballista_damage_table_addr = 0 -- defined when allocated.
local mangonel_damage_table_addr = 0 -- defined when allocated.
local catapult_damage_table_addr = 0 -- defined when allocated.
local trebuchet_damage_table_addr = 0 -- defined when allocated.

local non_rax_unit_cost_func_addr = locate_aob("8B 44 24 04 83 F8 1E 55")
local non_rax_unit_display_cost_func_addr = locate_aob("33 DB 83 F8 03 77 1A FF 24 85 ? ? ? ?")

local ballista_damage_addr = locate_aob("66 83 F9 37 75 07 B9 32 00 00 00 EB 70 66 83 F9") -- 125 bytes (+14)
local mangonel_damage_addr = locate_aob("66 83 F9 37 75 0A B9 32 00 00 00 E9 51 01 00 00") -- 154 bytes

local unit_health_base = locate_aob("C4 09 00 00 C4 09 00 00 10 27 00 00 C4 09 00 00 10 27 00 00 88 13 00 00 10 27 00")
local unit_arrow_dmg_base = locate_aob("98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 88 13 00 00 98 3A 00 00 98 3A 00 00 98 3A")
local unit_xbow_dmg_base = locate_aob("98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 98 3A 00 00 88 13 00 00 98 3A 00 00 B8 0B 00 00")
local unit_stone_dmg_base = locate_aob("88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00 88 13 00 00")
local unit_speed_base = locate_aob("01 00 00 00 01 00 00 00 02 00 00 00 03 00 00 00 01 00 00 00 01 00 00 00 02 00 00 00 02 00 00 00 03 00 00 00 01 00 00 00")

local tunneller_building_melee_addr =   locate_aob("F7 D9 1B C9 83 E1 F0 83 C1 14 0F BF A8")
local archer_building_melee_addr =      locate_aob("F7 D9 1B C9 83 E1 FD 83 C1 04 0F BF 98")  -- +6 +9
local crossbow_building_melee_addr =    locate_aob("33 FF 8D 44 00 02 8B D0 8B 44 24 10")
local spearman_building_melee_addr =    locate_aob("F7 D9 1B C9 83 E1 FB 83 C1 08 0F BF 90")  -- +6 +9
local maceman_building_melee_addr =     locate_aob("F7 D9 1B C9 83 E1 E1 83 C1 23 0F BF 98")  -- +6 +9
local pikeman_building_melee_addr =     locate_aob("F7 D9 1B C9 83 E1 F0 83 C1 14 0F BF A8", tunneller_building_melee_addr+10)  -- +6 +9
local swordsman_building_melee_addr =   locate_aob("F7 D9 1B C9 83 E1 C0 83 C1 46 0F BF 98")  -- +6 +9
local knight_building_melee_addr =      locate_aob("F7 D9 1B C9 83 E1 C0 83 C1 46 0F BF 98", swordsman_building_melee_addr+10)  -- +6 +9
local lord_building_melee_addr =        locate_aob("F7 D9 1B C9 83 E1 C0 83 C1 46 0F BF A8")
local arabbow_building_melee_addr =     locate_aob("F7 D9 1B C9 83 E1 FD 83 C1 04 0F BF 98", archer_building_melee_addr+10)  -- +6 +9
local slave_building_melee_addr =       locate_aob("0F BF 90 ? ? ? ? 8B 80 ? ? ? ? 6A 08")  -- +14
local slinger_building_melee_addr =     locate_aob("F7 D9 1B C9 83 E1 FD 83 C1 04 0F BF 98", arabbow_building_melee_addr+10)  -- +6 +9
local assassin_building_melee_addr =    locate_aob("F7 D9 1B C9 83 E1 C0 83 C1 46 0F BF A8", lord_building_melee_addr+10)  -- +6 +9
local firethrower_building_melee_addr = locate_aob("F7 D9 1B C9 83 E1 FD 83 C1 04 0F BF 98", slinger_building_melee_addr+10)  -- +6 +9
local horsearcher_building_melee_addr = locate_aob("F7 D9 1B C9 83 E1 FD 83 C1 04 0F BF 98", firethrower_building_melee_addr+10)  -- +6 +9
local arabsword_building_melee_addr =   locate_aob("F7 D9 1B C9 83 E1 C0 83 C1 46 0F BF A8", assassin_building_melee_addr+10)  -- +6 +9
local monk_building_melee_addr =        locate_aob("F7 D9 1B C9 83 E1 EF 83 C1 14 0F BF A8 ? ? ? ? 6A 01")  -- +6 +9
local ram_damage_addr =                 locate_aob("55 6A 32 52 8B 90 ? ? ? ? 51 52")  -- +3  

local unit_melee_damage_offset_map = {}
unit_melee_damage_offset_map["Tunneler"] =             {building = tunneller_building_melee_addr+9,   fortification = tunneller_building_melee_addr+6,   wall = tunneller_building_melee_addr - 53}
unit_melee_damage_offset_map["European archer"] =      {building = archer_building_melee_addr+9,      fortification = archer_building_melee_addr+6,      wall = archer_building_melee_addr - 53}
unit_melee_damage_offset_map["European crossbowman"] = {building = crossbow_building_melee_addr+4,    fortification = crossbow_building_melee_addr+2,    wall = crossbow_building_melee_addr-62}
unit_melee_damage_offset_map["European spearman"] =    {building = spearman_building_melee_addr+9,    fortification = spearman_building_melee_addr+6,    wall = spearman_building_melee_addr - 36}
unit_melee_damage_offset_map["European pikeman"] =     {building = pikeman_building_melee_addr+9,     fortification = pikeman_building_melee_addr+6,     wall = pikeman_building_melee_addr - 55}
unit_melee_damage_offset_map["European maceman"] =     {building = maceman_building_melee_addr+9,     fortification = maceman_building_melee_addr+6,     wall = maceman_building_melee_addr - 46}
unit_melee_damage_offset_map["European swordsman"] =   {building = swordsman_building_melee_addr+9,   fortification = swordsman_building_melee_addr+6,   wall = swordsman_building_melee_addr - 55}
unit_melee_damage_offset_map["European knight"] =      {building = knight_building_melee_addr+9,      fortification = knight_building_melee_addr+6,      wall = knight_building_melee_addr - 55}
unit_melee_damage_offset_map["Monk"] =                 {building = monk_building_melee_addr+9,        fortification = monk_building_melee_addr+6,        wall = monk_building_melee_addr - 52}
unit_melee_damage_offset_map["Lord"] =                 {building = lord_building_melee_addr+9,        fortification = lord_building_melee_addr+6,        wall = lord_building_melee_addr - 66}
unit_melee_damage_offset_map["Battering ram"] =        {building = ram_damage_addr+2,                 fortification = "Not supported.",                  wall = "Not supported."}
unit_melee_damage_offset_map["Arabian archer"] =       {building = arabbow_building_melee_addr+9,     fortification = arabbow_building_melee_addr+6,     wall = arabbow_building_melee_addr - 44}
unit_melee_damage_offset_map["Arabian slave"] =        {building = slave_building_melee_addr+14,      fortification = "Not supported.",                  wall = "Not supported."}
unit_melee_damage_offset_map["Arabian slinger"] =      {building = slinger_building_melee_addr+9,     fortification = slinger_building_melee_addr+6,     wall = slinger_building_melee_addr - 53}
unit_melee_damage_offset_map["Arabian assassin"] =     {building = assassin_building_melee_addr+9,    fortification = assassin_building_melee_addr+6,    wall = assassin_building_melee_addr - 52}
unit_melee_damage_offset_map["Arabian horse archer"] = {building = horsearcher_building_melee_addr+9, fortification = horsearcher_building_melee_addr+6, wall = horsearcher_building_melee_addr - 55}
unit_melee_damage_offset_map["Arabian swordsman"] =    {building = arabsword_building_melee_addr+9,   fortification = arabsword_building_melee_addr+6,   wall = arabsword_building_melee_addr - 55}
unit_melee_damage_offset_map["Arabian firethrower"] =  {building = firethrower_building_melee_addr+9, fortification = firethrower_building_melee_addr+6, wall = firethrower_building_melee_addr - 53}

local unit_power_levels_addr = locate_aob("05 00 00 00 0A 00 00 00 04 00 00 00 0A 00 00 00 0A 00 00 00")
local eu_unit_gold_cost_base = locate_aob("0C 00 00 00 14 00 00 00 08 00 00 00 14 00 00 00")
local ar_unit_gold_cost_base = locate_aob("4B 00 00 00 05 00 00 00 0C 00 00 00 3C 00 00 00")
-- 16 bytes from last of one unit to start of next unit
local unit_melee_dmg_base = locate_aob("02 00 00 00 02 00 00 00 02 00 00 00 02 00 00 00 02 00 00 00 02 00 00 00 02 00 00 00 14 00 00 00") - 0x260

-- building related addresses
local building_cost_base = locate_aob("06 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 06 00 00 00 00 00 00 00")
local building_health_base = locate_aob("64 00 00 00 64 00 00 00 64 00 00 00 64 00 00 00 64 00 00 00 64 00 00 00 64 00 00 00")
local building_population_base = locate_aob("08 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")

-- siege related addresses
local cat_collateral_addr = locate_aob("8B 1C 95 ? ? ? ? 8B CB BF 0A 00 00 00 81 E1 01 00 10 40 8B EF")+10
local siege_projectile_func_addr = locate_aob("66 83 F9 03 75 0A BF 3C 00 00 00 8D 6F E2")
local oneshot_threshold_addr = locate_aob("81 F9 20 4E 00 00 0F 8E F9 FD FF FF")
local cat_primary_addr = siege_projectile_func_addr+23 -- integer
local treb_collateral_penalty_addr = siege_projectile_func_addr+13  -- byte
local treb_primary_addr = siege_projectile_func_addr+7 -- integer
local mango_primary_addr = siege_projectile_func_addr+36  -- integer

-- resource related addresses
local resource_buy_base = locate_aob("14 00 00 00 4B 00 00 00 46 00 00 00 00 00 00 00 E1 00 00 00 64 00 00 00 64 00 00 00 73 00 00 00 28 00 00 00 28 00 00 00 28 00 00 00 28 00 00 00")
local resource_sell_base = locate_aob("05 00 00 00 28 00 00 00 23 00 00 00 00 00 00 00 73 00 00 00 32 00 00 00 32 00 00 00 28 00 00 00 14 00 00 00 14 00 00 00 14 00 00 00 14 00 00 00")

local woodcutter_func = locate_aob("6A 01 66 89 BE ? ? ? ? 6A 0C 89 96 ? ? ? ? 50")
local quarry_grunt_func = locate_aob("6A 01 6A 08 55 C7 81 ? ? ? ? 00 00 00 00 E8")
local ironminer_func = locate_aob("6A 01 8D 80 ? ? ? ? 6A 01 51 E8")
local pitchman_func = locate_aob("6A 01 66 89 AE ? ? ? ? 6A 01 89 8E")
local hunter_func = locate_aob("6A 01 66 89 BE ? ? ? ? 6A 06 89 8E ? ? ? ?")
local apple_farmer_func = locate_aob("6A 01 6A 03 50 66 C7 86 ? ? ? ? 07 00 E8")
local dairy_farmer_func = locate_aob("6A 01 66 89 BE ? ? ? ? 6A 03 89 96 ? ? ? ? 50 66 C7 86 ? ? ? ? 05 00")
local hops_farmer_func = locate_aob("6A 01 74 04 6A 02 EB 02 6A 01 50 E8")  -- hops farm yields 1 per delivery on scenario/castle builder mode, 2 on skirmish

local baker_func = locate_aob("53 C6 86 ? ? ? ? FE 6A 08 66 C7 86 ? ? ? ? 05 00")  -- skirmish bonus is push ebx instead of push val
local wheatfarmer_func = locate_aob("53 66 89 BE ? ? ? ? 6A 02") -- skirmish bonus is push ebx instead of push val
local brewer_func = locate_aob("55 C6 86 ? ? ? ? FE 55 66 C7 86 ? ? ? ? 07 00") -- both produce amount and skirmish bonus is push ebp instead of push val

local fletcher_func = locate_aob("55 55 66 89 9E ? ? ? ? 50 66 C7 86 ? ? ? ? 06 00 E8")
local poleturner_func = locate_aob("55 C6 86 ? ? ? ? FE 55 66 C7 86 ? ? ? ? 07 00", brewer_func+16)  -- exact same AOB as brewer func
local blacksmith_func = locate_aob("55 55 66 89 9E ? ? ? ? 50 66 C7 86 ? ? ? ? 07 00 E8")  -- blacksmith has another call to calculategoodsproduced but its a mystery
local custom_fletcher_code_addr = 0  -- defined when inserted as code
local custom_poleturner_code_addr = 0  -- defined when inserted as code
local custom_blacksmith_code_addr = 0  -- defined when inserted as code
local tanner_func = locate_aob("53 53 50 66 89 AE ? ? ? ? E8 53 6C FD FF 66 89 86")
local armourer_func = locate_aob("55 C6 86 ? ? ? ? FE 55 66 C7 86 ? ? ? ? 07 00 57 66 89 9E ? ? ? ? E8", poleturner_func+16)
local resource_production_offset_map = {}  -- defined under enable_rebalance_features

-- religion related addresses
local religion_addr_1 = locate_aob("83 F8 18 7F 04 33 C9 EB 2C 83 F8 31 7F 07 B9 32 00 00 00 EB 20 83 F8 4A 7F 07 B9 64 00 00 00 EB 14 33 C9 83 F8 5E 0F 9F C1 83 E9 01 83 E1 CE 81 C1 C8 00 00 00 83 BE")
local religion_addr_2 = locate_aob("83 F8 18 7F 04 33 C0 EB 2E 83 F8 31 7F 07 B8 32 00 00 00 EB 22 83 F8 4A 7F 07 B8 64 00 00 00 EB 16 33 D2 83 F8 5E 0F 9F C2 83 EA 01 83 E2 CE 81 C2 C8 00 00 00 8B C2")
local religion_addr_3 = locate_aob("83 F8 18 7F 04 33 F6 EB 2E 83 F8 31 7F 07 BE 32 00 00 00 EB 22 83 F8 4A 7F 07 BE 64 00 00 00 EB 16 33 D2 83 F8 5E 0F 9F C2 83 EA 01 83 E2 CE 81 C2 C8 00 00 00 8B F2 83 B9")

-- beer related addresses
local beer_addr_1 = locate_aob("83 FE 19 7D 04 33 C0 EB 2B 83 FE 32 7D 07 B8 32 00 00 00 EB 1F 83 FE 4B 7D 07 B8 64 00 00 00 EB 13 33 C0 83 FE 64 0F 9D C0 83 E8 01 83 E0 CE 05 C8 00 00 00 8B")
local beer_addr_2 = locate_aob("83 F8 19 7D 04 33 F6 EB 2E 83 F8 32 7D 07 BE 32 00 00 00 EB 22 83 F8 4B 7D 07 BE 64 00 00 00 EB 16 33 C9 83 F8 64 0F 9D C1 83 E9 01 83 E1 CE 81 C1 C8 00 00 00 8B F1")
local beer_addr_3 = locate_aob("83 F8 19 89 84 3E ? ? ? ? 7D 04 33 C0 EB 2E 83 F8 32 7D 07 B8 32 00 00 00 EB 22 83 F8 4B 7D 07 B8 64 00 00 00 EB 16 33 D2 83 F8 64 0F 9D C2 83 EA 01 83 E2 CE 81 C2 C8 00 00 00 8B C2")
local beer_coverage_addr = locate_aob("7F 05 33 C0 C2 04 00 8B 89 ? ? ? ? 85 C9 7E F1 69 C0 B8 0B 00 00 99")
local flagon_mul_addr = locate_aob("69 C0 2C 03 00 00 66 81 80 ? ? ? ? A0 00")
local flagon_inn_display_addr = locate_aob("8D B6 ? ? ? ? 50 B8 67 66 66 66 F7 E9 C1 FA 06")

-- food related addresses
local food_addr_1 = locate_aob("BE 38 FF FF FF EB 49 8B 0D ? ? ? ? 69 C9 ? ? ? ? 8B 81 ? ? ? ? 83 F8 04 75 07 BE C8 00 00 00 EB 2B 83 F8 03 75 05 8D 70 61 EB 21 83 F8 02 75 04 33 F6 EB 18 3B C3 75 07 BE 9C FF FF FF EB 0D 85 C0 BE 38 FF FF FF 74 04")
local food_addr_2 = locate_aob("BE 38 FF FF FF EB 3C 8B 88 ? ? ? ? 83 F9 04 75 07 BE C8 00 00 00 EB 2A 83 F9 03 75 05 8D 71 61 EB 20 83 F9 02 75 04 33 F6 EB 17 83 F9 01 75 05 8D 71 9B EB 0D 85 C9 BE 38 FF FF FF 74 04")
local food_addr_3 = locate_aob("B9 38 FF FF FF EB 3F 8B 84 3E ? ? ? ? 85 C0 75 07 B9 38 FF FF FF EB 2D 83 F8 01 75 05 8D 48 9B EB 23 83 F8 02 75 04 33 C9 EB 1A 83 F8 04 75")
local food_point_addr = locate_aob("0E 3B CD 74 25 B8 98 3A 00 00 99")+6

-- fear factor related addresses
local ff_addr_1 = locate_aob("8B 82 ? ? ? ? 83 F8 01 7C 05 6B C0 19 EB 0C 83 F8 FF 7F 05 6B C0 19")
local ff_addr_2 = locate_aob("8B 81 ? ? ? ? 83 F8 01 7C 07 6B C0 19 8B F0 EB 0E 83 F8 FF 7F 07 6B C0 19")
local ff_addr_3 = locate_aob("8B 84 3E ? ? ? ? 83 F8 01 7C 09 6B C0 19 89 44 24 1C EB 16 83 F8 FF 7F 09 6B C0 19")
local productivity_addr = locate_aob("C7 01 96 00 00 00 EB 7A 83 F8 FC 7F 08 C7 01 8C 00 00 00 EB 6D 83 F8 FD 7F 08 C7 01")
local ff_coverage_addr = locate_aob("C1 F9 04 83 C1 01 2B 46 F8")
local combat_bonus_memory_addr = locate_aob("83 C0 14 0F AF 44 24 04 8D 0C 80 B8 1F 85 EB 51 F7 E9")
local resting_factor_addr = locate_aob("69 F6 ? ? ? ? 66 83 86 ? ? ? ? 01")+13

local positive_troop_combat_bonus_visual_addr = locate_aob("8D 96 A2 00 00 00 8D 0C 80")
local negative_troop_combat_bonus_visual_addr = locate_aob("8D 96 98 00 00 00 8D 0C 80")

-- tax related addresses
local tax_addr = locate_aob("8B 44 24 08 83 C0 FF 0F AF 44 24 0C 99 2B C2 D1 F8")
local bribe_addr = locate_aob("B8 05 00 00 00 2B 44 24 08 0F AF 44 24 0C 99")
local tax_table_addr = 0 -- defined when allocated
local neutral_level_addr_1 = locate_aob("83 F8 03 7D 12")
local neutral_level_addr_2 = locate_aob("03 00 00 00 C7 86")
local neutral_level_addr_3 = locate_aob("83 F8 03 7E 16 8B 54 24 0C 52 50 8B 44 24 0C 50")
local neutral_level_addr_4 = locate_aob("83 F8 03 7D 16 8B 54 24 0C 52 50")
local keep_menu_addr = locate_aob("83 F8 03 7D 07 83 7C 24 10 00 7E 2B 85 C0 75 0A B8 AF 00 00 00 E9 86 00 00 00 83 F8 01 75 07 B8 7D 00 00 00 EB 7A 83 F8 02 75 07 B8 4B 00 00 00")
local pop_report_addr = locate_aob("83 B8 ? ? ? ? 03 7D 11 83 7C 24 18 00 7F 0A BE 19 00 00 00 E9")
local actual_effect_addr = locate_aob("83 F8 03 7D 0E 85 ED 7F 0A B8 19 00 00 00 E9 86 00 00")
local multipliers_addr_base = locate_aob("69 C0 FA 00 00 00 8B C8 B8 1F 85 EB 51 F7 E9 C1 FA 05 8B C2 C1 E8 1F")

-- castle defence addresses
local pitch_ditch_costaddr = locate_aob("5D 66 C7 06 01 00")+4
local killing_pit_dmg_addr = locate_aob("75 7D 81 86 ? ? ? ? B0 B9 FF FF")+8
local dog_threshold_addr = locate_aob("E8 ? ? ? ? 83 3D ? ? ? ? 19 7D 0D")+11
local fire_damage_code_addr = locate_aob("66 83 FF 37 75 07 B8 19 00 00 00 EB 21 66 83 FF 35 75 09")
local fire_damage_table_addr = 0 -- defined when allocated

-- leather_per_cow address
local leather_per_cow_address = locate_aob("53 6A 03 6A 03 6A 05 52 50")

-- range related addresses
local base_ranges_table_addr = locate_aob("36 00 00 00 4B 00 00 00 55 00 00 00 46 00 00 00 00 00 00 00 00 00 00 00 36")
local proj_velocity_table_addr = locate_aob("7D 00 00 00 0A 00 00 00 1E 00 00 00 0F 00 00 00 64 00 00 00 64 00 00 00")
local proj_archtype_table_addr = locate_aob("00 00 00 00 02 00 00 00 01 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00")

local range_split_addr1 = locate_aob("8B 04 85 ? ? ? ? 0F AF C0 66 83 BC 37") -- (0x54B621)  -- patch size should be 7
local range_split_addr2 = locate_aob("BD 64 0B 00 00 E9 A2 00 00 00") -- (0x43595D)  -- patch size should be 5
local range_split_addr3 = locate_aob("BE 64 0B 00 00 E9 A5 00 00 00") -- (0x436339)  -- patch size should be 5
local range_split_addr4 = locate_aob("BE 64 0B 00 00 0F 87 52 01 00 00") -- (0x435E2C)  -- patch size should be 5
local range_split_addr5 = locate_aob("B8 64 0B 00 00 EB 25 B8") -- (0x4369B2)  -- patch size should be 5
local range_split_addr6 = locate_aob("BA 64 0B 00 00 EB 25 BA") -- (0x436AB9)  -- patch size should be 5
local range_split_addr7 = locate_aob("BD 39 1C 00 00 EB 7D BD") -- (0x435985)  -- patch size should be 5
local range_split_addr8 = locate_aob("BE 39 1C 00 00 E9 7D 00 00 00 BE") -- (0x436361)  -- patch size should be 5
local range_split_addr9 = locate_aob("B8 39 1C 00 00 EB 09 B8") -- (0x4369CE)  -- patch size should be 5
local range_split_addr10 = locate_aob("BA 39 1C 00 00 EB 09 BA") -- (0x436AD5)  -- patch size should be 5
local range_split_addr11 = locate_aob("83 E9 03 F7 D9 1B C9")  -- (0x53D642)1 -- patch size should be 13
local range_split_addr12 = locate_aob("03 D1 83 FA 79 7E")  -- (0x57770C)2 -- patch size should be 5

local scan_range_addr_archer = locate_aob("66 81 B8 ? ? ? ? 90 01 7F")
local scan_range_addr_arabbow_1 = locate_aob("85 FF BD 90 01 00 00 7E 28 8B C3")
local scan_range_addr_arabbow_2 = locate_aob("66 00 BD 90 01 00 00 66 39 AE ? ? ? ?")
local scan_range_addr_horse_archer = locate_aob("69 D2 90 04 00 00 66 81 BA ? ? ? ? B0 01")
local scan_range_addr_xbow = locate_aob("0F B7 88 ? ? ? ? 66 81 F9 90 01", scan_range_addr_archer + 500)
local scan_range_addr_xbow_2 = locate_aob("66 C7 86 ? ? ? ? 0A 00 66 81 BE ? ? ? ? 90 01")
local scan_range_addr_slinger_1 = locate_aob("0F B7 88 ? ? ? ? 66 81 F9 90 01", scan_range_addr_xbow + 500)
local scan_range_addr_slinger_2 = locate_aob("03 F9 81 FF E4 01 00 00 7E 17 C7 86 ? ? ? ? D8 FF FF FF")
local scan_range_addr_slinger_3 = locate_aob("89 8E ? ? ? ? 66 C7 86 ? ? ? ? 66 00 BD 90 01 00 00")
local scan_range_addr_firethrower_1 = locate_aob("0F B7 88 ? ? ? ? 66 81 F9 90 01", scan_range_addr_slinger_1 + 500)
local scan_range_addr_fbal_1 = locate_aob("66 C7 86 ? ? ? ? 03 00 66 81 BE ? ? ? ? A8 02")
local scan_range_addr_fbal_2 = locate_aob("0F AF FA 03 DF 81 FB 64 0B")
local scan_range_addr_mango = locate_aob("0F 85 E0 00 00 00 66 81 BE ? ? ? ? A8 02")
local scan_range_addr_towerbal_1 = locate_aob("C3 66 81 BE ? ? ? ? A8 02")
local scan_range_addr_towerbal_2 = locate_aob("C3 66 81 BE ? ? ? ? A8 02", scan_range_addr_towerbal_1 + 250)

-- rally running addresses
local arabbow_rally_running_addr = locate_aob("66 89 AE ? ? ? ? 66 8B 8E ? ? ? ?")
local slinger_rally_running_addr = locate_aob("66 89 86 ? ? ? ? 66 8B 96 ? ? ? ?")
local assassin_rally_running_addr = locate_aob("66 89 86 ? ? ? ? 89 86 ? ? ? ? C7 86 ? ? ? ? 10 00 00 00 66 8B 96 ? ? ? ?")
local firethrower_rally_running_addr = locate_aob("66 89 86 ? ? ? ? 66 8B 96 ? ? ? ? 53 B9 ? ? ? ? 66 89 96 ? ? ? ? E8", assassin_rally_running_addr)

-- half siege ammo addresses
local siege_initial_ammo_addr = locate_aob("74 0E 66 C7 86 76 09 00 00 14 00") + 9
local reload_amount_addr = locate_aob("66 83 80 ? ? ? ? 14 8D 80 ? ? ? ? C3")
local multi_reload_func_addr = locate_aob("0F BF 8E ? ? ? ? BF 14 00 00 00 2B F9 85 FF")

-- double iron pickup addresses
local iron_wait_addr = locate_aob("33 C9 39 88 ? ? ? ? 0F 94 C1 8D 4C 09 03")
local iron_subtract_addr = locate_aob("FF 6A ? 8D 80 ? ? ? ? 6A ? 51 E8")


local function extreme_only_feature_check(warning_message)
  if data.version.isExtreme() then
    return true
  end
  log(WARNING, warning_message)
  return false
end

local function reduce_height_advantage()
  core.writeCodeSmallInteger(0x400000 + 0x132408, 37008) -- Highground damage reduction for all units to 50%. {0x90, 0x90}
end

local function increase_enemy_check_frequency()
  core.writeCodeInteger(0x400000 + 0x17A08A, 20) -- Custom unit to closest enemy distance update rate cap (Set in gameticks, picked at random from 0 to this number, applies to all units
  core.writeCodeByte(0x400000 + 0x17A089, 0xB8)  -- Custom unit to closest enemy distance update rate cap, code adjustment 1
  core.writeCodeByte(0x400000 + 0x17A08E, 0x90)  -- Custom unit to closest enemy distance update rate cap, code adjustment 2
end

local function increase_minimap_unit_size()
  core.writeCodeByte(0x400000 + 0xB6FC0, 4) -- "Minimap unit size.", 
end


local function enable_spearmen_conditional_run()
  core.writeCodeBytes(0x400000 + 0x15E47B, {
    0x7e, 0x36
  })

  core.writeCodeBytes(0x400000 + 0x15E4B3, {
    0xE9, 0x74, 0xDE, 0x04, 0x00,
    0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90
  })

  core.writeCodeBytes(0x400000 + 0x1AC32C, {
    0x66, 0x81, 0xBE, 0xE2, 0xD2, 0x45, 0x01, 0xF0, 0x00,
    0x7F, 0x16,
    0xC7, 0x86, 0x44, 0xD0, 0x45, 0x01, 0x81, 0x00, 0x00, 0x00,
    0x66, 0x89, 0x86, 0xFA, 0xD2, 0x45, 0x01,
    0xE9, 0x73, 0x21, 0xFB, 0xFF, 0x89, 0x86, 0x44, 0xD0, 0x45, 0x01,
    0x66, 0x89, 0xBE, 0xFA, 0xD2, 0x45, 0x01,
    0xE9, 0x61, 0x21, 0xFB, 0xFF
  })

  core.writeCodeSmallInteger(0x400000+ 0x1AC333, 240) -- Spearman running trigger range around enemy units * 8."
end

local function enable_rebalance_features()
  ballista_damage_table_addr = core.allocate(#unit_names*4)
  mangonel_damage_table_addr = core.allocate(#unit_names*4)
  catapult_damage_table_addr = core.allocate(#unit_names*4)
  trebuchet_damage_table_addr = core.allocate(#unit_names*4)
  fire_damage_table_addr = core.allocate(#unit_names*4)

  for index, name in ipairs(unit_names) do
    if name == "Lord" then
      core.writeInteger(fire_damage_table_addr + 4*index, 25)
    elseif name == "Fireman" then
      core.writeInteger(fire_damage_table_addr + 4*index, 1)
    elseif name == "Arabian firethrower" then
      core.writeInteger(fire_damage_table_addr + 4*index, 10)
    else
      core.writeInteger(fire_damage_table_addr + 4*index, 100)
    end
  end

  for index, name in ipairs(unit_names) do
    if name == "Lord" then
      core.writeInteger(ballista_damage_table_addr + 4*(index-1), 50)
      core.writeInteger(mangonel_damage_table_addr + 4*(index-1), 50)
    elseif name == "Catapult" then
      core.writeInteger(ballista_damage_table_addr + 4*(index-1), 2500)
      core.writeInteger(mangonel_damage_table_addr + 4*(index-1), 5000)
    elseif name == "Trebuchet" then
      core.writeInteger(ballista_damage_table_addr + 4*(index-1), 4000)
      core.writeInteger(mangonel_damage_table_addr + 4*(index-1), 5000)
    elseif name == "Mangonel" then
      core.writeInteger(ballista_damage_table_addr + 4*(index-1), 2000)
      core.writeInteger(mangonel_damage_table_addr + 4*(index-1), 500)
    elseif name == "Siege tower" then
      core.writeInteger(ballista_damage_table_addr + 4*(index-1), 20000)
      core.writeInteger(mangonel_damage_table_addr + 4*(index-1), 10000)
    elseif name == "Battering ram" then
      core.writeInteger(ballista_damage_table_addr + 4*(index-1), 20000)
      core.writeInteger(mangonel_damage_table_addr + 4*(index-1), 10000)
    elseif name == "Portable shield" then
      core.writeInteger(ballista_damage_table_addr + 4*(index-1), 500)
      core.writeInteger(mangonel_damage_table_addr + 4*(index-1), 1500)
    elseif name == "Tower ballista" then
      core.writeInteger(ballista_damage_table_addr + 4*(index-1), 2000)
      core.writeInteger(mangonel_damage_table_addr + 4*(index-1), 1000)
    elseif name == "Fire ballista" then
      core.writeInteger(ballista_damage_table_addr + 4*(index-1), 2000)
      core.writeInteger(mangonel_damage_table_addr + 4*(index-1), 1000)
    else
      core.writeInteger(ballista_damage_table_addr + 4*(index-1), 10000)
      core.writeInteger(mangonel_damage_table_addr + 4*(index-1), 30000)
    end
  end

  for index, name in ipairs(unit_names) do
    if name == "Lord" then
      core.writeInteger(catapult_damage_table_addr + 4*(index-1), 50)
      core.writeInteger(trebuchet_damage_table_addr + 4*(index-1), 50)
    else
      core.writeInteger(catapult_damage_table_addr + 4*(index-1), 30000)
      core.writeInteger(trebuchet_damage_table_addr + 4*(index-1), 30000)
    end
  end

   -- enable fully changing melee damage of xbows to buildings
  core.writeCodeBytes(crossbow_building_melee_addr-12, core.compile({ 
    0x8B, 0x04, 0x95, core.itob(towers_or_gates_base), -- mov eax,[edx*4+005B9980]
    0x3C, 0x01,                                        -- cmp al,01
    0x75, 0x04,                                        -- jne 0055CE06
    0x31, 0xC0,                                        -- xor eax,eax
    0x2C, 0x02,                                        -- sub al,02
    0x04, 0x04,                                        -- add al,04
    0x90                                               -- nop 
  }, crossbow_building_melee_addr-12)
  )

  -- enable skirmish bonus&delivery modification for bakers
  core.writeCodeByte(baker_func, 0x90)
  core.insertCode(baker_func, 8, {}, baker_func+6, "after")
  core.writeCodeBytes(baker_func+6, {0x6A, 0x00})

  -- enable skirmish bonus&delivery modification for wheat farmers
  core.writeCodeByte(wheatfarmer_func, 0x90)
  core.insertCode(wheatfarmer_func, 8, {}, wheatfarmer_func+6, "after")
  core.writeCodeBytes(wheatfarmer_func+6, {0x6A, 0x00})

  -- enable skirmish bonus&delivery modification for brewers
  core.writeCodeByte(brewer_func, 0x90)
  core.writeCodeByte(brewer_func+8, 0x90)
  core.insertCode(brewer_func, 9, {}, brewer_func+5, "after")
  core.writeCodeBytes(brewer_func+5, {0x6A, 0x01, 0x6A, 0x01})

  -- enable skirmish bonus&delivery modification for bows/xbows
  local custom_fletcher_code = {
    0x50,                                       -- push eax
    0x69, 0xC0, 0x90, 0x04, 0x00, 0x00,         -- imul eax,eax,00000490
    0x0F, 0xBF, 0x80, core.itob(unit_array_base_addr+0x338),   -- movsx eax,word ptr [eax+0145D374]
    0x69, 0xC0, 0x2C, 0x03, 0x00, 0x00,         -- imul eax,eax,0000032C
    0x0F, 0xBF, 0x80, core.itob(building_array_base_addr+0x28E),   -- movsx eax,word ptr [eax+00F98C42]
    0x83, 0xF8, 0x11,                           -- cmp eax, 11
    0x58,                                       -- pop eax
    0x75, 0x06,                                 -- jne 6bytes
    0x6A, 0x01,                                 -- push 01
    0x6A, 0x01,                                 -- push 01
    0xEB, 0x04,                                 -- jmp 4bytes
    0x6A, 0x01,                                 -- push 01
    0x6A, 0x01,                                 -- push 01
  }

  core.writeCodeBytes(fletcher_func, {0x90, 0x90})
  custom_fletcher_code_addr = core.insertCode(fletcher_func, 9, custom_fletcher_code, fletcher_func+9, "after")

  -- enable skirmish bonus&delivery modification for spears/pikes
  local custom_poleturner_code = {
    0x50,                                       -- push eax
    0x8B, 0xC7,                                 -- mov eax, edi
    0x69, 0xC0, 0x90, 0x04, 0x00, 0x00,         -- imul eax,eax,00000490
    0x0F, 0xBF, 0x80, core.itob(unit_array_base_addr+0x338),   -- movsx eax,word ptr [eax+0145D374]
    0x69, 0xC0, 0x2C, 0x03, 0x00, 0x00,         -- imul eax,eax,0000032C
    0x0F, 0xBF, 0x80, core.itob(building_array_base_addr+0x28E),   -- movsx eax,word ptr [eax+00F98C42]
    0x83, 0xF8, 0x13,                           -- cmp eax, 13
    0x58,                                       -- pop eax
    0x75, 0x06,                                 -- jne 6bytes
    0x6A, 0x01,                                 -- push 01
    0x6A, 0x01,                                 -- push 01
    0xEB, 0x04,                                 -- jmp 4bytes
    0x6A, 0x01,                                 -- push 01
    0x6A, 0x01,                                 -- push 01
  }
  core.writeCodeByte(poleturner_func, 0x90)
  core.writeCodeByte(poleturner_func+8, 0x90)
  custom_poleturner_code_addr = core.insertCode(poleturner_func, 9, custom_poleturner_code, poleturner_func+9, "after")

  -- enable skirmish bonus&delivery modification for maces/swords
  local custom_blacksmith_code = {
    0x50,                                       -- push eax
    0x69, 0xC0, 0x90, 0x04, 0x00, 0x00,         -- imul eax,eax,00000490
    0x0F, 0xBF, 0x80, core.itob(unit_array_base_addr+0x338),   -- movsx eax,word ptr [eax+0145D374]
    0x69, 0xC0, 0x2C, 0x03, 0x00, 0x00,         -- imul eax,eax,0000032C
    0x0F, 0xBF, 0x80, core.itob(building_array_base_addr+0x28E),   -- movsx eax,word ptr [eax+00F98C42]
    0x83, 0xF8, 0x11,                           -- cmp eax, 15
    0x58,                                       -- pop eax
    0x75, 0x06,                                 -- jne 6bytes
    0x6A, 0x01,                                 -- push 01
    0x6A, 0x01,                                 -- push 01
    0xEB, 0x04,                                 -- jmp 4bytes
    0x6A, 0x01,                                 -- push 01
    0x6A, 0x01,                                 -- push 01
  }

  core.writeCodeBytes(blacksmith_func, {0x90, 0x90})
  custom_blacksmith_code_addr = core.insertCode(blacksmith_func, 9, custom_blacksmith_code, blacksmith_func+9, "after")

  -- enable skirmish bonus&delivery modification for tanners
  core.writeCodeBytes(tanner_func, {0x90, 0x90, 0x90})
  core.insertCode(tanner_func, 10, {}, tanner_func+5, "after")
  core.writeCodeBytes(tanner_func+5, {0x6A, 0x01, 0x6A, 0x01, 0x50})

  -- enable skirmish bonus&delivery modification for armourers
  core.writeCodeByte(armourer_func, 0x90)
  core.writeCodeByte(armourer_func+8, 0x90)
  core.insertCode(armourer_func, 9, {}, armourer_func+5, "after")
  core.writeCodeBytes(armourer_func+5, {0x6A, 0x01, 0x6A, 0x01})

  resource_production_offset_map["Wood"] =    {baseDelivery=woodcutter_func+10,             skirmishBonus=woodcutter_func+1}
  resource_production_offset_map["Stone"] =   {baseDelivery=quarry_grunt_func+3,            skirmishBonus=quarry_grunt_func+1}
  resource_production_offset_map["Iron"] =    {baseDelivery=ironminer_func+9,               skirmishBonus=ironminer_func+1}
  resource_production_offset_map["Pitch"] =   {baseDelivery=pitchman_func+10,               skirmishBonus=pitchman_func+1}
  resource_production_offset_map["Meat"] =    {baseDelivery=hunter_func+10,                 skirmishBonus=hunter_func+1}
  resource_production_offset_map["Fruit"] =   {baseDelivery=apple_farmer_func+3,            skirmishBonus=apple_farmer_func+1}
  resource_production_offset_map["Cheese"] =  {baseDelivery=dairy_farmer_func+10,           skirmishBonus=dairy_farmer_func+1}
  resource_production_offset_map["Hop"] =     {baseDelivery=hops_farmer_func+5,             skirmishBonus=hops_farmer_func+1}
  resource_production_offset_map["Bread"] =   {baseDelivery=baker_func+9,                   skirmishBonus=baker_func+7}
  resource_production_offset_map["Wheat"] =   {baseDelivery=wheatfarmer_func+9,             skirmishBonus=wheatfarmer_func+7}
  resource_production_offset_map["Flour"] =   {baseDelivery="Not supported.",               skirmishBonus="Not supported."}
  resource_production_offset_map["Beer"] =    {baseDelivery=brewer_func+8,                  skirmishBonus=brewer_func+6}
  resource_production_offset_map["Bow"] =     {baseDelivery=custom_fletcher_code_addr+36,   skirmishBonus=custom_fletcher_code_addr+34}
  resource_production_offset_map["Xbow"] =    {baseDelivery=custom_fletcher_code_addr+42,   skirmishBonus=custom_fletcher_code_addr+40}
  resource_production_offset_map["Spear"] =   {baseDelivery=custom_poleturner_code_addr+38, skirmishBonus=custom_poleturner_code_addr+36}
  resource_production_offset_map["Pike"] =    {baseDelivery=custom_poleturner_code_addr+44, skirmishBonus=custom_poleturner_code_addr+42}
  resource_production_offset_map["Mace"] =    {baseDelivery=custom_blacksmith_code_addr+36, skirmishBonus=custom_blacksmith_code_addr+34}
  resource_production_offset_map["Sword"] =   {baseDelivery=custom_blacksmith_code_addr+42, skirmishBonus=custom_blacksmith_code_addr+40}
  resource_production_offset_map["Leather"] = {baseDelivery=tanner_func+8,                  skirmishBonus=tanner_func+6}
  resource_production_offset_map["Armor"] =   {baseDelivery=armourer_func+8,                skirmishBonus=armourer_func+6}

  -- enable custom taxation multipliers
  tax_table_addr = core.allocate(12*2)
  local custom_tax_instructions = {
    0x8A, 0x44, 0x24, 0x0C,                          -- mov eax [esp+0C]
    0x66, 0x8B, 0x04, 0x45, core.itob(tax_table_addr),  -- mov ax,[eax*2+Stronghold_Crusader_Extreme.exe+45AD]
    0x0F, 0xAF, 0x44, 0x24, 0x10,                    -- imul eax,[esp+10]
    0xC3                                             -- return
  }

  local divby10_code = {
    0x52,
    0x51,
    0x8B, 0xC8,
    0xBA, 0x67, 0x66, 0x66, 0x66,
    0xF7, 0xEA,
    0xD1, 0xFA,
    0x8B, 0xC1,
    0xC1, 0xF8, 0x1F,
    0x29, 0xC2,
    0x8B, 0xC2,
    0x59,
    0x5A,
    0xC3,
  }

  local custom_tax_addr = core.allocateCode(18)
  local divby10_addr = core.allocateCode(25)
  core.writeCodeBytes(divby10_addr, divby10_code)
  local tax_jumpout_instructions = {
    0xE8, core.itob(custom_tax_addr - tax_addr-5),  -- call 40459B
    0xE8, core.itob(divby10_addr - tax_addr-10),  -- call 4045F9
    0xEB, 0x02,  -- jump over 2 bytes
    0x90, 0x90,
    0xC1, 0xF8, 0x03,  -- sar eax,03
    0x83, 0x3D, 0xF0, 0x4D, 0x35, 0x02, 0x00 -- cmp dword ptr [Stronghold_Crusader_Extreme.exe+1F54DF0],00
  }

  local bribe_jumpout_instructions = {
    0xE8, core.itob(custom_tax_addr - bribe_addr-5),  -- call 40459B
    0xE8, core.itob(divby10_addr - bribe_addr-10),  -- call 4045F9
    0x90,
    0xC1, 0xF8, 0x02  -- sar eax,02
  }

  core.writeCodeBytes(tax_addr, core.compile(tax_jumpout_instructions, tax_addr))
  core.writeCodeBytes(bribe_addr, core.compile(bribe_jumpout_instructions, bribe_addr))
  core.writeCodeBytes(custom_tax_addr, core.compile(custom_tax_instructions, custom_tax_addr))
  local default_tax_table = {"1.0", "0.8", "0.6", "0.0", "0.6", "0.8", "1.0", "1.2", "1.4", "1.6", "1.8", "2.0"}
  for idx, tax_val in ipairs(default_tax_table) do
    core.writeCodeSmallInteger(tax_table_addr+2*(idx-1), math.floor(tax_val*100))
  end

  -- enable per-unit damage definition for ballistas, catapults and trebuchets
  core.writeCodeBytes(ballista_damage_addr-14,
    core.compile({
      0x75, 0x13,                                                     -- jne 005322D2
      0x0F, 0xB7, 0x8C, 0x3E, core.itob(0x6A2),                       -- movzx ecx,word ptr [esi+edi+000006A2]
      0x49,                                                           -- dec ecx
      0x8B, 0x0C, 0x8D, core.itob(ballista_damage_table_addr), 0x90,  -- mov ecx,[ecx*4+053FF2C0]  -- clear the nops later.
      0xEB, 0x76,                                                     -- jmp 00532348
      0x66, 0x83, 0xFB, 0x02,                                         -- cmp bx,02
      0x75, 0x13,                                                     -- jne 005322EB
      0x0F, 0xB7, 0x8C, 0x3E, core.itob(0x6A2),                       -- movzx ecx,word ptr [esi+edi+000006A2]
      0x49,                                                           -- dec ecx
      0x8B, 0x0C, 0x8D, core.itob(catapult_damage_table_addr), 0x90,  -- mov ecx,[ecx*4+053FF2C0]  -- clear the nops later.
      0xEB, 0x17,                                                     -- jmp 00532302
      0x66, 0x83, 0xFB, 0x03,                                         -- cmp bx,03
      0x75, 0x75,                                                     -- jne 00532366
      0x0F, 0xB7, 0x8C, 0x3E, core.itob(0x6A2),                       -- movzx ecx,word ptr [esi+edi+000006A2]
      0x49,                                                           -- dec ecx
      0x8B, 0x0C, 0x8D, core.itob(trebuchet_damage_table_addr), 0x90, -- mov ecx,[ecx*4+053FF2C0]  -- clear the nops later.
      0xEB, 0x7C,                                                     -- jmp 00532380
    }, ballista_damage_addr-14)
  )

  for i=57,124 do core.writeCodeByte(ballista_damage_addr+i, 0x90) end -- nop out remaining bytes

  -- enable per-unit damage definition for mangonels
  core.writeCodeBytes(mangonel_damage_addr,
    core.compile({
      0x49, -- sub ecx
      0x8B, 0x0C, 0x8D, core.itob(mangonel_damage_table_addr), 0x90, -- mov ecx, [ecx*4+ballista_damage_table_addr]  -- clear the nops later.
      0xE9, core.itob(339)  -- jmp 339 bytes forward
    }, mangonel_damage_addr)
  )
  for i=14,153,5 do core.writeCodeBytes(mangonel_damage_addr+i, {0xBB, 0,0,0,0}) end -- fill 140 bytes with trash

  -- enable unit display costs&actual costs to be read from same place
  core.writeCodeBytes(non_rax_unit_display_cost_func_addr+14,{
    0xB3, 0x1E, -- mov bl, engineer_cost
    0xEB, 0x0F,
    0xB3, 0x04, -- mov bl, laddermen_cost
    0xEB, 0x0B,
    0xB3, 0x1E, -- mov bl, tunnellor_cost
    0xEB, 0x07,
    0xB3, 0x0A, -- mov bl, monk_cost
    0xEB, 0x03,
    0x90, 0x90, 0x90,
  })
  core.writeCodeBytes(unit_gold_jumplist_addr, core.compile({
      core.itob(non_rax_unit_display_cost_func_addr + 14),
      core.itob(non_rax_unit_display_cost_func_addr + 18),
      core.itob(non_rax_unit_display_cost_func_addr + 22),
      core.itob(non_rax_unit_display_cost_func_addr + 26),
    },unit_gold_jumplist_addr)
  )

  core.writeCodeByte(non_rax_unit_cost_func_addr+6, 70)  -- compare unit id with arab bow

  core.writeCodeBytes(non_rax_unit_cost_func_addr+18, core.compile({
      0x7C, 0x10,
      0x50,
      0x83, 0xE8, 0x46,
      0xC1, 0xE0, 0x02,
      0x8B, 0xA8, core.itob(ar_unit_gold_cost_base),
      0x58,
      0xEB, 0x5A,
      0x83, 0xF8, 0x1E,
      0x75, 0x07,
      0xBD, 0x1E, 0x00, 0x00, 0x00,
      0xEB, 0x4E,
      0x83, 0xF8, 0x1D,
      0x75, 0x07,
      0xBD, 0x04, 0x00, 0x00, 0x00,
      0xEB, 0x42,
      0x83, 0xF8, 0x05,
      0x75, 0x07,
      0xBD, 0x1E, 0x00, 0x00, 0x00,
      0xEB, 0x36,
      0x83, 0xF8, 0x25,
      0x75, 0x07,
      0xBD, 0x0A, 0x00, 0x00, 0x00,
      0xEB, 0x2A
    }, non_rax_unit_cost_func_addr+18
  ))

  core.writeCodeBytes(fire_damage_code_addr, core.compile({
    0x8B, 0x04, 0xBD, core.itob(fire_damage_table_addr),  -- mov ax,[edi*4+fire_damage_table_addr]
    0xBD, 0x01, 0x00, 0x00, 0x00,                         -- mov ebp,00000001
    0xEB, 0x25                                            -- jmp +24
  }, fire_damage_code_addr)
  )

end

local function edit_buildings(buildings)
  local address = 0
  for building, stats in pairs(buildings) do
    local cost = stats["cost"]
    local health = stats["health"]
    local housing = stats["housing"]
    local building_idx = table.find(building_names, building)-1
    if cost ~= nil then
      address = building_cost_base + 20 * building_idx
      core.writeInteger(address, cost[1])
      core.writeInteger(address+4, cost[2])
      core.writeInteger(address+8, cost[3])
      core.writeInteger(address+12, cost[4])
      core.writeInteger(address+16, cost[5])
    end

    if health ~= nil then
      address = building_health_base + 4 * building_idx
      core.writeInteger(address, health)
    end

    if housing ~= nil then
      address = building_population_base + 4 * building_idx
      core.writeInteger(address, housing)
    end
  end
end

local function edit_siege(siege)
  local default_ballista_damage = 10000
  local default_mangonel_damage = 30000
  local default_catapult_damage = 30000
  local default_trebuchet_damage = 30000
  if siege["catapultRockDamage"] ~= nil then core.writeCodeInteger(cat_primary_addr, siege["catapultRockDamage"]) end
  if siege["catapultRockCollateralDamage"] ~= nil then core.writeCodeInteger(cat_collateral_addr, siege["catapultRockCollateralDamage"]) end
  if siege["trebuchetRockDamage"] ~= nil then core.writeCodeInteger(treb_primary_addr, siege["trebuchetRockDamage"]) end
  if siege["trebuchetRockCollateralPenalty"] ~= nil then core.writeCodeByte(treb_collateral_penalty_addr, siege["trebuchetRockCollateralPenalty"]) end
  if siege["mangonelPebbleDamage"] ~= nil then core.writeCodeInteger(mango_primary_addr, siege["mangonelPebbleDamage"]) end
  if siege["defaultMangonelPebbleUnitDamage"] ~= nil then default_mangonel_damage = siege["defaultMangonelPebbleUnitDamage"] end
  if siege["defaultCatapultRockUnitDamage"] ~= nil then default_catapult_damage = siege["defaultCatapultRockUnitDamage"] end
  if siege["defaultTrebuchetRockUnitDamage"] ~= nil then default_trebuchet_damage = siege["defaultTrebuchetRockUnitDamage"] end
  if siege["defaultBallistaBoltUnitDamage"] ~= nil then default_ballista_damage = siege["defaultBallistaBoltUnitDamage"] end
  if siege["siegeProjectileOneShotThreshold"] ~= nil then core.writeCodeInteger(oneshot_threshold_addr+2, siege["siegeProjectileOneShotThreshold"]) end
  if siege["enable_half_siege_ammo"] ~= nil and siege["enable_half_siege_ammo"] == true then 
    core.writeCodeSmallInteger(siege_initial_ammo_addr, 10) -- "Catapult/Trebuchet initial stone.",     
    core.writeCodeByte(reload_amount_addr+7, 10) -- "Catapult stone reload amount.",             
    core.writeCodeByte(multi_reload_func_addr+8, 10) -- "Default max. ammunition amount.",             
    core.writeCodeByte(multi_reload_func_addr+20, 0) -- "Rounding extra stone cost.",       
    core.writeCodeBytes(multi_reload_func_addr+32, {0x90, 0x90})  -- "Shift left to divide instruction.",  nop-out
    core.writeCodeBytes(multi_reload_func_addr+121, {0x89, 0xC6, 0x90})
  end

  for index, name in ipairs(unit_names) do
    if name == "Lord"
    or name == "Catapult"
    or name == "Trebuchet"
    or name == "Mangonel"
    or name == "Siege tower"
    or name == "Battering ram"
    or name == "Portable shield"
    or name == "Tower ballista"
    or name == "Fire ballista" then  -- defaults are set once
    else
      core.writeInteger(ballista_damage_table_addr + 4*(index-1), default_ballista_damage)
      core.writeInteger(mangonel_damage_table_addr + 4*(index-1), default_mangonel_damage)
    end
  end

  for index, name in ipairs(unit_names) do
    if name == "Lord" then  -- defaults are set once
    else
      core.writeInteger(catapult_damage_table_addr + 4*(index-1), default_catapult_damage)
      core.writeInteger(trebuchet_damage_table_addr + 4*(index-1), default_trebuchet_damage)
    end
  end
end

local function edit_castle(castle)
  local ditch_per_pitch = castle["ditch_per_pitch"]
  local killing_pit_damage = castle["killing_pit_damage"]
  local dog_trigger_threshold = castle["dog_trigger_threshold"]
  local fire_damage = castle["fire_damage"]

  if ditch_per_pitch ~= nil then
    if ditch_per_pitch == 1 then -- 0
      core.writeCodeSmallInteger(pitch_ditch_costaddr, 0)
    elseif ditch_per_pitch == 2 then -- 3
      core.writeCodeSmallInteger(pitch_ditch_costaddr, 3)
    elseif ditch_per_pitch == 3 then -- 2
      core.writeCodeSmallInteger(pitch_ditch_costaddr, 2)
    elseif ditch_per_pitch == 4 then -- 1
      core.writeCodeSmallInteger(pitch_ditch_costaddr, 1)
    else
      log(WARNING, "Ditch per pitch can only be a value from 1 to 4.")
    end
  end

  if killing_pit_damage ~= nil then
    if killing_pit_damage > 0 then  -- force negative value
      killing_pit_damage = -killing_pit_damage
    end
    core.writeCodeInteger(killing_pit_dmg_addr, killing_pit_damage)
  end

  if dog_trigger_threshold ~= nil then 
    core.writeCodeByte(dog_threshold_addr, dog_trigger_threshold)
  end

  if fire_damage ~= nil then
    for index, name in ipairs(unit_names) do
      if name == "Lord"
      or name == "Fireman"
      or name == "Arabian firethrower" then -- defaults are set once
      else
        core.writeInteger(fire_damage_table_addr + 4*index, fire_damage)
      end
    end
  end
end

local function edit_units(units)
  local function get_unit_melee_dmg_address(attacker, defender)
    local attacker_idx = table.find(unit_names, attacker) - 1
    local defender_idx = table.find(unit_names, defender) - 1
    return unit_melee_dmg_base + defender_idx * 4 + attacker_idx * 16 + attacker_idx * (#unit_names - 1) * 4
  end
  local address = 0
  for unit, stats in pairs(units) do
    local health = stats["health"]
    local arrowDamage = stats["arrowDamage"]
    local xbowDamage = stats["xbowDamage"]
    local stoneDamage = stats["stoneDamage"]
    local ballistaBoltDamage = stats["ballistaBoltDamage"]
    local catapultRockDamage = stats["catapultRockDamage"]
    local trebuchetRockDamage = stats["trebuchetRockDamage"]
    local mangonelDamage = stats["mangonelDamage"]
    local baseMeleeDamage = stats["baseMeleeDamage"]
    local meleeDamageVs = stats["meleeDamageVs"]
    local buildingDamage = stats["buildingDamage"]
    local fortificationDamagePenalty = stats["fortificationDamagePenalty"]
    local fortificationDamage = stats["fortificationDamage"]
    local wallDamage = stats["wallDamage"]
    local powerLevel = stats["powerLevel"]
    local meleeEngage = stats["meleeEngage"]
    local notBlessable = stats["notBlessable"]
    local meleeImmunity = stats["meleeImmunity"]
    local allowedOnWalls = stats["allowedOnWalls"]
    local fireDamage = stats["fireDamage"]
    local jesterUnfriendly = stats["jesterUnfriendly"]

    local goldCost = stats["goldCost"]
    local speedLevel = stats["speedLevel"]
    local unit_military_idx = table.find(military_ground_unit_names, unit)
    local unit_idx_p1 = table.find(unit_names, unit)
    local unit_idx = unit_idx_p1-1

    if health ~= nil then core.writeInteger(unit_health_base + unit_idx * 4, health) end
    if arrowDamage ~= nil then core.writeInteger(unit_arrow_dmg_base + unit_idx * 4, arrowDamage) end
    if xbowDamage ~= nil then core.writeInteger(unit_xbow_dmg_base + unit_idx * 4, xbowDamage) end
    if stoneDamage ~= nil then core.writeInteger(unit_stone_dmg_base + unit_idx * 4, stoneDamage) end
    if meleeEngage ~= nil then core.writeInteger(unit_melee_toggles_base + 4*unit_idx, meleeEngage and 1 or 0) end
    if notBlessable ~= nil then core.writeInteger(unit_blessable_base + 4*unit_idx, notBlessable and 1 or 0) end
    if allowedOnWalls ~= nil then core.writeInteger(unit_allowed_on_walls_base + 4*unit_idx, allowedOnWalls and 1 or 0) end
    if fireDamage ~= nil then core.writeInteger(fire_damage_table_addr + 4*unit_idx_p1, fireDamage) end
    if jesterUnfriendly ~= nil then core.writeInteger(unit_jester_unfriendly_base + 4*unit_idx, jesterUnfriendly and 1 or 0) end
    if meleeImmunity ~= nil then core.writeInteger(unit_melee_immunity_base + 4*unit_idx, meleeImmunity and 1 or 0) end
    if ballistaBoltDamage ~= nil then core.writeInteger(ballista_damage_table_addr + 4*unit_idx, ballistaBoltDamage) end
    if mangonelDamage ~= nil then core.writeInteger(mangonel_damage_table_addr + 4*unit_idx, mangonelDamage) end
    if catapultRockDamage ~= nil then core.writeInteger(catapult_damage_table_addr + 4*unit_idx, catapultRockDamage) end
    if trebuchetRockDamage ~= nil then core.writeInteger(trebuchet_damage_table_addr + 4*unit_idx, trebuchetRockDamage) end
    if speedLevel ~= nil then core.writeInteger(unit_speed_base + unit_idx*4, speedLevel) end

    if baseMeleeDamage ~= nil then
      for _, defender in ipairs(unit_names) do
        address = get_unit_melee_dmg_address(unit, defender)
        core.writeInteger(address, baseMeleeDamage)
      end
    end

    if meleeDamageVs ~= nil then
      for defender, damage in pairs(meleeDamageVs) do
        address = get_unit_melee_dmg_address(unit, defender)
        core.writeInteger(address, damage)
      end
    end

    if powerLevel ~= nil then
      if unit_military_idx ~= nil then
        core.writeInteger(unit_power_levels_addr + 4*(unit_military_idx-1), powerLevel)
      end
    end

    if goldCost ~= nil then
      local is_arab_unit = unit_idx_p1 >= arabbow_idx and unit_idx_p1 <= table.find(unit_names, "Arabian firethrower")
      local is_other_trainable_unit = unit_idx_p1 == 5 or unit_idx_p1 == 29 or unit_idx_p1 == 30 or unit_idx_p1 == 37
      -- other trainable units are tunneller, laddermen, engineer or monk
      if unit_idx_p1 >= archer_idx and unit_idx_p1 <= table.find(unit_names, "European knight") then
        local eu_unit_idx = unit_idx_p1 - archer_idx
        address = eu_unit_gold_cost_base + 4 * eu_unit_idx
        core.writeInteger(address, goldCost)
      end
      if is_arab_unit then
        local ar_unit_idx = unit_idx_p1 - arabbow_idx
        address = ar_unit_gold_cost_base + 4*ar_unit_idx
        core.writeInteger(address, goldCost)
      end  -- arab unit display cost

      if is_other_trainable_unit then
        if unit_idx_p1 == 30 then -- engineer cost
          core.writeCodeByte(non_rax_unit_display_cost_func_addr + 15, goldCost)
          core.writeCodeInteger(non_rax_unit_cost_func_addr+42, goldCost)
        elseif unit_idx_p1 == 29 then -- laddermen cost
          core.writeCodeByte(non_rax_unit_display_cost_func_addr + 19, goldCost)
          core.writeCodeInteger(non_rax_unit_cost_func_addr+54, goldCost)
        elseif unit_idx_p1 == 5 then -- tunnellor cost
          core.writeCodeByte(non_rax_unit_display_cost_func_addr + 23, goldCost)
          core.writeCodeInteger(non_rax_unit_cost_func_addr+66, goldCost)
        else -- monk cost (37)
          core.writeCodeByte(non_rax_unit_display_cost_func_addr + 27, goldCost)
          core.writeCodeInteger(non_rax_unit_cost_func_addr+78, goldCost)
        end
      end  -- other unit display cost

    end

    if buildingDamage ~= nil then core.writeCodeByte(unit_melee_damage_offset_map[unit]["building"], buildingDamage) end

    if fortificationDamagePenalty ~= nil then
      log(ERROR, string.format("[%s] fortificationDamagePenalty is removed, update your config to use fortificationDamage instead.", unit))
    end

    if fortificationDamage ~= nil then
      address = unit_melee_damage_offset_map[unit]["fortification"]
      if address == "Not supported." then
        log(WARNING, string.format("[%s] fortificationDamage is not supported.", unit))
      else
        local fdp = core.readByte(unit_melee_damage_offset_map[unit]["building"]) - fortificationDamage
        if unit == "European crossbowman" then
          core.writeCodeByte(address, fdp)  -- special case.
        else
          core.writeCodeByte(address, -fdp)
        end
      end
    end

    if wallDamage ~= nil then
      address = unit_melee_damage_offset_map[unit]["wall"]
      if address == "Not supported." then
        log(WARNING, string.format("[%s] wallDamage is not supported.", unit))
      else
        core.writeCodeByte(address, wallDamage)
      end
    end

  end
end

local function edit_resources(resources)
  local address = 0
  for res_name, attrs in pairs(resources) do
    local buy = attrs["buy"]
    local sell = attrs["sell"]
    local baseDelivery = attrs["baseDelivery"]
    local skirmishBonus = attrs["skirmishBonus"]
    local res_index = table.find(resource_names, res_name)-1
    if buy ~= nil then
      address = resource_buy_base + 4 * res_index
      core.writeInteger(address, buy)
    end

    if sell ~= nil then
      address = resource_sell_base + 4 * res_index
      core.writeInteger(address, sell)
    end

    if baseDelivery ~= nil then
      address = resource_production_offset_map[res_name]["baseDelivery"]
      if address == "Not supported." then
        log(WARNING, string.format("%s  production cannot be modified.", res_name))
      else
        core.writeCodeByte(address, baseDelivery)
      end
    end

    if skirmishBonus ~= nil then
      local sb = skirmishBonus and 1 or 0
      address = resource_production_offset_map[res_name]["skirmishBonus"]
      if address == "Not supported." then
        log(WARNING, string.format("%s  production cannot be modified.", res_name))
      else
        core.writeCodeByte(address, sb)
      end
    end
  end
end

local function edit_population(population)
  local gathering_rate_skirmish = population["gathering_rate_skirmish"]
  local gathering_rate_scenario_small_town = population["gathering_rate_scenario_small_town"]
  local gathering_rate_scenario_large_town = population["gathering_rate_scenario_large_town"]
  local large_town_threshold = population["large_town_threshold"]
  local civilian_upkeep = population["civilian_upkeep"]
  local minimum_population = population["minimum_population"]
  local reset_population_threshold = population["reset_population_threshold"]
  local reset_popularity_threshold = population["reset_popularity_threshold"]
  local reset_popularity_value = population["reset_popularity_value"]
  local crowding = population["crowding"]

  if gathering_rate_skirmish ~= nil then
    for pgr_index, value in ipairs(gathering_rate_skirmish) do
      core.writeInteger(skirmish_pgr_base + 4 * (pgr_index-1), value)
    end
  end
  if gathering_rate_scenario_small_town ~= nil then
    for pgr_index, value in ipairs(gathering_rate_scenario_small_town) do
      core.writeInteger(scenario_pgr_base + 4 * (pgr_index-1), value)
    end
  end
  if gathering_rate_scenario_large_town ~= nil then
    for pgr_index, value in ipairs(gathering_rate_scenario_large_town) do
      core.writeInteger(scenario_pgr_crowded_base + 4 * (pgr_index-1), value)
    end
  end
  if civilian_upkeep ~= nil then
    local slower_gathering = civilian_upkeep["slower_gathering"]
    local minimum_gathering = civilian_upkeep["minimum_gathering"]
    local faster_leaving = civilian_upkeep["faster_leaving"]
    if minimum_gathering == nil then
      minimum_gathering = 4
    end
    if slower_gathering < 1 then
      log(WARNING, "Upkeep values must be between 1 and 5")
      slower_gathering = 1
    end
    if slower_gathering > 5 then
      log(WARNING, "Upkeep values must be between 1 and 5")
      slower_gathering = 5
    end
    if faster_leaving < 1 then
      log(WARNING, "Upkeep values must be between 1 and 5")
      faster_leaving = 1
    end
    if faster_leaving > 5 then
      log(WARNING, "Upkeep values must be between 1 and 5")
      faster_leaving = 5
    end

    local upkeep_code_bytes = core.assemble([[
      push eax
      mov eax, [esi+0x2110]
      cmp ecx, 0
      jl label_0
      shr eax, gather_factor
      cmp eax, ecx
      jg label_2
      jmp label_1
          label_0:
      shr eax, leave_factor
          label_1:
      sub ecx, eax
      jmp end_label
          label_2:
      mov ecx, minimum_gather
          end_label:
      pop eax
    ]],{
      leave_factor = 7-faster_leaving,
      minimum_gather = minimum_gathering,
      gather_factor = 7-slower_gathering
    },0)
    core.insertCode(pop_gathering_addr, 7, upkeep_code_bytes, pop_gathering_addr+7, "before")
  end
  if minimum_population ~= nil then
    core.writeCodeByte(min_peasants_addr, minimum_population)
  end
  if reset_population_threshold ~= nil then
    core.writeCodeByte(pop_reset_population_limit_addr, reset_population_threshold)
  end
  if reset_popularity_threshold ~= nil then
    core.writeCodeInteger(pop_reset_popularity_limit_addr, reset_popularity_threshold)
  end
  if reset_popularity_value ~= nil then
    core.writeCodeInteger(pop_reset_value_addr, reset_popularity_value)
  end
  if large_town_threshold ~= nil then
    core.writeCodeByte(large_town_threshold_addr, large_town_threshold)
  end
  if crowding ~= nil then
    local thresholds = crowding["thresholds"]
    local penalties = crowding["penalties"]
    if thresholds ~= nil then
      core.writeCodeByte(crowding_addr_1+15, thresholds[1])
      core.writeCodeByte(crowding_addr_1+29, thresholds[2])
      core.writeCodeInteger(crowding_addr_1+45, thresholds[3])
      core.writeCodeInteger(crowding_addr_1+64, thresholds[4])
      core.writeCodeInteger(crowding_addr_1+67, thresholds[5])

      core.writeCodeByte(crowding_addr_2+15, thresholds[1])
      core.writeCodeByte(crowding_addr_2+29, thresholds[2])
      core.writeCodeInteger(crowding_addr_2+45, thresholds[3])
      core.writeCodeInteger(crowding_addr_2+64, thresholds[4])
      core.writeCodeInteger(crowding_addr_2+67, thresholds[5])
    end
    if penalties ~= nil then
      core.writeCodeInteger(crowding_addr_1+2, penalties[1])
      core.writeCodeInteger(crowding_addr_1+11, penalties[2])
      core.writeCodeInteger(crowding_addr_1+22, penalties[3])
      core.writeCodeByte(crowding_addr_1+36, penalties[4]-penalties[5])
      core.writeCodeInteger(crowding_addr_1+52, penalties[5])

      core.writeCodeInteger(crowding_addr_2+2, penalties[1])
      core.writeCodeInteger(crowding_addr_2+11, penalties[2])
      core.writeCodeInteger(crowding_addr_2+22, penalties[3])
      core.writeCodeByte(crowding_addr_2+36, penalties[4]-penalties[5])
      core.writeCodeInteger(crowding_addr_2+52, penalties[5])
    end
  end

end

local function edit_religion(religion)
  local religion_thresholds = religion["thresholds"]
  local religion_bonuses = religion["bonuses"]
  local religion_multipliers = religion["multipliers"]
  local church_bonus = religion["church_bonus"]
  local cathedral_bonus = religion["cathedral_bonus"]
  if religion_thresholds ~= nil then
    core.writeCodeByte(religion_addr_1 + 2, religion_thresholds[1])
    core.writeCodeByte(religion_addr_1 + 11, religion_thresholds[2])
    core.writeCodeByte(religion_addr_1 + 23, religion_thresholds[3])
    core.writeCodeByte(religion_addr_1 + 37, religion_thresholds[4])

    core.writeCodeByte(religion_addr_2 + 2, religion_thresholds[1])
    core.writeCodeByte(religion_addr_2 + 11, religion_thresholds[2])
    core.writeCodeByte(religion_addr_2 + 23, religion_thresholds[3])
    core.writeCodeByte(religion_addr_2 + 37, religion_thresholds[4])

    core.writeCodeByte(religion_addr_2 + 100, religion_thresholds[1]-1)
    core.writeCodeByte(religion_addr_2 + 115, religion_thresholds[2]-1)
    core.writeCodeByte(religion_addr_2 + 130, religion_thresholds[3]-1)
    core.writeCodeByte(religion_addr_2 + 145, religion_thresholds[4]-1)

    core.writeCodeInteger(religion_addr_2 + 107, religion_thresholds[1])
    core.writeCodeInteger(religion_addr_2 + 122, religion_thresholds[2])
    core.writeCodeInteger(religion_addr_2 + 137, religion_thresholds[3])
    core.writeCodeInteger(religion_addr_2 + 152, religion_thresholds[4])

    core.writeCodeByte(religion_addr_3 + 2, religion_thresholds[1]-1)
    core.writeCodeByte(religion_addr_3 + 11, religion_thresholds[2]-1)
    core.writeCodeByte(religion_addr_3 + 23, religion_thresholds[3]-1)
    core.writeCodeByte(religion_addr_3 + 37, religion_thresholds[4]-1)
  end
  if religion_bonuses ~= nil then
    core.writeCodeInteger(religion_addr_1 + 15, religion_bonuses[1])
    core.writeCodeInteger(religion_addr_1 + 27, religion_bonuses[2])
    core.writeCodeByte(religion_addr_1 + 46, religion_bonuses[3]-religion_bonuses[4])
    core.writeCodeInteger(religion_addr_1 + 49, religion_bonuses[4])

    core.writeCodeInteger(religion_addr_2 + 15, religion_bonuses[1])
    core.writeCodeByte(religion_addr_2 + 27, religion_bonuses[2])
    core.writeCodeByte(religion_addr_2 + 46, religion_bonuses[3]-religion_bonuses[4])
    core.writeCodeInteger(religion_addr_2 + 49, religion_bonuses[4])

    core.writeCodeInteger(religion_addr_3 + 15, religion_bonuses[1])
    core.writeCodeInteger(religion_addr_3 + 27, religion_bonuses[2])
    core.writeCodeByte(religion_addr_3 + 46, religion_bonuses[3]-religion_bonuses[4])
    core.writeCodeByte(religion_addr_3 + 49, religion_bonuses[4])
  end
  if religion_multipliers ~= nil then
    if religion_thresholds == nil then
      religion_thresholds = {25, 50, 75, 100} -- vanilla thresholds are 24 49 74 94
    end
    local assembled_code = core.assemble(scaling_code,{
      threshold_1 = religion_thresholds[1],
      threshold_2 = religion_thresholds[2],
      threshold_3 = religion_thresholds[3],
      threshold_4 = religion_thresholds[4],
      multiplier_1 = religion_multipliers[1],
      multiplier_2 = religion_multipliers[2],
      multiplier_3 = religion_multipliers[3],
      multiplier_4 = religion_multipliers[4]
    },0)
    assembled_code["n"] = nil
    -- religion_addr_1 (53 bytes) info:eax  target:ecx
    core.writeCodeByte(religion_addr_1, 0x50) -- push eax
    core.insertCode(religion_addr_1+1, 49, assembled_code)
    core.writeCodeBytes(religion_addr_1+50, {
      0x8B, 0xC8, -- mov ecx, eax
      0x58        -- pop eax
    })
    -- religion_addr_2 (55 bytes) info: eax  target: eax
    core.insertCode(religion_addr_2, 55, assembled_code)
    -- religion_addr_3 (55 bytes) info: eax  target: esi
    core.writeCodeByte(religion_addr_3, 0x50) -- push eax
    core.insertCode(religion_addr_3+1, 51, assembled_code)
    core.writeCodeBytes(religion_addr_3+52, {
      0x8B, 0xF0, -- mov esi, eax
      0x58        -- pop eax
    })
  end
  if church_bonus ~= nil then
    core.writeCodeByte(religion_addr_1 + 64, church_bonus)
    core.writeCodeByte(religion_addr_2 + 448, church_bonus)
    core.writeCodeByte(religion_addr_3 + 66, church_bonus)
  end
  if cathedral_bonus ~= nil then
    core.writeCodeByte(religion_addr_1 + 76, cathedral_bonus)
    core.writeCodeByte(religion_addr_2 + 463, cathedral_bonus)
    core.writeCodeByte(religion_addr_3 + 78, cathedral_bonus)
  end
end

local function edit_beer(beer)
  local beer_thresholds = beer["thresholds"]
  local beer_bonuses = beer["bonuses"]
  local beer_coverage = beer["coverage_per_inn"]
  local beer_flagons = beer["flagons_per_beer"]
  local beer_multipliers = beer["multipliers"]
  local beer_flagon_cap = beer["flagon_cap"]
  if beer_thresholds == nil then
    beer_thresholds = {25, 50, 75, 100}
  else
    core.writeCodeByte(beer_addr_1 + 2, beer_thresholds[1])
    core.writeCodeByte(beer_addr_1 + 11, beer_thresholds[2])
    core.writeCodeByte(beer_addr_1 + 23, beer_thresholds[3])
    core.writeCodeByte(beer_addr_1 + 37, beer_thresholds[4])

    -- next level at: %## informative texts
    core.writeCodeByte(beer_addr_1 + 95+2, beer_thresholds[1])
    core.writeCodeInteger(beer_addr_1 + 95+6, beer_thresholds[1])

    core.writeCodeByte(beer_addr_1 + 95+14, beer_thresholds[2])
    core.writeCodeInteger(beer_addr_1 + 95+18, beer_thresholds[2])

    core.writeCodeByte(beer_addr_1 + 95+26, beer_thresholds[3])
    core.writeCodeInteger(beer_addr_1 + 95+30, beer_thresholds[3])

    core.writeCodeByte(beer_addr_1 + 95+38, beer_thresholds[4])
    core.writeCodeInteger(beer_addr_1 + 95+46, beer_thresholds[4])

    core.writeCodeByte(beer_addr_2 + 2 , beer_thresholds[1])
    core.writeCodeByte(beer_addr_2 + 11 , beer_thresholds[2])
    core.writeCodeByte(beer_addr_2 + 23 , beer_thresholds[3])
    core.writeCodeByte(beer_addr_2 + 37 , beer_thresholds[4])

    core.writeCodeByte(beer_addr_3 + 2, beer_thresholds[1])
    core.writeCodeByte(beer_addr_3 + 18, beer_thresholds[2])
    core.writeCodeByte(beer_addr_3 + 30, beer_thresholds[3])
    core.writeCodeByte(beer_addr_3 + 44, beer_thresholds[4])
  end
  if beer_bonuses ~= nil then
    core.writeCodeByte(beer_addr_1 + 15, beer_bonuses[1])
    core.writeCodeByte(beer_addr_1 + 27, beer_bonuses[2])
    core.writeCodeByte(beer_addr_1 + 46, beer_bonuses[3]-beer_bonuses[4])
    core.writeCodeByte(beer_addr_1 + 48, beer_bonuses[4])

    core.writeCodeByte(beer_addr_2 + 15 , beer_bonuses[1])
    core.writeCodeByte(beer_addr_2 + 27 , beer_bonuses[2])
    core.writeCodeByte(beer_addr_2 + 46 , beer_bonuses[3]-beer_bonuses[4])
    core.writeCodeByte(beer_addr_2 + 49 , beer_bonuses[4])

    core.writeCodeByte(beer_addr_3 + 22, beer_bonuses[1])
    core.writeCodeByte(beer_addr_3 + 34, beer_bonuses[2])
    core.writeCodeByte(beer_addr_3 + 53, beer_bonuses[3]-beer_bonuses[4])
    core.writeCodeByte(beer_addr_3 + 56, beer_bonuses[4])
  end
  if beer_coverage ~= nil then
    core.writeCodeInteger(beer_coverage_addr+19, beer_coverage*100)
  end
  if beer_flagons ~= nil then
    core.writeCodeSmallInteger(flagon_mul_addr+13, beer_flagons)
      core.writeCodeBytes(flagon_inn_display_addr+7, core.compile({
        0x31, 0xD2, -- xor edx, edx
        0x8B, 0xC1, -- mov eax, ecx
        0xB9, core.itob(beer_flagons), -- mov eax, val
        0xF7, 0xF1, -- div ecx
        0x50,   -- push eax
        0x90, 0x90, 0x90, 0x90, 0x90, 0x90
      }, flagon_inn_display_addr+7))
  end
  if beer_multipliers ~= nil then
    local assembled_code = core.assemble(scaling_code,{
      threshold_1 = beer_thresholds[1],
      threshold_2 = beer_thresholds[2],
      threshold_3 = beer_thresholds[3],
      threshold_4 = beer_thresholds[4],
      multiplier_1 = beer_multipliers[1],
      multiplier_2 = beer_multipliers[2],
      multiplier_3 = beer_multipliers[3],
      multiplier_4 = beer_multipliers[4]
    },0)
    assembled_code["n"] = nil
    -- beer_addr_1 (52 bytes) info: esi target: eax
    core.writeCodeBytes(beer_addr_1, {
      0x56, -- push esi
      0x8B, 0xC6 -- mov eax esi
    })
    core.insertCode(beer_addr_1+3, 48, assembled_code)
    core.writeCodeBytes(beer_addr_1+51, {
      0x5E  -- pop esi
    })
    -- beer_addr_2 (55 bytes) info: eax target: esi
    core.writeCodeBytes(beer_addr_2, {
      0x50 -- push eax
    })
    core.insertCode(beer_addr_2+1, 51, assembled_code)
    core.writeCodeBytes(beer_addr_2+52, {
      0x8B, 0xF0, -- mov esi eax
      0x58 -- pop eax
    })
    -- beer_addr_3 (62 bytes) info: eax target: eax
    core.insertCode(beer_addr_3, 62, assembled_code)
  end
  if beer_flagon_cap ~= nil then
    if extreme_only_feature_check("Beer flagon cap editing is only available for SHC Extreme!") then
      core.writeCodeSmallInteger(0x400000 + 0x1418A0, beer_flagon_cap)
    end
  end
end

local function edit_food(food)
  local ration_bonuses = food["ration_bonuses"]
  local variety_bonuses = food["variety_bonuses"]
  local food_value = food["food_value"]
  if ration_bonuses ~= nil then
      core.writeCodeInteger(food_addr_1 + 1, ration_bonuses[1])
      core.writeCodeInteger(food_addr_1 + 70, ration_bonuses[1])
      core.writeCodeInteger(food_addr_1 + 61, ration_bonuses[2])
      core.writeCodeByte(food_addr_1 + 44, ration_bonuses[3]-3)
      core.writeCodeInteger(food_addr_1 + 31, ration_bonuses[4])

      core.writeCodeInteger(food_addr_2 + 1, ration_bonuses[1])
      core.writeCodeInteger(food_addr_2 + 57, ration_bonuses[1])
      core.writeCodeByte(food_addr_2 + 51, ration_bonuses[2]-1)
      core.writeCodeByte(food_addr_2 + 32, ration_bonuses[3]-3)
      core.writeCodeInteger(food_addr_2 + 19, ration_bonuses[4])

      core.writeCodeInteger(food_addr_3 + 1, ration_bonuses[1])
      core.writeCodeInteger(food_addr_3 + 19, ration_bonuses[1])
      core.writeCodeByte(food_addr_3 + 32, ration_bonuses[2]-1)
      core.writeCodeInteger(food_addr_3 + 60, ration_bonuses[3])
      core.writeCodeInteger(food_addr_3 + 50, ration_bonuses[4])
  end
  if variety_bonuses ~= nil then
    core.writeCodeByte(food_addr_1 + 466, variety_bonuses[1]-2)
    core.writeCodeByte(food_addr_1 + 476, variety_bonuses[2]-3)
    core.writeCodeInteger(food_addr_1 + 485, variety_bonuses[3])

    core.writeCodeByte(food_addr_2 + 89, variety_bonuses[1])
    core.writeCodeByte(food_addr_2 + 99, variety_bonuses[2])
    core.writeCodeByte(food_addr_2 + 109, variety_bonuses[3])

    core.writeCodeByte(food_addr_3 + 84, variety_bonuses[1])
    core.writeCodeByte(food_addr_3 + 94, variety_bonuses[2])
    core.writeCodeByte(food_addr_3 + 104, variety_bonuses[3])
  end
  if food_value ~= nil then
    core.writeCodeInteger(food_point_addr, food_value)
    core.writeCodeInteger(food_point_addr+242, food_value)
  end
end

local function edit_fear_factor(fear_factor)
  local popularity_per_good_level = fear_factor["popularity_per_good_level"]
  local popularity_per_bad_level = fear_factor["popularity_per_bad_level"]
  local popularity_table = fear_factor["popularity_table"]
  local productivity = fear_factor["productivity"]
  local coverage = fear_factor["coverage"]
  local combat_bonus = fear_factor["combat_bonus"]
  local resting_factor = fear_factor["resting_factor"]

  if popularity_table ~= nil then
    local pop_table_addr = core.allocate(11*4)

    for idx, pop_val in ipairs(popularity_table) do
      core.writeCodeInteger(pop_table_addr+4*(idx-1), pop_val)
    end

    core.insertCode(ff_addr_1+6, 22, core.assemble([[
      mov eax, [eax*4 + table_addr]
    ]], {
      table_addr=pop_table_addr+20
    }, 0))

    core.insertCode(ff_addr_2+6, 26, core.assemble([[
      mov eax, [eax*4 + table_addr]
      mov esi, eax
    ]], {
      table_addr=pop_table_addr+20
    }, 0))

    core.insertCode(ff_addr_3+7, 36, core.assemble([[
      mov eax, [eax*4 + table_addr]
      mov [esp+0x1C], eax
    ]], {
      table_addr=pop_table_addr+20
    }, 0))

  else
    if popularity_per_good_level ~= nil then
      core.writeCodeByte(ff_addr_1 + 13, popularity_per_good_level)
      core.writeCodeByte(ff_addr_2 + 13, popularity_per_good_level)
      core.writeCodeByte(ff_addr_3 + 14, popularity_per_good_level)
    end
    if popularity_per_bad_level ~= nil then
      core.writeCodeByte(ff_addr_1 + 23, popularity_per_bad_level)
      core.writeCodeByte(ff_addr_2 + 25, popularity_per_bad_level)
      core.writeCodeByte(ff_addr_3 + 28, popularity_per_bad_level)
    end
  end
  if productivity ~= nil then
    core.writeCodeInteger(productivity_addr + 2, productivity[1])
    core.writeCodeInteger(productivity_addr + 15, productivity[2])
    core.writeCodeInteger(productivity_addr + 28, productivity[3])
    core.writeCodeInteger(productivity_addr + 41, productivity[4])
    core.writeCodeInteger(productivity_addr + 54, productivity[5])
    core.writeCodeInteger(productivity_addr + 66, productivity[6])
    core.writeCodeInteger(productivity_addr + 79, productivity[7])
    core.writeCodeInteger(productivity_addr + 92, productivity[8])
    core.writeCodeInteger(productivity_addr + 105, productivity[9])
    core.writeCodeByte(productivity_addr + 124, productivity[10]-productivity[11])
    core.writeCodeByte(productivity_addr + 127, productivity[11])
  end
  if coverage ~= nil then
    local custom_coverage_instructions = {
      0x85, 0xC9,  -- test ecx, ecx
      0x74, 0x01,  -- jn by one
      0x49,  -- dec ecx
      0xC1, 0xF9, coverage,  -- sar ecx, coverage_value
      0x41  -- inc ecx
    }
    core.insertCode(ff_coverage_addr, 6, custom_coverage_instructions)
  end
  if combat_bonus ~= nil then
    local damage_table_addr = core.allocate(11)
    local damage_table_visual_addr = core.allocate(11*4)

    local custom_combat_instructions = {
      0x8A, 0x88, core.itob(damage_table_addr+5),
      0x0F, 0xAF, 0x4C, 0x24, 0x04,             -- imul ecx,[esp+04]
      core.jmpTo(combat_bonus_memory_addr+11)   -- jmp 0053162B
    }

    core.writeCode(damage_table_addr, combat_bonus, true)
    for idx, multiplier in ipairs(combat_bonus) do
        core.writeInteger(damage_table_visual_addr+4*(idx-1), multiplier-100)
    end

    -- positive_troop_combat_bonus_visual_addr  -- target is ecx, src is eax
    core.writeCodeBytes(positive_troop_combat_bonus_visual_addr+6, {0x90, 0x90, 0x90})  -- nop out original eax*5 -> ecx
    -- negative_troop_combat_bonus_visual_addr  -- target is ecx, src is eax
    core.writeCodeBytes(negative_troop_combat_bonus_visual_addr+6, {0x90, 0x90, 0x90})  -- nop out original eax*5 -> ecx
    
    local visual_code_positive = core.assemble("mov ecx, [eax*4 + tcb_table_addr]", {tcb_table_addr=damage_table_visual_addr+ 20}, 0)
    local visual_code_negative = core.assemble("mov ecx, [eax*4 + tcb_table_addr]", {tcb_table_addr=damage_table_visual_addr+ 20}, 0)

    core.insertCode(positive_troop_combat_bonus_visual_addr, 6, visual_code_positive, positive_troop_combat_bonus_visual_addr+9, "before")
    core.insertCode(negative_troop_combat_bonus_visual_addr, 6, visual_code_negative, negative_troop_combat_bonus_visual_addr+9, "before")

    local custom_combat_addr = core.allocateCode(core.calculateCodeSize(custom_combat_instructions))

    local combat_jumpout_instructions = {
      0x31, 0xC9,                   -- xor ecx, ecx
      core.jmpTo(custom_combat_addr),
      0x90, 0x90, 0x90, 0x90        -- nop nop nop nop
    }

    core.writeCode(custom_combat_addr, custom_combat_instructions, true)
    core.writeCode(combat_bonus_memory_addr, combat_jumpout_instructions, true)
  end
  if resting_factor ~= nil then
    core.writeCodeByte(resting_factor_addr, resting_factor)
  end
end

local function edit_taxation(taxation)
  local tax_table = taxation["gold"]
  local pop_table = taxation["popularity"]
  local adv_multipliers = taxation["advantage_multiplier"]
  local neutral_level = 3
  if tax_table ~= nil then
    for idx, tax_val in ipairs(tax_table) do
      core.writeCodeSmallInteger(tax_table_addr+2*(idx-1), math.floor(tax_val*100))
      if math.floor(tax_val*100) == 0 then
        neutral_level = idx-1
      end
    end
  end
  core.writeCodeByte(neutral_level_addr_1 + 2, neutral_level)
  core.writeCodeByte(neutral_level_addr_2, neutral_level)
  core.writeCodeByte(neutral_level_addr_3 + 2, neutral_level)
  core.writeCodeByte(neutral_level_addr_4 + 2, neutral_level)
  if pop_table ~= nil then
    local pop_table_addr = keep_menu_addr + 31
    core.writeCodeBytes(keep_menu_addr, core.compile({  -- keep menu
      0x83, 0xF8, neutral_level,
      0x7D, 0x09,                          -- jnl 0043B0AB
      0x83, 0x7C, 0x24, 0x10, 0x00,        -- cmp dword ptr [esp+10],00 { 0 }
      0x7F, 0x02,                          -- jle 0043B0AB
      0xB0, neutral_level,                 -- mov al,03 { 3 }
      0xC1, 0xE0, 0x02,                    -- shl eax,02 { 2 }
      0x8B, 0x80, core.itob(pop_table_addr),  -- mov eax,[eax+0043B0BC]
      0xE9, 0x84, 0x00, 0x00, 0x00,        -- jmp 0043B13D
      0x90,                                -- nop
      0x90,                                -- nop
      0x90                                 -- nop
    }, keep_menu_addr))
    for index, value in ipairs(pop_table) do
      core.writeCodeInteger(pop_table_addr + 4*(index-1), value)
    end
    -- 75 bytes are free in function

    core.writeCodeBytes(pop_report_addr + 6, core.compile({  -- pop report
      neutral_level,
      0x7D, 0x0E,
      0x83, 0x7C, 0x24, 0x18, 0x00,
      0x7F, 0x07,
      0xB8, neutral_level, 0x00, 0x00, 0x00,  -- mov eax,00000003
      0xEB, 0x06,                             -- jmp 0043EBDB
      0x8B, 0x80, core.itob(tax_popularity_offset),     -- mov eax,[eax+011F0BC0]
      0xC1, 0xE0, 0x02,                       -- shl eax,02
      0x8B, 0xB0, core.itob(pop_table_addr),     -- mov esi,[eax+0043B0BC]
      0xEB, 0x76                              -- jmp 0043EC5C
    }, pop_report_addr + 6))
    -- 118 bytes are free in function

    core.writeCodeBytes(actual_effect_addr + 2, core.compile({  -- actual effect
      neutral_level,
      0x7D, 0x06,
      0x85, 0xED,
      0x7F, 0x02,
      0xB0, neutral_level,
      0xC1, 0xE0, 0x02,
      0x8B, 0x80, core.itob(pop_table_addr),
      0xE9, 0x80, 0x00, 0x00, 0x00
    }, actual_effect_addr + 2))
    -- 128 bytes are free in function

  end

  if adv_multipliers ~= nil then
    local human_big_ai_medium = adv_multipliers["human_big_ai_medium"]
    local ai_big = adv_multipliers["ai_big"]
    if human_big_ai_medium ~= nil then
      core.writeCodeInteger(multipliers_addr_base + 46, human_big_ai_medium)
    end 
    if ai_big ~= nil then
      core.writeCodeInteger(multipliers_addr_base + 2, ai_big)
    end
  end

end

local function edit_ranges(ranges)
  local archer_range = ranges["archer_range"]
  local xbow_range = ranges["xbow_range"]
  local arabbow_range = ranges["arabbow_range"]
  local slinger_range = ranges["slinger_range"]
  local horse_archer_range = ranges["horse_archer_range"]
  local firethrower_range = ranges["firethrower_range"]
  local catapult_range = ranges["catapult_range"]
  local treb_range = ranges["treb_range"]
  local fbal_range = ranges["fbal_range"]
  local towerbal_range = ranges["towerbal_range"]
  local mangonel_range = ranges["mangonel_range"]

  -- load default values if not specified
  if archer_range == nil then archer_range = 54 end
  if xbow_range == nil then xbow_range = 54 end
  if arabbow_range == nil then arabbow_range = 54 end
  if slinger_range == nil then slinger_range = 22 end
  if horse_archer_range == nil then horse_archer_range = 54 end
  if firethrower_range == nil then firethrower_range = 11 end
  if catapult_range == nil then catapult_range = 75 end
  if treb_range == nil then treb_range = 85 end
  if fbal_range == nil then fbal_range = 54 end
  if towerbal_range == nil then towerbal_range = 85 end
  if mangonel_range == nil then mangonel_range = 70 end

  local mapping_1 ={archer_range=archer_range, xbow_range=xbow_range, arabbow_range=arabbow_range, horse_archer_range=horse_archer_range, fbal_range=fbal_range}
  local mapping_2 ={treb_range=treb_range, towerbal_range=towerbal_range}

  local code_1 = core.assemble(templates.range_split_asm1, {archer_range=archer_range, arabbow_range=arabbow_range, horse_archer_range=horse_archer_range}, 0)
  local code_2 = core.assemble(templates.range_split_asm2, mapping_1, 0)
  local code_3 = core.assemble(templates.range_split_asm3, mapping_1, 0)
  local code_4 = core.assemble(templates.range_split_asm4, {archer_range=archer_range, xbow_range=xbow_range, arabbow_range=arabbow_range, horse_archer_range=horse_archer_range}, 0)
  local code_5 = core.assemble(templates.range_split_asm5, mapping_1, 0)
  local code_6 = core.assemble(templates.range_split_asm6, mapping_1, 0)
  local code_7 = core.assemble(templates.range_split_asm7, mapping_2, 0)
  local code_8 = core.assemble(templates.range_split_asm8, mapping_2, 0)
  local code_9 = core.assemble(templates.range_split_asm9, mapping_2, 0)
  local code_10 = core.assemble(templates.range_split_asm10, mapping_2, 0)
  local code_11 = core.assemble(templates.range_split_asm11, {catapult_range=catapult_range, treb_range=treb_range}, 0)
  local code_12 = core.assemble(templates.range_split_asm12, {firethrower_range=firethrower_range}, 0)

  -- base ranges
  core.writeCodeInteger(base_ranges_table_addr + 24, xbow_range) -- "Crossbowman base range.",
  core.writeCodeInteger(base_ranges_table_addr + 144, fbal_range) -- "Fireballista base range.",
  core.insertCode(range_split_addr1, 7, code_1)

  -- manual control
  core.insertCode(range_split_addr2, 5, code_2)
  core.insertCode(range_split_addr3, 5, code_3)
  core.insertCode(range_split_addr4, 5, code_4)
  core.insertCode(range_split_addr5, 5, code_5)
  core.insertCode(range_split_addr6, 5, code_6)

  -- Trebuchets and Tower Ballistas
  core.insertCode(range_split_addr7, 5, code_7)
  core.insertCode(range_split_addr8, 5, code_8)
  core.insertCode(range_split_addr9, 5, code_9)
  core.insertCode(range_split_addr10, 5, code_10)

  core.insertCode(range_split_addr11, 13, code_11)

  -- slinger range addresses
  core.writeCodeInteger(base_ranges_table_addr + 128, slinger_range) -- also +136 can be relevant
  -- core.writeCodeInteger(base_ranges_table_addr + 136, slinger_range)
  core.writeCodeInteger(range_split_addr2 + 11, slinger_range*slinger_range)
  core.writeCodeInteger(range_split_addr4 + 126, slinger_range*slinger_range)
  core.writeCodeInteger(range_split_addr3 + 11, slinger_range*slinger_range)
  core.writeCodeInteger(range_split_addr5 + 8, slinger_range*slinger_range)
  core.writeCodeInteger(range_split_addr6 + 8, slinger_range*slinger_range)

  -- firethrower
  core.insertCode(range_split_addr12, 5, code_12)  -- allowing for 4-byte sized ranges
  core.writeCodeInteger(base_ranges_table_addr + 132, firethrower_range) -- also +140 can be relevant
  -- core.writeCodeInteger(base_ranges_table_addr + 140, firethrower_range)
  core.writeCodeInteger(range_split_addr2 + 21, firethrower_range*firethrower_range)
  core.writeCodeInteger(range_split_addr4 + 164, firethrower_range*firethrower_range)
  core.writeCodeInteger(range_split_addr3 + 21, firethrower_range*firethrower_range)
  core.writeCodeInteger(range_split_addr5 + 15, firethrower_range*firethrower_range)
  core.writeCodeInteger(range_split_addr6 + 15, firethrower_range*firethrower_range)

  -- catapult
  core.writeCodeInteger(base_ranges_table_addr + 4, catapult_range)
  core.writeCodeInteger(range_split_addr2 + 31, catapult_range*catapult_range)  -- also linked to cow throwing range
  core.writeCodeInteger(range_split_addr4 + 189, catapult_range*catapult_range)
  core.writeCodeInteger(range_split_addr3 + 31, catapult_range*catapult_range)  -- also linked to cow throwing range
  core.writeCodeInteger(range_split_addr5 - 650, catapult_range*catapult_range)  -- maybe find a new base address?
  core.writeCodeInteger(range_split_addr5 - 264, catapult_range*catapult_range)  -- maybe find a new base address?
  core.writeCodeInteger(range_split_addr5 + 22, catapult_range*catapult_range)
  core.writeCodeInteger(range_split_addr6 + 22, catapult_range*catapult_range)

  -- mangonel
  core.writeCodeInteger(base_ranges_table_addr + 12, mangonel_range)
  core.writeCodeInteger(range_split_addr2 + 48, mangonel_range*mangonel_range)
  core.writeCodeInteger(range_split_addr4 + 209, mangonel_range*mangonel_range)
  core.writeCodeInteger(range_split_addr3 + 51, mangonel_range*mangonel_range)
  core.writeCodeInteger(range_split_addr5 - 636, mangonel_range*mangonel_range)  -- maybe find a new base address?
  core.writeCodeInteger(range_split_addr5 - 250, mangonel_range*mangonel_range)  -- maybe find a new base address?
  core.writeCodeInteger(range_split_addr9 + 8, mangonel_range*mangonel_range)
  core.writeCodeInteger(range_split_addr10 + 8, mangonel_range*mangonel_range)

  -- trebuchet
  core.writeCodeInteger(base_ranges_table_addr + 8, treb_range)
  core.writeCodeInteger(range_split_addr4 + 199, treb_range*treb_range)
  core.writeCodeInteger(range_split_addr5 - 643, treb_range*treb_range)  -- maybe find a new base address?
  core.writeCodeInteger(range_split_addr5 - 257, treb_range*treb_range)  -- maybe find a new base address?

  -- towerbal
  core.writeCodeInteger(base_ranges_table_addr + 76, towerbal_range)
  core.writeCodeInteger(range_split_addr4 + 232, towerbal_range*towerbal_range)

  -- firebal
  core.writeCodeInteger(range_split_addr4 + 271, fbal_range*fbal_range)

  -- scan ranges
  core.writeCodeSmallInteger(scan_range_addr_archer + 7, (archer_range-4)*8)
  core.writeCodeSmallInteger(scan_range_addr_archer + 52, (archer_range-4)*8)
  core.writeCodeSmallInteger(scan_range_addr_archer + 74, archer_range*8)

  core.writeCodeInteger(scan_range_addr_arabbow_1 + 3, (arabbow_range-4)*8)
  core.writeCodeSmallInteger(scan_range_addr_arabbow_1 + 87, arabbow_range*8)
  core.writeCodeInteger(scan_range_addr_arabbow_2 + 3, (arabbow_range-4)*8)

  core.writeCodeSmallInteger(scan_range_addr_horse_archer + 13, horse_archer_range*8)
  core.writeCodeSmallInteger(scan_range_addr_horse_archer + 230, horse_archer_range*8)
  core.writeCodeSmallInteger(scan_range_addr_horse_archer + 661, horse_archer_range*8)

  core.writeCodeSmallInteger(scan_range_addr_xbow + 10, (xbow_range-4)*8)
  core.writeCodeSmallInteger(scan_range_addr_xbow + 32, xbow_range*8)
  core.writeCodeSmallInteger(scan_range_addr_xbow_2 + 16, (xbow_range-4)*8)

  core.writeCodeSmallInteger(scan_range_addr_slinger_1 + 10, (slinger_range+5)*8)
  core.writeCodeSmallInteger(scan_range_addr_slinger_1 + 32, (slinger_range+5)*8)
  core.writeCodeInteger(scan_range_addr_slinger_2 + 4, slinger_range*slinger_range)
  core.writeCodeInteger(scan_range_addr_slinger_3 + 16, (slinger_range+5)*8)

  core.writeCodeSmallInteger(scan_range_addr_firethrower_1 + 10, (firethrower_range+5)*8)
  core.writeCodeSmallInteger(scan_range_addr_firethrower_1 + 32, (firethrower_range+5)*8)

  core.writeCodeSmallInteger(scan_range_addr_fbal_1 + 16, towerbal_range*8) -- for some reason tied to towerbal range
  core.writeCodeSmallInteger(scan_range_addr_fbal_1 + 216, fbal_range*8)
  core.writeCodeInteger(scan_range_addr_fbal_2 + 7, fbal_range*fbal_range)
  core.writeCodeByte(scan_range_addr_fbal_1 + 73, fbal_range-2) -- ai range
  core.writeCodeByte(range_split_addr11-6, fbal_range-2) -- also ai range

  core.writeCodeSmallInteger(scan_range_addr_mango + 13, towerbal_range*8) -- for some reason tied to towerbal range
  core.writeCodeSmallInteger(scan_range_addr_mango + 237, towerbal_range*8) -- for some reason tied to towerbal range

  core.writeCodeSmallInteger(scan_range_addr_towerbal_1 + 8, towerbal_range*8)
  core.writeCodeSmallInteger(scan_range_addr_towerbal_2 + 8, towerbal_range*8)
end

local function edit_projectiles(projectiles)
    local keyword_offset_map = {
     arrow = 0,
     catapult_rock = 4,
     trebuchet_rock = 8,
     mangonel_pebble = 12,
     crossbow_bolt = 24,
     towerbal_bolt = 76,
     cow = 88,
     slinger_stone = 128,
     firethrower_grenade = 132,
     firebal_bolt = 144
    }
    for key, offset in pairs(keyword_offset_map) do
      local projectile = projectiles[key]
      if projectile ~= nil then
        local velocity = projectile["velocity"]
        local arch_type = projectile["arch_type"]
        if velocity ~= nil then
          core.writeCodeInteger(proj_velocity_table_addr+offset, velocity)
        end
        if arch_type ~= nil then
          core.writeCodeInteger(proj_archtype_table_addr+offset, arch_type)
        end

      end
    end
end

local function edit_leather_per_cow(leather_per_cow)
  core.writeCodeByte(leather_per_cow_address+2, leather_per_cow)
  core.writeCodeByte(leather_per_cow_address+4, leather_per_cow)
end

local function apply_rebalance_function(function_name, config_section)
  if config_section ~= nil then
    function_name(config_section)
  end
end

namespace.apply_rebalance = function(config)
  apply_rebalance_function(edit_buildings, config["buildings"])
  apply_rebalance_function(edit_siege, config["siege"])  -- siege changes need to come before units, due to projectile damages on units
  apply_rebalance_function(edit_castle, config["castle"])  -- castle changes need to come before units, due to fire damages on units
  apply_rebalance_function(edit_units, config["units"])
  apply_rebalance_function(edit_resources, config["resources"])
  apply_rebalance_function(edit_population, config["population"])
  apply_rebalance_function(edit_religion, config["religion"])
  apply_rebalance_function(edit_beer, config["beer"])
  apply_rebalance_function(edit_food, config["food"])
  apply_rebalance_function(edit_fear_factor, config["fear_factor"])
  apply_rebalance_function(edit_taxation, config["taxation"])
  apply_rebalance_function(edit_ranges, config["ranges"])
  apply_rebalance_function(edit_projectiles, config["projectiles"])
  apply_rebalance_function(edit_leather_per_cow, config["leather_per_cow"])

  if config["population_gathering_rate"] then
    log(ERROR, "population_gathering_rate is removed, use population section in the config instead.")
  end

  if config["enable_iron_double_pickup"] then
    core.writeCodeBytes(iron_wait_addr, core.compile({
      0x83, 0xB8, core.itob(building_array_base_addr + 0x138), 0x01,
      0x0F, 0x9E, 0xC1,
      0x90
    }, iron_wait_addr)) 
    core.writeCodeByte(iron_subtract_addr, -2)
  end

  if config["disable_rally_runners"] then
    core.writeCodeBytes(arabbow_rally_running_addr, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90})
    core.writeCodeBytes(slinger_rally_running_addr, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90})
    core.writeCodeBytes(assassin_rally_running_addr, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90})
    core.writeCodeBytes(firethrower_rally_running_addr, {0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90})
  end

  if config["enable_spearmen_conditional_run"] then
    if extreme_only_feature_check("enable_spearmen_conditional_run is only available for SHC Extreme!") then
      enable_spearmen_conditional_run()
    end
  end

  if config["reduce_height_advantage"] then
    if extreme_only_feature_check("reduce_height_advantage is only available for SHC Extreme!") then
      reduce_height_advantage()
    end
  end

  if config["increase_enemy_check_frequency"] ~= nil then
    if extreme_only_feature_check("increase_enemy_check_frequency is only available for SHC Extreme!") then
      increase_enemy_check_frequency()
    end
  end

  if config["increase_minimap_unit_size"] ~= nil then
    if extreme_only_feature_check("increase_minimap_unit_size is only available for SHC Extreme!") then
      increase_minimap_unit_size()
    end
  end

end

namespace.enable = function(self, config)
  local file = io.open(config["balance_config_file_selector"], "rb")
---@diagnostic disable-next-line: need-check-nil
  local spec = file:read("*all")
---@diagnostic disable-next-line: undefined-global
  local rebalance_cfg = yaml.parse(spec)
  enable_rebalance_features()
  namespace.apply_rebalance(rebalance_cfg)
end

namespace.disable = function(self, config)
end

return namespace
