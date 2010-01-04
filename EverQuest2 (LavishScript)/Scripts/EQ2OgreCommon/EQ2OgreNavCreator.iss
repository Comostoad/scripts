;-----------------------------------------------------------------------------------------------
; New NavCreator by Kannkor (Hotshot). Written from scratch, based off of EQ2NavCreator written by Amadeus
; Version 1.01
;
;-----------------------------------------------------------------------------------------------

/**

**/



variable float XZBoxRadius=1
variable float YUpBoxRadius=1
variable float YDownBoxRadius=0.5
variable float MaxDistanceBetweenBoxes=3

variable float X1
variable float X2
variable float Y1
variable float Y2
variable float Z1
variable float Z2

variable(global) int EQ2OgreNavCreatorHUDX=250
variable(global) int EQ2OgreNavCreatorHUDY=180
variable(global) int EQ2OgreNavCreatorHUDInc=20
variable(global) int EQ2OgreNavCreatorCurrentPointHUDX=750
variable(global) int EQ2OgreNavCreatorCurrentPointHUDY=180

variable bool AllowConnections=TRUE
variable lnavregion LastPoint
variable lnavregion CurrentPoint
variable lnavregion EQ2OgreNavRegion
variable(global) lnavconnection EQ2OgreNavConnection

variable collection:string RegionConnectionsToBeRemoved

variable(global) bool EQ2OgreMapperAddCustomPointBool=FALSE
variable(global) bool EQ2OgreMapperExitAndSaveBool=FALSE
variable(global) bool EQ2OgreMapperMarkAsAvoidBool=FALSE
variable(global) bool EQ2OgreMapperDeletePointBool=FALSE

variable string CustomPointName=NULL
variable(global) string EQ2OgreNavCreatorLastNamedPoint=None

variable string ZoneVar
;I use a Zone variable to ensure the lavish tree we create is deleted, and the zone we start in is the file we save also incase you zone.

#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreCommon/OgreMapController.inc"

