/obj/item/gun/moddable
	name = "Modular Gun"
	icon = 'icons/obj/items/gun.dmi'
	item_state = "hipoint"
	m_amt = 2000
	add_residue = 0
	flags = ONBELT | TABLEPASS | CONDUCT
	var/can_add_attachments = TRUE
	//energy
	var/obj/item/gun/energy/rechargeable = 0
	var/obj/item/gun/energy/robocharge = 0
	var/obj/item/gun/energy/cell_type = null
	var/obj/item/ammo/power_cell/cell = null
	var/obj/item/gun/energy/custom_cell_max_capacity = null
	var/obj/item/gun/energy/wait_cycle = 0
	var/obj/item/gun/energy/can_swap_cell = 0
	//energy end
	muzzle_flash = null
	inventory_counter_enabled = 1
	//kinetic
	var/obj/item/ammo/bullets/ammo = null
	var/obj/item/gun/kinetic/max_ammo_capacity = 0
	var/obj/item/gun/kinetic/caliber = null
	var/obj/item/gun/kinetic/has_empty_state = 0
	var/obj/item/gun/kinetic/auto_eject = 0
	var/obj/item/gun/kinetic/casings_to_eject = 0
	var/obj/item/gun/kinetic/allowReverseReload = 0
	var/obj/item/gun/kinetic/allowDropReload = 0
	//kinetic end

	New()
		if(!cell)
			cell = new cell_type //this runtimes because the cell's null
		if (!(src in processing_items))
			processing_items.Add(src)
		if(silenced)
			current_projectile.shot_sound = 'sound/machines/click.ogg'
		..()
		src.update_icon()

	disposing()
		processing_items -= src
		..()

	examine()
		. = ..()
		if (src.flags & GP_ENERGY)
			if(src.cell)
				. += "[src.projectiles ? "It is set to [src.current_projectile.sname]. " : ""]There are [src.cell.charge]/[src.cell.max_charge] PUs left!"
			else
				. += "There is no cell loaded!"
			if(current_projectile)
				. += "Each shot will currently use [src.current_projectile.cost] PUs!"
			else
				. += "<span class='alert'>*ERROR* No output selected!</span>"
		if (src.flags & GP_KINETIC)
			if (src.ammo && (src.ammo.amount_left > 0))
				var/datum/projectile/ammo_type = src.ammo.ammo_type
				. += "There are [src.ammo.amount_left][(ammo_type.material && istype(ammo_type.material, /datum/material/metal/silver)) ? " silver " : " "]bullets of [src.ammo.sname] left!"
			else
				. += "There are 0 bullets left!"
			if (current_projectile)
				. += "Each shot will currently use [src.current_projectile.cost] bullets!"
			else
				. += "<span class='alert'>*ERROR* No output selected!</span>"

	update_icon()
		if (src.flags & GP_ENERGY)
			if (src.cell)
				inventory_counter.update_percent(src.cell.charge, src.cell.max_charge)
			else
				inventory_counter.update_text("-")
			return 0
		if (src.flags & GP_KINETIC)
			if (src.ammo)
				inventory_counter.update_number(src.ammo.amount_left)
			else
				inventory_counter.update_text("-")
			if(src.has_empty_state)
				if (src.ammo.amount_left < 1 && !findtext(src.icon_state, "-empty")) //sanity check
					src.icon_state = "[src.icon_state]-empty"
				else
					src.icon_state = replacetext(src.icon_state, "-empty", "")
			return 0

	emp_act()
		if (src.flags & GP_ENERGY)
			if (src.cell && istype(src.cell))
				src.cell.use(INFINITY)
				src.update_icon()
			return

	process()
		if (src.flags & GP_ENERGY)
			src.wait_cycle = !src.wait_cycle // Self-charging cells recharge every other tick (Convair880).
			if (src.wait_cycle)
				return

			if (!(src in processing_items))
				logTheThing("debug", null, null, "<b>Convair880</b>: Process() was called for an egun ([src]) that wasn't in the item loop. Last touched by: [src.fingerprintslast]")
				processing_items.Add(src)
				return
			if (!src.cell)
				processing_items.Remove(src)
				return
			if (!istype(src.cell, /obj/item/ammo/power_cell/self_charging)) // Plain cell? No need for dynamic updates then (Convair880).
				processing_items.Remove(src)
				return
			if (src.cell.charge == src.cell.max_charge) // Keep them in the loop, as we might fire the gun later (Convair880).
				return

			src.update_icon()
			return

	canshoot()
		if (src.flags & GP_KINETIC)
			if(src.ammo && src.current_projectile)
				if(src.ammo:amount_left >= src.current_projectile:cost)
					return 1
			return 0
		if (src.flags & GP_ENERGY)
			if(src.cell && src.cell:charge && src.current_projectile)
				if(src.cell:charge >= src.current_projectile:cost)
					return 1
			return 0

	process_ammo(var/mob/user)
		if (src.flags & GP_KINETIC)
			if(src.ammo && src.current_projectile)
				if(src.ammo.use(current_projectile.cost))
					return 1
			boutput(user, "<span class='alert'>*click* *click*</span>")
			if (!src.silenced)
				playsound(user, "sound/weapons/Gunclick.ogg", 60, 1)
			return 0
		if (src.flags & GP_ENERGY)
			if(isrobot(user))
				var/mob/living/silicon/robot/R = user
				if(R.cell)
					if(R.cell.charge >= src.robocharge)
						R.cell.charge -= src.robocharge
						return 1
				return 0
			else
				if(src.cell && src.current_projectile)
					if(src.cell.use(src.current_projectile.cost))
						return 1
				boutput(user, "<span class='alert'>*click* *click*</span>")
				if (!src.silenced)
					playsound(user, "sound/weapons/Gunclick.ogg", 60, 1)
				return 0

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (src.flags & GP_KINETIC)
			if (istype(O, /obj/item/ammo/bullets) && allowDropReload)
				attackby(O, user)
			return ..()

	attackby(obj/item/b as obj, mob/user as mob)
		if (src.flags & GP_KINETIC)
			if(istype(b, /obj/item/ammo/bullets))
				var/obj/item/ammo/bullets/bullet = b
				src.max_ammo_capacity = bullet.max_amount
				switch (src.ammo.loadammo(b,src))
					if(0)
						user.show_text("You can't reload this gun.", "red")
						return
					if(1)
						user.show_text("This ammo won't fit!", "red")
						return
					if(2)
						user.show_text("There's no ammo left in [b.name].", "red")
						return
					if(3)
						user.show_text("[src] is full!", "red")
						return
					if(4)
						user.visible_message("<span class='alert'>[user] reloads [src].</span>", "<span class='alert'>There wasn't enough ammo left in [b.name] to fully reload [src]. It only has [src.ammo.amount_left] rounds remaining.</span>")
						src.logme_temp(user, src, b) // Might be useful (Convair880).
						return
					if(5)
						user.visible_message("<span class='alert'>[user] reloads [src].</span>", "<span class='alert'>You fully reload [src] with ammo from [b.name]. There are [bullet.amount_left] rounds left in [b.name]</span>")
						src.logme_temp(user, src, b)
						return
					if(6)
						switch (src.ammo.swap(b,src))
							if(0)
								user.show_text("This ammo won't fit!", "red")
								return
							if(1)
								user.visible_message("<span class='alert'>[user] reloads [src].</span>", "<span class='alert'>You swap out the magazine. Or whatever this specific gun uses.</span>")
							if(2)
								user.visible_message("<span class='alert'>[user] reloads [src].</span>", "<span class='alert'>You swap [src]'s ammo with [b.name]. There are [bullet.amount_left] rounds left in [b.name].</span>")
						src.logme_temp(user, src, b)
						return
			else
				..()
		if (src.flags & GP_ENERGY)
			if (can_swap_cell && istype(b, /obj/item/ammo/power_cell))
				var/obj/item/ammo/power_cell/pcell = b
				if (src.custom_cell_max_capacity && (pcell.max_charge > src.custom_cell_max_capacity))
					boutput(user, "<span class='alert'>This [pcell.name] won't fit!</span>")
					return
				src.logme_temp(user, src, pcell)
				if (istype(pcell, /obj/item/ammo/power_cell/self_charging) && !(src in processing_items))
					processing_items.Add(src)
				if (src.cell)
					actions.start(new/datum/action/bar/icon/powercellswap(user, pcell, src), user)
				else
					src.cell = pcell
					user.drop_item()
					pcell.set_loc(src)
					user.visible_message("<span class='alert'>[user] swaps [src]'s power cell.</span>")
			else
				..()
