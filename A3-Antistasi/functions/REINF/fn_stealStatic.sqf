params ["_static", "_player"];

if (!alive _static) exitWith
{
    hint "You cannot steal a destroyed static weapon";
};

if (alive gunner _static) exitWith
{
    hint "You cannot steal a static weapon when someone is using it";
};

if ((alive assignedGunner _static) && (!isPlayer (assignedGunner _static))) exitWith
{
    hint "The gunner of this static weapon is still alive";
};

if (activeGREF && ((typeOf _static == staticATteamPlayer) || (typeOf _static == staticAAteamPlayer))) exitWith
{
    hint "This weapon cannot be dissassembled";
};

private _marker = _static getVariable "StaticMarker";

if (!(sidesX getVariable [_marker,sideUnknown] == teamPlayer)) exitWith
{
    hint "You have to conquer this zone in order to be able to steal this Static Weapon";
};

_static setOwner (owner _player);
private _staticClass =	typeOf _static;
private _staticComponents = getArray (configFile >> "CfgVehicles" >> _staticClass >> "assembleInfo" >> "dissasembleTo");

deleteVehicle _static;

//We need to create the ground weapon holder first, otherwise it won't spawn exactly where we tell it to.
private _groundWeaponHolder = createVehicle ["GroundWeaponHolder", (getPosATL _player), [], 0, "CAN_COLLIDE"];

for "_i" from 0 to ((count _staticComponents) - 1) do
	{
		_groundWeaponHolder addBackpackCargoGlobal [(_staticComponents select _i), 1];
	};

[_groundWeaponHolder] call A3A_fnc_AIVEHinit;

/* [_bag1] call A3A_fnc_AIVEHinit;
[_bag2] call A3A_fnc_AIVEHinit; */

hint "Weapon Stolen. It won't despawn when you assemble it again";
