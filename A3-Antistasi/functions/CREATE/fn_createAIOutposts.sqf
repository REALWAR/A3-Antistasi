if (!isServer && {hasInterface}) exitWith {};

private
[
	"_markerX",
	"_vehiclesX",
	"_groups",
	"_soldiers",
	"_positionX",
	"_pos",
	"_size",
	"_frontierX",
	"_sideX",
	"_cfg",
	"_isFIA",
	"_garrison",
	"_antenna",
	"_radiusX",
	"_buildings",
	"_mrk",
	"_countX",
	"_typeGroup",
	"_groupX",
	"_typeUnit",
	"_typeVehX",
	"_veh",
	"_unit",
	"_flagX",
	"_boxX",
	"_roads",
	"_mrkMar",
	"_vehicle",
	"_vehCrew",
	"_groupVeh",
	"_dist",
	"_road",
	"_roadCon",
	"_dirVeh",
	"_bunker",
	"_dir",
	"_posF"
];

_markerX = _this #0;

//Not sure if that ever happens, but it reduces redundance
if (spawner getVariable _markerX == 2) exitWith {};

_vehiclesX = [];
_groups = [];
_soldiers = [];
_positionX = getMarkerPos (_markerX);
_pos = [];

diag_log format ["[Antistasi] Spawning Outpost %1 (createAIOutposts.sqf)", _markerX];

_size = [_markerX] call A3A_fnc_sizeMarker;
_frontierX = [_markerX] call A3A_fnc_isFrontline;
_sideX = Invaders;
_isFIA = false;

if (sidesX getVariable [_markerX, sideUnknown] == Occupants)
then
{
	_sideX = Occupants;

	if ((random 10 >= (tierWar + difficultyCoef)) && {
		!(_frontierX) && {
		!(_markerX in forcedSpawn) }})
	then { _isFIA = true; };
};

_antenna = objNull;

