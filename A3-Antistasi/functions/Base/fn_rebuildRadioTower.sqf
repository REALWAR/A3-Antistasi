// Repairs a radio tower.
// Parameter should be present in antennasDead array
private _file = "fn_rebuildRadioTower";

if (!isServer)
exitWith { null = [1, "Server-only function miscalled", _file] call A3A_fnc_log; };

params ["_antenna"];

if !(_antenna in antennasDead)
exitWith { null = [1, "Attempted to rebuild invalid radio tower", _file] call A3A_fnc_log; };

null = [2, format["Repairing Antenna %1", str _antenna], _file] call A3A_fnc_log;

antennasDead = antennasDead - [_antenna]; publicVariable "antennasDead";
null = [_antenna] call A3A_fnc_repairRuinedBuilding;
antennas pushBack _antenna; publicVariable "antennas";

{
	if ([antennas, _x] call BIS_fnc_nearestPosition == _antenna)
	then { null = [_x, true] spawn A3A_fnc_blackout; };
} forEach citiesX;

private _mrkFinal = createMarker [format ["Ant%1", mapGridPosition _antenna], getPos _antenna];
_mrkFinal setMarkerShape "ICON";
_mrkFinal setMarkerType "loc_Transmitter";
_mrkFinal setMarkerColor "ColorBlack";
_mrkFinal setMarkerText "Radio Tower";
mrkAntennas pushBack _mrkFinal;
publicVariable "mrkAntennas";

_antenna addEventHandler
[
	"Killed",
	{
		params ["_unit"];
		_unit removeAllEventHandlers "Killed";

		null = _this spawn
		{
			params ["_unit"];

			{
				if ([antennas, _x] call BIS_fnc_nearestPosition == _unit)
				then { null = [_x, false] spawn A3A_fnc_blackout; };
			} forEach citiesX;

			_mrk = [mrkAntennas, _unit] call BIS_fnc_nearestPosition;
			mrkAntennas = mrkAntennas - [_mrk];
			deleteMarker _mrk;
			antennas = antennas - [_unit];
			antennasDead = antennasDead + [_unit];
			publicVariable "antennas";
			publicVariable "antennasDead";
			publicVariable "mrkAntennas";
			null = ["TaskSucceeded", ["", "Radio Tower Destroyed"]] remoteExec ["BIS_fnc_showNotification", teamPlayer];
			null = ["TaskFailed", ["", "Radio Tower Destroyed"]] remoteExec ["BIS_fnc_showNotification", Occupants];
		};
	}
];
