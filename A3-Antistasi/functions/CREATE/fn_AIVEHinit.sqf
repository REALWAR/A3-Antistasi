/*
	Installs various damage/smoke/kill/capture logic for vehicles
	Will set and modify the "originalSide" and "ownerSide" variables on the vehicle indicating side ownership
	If a rebel enters a vehicle, it will be switched to rebel side and added to vehDespawner

	Params:
	1. Object: Vehicle object
	2. Side: Side ownership for vehicle
*/

params ["_veh", "_side"];
private _filename = "fn_AIVEHinit";

if (isNil "_veh") exitWith {};

// vehicle already initialized, just swap side and exit
if !(isNil { _veh getVariable "ownerSide" })
exitWith { null = [_veh, _side] call A3A_fnc_vehKilledOrCaptured; };

_veh setVariable ["originalSide", _side, true];
_veh setVariable ["ownerSide", _side, true];

// probably just shouldn't be called for these
if ((_veh isKindOf "FlagCarrier") || {
	(_veh isKindOf "Building") || {
	(_veh isKindOf "ReammoBox_F") }})
exitWith {};

// this might need moving into a different function later
if (_side == teamPlayer)
then
{
	// might need an exception on this for vehicle weapon mags?
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
	null = _veh call A3A_fnc_addActionBreachVehicle;

	if !(_typeX in vehAttack)
	then
	{
		if (_veh isKindOf "Car")
		then
		{
			_veh addEventHandler
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

					if ((_hitSelection find "wheel" != -1) && {
						!(isPlayer driver _unit) && {
						(_projectile == "") || {
						(side _source != teamPlayer) }}})
					exitWith { 0 };
				}
			];

			if ({"SmokeLauncher" in (_veh weaponsTurret _x)} count (allTurrets _veh) > 0)
			then
			{
				_veh setVariable ["within", true];

				_veh addEventHandler
				[
					"GetOut",
					{
						null = _this spawn
						{
							params ["_veh", "_position", "_unit"];

							if ((side _unit != teamPlayer) && {
								(_veh getVariable "within") })
							then
							{
								_veh setVariable ["within", false];
								null = [_veh] call A3A_fnc_smokeCoverAuto;
							};
						};
					}
				];

				_veh addEventHandler
				[
					"GetIn",
					{
						null = _this spawn
						{
							params ["_veh", "_position", "_unit"];

							if (side _unit != teamPlayer)
							then { _veh setVariable ["within", true]; }
						};
					}
				];
			};
		};
	}
	else
	{
		if (_typeX in vehAPCs)
		then
		{
			_veh addEventHandler
			[
				"HandleDamage",
				{
					params ["_veh"];

					if !(canFire _veh)
					then
					{
						null = [_veh] spawn A3A_fnc_smokeCoverAuto;
						_veh removeEventHandler ["HandleDamage", _thisEventHandler];
					};
				}
			];

			_veh setVariable ["within", true];

			_veh addEventHandler
			[
				"GetOut",
				{
					null = _this spawn
					{
						params ["_veh", "_position", "_unit"];

						if ((side _unit != teamPlayer) && {
							(_veh getVariable "within") })
						then
						{
							_veh setVariable ["within", false];
							null = [_veh] call A3A_fnc_smokeCoverAuto;
						};
					};
				}
			];

			_veh addEventHandler
			[
				"GetIn",
				{
					null = _this spawn
					{
						params ["_veh", "_position", "_unit"];

						if (side _unit != teamPlayer)
						then { _veh setVariable ["within", true]; }
					};
				}
			];
		}
		else
		{
			if (_typeX in vehTanks)
			then
			{
				_veh addEventHandler
				[
					"HandleDamage",
					{
						params ["_unit"];

						if !(canFire _unit)
						then
						{
							null = [_unit] spawn A3A_fnc_smokeCoverAuto;
							_unit removeEventHandler ["HandleDamage", _thisEventHandler];
						};
					}
				];
			}
			else		// never called? vehAttack is APCs+tank
			{
				_veh addEventHandler
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

						if ((_hitSelection find "wheel" != -1) && {
							!(isPlayer driver _unit) && {
							(_projectile == "") || {
							(side _source != teamPlayer) }}})
						exitWith { 0 };
					}
				];
			};
		};
	};
}
else
{
	if (_typeX in vehPlanes)
	then
	{
		_veh addEventHandler
		[
			"GetIn",
			{
				null = _this spawn
				{
					params ["_veh", "_position", "_unit"];

					if ((_position == "driver") && {
						(!isPlayer _unit) && {
						(_unit getVariable ["spawner", false]) && {
						(side group _unit == teamPlayer) }}})
					then
					{
						moveOut _unit;
						null = ["General", "Only Humans can pilot an air vehicle"] call A3A_fnc_customHint;
					};
				};
			}
		];

		if ((_veh isKindOf "Helicopter") && {
			(_typeX in vehTransportAir) })
		then
		{
			_veh setVariable ["within", true];

			_veh addEventHandler
			[
				"GetOut",
				{
					null = _this spawn
					{
						params ["_veh", "_position", "_unit"];

						if ((isTouchingGround _veh) && {
							(isEngineOn _veh) && {
							(side _unit != teamPlayer) && {
							(_veh getVariable "within") }}})
						then
						{
							_veh setVariable ["within", false];
							null = [_veh] call A3A_fnc_smokeCoverAuto;
						};
					};
				}
			];

			_veh addEventHandler
			[
				"GetIn",
				{
					null = _this spawn
					{
						params ["_veh", "_position", "_unit"];

						if (side _unit != teamPlayer)
						then { _veh setVariable ["within", true]; };
					};
				}
			];
		};
	}
	else
	{
		if (_veh isKindOf "StaticWeapon")
		then
		{
			_veh setCenterOfMass [(getCenterOfMass _veh) vectorAdd [0, 0, -1], 0];

			if (!(_veh in staticsToSave) && {
				(side gunner _veh != teamPlayer) })
			then
			{
				if (activeGREF && {
					(_typeX == staticATteamPlayer) || {
					(_typeX == staticAAteamPlayer) }})
				then { [_veh, "moveS"] remoteExec ["A3A_fnc_flagaction", [teamPlayer, civilian], _veh]; }
				else { [_veh, "steal"] remoteExec ["A3A_fnc_flagaction", [teamPlayer, civilian], _veh]; };
			};

			if (_typeX != SDKMortar) exitWith {};

			if (!isNull gunner _veh)
			then { [_veh, "steal"] remoteExec ["A3A_fnc_flagaction", [teamPlayer, civilian], _veh]; };

			_veh addEventHandler
			[
				"Fired",
				{
					_this spawn
					{
						params ["_mortarX"];

						private _dataX = _mortarX getVariable ["detection", [position _mortarX, 0]];
						private _positionX = position _mortarX;
						private _chance = _dataX #1;

						if ((_positionX distance (_dataX #0)) < 300)
						then { _chance = _chance + 2; }
						else { _chance = 0; };

						if (random 100 < _chance)
						then
						{
							{
								if ((side _x == Occupants) || {
									(side _x == Invaders) })
								then { _x reveal [_mortarX, 4]; };
							} forEach allUnits;

							if (_mortarX distance posHQ < 300)
							then
							{
								if (!(["DEF_HQ"] call BIS_fnc_taskExists))
								then
								{
									private _LeaderX = leader (gunner _mortarX);

									if (!isPlayer _LeaderX)
									then { [[], "A3A_fnc_attackHQ"] remoteExec ["A3A_fnc_scheduler", 2]; }
									else
									{
										if ([_LeaderX] call A3A_fnc_isMember)
										then { [[], "A3A_fnc_attackHQ"] remoteExec ["A3A_fnc_scheduler", 2]; };
									};
								};
							}
							else
							{
								private _bases = airportsX select
								{
									(getMarkerPos _x distance _mortarX < distanceForAirAttack) && {
									([_x, true] call A3A_fnc_airportCanAttack) && {
									(sidesX getVariable [_x, sideUnknown] != teamPlayer) }}
								};

								if (count _bases > 0)
								then
								{
									private _base = [_bases, _positionX] call BIS_fnc_nearestPosition;
									private _sideX = sidesX getVariable [_base, sideUnknown];
									[
										[getPosASL _mortarX, _sideX, "Normal", false],
										"A3A_fnc_patrolCA"
									] remoteExec ["A3A_fnc_scheduler", 2];
								};
							};
						};

						_mortarX setVariable ["detection", [_positionX, _chance]];
					};
				}
			];
		};
	};
};

if (_side == civilian)
then
{
	_veh addEventHandler
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

			if ((_hitSelection find "wheel" != -1) && {
				(_projectile == "") && {
				!(isPlayer driver _unit) }})
			exitWith { 0 };
		}
	];

	_veh addEventHandler
	[
		"HandleDamage",
		{
			params
			[
				"_unit",
				"_hitSelection",
				"_damage",
				"_source"
			]

			if (side _source == teamPlayer)
			then
			{
				private _driverX = driver _unit;

				if (side group _driverX == civilian)
				then { _driverX leaveVehicle _unit; };

				_unit removeEventHandler ["HandleDamage", _thisEventHandler];
			};
		}
	];
};

// EH behaviour:
// GetIn/GetOut/Dammaged: Runs where installed, regardless of locality
// Local: Runs where installed if target was local before or after the transition
// HandleDamage/Killed: Runs where installed, only if target is local
// MPKilled: Runs everywhere, regardless of target locality or install location

if (_side != teamPlayer)
then
{
	// Vehicle stealing handler
	// When a rebel first enters a vehicle, fire capture function
	_veh addEventHandler
	[
		"GetIn",
		{
			null = _this spawn
			{
				params ["_veh", "_role", "_unit"];

				if (side group _unit != teamPlayer) exitWith {};		// only rebels can flip vehicles atm

				private _oldside = _veh getVariable ["ownerSide", teamPlayer];

				if (_oldside != teamPlayer)
				then
				{
					null = [3, format ["%1 switching side from %2 to rebels", typeof _veh, _oldside], "fn_AIVEHinit"] call A3A_fnc_log;
					null = [_veh, teamPlayer, true] call A3A_fnc_vehKilledOrCaptured;
				};
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
		null = _this spawn
		{
			params ["_veh", "_role", "_unit"];

			if !(_unit isEqualType objNull)
			exitWith { null = [1, format ["GetOut handler weird input: %1, %2, %3", _veh, _role, _unit], "fn_AIVEHinit"] call A3A_fnc_log; };

			// despawner always launched locally
			if (side group _unit == teamPlayer)
			then { _veh setVariable ["despawnBlockTime", time + 3600]; };
		};
	}
];

// Because Killed and MPKilled are both retarded, we use Dammaged

_veh addEventHandler
[
	"Dammaged",
	{
		params
		[
			"_unit",
			"_selection",
			"_damage"
		];

		if ((_damage >= 1) && {
			(_selection == "") })
		then
		{
			null = _this spawn
			{
				params
				[
					"_unit",
					"_selection",
					"_damage",
					"_hitIndex",
					"_hitPoint",
					"_shooter",
					"_projectile"
				];

				private _killerSide = side group _shooter;
				null = [3, format ["%1 destroyed by %2", typeof _unit, _killerSide], "fn_AIVEHinit"] call A3A_fnc_log;
				null = [_unit, _killerSide, false] call A3A_fnc_vehKilledOrCaptured;
				null = [_unit] spawn A3A_fnc_postmortem;
			};

			_unit removeEventHandler ["Dammaged", _thisEventHandler];
		};
	}
];


// deletes vehicle if it exploded on spawn...
null = [_veh] spawn A3A_fnc_cleanserVeh;
