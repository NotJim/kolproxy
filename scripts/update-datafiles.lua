local faxbot_most_popular = {
	["Blooper"] = true,
	["dirty thieving brigand"] = true,
	["ghost"] = true,
	["Knob Goblin Elite Guard Captain"] = true,
	["lobsterfrogman"] = true,
	["sleepy mariachi"] = true,
	["smut orc pervert"] = true,
}

local faxbot_category_order = {
	"Most Popular",
	"Sorceress's Quest",
	"Misc Ascension",
	"Misc Aftercore",
	"Bounty Targets",
	"Featured Butts",
}

local blacklist = {
	["Kung Fu Fighting"] = true,
	["Fast as Lightning"] = true,
	["Expert Timing"] = true,
	["Gaze of the Trickster God"] = true,
	["buff: Overconfident"] = true,
	["Iron Palms"] = true,
	["Missing Kidney"] = true,

	["A Little Bit Evil (Seal Clubber)"] = true,
	["A Little Bit Evil (Turtle Tamer)"] = true,
	["A Little Bit Evil (Pastamancer)"] = true,
	["A Little Bit Evil (Sauceror)"] = true,
	["A Little Bit Evil (Disco Bandit)"] = true,
	["A Little Bit Evil (Accordion Thief)"] = true,
	["Buy! Sell! Buy! Sell!"] = true,

	[""] = true,
	["especially homoerotic frat-paddle"] = true,

	["bonuses: jalape&ntilde;o slices"] = true,
	["bonuses: frosty halo"] = true,

	["recast buff warning: Overconfident"] = true,

	["Dungeons of Doom"] = true,
}

local processed_datafiles = {}

local softwarn = function()
	-- Errors that are just too frequent to spam warnings for
end

local function hardwarn(...)
	print("WARNING: downloaded data files inconsistent,", ...)
end

function string.contains(a, b) return a:find(b, 1, true) end

local function split_line_on(what, l)
	local tbl = {}
	local idx = 0
	while idx do
		local nextidx = l:find(what, idx + 1)
		if nextidx then
			table.insert(tbl, l:sub(idx + 1, nextidx - 1))
		else
			table.insert(tbl, l:sub(idx + 1))
		end
		idx = nextidx
	end
	return tbl
end

local function split_tabbed_line(l)
	return split_line_on("	", l:gsub("\r$", ""))
end

local function split_commaseparated(l)
	return split_line_on(",", l:gsub(", ", ","))
end

local function parse_mafia_bonuslist(bonuslist)
	local checks = {
		["Initiative"] = "Combat Initiative",
		["Item Drop"] = "Item Drops from Monsters",
		["Meat Drop"] = "Meat from Monsters",
		["Monster Level"] = "Monster Level",
		["Combat Rate"] = "Monsters will be more attracted to you",

		["Muscle"] = "Muscle",
		["Mysticality"] = "Mysticality",
		["Moxie"] = "Moxie",
		["Hobo Power"] = "Hobo Power",
		["PvP Fights"] = "PvP fights per day", -- PvP fight(s) per day when equipped
		["Adventures"] = "Adventures per day", -- Adventure(s) per day when equipped.
		["Muscle Percent"] = "Muscle %", -- Muscle +15%
		["Mysticality Percent"] = "Mysticality %",
		["Moxie Percent"] = "Moxie %",

		["Damage Absorption"] = "Damage Absorption",
		["Damage Reduction"] = "Damage Reduction",

		["Cold Resistance"] = "Cold Resistance",
		["Hot Resistance"] = "Hot Resistance",
		["Sleaze Resistance"] = "Sleaze Resistance",
		["Spooky Resistance"] = "Spooky Resistance",
		["Stench Resistance"] = "Stench Resistance",
		["Slime Resistance"] = "Slime Resistance",

		["Cold Spell Damage"] = "Damage to Cold Spells",
		["Hot Spell Damage"] = "Damage to Hot Spells",
		["Sleaze Spell Damage"] = "Damage to Sleaze Spells",
		["Spooky Spell Damage"] = "Damage to Spooky Spells",
		["Stench Spell Damage"] = "Damage to Stench Spells",

		["Cold Damage"] = "Cold Damage",
		["Hot Damage"] = "Hot Damage",
		["Sleaze Damage"] = "Sleaze Damage",
		["Spooky Damage"] = "Spooky Damage",
		["Stench Damage"] = "Stench Damage",

		["Spell Damage"] = "Spell Damage",
		["Weapon Damage"] = "Weapon Damage",

		["Maximum HP"] = "Maximum HP",
		["Maximum MP"] = "Maximum MP",

		["HP Regen Min"] = "Regenerate minimum HP per adventure", -- Regenerate 10-15 HP and MP per adventure
		["HP Regen Max"] = "Regenerate maximum HP per adventure",
		["MP Regen Min"] = "Regenerate minimum MP per adventure",
		["MP Regen Max"] = "Regenerate maximum MP per adventure",

		["Food Drop"] = "Food Drops from Monsters",
		["Booze Drop"] = "Booze Drops from Monsters",

		-- TODO: add more modifiers
	}

	local bonuses = {}
	for x, y in (", "..bonuslist):gmatch(", ([^,:]+): ([^,]+)") do
		-- TODO: Do more complicated parsing for expressions
		if checks[x] then
			bonuses[checks[x]] = tonumber(y)
		end
	end

	return bonuses