//attachments time
		if (can_add_attachments && istype(b, /obj/item/gun/moddable/attachment))
			if (istype(b, /obj/item/gun/moddable/attachment/kinetic))
				if (src.flags & GP_TYPE)
					src.name = "Kinetic Gun Frame"
					src.desc = "A kinetic gun frame that still isn't functional, due to its lack of an ammo type."
					src.flags = src.flags &= ~GP_TYPE
					src.flags = src.flags |= GP_AMMO
					qdel(b)
			if (istype(b, /obj/item/gun/moddable/attachment/energy))
				if (src.flags & GP_TYPE)
					src.name = "Energy Gun" //change me
					src.desc = "A completed energy gun."
					src.flags = src.flags &= ~GP_TYPE
					src.flags = src.flags |= GP_E_AMMO
					qdel(b)
			if (istype(b, /obj/item/gun/moddable/attachment/ammo22))
				if (src.flags & GP_AMMO)
					new /obj/item/gun/moddable/base/kinetic/gun22(get_turf(src))
					qdel(b)
					qdel(src)
			if (istype(b, /obj/item/gun/moddable/attachment/ammo308))
				if (src.flags & GP_AMMO)
					new /obj/item/gun/moddable/base/kinetic/gun308(get_turf(src))
					qdel(b)
					qdel(src)
			if (istype(b, /obj/item/gun/moddable/attachment/ammo556))
				if (src.flags & GP_AMMO)
					new /obj/item/gun/moddable/base/kinetic/gun556(get_turf(src))
					qdel(b)
					qdel(src)
			if (istype(b, /obj/item/gun/moddable/attachment/ammo357))
				if (src.flags & GP_AMMO)
					new /obj/item/gun/moddable/base/kinetic/gun357(get_turf(src))
					qdel(b)
					qdel(src)
			if (istype(b, /obj/item/gun/moddable/attachment/ammo762))
				if (src.flags & GP_AMMO)
					new /obj/item/gun/moddable/base/kinetic/gun762(get_turf(src))
					qdel(b)
					qdel(src)
			if (istype(b, /obj/item/gun/moddable/attachment/ammo12ga))
				if (src.flags & GP_AMMO)
					new /obj/item/gun/moddable/base/kinetic/gun12ga(get_turf(src))
					qdel(b)
					qdel(src)
			if (istype(b, /obj/item/gun/moddable/attachment/ammo50))
				if (src.flags & GP_AMMO)
					new /obj/item/gun/moddable/base/kinetic/gun50(get_turf(src))
					qdel(b)
					qdel(src)
			if (istype(b, /obj/item/gun/moddable/attachment/energystun))
				if (src.flags & GP_AMMO)
					new /obj/item/gun/moddable/base/energy/stun(get_turf(src))
					qdel(b)
					qdel(src)
			if (istype(b, /obj/item/gun/moddable/attachment/energylaser))
				if (src.flags & GP_AMMO)
					new /obj/item/gun/moddable/base/energy/laser(get_turf(src))
					qdel(b)
					qdel(src)
			if (istype(b, /obj/item/gun/moddable/attachment/energyemp))
				if (src.flags & GP_AMMO)
					new /obj/item/gun/moddable/base/energy/emp(get_turf(src))
					qdel(b)
					qdel(src)

	attack_hand(mob/user as mob)
		if (src.flags & GP_KINETIC)
			if ((src.loc == user) && user.find_in_hand(src)) // Make sure it's not on the belt or in a backpack.
				src.add_fingerprint(user)
				if (src.sanitycheck(0, 1) == 0)
					user.show_text("You can't unload this gun.", "red")
					return
				if (src.ammo.amount_left <= 0)
					// The gun may have been fired; eject casings if so.
					if ((src.casings_to_eject > 0) && src.current_projectile.casing)
						if (src.sanitycheck(1, 0) == 0)
							logTheThing("debug", usr, null, "<b>Convair880</b>: [usr]'s gun ([src]) ran into the casings_to_eject cap, aborting.")
							src.casings_to_eject = 0
							return
						else
							user.show_text("You eject [src.casings_to_eject] casings from [src].", "red")
							src.ejectcasings()
							return
					else
						user.show_text("[src] is empty!", "red")
						return

				// Make a copy here to avoid item teleportation issues.
				var/obj/item/ammo/bullets/ammoHand = new src.ammo.type
				ammoHand.amount_left = src.ammo.amount_left
				ammoHand.name = src.ammo.name
				ammoHand.icon = src.ammo.icon
				ammoHand.icon_state = src.ammo.icon_state
				ammoHand.ammo_type = src.ammo.ammo_type
				ammoHand.delete_on_reload = 1 // No duplicating empty magazines, please (Convair880).
				ammoHand.update_icon()
				user.put_in_hand_or_drop(ammoHand)
				ammoHand.after_unload(user)

				// The gun may have been fired; eject casings if so.
				src.ejectcasings()
				src.casings_to_eject = 0

				src.ammo.amount_left = 0
				src.update_icon()
				src.add_fingerprint(user)
				ammoHand.add_fingerprint(user)

				user.visible_message("<span class='alert'>[user] unloads [src].</span>", "<span class='alert'>You unload [src].</span>")
				return

			return ..()
		if (src.flags & GP_ENERGY)
			if ((user.r_hand == src || user.l_hand == src) && src.contents && length(src.contents))
				if (src.can_swap_cell && src.cell&&!src.rechargeable)
					var/obj/item/ammo/power_cell/W = src.cell
					user.put_in_hand_or_drop(W)
					src.cell = null
					update_icon()
					src.add_fingerprint(user)
				else
					return ..()
			else
				return ..()
			return

	proc/charge(var/amt)
		if (src.flags & GP_ENERGY)
			if(src.cell && rechargeable)
				return src.cell.charge(amt)
			else
				//No cell, or not rechargeable. Tell anything trying to charge it.
				return -1

	attack(mob/M as mob, mob/user as mob)
		if (src.flags & GP_KINETIC)
			if (src.canshoot() && user.a_intent != "help" && user.a_intent != "grab")
				if (src.auto_eject)
					var/turf/T = get_turf(src)
					if(T)
						if (src.current_projectile.casing && (src.sanitycheck(1, 0) == 1))
							var/number_of_casings = max(1, src.current_projectile.shot_number)
							//DEBUG_MESSAGE("Ejected [number_of_casings] casings from [src].")
							for (var/i = 1, i <= number_of_casings, i++)
								var/obj/item/casing/C = new src.current_projectile.casing(T)
								C.forensic_ID = src.forensic_ID
								C.set_loc(T)
				else
					if (src.casings_to_eject < 0)
						src.casings_to_eject = 0
					src.casings_to_eject += src.current_projectile.shot_number
			..()

	shoot(var/target,var/start ,var/mob/user)
		if (src.flags & GP_KINETIC)
			if (src.canshoot())
				if (src.auto_eject)
					var/turf/T = get_turf(src)
					if(T)
						if (src.current_projectile.casing && (src.sanitycheck(1, 0) == 1))
							var/number_of_casings = max(1, src.current_projectile.shot_number)
							//DEBUG_MESSAGE("Ejected [number_of_casings] casings from [src].")
							for (var/i = 1, i <= number_of_casings, i++)
								var/obj/item/casing/C = new src.current_projectile.casing(T)
								C.forensic_ID = src.forensic_ID
								C.set_loc(T)
				else
					if (src.casings_to_eject < 0)
						src.casings_to_eject = 0
					src.casings_to_eject += src.current_projectile.shot_number

			if (fire_animation)
				if(src.ammo?.amount_left > 1)
					flick(icon_state, src)

			..()

	proc/ejectcasings()
		if (src.flags & GP_KINETIC)
			if ((src.casings_to_eject > 0) && src.current_projectile.casing && (src.sanitycheck(1, 0) == 1))
				var/turf/T = get_turf(src)
				if(T)
					//DEBUG_MESSAGE("Ejected [src.casings_to_eject] [src.current_projectile.casing] from [src].")
					var/obj/item/casing/C = null
					while (src.casings_to_eject > 0)
						C = new src.current_projectile.casing(T)
						C.forensic_ID = src.forensic_ID
						C.set_loc(T)
						src.casings_to_eject = src.casings_to_eject - 1
			return

	proc/sanitycheck(var/casings = 0, var/ammo = 1)
		if (src.flags & GP_KINETIC)
			if (casings && (src.casings_to_eject > 30 || src.current_projectile.shot_number > 30))
				logTheThing("debug", usr, null, "<b>Convair880</b>: [usr]'s gun ([src]) ran into the casings_to_eject cap, aborting.")
				if (src.casings_to_eject > 0)
					src.casings_to_eject = 0
				return 0
			if (ammo && (src.max_ammo_capacity > 200 || src.ammo.amount_left > 200))
				logTheThing("debug", usr, null, "<b>Convair880</b>: [usr]'s gun ([src]) ran into the magazine cap, aborting.")
				return 0
			return 1


