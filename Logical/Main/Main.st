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
	NrOfShuttles	:= 4;
	
	ShuttleInitData.Position[0]	:= 0.1;
	ShuttleInitData.Position[1]	:= 0.2;
	ShuttleInitData.Position[2]	:= 0.3;
	ShuttleInitData.Position[3]	:= 0.4;
	ShuttleInitData.Position[4]	:= 0.5;
	ShuttleInitData.Position[5]	:= 0.6;
	ShuttleInitData.Position[6]	:= 0.7;
	ShuttleInitData.Position[7]	:= 0.8;
	ShuttleInitData.Position[8]	:= 0.9;
	ShuttleInitData.Position[9]	:= 1.0;
	ShuttleInitData.Position[10]:= 1.1;
	ShuttleInitData.Position[11]:= 1.2;
	ShuttleInitData.Position[12]:= 1.3;
	ShuttleInitData.Position[13]:= 1.4;
	ShuttleInitData.Position[14]:= 1.5;
	ShuttleInitData.Position[15]:= 1.6;
	ShuttleInitData.Position[16]:= 1.7;
	ShuttleInitData.Position[17]:= 1.8;
	ShuttleInitData.Position[18]:= 1.9;
	ShuttleInitData.Position[19]:= 2.0;
	
	ShuttleInitData.ID[0]		:= 'ID1';
	ShuttleInitData.ID[1]		:= 'ID2';
	ShuttleInitData.ID[2]		:= 'ID3';
	ShuttleInitData.ID[3]		:= 'ID4';
	ShuttleInitData.ID[4]		:= 'ID5';
	ShuttleInitData.ID[5]		:= 'ID6';
	ShuttleInitData.ID[6]		:= 'ID7';
	ShuttleInitData.ID[7]		:= 'ID8';
	ShuttleInitData.ID[8]		:= 'ID9';
	ShuttleInitData.ID[9]		:= 'ID10';
	ShuttleInitData.ID[10]		:= 'ID11';
	ShuttleInitData.ID[11]		:= 'ID12';
	ShuttleInitData.ID[12]		:= 'ID13';
	ShuttleInitData.ID[13]		:= 'ID14';
	ShuttleInitData.ID[14]		:= 'ID15';
	ShuttleInitData.ID[15]		:= 'ID16';
	ShuttleInitData.ID[16]		:= 'ID17';
	ShuttleInitData.ID[17]		:= 'ID18';
	ShuttleInitData.ID[18]		:= 'ID19';
	ShuttleInitData.ID[19]		:= 'ID20';
	
	AddPosition					:= 0.1;
	UserID						:= 'UserID';
	
	// Set default movement parameter
	Velocity		:= 2.0;
	Acceleration	:= 20.0;
	Deceleration	:= 20.0;
	ConveyorVelocity:= Velocity;
	
	AutomaticVelocityAdjustment	:= TRUE;
	
	// Set no error information
	ErrorInfo	:= 'No error';
	 
END_PROGRAM