if (_sideX == Occupants)
then
{
	if (_markerX in outposts)
	then
	{
		_buildings = nearestObjects [_positionX, ["Land_TTowerBig_1_F", "Land_TTowerBig_2_F", "Land_Communication_F"], _size];

		if (count _buildings > 0)
		then { _antenna = _buildings #0; };
	};
};

_mrk = createMarkerLocal [format ["%1patrolarea", random 100], _positionX];
_mrk setMarkerShapeLocal "RECTANGLE";
_mrk setMarkerSizeLocal [(distanceSPWN/2), (distanceSPWN/2)];
_mrk setMarkerTypeLocal "hd_warning";
_mrk setMarkerColorLocal "ColorRed";
_mrk setMarkerBrushLocal "DiagGrid";
_ang = markerDir _markerX;
_mrk setMarkerDirLocal _ang;

if (!debug) then { _mrk setMarkerAlphaLocal 0; };

_garrison = garrison getVariable [_markerX, []];
_garrison = _garrison call A3A_fnc_garrisonReorg;
_radiusX = count _garrison;
private _patrol = true;
//If one is missing, there are no patrols??

//No patrol if patrol area overlaps with an enemy site
if (_radiusX < ([_markerX] call A3A_fnc_garrisonSize))
then { _patrol = false; }
else
{
	_patrol = ((markersX findIf {(getMarkerPos _x inArea _mrk) && { (sidesX getVariable [_x, sideUnknown] != _sideX) }}) == -1);
};

if (_patrol)
then
{
	_countX = 0;

	//Fixed number of patrols?
	while {_countX < 4} do
	{
		_arraygroups =
		if (_sideX == Occupants)
		then { if (!_isFIA) then {groupsNATOsmall} else {groupsFIASmall}; }
		else { groupsCSATsmall };

		if ([_markerX, false] call A3A_fnc_fogCheck < 0.3)
		then { _arraygroups = _arraygroups - sniperGroups; };

		_typeGroup = selectRandom _arraygroups;
		_groupX = [_positionX, _sideX, _typeGroup, false, true] call A3A_fnc_spawnGroup;

		if !(isNull _groupX)
		then
		{
			sleep 1;

			if ((random 10 < 2.5) && {
				!(_typeGroup in sniperGroups) })
			then
			{
				_dog = [_groupX, "Fin_random_F", _positionX, [], 0, "FORM"] call A3A_fnc_createUnit;
				null = [_dog] spawn A3A_fnc_guardDog;
				sleep 1;
			};

			//TODO need delete UPSMON link
			null = [leader _groupX, _mrk, "SAFE", "SPAWNED", "RANDOM", "NOVEH2"] execVM "scripts\UPSMON.sqf";
			_groups pushBack _groupX;

			{
				null = [_x, _markerX] call A3A_fnc_NATOinit;
				_soldiers pushBack _x;
			} forEach units _groupX;
		};

		_countX = _countX +1;
	};
};

if ((_frontierX) && {
	(_markerX in outposts) })
then
{
	_typeUnit = if (_sideX == Occupants) then {staticCrewOccupants} else {staticCrewInvaders};
	_typeVehX = if (_sideX == Occupants) then {NATOMortar} else {CSATMortar};

	_spawnParameter = [_markerX, "Mortar"] call A3A_fnc_findSpawnPosition;

	if (_spawnParameter isEqualType [])
	then
	{
		_groupX = createGroup _sideX;
		_veh = _typeVehX createVehicle (_spawnParameter #0);
		//TODO need delete UPSMON link
		null = [_veh] execVM "scripts\UPSMON\MON_artillery_add.sqf";
		_unit = [_groupX, _typeUnit, _positionX, [], 0, "NONE"] call A3A_fnc_createUnit;
		null = [_unit, _markerX] spawn A3A_fnc_NATOinit;
		_unit moveInGunner _veh;
		_groups pushBack _groupX;
		_soldiers pushBack _unit;
		_vehiclesX pushBack _veh;
		sleep 1;
	};
};

_ret = [_markerX, _size, _sideX, _frontierX] call A3A_fnc_milBuildings;
_groups pushBack (_ret #0);
_vehiclesX append (_ret #1);
_soldiers append (_ret #2);

{ null = [_x, _sideX] spawn A3A_fnc_AIVEHinit; } forEach _vehiclesX;

if (random 100 < (40 + tierWar * 3))
then
{
	_large = (random 100 < (30 + tierWar * 2));
	null = [_markerX, _large] spawn A3A_fnc_placeIntel;
};

_typeVehX = if (_sideX == Occupants) then {NATOFlag} else {CSATFlag};

_flagX = createVehicle [_typeVehX, _positionX, [], 0, "NONE"];
_flagX allowDamage false;
null = [_flagX, "take"] remoteExec ["A3A_fnc_flagaction", [teamPlayer, civilian], _flagX];
_vehiclesX pushBack _flagX;

private _ammoBoxType = if (_sideX == Occupants) then {NATOAmmoBox} else {CSATAmmoBox};

private _ammoBox = _ammoBoxType createVehicle _positionX;
null = [_ammoBox] spawn A3A_fnc_fillLootCrate;
null = _ammoBox call jn_fnc_logistics_addAction;
_vehiclesX pushBack _ammoBox;

_roads = _positionX nearRoads _size;

if ((_markerX in seaports) && {
	!(hasIFA) })
then
{
	_typeVehX = if (_sideX == Occupants) then {vehNATOBoat} else {vehCSATBoat};

	if ([_typeVehX] call A3A_fnc_vehAvailable)
	then
	{
		_mrkMar = seaSpawn select {getMarkerPos _x inArea _markerX};

		if (count _mrkMar > 0)
		then
		{
			_pos = (getMarkerPos (_mrkMar #0)) findEmptyPosition [0, 20, _typeVehX];
			_vehicle = [_pos, 0, _typeVehX, _sideX] call bis_fnc_spawnvehicle;
			_veh = _vehicle #0;
			null = [_veh, _sideX] spawn A3A_fnc_AIVEHinit;
			_vehCrew = _vehicle #1;
			{ null = [_x, _markerX] spawn A3A_fnc_NATOinit; } forEach _vehCrew;
			_groupVeh = _vehicle #2;
			_soldiers = _soldiers + _vehCrew;
			_groups pushBack _groupVeh;
			_vehiclesX pushBack _veh;
			sleep 1;
		}
		else { diag_log format ["createAIOutposts: Could not find seaSpawn marker on %1!", _markerX]; };
	};

	sleep 1;    //make sure fillLootCrate finished clearing the crate

	{
		_ammoBox addItemCargoGlobal [_x, round random [2, 6, 8]];
	} forEach diveGear;
}
else
{
	if (_frontierX)
	then
	{
		if (count _roads != 0)
		then
		{
			_dist = 0;
			_road = objNull;

			{
				if ((position _x) distance _positionX > _dist)
				then
				{
					_road = _x;
					_dist = position _x distance _positionX;
				};
			} forEach _roads;

			_roadscon = roadsConnectedto _road;
			_roadcon = objNull;

			//This is a extrem complex way, use vector and scalar product to determine which way they are pointing
			{
				if ((position _x) distance _positionX > _dist)
				then { _roadcon = _x; };
			} forEach _roadscon;

			_dirveh = [_roadcon, _road] call BIS_fnc_DirTo;
				//if (!_isFIA) then		_isFIA can only be true if _frontierX (line 167) is false, if unneeded, else case not possible
			//{

			_groupX = createGroup _sideX;
			_groups pushBack _groupX;
			_pos = [getPos _road, 7, _dirveh + 270] call BIS_Fnc_relPos;
			_bunker = "Land_BagBunker_01_Small_green_F" createVehicle _pos;
			_vehiclesX pushBack _bunker;
			_bunker setDir _dirveh;
			_pos = getPosATL _bunker;
			_typeVehX = if (_sideX==Occupants) then { staticATOccupants } else { staticATInvaders };
			_veh = _typeVehX createVehicle _positionX;
			_vehiclesX pushBack _veh;
			_veh setPos _pos;
			_veh setDir _dirVeh + 180;
			_typeUnit = if (_sideX==Occupants) then { staticCrewOccupants } else { staticCrewInvaders };
			_unit = [_groupX, _typeUnit, _positionX, [], 0, "NONE"] call A3A_fnc_createUnit;
			null = [_unit, _markerX] spawn A3A_fnc_NATOinit;
			null = [_veh, _sideX] spawn A3A_fnc_AIVEHinit;
			_unit moveInGunner _veh;
			_soldiers pushBack _unit;
		};
	};
};

_spawnParameter = [_markerX, "Vehicle"] call A3A_fnc_findSpawnPosition;

if (_spawnParameter isEqualType [])
then
{
	_typeVehX =
	if (_sideX == Occupants)
	then
	{
		if (!_isFIA)
		then { vehNATOTrucks + vehNATOCargoTrucks }
		else { [vehFIATruck] };
	}
	else { vehCSATTrucks };

	_veh = createVehicle [selectRandom _typeVehX, (_spawnParameter #0), [], 0, "NONE"];
	_veh setDir (_spawnParameter #1);
	_vehiclesX pushBack _veh;
	null = [_veh, _sideX] spawn A3A_fnc_AIVEHinit;
	sleep 1;
};

{ _x setVariable ["originalPos", getPos _x]; } forEach _vehiclesX;

_countX = 0;

if (!isNull _antenna)
then
{
	if ((typeOf _antenna == "Land_TTowerBig_1_F") || {
		(typeOf _antenna == "Land_TTowerBig_2_F") })
	then
	{
		_groupX = createGroup _sideX;
		_pos = getPosATL _antenna;
		_dir = getDir _antenna;
		_posF = _pos getPos [2, _dir];
		_posF set [2, 23.1];

		if (typeOf _antenna == "Land_TTowerBig_2_F")
		then
		{
			_posF = _pos getPos [1, _dir];
			_posF set [2, 24.3];
		};

		_typeUnit =
		if (_sideX == Occupants)
		then
		{
			if (!_isFIA)
			then { NATOMarksman }
			else { FIAMarksman };
		}
		else { CSATMarksman };

		_unit = [_groupX, _typeUnit, _positionX, [], _dir, "NONE"] call A3A_fnc_createUnit;
		_unit setPosATL _posF;
		_unit forceSpeed 0;
		_unit setUnitPos "UP";
		null = [_unit, _markerX] spawn A3A_fnc_NATOinit;
		_soldiers pushBack _unit;
		_groups pushBack _groupX;
	};
};

_array = [];
_subArray = [];
_countX = 0;
_radiusX = _radiusX -1;

while {_countX <= _radiusX} do
{
	_array pushBack (_garrison select [_countX, 7]);
	_countX = _countX + 8;
};

for "_i" from 0 to (count _array - 1) do
{
	//What is so special about the first?
	_groupX =
	if (_i == 0)
	then { [_positionX, _sideX, (_array select _i), true, false] call A3A_fnc_spawnGroup; }
	else { [_positionX, _sideX, (_array select _i), false, true] call A3A_fnc_spawnGroup; };

	_groups pushBack _groupX;

	{
		null = [_x, _markerX] call A3A_fnc_NATOinit;
		_soldiers pushBack _x;
	} forEach units _groupX;

	//Can't we just precompile this and call this like every other funtion? Would save some time
	if (_i == 0)
	then { null = [leader _groupX, _markerX, "SAFE", "RANDOMUP", "SPAWNED", "NOVEH2", "NOFOLLOW"] execVM "scripts\UPSMON.sqf"; }
	else { null = [leader _groupX, _markerX, "SAFE", "SPAWNED", "RANDOM", "NOVEH2", "NOFOLLOW"] execVM "scripts\UPSMON.sqf"; };
};
//TODO need delete UPSMON link

waitUntil { sleep 1; (spawner getVariable _markerX == 2) };

null = [_markerX] call A3A_fnc_freeSpawnPositions;

deleteMarker _mrk;

{
	if (alive _x)
	then { deleteVehicle _x; };
} forEach _soldiers;

{ deleteGroup _x; } forEach _groups;

{
	// delete all vehicles that haven't been stolen
	if (_x getVariable ["ownerSide", _sideX] == _sideX)
	then
	{
		if (_x distance2d (_x getVariable "originalPos") < 100)
		then { deleteVehicle _x; }
		else
		{
			if !(_x isKindOf "StaticWeapon")
			then { null = [_x] spawn A3A_fnc_VEHdespawner; };
		};
	};
} forEach _vehiclesX;
