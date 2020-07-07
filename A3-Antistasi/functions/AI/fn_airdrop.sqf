params
[
	"_veh",
	"_groupX",
	"_markerX",
	"_originX",
	["_reinf", false]
];

private _positionX = _markerX;

if (_markerX isEqualType "") then { _positionX = getMarkerPos _markerX; };

private _groupPilot = group driver _veh;
{_x disableAI "TARGET"; _x disableAI "AUTOTARGET"} foreach units _groupPilot;
private _dist = 500;
private _distEng = if (_veh isKindOf "Helicopter") then {1000} else {2000};
private _distExit = if (_veh isKindOf "Helicopter") then {400} else {1000};
private _orig = getMarkerPos _originX;


private _engagepos = [];
private _landpos = [];
private _exitpos = [];

private _randAng = random 360;

while {true} do
{
 	_landpos = _positionX getPos [_dist, _randang];

 	if (!surfaceIsWater _landpos)
	exitWith {false};

   _randAng = _randAng + 1;
};

_randang = _randang + 90;

while {true} do
{
 	_exitpos = _positionX getPos [_distExit, _randang];
 	_randang = _randang + 1;

 	if ((!surfaceIsWater _exitpos) && {
		(_exitpos distance _positionX > 300) })
	exitWith {false};
};

_randang = [_landpos, _exitpos] call BIS_fnc_dirTo;
_randang = _randang - 180;

private _engagepos = _landpos getPos [_distEng, _randang];
{ _x set [2, 300]; } forEach [_landPos, _exitPos, _engagePos];
{ _x setBehaviour "CARELESS"; } forEach units _groupPilot;
_veh flyInHeight 300;
_veh setCollisionLight false;

private _wp = _groupPilot addWaypoint [_engagepos, 0];
_wp setWaypointType "MOVE";
//_wp setWaypointSpeed "LIMITED";

private _wp1 = _groupPilot addWaypoint [_landpos, 1];
_wp1 setWaypointType "MOVE";
_wp1 setWaypointSpeed "LIMITED";

private _wp2 = _groupPilot addWaypoint [_exitpos, 2];
_wp2 setWaypointType "MOVE";

private _wp3 = _groupPilot addWaypoint [_orig, 3];
_wp3 setWaypointType "MOVE";
_wp3 setWaypointSpeed "NORMAL";
_wp3 setWaypointStatements ["true", "deleteVehicle (vehicle this); {deleteVehicle _x} forEach thisList"];

{ removebackpack _x; _x addBackpack "B_Parachute"; } forEach units _groupX;

waitUntil
{
	sleep 1;

	(currentWaypoint _groupPilot == 3) || {
	!(alive _veh) || {
	!(canMove _veh) }}
}

//[_veh] call A3A_fnc_entriesLand;

if (alive _veh)
then
{
	_veh setCollisionLight true;

	{
		waitUntil {sleep 0.5; !surfaceIsWater (position _x)};
		_x allowDamage false;
		unAssignVehicle _x;
		//Move them into alternating left/right positions, so their parachutes are less likely to kill each other
		private "_pos";

		if (_forEachIndex % 2 == 0)
		then { _pos = _veh modeltoWorld [7, -20, -5]; }
		else { _pos = _veh modeltoWorld [-7, -20, -5]; };

		_x setPos _pos;
		null = _x spawn {sleep 5; _this allowDamage true; };
  	} forEach units _groupX;
};

private ["_wp4", "_wp5"];

if !(_reinf)
then
{
   _posLeader = position (leader _groupX);
   _posLeader set [2, 0];
   _wp5 = _groupX addWaypoint [_posLeader, 0];
   _wp5 setWaypointType "MOVE";
   _wp5 setWaypointStatements ["true", "(group this) spawn A3A_fnc_attackDrillAI"];
   _wp4 = _groupX addWaypoint [_positionX, 1];
   _wp4 setWaypointType "MOVE";
   _wp4 setWaypointStatements ["true", "{if (side _x != side this) then {this reveal [_x, 4]}} forEach allUnits"];
   _wp4 = _groupX addWaypoint [_positionX, 2];
   _wp4 setWaypointType "SAD";
}
else
{
   _wp4 = _groupX addWaypoint [_positionX, 0];
   _wp4 setWaypointType "MOVE";
   _wp4 setWaypointStatements ["true", "nul = [(thisList select {alive _x}), side this, (group this) getVariable [""reinfMarker"", """"], 0] remoteExec [""A3A_fnc_garrisonUpdate"", 2];[group this] spawn A3A_fnc_groupDespawner; reinfPatrols = reinfPatrols - 1; publicVariable ""reinfPatrols"";"];
};