/obj/item/gun/moddable/base
	name = "Unbuilt Gun"
	desc = "A gun that seems not to be functioning, probably due to lacking any sort of parts."
	icon_state = "hipoint"
	flags = GP_TYPE | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY
	event_handler_flags = USE_GRAB_CHOKE | USE_FLUID_ENTER

/obj/item/gun/moddable/base/kinetic
	name = "Generic Kinetic Frame"
	desc = "You shouldn't see me!"
	icon_state = "hipoint"
	flags = GP_AMMO | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY
	event_handler_flags = USE_GRAB_CHOKE | USE_FLUID_ENTER
	auto_eject = 1
	allowDropReload = 1
	allowReverseReload = 1
	max_ammo_capacity = 1
	has_empty_state = 1

/obj/item/gun/moddable/base/energy
	name = "Generic Energy Frame"
	desc = "You shouldn't see me!"
	icon_state = "hipoint"
	flags = GP_E_AMMO | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY
	event_handler_flags = USE_GRAB_CHOKE | USE_FLUID_ENTER
	rechargeable = 1
	can_swap_cell = 1

	New()
		cell = /obj/item/ammo/power_cell/empty
		..()

/obj/item/gun/moddable/base/kinetic/gun22
	name = ".22 Gun" //change me
	desc = "A kinetic gun chambered in .22LR."
	caliber = 0.22
	max_ammo_capacity = 10
	flags = GP_KINETIC | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY

	New()
		ammo = new/obj/item/ammo/bullets/bullet_22
		set_current_projectile(new/datum/projectile/bullet/bullet_22)
		..()

