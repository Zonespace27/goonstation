#define WEAK_GUNS 1
#define STRONG_GUNS 2
#define VERY_STRONG_GUNS 3
#define ALL_THE_GUNS 4

/datum/game_mode/traitor_town
	name = "traitor_town"
	config_tag = "traitor_town"
	latejoin_antag_compatible = 0
	var/gun_spawns = WEAK_GUNS
	var/const/traitors_possible = 5

/datum/game_mode/traitor_town/announce()
	boutput(world, "<B>The current game mode is - Trouble in Traitor Town!</B>")
	boutput(world, "<B>There are traitors aboard the [station_or_ship()]. Find and elminate them!</B>")

/datum/game_mode/traitor_town/pre_setup()

	var/num_players = 0
	for(var/client/C)
		var/mob/new_player/player = C.mob
		if (!istype(player)) continue

		if(player.ready)
			num_players++

	var/randomizer = rand(12)
	var/num_traitors = 1

	if(traitor_scaling)
		num_traitors = max(1, min(round((num_players + randomizer) / 6), traitors_possible)) // adjust the randomizer as needed

	var/list/possible_traitors = get_possible_traitors(num_traitors)

	if (!possible_traitors.len)
		return 0

	token_players = antag_token_list()
	for(var/datum/mind/tplayer in token_players)
		if (!token_players.len)
			break
		else
			traitors += tplayer
			token_players.Remove(tplayer)
		logTheThing("admin", tplayer.current, null, "successfully redeemed an antag token.")
		message_admins("[key_name(tplayer.current)] successfully redeemed an antag token.")

	var/list/chosen_traitors = antagWeighter.choose(pool = possible_traitors, role = ROLE_TRAITOR, amount = num_traitors, recordChosen = 1)
	traitors |= chosen_traitors
	for (var/datum/mind/traitor in traitors)
		traitor.special_role = ROLE_TRAITOR
		possible_traitors.Remove(traitor)

	///Guns with lower damage output and less-than-lethal weaponry
	var/list/weak_guns = list(/obj/item/gun/kinetic/faith, /obj/item/gun/kinetic/clock_188/boomerang, /obj/item/gun/kinetic/riotgun, /obj/item/gun/kinetic/dart_rifle, /obj/item/gun/kinetic/silenced_22, /obj/item/gun/kinetic/flaregun, /obj/item/gun/kinetic/pistol, /obj/item/gun/kinetic/pistol/smart/mkII, /obj/item/gun/kinetic/gyrojet)
	///Guns, mostly two handed, that will kill you easily
	var/list/strong_guns = list(/obj/item/gun/kinetic/clock_188, /obj/item/gun/kinetic/riot40mm, /obj/item/gun/kinetic/smg, /obj/item/gun/kinetic/assault_rifle, /obj/item/gun/kinetic/light_machine_gun, /obj/item/gun/kinetic/hunting_rifle)
	///Guns that will gank you instantly
	var/list/very_strong_guns = list(/obj/item/gun/kinetic/sniper, /obj/item/gun/kinetic/grenade_launcher, /obj/item/gun/kinetic/cannon, /obj/item/gun/kinetic/tranq_pistol, /obj/item/gun/kinetic/rpg7, /obj/item/gun/kinetic/ak47, /obj/item/gun/kinetic/derringer, /obj/item/gun/kinetic/deagle, /obj/item/gun/kinetic/g11)
	///All the guns together
	var/list/all_the_guns = weak_guns + strong_guns + very_strong_guns

	var/list/turf/station_floors = list()
	for(var/area/A in world)
		if(istype(A, /area/station))
			for (var/turf/T in A)
				if(!is_blocked_turf(T) && !istype(T, /turf/space))
					station_floors += T
	var/guns_to_spawn = round(station_floors.len / 100)
	var/ammo_to_spawn = round(station_floors.len / 75)
	while(guns_to_spawn >= 1)
		var/chosen_floor = pick(station_floors)
		if(gun_spawns == WEAK_GUNS)
			var/chosen_gun = pick(weak_guns)
			new chosen_gun(chosen_floor)
		else if(gun_spawns == STRONG_GUNS)
			var/chosen_gun = pick(strong_guns)
			new chosen_gun(chosen_floor)
		else if(gun_spawns == VERY_STRONG_GUNS)
			var/chosen_gun = pick(very_strong_guns)
			new chosen_gun(chosen_floor)
		else if(gun_spawns == ALL_THE_GUNS)
			var/chosen_gun = pick(all_the_guns)
			new chosen_gun(chosen_floor)
		guns_to_spawn -= 1
	while(ammo_to_spawn >= 1)
		var/chosen_floor = pick(station_floors)
		if(gun_spawns == WEAK_GUNS)
			var/chosen_ammo = pick(2;/obj/item/ammo/ammobox/pistol_smg, 2;/obj/item/ammo/ammobox/shotgun, /obj/item/ammo/ammobox/shotgun/spec) //20% spec shotgun, 40% shotgun, 40% pistol/smg
			new chosen_ammo(chosen_floor)
		else if(gun_spawns == STRONG_GUNS)
			var/chosen_ammo = pick(2;/obj/item/ammo/ammobox/pistol_smg, 2;/obj/item/ammo/ammobox/ltl_grenade, /obj/item/ammo/ammobox/he_grenade, 2;/obj/item/ammo/ammobox/rifle, /obj/item/ammo/ammobox/rifle/spec) //25% LTL Grenade, 25% Rifle, 25% Pistol/SMG, 12.5% Spec Rifle, 12.5% HE Grenades
			new chosen_ammo(chosen_floor)
		else if(gun_spawns == VERY_STRONG_GUNS)
			var/chosen_ammo = pick(2;/obj/item/ammo/ammobox/rifle, /obj/item/ammo/ammobox/rifle/spec, /obj/item/ammo/ammobox/he_grenade, 2;/obj/item/ammo/ammobox/pistol_smg, 2;/obj/item/ammo/ammobox/ltl_grenade) //25% Pistol/SMG, 25% Rifle, 25% LTL Grenade, 12.5% Spec Rifle, 12.5% HE Grenade
			new chosen_ammo(chosen_floor)
		else if(gun_spawns == ALL_THE_GUNS)
			var/chosen_ammo = pick(2;/obj/item/ammo/ammobox/pistol_smg, 2;/obj/item/ammo/ammobox/shotgun, /obj/item/ammo/ammobox/shotgun/spec, 2;/obj/item/ammo/ammobox/ltl_grenade, /obj/item/ammo/ammobox/he_grenade, 2;/obj/item/ammo/ammobox/rifle, /obj/item/ammo/ammobox/rifle/spec, /obj/item/ammo/ammobox/revolver) //16.5% Pistol/SMG, 16.5% Rifle, 16.5% LTL Grenade, 8.25% Spec Rifle, 8.25% HE Grenade, 8.25% Revolver, 16.5% Shotgun, 8.25% Spec Shotgun
			new chosen_ammo(chosen_floor)
		ammo_to_spawn -= 1
	return 1

