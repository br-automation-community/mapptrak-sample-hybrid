(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    B&R 
 * Created:   July 22, 2025/2:18 PM 
 * Description: Entry to the trak from the conveyor, catch all shuttles
 *********************************************************************************)

ACTION EntrySegment: 

	// Reset the state machine and all FUBs after a stop command
	IF EnableStations = FALSE AND EntryState <> ENTRY_INIT AND EntryState <> ENTRY_ABORT_CATCH THEN
		EntryState	:= ENTRY_ERROR;
	END_IF;
	
	CASE EntryState OF
		// Wait for enabling the station
		ENTRY_INIT:
			IF EnableStations AND NOT(Paused) THEN
				EntryState	:= ENTRY_CHECK_TRIGGER;
			END_IF;
		
		// Check for shuttle passed the trigger
		ENTRY_CHECK_TRIGGER:
			MC_BR_TrgPointEnable_Entry.Enable		:= TRUE;
			MC_BR_ShReadInfo_Entry.Enable			:= FALSE;
			MC_BR_SecReadInfo_SimSector.Enable		:= TRUE;
		
			IF MC_BR_TrgPointEnable_Entry.Valid AND MC_BR_TrgPointEnable_Entry.EventCount > 0 THEN
				EntryState	:= ENTRY_GET_SHUTTLE;
			ELSIF MC_BR_TrgPointEnable_Entry.Error THEN
				ErrorInfo	:= 'Error in TrgPointEnable Entry';
				State		:= ERROR;
				EntryState	:= ENTRY_ERROR;
			END_IF;
		
		// Get the passing shuttle
		ENTRY_GET_SHUTTLE:
			MC_BR_TrgPointReadInfo_Entry.Execute	:= TRUE;
		
			IF MC_BR_TrgPointReadInfo_Entry.Done THEN
				MC_BR_TrgPointReadInfo_Entry.Execute	:= FALSE;
				EntryShuttle	:= MC_BR_TrgPointReadInfo_Entry.TrgPointInfo.Axis;
				EntryState		:= ENTRY_GET_SHUTTLEID;
			ELSIF MC_BR_TrgPointReadInfo_Entry.Error THEN
				ErrorInfo	:= 'Error in TrgPointReadInfo Entry';
				State		:= ERROR;
				EntryState	:= ENTRY_ERROR;
			END_IF;
		
		// Get the shuttle virtual ID and velocity (for sim)
		ENTRY_GET_SHUTTLEID:
			MC_BR_ShReadInfo_Entry.Axis		:= ADR(EntryShuttle);
			MC_BR_ShReadInfo_Entry.Enable	:= TRUE;
			
			IF MC_BR_ShReadInfo_Entry.Valid THEN
				VirtShID	:= MC_BR_ShReadInfo_Entry.ShuttleInfo.AdditionalInfo.ID;
				ShVelocity	:= MC_BR_ShReadInfo_Entry.ShuttleInfo.CurrentValues.Velocity;
				EntryState	:= ENTRY_CATCH_SHUTTLE;
				
				Message		:= 'Shuttle "';
				brsstrcat(ADR(Message),ADR(MC_BR_ShReadInfo_Entry.ShuttleInfo.AdditionalInfo.UserID));
				brsstrcat(ADR(Message),ADR('" left the conveyor and entered the trak'));
				AddMessage	:= TRUE;
				AddImage	:= 0;
			ELSIF MC_BR_ShReadInfo_Entry.Error THEN
				ErrorInfo	:= 'Error in ShReadInfo Entry';
				State		:= ERROR;
				EntryState	:= ENTRY_ERROR;
			END_IF;
		
		// Catch the shuttle
		// Use two FUBs to be able to catch two shuttles if one is waiting
		ENTRY_CATCH_SHUTTLE:
			IF NOT(MC_BR_SecAddShuttle_0.Execute) THEN
				// Set velocity if the simulation is active
				// If the simulation is active, wiat until the shuttle reached the position
				IF SimActive AND MC_BR_ShReadInfo_Entry.ShuttleInfo.CurrentValues.SegmentPosition.Position >= 0.0 AND MC_BR_ShReadInfo_Entry.ShuttleInfo.CurrentValues.SegmentPosition.Segment.controlif = Seg_08.controlif (*AND MC_BR_SecReadInfo_SimSector.SectorInfo.ShuttleCount.Count = 0 AND MC_BR_SecReadInfo_SimSector.Valid*) THEN
					MC_BR_SecAddShuttle_0.Velocity	:= ConveyorVelocity;
					MC_BR_SecAddShuttle_0.Execute	:= TRUE;
					EntryState	:= ENTRY_CHECK_TRIGGER;
				ELSIF NOT(SimActive) THEN
					MC_BR_SecAddShuttle_0.Execute	:= TRUE;
					EntryState	:= ENTRY_CHECK_TRIGGER;
				END_IF;
				MC_BR_SecAddShuttle_0.Sector	:= ADR(Sector_2);
				MC_BR_SecAddShuttle_0.Position	:= 0.0;
				MC_BR_SecAddShuttle_0.AdvancedParameters.Mode				:= mcACPTRAK_ADD_CATCH;
				MC_BR_SecAddShuttle_0.AdvancedParameters.VirtualShuttleID	:= VirtShID;
				MC_BR_SecAddShuttle_0.AdvancedParameters.MoveCmd			:= mcACPTRAK_MOV_CMD_ELASTICMOVEVEL;
				MC_BR_SecAddShuttle_0.AdvancedParameters.Velocity			:= ConveyorVelocity;
				MC_BR_SecAddShuttle_0.AdvancedParameters.Acceleration		:= Acceleration;
				MC_BR_SecAddShuttle_0.AdvancedParameters.Deceleration		:= Deceleration;
				MC_BR_SecAddShuttle_0.AdvancedParameters.Direction			:= mcDIR_POSITIVE;
				MC_BR_SecAddShuttle_0.AdvancedParameters.UserID				:= '';
			ELSIF NOT(MC_BR_SecAddShuttle_1.Execute) THEN				
				// Set velocity if the simulation is active
				// If the simulation is active, wiat until the shuttle reached the position
				IF SimActive AND MC_BR_ShReadInfo_Entry.ShuttleInfo.CurrentValues.SegmentPosition.Position >= 0.0 AND MC_BR_ShReadInfo_Entry.ShuttleInfo.CurrentValues.SegmentPosition.Segment.controlif = Seg_08.controlif(*AND MC_BR_SecReadInfo_SimSector.SectorInfo.ShuttleCount.Count = 0 AND MC_BR_SecReadInfo_SimSector.Valid*) THEN
					MC_BR_SecAddShuttle_1.Velocity	:= ConveyorVelocity;
					MC_BR_SecAddShuttle_1.Execute	:= TRUE;
					EntryState	:= ENTRY_CHECK_TRIGGER;
				ELSIF NOT(SimActive) THEN
					MC_BR_SecAddShuttle_1.Execute	:= TRUE;
					EntryState	:= ENTRY_CHECK_TRIGGER;
				END_IF;
				MC_BR_SecAddShuttle_1.Sector	:= ADR(Sector_2);
				MC_BR_SecAddShuttle_1.Position	:= 0.0;
				MC_BR_SecAddShuttle_1.AdvancedParameters.Mode				:= mcACPTRAK_ADD_CATCH;
				MC_BR_SecAddShuttle_1.AdvancedParameters.VirtualShuttleID	:= VirtShID;
				MC_BR_SecAddShuttle_1.AdvancedParameters.MoveCmd			:= mcACPTRAK_MOV_CMD_ELASTICMOVEVEL;
				MC_BR_SecAddShuttle_1.AdvancedParameters.Velocity			:= ConveyorVelocity;
				MC_BR_SecAddShuttle_1.AdvancedParameters.Acceleration		:= Acceleration;
				MC_BR_SecAddShuttle_1.AdvancedParameters.Deceleration		:= Deceleration;
				MC_BR_SecAddShuttle_1.AdvancedParameters.Direction			:= mcDIR_POSITIVE;
				MC_BR_SecAddShuttle_1.AdvancedParameters.UserID				:= '';
				MC_BR_SecAddShuttle_1.Execute	:= TRUE;
			ELSE
				ErrorInfo	:= 'Error, no SecAddShuttle available';
				State		:= ERROR;
				EntryState	:= ENTRY_ERROR;
			END_IF;
		
		// Error state, reset all FUBs
		ENTRY_ERROR:
			MC_BR_TrgPointEnable_Entry.Enable		:= FALSE;
			MC_BR_TrgPointReadInfo_Entry.Execute	:= FALSE;
			MC_BR_SecAddShuttle_0.Execute			:= FALSE;
			MC_BR_SecAddShuttle_1.Execute			:= FALSE;
			MC_BR_SecReadInfo_SimSector.Enable		:= FALSE;
			
			EntryState	:= ENTRY_ABORT_CATCH;
			
		// Abort the catch mode
		ENTRY_ABORT_CATCH:
			MC_BR_SecAddShuttle_0.Sector			:= ADR(Sector_2);
			MC_BR_SecAddShuttle_0.AdvancedParameters.Mode	:= mcACPTRAK_ABORT_CATCH;
			MC_BR_SecAddShuttle_0.AdvancedParameters.VirtualShuttleID	:= 0;
			MC_BR_SecAddShuttle_0.Execute			:= TRUE;
			
			MC_BR_SecAddShuttle_1.Sector			:= ADR(Sector_2);
			MC_BR_SecAddShuttle_1.AdvancedParameters.Mode	:= mcACPTRAK_ABORT_CATCH;
			MC_BR_SecAddShuttle_1.AdvancedParameters.VirtualShuttleID	:= 0;
			MC_BR_SecAddShuttle_1.Execute			:= TRUE;
		
			IF MC_BR_SecAddShuttle_0.Done AND MC_BR_SecAddShuttle_1.Done THEN
				MC_BR_SecAddShuttle_0.Execute		:= FALSE;
				MC_BR_SecAddShuttle_1.Execute		:= FALSE;
				EntryState	:= ENTRY_INIT;
			ELSIF MC_BR_SecAddShuttle_0.Error OR MC_BR_SecAddShuttle_1.Error THEN
				ErrorInfo	:= 'Error in SecAddShuttle Abort Catch';
				State		:= ERROR;
				EntryState	:= ENTRY_ERROR;
			END_IF;
		
	END_CASE;
	
	// Reset the FUB if the station is active and a new shuttle catched
	IF EnableStations THEN
		IF EDGEPOS(MC_BR_SecAddShuttle_0.Active) THEN
			MC_BR_SecAddShuttle_0.Execute		:= FALSE;
			CalcShuttle	:= MC_BR_SecAddShuttle_0.Axis;
		ELSIF MC_BR_SecAddShuttle_0.Error THEN
			ErrorInfo	:= 'Error in SecAddShuttle 0 Entry';
			State		:= ERROR;
			EntryState	:= ENTRY_ERROR;
		END_IF;
		
		IF EDGEPOS(MC_BR_SecAddShuttle_1.Active) THEN
			MC_BR_SecAddShuttle_1.Execute		:= FALSE;
			CalcShuttle	:= MC_BR_SecAddShuttle_1.Axis;
		ELSIF MC_BR_SecAddShuttle_1.Error THEN
			ErrorInfo	:= 'Error in SecAddShuttle 1 Entry';
			State		:= ERROR;
			EntryState	:= ENTRY_ERROR;
		END_IF;
	END_IF;
	
	IF MC_BR_SegReadInfo_Entry.Error THEN
		ErrorInfo	:= 'Error in SegReadInfo Entry';
		State		:= ERROR;
		EntryState	:= ENTRY_ERROR;
	END_IF;
	
	IF MC_BR_SecReadInfo_SimSector.Error THEN
		ErrorInfo	:= 'Error in SecReadInfo SimSector';
		State		:= ERROR;
		EntryState	:= ENTRY_ERROR;
	END_IF;
	
	// Call the FUBs
	MC_BR_TrgPointEnable_Entry();
	MC_BR_TrgPointReadInfo_Entry();
	MC_BR_ShReadInfo_Entry();
	
	MC_BR_SecReadInfo_SimSector();
	MC_BR_SegReadInfo_Entry();
	
END_ACTION
