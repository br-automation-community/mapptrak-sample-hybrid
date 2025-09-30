(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    B&R 
 * Created:   July 22, 2025/2:18 PM 
 * Description: Add a new shuttle to the trak if possible
 *********************************************************************************)

ACTION AddNewShuttle: 
	
	// Reset the state machine and all FUBs after a stop command
	IF OpenBarrier OR EDGENEG(EnableStations) THEN
		AddShuttleState	:= ADDSHUTTLE_RESET;
	END_IF;
	
	CASE AddShuttleState OF
		// Wait for enabling the station
		ADDSHUTTLE_INIT:
			IF AddShuttle AND EnableStations AND MC_BR_AsmReadInfo_0.AssemblyInfo.ShuttleCount.Count <= MAX_SHUTTLES THEN
				AddShuttleState	:= ADDSHUTTLE_CLOSE_BARRIER;
			END_IF;
		
		// Close the barrier to avoid a shuttle to be created on another one
		ADDSHUTTLE_CLOSE_BARRIER:
			MC_BR_SecReadInfo_AddShuttle.Enable			:= TRUE;
		
			MC_BR_BarrierCmd_AddShuttle.Command			:= mcACPTRAK_BARRIER_CLOSE;
			MC_BR_BarrierCmd_AddShuttle.Execute			:= TRUE;
			
			IF MC_BR_BarrierCmd_AddShuttle.Done THEN
				MC_BR_BarrierCmd_AddShuttle.Execute		:= FALSE;
				IF SimActive THEN
					AddShuttleState	:= ADDSHUTTLE_ADD_SHUTTLE;
				ELSE
					BarrierClosed_AddShuttle	:= TRUE;
					AddShuttleState	:= ADDSHUTTLE_POWER_OFF_SEGMENT;
				END_IF;
			ELSIF MC_BR_BarrierCmd_AddShuttle.Error THEN
				ErrorInfo		:= 'Error in BarrierCmd AddShuttle';
				State			:= ERROR;
				AddShuttleState	:= ADDSHUTTLE_ERROR;
			END_IF;
		
		// Add a shuttle to the trak
		ADDSHUTTLE_ADD_SHUTTLE:
			MC_BR_SecAddShuttle_AddShuttle.Sector		:= ADR(Sector_1);
			MC_BR_SecAddShuttle_AddShuttle.Position		:= AddPosition;
			MC_BR_SecAddShuttle_AddShuttle.Velocity		:= Velocity;
			MC_BR_SecAddShuttle_AddShuttle.AdvancedParameters.Mode			:= mcACPTRAK_ADD_IMMEDIATE;
			MC_BR_SecAddShuttle_AddShuttle.AdvancedParameters.MoveCmd		:= mcACPTRAK_MOV_CMD_ELASTICMOVEVEL;
			MC_BR_SecAddShuttle_AddShuttle.AdvancedParameters.Direction		:= mcDIR_POSITIVE;
			MC_BR_SecAddShuttle_AddShuttle.AdvancedParameters.Velocity		:= Velocity;
			MC_BR_SecAddShuttle_AddShuttle.AdvancedParameters.Acceleration	:= Acceleration;
			MC_BR_SecAddShuttle_AddShuttle.AdvancedParameters.Deceleration	:= Deceleration;
			MC_BR_SecAddShuttle_AddShuttle.AdvancedParameters.UserID		:= UserID;
			IF MC_BR_SecReadInfo_AddShuttle.SectorInfo.InRest AND MC_BR_SecReadInfo_AddShuttle.Valid AND MC_BR_SecReadInfo_AddShuttle.SectorInfo.ShuttleCount.Count = 0 THEN
				MC_BR_SecAddShuttle_AddShuttle.Execute	:= TRUE;
				AddShuttleState	:= ADDSHUTTLE_CHECK_CREATED;
			END_IF;
		
		// Check for shuttle created
		ADDSHUTTLE_CHECK_CREATED:
			IF MC_BR_SecAddShuttle_AddShuttle.Axis.controlif <> AxisOld.controlif THEN
				MC_BR_SecAddShuttle_AddShuttle.Execute	:= FALSE;
				AddShuttleState	:= ADDSHUTTLE_OPEN_BARRIER;
			ELSIF MC_BR_SecAddShuttle_AddShuttle.Error THEN
				ErrorInfo	:= 'Error in SecAddShuttle AddShuttle';
				State		:= ERROR;
				AddShuttleState	:= ADDSHUTTLE_ERROR;
			END_IF;
			// Check if new shuttle created
			AxisOld	:= MC_BR_SecAddShuttle_AddShuttle.Axis;
				
		// Power off the segment
		ADDSHUTTLE_POWER_OFF_SEGMENT:
			MC_BR_SegPowerOff_AddShuttle.Segment		:= ADR(Seg_01);
			IF MC_BR_SecReadInfo_AddShuttle.SectorInfo.InRest AND MC_BR_SecReadInfo_AddShuttle.Valid THEN
				MC_BR_SegPowerOff_AddShuttle.Execute	:= TRUE;
			END_IF;
			
			IF MC_BR_SegPowerOff_AddShuttle.Done THEN
				MC_BR_SegPowerOff_AddShuttle.Execute	:= FALSE;
				AddShuttleState	:= ADDSHUTTLE_POWER_ON_SEGMENT;
			ELSIF MC_BR_SegPowerOff_AddShuttle.Error THEN
				ErrorInfo		:= 'Error in SegPowerOff AddShuttle';
				State			:= ERROR;
				AddShuttleState	:= ADDSHUTTLE_ERROR;
			END_IF;
				
		// Power on the segment
		ADDSHUTTLE_POWER_ON_SEGMENT:
			MC_BR_SegPowerOn_AddShuttle.Segment		:= ADR(Seg_01);
			MC_BR_SegPowerOn_AddShuttle.Execute		:= ConfirmShuttleAdded;
			
			IF MC_BR_SegPowerOn_AddShuttle.Done THEN
				MC_BR_SegPowerOn_AddShuttle.Execute	:= FALSE;
				AddShuttleState	:= ADDSHUTTLE_GET_SHUTTLE;
			ELSIF MC_BR_SegPowerOn_AddShuttle.Error THEN
				ErrorInfo		:= 'Error in SegPowerOn AddShuttle';
				State			:= ERROR;
				AddShuttleState	:= ADDSHUTTLE_ERROR;
			END_IF;
			
		// Get shuttle reference for real hardware
		ADDSHUTTLE_GET_SHUTTLE:
			MC_BR_SecGetShuttle_AddShuttle.Sector		:= ADR(Sector_3);
			MC_BR_SecGetShuttle_AddShuttle.Enable		:= TRUE;
			
			IF MC_BR_SecGetShuttle_AddShuttle.Valid THEN
				MC_BR_SecGetShuttle_AddShuttle.Next		:= FALSE;
				// If Continue is pressed check how many shuttles are on the trak
				// If no shuttles are on the trak open the barrier, if at least one is, set the UserID
				IF MC_BR_SecGetShuttle_AddShuttle.TotalCount > 0 THEN
					AddedShuttle	:= MC_BR_SecGetShuttle_AddShuttle.Axis;
					AddShuttleState	:= ADDSHUTTLE_SET_USERID;
				ELSE
					MC_BR_SecGetShuttle_AddShuttle.Enable	:= FALSE;
					AddShuttleState	:= ADDSHUTTLE_OPEN_BARRIER;
				END_IF;
			ELSIF MC_BR_SecGetShuttle_AddShuttle.Error THEN
				ErrorInfo		:= 'Error in SecGetShuttle AddShuttle';
				State			:= ERROR;
				AddShuttleState	:= ADDSHUTTLE_ERROR;
			END_IF;
		
		// Set the UserID for the shuttle
		ADDSHUTTLE_SET_USERID:
			MC_BR_ShSetUserID_AddShuttle.Axis			:= ADR(AddedShuttle);
			MC_BR_ShSetUserID_AddShuttle.UserID			:= UserID;
			MC_BR_ShSetUserID_AddShuttle.Execute		:= TRUE;
			
			IF MC_BR_ShSetUserID_AddShuttle.Done THEN
				MC_BR_ShSetUserID_AddShuttle.Execute	:= FALSE;
				AddShuttleState	:= ADDSHUTTLE_MOVESHUTTLE;
			ELSIF MC_BR_ShSetUserID_AddShuttle.Error THEN
				ErrorInfo		:= 'Error in ShSetUserID AddShuttle';
				State			:= ERROR;
				AddShuttleState	:= ADDSHUTTLE_ERROR;
			END_IF;
			
		// Start a movement for the shuttle
		ADDSHUTTLE_MOVESHUTTLE:
			MC_BR_ElasticMoveVel_AddShuttle.Axis		:= ADR(AddedShuttle);
			MC_BR_ElasticMoveVel_AddShuttle.Direction	:= mcDIR_POSITIVE;
			MC_BR_ElasticMoveVel_AddShuttle.Velocity	:= Velocity;
			MC_BR_ElasticMoveVel_AddShuttle.Acceleration:= Acceleration;
			MC_BR_ElasticMoveVel_AddShuttle.Deceleration:= Deceleration;
			MC_BR_ElasticMoveVel_AddShuttle.Execute		:= TRUE;
			
			IF EDGEPOS(MC_BR_ElasticMoveVel_AddShuttle.Active) THEN
				MC_BR_ElasticMoveVel_AddShuttle.Execute	:= FALSE;
				
				// If all shuttles are read, power on the segment
				IF MC_BR_SecGetShuttle_AddShuttle.RemainingCount = 0 THEN
					MC_BR_SecGetShuttle_AddShuttle.Enable	:= FALSE;
					AddShuttleState	:= ADDSHUTTLE_OPEN_BARRIER;
				ELSE
					MC_BR_SecGetShuttle_AddShuttle.Next	:= TRUE;
					AddShuttleState	:= ADDSHUTTLE_GET_SHUTTLE;
				END_IF;
			ELSIF MC_BR_ElasticMoveVel_AddShuttle.Error THEN
				ErrorInfo		:= 'Error in ElasticMoveVel AddShuttle';
				State			:= ERROR;
				AddShuttleState	:= ADDSHUTTLE_ERROR;
			ELSIF MC_BR_SecGetShuttle_AddShuttle.Error THEN
				ErrorInfo		:= 'Error in SecGetShuttle AddShuttle';
				State			:= ERROR;
				AddShuttleState	:= ADDSHUTTLE_ERROR;
			END_IF;
		
		// Open the barrier again
		ADDSHUTTLE_OPEN_BARRIER:
			MC_BR_BarrierCmd_AddShuttle.Command			:= mcACPTRAK_BARRIER_OPEN;
			MC_BR_BarrierCmd_AddShuttle.Execute			:= TRUE;
			
			IF MC_BR_BarrierCmd_AddShuttle.Done THEN
				MC_BR_BarrierCmd_AddShuttle.Execute		:= FALSE;
				AddShuttle					:= FALSE;
				ConfirmShuttleAdded			:= FALSE;
				BarrierClosed_AddShuttle	:= FALSE;
				AddShuttleState	:= ADDSHUTTLE_INIT;
			ELSIF MC_BR_BarrierCmd_AddShuttle.Error THEN
				ErrorInfo		:= 'Error in BarrierCmd AddShuttle';
				State			:= ERROR;
				AddShuttleState	:= ADDSHUTTLE_ERROR;
			END_IF;
		
		// Reset the station and open the barrier
		ADDSHUTTLE_RESET:
			MC_BR_BarrierCmd_AddShuttle.Execute			:= FALSE;
			OpenBarrier			:= FALSE;
			AddShuttleState		:= ADDSHUTTLE_OPEN_BARRIER;
		
		// Error state, reset all FUBs
		ADDSHUTTLE_ERROR:
			MC_BR_SecAddShuttle_AddShuttle.Execute		:= FALSE;
			MC_BR_SecReadInfo_AddShuttle.Enable			:= FALSE;
			MC_BR_BarrierCmd_AddShuttle.Execute			:= FALSE;
		
			AddShuttleState		:= ADDSHUTTLE_INIT;

	END_CASE;
	
	IF MC_BR_SecReadInfo_AddShuttle.Error THEN
		MC_BR_SecReadInfo_AddShuttle.Enable			:= FALSE;
		ErrorInfo		:= 'Error in SecReadInfo AddShuttle';
		State			:= ERROR;
		AddShuttleState	:= ADDSHUTTLE_ERROR;
	END_IF;
	
	// Call the FUBs
	MC_BR_SecAddShuttle_AddShuttle();
	MC_BR_SecReadInfo_AddShuttle();
	MC_BR_BarrierCmd_AddShuttle();
	
	MC_BR_SegPowerOff_AddShuttle();
	MC_BR_SegPowerOn_AddShuttle();
	MC_BR_SecGetShuttle_AddShuttle();
	MC_BR_ShSetUserID_AddShuttle();
	MC_BR_ElasticMoveVel_AddShuttle();
	
END_ACTION
