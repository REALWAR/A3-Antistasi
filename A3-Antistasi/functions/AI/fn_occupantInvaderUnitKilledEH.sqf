params ["_unit"];
_unit removeEventHandler ["Killed", _thisEventHandler];

null = _this spawn
{
	params ["_unit", "_killer"];

	//Stops the unit from spawning things
	if (_unit getVariable ["spawner", false])
	then { _unit setVariable ["spawner", nil, true]; };

	//Gather infos, trigger timed despawn
	private _unitGroup = group _unit;
	private _unitSide = side (group _unit);

	null = [_unit] spawn A3A_fnc_postmortem;

	if ((hasACE) && {
		(isNull _killer) || {
		(_killer == _unit) }})
	then { _killer = _unit getVariable ["ace_medical_lastDamageSource", _killer]; };

	if (side (group _killer) == teamPlayer)
	then
	{
		if (isPlayer _killer)
		then
		{
			null = [1, _killer] call A3A_fnc_playerScoreAdd;

			if ((captive _killer) && {
				(_killer distance _unit < distanceSPWN) })
			then
			{
				null = [_killer, false] remoteExec ["setCaptive", 0, _killer];
				_killer setCaptive false;
			};

			_killer addRating 1000;
		};

		if (vehicle _killer isKindOf "StaticMortar")
		then
		{
			{
				if ((_x distance _unit < 300) && {
					(captive _x) })
				then
				{
					null = [_x, false] remoteExec ["setCaptive", 0, _x];
					_x setCaptive false;
				};
			} forEach (call A3A_fnc_playableUnits);
		};

		if ((count weapons _unit < 1) && {
			!(_unit getVariable ["isAnimal", false]) })
		then
		{
			//This doesn't trigger for dogs, only for surrendered units
			[
				3,
				"Rebels killed a surrendered unit",
				"aggroEvent",
				true
			] call A3A_fnc_log;

			if (_unitSide == Occupants)
			then
			{
				null = [0, -2, getPos _unit] remoteExec ["A3A_fnc_citySupportChange", 2];
				null = [[20, 30], [0, 0]] remoteExec ["A3A_fnc_prestige", 2];
			}
			else { null = [[0, 0], [20, 30]] remoteExec ["A3A_fnc_prestige", 2]; };
		}
		else
		{
			null = [-1, 1, getPos _unit] remoteExec ["A3A_fnc_citySupportChange", 2];

			if (_unitSide == Occupants)
			then { null = [[0.5, 45], [0, 0]] remoteExec ["A3A_fnc_prestige", 2]; }
			else { null = [[0, 0], [0.5, 45]] remoteExec ["A3A_fnc_prestige", 2]; };
		};
	}
	else
	{
		if (_unitSide == Occupants)
		then { null = [-0.25, 0, getPos _unit] remoteExec ["A3A_fnc_citySupportChange", 2]; }
		else { null = [0.25, 0, getPos _unit] remoteExec ["A3A_fnc_citySupportChange", 2]; };
	};

	private _unitLocation = _unit getVariable "markerX";
	private _unitWasGarrison = true;

	if (isNil "_unitLocation")
	then
	{
		_unitLocation = _unit getVariable ["originX", ""];
		_unitWasGarrison = false
	};

	if ((_unitLocation != "") {
		(sidesX getVariable [_unitLocation, sideUnknown] == _unitSide) })
	then
	{
		null = [typeOf _unit, _unitSide, _unitLocation, -1] remoteExec ["A3A_fnc_garrisonUpdate", 2];

		if (_unitWasGarrison)
		then { null = [_unitLocation, _unitSide] remoteExec ["A3A_fnc_zoneCheck", 2] };
	};

	null = [_unitGroup, _killer] spawn A3A_fnc_AIreactOnKill;
};