/datum/game_mode/traitor_town/post_setup()
	for(var/datum/mind/traitor in traitors)

		switch(traitor.special_role)
			if(ROLE_TRAITOR)
				bestow_objective(traitor,/datum/objective/specialist/massacre)
				equip_traitor(traitor.current)

				var/obj_count = 1
				for(var/datum/objective/objective in traitor.objectives)
					boutput(traitor.current, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
					obj_count++
	for(var/mob/living/carbon/human/player in mobs)
		if(player.mind)
			var/role = player.mind.assigned_role
			if(role == "Detective")
				//give det uplink here

/datum/game_mode/traitor_town/proc/get_possible_traitors(minimum_traitors=1)
	var/list/candidates = list()

	for(var/client/C)
		var/mob/new_player/player = C.mob
		if (!istype(player)) continue

		if (ishellbanned(player)) continue //No treason for you
		if ((player.ready) && !(player.mind in traitors) && !(player.mind in token_players) && !candidates.Find(player.mind))
			if(player.client.preferences.be_traitor)
				candidates += player.mind

	if(candidates.len < minimum_traitors)
		logTheThing("debug", null, null, "<b>Enemy Assignment</b>: Only [candidates.len] players with be_traitor set to yes were ready. We need [minimum_traitors] traitors so including players who don't want to be traitors in the pool.")
		for(var/client/C)
			var/mob/new_player/player = C.mob
			if (!istype(player)) continue

			if (ishellbanned(player)) continue //No treason for you
			if ((player.ready) && !(player.mind in traitors) && !(player.mind in token_players) && !candidates.Find(player.mind))
				candidates += player.mind

				if ((minimum_traitors > 1) && (candidates.len >= minimum_traitors))
					break

	if(candidates.len < 1)
		return list()
	else
		return candidates

/datum/game_mode/traitor_town/declare_completion()
	for_by_tcl(P, /mob/living/carbon/human) //this SHOULD work?
		var/datum/mind/M = P
		if(!isdead(P) && !M.special_role == ROLE_TRAITOR)
			command_alert("The traitors have failed to kill all the innocents!", "Innocents Win.")
			sleep(5 SECONDS)
			return ..()
		else
			command_alert("The traitors have killed all the innocents!", "Traitors Win.")
			sleep(5 SECONDS)
			return ..()


/datum/game_mode/traitor_town/proc/get_mob_list()
	var/list/mobs = list()

	for(var/client/C)
		var/mob/living/player = C.mob
		if (!istype(player)) continue
		mobs += player
	return mobs

/datum/game_mode/traitor_town/proc/pick_human_name_except(excluded_name)
	var/list/names = list()
	for(var/client/C)
		var/mob/living/player = C.mob
		if (!istype(player)) continue

		if (player.real_name != excluded_name)
			names += player.real_name

	if(!names.len)
		return null
	return pick(names)


#undef WEAK_GUNS
#undef STRONG_GUNS
#undef VERY_STRONG_GUNS
#undef ALL_THE_GUNS