/obj/item/gun/moddable/base/kinetic/gun308
	name = ".308 Gun" //change me
	desc = "A kinetic gun chambered in .308 Winchester."
	caliber = 0.308
	max_ammo_capacity = 4
	flags = GP_KINETIC | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY

	New()
		ammo = new/obj/item/ammo/bullets/rifle_3006
		set_current_projectile(new/datum/projectile/bullet/rifle_3006)
		..()

/obj/item/gun/moddable/base/kinetic/gun556
	name = "5.56 Gun" //change me
	desc = "A kinetic gun chambered in 5.56 NATO."
	caliber = 0.223
	max_ammo_capacity = 30
	flags = GP_KINETIC | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY

	New()
		ammo = new/obj/item/ammo/bullets/assault_rifle
		set_current_projectile(new/datum/projectile/bullet/assault_rifle)
		..()

/obj/item/gun/moddable/base/kinetic/gun762
	name = "7.62 Gun" //change me
	desc = "A kinetic gun chambered in 7.62 NATO."
	caliber = 0.308
	max_ammo_capacity = 20
	flags = GP_KINETIC | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY

	New()
		ammo = new/obj/item/ammo/bullets/ak47
		set_current_projectile(new/datum/projectile/bullet/ak47)
		..()

/obj/item/gun/moddable/base/kinetic/gun357
	name = ".357 Gun" //change me
	desc = "A kinetic gun chambered in .357 Smith & Wesson."
	caliber = list(0.38, 0.357)
	max_ammo_capacity = 7
	flags = GP_KINETIC | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY

	New()
		ammo = new/obj/item/ammo/bullets/a357
		set_current_projectile(new/datum/projectile/bullet/revolver_357)
		..()