PROGRAM _CYCLIC
	
	// Stop the application when the assembly is ready and running
	IF Stop AND (State > GET_SHUTTLE_WAIT OR State = INIT) AND State <> ERROR THEN
		Start	:= FALSE;
		Stop	:= FALSE;
		State	:= DELETE_SHUTTLES;
		StateAxis	:= AXIS_POWER_OFF;
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
			
			IF MC_BR_AsmPowerOn_0.Done THEN
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
		
		// Initialize the SecGetShuttle FUB
		GET_SHUTTLE_INIT:
			StopConveyor	:= TRUE;
			MC_BR_SecGetShuttle_0.Enable		:= TRUE;
			MC_BR_SecGetShuttle_0.Next			:= FALSE;
			MC_BR_SecGetShuttle_0.Mode			:= mcACPTRAK_SEARCH_BACKWARD;
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
					ShIndex	:= -1;
					
					IF UserIDSet THEN
						State	:= START_MOVEMENT;
						Cnt		:= 0;
					ELSE
						State	:= SET_USERID;
					END_IF;
				ELSE
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
				IF MC_BR_SecGetShuttle_0.Enable THEN
					State	:= GET_SHUTTLE;
				ELSE
					State	:= START_MOVEMENT;
					Cnt		:= 0;
				END_IF;
			ELSIF MC_BR_ShSetUserID_0.Error THEN
				ErrorInfo	:= 'Error in ShSetUserID';
				State		:= ERROR;
			END_IF;
			
		// Move all shuttles
		START_MOVEMENT:
			Paused			:= FALSE;			
			EnableStations	:= TRUE;
			
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
				IF Cnt >= NrOfShuttles THEN
					State	:= READY;
				END_IF;
			ELSIF MC_BR_ElasticMoveVel_0.Error THEN
				ErrorInfo	:= 'Error in ElasticMoveVel';
				State		:= ERROR;
			END_IF;
		
		// All shuttles added and started
		READY:						
			StartAxisMovement	:= TRUE;
			StopConveyor		:= FALSE;
			
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
		
		// Delete all shuttles and open the barrier
		DELETE_SHUTTLES:
			OpenBarrier		:= TRUE;
			EnableStations	:= FALSE;
			CalcShuttle.controlif	:= 0;
			MC_BR_AsmDeleteShuttle_0.Execute	:= TRUE;
			
			IF MC_BR_AsmDeleteShuttle_0.Done THEN
				MC_BR_AsmDeleteShuttle_0.Execute:= FALSE;
				State		:= POWER_OFF;
			ELSIF MC_BR_AsmDeleteShuttle_0.Error THEN
				ErrorInfo	:= 'Error in AsmDeleteShuttle';
				State		:= ERROR;
			END_IF;
		
		// Power off the assembly
		POWER_OFF:
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
			Paused			:= TRUE;
			EnableStations	:= FALSE;
			Start			:= FALSE;
			Stop			:= FALSE;
			CalcShuttle.controlif	:= 0;
			
			MC_BR_AsmPowerOn_0.Execute			:= FALSE;
			MC_BR_AsmPowerOff_0.Execute			:= FALSE;
			MC_BR_AsmDeleteShuttle_0.Execute	:= FALSE;
			MC_BR_AsmReset_0.Execute			:= FALSE;
			MC_BR_AsmReadInfo_0.Enable			:= FALSE;
	
			MC_BR_SecAddShuttle_Main.Execute	:= FALSE;
			MC_BR_SecAddShuttle_1.Execute		:= FALSE;
			MC_BR_SecGetShuttle_0.Enable		:= FALSE;
			MC_BR_SecReadInfo_Seg08.Enable		:= FALSE;
	
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
			IF StartAxisMovement AND MC_BR_SecReadInfo_Seg08.SectorInfo.ShuttleCount.Count = 0 THEN
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
	IF EDGEPOS(MpAxisBasic_0.Error) THEN
		ErrorInfo	:= 'Error in MpAxisBasic';
		StateAxis	:= AXIS_ERROR;
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
			ELSIF MC_BR_AsmReset_0.Error THEN
				ErrorInfo	:= 'Error in AsmReset';
				State		:= ERROR;
			END_IF;
		ELSIF StateAxis = AXIS_ERROR THEN
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
	MC_BR_SecGetShuttle_0();
	MC_BR_SecReadInfo_Seg08();
	MC_BR_SecReadInfo_CheckFree();
	
	MC_BR_ShSetUserID_0();
	
	MC_BR_ElasticMoveVel_0();
	
	MpAxisBasic_0();
	
	MpAxisCyclicSet_0.CyclicVelocity	:= ConveyorVelocity;
	MpAxisCyclicSet_0();
	
	FOR Index := 0 TO MAX_SHUTTLES_MIN_ONE DO
		// Read shuttle information if available
		IF Shuttle[Index].controlif <> 0 AND State > GET_SHUTTLE_WAIT AND State < DELETE_SHUTTLES AND Index < NrOfShuttles THEN
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
	
	AutomaticVelocityAdjNotActive	:= NOT(AutomaticVelocityAdjustment);
	 
END_PROGRAM

PROGRAM _EXIT
	
	MpAxisBasic_0.Enable		:= FALSE;
	MpAxisBasic_0();
	
	MpAxisCyclicSet_0.Enable	:= FALSE;
	MpAxisCyclicSet_0();
	 
END_PROGRAM

