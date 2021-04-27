

/datum/game_mode/infiltrator
	name = "infiltrator"
	config_tag = "infiltrator"
	shuttle_available = 1
	var/agent_number = 1
	var/list/datum/mind/infiltrators = list()
	var/agent_radiofreq = 0 //:h for syndies, randomized per round
	var/infiltratorlist = list()
	var/const/agents_possible = 5 // Changed it back to 5 for balance reasons of RP and infils
	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)
	var/token_players_assigned = 0

	do_antag_random_spawns = 0

/datum/game_mode/infiltrator/announce()
	boutput(world, "<B>The current game mode is - Syndicate Infiltrators!</B>")
	boutput(world, "<B>[infiltrator_name()] operatives are approaching [station_name(1)]! They intend to execute their objectives on the [station_or_ship()].</B>")

/datum/game_mode/infiltrator/pre_setup()
	var/list/possible_infiltrators = list()

	if (!landmarks[LANDMARK_SYNDICATE])
		boutput(world, "<span class='alert'><b>ERROR: couldn't find spawn (LANDMARK_SYNDICATE), aborting infil round pre-setup.</b></span>")
		return 0

	var/num_players = 0
	for(var/client/C)
		var/mob/new_player/player = C.mob
		if (!istype(player)) continue

		if (player.ready)
			num_players++
	var/num_infil = max(1, min(round(num_players / 4), agents_possible))

	possible_infiltrators = get_possible_infiltrators(num_infil)

	if (!islist(possible_infiltrators) || possible_infiltrators.len < 1)
		boutput(world, "<span class='alert'><b>ERROR: couldn't assign any players as syndicate infiltrators, aborting infil round pre-setup.</b></span>")
		return 0

	token_players = antag_token_list()
	for (var/datum/mind/tplayer in token_players)
		if (!token_players.len)
			break
		infiltrators += tplayer
		token_players.Remove(tplayer)
		num_infil--
		num_infil = max(num_infil, 0)
		logTheThing("admin", tplayer.current, null, "successfully redeemed an antag token.")
		message_admins("[key_name(tplayer.current)] successfully redeemed an antag token.")

	var/list/chosen_infiltrators = antagWeighter.choose(pool = possible_infiltrators, role = "infiltrator", amount = num_infil, recordChosen = 1)
	infiltrators |= chosen_infiltrators
	traitors |= chosen_infiltrators
	infiltratorlist = infiltrators
	for (var/datum/mind/infiltrator in traitors)
		infiltrator.assigned_role = "MODE" //So they aren't chosen for other jobs.
		infiltrator.special_role = "infiltrator"
		possible_infiltrators.Remove(infiltrator)

	agent_radiofreq = random_radio_frequency()

	return 1

/datum/game_mode/infiltrator/post_setup()
	var/leader_title = pick("Czar", "Boss", "Commander", "Chief", "Kingpin", "Director", "Overlord", "General", "Warlord", "Commissar")
	var/leader_selected = 0

	var/list/callsign_pool_keys = list("nato", "melee_weapons", "colors", "birds", "mammals", "moons")
	//Alphabetical agent callsign lists are delcared here, seperated in to catagories.
	var/list/callsign_list = strings("agent_callsigns.txt", pick(callsign_pool_keys))

	var/pickedHighValue1 = pick(typesof(/datum/objective/specialist/infiltrator/stealhighvalue))
	var/pickedHighValue2 = pick(typesof(/datum/objective/specialist/infiltrator/stealhighvalue))
	var/pickedHighValue3 = pick(typesof(/datum/objective/specialist/infiltrator/stealhighvalue))
	var/pickedKidnap = pick(typesof(/datum/objective/specialist/infiltrator/kidnaphead))
	var/pickedFortify = pick(typesof(/datum/objective/specialist/infiltrator/fortify))
	var/makeSilicon = /datum/objective/specialist/infiltrator/makesilicon
#ifdef MAP_OVERRIDE_MANTA
	var/pickedHighValue4Manta = pick(typesof(/datum/objective/specialist/infiltrator/stealhighvalue))
	var/pickedHighValue5Manta = pick(typesof(/datum/objective/specialist/infiltrator/stealhighvalue))
#endif
	var/bigObjective = pick(list(pickedKidnap, pickedFortify, makeSilicon))
//	var/pickedBigObjective = pick(bigObjective)
	var/assassinateImportant = pick(list(/datum/objective/specialist/infiltrator/assassinatecaptain,/datum/objective/specialist/infiltrator/assassinatehos))
