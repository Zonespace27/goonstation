/// A list of every single character loadout item datum
var/list/all_character_loadout_datums = list()


/// Generates a list of single datums of a type, adds them to the global `all_character_loadout_datums` list
/proc/generate_character_loadout_items(type_to_generate)
	. = list()

	for(var/datum/character_loadout_item/found_type as anything in concrete_typesof(type_to_generate))
		var/datum/character_loadout_item/spawned_type = new found_type()
		all_character_loadout_datums[spawned_type.path] = spawned_type
		. |= spawned_type


ABSTRACT_TYPE(/datum/character_loadout_item)
/datum/character_loadout_item
	var/name = null
	var/path
	var/slot = LOADOUT_ITEM_MISC
	//var/category = "Misc"
	var/cost = 0
	var/list/job_restricted = list()
	var/list/tooltip_text = list()

/datum/character_loadout_item/New()
	..()
	if(!name)
		var/obj/O = src.path
		src.name = initial(O.name)
	cost = round(cost)

