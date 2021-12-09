var/list/character_loadout_shoes = list(generate_character_loadout_items(/datum/character_loadout_item/shoes))

/datum/character_loadout_item/shoes
	slot = LOADOUT_ITEM_SHOES

/datum/character_loadout_item/shoes/orange
	name = "Orange Shoes"
	path = /obj/item/clothing/shoes/orange

/datum/character_loadout_item/shoes/blue
	name = "Blue Shoes"
	path = /obj/item/clothing/shoes/blue
	job_restricted = list("Scientist")