//	var/pickedAssassinateImportant = pick(assassinateImportant)
	for(var/datum/mind/synd_mind in infiltrators)
		//bestow_objective(synd_mind,/datum/objective/specialist/infiltrator/assassinatecaptain)
		//bestow_objective(synd_mind,/datum/objective/specialist/infiltrator/assassinatehos)
		ticker.mode.bestow_objective(synd_mind, assassinateImportant)
		ticker.mode.bestow_objective(synd_mind, pickedHighValue1)
		ticker.mode.bestow_objective(synd_mind, pickedHighValue2)
		ticker.mode.bestow_objective(synd_mind, pickedHighValue3)
		ticker.mode.bestow_objective(synd_mind, bigObjective)
#ifdef MAP_OVERRIDE_MANTA
		ticker.mode.bestow_objective(synd_mind, pickedHighValue4Manta)
		ticker.mode.bestow_objective(synd_mind, pickedHighValue5Manta)
#endif

		var/obj_count = 1
		boutput(synd_mind.current, "<span class='notice'>You are a [infiltrator_name()] agent!</span>")
		for(var/datum/objective/objective in synd_mind.objectives)
			boutput(synd_mind.current, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
			obj_count++

		boutput(synd_mind.current, "We a number of objectives that need to be completed discreetly on [station_name(1)].")

		if(!leader_selected)
			synd_mind.current.set_loc(pick_landmark(LANDMARK_SYNDICATE_BOSS))
			if(!synd_mind.current.loc)
				synd_mind.current.set_loc(pick_landmark(LANDMARK_SYNDICATE))
			synd_mind.current.real_name = "[infiltrator_name()] [leader_title]"
			equip_infiltrator(synd_mind.current, 1)
			leader_selected = 1
		else
			synd_mind.current.set_loc(pick_landmark(LANDMARK_SYNDICATE))
			var/callsign = pick(callsign_list)
			synd_mind.current.real_name = "[infiltrator_name()] Operative [callsign]" //new naming scheme
			callsign_list -= callsign
			equip_infiltrator(synd_mind.current, 0)
		boutput(synd_mind.current, "<span class='alert'>Your headset allows you to communicate on the syndicate radio channel by prefacing messages with :h, as (say \":h Agent reporting in!\").</span>")

		synd_mind.current.antagonist_overlay_refresh(1, 0)
		SHOW_INFILTRATOR_TIPS(synd_mind.current)

	for(var/turf/T in landmarks[LANDMARK_SYNDICATE_GEAR_CLOSET])
		new /obj/storage/closet/syndicate/personal(T)
/*	removed these for the sake of a "stealth" team not really needing breaches, leaving them just in case
for(var/turf/T in landmarks[LANDMARK_SYNDICATE_BREACHING_CHARGES])
		for(var/i = 1 to 5)
			new /obj/item/breaching_charge/thermite(T)*/

	SPAWN_DBG (rand(waittime_l, waittime_h))
		send_intercept()

	return

/datum/game_mode/nuclear/check_finished()
	if(emergency_shuttle.location == SHUTTLE_LOC_RETURNED)
		return 1

	if (no_automatic_ending)
		return 0

/datum/game_mode/infiltrator/declare_completion()
	. = ..()

/datum/game_mode/infiltrator/proc/get_possible_infiltrators(minimum_infiltrators=1)
	var/list/candidates = list()

	for(var/client/C)
		var/mob/new_player/player = C.mob
		if (!istype(player)) continue

		if (ishellbanned(player)) continue //No treason for you
		if ((player.ready) && !(player.mind in infiltrators) && !(player.mind in token_players) && !candidates.Find(player.mind))
			if(player.client.preferences.be_infiltrator)
				candidates += player.mind

	if(candidates.len < minimum_infiltrators)
		logTheThing("debug", null, null, "<b>Enemy Assignment</b>: Not enough players with be_infiltrator set to yes, including players who don't want to be infiltrators in the pool.")
		for(var/client/C)
			var/mob/new_player/player = C.mob
			if (!istype(player)) continue
			if (ishellbanned(player)) continue //No treason for you

			if ((player.ready) && !(player.mind in infiltrators) && !(player.mind in token_players) && !candidates.Find(player.mind))
				candidates += player.mind

				if ((minimum_infiltrators > 1) && (candidates.len >= minimum_infiltrators))
					break

	if(candidates.len < 1)
		return list()
	else
		return candidates

/datum/game_mode/infiltrator/send_intercept()
	var/intercepttext = "Cent. Com. Update Requested staus information:<BR>"
	intercepttext += " Cent. Com has recently been contacted by the following syndicate affiliated organisations in your area, please investigate any information you may have:"

	var/list/possible_modes = list()
	possible_modes.Add("revolution", "wizard", "nuke", "traitor", "changeling", "infiltator")
	possible_modes -= "[ticker.mode]"
	var/number = pick(2, 3)
	var/i = 0
	for(i = 0, i < number, i++)
		possible_modes.Remove(pick(possible_modes))
	possible_modes.Insert(rand(possible_modes.len), "[ticker.mode]")

	var/datum/intercept_text/i_text = new /datum/intercept_text
	for(var/A in possible_modes)
		intercepttext += i_text.build(A, pick(ticker.minds))

	for_by_tcl(C, /obj/machinery/communications_dish)
		C.add_centcom_report("Cent. Com. Status Summary", intercepttext)

	command_alert("Summary downloaded and printed out at all communications consoles.", "Enemy communication intercept. Security Level Elevated.")


/datum/game_mode/infiltrator/proc/random_radio_frequency()
	. = 0
	var/list/blacklisted = list(0, 1451, 1457) // The old blacklist was rather incomplete and thus ineffective (Convair880).
	blacklisted.Add(R_FREQ_BLACKLIST)

	do
		. = rand(1352, 1439)

	while (. in blacklisted)

/datum/game_mode/infiltrator/process()
	set background = 1
	..()
	return

var/infiltrator_name = null
/proc/infiltrator_name()
	if (infiltrator_name)
		return infiltrator_name

	var/name = ""

	// Prefix
#if defined(XMAS)
	name += pick("Merry", "Jingle", "Holiday", "Santa", "Gift", "Elf", "Jolly")
#elif defined(HALLOWEEN)
	name += pick("Hell", "Demon", "Blood", "Murder", "Gore", "Grave", "Sin", "Slaughter")
#else
	name += pick("Clandestine", "Prima", "Blue", "Zero-G", "Max", "Blasto", "Waffle", "North", "Omni", "Newton", "Cyber", "Bonk", "Gene", "Gib", "Funk", "Joint")
#endif
	// Suffix
	if (prob(80))
		name += " "

		// Full
		if (prob(60))
			name += pick("Syndicate", "Consortium", "Collective", "Corporation", "Consolidated", "Group", "Holdings", "Biotech", "Industries", "Systems", "Products", "Chemicals", "Enterprises", "Family", "Creations", "International", "Intergalactic", "Interplanetary", "Foundation", "Positronics", "Hive", "Cartel")
		// Broken
		else
			name += pick("Syndi", "Corp", "Bio", "System", "Prod", "Chem", "Inter", "Hive")
			name += pick("", "-")
			name += pick("Tech", "Sun", "Co", "Tek", "X", "Inc", "Code")
	// Small
	else
		name += pick("-", "*", "")
		name += pick("Tech", "Sun", "Co", "Tek", "X", "Inc", "Gen", "Star", "Dyne", "Code", "Hive")

	infiltrator_name = name
	return name

/obj/cairngorm_stats/
	name = "Mission Memorial"
	icon = 'icons/obj/32x64.dmi'
	icon_state = "memorial_mid"
	anchored = 1.0
	opacity = 0
	density = 1



	New()
		..()
		var/wins = world.load_intra_round_value("nukie_win")
		var/losses = world.load_intra_round_value("nukie_loss")
		if(isnull(wins))
			wins = 0
		if(isnull(losses))
			losses = 0
		src.desc = "<center><h2><b>Battlecruiser Cairngorm Mission Memorial</b></h2><br> <h3>Successful missions: [wins]<br>\nUnsuccessful missions: [losses]</h3><br></center>"

	attack_hand(var/mob/user as mob)
		if (..(user))
			return

		var/wins = world.load_intra_round_value("nukie_win")
		var/losses = world.load_intra_round_value("nukie_loss")
		if(isnull(wins))
			wins = 0
		if(isnull(losses))
			losses = 0
		var/dat = ""
		dat += "<center><h2><b>Battlecruiser Cairngorm Mission Memorial</b></h2><br> <h3>Successful missions: [wins]<br>\nUnsuccessful missions: [losses]</h3></center>"

		src.add_dialog(user)
		user.Browse(dat, "title=Mission Memorial;window=cairngorm_stats_[src];size=300x300")
		onclose(user, "cairngorm_stats_[src]")
		return

/obj/cairngorm_stats/left
	icon_state = "memorial_left"

/obj/cairngorm_stats/right
	icon_state = "memorial_right"
