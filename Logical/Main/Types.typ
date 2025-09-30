
TYPE
	StateEnum : 
		( (*Main state enum*)
		INIT, (*Initial state*)
		POWER_ON, (*Power on the assembly*)
		ADD_SHUTTLES, (*Add shuttles to the sector*)
		GET_SHUTTLE_INIT, (*Get shuttles on the assembly - init FUBs*)
		GET_SHUTTLE, (*Get shuttle on the assembly*)
		GET_SHUTTLE_WAIT, (*Wait for shuttle to be read*)
		SET_USERID, (*Set a UserID to the shuttle*)
		START_MOVEMENT, (*Start movement for all shuttles and axis*)
		READY, (*Application running*)
		HALT_SHUTTLES, (*Execute a stop without power off and deletion of shuttles*)
		DELETE_SHUTTLES, (*Delete all shuttles*)
		POWER_OFF, (*Power off the assembly*)
		ERROR (*Error*)
		);
	StateAxisEnum : 
		( (*Axis state enum*)
		AXIS_INIT, (*Initial state*)
		AXIS_POWER_ON, (*Power on the axis*)
		AXIS_HOME, (*Home the axis*)
		AXIS_READY, (*Axis is ready and can be used*)
		AXIS_POWER_OFF, (*Power off the axis*)
		AXIS_ERROR (*Error*)
		);
	EntryStateEnum : 
		( (*Entry state enum*)
		ENTRY_INIT, (*Initial state*)
		ENTRY_CHECK_TRIGGER, (*Check if shuttle moved over the trigger*)
		ENTRY_GET_SHUTTLE, (*Get the shuttle reference from the trigger*)
		ENTRY_GET_SHUTTLEID, (*Get the shuttle ID to catch the virtual shuttle*)
		ENTRY_CATCH_SHUTTLE, (*Catch the shuttles*)
		ENTRY_ERROR, (*Error*)
		ENTRY_ABORT_CATCH (*Abort the catch mode*)
		);
	ExitStateEnum : 
		( (*Exit state enum*)
		EXIT_INIT, (*Initial state*)
		EXIT_CHECK_TRIGGER, (*Check if shuttle moved over the trigger*)
		EXIT_GET_SHUTTLE, (*Get the shuttle reference from the trigger*)
		EXIT_GET_SHUTTLEID, (*Get the shuttle ID to catch the virtual shuttle*)
		EXIT_CYCMOVEVEL, (*Execute cyclic velocity*)
		EXIT_ERROR (*Error*)
		);
	ClearStateEnum : 
		( (*Clear state enum*)
		CLEAR_INIT, (*Initial state*)
		CLEAR_CHECK_TRIGGER, (*Check if shuttle moved over the trigger*)
		CLEAR_GET_SHUTTLE, (*Get the shuttle reference from the trigger*)
		CLEAR_MOVE_SH_ELASTIC, (*Move the shuttle elastic*)
		CLEAR_ERROR (*Error*)
		);
	AddShuttleStateEnum : 
		( (*Add shuttles to the trak enum*)
		ADDSHUTTLE_INIT, (*Initial state*)
		ADDSHUTTLE_CLOSE_BARRIER, (*Close the barrier*)
		ADDSHUTTLE_ADD_SHUTTLE, (*Add shuttle to the trak*)
		ADDSHUTTLE_CHECK_CREATED, (*Check if the shuttle was created*)
		ADDSHUTTLE_POWER_OFF_SEGMENT,
		ADDSHUTTLE_POWER_ON_SEGMENT,
		ADDSHUTTLE_GET_SHUTTLE,
		ADDSHUTTLE_SET_USERID,
		ADDSHUTTLE_MOVESHUTTLE,
		ADDSHUTTLE_OPEN_BARRIER, (*Open the barrier*)
		ADDSHUTTLE_RESET, (*Reset all FUBs*)
		ADDSHUTTLE_ERROR (*Error*)
		);
	ShuttleInitDataType : 	STRUCT  (*Initial data for creating shuttles*)
		Position : ARRAY[0..MAX_SHUTTLES_MIN_ONE]OF LREAL; (*Position on the sector*)
		ID : ARRAY[0..MAX_SHUTTLES_MIN_ONE]OF STRING[32]; (*ID of the shuttle*)
	END_STRUCT;
END_TYPE
