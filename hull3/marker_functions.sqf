#include "hull3_macros.h"

#include "\userconfig\hull3\log\marker.h"
#include "logbook.h"


hull3_marker_fnc_preInit = {
    if (!isDedicated) then {
        hull3_marker_rawGroupMarkers = [];
        hull3_marker_updatableMarkers = [];
        hull3_marker_groups = [];
        hull3_marker_units = [];
        hull3_marker_fireTeam = [];
        hull3_marker_custom = [];
        hull3_marker_defaultDelay = ["Marker", "defaultDelay"] call hull3_config_fnc_getNumber;
    };
    DEBUG("hull3.marker","Marker functions preInit finished.");
};

hull3_marker_fnc_initMarker = {
    FUN_ARGS_3(_unit,_markerText,_markerColor);

    PUSH(hull3_marker_rawGroupMarkers, AS_ARRAY_4(_unit,_unit getVariable "hull3_gear_class",_markerText,_markerColor));
};

hull3_marker_fnc_addMarkers = {
    [] call hull3_marker_fnc_addGroupAndUnitMarkers;
    [player] call hull3_marker_fnc_addFireTeamMarkers;
    ["marker.group.created", []] call hull3_event_fnc_emitEvent;
};

hull3_marker_fnc_addGroupAndUnitMarkers = {
    {
        if (side player == side (_x select 0)) then {
            _x call hull3_marker_fnc_addGroupAndUnitMarker;
        };
    } foreach hull3_marker_rawGroupMarkers;
    if (hull3_marker_isGroupEnabled) then {
        PUSH(hull3_marker_updatableMarkers,AS_ARRAY_2(hull3_marker_groups,hull3_marker_fnc_updateGroupMarkers));
        PUSH(hull3_marker_updatableMarkers,AS_ARRAY_2(hull3_marker_units,hull3_marker_fnc_updateUnitMarkers));
    };
    hull3_marker_rawGroupMarkers = nil;
};

hull3_marker_fnc_addGroupAndUnitMarker = {
    FUN_ARGS_4(_unit,_gearClass,_markerText,_markerColor);

    private "_markerName";
    call {
        if (toLower _gearClass in ["ftl", "matg", "hatg", "mmgg"]) exitWith {
            [_unit, "b_inf", _markerText, _markerColor] call hull3_marker_fnc_addGroupMarker;
        };
        if (toLower _gearClass in ["sl", "co"]) exitWith {
            [_unit, "b_hq", _markerText, _markerColor] call hull3_marker_fnc_addGroupMarker;
        };
        if (toLower _gearClass == "p") exitWith {
            [_unit, "b_air", _markerText, _markerColor] call hull3_marker_fnc_addGroupMarker;
        };
        if (toLower _gearClass == "vc") exitWith {
            [_unit, "b_armor", _markerText, _markerColor] call hull3_marker_fnc_addGroupMarker;
        };
        if (toLower _gearClass == "eng") exitWith {
            [_unit, "b_maint", _markerText, _markerColor] call hull3_marker_fnc_addGroupMarker;
        };
        if (toLower _gearClass == "xo") exitWith {
            [_unit, "b_hq", _markerText, _markerColor, [1, 1]] call hull3_marker_fnc_addUnitMarker;
        };
        if (toLower _gearClass == "medic") exitWith {
            [_unit, "b_med", _markerText, _markerColor, ["Marker", "MedicMarker", "size"] call hull3_config_fnc_getArray] call hull3_marker_fnc_addUnitMarker;
        };
        [_unit, "b_unknown", _markerText, _markerColor] call hull3_marker_fnc_addGroupMarker;
    };
};

hull3_marker_fnc_addGroupMarker = {
    FUN_ARGS_4(_unit,_markerType,_markerText,_markerColor);

    (group _unit) setGroupId [_markerText];
    if (hull3_marker_isGroupEnabled) then {
        _markerName = format ["hull3_marker_group_%1_%2", _markerText, group _unit];
        [_markerName, getPosATL _unit, "ICON", _markerType, _markerColor, _markerText] call hull3_marker_fnc_createMarker;
        (group _unit) setVariable ["hull3_marker_group", _markerName, false];
    };
    PUSH(hull3_marker_groups,group _unit);
};

hull3_marker_fnc_addUnitMarker = {
    FUN_ARGS_5(_unit,_markerType,_markerText,_markerColor,_markerSize);

    _markerName = format ["hull3_marker_unit_%1_%2", _markerText, _unit];
    if (hull3_marker_isGroupEnabled) then {
        [_markerName, getPosATL _unit, "ICON", _markerType, _markerColor, _markerText, _markerSize] call hull3_marker_fnc_createMarker;
        _unit setVariable ["hull3_marker_unit", _markerName, false];
    };
    PUSH(hull3_marker_units,_unit);
};

hull3_marker_fnc_updateAllMarkers = {
    if (count hull3_marker_updatableMarkers > 0) then {
        waitUntil {
            {
                [_x select 0] call (_x select 1);
            } foreach hull3_marker_updatableMarkers;
            sleep hull3_marker_defaultDelay;
            false;
        };
    };
};

hull3_marker_fnc_updateCustomMarkers = {
    waitUntil {
        {
            _x call hull3_marker_fnc_updateCustomMarker;
        } foreach hull3_marker_custom;
        sleep 1;
        false;
    };
};

hull3_marker_fnc_updateGroupMarkers = {
    FUN_ARGS_1(_groups);

    {
        private ["_group", "_markerName"];
        _group = _x;
        _markerName = _group getVariable "hull3_marker_group";
        if ({alive _x} count units _group > 0) then {
            _markerName setMarkerPosLocal getPosASL leader _group;
        }
    } foreach _groups;
};

