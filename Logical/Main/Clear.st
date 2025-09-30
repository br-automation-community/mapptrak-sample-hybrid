(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    B&R 
 * Created:   July 22, 2025/2:18 PM 
 * Description: Clear station to move the shuttles elastic after the conveyor
 *********************************************************************************)

ACTION Clear: 

	// Reset the state machine and all FUBs after a stop command
	IF EnableStations = FALSE AND ClearState <> CLEAR_INIT THEN
		ClearState	:= CLEAR_ERROR;
	END_IF;
	
	// Reset the state machine after a Halt command
	IF Paused THEN
		ClearState	:= CLEAR_ERROR;
	END_IF;
	
	CASE ClearState OF
		// Wait for enabling the station
		CLEAR_INIT:
			IF EnableStations THEN
				ClearState	:= CLEAR_CHECK_TRIGGER;
			END_IF;
		
		// Check for trigger event
		CLEAR_CHECK_TRIGGER:
			MC_BR_TrgPointEnable_Clear.Enable		:= TRUE;
		
			IF MC_BR_TrgPointEnable_Clear.Valid AND MC_BR_TrgPointEnable_Clear.EventCount > 0 THEN
				ClearState	:= CLEAR_GET_SHUTTLE;
			ELSIF MC_BR_TrgPointEnable_Clear.Error THEN
				ErrorInfo	:= 'Error in TrgPointEnable Clear';
				State		:= ERROR;
				ClearState	:= CLEAR_ERROR;
			END_IF;
		
		// Get the passed shuttle
		CLEAR_GET_SHUTTLE:
			MC_BR_TrgPointReadInfo_Clear.Execute	:= TRUE;
		
			IF MC_BR_TrgPointReadInfo_Clear.Done THEN
				MC_BR_TrgPointReadInfo_Clear.Execute	:= FALSE;
				ClearShuttle	:= MC_BR_TrgPointReadInfo_Clear.TrgPointInfo.Axis;
				ClearState		:= CLEAR_MOVE_SH_ELASTIC;
			ELSIF MC_BR_TrgPointReadInfo_Clear.Error THEN
				ErrorInfo	:= 'Error in TrgPointReadInfo Clear';
				State		:= ERROR;
				ClearState	:= CLEAR_ERROR;
			END_IF;
			
		// Move the shuttle elastic
		CLEAR_MOVE_SH_ELASTIC:
			MC_BR_ElasticMoveVel_Clear.Axis			:= ADR(ClearShuttle);
			MC_BR_ElasticMoveVel_Clear.Velocity		:= Velocity;
			MC_BR_ElasticMoveVel_Clear.Acceleration	:= Acceleration;
			MC_BR_ElasticMoveVel_Clear.Deceleration	:= Deceleration;
			MC_BR_ElasticMoveVel_Clear.Direction	:= mcDIR_POSITIVE;
			MC_BR_ElasticMoveVel_Clear.Execute		:= NOT(Paused);
			
			IF EDGEPOS(MC_BR_ElasticMoveVel_Clear.Active) THEN
				MC_BR_ElasticMoveVel_Clear.Execute	:= FALSE;
				ClearState	:= CLEAR_CHECK_TRIGGER;
			ELSIF MC_BR_ElasticMoveVel_Clear.Error THEN
				ErrorInfo	:= 'Error in ElasticMoveVel Clear';
				State		:= ERROR;
				ClearState	:= CLEAR_ERROR;
			END_IF;
		
		// Error state, reset all FUBs
		CLEAR_ERROR:
			MC_BR_TrgPointEnable_Clear.Enable		:= FALSE;
			MC_BR_TrgPointReadInfo_Clear.Execute	:= FALSE;
			MC_BR_ElasticMoveVel_Clear.Execute		:= FALSE;
			
			ClearState	:= CLEAR_INIT;
		
	END_CASE;
	
	// Call the FUBs
	MC_BR_TrgPointEnable_Clear();
	MC_BR_TrgPointReadInfo_Clear();
	MC_BR_ElasticMoveVel_Clear();
	
END_ACTION
