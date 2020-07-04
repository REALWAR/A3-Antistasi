_this call A3A_fnc_initClient;

[] spawn {

	private _fnc_checkTeamSpeakServer = {
		params ["_serverName", "_time"];
		if ((call TFAR_fnc_getTeamSpeakServerName) == _serverName) exitwith {};

		cutText ["", "BLACK FADED", _time + 2];
		_time = _time + time;

		waitUntil {
			Sleep 2;
			["<t size='2.5' color='#FF0000'>Вы не подключены<br />к TeamSpeak серверу!<br /><br />IP адрес: <br /><t color='#00ff00'>realwar",0,0,1] spawn BIS_fnc_dynamicText;
			if (((call TFAR_fnc_getTeamSpeakServerName) == _serverName) || (time > _time)) exitWith {true};
			false
		};

		cutText ["", "BLACK IN", 2];
		if ((call TFAR_fnc_getTeamSpeakServerName) == _serverName) exitwith {};
		["Endts", true, 2] call BIS_fnc_endMission;
	};

	waitUntil {
		sleep 120;
		["ARMA 3 REALWAR", 60] call _fnc_checkTeamSpeakServer;
		false
	};
};