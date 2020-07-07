if (isDedicated) exitWith {};

params ["_newUnit", "_oldUnit"];

if (isNull _oldUnit) exitWith {};

waitUntil { alive player };

//When LAN hosting, Bohemia's Zeus module code will cause the player lose Zeus access if the body is deleted after respawning.
//This is a workaround that re-assigns curator to the player if their body is deleted.
//It will only run on LAN hosted MP, where the hoster is *always* admin, so we shouldn't run into any issues.
if (isServer)
then
{
	_oldUnit addEventHandler
	[
		"Deleted",
		{
			null = [] spawn
			{
				sleep 1;		// should ensure that the bug unassigns first
				{ player assignCurator _x } forEach allCurators;
			}
		}
	];
};

null = [_oldUnit] spawn A3A_fnc_postmortem;

_oldUnit setVariable ["incapacitated", false, true];
_newUnit setVariable ["incapacitated", false, true];

if (side group player == teamPlayer)
then
{
	_owner = _oldUnit getVariable ["owner", _oldUnit];

	if (_owner != _oldUnit)
	exitWith
	{
		null = ["Remote AI", "Died while remote controlling AI"] call A3A_fnc_customHint;
		selectPlayer _owner;
		disableUserInput false;
		deleteVehicle _newUnit;
	};

	[0, -1, getPos _oldUnit] remoteExec ["A3A_fnc_citySupportChange", 2];

	_score = _oldUnit getVariable ["score", 0];
	_punish = _oldUnit getVariable ["punish", 0];
	_moneyX = _oldUnit getVariable ["moneyX", 0];
	_moneyX = round (_moneyX - (_moneyX * 0.15));
	_eligible = _oldUnit getVariable ["eligible", true];
	_rankX = _oldUnit getVariable ["rankX", "PRIVATE"];

	if (_moneyX < 0) then { _moneyX = 0; };

	_newUnit setVariable ["score", _score -1, true];
	_newUnit setVariable ["owner", _newUnit, true];
	_newUnit setVariable ["punish", _punish, true];
	_newUnit setVariable ["respawning", false];
	_newUnit setVariable ["moneyX", _moneyX, true];
	//_newUnit setUnitRank (rank _oldUnit);
	_newUnit setVariable ["compromised", 0];
	_newUnit setVariable ["eligible", _eligible, true];
	_oldUnit setVariable ["eligible", false, true];
	_newUnit setVariable ["spawner", true, true];
	_oldUnit setVariable ["spawner", nil, true];
	[_newUnit, false] remoteExec ["setCaptive", 0, _newUnit];
	_newUnit setCaptive false;
	_newUnit setRank (_rankX);
	_newUnit setVariable ["rankX", _rankX, true];
	_newUnit setUnitTrait ["camouflageCoef", 0.8];
	_newUnit setUnitTrait ["audibleCoef", 0.8];

	{
    	_newUnit addOwnedMine _x;
    } count (getAllOwnedMines (_oldUnit));

	{
		if (_x getVariable ["owner", ObjNull] == _oldUnit)
		then { _x setVariable ["owner", _newUnit, true]; };
	} forEach (units group player);


	// don't reinit revive because damage handlers are respawn-persistent
	//if (!hasACEMedical) then {[_newUnit] call A3A_fnc_initRevive};
	disableUserInput false;
	//_newUnit enableSimulation true;

	if (_oldUnit == theBoss)
	then { null = [_newUnit, true] remoteExec ["A3A_fnc_theBossTransfer", 2]; };

	removeAllItemsWithMagazines _newUnit;

	{ _newUnit removeWeaponGlobal _x; } forEach weapons _newUnit;

	removeBackpackGlobal _newUnit;
	removeVest _newUnit;
	removeAllAssignedItems _newUnit;
	//Give them a map, in case they're commander and need to replace petros.
	_newUnit linkItem "ItemMap";

	if (!isPlayer (leader group player))
	then { (group player) selectLeader player; };

	player addEventHandler
	[
		"FIRED",
		{
			null = _this spawn
			{
				_player = _this #0;

				if !(captive _player) exitWith {};

				if
				(
					allUnits findIf
					{
						((side _x == Occupants) ||
						(side _x == Invaders)) &&
						(_x distance player < 300)
					} != 0
				)
				then
				{
					[_player, false] remoteExec ["setCaptive", 0, _player];
					_player setCaptive false;
				}
				else
				{
					_city = [citiesX, _player] call BIS_fnc_nearestPosition;
					_size = [_city] call A3A_fnc_sizeMarker;
					_dataX = server getVariable _city;

					if ((random 100 < _dataX #2) && {
						(_player distance getMarkerPos _city < _size * 1.5) })
					then
					{
						null = [_player, false] remoteExec ["setCaptive", 0, _player];
						_player setCaptive false;

						if (vehicle _player != _player)
						then
						{
							{
								if (isPlayer _x)
								then
								{
									null = [_x, false] remoteExec ["setCaptive", 0, _x];
									_x setCaptive false;
								};
							} forEach ((assignedCargo (vehicle _player)) + (crew (vehicle _player)) - [_player]);
						};
					};
				};
			};
		}
	];

	player addEventHandler
	[
		"InventoryOpened",
		{
			null = _this spawn
			{
				private _playerX = _this #0;

				if !(captive _playerX) exitWith {};

				private _containerX = _this #1;
				private _typeX = typeOf _containerX;

				if !(((_containerX isKindOf "CAManBase") && {
					(!alive _containerX) }) || {
					(_typeX == NATOAmmoBox) || {
					(_typeX == CSATAmmoBox) }})
				exitWith {};

				if
				(
					allUnits findIf
					{
						((side _x== Invaders) || {
						(side _x== Occupants) }) && {
						(_x knowsAbout _playerX > 1.4) }
					} != -1
				)
				then
				{
					[_playerX, false] remoteExec ["setCaptive", 0, _playerX];
					_playerX setCaptive false;
				}
				else
				{
					_city = [citiesX, _playerX] call BIS_fnc_nearestPosition;
					_size = [_city] call A3A_fnc_sizeMarker;
					_dataX = server getVariable _city;

					if ((random 100 < _dataX #2) && {
						(_playerX distance getMarkerPos _city < _size * 1.5) })
					then
					{
						null = [_playerX, false] remoteExec ["setCaptive", 0, _playerX];
						_playerX setCaptive false;
					};
				};
			};

			false
		}
	];

	if (hasInterface)
	then { [player] call A3A_fnc_punishment_FF_addEH; };

	player addEventHandler
	[
		"HandleHeal",
		{
			null = _this spawn
			{
				private _player = _this #0;

				if !(captive _player) exitWith {};

				if
				(
					allUnits findIf
					{
						(_x knowsAbout player > 1.4) && {
						(side _x == Invaders) || {
						(side _x == Occupants) }}
					} != -1
				)
				then
				{
					[_player, false] remoteExec ["setCaptive", 0, _player];
					_player setCaptive false;
				}
				else
				{
					_city = [citiesX, _player] call BIS_fnc_nearestPosition;
					_size = [_city] call A3A_fnc_sizeMarker;
					_dataX = server getVariable _city;

					if ((random 100 < _dataX #2) && {
						(_player distance getMarkerPos _city < _size * 1.5) })
					then
					{
						null = [_player, false] remoteExec ["setCaptive", 0, _player];
						_player setCaptive false;
					};
				};
			};
		}
	];

	player addEventHandler
	[
		"WeaponAssembled",
		{
			null = _this spawn
			{
				private _veh = _this #1;

				// will flip/capture if already initialized
				null = _veh, teamPlayer] call A3A_fnc_AIVEHinit;

				if !(_veh isKindOf "StaticWeapon") exitWith {};

				if !(_veh in staticsToSave)
				then
				{
					staticsToSave pushBack _veh;
					publicVariable "staticsToSave";
				};

				_markersX = markersX select { sidesX getVariable [_x, sideUnknown] == teamPlayer };
				_pos = position _veh;

				if (_markersX findIf { _pos inArea _x } != -1)
				then
				{
					null =
					[
						"Static Deployed",
						"Static weapon has been deployed for use in a nearby zone, and will be used by garrison militia if you leave it here the next time the zone spawns"
					] call A3A_fnc_customHint;
				};
			};
		}
	];

	player addEventHandler
	[
		"WeaponDisassembled",
		{
			null = _this spawn
			{
				_bag1 = _this #1;
				_bag2 = _this #2;

				null = [_bag1] remoteExec ["A3A_fnc_postmortem", 2];
				null = [_bag2] remoteExec ["A3A_fnc_postmortem", 2];
			};
		}
	];

	null = [true] spawn A3A_fnc_reinitY;
	null = [player] execVM "OrgPlayers\unitTraits.sqf";
	null = [] spawn A3A_fnc_statistics;
}
else
{
	_oldUnit setVariable ["spawner", nil, true];
	_newUnit setVariable ["spawner", true, true];
	null = [player] call A3A_fnc_dress;

	if (hasACE) then { null = [] call A3A_fnc_ACEpvpReDress; };
};