/obj/item/gun/moddable/base/kinetic/gun50
	name = ".50 Gun" //change me
	desc = "A kinetic gun chambered in .50 Action Express."
	caliber = 0.50
	max_ammo_capacity = 8
	flags = GP_KINETIC | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY

	New()
		ammo = new/obj/item/ammo/bullets/deagle50cal
		set_current_projectile(new/datum/projectile/bullet/deagle50cal)
		..()

/obj/item/gun/moddable/base/kinetic/gun12ga
	name = "12 Gauge Gun" //change me
	desc = "A kinetic gun chambered in .357 Winchester."
	caliber = 0.72
	max_ammo_capacity = 8
	flags = GP_KINETIC | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY

	New()
		ammo = new/obj/item/ammo/bullets/a12
		set_current_projectile(new/datum/projectile/bullet/a12)
		..()

/obj/item/gun/moddable/base/energy/stun
	name = "Taser Energy Gun" //change me
	desc = "An energy gun, firing taser bolts."
	flags = GP_ENERGY | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY

	New()
		set_current_projectile(new/datum/projectile/energy_bolt)
		projectiles = list(current_projectile)
		cell = new/obj/item/ammo/power_cell/empty
		..()

/obj/item/gun/moddable/base/energy/laser
	name = "Laser Energy Gun" //change me
	desc = "An energy gun, firing lethal laser bolts."
	flags = GP_ENERGY | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY
	muzzle_flash = "muzzle_flash_phaser"

	New()
		set_current_projectile(new/datum/projectile/laser/light)
		projectiles = list(current_projectile)
		cell = new/obj/item/ammo/power_cell/empty
		..()

