params ["_unit"];

_unit setSkill 0;
_unit forceAddUniform (selectRandom allCivilianUniforms);
_unit disableAI "TARGET";
_unit disableAI "AUTOTARGET";
//Stops civilians from shouting out commands.
[_unit, "NoVoice"] remoteExec ["setSpeaker", 0, _unit];

_unit addEventHandler
[
	"HandleDamage",
	{
		params
		[
			"_unit",
			"_hitSelection",
			"_damage",
			"_source",
			"_projectile"
		];

		if (!(isNil "_source") && {
			(isPlayer _source) })
		then
		{
			_unit setVariable ["injuredByPlayer", _source, true];
			_unit setVariable ["lastInjuredByPlayer", time, true];
		};

		if ((projectile == "") && {
			(_damage > 0.95) && {
			!(isPlayer _source) }})
		then { _damage = 0.9; };

		_damage
	}
];

_unit addEventHandler
[
	"killed",
	{
		null = _this spawn
		{
			params ["_unit", "_killer"];

			if (time - (_unit getVariable ["lastInjuredByPlayer", 0]) < 120)
			then { _killer = _unit getVariable ["injuredByPlayer", _killer]; };

			if (isNull _killer)
			then { _killer	= _unit; };

			if (_unit == _killer)
			then { _nul = [-1, -1, getPos _unit] remoteExec ["A3A_fnc_citySupportChange", 2]; }
			else
			{
				if (isPlayer _killer)
				then
				{
					if (typeOf _unit == "C_man_w_worker_F")
					then { _killer addRating 1000; };

					[-10, _killer] call A3A_fnc_playerScoreAdd;
				};

				_multiplier = 1;

				if (typeOf _unit == "C_journalist_F")
				then { _multiplier = 3 };
				//Must be group, in case they're undercover.

				if (side group _killer == teamPlayer)
				then
				{
					[
						3,
						"Rebels killed a civilian",
						"aggroEvent",
						true
					] call A3A_fnc_log;

					[[10 * _multiplier, 60], [0, 0]] remoteExec ["A3A_fnc_prestige", 2];
					[1, 0, getPos _unit] remoteExec ["A3A_fnc_citySupportChange", 2];
				}
				else
				{
					if (side group _killer == Occupants)
					then
					{
						[[-5 * _multiplier, 60], [0, 0]] remoteExec ["A3A_fnc_prestige", 2];
						[0, 1, getPos _unit] remoteExec ["A3A_fnc_citySupportChange", 2];
					}
					else
					{
						if (side group _killer == Invaders)
						then { [-1, 1, getPos _unit] remoteExec ["A3A_fnc_citySupportChange", 2]; };
					};
				};
			};
		};
	}
];
