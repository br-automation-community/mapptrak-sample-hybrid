(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    B&R 
 * Created:   July 22, 2025/2:18 PM 
 * Description: Exit from the trak to the conveyor, set a cyclic velocity control
 *********************************************************************************)

ACTION ExitSegment: 

	// Reset the state machine and all FUBs after a stop or halt command
	// Avoid shuttles to go on the conveyor
	IF (Paused OR EnableStations = FALSE) AND ExitState <> EXIT_INIT THEN
		ExitState	:= EXIT_ERROR;
	END_IF;
	
	CASE ExitState OF
		// Wait for enable the station
		EXIT_INIT:
			IF EnableStations AND NOT(Paused) THEN
				AddTicket	:= TRUE;
				ExitState	:= EXIT_CHECK_TRIGGER;
				MC_BR_BarrierReadInfo_Exit.Enable	:= TRUE;
			END_IF;
		
		// Check for a shuttle passing the trigger
		EXIT_CHECK_TRIGGER:
			MC_BR_TrgPointEnable_Exit.Enable		:= TRUE;
		
			IF MC_BR_TrgPointEnable_Exit.Valid AND MC_BR_TrgPointEnable_Exit.EventCount > 0 THEN
				ExitState	:= EXIT_GET_SHUTTLE;
			ELSIF MC_BR_TrgPointEnable_Exit.Error THEN
				ErrorInfo	:= 'Error in TrgPointEnable Exit';
				State		:= ERROR;
				ExitState	:= EXIT_ERROR;
			END_IF;
		
		// Get the shuttle exiting the trak
		EXIT_GET_SHUTTLE:
			MC_BR_TrgPointReadInfo_Exit.Execute	:= TRUE;
		
			IF MC_BR_TrgPointReadInfo_Exit.Done THEN				
				MC_BR_TrgPointReadInfo_Exit.Execute	:= FALSE;
				ExitShuttle	:= MC_BR_TrgPointReadInfo_Exit.TrgPointInfo.Axis;
				ExitState		:= EXIT_GET_SHUTTLEID;
			ELSIF MC_BR_TrgPointReadInfo_Exit.Error THEN
				ErrorInfo	:= 'Error in TrgPointReadInfo Exit';
				State		:= ERROR;
				ExitState	:= EXIT_ERROR;
			END_IF;
			
		// Read shuttle information
		EXIT_GET_SHUTTLEID:
			MC_BR_ShReadInfo_Exit.Axis		:= ADR(ExitShuttle);
			MC_BR_ShReadInfo_Exit.Enable	:= TRUE;
			
			IF MC_BR_ShReadInfo_Exit.Valid THEN
				MC_BR_ShReadInfo_Exit.Enable	:= FALSE;
				ExitState	:= EXIT_CYCMOVEVEL;
				
				Message		:= 'Shuttle "';
				brsstrcat(ADR(Message),ADR(MC_BR_ShReadInfo_Exit.ShuttleInfo.AdditionalInfo.UserID));
				brsstrcat(ADR(Message),ADR('" left the trak and entered the conveyor'));
				AddMessage	:= TRUE;
				AddImage	:= 1;
			ELSIF MC_BR_ShReadInfo_Exit.Error THEN
				ErrorInfo	:= 'Error in ShReadInfo Exit';
				State		:= ERROR;
				ExitState	:= EXIT_ERROR;
			END_IF;
		
		// Set a cyclic MoveVel to the shuttle with the same speed as the conveyor
		EXIT_CYCMOVEVEL:
			FOR Index := 0 TO MAX_SHUTTLES_MIN_ONE DO
				IF Shuttle[Index].controlif	= ExitShuttle.controlif THEN
					MC_BR_MoveCyclicTcpVel_0[Index].Enable	:= TRUE;
					EXIT;
				END_IF;
			END_FOR;
			IF MC_BR_MoveCyclicTcpVel_0[Index].Valid THEN
				ExitState	:= EXIT_CHECK_TRIGGER;
			END_IF;
			
		// Error state, reset all FUBs
		EXIT_ERROR:
			MC_BR_TrgPointEnable_Exit.Enable	:= FALSE;
			MC_BR_TrgPointReadInfo_Exit.Execute	:= FALSE;
	
			MC_BR_ShReadInfo_Exit.Enable		:= FALSE;
		
			MC_BR_BarrierCmd_Exit.Execute		:= FALSE;
			
			MC_BR_TrgPointEnable_CheckFree.Enable	:= FALSE;
		
			ExitState	:= EXIT_INIT;

	END_CASE;
	
	MC_BR_TrgPointEnable_CheckFree.Enable		:= ExitState <> EXIT_ERROR AND ExitState <> EXIT_INIT;
	IF MC_BR_TrgPointEnable_CheckFree.Valid AND MC_BR_TrgPointEnable_CheckFree.EventCount > 0 THEN
		MC_BR_TrgPointEnable_CheckFree.Enable	:= FALSE;
		AddTicket	:= TRUE;
	ELSIF MC_BR_TrgPointEnable_CheckFree.Error THEN
		ErrorInfo	:= 'Error in TrgPointEnable CheckFree';
		State		:= ERROR;
		ExitState	:= EXIT_ERROR;
	END_IF;
	
	// If no movement of the conveyor is active, close the barrier to prevent shuttles going onto the conveyor
	IF (MpAxisBasic_0.MoveActive = FALSE OR MpAxisBasic_0.Velocity = 0.0 OR StopConveyor OR Paused) AND 
		MC_BR_BarrierReadInfo_Exit.BarrierInfo.Status <> mcACPTRAK_BARRIER_CLOSED AND MC_BR_BarrierReadInfo_Exit.Valid THEN
		
		AddTicket	:= FALSE;
		MC_BR_BarrierCmd_Exit.Command	:= mcACPTRAK_BARRIER_CLOSE;
		MC_BR_BarrierCmd_Exit.Execute	:= TRUE;
		
	// Open the conveyor when the movement is active
	ELSIF MpAxisBasic_0.MoveActive AND MpAxisBasic_0.Velocity <> 0.0 AND StopConveyor = FALSE AND Paused = FALSE AND AddTicket AND MC_BR_BarrierReadInfo_Exit.BarrierInfo.RemainingTickets = 0 AND
		(MC_BR_BarrierReadInfo_Exit.BarrierInfo.Status = mcACPTRAK_BARRIER_CLOSED OR MC_BR_BarrierReadInfo_Exit.BarrierInfo.Status = mcACPTRAK_BARRIER_TICKETING) AND MC_BR_BarrierReadInfo_Exit.Valid THEN
		
		AddTicket	:= FALSE;
		MC_BR_BarrierCmd_Exit.AdvancedParameters.TicketCount	:= 1;
		MC_BR_BarrierCmd_Exit.Command	:= mcACPTRAK_BARRIER_ADD_TICKETS;
		MC_BR_BarrierCmd_Exit.Execute	:= TRUE;
	END_IF;
	
	// Reset the barrier command
	IF MC_BR_BarrierCmd_Exit.Done THEN
		MC_BR_BarrierCmd_Exit.Execute	:= FALSE;
	ELSIF MC_BR_BarrierCmd_Exit.Error THEN
		ErrorInfo	:= 'Error in BarrierCmd Exit';
		State		:= ERROR;
		ExitState	:= EXIT_ERROR;
	END_IF;
	
	// Check error for reading barrier info
	IF MC_BR_BarrierReadInfo_Exit.Error THEN
		MC_BR_BarrierReadInfo_Exit.Enable	:= FALSE;
		ErrorInfo	:= 'Error in BarrierReadInfo Exit';
		State		:= ERROR;
		ExitState	:= EXIT_ERROR;
	END_IF;
	
	// Call the FUBs
	MC_BR_TrgPointEnable_Exit();
	MC_BR_TrgPointReadInfo_Exit();
	
	MC_BR_ShReadInfo_Exit();
		
	MC_BR_BarrierCmd_Exit();
	MC_BR_BarrierReadInfo_Exit();
	
	MC_BR_TrgPointEnable_CheckFree();
	
END_ACTION
