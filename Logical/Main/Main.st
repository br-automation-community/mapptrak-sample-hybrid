(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    B&R 
 * Created:   July 22, 2025/2:17 PM 
 * Description: Demo application for an oval trak with one segment as conveyor(hybrid)
 *********************************************************************************)

PROGRAM _INIT
	
	// Initialize all FUBs once
	MC_BR_AsmPowerOn_0.Assembly			:= ADR(gAssembly_1);
	MC_BR_AsmPowerOff_0.Assembly		:= ADR(gAssembly_1);
	MC_BR_AsmDeleteShuttle_0.Assembly	:= ADR(gAssembly_1);
	MC_BR_AsmDeleteShuttle_0.Command	:= mcACPTRAK_SH_DELETE_ALL;
	MC_BR_AsmReset_0.Assembly			:= ADR(gAssembly_1);
	MC_BR_AsmReadInfo_0.Assembly		:= ADR(gAssembly_1);
	MC_BR_AsmStop_0.Assembly			:= ADR(gAssembly_1);
	
	MC_BR_SecGetShuttle_0.Sector		:= ADR(Sector_1);
	
	MC_BR_TrgPointEnable_Entry.ProcessPoint		:= ADR(ProcessPoint_Entry);
	MC_BR_TrgPointReadInfo_Entry.ProcessPoint	:= ADR(ProcessPoint_Entry);
	
	MC_BR_SegReadInfo_Entry.Segment		:= ADR(Seg_08);
	MC_BR_SegReadInfo_Entry.Enable		:= TRUE;
	
	MC_BR_TrgPointEnable_Exit.ProcessPoint		:= ADR(ProcessPoint_PreExit);
	MC_BR_TrgPointReadInfo_Exit.ProcessPoint	:= ADR(ProcessPoint_PreExit);
	
	MC_BR_BarrierCmd_Exit.ProcessPoint			:= ADR(ProcessPoint_PreExit);
	MC_BR_BarrierReadInfo_Exit.ProcessPoint		:= ADR(ProcessPoint_PreExit);
	MC_BR_BarrierReadInfo_Exit.Enable			:= TRUE;
	
	MC_BR_TrgPointEnable_CheckFree.ProcessPoint	:= ADR(ProcessPoint_Exit);
	MC_BR_SecReadInfo_CheckFree.Sector			:= ADR(Sector_Check_Free);
	
	MC_BR_TrgPointEnable_Clear.ProcessPoint		:= ADR(ProcessPoint_Clear);
	MC_BR_TrgPointReadInfo_Clear.ProcessPoint	:= ADR(ProcessPoint_Clear);
	
	MC_BR_SecReadInfo_AddShuttle.Sector	:= ADR(Sector_3);
	MC_BR_SecReadInfo_AddShuttle.Enable	:= TRUE;
	
	MC_BR_BarrierCmd_AddShuttle.ProcessPoint	:= ADR(ProcessPoint_AddShuttle);
	
	MC_BR_SecReadInfo_Seg08.Sector		:= ADR(SegSec_08);
	
	MC_BR_SecReadInfo_SimSector.Sector	:= ADR(SimSector);
	
	// Initialize axis
	MpAxisBasic_0.MpLink				:= ADR(gAxis_1);
	MpAxisBasic_0.Parameters			:= ADR(AxisParams);
	MpAxisBasic_0.Enable				:= TRUE;
	
	MpAxisCyclicSet_0.MpLink			:= ADR(gAxis_1);
	MpAxisCyclicSet_0.Parameters		:= ADR(CyclicSetParams);
	MpAxisCyclicSet_0.Enable			:= TRUE;
	
	// Set the init states
	State		:= INIT;
	StateAxis	:= AXIS_INIT;
	EntryState	:= ENTRY_INIT;
	ExitState	:= EXIT_INIT;
	ClearState	:= CLEAR_INIT;
	AddShuttleState	:= ADDSHUTTLE_INIT;
	
	// Check if simulation is active
	SimActive	:= DiagCpuIsSimulated();
	
	// Set default values for the shuttles
	NrOfShuttles	:= 4; // Default number of shuttles for demo application
	
	// Initialize shuttle positions (spaced evenly) and IDs (ID1, ID2, ID3, ...)
	FOR Index := 0 TO MAX_SHUTTLES_MIN_ONE DO
		ShuttleInitData.Position[Index]	:= DEFAULT_ADD_POSITION + (USINT_TO_LREAL(Index) * SHUTTLE_SPACING);
		brsitoa(Index + 1, ADR(TempIDStr));
		ShuttleInitData.ID[Index] := 'ID';
		brsstrcat(ADR(ShuttleInitData.ID[Index]), ADR(TempIDStr));
	END_FOR;

	AddPosition					:= DEFAULT_ADD_POSITION;
	UserID						:= 'UserID';
	
	// Set default movement parameter
	Velocity 		:= 2.0;       // m/s - Default trak velocity
	Acceleration 	:= 20.0;      // m/s² - Default acceleration
	Deceleration 	:= 20.0;      // m/s² - Default deceleration
	ConveyorVelocity:= Velocity;
	
	AutomaticVelocityAdjustment	:= TRUE;
	
	// Set no error information
	ErrorInfo	:= 'No error';
	
	ShuttleData;
	 