/obj/item/gun/moddable/base/energy/emp
	name = "EMP Energy Gun" //change me
	desc = "An energy gun, firing EMP blasts."
	flags = GP_ENERGY | ONBELT | TABLEPASS | CONDUCT | FPRINT | USEDELAY | EXTRADELAY

	New()
		set_current_projectile(new/datum/projectile/energy_bolt/electromagnetic_pulse)
		projectiles = list(current_projectile)
		cell = new/obj/item/ammo/power_cell/empty
		..()

/obj/item/gun/moddable/attachment
	name = "Generic Attachment"
	desc = "You shouldn't see me!"
	//icon = 'icons/obj/items/attachment.dmi'
	icon = 'icons/obj/items/gun.dmi'

/obj/item/gun/moddable/attachment/kinetic
	name = "Kinetic Conversion Kit"
	desc = "Converts a gun frame into a kinetic weapon."
	icon_state = "derringer" //change me
	flags = GP_TYPE | ONBELT | TABLEPASS | CONDUCT

/obj/item/gun/moddable/attachment/energy
	name = "Energy Conversion Kit"
	desc = "Converts a gun frame into an energy weapon."
	icon_state = "derringer" //change me
	flags = GP_TYPE | ONBELT | TABLEPASS | CONDUCT

/obj/item/gun/moddable/attachment/ammo22
	name = ".22 LR Reciever"
	desc = "Converts a kinetic frame to .22 caliber."
	icon_state = "derringer" //change me
	flags = GP_AMMO | ONBELT | TABLEPASS | CONDUCT

/obj/item/gun/moddable/attachment/ammo308
	name = ".308 Winchester Reciever"
	desc = "Converts a kinetic frame to .308 caliber."
	icon_state = "derringer" //change me
	flags = GP_AMMO | ONBELT | TABLEPASS | CONDUCT

/obj/item/gun/moddable/attachment/ammo556
	name = "5.56 NATO Reciever"
	desc = "Converts a kinetic frame into firing 5.56."
	icon_state = "derringer" //change me
	flags = GP_AMMO | ONBELT | TABLEPASS | CONDUCT

/obj/item/gun/moddable/attachment/ammo762
	name = "7.62 NATO Reciever"
	desc = "Converts a kinetic frame into firing 7.62."
	icon_state = "derringer" //change me
	flags = GP_AMMO | ONBELT | TABLEPASS | CONDUCT

/obj/item/gun/moddable/attachment/ammo357
	name = ".357 Magnum Reciever"
	desc = "Converts a kinetic frame to .357 caliber."
	icon_state = "derringer" //change me
	flags = GP_AMMO | ONBELT | TABLEPASS | CONDUCT

/obj/item/gun/moddable/attachment/ammo50
	name = ".50 AE Reciever"
	desc = "Converts a kinetic frame to .50 caliber."
	icon_state = "derringer" //change me
	flags = GP_AMMO | ONBELT | TABLEPASS | CONDUCT

/obj/item/gun/moddable/attachment/ammo12ga
	name = "12 Gauge Reciever"
	desc = "Converts a kinetic frame to 12 gauge."
	icon_state = "derringer" //change me
	flags = GP_AMMO | ONBELT | TABLEPASS | CONDUCT

/obj/item/gun/moddable/attachment/energystun
	name = "Energy Stun Reciever"
	desc = "Converts an energy frame to fire taser bolts."
	icon_state = "derringer" //change me
	flags = GP_E_AMMO | ONBELT | TABLEPASS | CONDUCT

/obj/item/gun/moddable/attachment/energylaser
	name = "Energy Laser Reciever"
	desc = "Converts an energy frame to fire laser bolts."
	icon_state = "derringer" //change me
	flags = GP_E_AMMO | ONBELT | TABLEPASS | CONDUCT

/obj/item/gun/moddable/attachment/energyemp
	name = "Energy EMP Reciever"
	desc = "Converts an energy frame to fire EMP lasers."
	icon_state = "derringer" //change me
	flags = GP_E_AMMO | ONBELT | TABLEPASS | CONDUCT