hull3_marker_fnc_updateUnitMarkers = {
    FUN_ARGS_1(_units);

    {
        private ["_unit", "_markerName"];
        _unit = _x;
        _markerName = _unit getVariable "hull3_marker_unit";
        if (alive _unit) then {
            _markerName setMarkerPosLocal getPosASL _unit;
        }
    } foreach _units;
};

hull3_marker_fnc_updateFireTeamMarkers = {
    FUN_ARGS_1(_fireTeam);

    {
        private ["_unit", "_markerName"];
        _unit = _x;
        _markerName = _unit getVariable "hull3_marker_fireTeam";
        if (alive _unit) then {
            _markerName setMarkerPosLocal getPosASL _unit;
            _markerName setMarkerDirLocal getDir _unit;
        }
    } foreach _fireTeam;
};

hull3_marker_fnc_updateCustomMarker = {
    FUN_ARGS_5(_markerName,_isActive,_lastUpdate,_object,_delay);

    if (_isActive && {alive _object} && {time - _lastUpdate >= _delay}) then {
        _markerName setMarkerPosLocal getPosASL _object;
        _this set [2, time];
    };
};

hull3_marker_fnc_addFireTeamMarkers = {
    FUN_ARGS_1(_unit);

    if (hull3_marker_isFireTeamEnabled) then {
        {
            [_x] call hull3_marker_fnc_addFireTeamMarker;
        } foreach (units group _unit);
        PUSH(hull3_marker_updatableMarkers,AS_ARRAY_2(hull3_marker_fireTeam,hull3_marker_fnc_updateFireTeamMarkers));
    };
};

hull3_marker_fnc_addFireTeamMarker = {
    FUN_ARGS_1(_unit);

    _markerName = format ["hull3_marker_fireTeam_%1", _unit];
    [
        _markerName,
        getPosATL _unit,
        "ICON",
        "mil_triangle",
        ["Marker", "FireTeamMemberMarker", "color"] call hull3_config_fnc_getText,
        "",
        ["Marker", "FireTeamMemberMarker", "size"] call hull3_config_fnc_getArray
    ] call hull3_marker_fnc_createMarker;
    _unit setVariable ["hull3_marker_fireTeam", _markerName];
    PUSH(hull3_marker_fireTeam,_unit);
};

hull3_marker_fnc_addCustomSideMarker = {
    FUN_ARGS_2(_object,_side);

    if (side player == _side) then {
        DECLARE(_arguments) = [_object];
        for "_i" from 2 to (count _this) - 1 do {
            PUSH(_arguments,_this select _i);
        };
        _arguments call hull3_marker_fnc_addCustomMarker;
    };
};

hull3_marker_fnc_addCustomMarker = {
    FUN_ARGS_1(_object);

    private ["_delay", "_shape", "_type", "_color", "_size", "_text", "_markerIndex", "_markerName"];
    if (count _this < 7) then {_text = ["Marker", "DefaultCustomMarker", "text"] call hull3_config_fnc_getText}      else {_text  = _this select 6};
    if (count _this < 6) then {_size = ["Marker", "DefaultCustomMarker", "size"] call hull3_config_fnc_getArray}     else {_size  = _this select 5};
    if (count _this < 5) then {_color = ["Marker", "DefaultCustomMarker", "color"] call hull3_config_fnc_getText}    else {_color = _this select 4};
    if (count _this < 4) then {_type = ["Marker", "DefaultCustomMarker", "type"] call hull3_config_fnc_getText}      else {_type  = _this select 3};
    if (count _this < 3) then {_shape = ["Marker", "DefaultCustomMarker", "shape"] call hull3_config_fnc_getText}    else {_shape = _this select 2};
    if (count _this < 2) then {_delay = hull3_marker_defaultDelay}                                                   else {_delay = _this select 1};
    _markerIndex = count hull3_marker_custom;
    _markerName = format ["hull3_marker_custom_%1", _markerIndex];
    [_markerName, getPosATL _object, _shape, _type, _color, _text, _size] call hull3_marker_fnc_createMarker;
    PUSH(hull3_marker_custom,AS_ARRAY_5(_markerName,true,time,_object,_delay));

    _markerIndex;
};

hull3_marker_fnc_deactivateCustomMarker = {
    FUN_ARGS_1(_markerIndex);

    if (count hull3_marker_custom > _markerIndex) then {
        (hull3_marker_custom select _markerIndex) set [1, fale];
    };
};

hull3_marker_fnc_activateCustomMarker = {
    FUN_ARGS_1(_markerIndex);

    if (count hull3_marker_custom > _markerIndex) then {
        (hull3_marker_custom select _markerIndex) set [1, true];
    };
};

hull3_marker_fnc_deleteCustomMarker = {
    FUN_ARGS_1(_markerIndex);

    if (count hull3_marker_custom > _markerIndex) then {
        DECLARE(_markerData) = hull3_marker_custom select _markerIndex;
        deleteMarkerLocal  (_markerData select 0);
        _markerData set [1, false];
    };
};

hull3_marker_fnc_createMarker = {
    FUN_ARGS_7(_name,_position,_shape,_type,_color,_text,_size);

    createMarkerLocal [_name, _position];
    _name setMarkerShapeLocal _shape;
    _name setMarkerTypeLocal _type;
    _name setMarkerColorLocal _color;
    _name setMarkerTextLocal _text;
    if (!isNil "_size") then {
        _name setMarkerSizeLocal _size;
    };

    _name;
};