end

function parse_buffs()
	local buffs = {}
	buffs["A Little Bit Evil"] = {}
	buffs["Buy!  Sell!  Buy!  Sell!"] = {}
	buffs["Everything Looks Yellow"] = {}
	buffs["Everything Looks Red"] = {}
	buffs["Everything Looks Blue"] = {}

	local section = nil
	for l in io.lines("cache/files/modifiers.txt") do
		section = l:match([[^# (.*) section of modifiers.txt]]) or section
		local name, bonuslist = l:match([[^([^	]+)	(.+)$]])
		local name2 = l:match([[^# ([^	:]+)]])
		if section == "Status Effects" and name and bonuslist and not blacklist[name] and not blacklist["buff: " .. name] and not name2 then
			buffs[name] = { bonuses = parse_mafia_bonuslist(bonuslist) }
		elseif section == "Status Effects" and name2 and not blacklist[name2] and not buffs[name2] then
			buffs[name2] = {}
		end
	end
	return buffs
end

function verify_buffs(data)
	if data["Peppermint Twisted"].bonuses["Combat Initiative"] == 40 and data["Peppermint Twisted"].bonuses["Monster Level"] == 10 and data["Peeled Eyeballs"].bonuses["Meat from Monsters"] == -20 then
		return data
	end
end

function parse_outfits()
	local outfits = {}
	for l in io.lines("cache/files/outfits.txt") do
		local name, itemlist = l:match([[^[0-9]*	([^	]+)	(.+)$]])
		if name and itemlist then
			local items = {}
			for x in (", "..itemlist):gmatch(", ([^,]+)") do
				table.insert(items, x)  
			end
			table.sort(items)
			outfits[name] = { items = items, bonuses = {} }
		end
	end
	for l in io.lines("cache/files/modifiers.txt") do
		local name, bonuslist = l:match([[^([^	]+)	(.+)$]])
		if name and bonuslist and outfits[name] then
			outfits[name].bonuses = parse_mafia_bonuslist(bonuslist)
		end
	end
	return outfits
end

function verify_outfits(data)
	for xi, x in pairs(data) do
		for _, y in ipairs(x.items) do
			if not processed_datafiles["items"][y] then
				hardwarn("outfit:item does not exist", y)
				data[xi] = nil
			end
		end
	end

	if data["Antique Arms and Armor"].bonuses["Combat Initiative"] == -10 and data["Pork Elf Prizes"].bonuses["Item Drops from Monsters"] == 10 and data["Pork Elf Prizes"].items[2] == "pig-iron helm" then
		return data
	end
end

function parse_skills()
	local skills = {}
	for l in io.lines("cache/files/classskills.txt") do
		local tbl = split_tabbed_line(l)
		local skillid, name, mpcost = tonumber(tbl[1]), tbl[2], tonumber(tbl[4])
		if skillid and name and mpcost then
			skills[name] = { skillid = skillid, mpcost = mpcost }
		end
	end
	return skills
end

function verify_skills(data)
	if data["Summon Sugar Sheets"].skillid == 8002 and data["Summon Sugar Sheets"].mpcost == 2 then
		if data["Leash of Linguini"].skillid == 3010 and data["Leash of Linguini"].mpcost == 12 then
			return data
		end
	end
end

function parse_buff_recast_skills(skills)
	local buff_recast_skills = {}
	for l in io.lines("cache/files/statuseffects.txt") do
		local tbl = split_tabbed_line(l)
		local buffname, usecmd = tbl[2], tbl[5]
		local castname = (usecmd or ""):match("^cast 1 ([^|]+)")
		if buffname and castname and not blacklist[buffname] then
			buff_recast_skills[buffname] = castname
		end
	end
	return buff_recast_skills
end

function verify_buff_recast_skills(data)
	for x, y in pairs(data) do
		if not processed_datafiles["buffs"][x] and not blacklist["recast buff warning: "..x] then
			hardwarn("unknown recast buff", x)
			data[x] = nil
		end
		if not processed_datafiles["skills"][y] then
			hardwarn("unknown recast skill", y)
			data[x] = nil
		end
	end

	if data["Zomg WTF"] == "Ag-grave-ation" and data["Ode to Booze"] == "The Ode to Booze" and data["Leash of Linguini"] == "Leash of Linguini" then
		return data
	end
end

function parse_items()
	local items = {}
	local lowercasemap = {}
	local allitemuses = {}
	local itemslots = { hat = "hat", shirt = "shirt", container = "container", weapon = "weapon", offhand = "offhand", pants = "pants", accessory = "accessory", familiar = "familiarequip" }
	for l in io.lines("cache/files/items.txt") do
		local tbl = split_tabbed_line(l)
		local itemid, name, picturestr, itemusestr, plural = tonumber(tbl[1]), tbl[2], tbl[4], tbl[5], tbl[8]
		local picture = (picturestr or ""):match("^(.-)%.gif$")
		if itemid and name and not blacklist[name] then
			items[name] = { id = itemid, picture = picture }
			lowercasemap[name:lower()] = name
			for _, u in ipairs(split_commaseparated(itemusestr or "")) do
				if itemslots[u] then
					items[name].equipment_slot = itemslots[u]
				end
			end
		end
	end

	function do_organ_line(l, field)
		local tbl = split_tabbed_line(l)
		local fakename, size, levelreq, advgainstr = tbl[1], tonumber(tbl[2]), tonumber(tbl[3]), tbl[5]
		if fakename and size and not blacklist[fakename] then
			local name = lowercasemap[fakename:lower()]
			if name then
				items[name][field] = size
				items[name].levelreq = levelreq
				if advgainstr then
					local advmin, advmax = advgainstr:match("^([0-9]+)%-([0-9]+)$")
					if advmin and advmax then
						items[name].advmin = tonumber(advmin)
						items[name].advmax = tonumber(advmax)
					else
						items[name].advmin = tonumber(advgainstr)
						items[name].advmax = tonumber(advgainstr)
					end
				end
			else
				softwarn("organ:item does not exist", fakename)
			end
		end
	end
	for l in io.lines("cache/files/fullness.txt") do
		do_organ_line(l, "fullness")
	end
	for l in io.lines("cache/files/inebriety.txt") do
		do_organ_line(l, "drunkenness")
	end
	for l in io.lines("cache/files/spleenhit.txt") do
		do_organ_line(l, "spleen")
	end

	for l in io.lines("cache/files/equipment.txt") do
		local tbl = split_tabbed_line(l)
		local name, power, req, weaptype = tbl[1], tonumber(tbl[2]), tbl[3], tbl[4]
		if name and req and not blacklist[name] then
			if items[name] then
				local reqtbl = {}
				reqtbl.muscle = tonumber(req:match("Mus: ([0-9]+)"))
				reqtbl.mysticality = tonumber(req:match("Mys: ([0-9]+)"))
				reqtbl.moxie = tonumber(req:match("Mox: ([0-9]+)"))
				if req ~= "none" and not next(reqtbl) then
					hardwarn("unknown equip requirement", req, "for", name)
				end
				-- Mafia data files frequently show no equipment requirements as e.g. "Mus: 0" instead of "none"
				for a, b in pairs(reqtbl) do
					if b == 0 then
						reqtbl[a] = nil
					end
				end
				items[name].equip_requirement = reqtbl
				items[name].power = power
				items[name].weapon_hands = tonumber((weaptype or ""):match("^([0-9]+)%-handed"))
			else
				hardwarn("equipment:item does not exist", name)
			end
		end
	end

	local section = nil
	local equip_sections = { Hats = true, Containers = true, Shirts = true, Weapons = true, ["Off-hand"] = true, Pants = true, Accessories = true, ["Familiar Items"] = true }
	for l in io.lines("cache/files/modifiers.txt") do
		section = l:match([[^# (.*) section of modifiers.txt]]) or section
		local name, bonuslist = l:match([[^([^	]+)	(.+)$]])
		local name2 = l:match([[^# ([^	:]+)]])
		if section and equip_sections[section] and name and bonuslist and not blacklist[name] and not name2 and not blacklist["bonuses: " .. name] then
			if items[name] then
				items[name].equip_bonuses = parse_mafia_bonuslist(bonuslist)
			else
				hardwarn("modifiers:item does not exist", name)
			end
		elseif section == "Everything Else" and name and bonuslist and bonuslist:contains("Effect:") then
			local effect = bonuslist:match([[Effect: "(.-)"]])
			if not effect then
				hardwarn("modifiers:useitem effect does not exist", name, effect)
			elseif items[name] then
				items[name].use_effect = effect
			elseif not name:match("^# ") then
				hardwarn("modifiers:useitem does not exist", name, effect)
			end
		end
	end

	for l in io.lines("cache/files/statuseffects.txt") do
		local n, i = l:match("[0-9]*	([^	]+)	.*use 1 (.+)")
		if n and i and items[i] then
			if not processed_datafiles["buffs"][n] then
				softwarn("statuseffects:buff does not exist", n)
			elseif not items[i].use_effect then
				softwarn("modifiers/statuseffects mismatch", i, n)
				items[i].use_effect = n
			end
		end
	end

	return items
end

function verify_items(data)
	if data["Orcish Frat House blueprints"] and data["Boris's Helm"] then
		if data["Hell ramen"].fullness == 6 and data["water purification pills"].drunkenness == 3 and data["beastly paste"].spleen == 4 then
			if data["leather chaps"].equip_requirement.moxie == 65 then
				if data["dried gelatinous cube"].id == 6256 then
					if data["flaming pink shirt"].equipment_slot == "shirt" then
						return data
					end
				end
			end
		end
	end
	local testitems = {}
	for _, x in ipairs { "Orcish Frat House blueprints", "Hell ramen", "water purification pills", "beastly paste", "leather chaps", "dried gelatinous cube", "flaming pink shirt" } do
		testitems[x] = data[x]
	end
	hardwarn("verify_items failure:", table_to_json(testitems))
end

local function parse_monster_stats(stats)
	if stats == "" then
		return {}
	end
	local statstbl = {}
	local i = 1
	if stats:match("^BOSS ") then
		statstbl.boss = true
		i = i + 5
	end
	stats = stats .. " "
	while i <= #stats do
		local ch = stats:byte(i)
		local name, value, pos
		if ch == 0x22 then -- quoted string
			name = "WatchOut"
			value, pos = stats:match('^"([^"]*)" ()', i)
		else
			name, value, pos = stats:match("^([^:]+): ([^ ]+) ()", i)
			if name and value then
				if tonumber(value) then
					value = tonumber(value)
				elseif value:match("^%[.*%]$") then
					value = "mafiaexpression:" .. value
				elseif name == "Meat" then
					local lo, hi = value:match("^([0-9]+)%-([0-9]+)$")
					lo, hi = tonumber(lo), tonumber(hi)
					if lo and hi then
						value = math.floor((lo + hi) / 2)
						if value * 2 ~= lo + hi then
							softwarn("bad monster meat value", value, lo, hi)
						end
					end
				end

				if name == "P" then
					name = "Phylum"
				elseif name == "E" or name == "ED" then
					name = "Element"
				end

				if name == "Init" and value == -10000 then
					value = 0
				end
			end
		end
		if not name or not value then
			print("ERROR: failed to parse monster stat", stats:sub(i))
			return statstbl
		end
		statstbl[name] = value
		i = pos
	end
	return statstbl
end

local prefixkeys = {
	p = "pickpocket only",
	n = "no pickpocket",
	b = "bounty",
	c = "conditional",
	f = "fixed",
}

local function parse_monster_items(items)
	if #items == 0 then return nil end
	itemtbl = {}
	for _, item in ipairs(items) do
		local name, prefix, rate =  item:match("^(.*) %(([pnbcf]*)(%d+)%)$")

		if not name then
			-- a few items are missing drop rates
			name = item
		end
		local nameitemid = tonumber(name:match("^%[([0-9]+)%]$"))
		if nameitemid then
			for n, d in pairs(processed_datafiles["items"]) do
				if d.id == nameitemid then
					name = n
				end
			end
		end

		local itementry = {
			Name = name,
		}
		rate = tonumber(rate)
		if rate and rate > 0 then
			itementry.Chance = rate
		end
		if prefix and prefix ~= "" then
			itementry[prefixkeys[prefix]] = true
			if prefix == "b" then
				itementry.Chance = 100
			end
		end
		table.insert(itemtbl, itementry)
	end
	return itemtbl
end

function parse_monsters()
	local monsters = {}
	for l in io.lines("cache/files/monsters.txt") do
		local tbl = split_tabbed_line(l)
		local name, stats = tbl[1], tbl[2]
		if not l:match("^#") and name and stats then
			--print("DEBUG parsing monster", name)
			table.remove(tbl, 1)
			table.remove(tbl, 1)
			local items = tbl
			monsters[name:lower()] = {
				Stats = parse_monster_stats(stats),
				Items = parse_monster_items(items),
			}
		end
	end
	return monsters
end

function verify_monsters(data)
	for xi, x in pairs(data) do
		for _, y in ipairs(x.Items or {}) do
			if not processed_datafiles["items"][y.Name] then
				hardwarn("monster:item does not exist", y.Name, "(from " .. tostring(xi) .. ")")
			end
		end
	end

	local cube_ok = false
	for _, x in ipairs(data["hellion"].Items) do
		if x.Name == "hellion cube" then
			cube_ok = true
		end
	end
	if data["hellion"].Stats.Element == "hot" and data["hellion"].Stats.Phylum == "demon" and data["hellion"].Stats.HP == 52 then
		if data["hank north, photojournalist"].Stats.HP == 180 then
			if data["beefy bodyguard bat"].Stats.Meat == 250 then
				return data
			end
		end
	end
end

function parse_hatrack()
	local hatrack = {}

	for l in io.lines("cache/files/modifiers.txt") do
		local name, bonuslist = l:match([[^([^	]+)	(.+)$]])
		if name and bonuslist and not blacklist[name] and processed_datafiles["items"][name] then
			hatrack[name] = bonuslist:match([[Familiar Effect: "(.-)"]])
		end
	end

	return hatrack
end

function verify_hatrack(data)
	if data["Cloaca-Cola fatigues"]:lower():contains("potato") and data["Cloaca-Cola fatigues"]:contains("7") then
		if data["asbestos helmet turtle"]:lower():contains("fairy") and data["asbestos helmet turtle"]:contains("20") then
			return data
		end
	end
end

function parse_recipes()
	local recipes = {}
	local function add_recipe(item, tbl)
		if not recipes[item] then
			recipes[item] = {}
		end
		table.insert(recipes[item], tbl)
	end
	for l in io.lines("cache/files/concoctions.txt") do
		local tbl = split_tabbed_line(l)
		if tbl[2] == "CLIPART" then
			add_recipe(tbl[1], { type = "cliparts", clips = { tonumber(tbl[3]), tonumber(tbl[4]), tonumber(tbl[5]) } })
		end
	end

	return recipes
end

function verify_recipes(data)
	local xray = data["potion of X-ray vision"][1]
	if xray.clips[1] == 4 and xray.clips[2] == 6 and xray.clips[3] == 8 then
		return data
	end
end

function parse_familiars()
	local familiars = {}
	for l in io.lines("cache/files/familiars.txt") do
		local tbl = split_tabbed_line(l)
		local famid, name, pic = tonumber(tbl[1]), tbl[2], tbl[3]
		if pic then
			pic = pic:gsub("%.gif$", "")
		end
		if famid and name then
			familiars[name] = { famid = famid, familiarpic = pic }
		end
	end
	return familiars
end

function verify_familiars(data)
	if data["Frumious Bandersnatch"].famid == 105 and data["Oily Woim"].famid == 168 then
		return data
	end
end

function parse_enthroned_familiars()
	local enthroned_familiars = {}
	local section = nil
	for l in io.lines("cache/files/modifiers.txt") do
		section = l:match([[^# (.*) section of modifiers.txt]]) or section
		local name, bonuslist = l:match([[^Throne:([^	]+)	(.+)$]])
		if section == "Enthroned familiars" and name and bonuslist then
			enthroned_familiars[name] = parse_mafia_bonuslist(bonuslist)
		end
	end
	return enthroned_familiars
end

function verify_enthroned_familiars(data)
	for x, _ in pairs(processed_datafiles["familiars"]) do
		if not data[x] then
			softwarn("missing enthroned familiar", x)
		end
	end
	for x, _ in pairs(data) do
		if not processed_datafiles["familiars"][x] then
			hardwarn("unknown enthroned familiar", x)
			data[x] = nil
		end
	end

	if data["Leprechaun"]["Meat from Monsters"] == 20 and data["Feral Kobold"]["Item Drops from Monsters"] == 15 then
		return data
	end
end

function xml_findelements(elem, name)
	local tbl = {}
	local function iter(e)
		if e.name == name then
			table.insert(tbl, e)
		else
			for _, c in ipairs(e.children) do
				iter(c)
			end
		end
	end
	iter(elem)
	return tbl
end

function parse_faxbot_monsters()
	local fobj = io.open("cache/files/faxbot.xml")
	local faxbot_datafile = fobj:read("*a")
	fobj:close()
	local faxbot_xml = simplexmldata_to_table(faxbot_datafile)

	local categories = {}
	local catsortorder = {}
	for x, y in ipairs(faxbot_category_order) do
		table.insert(catsortorder, { name = y, sortpriority = x })
		categories[y] = {}
	end

	for _, e in ipairs(xml_findelements(faxbot_xml, "monsterdata")) do
		local m = {}
		m.name = xml_findelements(e, "actual_name")[1].text
		m.description = xml_findelements(e, "name")[1].text

		local cmd = xml_findelements(e, "command")[1].text
		local cat = xml_findelements(e, "category")[1].text

		if not categories[cat] then
			categories[cat] = {}
			table.insert(catsortorder, { name = cat, sortpriority = 1000000 })
		end
		categories[cat][cmd] = m
		if faxbot_most_popular[m.name] then
			categories["Most Popular"][cmd] = m
		end
	end

	table.sort(catsortorder, function(a, b)
		if a.sortpriority ~= b.sortpriority then
			return a.sortpriority < b.sortpriority
		else
			return a.name < b.name
		end
	end)

	local order = {}
	for _, x in ipairs(catsortorder) do
		table.insert(order, x.name)
	end

	local faxbot_monsters = {
		categories = categories,
		order = order,
	}

	return faxbot_monsters
end

function verify_faxbot_monsters(data)
	if data.categories["Most Popular"]["blooper"].name == "Blooper" and data.categories["Sorceress's Quest"]["handsomeness"].name == "handsome mariachi" and data.order[1] == "Most Popular" then
		return data
	end
end

function parse_semirares()
	local semirares = {}
	for l in io.lines("cache/files/KoLmafia.java") do
		local sr = l:match([[{ *"([^"]+)", *EncounterTypes.SEMIRARE *}]])
		if sr then
			table.insert(semirares, sr)
		end
	end
	return semirares
end

function verify_semirares(data)
	local ok1, ok2 = false, false
	for _, x in ipairs(data) do
		if x == "All The Rave" then
			ok1 = true
		end
		if x == "It's a Gas Gas Gas" then
			ok2 = true
		end
	end
	if ok1 and ok2 then
		return data
	end
end

function parse_mallprices()
	local fobj = io.open("cache/files/mallprices.json")
	local mallprices_datafile = fobj:read("*a")
	fobj:close()
	return json_to_table(mallprices_datafile)
end

function verify_mallprices(data)
	if data["Mr. Accessory"]["buy 10"] >= 1000000 and data["Mr. Accessory"]["buy 10"] <= 100000000 and data["Mick's IcyVapoHotness Inhaler"]["buy 10"] >= 200 and data["Mick's IcyVapoHotness Inhaler"]["buy 10"] <= 200000 then
		return data
	end
end

-- TODO: Merge with items datafile, or at least don't have fullness/drunkenness/spleen in both?
function parse_consumables()
	local fobj = io.open("cache/files/consumable-advgain.json")
	local consumables_datafile = fobj:read("*a")
	fobj:close()
	return json_to_table(consumables_datafile)
end

function verify_consumables(data)
	if data["Hell ramen"].type == "food" and data["Hell ramen"].size[1] == 6 and data["Hell ramen"].advmin == 22 and data["Hell ramen"].advmax == 28 then
		if data["beastly paste"].type == "spleen" and data["beastly paste"].size[3] == 4 and data["beastly paste"].advmin == 5 and data["beastly paste"].advmax == 10 then
				return data
		end
	end
end

function parse_zones()
	local fobj = io.open("cache/files/zones.json")
	local zones_datafile = fobj:read("*a")
	fobj:close()
	zones_datafile = json_to_table(zones_datafile)

	local mafia_adventures = {}
	local mafia_adventures_inverse = {}
	for l in io.lines("cache/files/adventures.txt") do
		local tbl = split_tabbed_line(l)
		if tbl[2] and tbl[4] then
			local zoneid = tonumber(tbl[2]:match("adventure=([0-9]*)"))
			if zoneid then
				mafia_adventures[tbl[4]] = zoneid
				mafia_adventures_inverse[zoneid] = tbl[4]
			end
		end
	end

	local mafia_combats = {}
	local found_valid = false
	local mafia_zoneid_monsters = {}
	for l in io.lines("cache/files/combats.txt") do
		local tbl = split_tabbed_line(l)
		if mafia_adventures[tbl[1]] then
			local monsters = {}
			for xidx, x in ipairs(tbl) do
				if xidx >= 3 then
					local xprefix = x:match("^(.+): [0-9oe-]+$")
					table.insert(monsters, xprefix or x)
				end
			end
			--print("DEBUG zone", tbl[1], mafia_adventures[tbl[1]], table.concat(monsters, " + "))
			mafia_zoneid_monsters[mafia_adventures[tbl[1]]] = monsters
			found_valid = true
		elseif found_valid and tbl[1] and tbl[1] ~= "" and not l:match("^#") and tbl[2] ~= "0" then
			softwarn("unknown adventure zone", tbl[1])
		end
	end

	local zones_by_number = {}

	local zones_datafile_inverse = {}
	for a, b in pairs(zones_datafile) do
		if not mafia_adventures[a] then
			softwarn("Zone mismatch", a, "vs", mafia_adventures_inverse[b.zoneid])
		end
		if b.zoneid then
			zones_datafile_inverse[b.zoneid] = a
			zones_by_number[b.zoneid] = a
		end
	end

	for a, b in pairs(mafia_adventures) do
		if not zones_datafile[a] then
			softwarn("Zone mismatch", zones_datafile_inverse[b], "vs", a)
		end
		if not zones_by_number[b] then
			zones_by_number[b] = a
		end
	end

	local zones = {}
	for a, b in pairs(zones_by_number) do
		local z = zones_datafile[b] or {}
		z.zoneid = z.zoneid or a
		if not mafia_zoneid_monsters[z.zoneid] then
			softwarn("zones:unknown monsters in", z.zoneid, b)
		end
		local monsters = mafia_zoneid_monsters[z.zoneid] or {}
		table.sort(monsters)
		z.monsters = z.monsters or monsters
		zones[b] = z
	end

	return zones
end

function verify_zones(data)
	for a, b in pairs(data) do
		for _, x in ipairs(b.monsters) do
			if not processed_datafiles["monsters"][x:lower()] then
				hardwarn("zones:unknown monster", x, "in", a)
			end
		end
	end

	if data["The Dungeons of Doom"].zoneid == 39 then
		if data["McMillicancuddy's Farm"].zoneid == 155 then
			if data["The Spooky Forest"].zoneid == 15 and data["The Spooky Forest"]["combat rate"] == 85 then
				return data
			end
		end
	end
end

function parse_choice_spoilers()
	local jsonlines = {}
	local found_adv_options = false
	for l in io.lines("cache/files/68727.user.js") do
		if l:match("var advOptions") then
			found_adv_options = true
			table.insert(jsonlines, "{")
		elseif found_adv_options then
			if l:match("};") then
				table.insert(jsonlines, "}")
				break
			else
				l_json = l:gsub("\r", ""):gsub("//.+", ""):gsub("([0-9]+)(:%[)", [["%1"%2]]) -- Strip CRs, comments, and quote keys
				l_json = l_json:gsub("\\m", "\\n") -- Correct known typo
				l_json = l_json:gsub("%+$", ",") -- HACK: Remove code using string concatenation
				table.insert(jsonlines, l_json)
			end
		end
	end
	local rawspoilers = json_to_table(table.concat(jsonlines, "\n"))
	local choice_spoilers = {}
	for a, b in pairs(rawspoilers) do
		table.remove(b, 1)
		choice_spoilers["choiceid:"..tonumber(a)] = b
	end
	return choice_spoilers
end

function verify_choice_spoilers(data)
	if data["choiceid:17"][2]:contains("snowboarder pants") and data["choiceid:603"][4]:contains("Skeletal Rogue") and data["choiceid:497"][1]:contains("unearthed monstrosity") then
		return data
	end
end

function process(datafile)
	local filename = datafile:gsub(" ", "-")
	local loadf = _G["parse_"..datafile:gsub(" ", "_")]
	local verifyf = _G["verify_"..datafile:gsub(" ", "_")]
	local dataok, data = pcall(loadf)
	if dataok then
		local verifyok, verified = pcall(verifyf, data)
		if verifyok and verified then
			local json = table_to_json(verified)
			local fobj = io.open("cache/data/" .. filename .. ".json", "w")
			fobj:write(json)
			fobj:close()
			processed_datafiles[datafile] = verified
		else
			print("WARNING: verifying " .. tostring(filename) .. " data file failed (" .. tostring(verified) .. ").")
		end
	else
		print("ERROR: parsing " .. tostring(filename) .. " data file failed (" .. tostring(data) .. ").")
	end
end

process("choice spoilers")

process("familiars")
process("enthroned familiars")

process("buffs")

process("items")
process("outfits")
process("hatrack")
process("recipes")

process("skills")
process("buff recast skills")

process("monsters")

process("faxbot monsters")

process("semirares")

process("mallprices")
process("consumables")

process("zones")
