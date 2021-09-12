#define MAX_QUEUE_LENGTH 20
/obj/machinery/automation //abstract parent
	name = "automation machinery"
	desc = "Contact #imcoder if you see me!" //@todo: put a begin work proc here
	icon = 'icons/obj/power.dmi'
	icon_state = "smes"
	anchored = 1

/proc/get_opposite_dir(var/D)
	switch(D)
		if(NORTH)
			return SOUTH
		if(NORTHEAST)
			return SOUTHWEST
		if(NORTHWEST)
			return SOUTHEAST
		if(EAST)
			return WEST
		if(SOUTH)
			return NORTH
		if(SOUTHEAST)
			return NORTHWEST
		if(SOUTHWEST)
			return NORTHEAST
		if(WEST)
			return EAST


/*
/obj/machinery/automation/refinery
	name = "automated refinery"
	desc = "An automated refinery. To use, throw items in the chute."
	event_handler_flags = USE_FLUID_ENTER | USE_CANPASS
	var/active = FALSE
	var/indir = NORTH
	var/outdir = SOUTH

	CanPass(var/obj/O, var/atom/oldloc)
		.= ..()
		if (oldloc && oldloc.y == src.y)
		var/oldloc_dir = get_dir(src, oldloc)
		if(oldloc && (oldloc_dir == NORTH || oldloc_dir == EAST || oldloc_dir == SOUTH || oldloc_dir == WEST) && oldloc_dir == src.indir)

			for (var/obj/item/M in src.contents)
				if (istype(M, /obj/item/raw_material))
					output_bar_from_item(M)
					pool(M)

	proc/load_reclaim(obj/item/W as obj, mob/user as mob)
		. = FALSE
		if (istype(W, /obj/item/raw_material/))
			W.set_loc(src)
			if (user) user.u_equip(W)
			W.dropped()
			. = TRUE*/

/obj/machinery/portable_reclaimer/automated
	name = "automated refinery"
	desc = "An automated refinery. To use, throw items in the chute."
	event_handler_flags = USE_FLUID_ENTER | USE_CANPASS
	anchored = 1
	var/indir = NORTH
	var/outdir = SOUTH

	New()
		..()
	/*	SPAWN_DBG(1 SECOND)
			indir = step(src, dir)
			outdir = get_opposite_dir(indir)*/

	attack_hand(mob/user)
		return

	attackby(obj/item/W, mob/user)
		if(ispryingtool(W))
			src.set_dir(turn(src.dir, 90))
			src.indir = src.dir
			src.outdir = get_opposite_dir(indir)
		return

	MouseDrop(over_object, src_location, over_location)
		return

	CanPass(var/obj/O, var/atom/oldloc)
		var/oldloc_dir = get_dir(src, oldloc)
		if(oldloc && (oldloc_dir == NORTH || oldloc_dir == EAST || oldloc_dir == SOUTH || oldloc_dir == WEST) && oldloc_dir == src.indir && istype(O, /obj/))
			O.set_loc(src)
		else if(oldloc && (oldloc_dir == NORTH || oldloc_dir == EAST || oldloc_dir == SOUTH || oldloc_dir == WEST) && oldloc_dir == src.indir && !istype(O, /obj/))
			return

	process()
		for(var/obj/item/M in src.contents)
			if(istype(M, /obj/item/raw_material))
				output_bar_from_item(M)
				qdel(M)
			else
				M.set_loc(locate(src))
		for(var/mob/M2 in src.contents)
			M2.set_loc(locate(src))


	output_bar(material, amount, quality)

		var/datum/material/MAT = material
		if (!istype(MAT))
			MAT = getMaterial(material)
			if (!MAT)
				return

		var/output_location = src.get_output_location()

		var/bar_type = getProcessedMaterialForm(MAT)
		var/obj/item/material_piece/BAR = unpool(bar_type)
		BAR.quality = quality
		BAR.name += getQualityName(quality)
		BAR.setMaterial(MAT)
		BAR.change_stack_amount(amount - 1)

		if (istype(output_location, /obj/machinery/manufacturer))
			var/obj/machinery/manufacturer/M = output_location
			M.load_item(BAR)
		else
			BAR.set_loc(output_location)
			step(BAR, src.outdir)

		playsound(src.loc, sound_process, 40, 1)

