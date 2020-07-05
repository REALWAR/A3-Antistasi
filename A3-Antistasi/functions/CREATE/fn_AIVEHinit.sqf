/*
	Installs various damage/smoke/kill/capture logic for vehicles
	Will set and modify the "originalSide" and "ownerSide" variables on the vehicle indicating side ownership
	If a rebel enters a vehicle, it will be switched to rebel side and added to vehDespawner

	Params:
	1. Object: Vehicle object
	2. Side: Side ownership for vehicle
*/

private _filename = "fn_AIVEHinit"; // using for logging

params ["_veh", "_side"];

if (isNil "_veh") exitWith {};

// vehicle already initialized, just swap side and exit
if !(isNil { _veh getVariable "ownerSide" })
exitWith { [_veh, _side] call A3A_fnc_vehKilledOrCaptured; };

_veh setVariable ["originalSide", _side, true];
_veh setVariable ["ownerSide", _side, true];

// probably just shouldn't be called for these
if (
	(_veh isKindOf "FlagCarrier") || {
	(_veh isKindOf "Building") || {
	(_veh isKindOf "ReammoBox_F") }}
) exitWith {};

// this might need moving into a different function later
if (_side == teamPlayer)
then
{
	clearMagazineCargoGlobal _veh;
	clearWeaponCargoGlobal _veh;
	clearItemCargoGlobal _veh;
	clearBackpackCargoGlobal _veh;
};

private _typeX = typeOf _veh;

if ((_typeX in vehNormal) || {
	(_typeX in vehAttack) || {
	(_typeX in vehBoats) || {
	(_typeX in vehAA) }}})
then
{
	_veh call A3A_fnc_addActionBreachVehicle;
}
else
{
	if (!(_typeX in vehPlanes) && {
		(_veh isKindOf "StaticWeapon") })
	then
	{
		_veh setCenterOfMass [(getCenterOfMass _veh) vectorAdd [0, 0, -2], 0];

		if (!(_veh in staticsToSave) && {
			(side gunner _veh != teamPlayer) })
		then
		{
			if ((activeGREF) && {
				(_typeX == staticATteamPlayer) || {
				(_typeX == staticAAteamPlayer) }})
			then { [_veh, "moveS"] remoteExec ["A3A_fnc_flagaction", [teamPlayer, civilian], _veh] }
			else { [_veh, "steal"] remoteExec ["A3A_fnc_flagaction", [teamPlayer, civilian], _veh] };
		};

		if (_typeX == SDKMortar)
		then
		{
			if (!isNull gunner _veh)
			then { [_veh, "steal"] remoteExec ["A3A_fnc_flagaction", [teamPlayer, civilian], _veh]; };

			_veh addEventHandler [
				"Fired",
				{
					_mortarX = _this #0;
					_dataX = _mortarX getVariable ["detection", [position _mortarX, 0]];
					_positionX = position _mortarX;
					_chance = _dataX #1;

					if ((_positionX distance (_dataX #0)) < 300)
					then { _chance = _chance + 2; }
					else { _chance = 0; };

					if (random 100 < _chance)
					then
					{
						{
							if ((side _x == Occupants) or (side _x == Invaders))
							then { _x reveal [_mortarX,4]; }
						} forEach allUnits;

						if ((_mortarX distance posHQ < 300) && {
							!(["DEF_HQ"] call BIS_fnc_taskExists) })
						then
						{
							_LeaderX = leader (gunner _mortarX);

							if (!isPlayer _LeaderX)
							then { [[], "A3A_fnc_attackHQ"] remoteExec ["A3A_fnc_scheduler", 2]; }
							else
							{
								if ([_LeaderX] call A3A_fnc_isMember)
								then { [[], "A3A_fnc_attackHQ"] remoteExec ["A3A_fnc_scheduler", 2] };
							};
						}
						else
						{
							_bases = airportsX select
							{
								(getMarkerPos _x distance _mortarX < distanceForAirAttack) && {
								([_x, true] call A3A_fnc_airportCanAttack) && {
								(sidesX getVariable [_x, sideUnknown] != teamPlayer) }}
							};

							if (count _bases > 0)
							then
							{
								_base = [_bases, _positionX] call BIS_fnc_nearestPosition;
								_sideX = sidesX getVariable [_base, sideUnknown];
								[[getPosASL _mortarX, _sideX, "Normal", false], "A3A_fnc_patrolCA"] remoteExec ["A3A_fnc_scheduler", 2];
							};
						};
					};

					_mortarX setVariable ["detection", [_positionX, _chance]];
				}
			];
		};
	};
};

// Civilians leave vehicles by damage from player side unit
if (_side == civilian)
then
{
	_veh addEventHandler
	[
		"HandleDamage",
		{
			_veh = _this #0;

			if (side (_this #3) == teamPlayer)
			then
			{
				_driverX = driver _veh;

				if (side group _driverX == civilian)
				then { _driverX leaveVehicle _veh; };

				_veh removeEventHandler ["HandleDamage", _thisEventHandler];
			};

			_this #2
		}
	];
};

if (_side != teamPlayer)
then
{
	// Vehicle stealing handler
	// When a rebel first enters a vehicle, fire capture function
	_veh addEventHandler
	[
		"GetIn",
		{
			params ["_veh", "_role", "_unit"];

			if (side group _unit != teamPlayer) exitWith {};		// only rebels can flip vehicles atm

			private _oldside = _veh getVariable ["ownerSide", teamPlayer];

			if (_oldside != teamPlayer)
			then
			{
				[
					3,
					format ["%1 switching side from %2 to rebels", typeof _veh, _oldside],
					"fn_AIVEHinit"
				] call A3A_fnc_log;

				[_veh, teamPlayer, true] call A3A_fnc_vehKilledOrCaptured;
			};

			_veh removeEventHandler ["GetIn", _thisEventHandler];
		}
	];
};

// Handler to prevent vehDespawner deleting vehicles for an hour after rebels exit them

_veh addEventHandler
[
	"GetOut",
	{
		params ["_veh", "_role", "_unit"];

		if !(_unit isEqualType objNull)
		exitWith
		{
			[
				1,
				format ["GetOut handler weird input: %1, %2, %3", _veh, _role, _unit],
				"fn_AIVEHinit"
			] call A3A_fnc_log;
		};

		// despawner always launched locally
		if (side group _unit == teamPlayer)
		then { _veh setVariable ["despawnBlockTime", time + 3600]; };
	}
];

// Because Killed and MPKilled are both retarded, we use Dammaged

_veh addEventHandler
[
	"Dammaged",
	{
		params ["_veh", "_selection", "_damage"];

		if ((_damage >= 1) && {
			(_selection == "") })
		then
		{
			private _killerSide = side group (_this select 5);
			[3, format ["%1 destroyed by %2", typeof _veh, _killerSide], "fn_AIVEHinit"] call A3A_fnc_log;
			[_veh, _killerSide, false] call A3A_fnc_vehKilledOrCaptured;
			[_veh] spawn A3A_fnc_postmortem;
			_veh removeEventHandler ["Dammaged", _thisEventHandler];
		};
	}
];


// deletes vehicle if it exploded on spawn...
[_veh] spawn A3A_fnc_cleanserVeh;
