//Upping this above 7 may break shit.
#define MAX_CHARACTER_LOADOUT_ITEMS 7

/client
	/// Stuff can be a tad fucked if someone opens multiple UIs, so we're forcing there to only be one.disposing()
	var/datum/character_loadout/open_loadout_ui = null

/datum/character_loadout
	/// Client who owns the loadout
	var/client/loadout_owner = null
	/// Assoc list of items a loadout has, gets pushed to prefs on save
	var/list/loadout_items = list()

	New(mob/user)
		loadout_owner = user.client
		loadout_items = user.client.preferences.character_loadout.Copy()
		if(length(loadout_items) > MAX_CHARACTER_LOADOUT_ITEMS)
			loadout_items.Cut(MAX_CHARACTER_LOADOUT_ITEMS + 1, 0) //Sanity check to make sure people don't get too much shit
		..()

	disposing()
		loadout_owner = null
		..()

	proc/select_item(datum/character_loadout_item/selected_item)
		var/list/datum_list = concrete_typesof(/datum/character_loadout_item)
		for(var/datum/character_loadout_item/C in datum_list)
			if(istype(selected_item, C))
				loadout_items["[C.slot]"] = "[C.type]"
				break

	proc/deselect_item(datum/character_loadout_item/selected_item)
		loadout_items -= loadout_items["[selected_item.slot]"]

	proc/display_job_restrictions(datum/character_loadout_item/item)
		var/composed_message = "<span class='alert'>The [initial(item.name)] is restricted to the following jobs:<br></span>"
		for(var/jobs in item.job_restricted)
			composed_message += "<span class='notice'>[jobs]<br></span>"

		boutput(loadout_owner, "[composed_message]")

	ui_close(mob/user)
		loadout_owner?.open_loadout_ui = null
		qdel(src)

	ui_state(mob/user)
		//return tgui_always_state.can_use_topic(src, user)
		return tgui_always_state

	ui_interact(mob/user, datum/tgui/ui)
		ui = tgui_process.try_update_ui(user, src, ui)
		if(!ui)
			ui = new(user, src, "CharacterLoadout")
			ui.open()

	ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
		. = ..()
		if(.)
			return

		var/datum/character_loadout_item/interacted_item
		if(params["path"])
			interacted_item = all_character_loadout_datums[text2path(params["path"])]
			if(!interacted_item)
				stack_trace("Failed to locate desired loadout item (path: [params["path"]]) in the global list of loadout datums!")
				return

		switch(action)
			// Closes the UI and saves our loadout
			if("close_ui")
				loadout_owner?.preferences?.character_loadout = loadout_items.Copy()
				tgui_process.close_uis(src)
				return

			if("select_item")
				//Here we will perform basic checks to ensure there are no exploits happening
				if(params["deselect"])
					deselect_item(interacted_item)
					//owner?.prefs?.character_preview_view.update_body()
				else
					select_item(interacted_item)
					//owner?.prefs?.character_preview_view.update_body()


			if("display_restrictions")
				display_job_restrictions(interacted_item)

			// Clears the loadout list entirely.
			if("clear_all_items")
				loadout_items = null
				//owner?.prefs?.character_preview_view.update_body()


			// Toggles between showing all dirs of the dummy at once.
			/*if("show_all_dirs")
				toggle_model_dirs()*/

			/*if("update_preview")
				owner?.prefs.preview_pref = params["updated_preview"]
				owner?.prefs?.character_preview_view.update_body()*/


		return TRUE


	ui_data(mob/user)
		var/list/data = list()

		var/list/all_selected_paths = list()
		for(var/path in loadout_owner?.preferences?.character_loadout)
			all_selected_paths += path
		data["selected_loadout"] = all_selected_paths

		return data

	ui_static_data()
		var/list/data = list()

		// [name] is the name of the tab that contains all the corresponding contents.
		// [title] is the name at the top of the list of corresponding contents.
		// [contents] is a formatted list of all the possible items for that slot.
		//  - [contents.path] is the path the single datum holds
		//  - [contents.name] is the name of the single datum
		//  - [contents.tooltip_text], any additional tooltip text that hovers over the item's select button

		var/list/loadout_tabs = list()
		//loadout_tabs += list(list("name" = "Belt", "title" = "Belt Slot Items", "contents" = list_to_data(GLOB.loadout_belts)))
		//-loadout_tabs += list(list("name" = "Ears", "title" = "Ear Slot Items", "contents" = list_to_data(GLOB.loadout_ears)))
		//loadout_tabs += list(list("name" = "Glasses", "title" = "Glasses Slot Items", "contents" = list_to_data(GLOB.loadout_glasses)))
		//loadout_tabs += list(list("name" = "Gloves", "title" = "Glove Slot Items", "contents" = list_to_data(GLOB.loadout_gloves)))
		//loadout_tabs += list(list("name" = "Head", "title" = "Head Slot Items", "contents" = list_to_data(GLOB.loadout_helmets)))
		//loadout_tabs += list(list("name" = "Mask", "title" = "Mask Slot Items", "contents" = list_to_data(GLOB.loadout_masks)))
		loadout_tabs += list(list("name" = "Shoes", "title" = "Shoe Slot Items", "contents" = list_to_data(character_loadout_shoes)))
		//loadout_tabs += list(list("name" = "Suit", "title" = "Suit Slot Items", "contents" = list_to_data(GLOB.loadout_exosuits)))
		//loadout_tabs += list(list("name" = "Jumpsuit", "title" = "Uniform Slot Items", "contents" = list_to_data(GLOB.loadout_jumpsuits)))
		//loadout_tabs += list(list("name" = "Formal", "title" = "Uniform Slot Items (cont)", "contents" = list_to_data(GLOB.loadout_undersuits)))
		//loadout_tabs += list(list("name" = "Misc. Under", "title" = "Uniform Slot Items (cont)", "contents" = list_to_data(GLOB.loadout_miscunders)))
		//-loadout_tabs += list(list("name" = "Accessory", "title" = "Uniform Accessory Slot Items", "contents" = list_to_data(GLOB.loadout_accessory)))
		//-loadout_tabs += list(list("name" = "Inhand", "title" = "In-hand Items", "contents" = list_to_data(GLOB.loadout_inhand_items)))
		//-loadout_tabs += list(list("name" = "Toys", "title" = "Toys!", "contents" = list_to_data(GLOB.loadout_toys)))
		//loadout_tabs += list(list("name" = "Other", "title" = "Backpack Items", "contents" = list_to_data(GLOB.loadout_pocket_items)))

		data["loadout_tabs"] = loadout_tabs

		return data