/obj/machinery/manufacturer/automated
	name = "automated fabricator"
	desc = "A manufacturing unit that can automatically take inputs and create outputs."
	icon_state = "fab-mining"
	icon_base = "mining"
	event_handler_flags = USE_FLUID_ENTER | USE_CANPASS
	var/indir = NORTH
	var/outdir = SOUTH
	repeat = 1

	New()
		..()
		SPAWN_DBG(1 SECOND)
			var/src_turf = locate(src)
			src.output_target = locate(get_step(src_turf, outdir)) //aaa this doesn't work aaa

	process(var/mult)
		if (status & NOPOWER)
			return

		power_usage = src.powconsumption + 200 * mult
		..()

		if (src.mode == "working")
			use_power(src.powconsumption)

		if (src.electrified > 0)
			src.electrified--

		if(src.repeat && length(src.queue) && check_enough_materials(src.queue[1]) && (src.mode == "halt" || src.mode == "ready"))
			src.begin_work(1)

	CanPass(var/obj/item/O, var/atom/oldloc)
		var/oldloc_dir = get_dir(src, oldloc)
		if(oldloc && oldloc_dir == src.indir && istype(O, /obj/) && O.material)
			src.load_item(O, null)
		else
			return

	MouseDrop(over_object, src_location, over_location)
		return

	attackby(obj/item/W, mob/user)
		if(ispryingtool(W))
			src.set_dir(turn(src.dir, 90))
			src.indir = src.dir
			src.outdir = get_opposite_dir(indir)
		if (istype(W, /obj/item/paper/manufacturer_blueprint))
			if (!src.accept_blueprints)
				boutput(user, "<span class='alert'>This manufacturer unit does not accept blueprints.</span>")
				return
			var/obj/item/paper/manufacturer_blueprint/BP = W
			if (src.malfunction && prob(75))
				src.visible_message("<span class='alert'>[src] emits a [pick(src.text_flipout_adjective)] [pick(src.text_flipout_noun)]!</span>")
				playsound(src.loc, pick(src.sounds_malfunction), 50, 1)
				boutput(user, "<span class='alert'>The manufacturer mangles and ruins the blueprint in the scanner! What the fuck?</span>")
				qdel(BP)
				return
			if (!BP.blueprint)
				src.visible_message("<span class='alert'>[src] emits a grumpy buzz!</span>")
				playsound(src.loc, src.sound_grump, 50, 1)
				boutput(user, "<span class='alert'>The manufacturer rejects the blueprint. Is something wrong with it?</span>")
				return
			for (var/datum/manufacture/mechanics/M in (src.available + src.download))
				if(istype(M) && istype(BP.blueprint, /datum/manufacture/mechanics))
					var/datum/manufacture/mechanics/BPM = BP.blueprint
					if(M.frame_path == BPM.frame_path)
						src.visible_message("<span class='alert'>[src] emits an irritable buzz!</span>")
						playsound(src.loc, src.sound_grump, 50, 1)
						boutput(user, "<span class='alert'>The manufacturer rejects the blueprint, as it already knows it.</span>")
						return
				else if (BP.blueprint.name == M.name)
					src.visible_message("<span class='alert'>[src] emits an irritable buzz!</span>")
					playsound(src.loc, src.sound_grump, 50, 1)
					boutput(user, "<span class='alert'>The manufacturer rejects the blueprint, as it already knows it.</span>")
					return
			BP.dropped()
			src.download += BP.blueprint
			src.visible_message("<span class='alert'>[src] emits a pleased chime!</span>")
			playsound(src.loc, src.sound_happy, 50, 1)
			boutput(user, "<span class='notice'>The manufacturer accepts and scans the blueprint.</span>")
			qdel(BP)
			return
		return

	Topic(href, href_list)

		if(!(href_list["cutwire"] || href_list["pulsewire"]))
			if(status & BROKEN || status & NOPOWER)
				return

		if(usr.stat || usr.restrained())
			return

		if(src.electrified != 0)
			if (!(status & NOPOWER || status & BROKEN))
				if (src.manuf_zap(usr, 10))
					return

		if ((usr.contents.Find(src) || ((get_dist(src, usr) <= 1 || isAI(usr)) && istype(src.loc, /turf))))
			src.add_dialog(usr)

			if (src.malfunction && prob(10))
				src.flip_out()

			if (href_list["eject"])
				if (src.mode != "ready")
					boutput(usr, "<span class='alert'>You cannot eject materials while the unit is working.</span>")
				else
					var/mat_id = href_list["eject"]
					var/ejectamt = 0
					var/turf/ejectturf = get_turf(usr)
					for(var/obj/item/O in src.contents)
						if (O.material && O.material.mat_id == mat_id)
							if (!ejectamt)
								ejectamt = input(usr,"How many material pieces (10 units per) do you want to eject?","Eject Materials") as num
								if (ejectamt <= 0 || src.mode != "ready" || get_dist(src, usr) > 1)
									break
							if (!ejectturf)
								break
							if (ejectamt > O.amount)
								playsound(src.loc, src.sound_grump, 50, 1)
								boutput(usr, "<span class='alert'>There's not that much material in [name]. It has ejected what it could.</span>")
								ejectamt = O.amount
							src.update_resource_amount(mat_id, -ejectamt * 10) // ejectamt will always be <= actual amount
							if (ejectamt == O.amount)
								O.set_loc(get_output_location(O,1))
							else
								var/obj/item/material_piece/P = unpool(O.type)
								P.setMaterial(copyMaterial(O.material))
								P.change_stack_amount(ejectamt - P.amount)
								O.change_stack_amount(-ejectamt)
								P.set_loc(get_output_location(O,1))
							break

			if (href_list["speed"])
				if (src.mode == "working")
					boutput(usr, "<span class='alert'>You cannot alter the speed setting while the unit is working.</span>")
				else
					var/upperbound = 3
					if (src.hacked)
						upperbound = 5
					var/newset = input(usr,"Enter from 1 to [upperbound]. Higher settings consume more power","Manufacturing Speed") as num
					newset = max(1,min(newset,upperbound))
					src.speed = newset

			if (href_list["clearQ"])
				var/Qcounter = 1
				for (var/datum/manufacture/M in src.queue)
					if (Qcounter == 1 && src.mode == "working") continue
					src.queue -= src.queue[Qcounter]
				if (src.mode == "halt")
					src.manual_stop = 0
					src.error = null
					src.mode = "ready"
					src.build_icon()

			if (href_list["removefromQ"])
				var/operation = text2num(href_list["removefromQ"])
				if (!isnum(operation) || src.queue.len < 1 || operation > src.queue.len)
					boutput(usr, "<span class='alert'>Invalid operation.</span>")
					return

				if(world.time < last_queue_op + 5) //Anti-spam to prevent people lagging the server with autoclickers
					return
				else
					last_queue_op = world.time

				src.queue -= src.queue[operation]
				begin_work(1)//pesky exploits

			if (href_list["page"])
				var/operation = text2num(href_list["page"])
				src.page = operation

			if (href_list["repeat"])
				boutput(usr, "<span class='alert'>The button seems to be stuck in the 'ON' position.</span>")

			if (href_list["search"])
				src.search = input("Enter text to search for in schematics.","Manufacturing Unit") as null|text
				if (length(src.search) == 0)
					src.search = null

			if (href_list["category"])
				src.category = input("Select which category to filter by.","Manufacturing Unit") as null|anything in src.categories

			if (href_list["continue"])
				if (src.queue.len < 1)
					boutput(usr, "<span class='alert'>Cannot find any items in queue to continue production.</span>")
					return
				if (!check_enough_materials(src.queue[1]))
					boutput(usr, "<span class='alert'>Insufficient usable materials to manufacture first item in queue.</span>")
				else
					src.begin_work(0)

			if (href_list["pause"])
				src.mode = "halt"
				src.build_icon()
				if (src.action_bar)
					src.action_bar.interrupt(INTERRUPT_ALWAYS)

			if (href_list["delete"])
				if(!src.allowed(usr))
					boutput(usr, "<span class='alert'>Access denied.</span>")
					return
				var/datum/manufacture/I = locate(href_list["disp"])
				if (!istype(I,/datum/manufacture/mechanics/))
					boutput(usr, "<span class='alert'>Cannot delete this schematic.</span>")
					return
				last_queue_op = world.time
				if(alert("Are you sure you want to remove [I.name] from the [src]?",,"Yes","No") == "Yes")
					src.download -= I
			else if (href_list["disp"])
				var/datum/manufacture/I = locate(href_list["disp"])
				if (!istype(I,/datum/manufacture/))
					return
				if(world.time < last_queue_op + 5) //Anti-spam to prevent people lagging the server with autoclickers
					return
				else
					last_queue_op = world.time

				// Verify that there is no href fuckery abound
				if(!validate_disp(I))
					// Since a manufacturer may get unhacked or a downloaded item could get deleted between someone
					// opening the window and clicking the button we can't assume intent here, so no cluwne
					return

				if (!check_enough_materials(I))
					boutput(usr, "<span class='alert'>Insufficient usable materials to manufacture that item.</span>")
				else if (src.queue.len >= MAX_QUEUE_LENGTH)
					boutput(usr, "<span class='alert'>Manufacturer queue length limit reached.</span>")
				else
					src.queue += I
					if (src.mode == "ready")
						src.begin_work(1)
						src.updateUsrDialog()

				if (src.queue.len > 0 && src.mode == "ready")
					src.begin_work(1)
					src.updateUsrDialog()
					return

			if (href_list["ejectbeaker"])
				if (src.beaker)
					src.beaker.set_loc(get_output_location(beaker,1))
				src.beaker = null

			if (href_list["transto"])
				// reagents are going into beaker
				var/obj/item/reagent_containers/glass/B = locate(href_list["transto"])
				if (!istype(B,/obj/item/reagent_containers/glass/))
					return
				var/howmuch = input("Transfer how much to [B]?","[src.name]",B.reagents.maximum_volume - B.reagents.total_volume) as null|num
				if (!howmuch || !B || B != src.beaker )
					return
				src.reagents.trans_to(B,howmuch)

			if (href_list["transfrom"])
				// reagents are being drawn from beaker
				var/obj/item/reagent_containers/glass/B = locate(href_list["transfrom"])
				if (!istype(B,/obj/item/reagent_containers/glass/))
					return
				var/howmuch = input("Transfer how much from [B]?","[src.name]",B.reagents.total_volume) as null|num
				if (!howmuch)
					return
				B.reagents.trans_to(src,howmuch)

			if (href_list["flush"])
				var/the_reagent = href_list["flush"]
				if (!istext(the_reagent))
					return
				var/howmuch = input("Flush how much [the_reagent]?","[src.name]",0) as null|num
				if (!howmuch)
					return
				src.reagents.remove_reagent(the_reagent,howmuch)

			if ((href_list["cutwire"]) && (src.panelopen || isAI(usr)))
				if (src.electrified)
					if (src.manuf_zap(usr, 100))
						return
				var/twire = text2num(href_list["cutwire"])
				if (!usr.find_tool_in_hand(TOOL_SNIPPING))
					boutput(usr, "You need a snipping tool!")
					return
				else if (src.isWireColorCut(twire))
					src.mend(twire)
				else
					src.cut(twire)
				src.build_icon()

			if ((href_list["pulsewire"]) && (src.panelopen || isAI(usr)))
				var/twire = text2num(href_list["pulsewire"])
				if ( !(usr.find_tool_in_hand(TOOL_PULSING) || isAI(usr)) )
					boutput(usr, "You need a multitool or similar!")
					return
				else if (src.isWireColorCut(twire))
					boutput(usr, "You can't pulse a cut wire.")
					return
				else
					src.pulse(twire)
				src.build_icon()

			if (href_list["card"])
				boutput(usr, "<span class='alert'>This fabricator does not support scanning in ID cards.</span>")

			if (href_list["purchase"])
				boutput(usr, "<span class='alert'>This fabricator does not support buying ores.</span>")

