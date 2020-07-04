// HandleDamage event handler for enemy (gov/inv) AIs

_this spawn
{
	params
	[
		"_unit",
		"_part",
		"_damage",
		"_injurer",
		"_projectile",
		"_hitIndex",
		"_instigator",
		"_hitPoint"
	];

	private _groupX = group _unit;

	// Helmet popping
	if (
		(_damage >= 1) && {
		(_hitPoint == "hithead") && {
		(random 100 < helmetLossChance) }}
	) then
	{
		removeHeadgear _unit;
	};

	// Marker "Under attack"
	if (side group _injurer == teamPlayer) then
	{
		// Contact report generation for PvP players
		if (_part == "" && side group _unit == Occupants) then
		{
			// Check if unit is part of a garrison
			private _marker = _unit getVariable ["markerX",""];
			if (_marker != "" && {sidesX getVariable [_marker,sideUnknown] == Occupants}) then
			{
				// Limit last attack var changes and task updates to once per 30 seconds
				private _lastAttackTime = garrison getVariable [_marker + "_lastAttack", -30];
				if (_lastAttackTime + 30 < serverTime) then {
					garrison setVariable [_marker + "_lastAttack", serverTime, true];
					[_marker, teamPlayer, side group _unit] remoteExec ["A3A_fnc_underAttack", 2];
				};
			};
		};
	};
};

if (hasACEMedical) exitWith {};

params
[
	"_unit",
	"_part",
	"_damage",
	"_injurer",
	"_projectile",
	"_hitIndex",
	"_instigator",
	"_hitPoint"
];

private _makeUnconscious =
{
	params ["_unit", "_injurer"];

	_unit setVariable ["incapacitated", true, true];
	_unit setUnconscious true;

	if (vehicle _unit != _unit) then
	{
		moveOut _unit;
	};

	if (isPlayer _unit) then
	{
		_unit allowDamage false;
	};

	[_unit, _injurer] spawn A3A_fnc_unconsciousAAF;
};

if (side _injurer == teamPlayer) then
{
	if (_part == "") then
	{
		if (_damage >= 1) then
		{
			if (!(_unit getVariable ["incapacitated",false])) then
			{
				_damage = 0.9;
				[_unit, _injurer] call _makeUnconscious;
			}
			else
			{
				// already unconscious, check whether we're pushed into death
				_overall = (_unit getVariable ["overallDamage",0]) + (_damage - 1);
				if (_overall > 0.5) then
				{
					_unit removeAllEventHandlers "HandleDamage";
				}
				else
				{
					_unit setVariable ["overallDamage",_overall];
					_damage = 0.9;
				};
			};
		}
		else
		{

            //Abort helping if hit too hard
			if (_damage > 0.25) then
			{
				if (_unit getVariable ["helping", false]) then
				{
					_unit setVariable ["cancelRevive", true];
				};
			};
		};
	}
	else
	{
		if (_damage >= 1) then
		{
			if !(_part in ["arms", "hands", "legs"]) then
			{
				_damage = 0.9;
				// Don't trigger unconsciousness on sub-part hits (face/pelvis etc), only the container
				if (_part in ["head","body"]) then
				{
					if !(_unit getVariable ["incapacitated",false]) then
					{
						[_unit, _injurer] call _makeUnconscious;
					};
				};
			};
		};
	};
};