function main()
{
	;Delcare the Nav Object
	declare OgreNavMapperOb OgreNavMapperObject
	OgreNavMapperOb:ImportIt

	Script:Squelch
	bind EQ2OgreNavCreatorAddCustomPointBind F2 EQ2OgreMapperAddCustomPointBool:Set[TRUE]
	bind EQ2OgreNavCreatorMarkAsAvoidBind F3 EQ2OgreMapperMarkAsAvoidBool:Set[TRUE]
	bind EQ2OgreNavCreatorDeletePointBind F4 EQ2OgreMapperDeletePointBool:Set[TRUE]
	bind EQ2OgreNavCreatorSaveAndExitBind F11 EQ2OgreMapperExitAndSaveBool:Set[TRUE]

	HUD -add EQ2OgreNavCreatorCustomAddPointHUD ${EQ2OgreNavCreatorHUDX},${EQ2OgreNavCreatorHUDY:Inc[${EQ2OgreNavCreatorHUDInc}]} "F2 - Re-name and make unique point."
	HUD -add EQ2OgreNavCreatorLastNamedPointAddedHUD ${EQ2OgreNavCreatorHUDX},${EQ2OgreNavCreatorHUDY:Inc[${EQ2OgreNavCreatorHUDInc}]} "Last unique point added: \${EQ2OgreNavCreatorLastNamedPoint}"
	HUD -add EQ2OgreNavCreatorMarkAsAvoidHUD ${EQ2OgreNavCreatorHUDX},${EQ2OgreNavCreatorHUDY:Inc[${EQ2OgreNavCreatorHUDInc}]} "F3 - Make current point as AVOID."
	HUD -add EQ2OgreNavCreatorDeletePointHUD ${EQ2OgreNavCreatorHUDX},${EQ2OgreNavCreatorHUDY:Inc[${EQ2OgreNavCreatorHUDInc}]} "F4 - Delete current point (method of removing unique)."


	HUD -add EQ2OgreNavCreatorSaveAndExitHUD ${EQ2OgreNavCreatorHUDX},${EQ2OgreNavCreatorHUDY:Inc[${EQ2OgreNavCreatorHUDInc}]} "F11 - Save and Exit."
	HUD -add EQ2OgreNavCreatorTotalPointsHUD ${EQ2OgreNavCreatorHUDX},${EQ2OgreNavCreatorHUDY:Inc[${EQ2OgreNavCreatorHUDInc}]} "Total points: \${Script[EQ2OgreNavCreator].VariableScope.EQ2OgreNavRegion.ChildCount}"

	;**Below is information about the current point you are on**
	HUD -add EQ2OgreNavCreatorCurrentPointNameHUD ${EQ2OgreNavCreatorCurrentPointHUDX},${EQ2OgreNavCreatorCurrentPointHUDY:Inc[${EQ2OgreNavCreatorHUDInc}]} "Current point Name: \${Script[EQ2OgreNavCreator].VariableScope.EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}].Name}"
	HUD -add EQ2OgreNavCreatorCurrentPointUniqueHUD ${EQ2OgreNavCreatorCurrentPointHUDX},${EQ2OgreNavCreatorCurrentPointHUDY:Inc[${EQ2OgreNavCreatorHUDInc}]} "Current point Unique?: \${Script[EQ2OgreNavCreator].VariableScope.EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}].Unique}"
	HUD -add EQ2OgreNavCreatorCurrentPointAvoidHUD ${EQ2OgreNavCreatorCurrentPointHUDX},${EQ2OgreNavCreatorCurrentPointHUDY:Inc[${EQ2OgreNavCreatorHUDInc}]} "Valid point?: \${Script[EQ2OgreNavCreator].VariableScope.EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}].AllPointsValid}"


	Script:Unsquelch

	while 1
	{
		AllowConnections:Set[TRUE]

		if ${EQ2OgreMapperExitAndSaveBool} || ${ZoneVar.NotEqual[${Zone}]}
			Script:End
		if ${EQ2OgreMapperMarkAsAvoidBool}
		{
			;OgreNavMapperOb:MarkAvoid
			OgreNavMapperOb:RemoveBox
			AllowConnections:Set[FALSE]
			OgreNavMapperOb:WorkTheMagic
			EQ2OgreMapperMarkAsAvoidBool:Set[FALSE]
			continue
		}
		if ${EQ2OgreMapperDeletePointBool}
		{
			OgreNavMapperOb:RemoveBox
			EQ2OgreMapperDeletePointBool:Set[FALSE]
			continue
		}

		if ${EQ2OgreMapperAddCustomPointBool}
		{
			OgreNavMapperOb:SetBoxAroundMe
			call CustomAddBox
			if ${CustomPointName.NotEqual[NULL]}
			{
				OgreNavMapperOb:AddCustomPoint
			}
			EQ2OgreMapperAddCustomPointBool:Set[FALSE]
			CustomPointName:Set[NULL]
		}
		else
		{
			OgreNavMapperOb:WorkTheMagic
		}

		wait 1
	}

	;***How many Children do we have?
	;echo Child Count: ${EQ2OgreNavRegion.ChildCount}

}
function CustomAddBox()
{
	InputBox "Enter a name for the custom point"
	if ${UserInput.Length}
		CustomPointName:Set[${UserInput}]
}
objectdef OgreNavMapperObject
{
	method Initialize(string Name)
	{
		ZoneVar:Set[${Zone}]
	}
	method WorkTheMagic()
	{
		This:SetBoxAroundMe
		if ${This.CheckIfBoxMapped}
		{
			This:LoadCurrentAndPreviousPoints
			;If the point is mapped, we need not do anything
			return
		}
		else
		{
			;Point is not mapped. Lets add the point, connect the last point since it is valid (we just ran from it)
			;then connect the surrounding poings
			This:AddBox

			;If AllowConnections is FALSE, we will skip the adding connections.
			if !${AllowConnections}
				return
			else
				This:MarkAsAllPoints
			This:ConnectLastPoint
			This:ConnectSurroundingRegions
		}
		
	}
	method AddCustomPoint()
	{
		;If we are already on a mapped region, delete it first so we can add in our own and not to "double" up on the same spot.
		if ${This.CheckIfBoxMapped}
			This:RemoveBox
		EQ2OgreNavCreatorLastNamedPoint:Set[${CustomPointName}]
		This:CustomAddBox[${CustomPointName}]
		This:ConnectLastPoint
		This:ConnectSurroundingRegions
	}
	member:bool CollisionCheck(float CCX1, float CCY1, float CCZ1, float CCX2, float CCY2, float CCZ2, float HeightMod=0.5)
	{
		if !${EQ2.CheckCollision[${CCX1},${Math.Calc[${CCY1}+${HeightMod}]},${CCZ1},${CCX2},${Math.Calc[${CCY2}+${HeightMod}]},${CCZ2}]}
			return TRUE
	}
	member:bool DistanceCheck(float CCX1, float CCY1, float CCZ1, float CCX2, float CCY2, float CCZ2)
	{
		if ${Math.Distance[${CCX1},${CCY1},${CCZ1},${CCX2},${CCY2},${CCZ2}]} < ${MaxDistanceBetweenBoxes}
			return TRUE
	}
	method LoadCurrentAndPreviousPoints()
	{
		LastPoint:SetRegion[${CurrentPoint.ID}]
		CurrentPoint:SetRegion[${EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}].ID}]
	}
	member:bool CheckIfBoxMapped()
	{
		if ${EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}].ID}==${EQ2OgreNavRegion.ID}
		{
			;echo ${Me.ToActor.Loc} is not mapped. BestContainer ( ${EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}].ID} ) is the same as the Region ( ${EQ2OgreNavRegion.ID} )
			return FALSE
		}
		else
		{
			;echo ${Me.ToActor.Loc} is mapped. BestContainer ( ${EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}].ID} ) is NOT the same as the Region ( ${EQ2OgreNavRegion.ID} )
			return TRUE
		}
	}
	method RemoveBox()
	{
		RegionConnectionsToBeRemoved:Set[${EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}].Name},${EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}].Name}]
		echo Adding ${EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}].Name} To the RegionConnectionsToBeRemoved ( ${RegionConnectionsToBeRemoved.Element[${EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}].Name}]} )
		EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}]:Remove
	}
	method MarkAvoid()
	{
		EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}]:SetAvoid[TRUE]
		EQ2OgreNavRegion.BestContainer[${Me.ToActor.Loc}]:SetAllPointsValid[FALSE]
	}
	method AddBox()
	{
		;echo Adding Box around ${Me.ToActor.Loc}
		;EQ2OgreNavRegion:AddChild[box,"auto",${X1},${X2},${Y1},${Y2},${Z1},${Z2}]
		LastPoint:SetRegion[${CurrentPoint.ID}]
		CurrentPoint:SetRegion[${EQ2OgreNavRegion.AddChild[box,"auto",${X1},${X2},${Y1},${Y2},${Z1},${Z2}]}]
		CurrentPoint:SetAllPointsValid[${AllowConnections}]
	}
	method CustomAddBox(string BoxName)
	{
		echo Adding custom Box ( ${BoxName} ) around ${Me.ToActor.Loc}
		;EQ2OgreNavRegion:AddChild[box,${BoxName},-unique,${X1},${X2},${Y1},${Y2},${Z1},${Z2}]
		;LastPoint:SetRegion[${CurrentPoint.ID}]
		CurrentPoint:SetRegion[${EQ2OgreNavRegion.AddChild[box,${BoxName},-unique,${X1},${X2},${Y1},${Y2},${Z1},${Z2}]}]
		CurrentPoint:SetAllPointsValid[${AllowConnections}]
	}
	method SetBoxAroundMe()
	{
		X1:Set[${Me.ToActor.X}-${XZBoxRadius}]
		X2:Set[${Me.ToActor.X}+${XZBoxRadius}]
		Y1:Set[${Me.ToActor.Y}-${YDownBoxRadius}]
		Y2:Set[${Me.ToActor.Y}+${YUpBoxRadius}]
		Z1:Set[${Me.ToActor.Z}-${XZBoxRadius}]
		Z2:Set[${Me.ToActor.Z}+${XZBoxRadius}]
	}
	method ConnectLastPoint()
	{
		if !${CurrentPoint.AllPointsValid} || !${LastPoint.AllPointsValid} || ${CurrentPoint}==${LastPoint} || ${CurrentPoint}==0 || ${LastPoint}==0 || ${CurrentPoint}==${EQ2OgreNavRegion.ID} || ${LastPoint}==${EQ2OgreNavRegion.ID}
		{
			echo Can't connect points: ${CurrentPoint}==${LastPoint} || ${CurrentPoint}==0 || ${LastPoint}==0 || ${CurrentPoint}==${EQ2OgreNavRegion.ID} || ${LastPoint}==${EQ2OgreNavRegion.ID}
		}
		else
		{
			EQ2OgreNavRegion.FindRegion[${CurrentPoint}]:Connect[${LastPoint}]
			EQ2OgreNavRegion.FindRegion[${LastPoint}]:Connect[${CurrentPoint}]
		}
	}
	method ConnectSurroundingRegions()
	{
		variable index:lnavregionref SurroundingRegions
		variable int RegionsFound
		variable int TempCounter=1
		variable float DistanceToCheck=5

		;This shouldn't ever be called, but may as well save the CPU cycles if it is
		if !${CurrentPoint.AllPointsValid}
		{
			echo The current point ( CurrentPoint.ID: ${CurrentPoint.ID} ) is flagged as not able to have connections ( Currentpoint.AllPointsValid: ${CurrentPoint.AllPointsValid} ), but we are inside of the ConnectSurroundingRegions method. Please bug report this.
		}
		RegionsFound:Set[${EQ2OgreNavRegion.ChildrenWithin[SurroundingRegions,${DistanceToCheck},${CurrentPoint.CenterPoint}]}]
		if ${RegionsFound} > 0
		{
			do
			{
				;if ${SurroundingRegions.Get[${TempCounter}].ID}==${CurrentPoint.ID} || ${SurroundingRegions.Get[${TempCounter}].ID}==${LastPoint.ID}
				if ${SurroundingRegions.Get[${TempCounter}].ID}==${CurrentPoint.ID} || !${SurroundingRegions.Get[${TempCounter}].AllPointsValid}
					continue

				if ${This.DistanceCheck[${CurrentPoint.CenterPoint},${SurroundingRegions.Get[${TempCounter}].CenterPoint}]} && ${This.CollisionCheck[${CurrentPoint.CenterPoint},${SurroundingRegions.Get[${TempCounter}].CenterPoint}]}
				{
					;CurrentRegion:Connect[${SurroundingRegions.Get[${TempCounter}].FQN}]
					;SurroundingRegions.Get[${TempCounter}]:Connect[${CurrentRegion.FQN}]
					EQ2OgreNavRegion.FindRegion[${CurrentPoint}]:Connect[${SurroundingRegions.Get[${TempCounter}].ID}]
					EQ2OgreNavRegion.FindRegion[${SurroundingRegions.Get[${TempCounter}].ID}]:Connect[${CurrentPoint}]
				}
			}
			while ${SurroundingRegions.Get[${TempCounter:Inc}](exists)}
		}
	}
	method ImportIt()
	{

		OgreMapControllerOb:LoadMap[${ZoneVar}]
		EQ2OgreNavRegion:SetRegion[${LavishNav.FindRegion[${ZoneVar}].ID}]
	}
	method ExportIt()
	{
		echo Method: Saving to: [${ZoneFilePath}${ZoneVar}.xml]
		EQ2OgreNavRegion:Export[${ZoneFilePath}${ZoneVar}.xml]
	}
}
function ExportIt()
{

	echo Function: Saving to: [${ZoneFilePath}${ZoneVar}.lso]
	EQ2OgreNavRegion:Export[-lso,${ZoneFilePath}${ZoneVar}.lso]
	;EQ2OgreNavRegion:Export[${ZoneFilePath}${ZoneVar}.xml]
	;If someXMLvar is true
	;echo Saving an XML copy also.
	;EQ2OgreNavRegion:Export[${ZoneFilePath}${ZoneVar}.xml]
}
function CleanUpConnections()
{
	if ${RegionConnectionsToBeRemoved.Used}>0
	{
		echo Cleaning up ${RegionConnectionsToBeRemoved.Used}. This will take up to a minute please wait.
		;One at a time, go through every single Child (Box) and see if it contains RegionConnectionsToBeRemoved, if it does, clear it.
		
		variable lnavregionref NavRef
		variable int EQ2OgreNavCounter
		EQ2OgreNavCounter:Set[0]

		NavRef:SetRegion[${LavishNav.FindRegion[${Zone}].Children}]
		while ${NavRef.Region(exists)}
		{
			if !${RegionConnectionsToBeRemoved.FirstKey(exists)}
				return
			do
			{
				if ${NavRef.GetConnection[${RegionConnectionsToBeRemoved.CurrentKey}](exists)}
				{
					echo (NoUni) ABC exists in ${NavRef} ${NavRef.Name} ConnectionID: ${NavRef.GetConnection[${RegionConnectionsToBeRemoved.CurrentKey}].ID}
					EQ2OgreNavConnection:SetConnection[${NavRef.GetConnection[${RegionConnectionsToBeRemoved.CurrentKey}].ID}]
					EQ2OgreNavConnection:Remove
					;echo ABC exists in ${NavRef} ${NavRef.Name} ConnectionID: ${NavRef.GetConnection[${RegionConnectionsToBeRemoved.CurrentKey}].ID}
				}
				elseif ${NavRef.GetConnection[${RegionConnectionsToBeRemoved.CurrentKey}.${EQ2OgreNavRegion.Name}](exists)}
				{
					echo (UniAdded)ABC exists in ${NavRef} ${NavRef.Name} ConnectionID: ${NavRef.GetConnection[${RegionConnectionsToBeRemoved.CurrentKey}.${EQ2OgreNavRegion.Name}].ID}
					EQ2OgreNavConnection:SetConnection[${NavRef.GetConnection[${RegionConnectionsToBeRemoved.CurrentKey}.${EQ2OgreNavRegion.Name}].ID}]
					EQ2OgreNavConnection:Remove
					;echo ABC exists in ${NavRef} ${NavRef.Name} ConnectionID: ${NavRef.GetConnection[${RegionConnectionsToBeRemoved.CurrentKey}.${EQ2OgreNavRegion.Name}].ID}
				}
				NavRef:SetRegion[${NavRef.Next}]
			}
			while ${RegionConnectionsToBeRemoved.NextKey(exists)}
		}
	
	}
	else
		echo No connections to be cleaned up.
}
atom atexit()
{
	Script:Squelch

	bind -delete EQ2OgreNavCreatorAddCustomPointBind
	bind -delete EQ2OgreNavCreatorSaveAndExitBind
	bind -delete EQ2OgreNavCreatorMarkAsAvoidBind
	bind -delete EQ2OgreNavCreatorDeletePointBind

	HUD -remove EQ2OgreNavCreatorLastNamedPointAddedHUD
	HUD -remove EQ2OgreNavCreatorCustomAddPointHUD
	HUD -remove EQ2OgreNavCreatorSaveAndExitHUD
	HUD -remove EQ2OgreNavCreatorTotalPointsHUD
	HUD -remove EQ2OgreNavCreatorDeletePointHUD 
	HUD -remove EQ2OgreNavCreatorMarkAsAvoidHUD 

	HUD -remove EQ2OgreNavCreatorCurrentPointNameHUD 
	HUD -remove EQ2OgreNavCreatorCurrentPointUniqueHUD
	HUD -remove EQ2OgreNavCreatorCurrentPointAvoidHUD

	Script:Unsquelch

	call CleanUpConnections
	call ExportIt
	OgreMapControllerOb:UnLoadMap[${ZoneVar}]

	;LNavRegion[${ZoneVar}]:Remove
	;EQ2OgreNavRegion:Remove
	;LNavRegion[EQ2OgreNavCreator]:Remove
	;LavishNav[EQ2OgreNavRegion]:Clear
	echo Exiting EQ2OgreNavCreator
}