/obj/machinery/automation/crate_loader
	name = "crate loader"
	desc = "Contact #imcoder if you see me!"
	icon_state = "smes"
	event_handler_flags = USE_FLUID_ENTER | USE_CANPASS
	var/indir = NORTH
	var/outdir = SOUTH
	var/metal_amount = 0
	var/currently_packing = FALSE

	/*attackby(obj/item/W, mob/user)
		if(istype(W, /obj/item/material_piece) && W?.material.material_flags & MATERIAL_METAL)
			qdel(W)
			metal_amount += 10*/ //'tis a shitty hack



	CanPass(var/obj/O, var/atom/oldloc)
		var/oldloc_dir = get_dir(src, oldloc)
		if(oldloc && (oldloc_dir == NORTH || oldloc_dir == EAST || oldloc_dir == SOUTH || oldloc_dir == WEST) && oldloc_dir == src.indir && istype(O, /obj/))
			O.set_loc(src)
		else if(oldloc && (oldloc_dir == NORTH || oldloc_dir == EAST || oldloc_dir == SOUTH || oldloc_dir == WEST) && oldloc_dir == src.indir && !istype(O, /obj/))
			return


/*
/obj/smes_spawner
	name = "power storage unit"
	icon = 'icons/obj/power.dmi'
	icon_state = "smes"
	density = 1
	anchored = 1
	New()
		..()
		SPAWN_DBG(1 SECOND)
			var/obj/term = new /obj/machinery/power/terminal(get_step(get_turf(src), dir))
			term.set_dir(get_dir(get_turf(term), src))
			new /obj/machinery/power/smes(get_turf(src))
			qdel(src)*/
#undef MAX_QUEUE_LENGTH
