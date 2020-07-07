private _fileName = "fn_initPetros";
[2, "initPetros started", _fileName] call A3A_fnc_log;
scriptName "fn_initPetros";

removeHeadgear petros;
removeGoggles petros;
petros setSkill 1;
petros setVariable ["respawning", false];
petros allowDamage false;

[petros, unlockedRifles] call A3A_fnc_randomRifle;
petros selectWeapon (primaryWeapon petros);
[petros] call A3A_fnc_punishment_FF_addEH;

petros addEventHandler
[
	"HandleDamage",
	{
		params
		[
			"_unit",
			"_selection",
			"_damage",
			"_source",
			"_projectile",
			"_hitIndex",
			"_instigator",
			"_hitPoint"
		];

		if (isPlayer _source)
		then { _damage = _unit getHitPointDamage _hitPoint; };

		if ((isNull _source) || {_source == petros})
		then { _damage = 0; };

		if (_selection != "") exitWith { _damage };

		if (_damage > 1)
		then
		{
			if (!(petros getVariable ["incapacitated", false]))
			then
			{
				petros setVariable ["incapacitated", true, true];
				_damage = 0.9;

				if (!isNull _source)
				then { [petros, side _source] spawn A3A_fnc_unconscious; }
				else { [petros, sideUnknown] spawn A3A_fnc_unconscious; };
			}
			else
			{
				_overall = (petros getVariable ["overallDamage", 0]) + (_damage - 1);

				if (_overall > 1)
				then { petros removeAllEventHandlers "HandleDamage"; }
				else
				{
					petros setVariable ["overallDamage", _overall];
					_damage = 0.9;
				};
			};
		};

		_damage
	}
];

petros addMPEventHandler [
	"mpkilled",
	{
		null = _this spawn
		{
			removeAllActions petros;
			private _killer = _this #1;

			if !(isServer) exitWith {};

			if ((side _killer == Invaders) || {
				(side _killer == Occupants) && {
				!(isPlayer _killer) && {
				!(isNull _killer) }}})
			then
			{
				[] spawn
				{
					garrison setVariable ["Synd_HQ", [], true];
					_hrT = server getVariable "hr";
					_resourcesFIAT = server getVariable "resourcesFIA";
					[-1*(round(_hrT*0.9)), -1*(round(_resourcesFIAT*0.9))] remoteExec ["A3A_fnc_resourcesFIA", 2];
					waitUntil {count allPlayers > 0};

					if (!isNull theBoss)
					then { [] remoteExec ["A3A_fnc_placementSelection", theBoss]; }
					else
					{
						private _playersWithRank =
							(call A3A_fnc_playableUnits)
							select {(side (group _x) == teamPlayer) && {
									(isPlayer _x) && {
									(_x == _x getVariable ["owner", _x]) }}}
							apply { [([_x] call A3A_fnc_numericRank) #0, _x] };
						_playersWithRank sort false;

						[] remoteExec ["A3A_fnc_placementSelection", _playersWithRank #0 #1];
					};
				};

				{
					if (side _x == Occupants) then { _x setPos (getMarkerPos respawnOccupants); };
				} forEach (call A3A_fnc_playableUnits);
			}
			else { [] call A3A_fnc_createPetros; };
		};
	}
];

[] spawn {sleep 120; petros allowDamage true;};

private _removeProblematicAceInteractions = {
	null = _this spawn
	{
		//Wait until we've got hasACE initialised fully
		waitUntil {!isNil "initVar"};
		//Disable ACE Interactions

		if (hasInterface && { hasACE })
		then
		{
			[typeOf _this, 0, ["ACE_ApplyHandcuffs"]] call ace_interact_menu_fnc_removeActionFromClass;
			[typeOf _this, 0, ["ACE_MainActions", "ACE_JoinGroup"]] call ace_interact_menu_fnc_removeActionFromClass;
		};
	};
};

//We're doing it per-init of petros, because the type of petros on respawn might be different to initial type.
//This'll prevent it breaking in the future.
[petros, _removeProblematicAceInteractions] remoteExec ["call", 0, petros];

[2, "initPetros completed", _fileName] call A3A_fnc_log;
