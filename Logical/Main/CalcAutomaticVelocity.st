(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    B&R 
 * Created:   July 24, 2025/10:46 AM 
 * Description: Calculate the automatic velocity adjustment
 *********************************************************************************)

ACTION CalcAutomaticVelocity: 
	
	MC_BR_ShReadInfo_Calc.Axis			:= ADR(CalcShuttle);
	MC_BR_ShReadInfo_Calc.Enable		:= AutomaticVelocityAdjustment AND CalcShuttle.controlif <> 0 AND EnableStations;
	
	// Restart the FUB when a new shuttle is available
	IF CalcShuttle.controlif <> OldShuttle_Calc.controlif THEN
		MC_BR_ShReadInfo_Calc.Enable	:= FALSE;
	END_IF;
	
	OldShuttle_Calc	:= CalcShuttle;
	
	IF MC_BR_ShReadInfo_Calc.Error THEN
		ErrorInfo	:= 'Error in ShReadInfo Calc';
		State		:= ERROR;
	END_IF;
	
	// Call the FUBs
	MC_BR_ShReadInfo_Calc();
	
	// Get the velocity if the shuttle is real and on the first segment after the conveyor
	IF MC_BR_ShReadInfo_Calc.Valid AND MC_BR_ShReadInfo_Calc.ShuttleInfo.CurrentValues.SegmentPosition.Segment.controlif = Seg_08.controlif AND 
		MC_BR_ShReadInfo_Calc.ShuttleInfo.CurrentValues.SegmentPosition.Position < 0.2 AND NOT(MC_BR_ShReadInfo_Calc.ShuttleInfo.AdditionalInfo.Virtual) AND 
		MC_BR_ShReadInfo_Calc.ShuttleInfo.CurrentValues.Velocity <> 0 THEN
		ConveyorVelocity	:= MC_BR_ShReadInfo_Calc.ShuttleInfo.CurrentValues.Velocity;
	// If the shuttle left the segment, but no other shuttle is available, set the maximum speed
	ELSIF MC_BR_ShReadInfo_Calc.Valid AND NOT(MC_BR_ShReadInfo_Calc.ShuttleInfo.AdditionalInfo.Virtual) THEN
		ConveyorVelocity	:= 2.0;
	END_IF;
	
END_ACTION
