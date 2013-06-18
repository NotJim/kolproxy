local function load_slots()
	local slots = ascension["interface.outfit slots"] or {}
	slots.outfits = slots.outfits or { {}, {}, {}, {}, {} }
	slots.selected = slots.selected or 1
	return slots
end

function switch_outfit_slot(slot)
	local slots = load_slots()
	slots.outfits[slots.selected] = equipment()
	slots.selected = slot
	set_equipment(slots.outfits[slots.selected])
	ascension["interface.outfit slots"] = slots
end

switch_outfit_slot_href = add_automation_script("custom-outfit-slot", function()
	local slot = tonumber(params.slot)
	if load_slots().outfits[slot] then
		switch_outfit_slot(slot)
		return "Done.", requestpath
	end
	return "Failed.", requestpath
end)

function get_outfit_slots_script()
	return [[
<script type="text/javascript">
	function switch_outfit_slot(slot) {
		$.ajax({
			type: 'GET',
			url: '/kolproxy-automation-script?automation-script=custom-outfit-slot&pwd=]]..session.pwd..[[&slot=' + slot,
			cache: false,
			global: false,
			success: function() {
				top.charpane.location.href = 'charpane.php';
			}
		});
	}
</script>
]]
end

function get_outfit_slots_line()
	local links = {}
	local slots = load_slots()
	for a, _ in ipairs(slots.outfits) do
		if a == slots.selected then
			table.insert(links, string.format([[<a href="javascript:switch_outfit_slot(%d)" style="color: black">[%d]</a>]], a, a))
		else
			table.insert(links, string.format([[<a href="javascript:switch_outfit_slot(%d)" style="color: gray">[%d]</a>]], a, a))
		end
	end
	return table.concat(links, " ")
end
