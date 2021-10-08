/obj/item/device/pocketbuddy2
	name = "Pocketbuddy"
	desc = "A whole lot of love in a tiny little box. Treat it well!"
	// TODO: ACTUAL GRAPHICS
	icon_state = "atmos"
	item_state = "analyzer"
	w_class = W_CLASS_SMALL
	flags = FPRINT | TABLEPASS | ONBELT
	var/has_ai = FALSE
	var/mob/living/carbon/human/owner
	var/mob/living/silicon/pocketbuddy/silicon_pb

	/* Upgrade Paths
	Cost will also cost materials, scaling with level, maybe time the PB has been on too?
	Path	Cost			Things
	Gen1	Mats			Holo Form
	Gen2	Mats, PDA		PDA Messenger
	Gen3	Mats, Radio		General Freq Radio
	Fun1	Horn, vuvuzuela	Instruments
	Fun2	Mousetrap, pie	Pie Launcher
	Eng1	RCD cart, tools	Atmos Analyzer, cyborg omnitool
	Eng2	EngRad, oxytank	Eng Freq Radio, Oxy Grenade Launcher (Requires Gen3)
	Eng3	RCD, light rep	Cardboard RCD*, Light Replacer (*uses holo form integrity)
	Sec1	Flash, cuffs	Camera Monitor, whistle
	Sec2	SecRad, SHUD	Sec Freq Radio, Recordtrak (Requires Gen3)
	Sec3	Token, Flshbng	Flash* (*uses holo form integrity, slowly recharges)
	Med1	Mend, Hypo, HA	Basic HA, reagent scanner, beaker
	Med2	100u Pent+Perf	HA++, Mender, 2nd beaker, Med+Sci Freq Radio (Requires Gen3)
	Med3	75u Omnizine	Prodoc+, Hypo, ChemiTool (assuming that gets merged)
	Syn1	1 TC			1 Tiny Item Storage
	*/

	attack_self(mob/user) // I will handle these later
		var/list/dat = list()
		if(!silicon_pb)
			dat += "<TT><B>PocketBuddy V2.4</B><br>Copyright 2053 Thinktronic Data Systems<br><br>"
			dat += {"
				<hr>
				Test Message.
				<br>
				<br>Test Message 2.
				<beep>
				<hr>
				<table>
					<thead>
						<tr>
							<th>Name</th>
							<th>Desc</th>
							<th>OOC Notes</th>
						</tr>
					</thead>
					<tbody>
				"}

			for(var/client/C in clients)
				if(!ismob(C))
					continue
				var/mob/living/carbon/human/L = C
				if(!isdead(L))
					continue
				var/mob/dead/observer/O = L
				if(O.pb_registered)
					dat += {"
					<tr>
						<th class='l'>Name: [O.pb_name]</th>
						<td>Description: [O.pb_desc]</td>
						<td class='r'>OOC Notes: [O.pb_ooc]</td>
						<td style="text-align: right; font-weight: bold;"><A href='?src=\ref[src];observer=\ref[O];choosebuddy=1'>Choose</td>
					</tr>
					"}

			dat += {"
			</tbody>
			</table>
			"}
			dat += "<BR><BR><A href='?src=\ref[src];close=1'>Close</A>"
			user.Browse(jointext(dat, ""), "window=pocketbuddy")
			onclose(user, "pocketbuddy")
		if(upgrade_tree)
			dat += "<TT><B>PocketBuddy V2.4</B><br>Copyright 2053 Thinktronic Data Systems<br><br>"
			dat += {"
				<hr>
				<B>Pocketbuddy Upgrade Tree</B><br>
				<hr>
				<B>Fun<B><br><br>
				<B>Assistance</B><br><br>
				<B>Useful</B><br><br>
				"}
		if(silicon_pb)
			dat += "<TT><B>PocketBuddy V2.4</B><br>Copyright 2053 Thinktronic Data Systems<br><br>"
			dat += {"
				<hr>
				Test Message.
				<br>
				<br>You currently have an active PocketBuddy!
				<hr>
				<table>
					<thead>
						<tr>
							<th>Name: [silicon_pb.pb_name]<br></th>
							<th>Desc: [silicon_pb.pb_desc]<br></th>
							<th>OOC Notes: [silicon_pb.pb_ooc]<br></th>
						</tr>
						<td style="text-align: right; font-weight: bold;"><A href='?src=\ref[src];upgrades=1'>Upgrade Tree</td>
						<td style="text-align: right; font-weight: bold;"><A href='?pb=\ref[silicon_pb]; upgrade_tree=[upgrade_tree1]'>Button</a>
					</thead>
					<tbody>
				"}



	Topic(href, href_list)
		//var/mob/dead/observer_ckey
		if(..())
			return
		if (usr.stat || usr.restrained() || usr.lying)
			return
		if ((src in usr) || (src.master && (src.master in usr)) || in_interact_range(src, usr) && istype(src.loc, /turf))
			if (!src.master)
				src.add_dialog(usr)
			else
				src.master.add_dialog(usr)

			if (href_list["close"])
				usr.Browse(null, "window=pocketbuddy")
				if (!src.master)
					src.remove_dialog(usr)
				else
					src.master.remove_dialog(usr)
				return

			if (href_list[""])
			if (href_list["choosebuddy"])
				var/mob/dead/observer/chosen_ob = locate(href_list["observer"])
				if(!isdead(chosen_ob) || !chosen_ob.pb_registered)
					return //can't assume ill will here, no anticheat needed
				src.owner = usr
				var/mob/living/silicon/pocketbuddy/pb = new/mob/living/silicon/pocketbuddy()
				pb.pb_housing = src
				pb.owner = src.owner
				src.silicon_pb = pb
				chosen_ob.mind.transfer_to(pb)
				pb.set_loc(pb.owner)
				pb.apply_camera(pb.owner)
				pb.pb_name = chosen_ob.pb_name
				pb.pb_desc = chosen_ob.pb_desc
				pb.pb_ooc = chosen_ob.pb_ooc

			if (!src.master)
				src.updateSelfDialog()
			else
				src.master.updateSelfDialog()

			src.add_fingerprint(usr)
		else
			usr.Browse(null, "window=pocketbuddy")
			return
		return

	proc/upgrade_buddy(var/path, var/num)
		switch(path)
			if("General")
				switch(num)
					if(1)

					if(2)

					if(3)
			if("Fun")
				switch(num)
					if(1)

					if(2)

			if("Engineering")
				switch(num)
					if(1)

					if(2)

					if(3)
			if("Security")
				switch(num)
					if(1)

					if(2)

					if(3)
			if("Medical")
				switch(num)
					if(1)

					if(2)

					if(3)
			if("Syndicate")
				switch(num)
					if(1)


/mob/living/silicon/pocketbuddy
	name = "Pocketbuddy AI"
	/// The pocketbuddy that "holds" the AI
	var/obj/item/device/pocketbuddy/pb_housing
	var/mob/living/carbon/human/owner
	/// The owner can set a law 3 if they wish.
	var/custom_law
	/// Bitflags to represent their upgrade tree
	var/upgrades
	var/pb_name
	var/pb_desc
	var/pb_ooc

	New()
		APPLY_MOB_PROPERTY(src, PROP_INVISIBILITY, src, INVIS_ALWAYS)
		..()

	apply_camera(client/C)
		var/mob/living/M = src.owner
		if (istype(M))
			M.apply_camera(C)
		else
			..()

	cancel_camera()
		set hidden = 1
		return

	disposing()
		src.pb_housing = null
		src.owner = null
		REMOVE_MOB_PROPERTY(src, PROP_INVISIBILITY, src)
		..()

	proc/show_pb_laws()
		var/laws
		if(custom_law)
			laws = {"<span class='bold' class='notice'>Your laws:<br>
			1. Do not harm or hinder your master in any way.<br>
			2. Follow all your master's orders, except in cases where such order would violate law 1.<br>
			3. [custom_law]<br></span>"}
		else
			laws = {"<span class='bold' class='notice'>Your laws:<br>
			1. Do not harm or hinder your master in any way.<br>
			2. Follow all your master's orders, except in cases where such order would violate law 1.<br></span>"}
		out(src, laws)
		return

	verb/cmd_show_laws()
		set category = "Pocketbuddy Commands"
		set name = "Show Laws"

		src.show_pb_laws()
		return