END_PROGRAM

PROGRAM _CYCLIC
	
	// Stop the application when the assembly is ready and running
	IF Stop AND (State > GET_SHUTTLE_WAIT OR State = INIT) AND State <> ERROR THEN
		Start	:= FALSE;
		Stop	:= FALSE;
		IF MC_BR_AsmReadInfo_0.AssemblyInfo.PLCopenState = mcACPTRAK_READY THEN
			State	:= STOP_SHUTTLES;
		END_IF;
	END_IF;
	
	// Reset Halt and Stop when the application is not ready
	// Reset to avoid old flags when starting application
	IF State <> READY THEN
		Halt	:= FALSE;
		Stop	:= FALSE;
	END_IF;
	
	// Reset the error information
	IF State <> ERROR THEN
		ErrorInfo	:= 'No error';
	END_IF;
	
	CASE State OF
		// Wait until the start command is set
		// If the application was paused by the Halt command, do not set new shuttles and do not power on again
		INIT:
			MC_BR_AsmReadInfo_0.Enable		:= TRUE;
			
			// If any virtual shuttles are on the system, get the IDs from end to start and delete all virtual shuttles
			IF MC_BR_AsmReadInfo_0.Valid AND MC_BR_AsmReadInfo_0.AssemblyInfo.ShuttleCount.VirtualShuttles > 0 AND NOT(SimActive) THEN
				State	:= GET_SHUTTLE_IDS_ON_CONVEYOR_INIT;
			END_IF;
			
			IF Start THEN
				IF Paused AND MC_BR_AsmReadInfo_0.AssemblyInfo.PLCopenState = mcACPTRAK_READY THEN
					State	:= GET_SHUTTLE_INIT;
					Cnt		:= 0;
					UserIDSet	:= TRUE;
				ELSE
					State	:= POWER_ON;
				END_IF;
				MC_BR_AsmReadInfo_0.Enable		:= TRUE;
				MC_BR_SecReadInfo_Seg08.Enable	:= TRUE;
				MC_BR_SecReadInfo_CheckFree.Enable	:= TRUE;
			END_IF;
		
		// Power on the assembly
		POWER_ON:
			MC_BR_AsmPowerOn_0.Execute		:= TRUE;
			
			// Close the barrier at the beginning of the conveyor to prevent shuttles to move onto the convoy during cleaning phase
			MC_BR_BarrierCmd_Safety.ProcessPoint	:= ADR(ProcessPoint_Safety);
			MC_BR_BarrierCmd_Safety.Execute			:= TRUE;
			MC_BR_BarrierCmd_Safety.Command			:= mcACPTRAK_BARRIER_CLOSE;
			
			IF MC_BR_AsmPowerOn_0.Done AND MC_BR_BarrierCmd_Safety.Done THEN
				MC_BR_BarrierCmd_Safety.Execute		:= FALSE;
				MC_BR_AsmPowerOn_0.Execute	:= FALSE;
				Cnt	:= 0;
				UserIDSet	:= FALSE;
				
				// If the application is simulated, or no shuttles are on the trak, add shuttles to the trak
				IF SimActive AND (NOT(Paused) OR MC_BR_AsmReadInfo_0.AssemblyInfo.ShuttleCount.Count = 0) THEN
					State	:= ADD_SHUTTLES;
					MC_BR_SecAddShuttle_Main.Execute		:= FALSE;
				ELSE
					State	:= GET_SHUTTLE_INIT;
				END_IF;
			ELSIF MC_BR_AsmPowerOn_0.Error THEN
				ErrorInfo	:= 'Error in AsmPowerOn';
				State		:= ERROR;
			END_IF;
		
		// Add shuttles to the sector
		ADD_SHUTTLES:
			MC_BR_SecAddShuttle_Main.Sector			:= ADR(Sector_1);
			MC_BR_SecAddShuttle_Main.Position		:= ShuttleInitData.Position[Cnt];
			MC_BR_SecAddShuttle_Main.Velocity		:= 0.0;
			MC_BR_SecAddShuttle_Main.AdvancedParameters.UserID	:= ShuttleInitData.ID[Cnt];
			MC_BR_SecAddShuttle_Main.AdvancedParameters.Mode	:= mcACPTRAK_ADD_IMMEDIATE;
			MC_BR_SecAddShuttle_Main.AdvancedParameters.VirtualShuttleID	:= 0;
			MC_BR_SecAddShuttle_Main.AdvancedParameters.MoveCmd				:= mcACPTRAK_MOV_CMD_HALT;
			MC_BR_SecAddShuttle_Main.AdvancedParameters.Velocity			:= 0.0;
			MC_BR_SecAddShuttle_Main.AdvancedParameters.Acceleration		:= 0.0;
			MC_BR_SecAddShuttle_Main.AdvancedParameters.Deceleration		:= 0.0;
			MC_BR_SecAddShuttle_Main.AdvancedParameters.Direction			:= mcDIR_POSITIVE;
			MC_BR_SecAddShuttle_Main.Execute		:= TRUE;
			
			IF MC_BR_SecAddShuttle_Main.Done THEN
				MC_BR_SecAddShuttle_Main.Execute	:= FALSE;
				Cnt	:= Cnt + 1;
				
				// When the counter reaches the defined number of shuttles, or no ID is set anymore, get the shuttles
				IF Cnt = NrOfShuttles OR ShuttleInitData.ID[Cnt] = '' THEN
					State	:= GET_SHUTTLE_INIT;
					Cnt		:= 0;
					UserIDSet	:= TRUE;
				END_IF;
			ELSIF MC_BR_SecAddShuttle_Main.Error THEN
				ErrorInfo	:= 'Error in SecAddShuttle';
				State		:= ERROR;
			END_IF;
		
		// Initialize the SecGetShuttle FUB for non virtual shuttles
		GET_SHUTTLE_INIT:
			NrOfShuttles	:= 0;
			StopConveyor	:= TRUE;
			MC_BR_SecGetShuttle_0.Sector		:= ADR(Sector_1);
			MC_BR_SecGetShuttle_0.Enable		:= TRUE;
			MC_BR_SecGetShuttle_0.Next			:= FALSE;
			MC_BR_SecGetShuttle_0.Mode			:= mcACPTRAK_SEARCH_BACKWARD;
			MC_BR_SecGetShuttle_0.AdvancedParameters.VirtualSelectionMode	:= mcACPTRAK_GET_SH_VIRT_NONVIRTUAL;
			State			:= GET_SHUTTLE_WAIT;
			
		// Get next shuttle
		GET_SHUTTLE:
			MC_BR_SecGetShuttle_0.Next			:= TRUE;
			State			:= GET_SHUTTLE_WAIT;
			
		// Get the shuttle
		// When no shuttle remains, move all shuttles
		GET_SHUTTLE_WAIT:
			IF MC_BR_SecGetShuttle_0.Valid THEN
				Shuttle[Cnt]	:= MC_BR_SecGetShuttle_0.Axis;
				Cnt	:= Cnt + 1;
				
				IF MC_BR_SecGetShuttle_0.RemainingCount = 0 THEN
					MC_BR_SecGetShuttle_0.Enable	:= FALSE;
					MC_BR_SecGetShuttle_0.Next		:= FALSE;
					MC_BR_ElasticMoveVel_0.Execute	:= FALSE;
					NrOfShuttles	:= MC_BR_SecGetShuttle_0.TotalCount;
					
					// If no shuttle is found or the system runs on a real machine, clean the conveyor
					IF MC_BR_SecGetShuttle_0.TotalCount = 0 AND NOT(SimActive) THEN
						State	:= CLEAN_CONVEYOR;
						Cnt		:= 0;
					// If all UserIDs are set, start the movement
					ELSIF UserIDSet THEN
						State	:= START_MOVEMENT;
						Cnt		:= 0;
					// Set the UserIDs
					ELSE
						State	:= SET_USERID;
					END_IF;
				ELSE
					// If no UserID is set, set the ID
					MC_BR_SecGetShuttle_0.Next		:= FALSE;
					IF UserIDSet THEN
						State	:= GET_SHUTTLE;
					ELSE
						State	:= SET_USERID;
					END_IF;
				END_IF;
			ELSIF MC_BR_SecGetShuttle_0.Error THEN
				ErrorInfo	:= 'Error in SecGetShuttle';
				State		:= ERROR;
			END_IF;
			
		// Set a UserID to the shuttle
		SET_USERID:
			MC_BR_ShSetUserID_0.Axis	:= ADR(Shuttle[Cnt-1]);
			MC_BR_ShSetUserID_0.UserID	:= ShuttleInitData.ID[Cnt-1];
			MC_BR_ShSetUserID_0.Execute	:= TRUE;
			
			IF MC_BR_ShSetUserID_0.Done THEN
				MC_BR_ShSetUserID_0.Execute			:= FALSE;
				// If SecGetShuttle is still active, get the next shuttle, otherwise move all shuttles
				IF MC_BR_SecGetShuttle_0.Enable THEN
					State	:= GET_SHUTTLE;
				ELSE
					State	:= START_MOVEMENT;
					Cnt		:= 0;
					UserIDSet	:= TRUE;
				END_IF;
			ELSIF MC_BR_ShSetUserID_0.Error THEN
				ErrorInfo	:= 'Error in ShSetUserID';
				State		:= ERROR;
			END_IF;
			
		// Move all shuttles
		START_MOVEMENT:		
			MC_BR_ElasticMoveVel_0.Axis			:= ADR(Shuttle[Cnt]);
			MC_BR_ElasticMoveVel_0.Velocity		:= Velocity;
			MC_BR_ElasticMoveVel_0.Acceleration	:= Acceleration;
			MC_BR_ElasticMoveVel_0.Deceleration	:= Deceleration;
			MC_BR_ElasticMoveVel_0.Direction	:= mcDIR_POSITIVE;
			
			// If a shuttle is on the trak and not ready, move the shuttle
			IF StateAxis = AXIS_READY THEN
				MC_BR_ElasticMoveVel_0.Execute	:= TRUE;
			END_IF;
			
			// Wait for the shuttle to move
			IF EDGEPOS(MC_BR_ElasticMoveVel_0.Active) THEN
				MC_BR_ElasticMoveVel_0.Execute	:= FALSE;
				Cnt	:= Cnt + 1;
				
				// If all shuttles are moved, go to ready
				IF Cnt = NrOfShuttles THEN
					State	:= READY;
					IF NOT(SimActive) AND NOT(Paused) THEN
						// If the machine was not paused, undetected shuttles can be found on the conveyor
						// Go to the cleaning state
						State	:= CLEAN_CONVEYOR;
						Cnt		:= 0;
					END_IF;
					Paused	:= FALSE;
				END_IF;
			ELSIF MC_BR_ElasticMoveVel_0.Error THEN
				ErrorInfo	:= 'Error in ElasticMoveVel';
				State		:= ERROR;
			END_IF;
			
		// Clean the conveyor
		// Start the conveyor when the catching is active for a certain amount of time
		// This prevents undetected shuttles on the conveyor
		CLEAN_CONVEYOR:
			IF MC_BR_SecAddShuttle_Clean.Busy THEN
				Paused				:= FALSE;
				StartAxisMovement	:= TRUE;
				StopConveyor		:= FALSE;
			END_IF;
			
			MC_BR_SecAddShuttle_Clean.Execute	:= TRUE;
			MC_BR_SecAddShuttle_Clean.Sector	:= ADR(Sector_2);
			MC_BR_SecAddShuttle_Clean.Position	:= 0.1;
			MC_BR_SecAddShuttle_Clean.AdvancedParameters.Mode				:= mcACPTRAK_ADD_CATCH;
			MC_BR_SecAddShuttle_Clean.AdvancedParameters.MoveCmd			:= mcACPTRAK_MOV_CMD_ELASTICMOVEVEL;
			MC_BR_SecAddShuttle_Clean.AdvancedParameters.Velocity			:= ConveyorVelocity;
			MC_BR_SecAddShuttle_Clean.AdvancedParameters.Acceleration		:= Acceleration;
			MC_BR_SecAddShuttle_Clean.AdvancedParameters.Deceleration		:= Deceleration;
			MC_BR_SecAddShuttle_Clean.AdvancedParameters.Direction			:= mcDIR_POSITIVE;
			// If no UserID should be recovered take the next from the InitData
			// The IDs are saved when stopping the system
			IF UserIDs[0] = '' THEN
				MC_BR_SecAddShuttle_Clean.AdvancedParameters.UserID			:= ShuttleInitData.ID[NrOfShuttles];
			ELSE
				MC_BR_SecAddShuttle_Clean.AdvancedParameters.UserID			:= UserIDs[Cnt];
			END_IF;
			
			// Check if a shuttle is catched and increase the number of shuttles on the system
			IF EDGEPOS(MC_BR_SecAddShuttle_Clean.Active) THEN
				MC_BR_SecAddShuttle_Clean.Execute	:= FALSE;
				
				IF NrOfShuttles < MAX_SHUTTLES THEN
					Shuttle[NrOfShuttles]	:= MC_BR_SecAddShuttle_Clean.Axis;
					NrOfShuttles	:= NrOfShuttles + 1;
					Cnt	:= Cnt + 1;
				ELSE
					ErrorInfo	:= 'Error too many shuttles';
					State		:= ERROR;
				END_IF;
			ELSIF MC_BR_SecAddShuttle_Clean.Error THEN
				ErrorInfo	:= 'Error in SecAddShuttle Catch';
				State		:= ERROR;
			END_IF;
			
			// Run the conveyor for 1,5s
			Timer.IN	:= TRUE;
			Timer.PT	:= CONVEYOR_CLEAN_TIME; // 1.5 second timeout to detect all shuttles on conveyor
			
			IF Timer.Q THEN
				Timer.IN	:= FALSE;
				MC_BR_SecAddShuttle_Clean.Execute	:= FALSE;
				State		:= CLEAN_CONVEYOR_ABORT;
			END_IF;
			
		// Abort the last catch command to free the channel
		CLEAN_CONVEYOR_ABORT:
			MC_BR_SecAddShuttle_Clean.Execute	:= TRUE;
			MC_BR_SecAddShuttle_Clean.AdvancedParameters.Mode				:= mcACPTRAK_ABORT_CATCH;
			IF MC_BR_SecAddShuttle_Clean.Done THEN
				MC_BR_SecAddShuttle_Clean.Execute	:= FALSE;
				// If the system is in errorstop delete all shuttles, otherwise start the process
				IF AbortCleaningCatch THEN
					State	:= DELETE_SHUTTLES;
				ELSE
					State	:= READY;
				END_IF;
				AbortCleaningCatch	:= FALSE;
			ELSIF MC_BR_SecAddShuttle_Clean.Error THEN
				ErrorInfo	:= 'Error in SecAddShuttle Catch Abort';
				State		:= ERROR;
			END_IF;
			
		// All shuttles added and started
		READY:	
			// Open the safety barrier in front of the conveyor
			IF MC_BR_BarrierCmd_Safety.Command = mcACPTRAK_BARRIER_CLOSE THEN
				MC_BR_BarrierCmd_Safety.Execute		:= TRUE;
				MC_BR_BarrierCmd_Safety.Command		:= mcACPTRAK_BARRIER_OPEN;
			END_IF;
			
			IF MC_BR_BarrierCmd_Safety.Done THEN
				MC_BR_BarrierCmd_Safety.Execute		:= FALSE;
			END_IF;
			
			StartAxisMovement	:= TRUE;
			StopConveyor		:= FALSE;
			EnableStations		:= TRUE;
			
			IF Halt THEN
				State			:= HALT_SHUTTLES;
				Paused			:= TRUE;
			END_IF;
		
		// Stop all shuttles on the assembly after the conveyor stopped --> avoid shuttles from being forgotten on the end of the conveyor
		HALT_SHUTTLES:
			IF MC_BR_AsmReadInfo_0.AssemblyInfo.ShuttleCount.VirtualShuttles = 0 AND MC_BR_AsmReadInfo_0.Valid AND
				MC_BR_SecReadInfo_CheckFree.SectorInfo.InRest AND MC_BR_SecReadInfo_CheckFree.Valid THEN
				StopConveyor	:= TRUE;
				MC_BR_AsmStop_0.Execute	:= TRUE;
			END_IF;
			
			MC_BR_AsmStop_0.AdvancedParameters.SegmentGroup	:= '';
			MC_BR_AsmStop_0.AdvancedParameters.Deceleration	:= Deceleration;
			IF MC_BR_AsmStop_0.Done THEN
				MC_BR_AsmStop_0.Execute	:= FALSE;
				State		:= INIT;
				
				FOR Index := 0 TO MAX_SHUTTLES_MIN_ONE DO
					MC_BR_MoveCyclicTcpVel_0[Index].Enable	:= FALSE;
				END_FOR;
			ELSIF MC_BR_AsmStop_0.Error THEN
				ErrorInfo	:= 'Error in AsmStop';
				State		:= ERROR;
			END_IF;
			
		// Stop all shuttles on the Trak segments
		STOP_SHUTTLES:
			StopConveyor	:= TRUE;
			MC_BR_AsmStop_0.Execute	:= TRUE;
			MC_BR_AsmStop_0.AdvancedParameters.Deceleration	:= Deceleration;
			MC_BR_AsmStop_0.AdvancedParameters.SegmentGroup	:= 'Sector_4';
			IF MC_BR_AsmStop_0.Done THEN
				MC_BR_AsmStop_0.Execute	:= FALSE;
				// If virtual shuttles are on the trak, check the UserIDs to restore at the restart
				IF MC_BR_AsmReadInfo_0.Valid AND MC_BR_AsmReadInfo_0.AssemblyInfo.ShuttleCount.VirtualShuttles > 0 AND NOT(SimActive) THEN
					State	:= GET_SHUTTLE_IDS_ON_CONVEYOR_INIT;
					DeleteAll	:= TRUE;
				ELSE
					State	:= DELETE_SHUTTLES;
				END_IF;
			ELSIF MC_BR_AsmStop_0.Error THEN
				ErrorInfo	:= 'Error in AsmStop';
				State		:= ERROR;
			END_IF;
			
		// Initialize SecGetShuttle for virtual shuttles
		GET_SHUTTLE_IDS_ON_CONVEYOR_INIT:
			MC_BR_SecGetShuttle_0.Sector		:= ADR(Sector_1);
			MC_BR_SecGetShuttle_0.Enable		:= TRUE;
			MC_BR_SecGetShuttle_0.Next			:= FALSE;
			MC_BR_SecGetShuttle_0.Mode			:= mcACPTRAK_SEARCH_BACKWARD;
			MC_BR_SecGetShuttle_0.AdvancedParameters.VirtualSelectionMode	:= mcACPTRAK_GET_SH_VIRT_VIRTUAL;
			Cnt				:= 0;
			State			:= GET_SHUTTLE_IDS_ON_CONVEYOR_WAIT;
			
		// Get next virtual shuttle
		GET_SHUTTLE_IDS_ON_CONVEYOR:
			MC_BR_SecGetShuttle_0.Next			:= TRUE;
			State			:= GET_SHUTTLE_IDS_ON_CONVEYOR_WAIT;
			
		// Get the virtual shuttle
		GET_SHUTTLE_IDS_ON_CONVEYOR_WAIT:
			IF MC_BR_SecGetShuttle_0.Valid THEN
				Shuttle_Conveyor[Cnt]	:= MC_BR_SecGetShuttle_0.Axis;
				Cnt	:= Cnt + 1;
				
				// When all shuttles are found, read the UserIDs
				IF MC_BR_SecGetShuttle_0.RemainingCount = 0 THEN
					MC_BR_SecGetShuttle_0.Enable	:= FALSE;
					MC_BR_SecGetShuttle_0.Next		:= FALSE;
					NrOfShuttlesOnConveyor	:= MC_BR_SecGetShuttle_0.TotalCount;
					
					State	:= GET_SHUTTLE_IDS;
					Cnt		:= 0;
				ELSE
					MC_BR_SecGetShuttle_0.Next		:= FALSE;
					State	:= GET_SHUTTLE_IDS_ON_CONVEYOR;
				END_IF;
			ELSIF MC_BR_SecGetShuttle_0.Error THEN
				ErrorInfo	:= 'Error in SecGetShuttle Conveyor';
				State		:= ERROR;
			END_IF;
			
		// Save all UserIDs in a list
		GET_SHUTTLE_IDS:
			MC_BR_ShReadInfo_GetIDS.Axis	:= ADR(Shuttle_Conveyor[Cnt]);
			MC_BR_ShReadInfo_GetIDS.Enable	:= TRUE;
			
			IF MC_BR_ShReadInfo_GetIDS.Valid THEN
				MC_BR_ShReadInfo_GetIDS.Enable	:= FALSE;
				UserIDs[Cnt]	:= MC_BR_ShReadInfo_GetIDS.ShuttleInfo.AdditionalInfo.UserID;
				Cnt	:= Cnt + 1;
				
				// If the application is stopped, delete all shuttles
				IF Cnt >= NrOfShuttlesOnConveyor THEN
					State	:= DELETE_VIRT_SHUTTLES;
				END_IF;
				IF DeleteAll THEN
					DeleteAll:= FALSE;
					State	:= DELETE_SHUTTLES;
				END_IF;
			ELSIF MC_BR_ShReadInfo_GetIDS.Error THEN
				ErrorInfo	:= 'Error in ShReadInfo GetIDs';
				State		:= ERROR;
			END_IF;
			
		// Delete all shuttles and open the barrier
		DELETE_SHUTTLES:
			UserIDSet		:= FALSE;
			OpenBarrier		:= TRUE;
			EnableStations	:= FALSE;
			CalcShuttle.controlif	:= 0;
			MC_BR_AsmDeleteShuttle_0.Execute	:= TRUE;
			MC_BR_AsmDeleteShuttle_0.Command	:= mcACPTRAK_SH_DELETE_ALL;
			
			IF MC_BR_AsmDeleteShuttle_0.Done THEN
				MC_BR_AsmDeleteShuttle_0.Execute:= FALSE;
				State		:= POWER_OFF;
				
				FOR Cnt := 0 TO MAX_SHUTTLES_MIN_ONE DO
					UserIDs[Cnt]	:= '';
				END_FOR;
			ELSIF MC_BR_AsmDeleteShuttle_0.Error THEN
				ErrorInfo	:= 'Error in AsmDeleteShuttle';
				State		:= ERROR;
			END_IF;
			
		// Delete only virtual shuttles
		DELETE_VIRT_SHUTTLES:
			MC_BR_AsmDeleteShuttle_0.Execute	:= TRUE;
			MC_BR_AsmDeleteShuttle_0.Command	:= mcACPTRAK_SH_DELETE_VIRTUAL;
			
			IF MC_BR_AsmDeleteShuttle_0.Done THEN
				MC_BR_AsmDeleteShuttle_0.Execute:= FALSE;
				State		:= INIT;
			ELSIF MC_BR_AsmDeleteShuttle_0.Error THEN
				ErrorInfo	:= 'Error in AsmDeleteShuttle Virtual';
				State		:= ERROR;
			END_IF;
		
		// Power off the assembly
		POWER_OFF:
			StateAxis	:= AXIS_POWER_OFF;
			MC_BR_AsmPowerOff_0.Execute			:= TRUE;
			
			IF MC_BR_AsmPowerOff_0.Done THEN
				MC_BR_AsmPowerOff_0.Execute		:= FALSE;
				State		:= INIT;
			ELSIF MC_BR_AsmPowerOff_0.Error THEN
				ErrorInfo	:= 'Error in AsmPowerOff';
				State		:= ERROR;
			END_IF;
		
		// Error state, reset all variables
		ERROR:
			EnableStations	:= FALSE;
			Start			:= FALSE;
			Stop			:= FALSE;
			CalcShuttle.controlif	:= 0;
			
			MC_BR_AsmPowerOn_0.Execute			:= FALSE;
			MC_BR_AsmPowerOff_0.Execute			:= FALSE;
			MC_BR_AsmDeleteShuttle_0.Execute	:= FALSE;
			MC_BR_AsmReset_0.Execute			:= FALSE;
			MC_BR_AsmReadInfo_0.Enable			:= FALSE;
			MC_BR_AsmStop_0.Execute				:= FALSE;
	
			MC_BR_SecAddShuttle_Main.Execute	:= FALSE;
			MC_BR_SecAddShuttle_1.Execute		:= FALSE;
			MC_BR_SecGetShuttle_0.Enable		:= FALSE;
			MC_BR_SecReadInfo_Seg08.Enable		:= FALSE;
			
			MC_BR_SecAddShuttle_Clean.Execute	:= FALSE;
			MC_BR_ShReadInfo_GetIDS.Enable		:= FALSE;
			Timer.IN	:= FALSE;
	
			MC_BR_ElasticMoveVel_0.Execute		:= FALSE;
			
			FOR Index := 0 TO MAX_SHUTTLES_MIN_ONE DO
				MC_BR_MoveCyclicTcpVel_0[Index].Enable	:= FALSE;
			END_FOR;
		
			StopConveyor	:= TRUE;
	
			// Only set the entry state to error to abort the catch mode
			EntryState		:= ENTRY_ERROR;		
		
	END_CASE;
	
	CASE StateAxis OF
		// Start the conveyor
		AXIS_INIT:
			IF Start OR (State <> INIT AND State <> POWER_OFF AND State <> DELETE_SHUTTLES AND State <> ERROR) THEN
				StopConveyor:= FALSE;
				StateAxis	:= AXIS_POWER_ON;
			END_IF;
		
		// Power on the conveyor
		AXIS_POWER_ON:
			IF MpAxisBasic_0.Info.ReadyToPowerOn THEN
				MpAxisBasic_0.Power	:= TRUE;
				IF MpAxisBasic_0.PowerOn THEN
					StateAxis	:= AXIS_HOME;
				END_IF;
			END_IF;
		
		// Home direct the conveyor
		AXIS_HOME:
			MpAxisBasic_0.Home	:= TRUE;
			IF MpAxisBasic_0.IsHomed THEN
				MpAxisBasic_0.Home	:= FALSE;
				StateAxis		:= AXIS_READY;
			END_IF;
			
		// Start the cyclic velocity command when no shuttle is on the segment behind the conveyor to avoid a crash
		AXIS_READY:
			IF StartAxisMovement AND (MC_BR_SecReadInfo_Seg08.SectorInfo.ShuttleCount.Count = 0 OR MC_BR_SecReadInfo_Seg08.SectorInfo.ShuttleCount.VirtualShuttles > 0) THEN
				MpAxisCyclicSet_0.MoveCyclicVelocity:= TRUE;
			END_IF;
			IF MC_BR_SegReadInfo_Entry.SegmentInfo.PLCopenState = mcACPTRAK_ERRORSTOP OR StopConveyor THEN
				MpAxisCyclicSet_0.MoveCyclicVelocity:= FALSE;
			END_IF;
			
		// Power off the conveyor
		AXIS_POWER_OFF:
			MpAxisCyclicSet_0.MoveCyclicVelocity	:= FALSE;
			MpAxisBasic_0.Power	:= FALSE;
			IF MpAxisBasic_0.PowerOn = FALSE THEN
				StateAxis		:= AXIS_INIT;
			END_IF;
			
		// Error state of the conveyor
		AXIS_ERROR:
			StopConveyor		:= TRUE;
			MpAxisBasic_0.Power	:= FALSE;
			MpAxisBasic_0.Home	:= FALSE;
		
			MpAxisCyclicSet_0.MoveCyclicVelocity	:= FALSE;

	END_CASE;
	
	// Check for error in MpAxisBasic
	IF MpAxisBasic_0.Error THEN
		ErrorInfo	:= 'Error in MpAxisBasic';
		StateAxis	:= AXIS_ERROR;
		State		:= ERROR;
	ELSE
		MpAxisBasic_0.ErrorReset	:= FALSE;
	END_IF;
	
	// Check for error in MpAxisCyclicSet
	IF EDGEPOS(MpAxisCyclicSet_0.Error) THEN
		ErrorInfo	:= 'Error in MpAxisCyclicSet';
		StateAxis	:= AXIS_ERROR;
	ELSE
		MpAxisCyclicSet_0.ErrorReset	:= FALSE;
	END_IF;
	
	// Check for error in AsmReadInfo
	IF MC_BR_AsmReadInfo_0.Error THEN
		ErrorInfo	:= 'Error in AsmReadInfo';
		State		:= ERROR;
	END_IF;
	
	// Check for assembly errorstop
	IF MC_BR_AsmReadInfo_0.AssemblyInfo.PLCopenState = mcACPTRAK_ERRORSTOP THEN
		ErrorInfo	:= 'Assembly in errorstop';
		State		:= ERROR;
	END_IF;
	
	// Check for SecReadInfo error for SegSec_08
	IF MC_BR_SecReadInfo_Seg08.Error THEN
		ErrorInfo	:= 'Error in SecReadInfo Seg08';
		State		:= ERROR;
	END_IF;
	
	// Check for SecReadInfo error for Sector_Check_Free
	IF MC_BR_SecReadInfo_CheckFree.Error THEN
		ErrorInfo	:= 'Error in SecReadInfo Check_Free';
		State		:= ERROR;
	END_IF;
	
	// Error reset
	// Do an error reset of the assembly first if assembly and axis are in error
	IF ErrorReset AND (State = ERROR OR StateAxis = AXIS_ERROR) THEN
		IF State = ERROR THEN
			MC_BR_AsmReset_0.Execute		:= TRUE;
			
			IF MC_BR_AsmReset_0.Done THEN
				IF StateAxis <> AXIS_ERROR THEN
					ErrorReset	:= FALSE;
					ErrorInfo	:= 'No error';
				END_IF;
				MC_BR_AsmReset_0.Execute	:= FALSE;
				State		:= INIT;
				OpenBarrier	:= TRUE;

				// If the catch is active for cleaning the conveyor, abort the catch
				IF MC_BR_SecAddShuttle_Clean.Active THEN
					State	:= CLEAN_CONVEYOR_ABORT;
					AbortCleaningCatch	:= TRUE;
				END_IF;
				
				// No shuttle will be catched after poweron the conveyor
				// Therefore all shuttles will be deleted in the simulation to restart the application
				IF SimActive THEN
					State	:= DELETE_SHUTTLES;
				END_IF;
			ELSIF MC_BR_AsmReset_0.Error THEN
				MC_BR_AsmReset_0.Execute	:= FALSE;
				ErrorInfo	:= 'Error in AsmReset';
				State		:= ERROR;
			END_IF;
		END_IF;
		
		IF StateAxis = AXIS_ERROR THEN
			StateAxis	:= AXIS_POWER_OFF;
			MpAxisBasic_0.ErrorReset	:= TRUE;
			MpAxisCyclicSet_0.ErrorReset:= TRUE;
			ErrorReset	:= FALSE;
			ErrorInfo	:= 'No error';
		END_IF;
	END_IF;
	
	// Station actions
	EntrySegment;
	ExitSegment;
	Clear;
	AddNewShuttle;
	CalcAutomaticVelocity;
	
	// Add messages, timestamps and image index to the list
	IF AddMessage THEN
		AddMessage	:= FALSE;
		FOR Index := 19 TO 1 BY -1 DO
			Messages[Index]		:= Messages[Index-1];
			ImageIndex[Index]	:= ImageIndex[Index-1];
			Timestamps[Index]	:= Timestamps[Index-1];
		END_FOR;
		Messages[0]		:= Message;
		ImageIndex[0]	:= AddImage;
		DTGetTime_0.enable	:= TRUE;
	END_IF;
	
	DTGetTime_0();
	
	IF DTGetTime_0.status = 0 THEN
		DTGetTime_0.enable	:= FALSE;
		Timestamps[0]		:= DTGetTime_0.DT1;
	END_IF;
	
	// Reset the start command after all states are run through
	Start		:= FALSE;
	
	// Call all FUBs
	MC_BR_AsmPowerOn_0();
	MC_BR_AsmPowerOff_0();
	MC_BR_AsmDeleteShuttle_0();
	MC_BR_AsmReset_0();
	MC_BR_AsmReadInfo_0();
	MC_BR_AsmStop_0();
	
	MC_BR_SecAddShuttle_Main();
	MC_BR_SecAddShuttle_0();
	MC_BR_SecAddShuttle_1();
	MC_BR_SecAddShuttle_Clean();
	MC_BR_SecGetShuttle_0();
	MC_BR_SecReadInfo_Seg08();
	MC_BR_SecReadInfo_CheckFree();
	
	MC_BR_ShSetUserID_0();
	
	MC_BR_ElasticMoveVel_0();
	
	MC_BR_BarrierCmd_Safety();
	
	Timer();
	
	MC_BR_ShReadInfo_GetIDS();
	
	MpAxisBasic_0();
	
	MpAxisCyclicSet_0.CyclicVelocity	:= ConveyorVelocity;
	MpAxisCyclicSet_0();
	
	FOR Index := 0 TO MAX_SHUTTLES_MIN_ONE DO
		// Read shuttle information if available
		IF Shuttle[Index].controlif <> 0 AND State > SET_USERID AND State < DELETE_SHUTTLES AND Index < NrOfShuttles THEN
			MC_BR_ShReadInfo_Main[Index].Axis	:= ADR(Shuttle[Index]);
			MC_BR_ShReadInfo_Main[Index].Enable	:= TRUE;
		ELSE
			MC_BR_ShReadInfo_Main[Index].Enable	:= FALSE;
		END_IF;
		MC_BR_ShReadInfo_Main[Index]();
		
		IF MC_BR_ShReadInfo_Main[Index].ShuttleInfo.AdditionalInfo.PLCopenState = mcAXIS_ERRORSTOP THEN
			ErrorInfo	:= 'Errorstop in Shuttle';
			State		:= ERROR;
		ELSIF MC_BR_ShReadInfo_Main[Index].Error THEN
			ErrorInfo	:= 'Error in ShReadInfo';
			State		:= ERROR;
		END_IF;
		
		// Reset MoveCyclicTcpVel after another command took over the shuttle
		MC_BR_MoveCyclicTcpVel_0[Index].Axis			:= ADR(Shuttle[Index]);
		MC_BR_MoveCyclicTcpVel_0[Index].CyclicVelocity	:= MpAxisBasic_0.Velocity;
		
		IF MC_BR_MoveCyclicTcpVel_0[Index].CommandAborted THEN
			MC_BR_MoveCyclicTcpVel_0[Index].Enable		:= FALSE;
		END_IF;
		
		MC_BR_MoveCyclicTcpVel_0[Index]();
		IF MC_BR_MoveCyclicTcpVel_0[Index].Error THEN
			ErrorInfo	:= 'Error in MoveCyclicTcpVel';
			State		:= ERROR;			
		END_IF;
	END_FOR;

	// Track state changes for debugging
	IF State <> LastState THEN
		// Shift history
		FOR Index := 9 TO 1 BY -1 DO
			StateHistory[Index] := StateHistory[Index-1];
		END_FOR;
		StateHistory[0] := LastState;
		LastState := State;
	END_IF;
	
	AutomaticVelocityAdjNotActive	:= NOT(AutomaticVelocityAdjustment);
	
	MachineRunning	:= State = INIT;
	 
END_PROGRAM

PROGRAM _EXIT
	
	MpAxisBasic_0.Enable		:= FALSE;
	MpAxisBasic_0();
	
	MpAxisCyclicSet_0.Enable	:= FALSE;
	MpAxisCyclicSet_0();
	 
END_PROGRAM

