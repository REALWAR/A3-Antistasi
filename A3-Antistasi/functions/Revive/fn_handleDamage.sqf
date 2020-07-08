// HandleDamage event handler for rebels and PvP players

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

	// Helmet popping
	if (
		(_damage >= 1) && {
		(_hitPoint == "hithead") && {
		(random 100 < helmetLossChance) }}
	)
	then { removeHeadgear _unit; };

	// Contact report generation for rebels
	if ((side group _injurer == Occupants) || {
		(side group _injurer == Invaders) })
	then
	{
		// Check if unit is part of a rebel garrison
		private _marker = _unit getVariable ["markerX", ""];

		if ((_marker != "") && {
			(sidesX getVariable [_marker, sideUnknown] == teamPlayer) })
		then
		{
			// Limit last attack var changes and task updates to once per 30 seconds
			private _lastAttackTime = garrison getVariable [_marker + "_lastAttack", -30];

			if (_lastAttackTime + 30 < serverTime)
			then
			{
				garrison setVariable [_marker + "_lastAttack", serverTime, true];
				[_marker, side group _injurer, side group _unit] remoteExec ["A3A_fnc_underAttack", 2];
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

	if (vehicle _unit != _unit) then { moveOut _unit; };
	if (isPlayer _unit) then { _unit allowDamage false; };

	private _fromside = if (!isNull _injurer) then {side group _injurer} else {sideUnknown};
	null = [_unit, _fromside] spawn A3A_fnc_unconscious;
};

if (_part == "")
then
{
	if (_damage >= 1)
	then
	{
		if (side _injurer == civilian)
		then
		{
			// apparently civilians are non-lethal
			_damage = 0.9;
		}
		else
		{
			if !(_unit getVariable ["incapacitated", false])
			then
			{
				_damage = 0.9;
				null = [_unit, _injurer] call _makeUnconscious;
			}
			else
			{
				// already unconscious, check whether we're pushed into death
				_overall = (_unit getVariable ["overallDamage", 0]) + (_damage - 1);
				if (_overall > 1)
				then
				{
					if (isPlayer _unit)
					then
					{
						_damage = 0;
						null = [_unit] spawn A3A_fnc_respawn;
					}
					else { _unit removeAllEventHandlers "HandleDamage"; };
				}
				else
				{
					_unit setVariable ["overallDamage", _overall];
					_damage = 0.9;
				};
			};
		};
	}
	else
	{
		if (_damage > 0.25)
		then
		{
			if (_unit getVariable ["helping", false])
			then { _unit setVariable ["cancelRevive", true]; };

			if (isPlayer (leader group _unit))
			then
			{
				if (autoheal)
				then
				{
					_helped = _unit getVariable ["helped", objNull];

					if (isNull _helped) then { null = [_unit] call A3A_fnc_askHelp; };
				};
			};
		};
	};
}
else
{
	if ((_damage >= 1) && {
		!(_part in ["arms", "hands", "legs"]) })
	then
	{
		_damage = 0.9;

		if ((_part in ["head", "body"]) && {
			!(_unit getVariable ["incapacitated", false]) })
		then { [_unit, _injurer] call _makeUnconscious; };
	};
};

_damage
