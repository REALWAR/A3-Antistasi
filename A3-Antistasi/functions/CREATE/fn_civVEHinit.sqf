private _veh = _this #0;

if (_veh isKindOf "Car")
then
{
	_veh addEventHandler [
		"HandleDamage",
		{
			if (((_this #1) find "wheel" != -1) && {
				(_this #4 == "") && {
				!(isPlayer driver (_this #0)) }})
			exitWith { 0 };
		}
	];
};

null = [_veh] spawn A3A_fnc_cleanserVeh;

_veh addEventHandler
[
	"Killed",
	{
		params ["_unit"];
		_unit removeEventHandler ["Killed", _thisEventHandler];
		null = [_this #0] spawn A3A_fnc_postmortem;
	}
];

if ((count crew _veh == 0) && {
	(activeGREF) && {
	!(hasIFA) }})
then
{
	sleep 10;

	if (isMultiplayer)
	then { null = [_veh, false] remoteExec ["enableSimulationGlobal", 2]; }
	else { _veh enableSimulation false; };

	_veh addEventHandler
	[
		"GetIn",
		{
			null = _this spawn
			{
				_veh = _this #0;

				if (!simulationEnabled _veh)
				then
				{
					if (isMultiplayer)
					then { null = [_veh, true] remoteExec ["enableSimulationGlobal", 2]; }
					else { _veh enableSimulation true; }
				};

				null = [_veh] spawn A3A_fnc_VEHdespawner;
			};
		}
	];

	_veh addEventHandler
	[
		"HandleDamage",
		{
			null = _this spawn
			{
				_veh = _this #0;

				if !(simulationEnabled _veh)
				then
				{
					if (isMultiplayer)
					then { null = [_veh, true] remoteExec ["enableSimulationGlobal", 2]; }
					else { _veh enableSimulation true; }
				};
			};
		}
	];
};