/*
 * Takes an assoc list of [typepath]s to [single datum]
 * And formats it into an object for TGUI.
 *
 * - list[name] is the name of the datum.
 * - list[path] is the typepath of the item.
 */
/datum/character_loadout/proc/list_to_data(list_of_datums)
	if(!length(list_of_datums))
		return

	var/list/formatted_list = new(length(list_of_datums))

	var/array_index = 1
	for(var/datum/character_loadout_item/item as anything in list_of_datums)

		var/list/formatted_item = list()
		formatted_item["name"] = item.name
		formatted_item["path"] = item.path
		formatted_item["is_job_restricted"] = !isnull(item.job_restricted)
		if(length(item.tooltip_text))
			formatted_item["tooltip_text"] = item.tooltip_text.Join("\n")

		formatted_list[array_index++] = formatted_item

	return formatted_list


/// Converts the defined slot of a loadout item datum into a target's equippable slot
/proc/cl_category_to_slot(datum/character_loadout_item/chosen_item, mob/living/carbon/human/target)
	switch(chosen_item.slot)
		if(LOADOUT_ITEM_BELT)
			return target.slot_belt
		if(LOADOUT_ITEM_GLASSES)
			return target.slot_glasses
		if(LOADOUT_ITEM_GLOVES)
			return target.slot_gloves
		if(LOADOUT_ITEM_HEAD)
			return target.slot_head
		if(LOADOUT_ITEM_MASK)
			return target.slot_wear_mask
		if(LOADOUT_ITEM_SHOES)
			return target.slot_shoes
		if(LOADOUT_ITEM_SUIT)
			return target.slot_wear_suit
		if(LOADOUT_ITEM_UNIFORM)
			return target.slot_w_uniform
		if(LOADOUT_ITEM_MISC)
			return target.slot_in_backpack
