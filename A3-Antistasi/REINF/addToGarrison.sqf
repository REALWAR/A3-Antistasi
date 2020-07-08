private
[
	"_positionTel",
	"_nearX",
	"_thingX",
	"_groupX",
	"_unitsX",
	"_leave"
];

if (!visibleMap) then { openMap true; };

positionTel = [];

_thingX = _this #0;

onMapSingleClick "positionTel = _pos";

null = ["Garrison", "Select the zone on which sending the selected troops as garrison"] call A3A_fnc_customHint;

waitUntil { sleep 0.5; (count positionTel > 0) || { !(visiblemap) } };
onMapSingleClick "";

if (!visibleMap) exitWith {};

_positionTel = positionTel;

_nearX = [markersX, _positionTel] call BIS_fnc_nearestPosition;

if !(_positionTel inArea _nearX)
exitWith { null = ["Garrison", "You must click near a marked zone"] call A3A_fnc_customHint; };

if (not(sidesX getVariable [_nearX, sideUnknown] == teamPlayer))
exitWith { null = ["Garrison", format ["That zone does not belong to %1", nameTeamPlayer]] call A3A_fnc_customHint; };

if ((_nearX in outpostsFIA) and !(isOnRoad getMarkerPos _nearX))
exitWith { null = ["Garrison", "You cannot manage garrisons on this kind of zone"] call A3A_fnc_customHint; };

_thingX = _this #0;

_groupX = grpNull;
_unitsX = objNull;

if ((_thingX #0) isEqualType grpNull)
then
{
	_groupX = _thingX #0;
	_unitsX = units _groupX;
}
else { _unitsX = _thingX; };

_leave = false;

private _alreadyInGarrison = false;

{
	private _garrisondIn = _x getVariable "markerX";

	if !(isNil "_garrisondIn")
	then { _alreadyInGarrison = true; };
} forEach _unitsX;

if _alreadyInGarrison
exitWith { null = ["Garrison", "The units selected already are in a garrison"] call A3A_fnc_customHint; };

{
	if ((typeOf _x == staticCrewTeamPlayer) || {
		(typeOf _x == SDKUnarmed) || {
		(typeOf _x in arrayCivs) || {
		(!alive _x) }}})
	exitWith { _leave = true; };
} forEach _unitsX;

if (_leave)
exitWith { null = ["Garrison", "Static crewman, prisoners, refugees or dead units cannot be added to any garrison"] call A3A_fnc_customHint; };

if ((groupID _groupX == "MineF") || {
	(groupID _groupX == "Watch") || {
	(isPlayer (leader _groupX)) }})
exitWith { null = ["Garrison", "You cannot garrison player led, Watchpost, Roadblocks or Minefield building squads"] call A3A_fnc_customHint; };


if (isNull _groupX)
then
{
	_groupX = createGroup teamPlayer;
	_unitsX joinSilent _groupX;
	//{arrayids = arrayids + [name _x]} forEach _unitsX;
	null = ["Garrison", "Adding units to garrison"] call A3A_fnc_customHint;

	if !(hasIFA)
	then { {arrayids pushBackUnique (name _x)} forEach _unitsX; };
}
else
{
	null = ["Garrison", format ["Adding %1 squad to garrison", groupID _groupX]] call A3A_fnc_customHint;
	theBoss hcRemoveGroup _groupX;
};

[_unitsX, teamPlayer, _nearX, 0] remoteExec ["A3A_fnc_garrisonUpdate", 2];
_noBorrar = false;

if (spawner getVariable _nearX != 2)
then
{

	{ deleteWaypoint _x; } forEach waypoints _groupX;

	_wp = _groupX addWaypoint [(getMarkerPos _nearX), 0];
	_wp setWaypointType "MOVE";
	{
		_x setVariable ["markerX", _nearX, true];
		_x addEventHandler
		[
			"Killed",
			{
				params ["_unit"];
				_unit removeEventHandler ["Killed", _thisEventHandler];

				null = _this spawn
				{
					params ["_unit"];

					private _markerX = _unit getVariable "markerX";

					if (!(isNil "_markerX") && {
						(sidesX getVariable [_markerX, sideUnknown] == teamPlayer) })
					then
					{
						null = [typeOf _unit, teamPlayer, _markerX, -1] remoteExec ["A3A_fnc_garrisonUpdate", 2];
						_unit setVariable [_markerX, nil, true];
					};
				};
			}
		];
	} forEach _unitsX;

	waitUntil
	{
		sleep 1;

		(spawner getVariable _nearX == 2) || {
		!(sidesX getVariable [_nearX, sideUnknown] == teamPlayer) }
	};

	if !(sidesX getVariable [_nearX, sideUnknown] == teamPlayer)
	then { _noBorrar = true; };
};

if (!_noBorrar)
then
{
	{
		if (alive _x)
		then { deleteVehicle _x; };
	} forEach _unitsX;

	deleteGroup _groupX;
}
else
{
	//añadir el groupX al HC y quitarles variables
	{
		if (alive _x)
		then
		{
			_x setVariable ["markerX", nil, true];
			_x removeAllEventHandlers "killed";

			_x addEventHandler
			[
				"killed",
				{
					params ["_unit"];
					_unit removeEventHandler ["Killed", _thisEventHandler];

					null = _this spawn
					{
						params ["_unit", "_killer"];

						null = [_unit] remoteExec ["A3A_fnc_postmortem", 2];

						if ((isPlayer _killer) && {
							(side _killer == teamPlayer)})
						then
						{
							if (!isMultiPlayer)
							then
							{
								null = [0, 20] remoteExec ["A3A_fnc_resourcesFIA", 2];
								_killer addRating 1000;
							};
						}
						else
						{
							if (side _killer == Occupants)
							then
							{
								null = [0.25, 0, getPos _unit] remoteExec ["A3A_fnc_citySupportChange", 2];
								null = [[-1, 30], [0, 0]] remoteExec ["A3A_fnc_prestige", 2];
							}
							else
							{
								if (side _killer == Invaders)
								then { null = [[0, 0], [-1, 30]] remoteExec ["A3A_fnc_prestige", 2]; };
							};
						};

						_unit setVariable ["spawner", nil, true];
					};
				}
			];
		};
	} forEach _unitsX;

	theBoss hcSetGroup [_groupX];
	null = ["Garrison", format ["Group %1 is back to HC control because the zone which was pointed to garrison has been lost", groupID _groupX]] call A3A_fnc_customHint;
};
