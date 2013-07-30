//
//	AI controller used to run the customer pawns. Handles moving the pawn to the tee, locking him into a hitting location, and telling the pawn to begin hitting.
//

class CartAIController_Customer extends AIController;

var CartCustomerPawn CartPawn;
var vector GoalPoint, TempDest;
var bool AIDebug;

event Possess(Pawn inPawn, bool bVehicleTransition)
{
	super.Possess(inPawn, bVehicleTransition);

	// Make sure our movement physics are set and cast our pawn class
	inPawn.SetMovementPhysics();
	CartPawn = CartCustomerPawn(inPawn);
}

function bool FindNavMeshPath(vector Point)
{
	// Clear cache and constraints (ignore recycling for the moment)
	NavigationHandle.PathConstraintList = none;
	NavigationHandle.PathGoalList = none;

	// Create constraints
	class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle, Point);
	class'NavMeshGoal_At'.static.AtLocation(NavigationHandle, Point, 96);

	// Find path
	return NavigationHandle.FindPath();
}

auto state Spawning
{
	// Find a hitting location
	local TargetPoint T;
	
	Begin:
	
	// Pick a random hitting stall from the pawn array and tag it blocked so nobody else takes it
	CartPawn.OurHitLocation = CartPawn.HitLocations[Rand(CartPawn.HitLocations.Length)];
	CartPawn.OurHitLocation.bBlocked = true;
	
	// Compare tags from our hit stall to the tee markers and get the match
	ForEach WorldInfo.AllActors(class'TargetPoint', T)
	{
		if (T.Tag == CartPawn.OurHitLocation.Tag)
		{
			CartPawn.OurTee = T;
		}
	}	
	
	// Set our movement goal point
	GoalPoint = CartPawn.OurHitLocation.Location;
	`log("Goalpoint at " $GoalPoint);
	GotoState('Moving');
}

state Moving
{
	Begin:

	while (Pawn != none && !Pawn.ReachedPoint(GoalPoint, Pawn))
	{
		if( !NavigationHandle.PointReachable(GoalPoint))
		{
			if( FindNavMeshPath(GoalPoint) )
			{
//				NavigationHandle.DrawPathCache(,TRUE);
			}
			else
			{
				//give up because the nav mesh failed to find a path
				`warn("FindNavMeshPath failed to find a path to"@GoalPoint);
				Sleep(1);
				Goto 'Begin';
			}   
		}
		else
		{
//			`log("Direct move");
			// then move directly to the actor
			MoveTo(GoalPoint, ,96);
//			FlushPersistentDebugLines();
//			DrawDebugLine(Pawn.Location,GoalPoint,0,255,0,true);
			GotoState('Hitting');
		}

		while( Pawn != None && !Pawn.ReachedPoint(GoalPoint, Pawn))
		{	
			if (Pawn.Health <= 0)
			{
				`log("Pawn death detected");
				GotoState('Dead');
			}
			// move to the first node on the path
			if( NavigationHandle.GetNextMoveLocation( TempDest, 96) )
			{
				// suggest move preparation will return TRUE when the edge's
			    // logic is getting the bot to the edge point
					// FALSE if we should run there ourselves
				if (!NavigationHandle.SuggestMovePreparation( TempDest,self))
				{
//					`log("Path move");
					TempDest -= vect(0,0,48);
					MoveTo(TempDest, ,96);	
//					FlushPersistentDebugLines();
//					DrawDebugLine(Pawn.Location,TempDest,255,0,0,true);
//					DrawDebugSphere(TempDest,16,20,255,0,0,true);		
					Goto 'Begin';
				}
			}
			sleep(0.5);
		}
		Sleep(0.5);
		Goto 'Begin';
	}
	Sleep(0.5);
	Goto 'Begin';
}

state Hitting
{
	local rotator HitRotation;
	
	Begin:
	
	// Flag some tags
	CartPawn.IsSwinging = true;
	// Tell the pawn to begin the hitting timer
	CartPawn.ReadyToHit();
	// Make sure we rotate correctly
	HitRotation = CartPawn.OurHitLocation.Rotation;
	HitRotation.Yaw += 16384;
	
	CartPawn.SetLocation(CartPawn.OurHitLocation.Location);
	CartPawn.SetRotation(HitRotation);
	
	// And set focus so our pawn always faces the tee
	Focus = CartPawn.OurTee;
	
//	Sleep(10 + Rand(20));
//	GotoState('Swinging');
}

state Swinging
{
	Begin:
	// Unused state
	CartPawn.PrioritySlot.PlayCustomAnimByDuration('swing', 4.12, 0.1, 0.1, false, true);
	GotoState('Hitting');
}

state Dead
{
	Begin:
}

defaultproperties
{
	AIDebug = false
}