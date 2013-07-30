//
//	The cart vehicle. Handles displaying the cart mesh, suspension animations, picker frame adjustments to terrain
//

class CartVehicle extends SVehicle;

var HUD OurHUD;
// A whole bunch of skeletal controls
var SkelControlSingleBone PickerFrameControl, PickerSteerControl, PickerWheelControl, Picker1RotControl, Picker2RotControl, Picker3RotControl, SteeringControl;
var SkelControlSingleBone LeftPickerFrameControl, LeftPickerSteerControl, LeftPickerWheelControl, RightPickerFrameControl, RightPickerSteerControl, RightPickerWheelControl;
// Refs for all the pickers to be attached to the frames
var CartPicker Picker1, Picker2, Picker3, LeftPicker1, LeftPicker2, RightPicker1, RightPicker2;
var SkeletalMeshComponent Picker1Mesh, Picker2Mesh, Picker3Mesh;
// Some values used to adjust the picker rotations
var float Picker1DesiredRot, Picker2DesiredRot, Picker3DesiredRot, PickerSteer, PickerDesiredSteer;
// Camera values
var float CamTwoDistance, CamOneFOV;
var CameraActor GroundCam;
// A bool to prevent instant re-collisions
var bool CanCollide;
var array<SoundCue> HitSounds;

simulated function DrawHUD( HUD H )
{
	OurHUD = H;
//	DisplayWheelsDebug(H, 20);
}

simulated event PostBeginPlay()
{	
	local CameraActor C;
	
	// Spawn in the 3 front pickers
	Picker1 = Spawn(class'CartPicker', self, , Location, Rotation, , true);
	Picker2 = Spawn(class'CartPicker', self, , Location, Rotation, , true);
	Picker3 = Spawn(class'CartPicker', self, , Location, Rotation, , true);
	
	// Give the pickers a reference to the vehicle
	Picker1.OurCart = self;
	Picker2.OurCart = self;
	Picker3.OurCart = self;
	
	// Spawn in the side pickers and fill their refs as well
	LeftPicker1 = Spawn(class'CartPicker', self, , Location, Rotation, , true);
	LeftPicker2 = Spawn(class'CartPicker', self, , Location, Rotation, , true);
	RightPicker1 = Spawn(class'CartPicker', self, , Location, Rotation, , true);
	RightPicker2 = Spawn(class'CartPicker', self, , Location, Rotation, , true);
	
	LeftPicker1.OurCart = self;
	LeftPicker2.OurCart = self;
	RightPicker1.OurCart = self;
	RightPicker2.OurCart = self;
	
	// Attach the picker meshes
	Mesh.AttachComponentToSocket(Picker1.SkeletalMeshComponent, 'Picker1Socket');
	Mesh.AttachComponentToSocket(Picker2.SkeletalMeshComponent, 'Picker2Socket');
	Mesh.AttachComponentToSocket(Picker3.SkeletalMeshComponent, 'Picker3Socket');
	
	Mesh.AttachComponentToSocket(LeftPicker1.SkeletalMeshComponent, 'LeftPicker1Socket');
	Mesh.AttachComponentToSocket(LeftPicker2.SkeletalMeshComponent, 'LeftPicker2Socket');
	Mesh.AttachComponentToSocket(RightPicker1.SkeletalMeshComponent, 'RightPicker1Socket');
	Mesh.AttachComponentToSocket(RightPicker2.SkeletalMeshComponent, 'RightPicker2Socket');

	ForEach WorldInfo.AllActors(class'CameraActor', C)
	{
		GroundCam = C;
	}	
	
	// Tell the gameinfo who we are
	CartGameInfo(WorldInfo.Game).TheCart = self;
	
	super.PostBeginPlay();
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	// Collect all our skeletal mesh controls
	PickerFrameControl = SkelControlSingleBone(Mesh.FindSkelControl('PickerFrame_cont'));
	PickerSteerControl = SkelControlSingleBone(Mesh.FindSkelControl('PickerFrameSteer_cont'));
	PickerWheelControl = SkelControlSingleBone(Mesh.FindSkelControl('PickerFrameWheel_cont'));
	SteeringControl = SkelControlSingleBone(Mesh.FindSkelControl('SWheel_cont'));
	
	LeftPickerFrameControl = SkelControlSingleBone(Mesh.FindSkelControl('LeftPickerFrame_cont'));
	LeftPickerSteerControl = SkelControlSingleBone(Mesh.FindSkelControl('LeftPickerFrameSteer_cont'));
	LeftPickerWheelControl = SkelControlSingleBone(Mesh.FindSkelControl('LeftPickerFrameWheel_cont'));	
	
	RightPickerFrameControl = SkelControlSingleBone(Mesh.FindSkelControl('RightPickerFrame_cont'));
	RightPickerSteerControl = SkelControlSingleBone(Mesh.FindSkelControl('RightPickerFrameSteer_cont'));
	RightPickerWheelControl = SkelControlSingleBone(Mesh.FindSkelControl('RightPickerFrameWheel_cont'));	
	
	super.PostInitAnimTree(SkelComp);
}

function Tick(float DeltaTime)
{
	local actor HitActor;
	local vector TraceStart, TraceEnd, HitLocation, HitNormal, Picker1Loc, Picker2Loc, Picker3Loc, LeftPicker1Loc, LeftPicker2Loc, RightPicker1Loc, RightPicker2Loc;
	local float TempFloat;
	local rotator PickerFrameAngle, PickerRot;

	//
	// Front
	//
	// Adjust front picker rotation
	// Do a trace straight down and see if we hit the world
	Mesh.GetSocketWorldLocationAndRotation('PickerFrameTraceSocket', TraceStart);
	TraceStart += vect(0,0,80);
	TraceEnd = TraceStart;
	TraceEnd += vect(0,0,-160) >> Rotation;
	
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	
	if (HitActor != none && HitActor.bWorldGeometry)
	{
		// Hit something, do trig
		TempFloat = TraceEnd.Z - HitLocation.Z;
		PickerFrameAngle.Pitch = atan(TempFloat / 300) * RadToUnrRot;
		
		PickerFrameControl.BoneRotation.Pitch = PickerFrameAngle.Pitch * -1;
	}
	else
	{
		PickerFrameControl.BoneRotation.Pitch = 0;
	}
	
	// Steer the picker frame wheel
	// Multiply by our current ground speed, as we only want the wheels to steer while we're in motion
	PickerSteerControl.BoneRotation.Roll = Wheels[2].Steer * DegToUnrRot * 3 * (VSize(Velocity) / GroundSpeed);
	// Rotate the picker frame wheel
	PickerWheelControl.BoneRotation.Roll = Wheels[2].CurrentRotation * DegToUnrRot * -1 * (VSize(Velocity) / GroundSpeed);

	//
	// Left
	//
	// Adjust left picker rotation
	Mesh.GetSocketWorldLocationAndRotation('LeftPickerTraceSocket', TraceStart);
	TraceStart += vect(0,0,80);
	TraceEnd = TraceStart;
	TraceEnd += vect(0,0,-160) >> Rotation;
	
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	
	if (HitActor != none && HitActor.bWorldGeometry)
	{
		// Hit something, do trig
		TempFloat = TraceEnd.Z - HitLocation.Z;
		PickerFrameAngle.Pitch = atan(TempFloat / 370) * RadToUnrRot;
		
		LeftPickerFrameControl.BoneRotation.Pitch = PickerFrameAngle.Pitch;
	}
	else
	{
		LeftPickerFrameControl.BoneRotation.Pitch = 0;
	}

	// Steer the picker frame wheel
	LeftPickerSteerControl.BoneRotation.Roll = Wheels[2].Steer * DegToUnrRot * 3 * (VSize(Velocity) / GroundSpeed);
	// Rotate the picker frame wheel
	LeftPickerWheelControl.BoneRotation.Roll = Wheels[2].CurrentRotation * DegToUnrRot * -1;

	//
	// Right
	//
	Mesh.GetSocketWorldLocationAndRotation('RightPickerTraceSocket', TraceStart);
	TraceStart += vect(0,0,80);
	TraceEnd = TraceStart;
	TraceEnd += vect(0,0,-160) >> Rotation;
	
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	
	if (HitActor != none && HitActor.bWorldGeometry)
	{
		// Hit something, do trig
		TempFloat = TraceEnd.Z - HitLocation.Z;
		PickerFrameAngle.Pitch = atan(TempFloat / 370) * RadToUnrRot;
		
		RightPickerFrameControl.BoneRotation.Pitch = PickerFrameAngle.Pitch * -1;
	}
	else
	{
		RightPickerFrameControl.BoneRotation.Pitch = 0;
	}

	// Steer the picker frame wheel
	RightPickerSteerControl.BoneRotation.Roll = Wheels[3].Steer * DegToUnrRot * 3 * (VSize(Velocity) / GroundSpeed);
	// Rotate the picker frame wheel
	RightPickerWheelControl.BoneRotation.Roll = Wheels[3].CurrentRotation * DegToUnrRot * -1;	
	
	//
	//	Picker Meshes
	//
	// Rotate the picker mesh bodies
	PickerDesiredSteer = Wheels[3].Steer * DegToUnrRot * 2 * -1;
	if (PickerSteer != PickerDesiredSteer)
	{
		PickerSteer = Lerp(PickerDesiredSteer, PickerSteer, 0.01);
	}

	// The pickers steer slightly different to simulate their positioning on the vehicle
	Picker1.RotateControl.BoneRotation.Pitch = PickerSteer * (VSize(Velocity) / GroundSpeed);
	Picker2.RotateControl.BoneRotation.Pitch = PickerSteer * 1.5 * (VSize(Velocity) / GroundSpeed);
	Picker3.RotateControl.BoneRotation.Pitch = PickerSteer * (VSize(Velocity) / GroundSpeed);

	LeftPicker1.RotateControl.BoneRotation.Pitch = PickerSteer * 0.75 * (VSize(Velocity) / GroundSpeed);
	LeftPicker2.RotateControl.BoneRotation.Pitch = PickerSteer * (VSize(Velocity) / GroundSpeed);

	RightPicker1.RotateControl.BoneRotation.Pitch = PickerSteer * 0.75 * (VSize(Velocity) / GroundSpeed);
	RightPicker2.RotateControl.BoneRotation.Pitch = PickerSteer * (VSize(Velocity) / GroundSpeed);
	
	// Check ground clearance for the pickers
	// This rotates the pickers to keep their collection drum on the ground properly
	//Picker 1
	Mesh.GetSocketWorldLocationAndRotation('Picker1TraceSocket', TraceStart, PickerRot);
	PickerRot.Yaw -= 16384;
	TraceStart += vect(0,0,16);
	TraceEnd = TraceStart;
	TraceEnd += vect(0,0,-32) >> PickerRot;
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	if (HitActor != none && HitActor.bWorldGeometry)
	{
		TempFloat = TraceEnd.Z - HitLocation.Z;
		Picker1.RotateControl.BoneRotation.Yaw = (atan(TempFloat / 66) * RadToUnrRot * -1);
		PickerRot = Rotator((HitLocation + HitNormal) - HitLocation);
		Picker1.RotateControl.BoneRotation.Roll = PickerRot.Roll;
	}
	else
	{
		PickerFrameControl.BoneRotation.Yaw = 0;
	}

	//Picker 2
	Mesh.GetSocketWorldLocationAndRotation('Picker2TraceSocket', TraceStart, PickerRot);
	PickerRot.Yaw -= 16384;
	TraceStart += vect(0,0,16);
	TraceEnd = TraceStart;
	TraceEnd += vect(0,0,-32) >> PickerRot;
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	if (HitActor != none && HitActor.bWorldGeometry)
	{
		TempFloat = TraceEnd.Z - HitLocation.Z;
		Picker2.RotateControl.BoneRotation.Yaw = (atan(TempFloat / 66) * RadToUnrRot * -1);
	}
	else
	{
		Picker2.RotateControl.BoneRotation.Yaw = 0;
	}
	
	//Picker 3
	Mesh.GetSocketWorldLocationAndRotation('Picker3TraceSocket', TraceStart, PickerRot);

	PickerRot.Yaw -= 16384;
	TraceStart += vect(0,0,16);
	TraceEnd = TraceStart;
	TraceEnd += vect(0,0,-32) >> PickerRot;
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	
	if (HitActor != none && HitActor.bWorldGeometry)
	{
		TempFloat = TraceEnd.Z - HitLocation.Z;
		Picker3.RotateControl.BoneRotation.Yaw = (atan(TempFloat / 66) * RadToUnrRot * -1);
	}
	else
	{
		Picker3.RotateControl.BoneRotation.Yaw = 0;
	}
	
	// Left Picker 1
	Mesh.GetSocketWorldLocationAndRotation('LeftPicker1TraceSocket', TraceStart, PickerRot);

	PickerRot.Yaw -= 16384;
	TraceStart += vect(0,0,16);
	TraceEnd = TraceStart;
	TraceEnd += vect(0,0,-32) >> PickerRot;
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	
	if (HitActor != none && HitActor.bWorldGeometry)
	{
		TempFloat = TraceEnd.Z - HitLocation.Z;
		LeftPicker1.RotateControl.BoneRotation.Yaw = (atan(TempFloat / 66) * RadToUnrRot * -1);
	}
	else
	{
		LeftPicker1.RotateControl.BoneRotation.Yaw = 0;
	}
	
	// Left Picker 2
	Mesh.GetSocketWorldLocationAndRotation('LeftPicker2TraceSocket', TraceStart, PickerRot);

	PickerRot.Yaw -= 16384;
	TraceStart += vect(0,0,16);
	TraceEnd = TraceStart;
	TraceEnd += vect(0,0,-32) >> PickerRot;
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	
	if (HitActor != none && HitActor.bWorldGeometry)
	{
		TempFloat = TraceEnd.Z - HitLocation.Z;
		LeftPicker2.RotateControl.BoneRotation.Yaw = (atan(TempFloat / 66) * RadToUnrRot * -1);
	}
	else
	{
		LeftPicker2.RotateControl.BoneRotation.Yaw = 0;
	}
	
	// Right Picker 1
	Mesh.GetSocketWorldLocationAndRotation('RightPicker1TraceSocket', TraceStart, PickerRot);

	PickerRot.Yaw -= 16384;
	TraceStart += vect(0,0,16);
	TraceEnd = TraceStart;
	TraceEnd += vect(0,0,-32) >> PickerRot;
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	
	if (HitActor != none && HitActor.bWorldGeometry)
	{
		TempFloat = TraceEnd.Z - HitLocation.Z;
		RightPicker1.RotateControl.BoneRotation.Yaw = (atan(TempFloat / 66) * RadToUnrRot * -1);
	}
	else
	{
		RightPicker1.RotateControl.BoneRotation.Yaw = 0;
	}
	
	// Right Picker 2
	Mesh.GetSocketWorldLocationAndRotation('RightPicker2TraceSocket', TraceStart, PickerRot);

	PickerRot.Yaw -= 16384;
	TraceStart += vect(0,0,16);
	TraceEnd = TraceStart;
	TraceEnd += vect(0,0,-32) >> PickerRot;
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	
	if (HitActor != none && HitActor.bWorldGeometry)
	{
		TempFloat = TraceEnd.Z - HitLocation.Z;
		RightPicker2.RotateControl.BoneRotation.Yaw = (atan(TempFloat / 66) * RadToUnrRot * -1);
	}
	else
	{
		RightPicker2.RotateControl.BoneRotation.Yaw = 0;
	}
	
	// Make sure picker actors are in the right places
	// This keeps their collision cylinders where they should be to pick up golf balls
	Mesh.GetSocketWorldLocationAndRotation('Picker1Socket', Picker1Loc, PickerRot);	
	Mesh.GetSocketWorldLocationAndRotation('Picker2Socket', Picker2Loc);	
	Mesh.GetSocketWorldLocationAndRotation('Picker3Socket', Picker3Loc);
	Mesh.GetSocketWorldLocationAndRotation('LeftPicker1Socket', LeftPicker1Loc);
	Mesh.GetSocketWorldLocationAndRotation('LeftPicker2Socket', LeftPicker2Loc);	
	Mesh.GetSocketWorldLocationAndRotation('RightPicker1Socket', RightPicker1Loc);
	Mesh.GetSocketWorldLocationAndRotation('RightPicker2Socket', RightPicker2Loc);
	
	Picker1.SetLocation(Picker1Loc);
	Picker1.SetRotation(PickerRot);
	Picker2.SetLocation(Picker2Loc);
	Picker2.SetRotation(PickerRot);
	Picker3.SetLocation(Picker3Loc);
	Picker3.SetRotation(PickerRot);
	
	LeftPicker1.SetLocation(LeftPicker1Loc);
	LeftPicker1.SetRotation(PickerRot);
	LeftPicker2.SetLocation(LeftPicker2Loc);
	LeftPicker2.SetRotation(PickerRot);
	
	RightPicker1.SetLocation(RightPicker1Loc);
	RightPicker1.SetRotation(PickerRot);
	RightPicker2.SetLocation(RightPicker2Loc);
	RightPicker2.SetRotation(PickerRot);
	
	// Set steering wheel
	SteeringControl.BoneRotation.Roll = (Wheels[2].Steer * -1) * 3 * DegToUnrRot;
	
	// Make our engine sound change. Not done by default, so let's force things.
	if (EngineSound != None)
	{
		EngineSound.SetFloatParameter('EnginePitchParam', VSize(Velocity));
	}	
	
	super.Tick(DeltaTime);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CartCustomerPawn(Other) != none)
	{
		// Fucking cart ran us over
		Pawn(Other).Died(Controller, class'DamageType', Location);
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

simulated function bool CalcCamera( float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV )
{
	local vector Pos, HitLocation, HitNormal, FirstPersonCameraLoc;
	
	if (CartGameInfo(WorldInfo.Game).CameraMode == 0)	// Standard first-person view. Set our camera to the driver camera socket location
	{
		GetActorEyesViewPoint( out_CamLoc, out_CamRot );
		Mesh.GetSocketWorldLocationAndRotation('CameraSocket', FirstPersonCameraLoc);	
		
		out_CamLoc = FirstPersonCameraLoc;
		out_CamRot += self.Rotation;
		out_FOV = CamOneFOV;
		
	} 
	else if (CartGameInfo(WorldInfo.Game).CameraMode == 1)
	{
		// Simple third person view implementation
		GetActorEyesViewPoint( out_CamLoc, out_CamRot );

		out_CamLoc += BaseOffset;
		Pos = out_CamLoc - Vector(out_CamRot) * CamTwoDistance;
		if( Trace(HitLocation, HitNormal, Pos, out_CamLoc, false, vect(0,0,0)) != None )
		{
			out_CamLoc = HitLocation + HitNormal*2;
		}
		else
		{
			out_CamLoc = Pos;
		}
	}
	else if (CartGameInfo(WorldInfo.Game).CameraMode == 2)
	{
		out_CamLoc = GroundCam.Location;
		out_CamRot = Rotator(Normal(self.Location - GroundCam.Location));
	}
	return true;
}

simulated event RigidBodyCollision (PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent, const out Actor.CollisionImpactData Collision, int ContactIndex)
{
	`log("Cart RB impact with " $OtherComponent.Owner$ " - Velocity: " $VSize(Collision.ContactInfos[0].ContactVelocity[0]));
	if (CartGolfBall(OtherComponent.Owner) != none)
	{
		if (VSize(Collision.ContactInfos[0].ContactVelocity[0]) > 64 && CanCollide)
		{
			CanCollide = false;
			SetTimer(0.5, false, 'SetCanCollide');
			// We got hit by a golf ball. Probably.
		}
	}
	
	super.RigidBodyCollision(HitComponent, OtherComponent, Collision, ContactIndex);
}

function SetCanCollide()
{
	CanCollide = true;
}

function EmptyPickers()
{
	// Function tells each picker attached to reset count, this will also clear the balls displayed in the baskets
	Picker1.BallsCollected = 0;
	Picker2.BallsCollected = 0;
	Picker3.BallsCollected = 0;
	
	LeftPicker1.BallsCollected = 0;
	LeftPicker2.BallsCollected = 0;
	
	RightPicker1.BallsCollected = 0;
	RightPicker2.BallsCollected = 0;
}

simulated function StartFire(byte FireModeNum)
{
	if (WorldInfo.Game.bGameEnded)
	{
		CartGameInfo(WorldInfo.Game).TriggerRemoteKismetEvent('Quit');
	}
}

defaultproperties
{
	Health=300
	CamOneFOV = 100
	CamTwoDistance = 512

	COMOffset=(x=32.0,y=0.0,z=0.0)
	UprightLiftStrength=500.0
	UprightTime=1.25
	UprightTorqueStrength=500.0
	bCanFlip=true
	bHasHandbrake=false
	GroundSpeed=500
	AirSpeed=500
	HeavySuspensionShiftPercent=0.75f;
    MomentumMult=0.5f
	BaseOffset=(Z=64)
	CamDist=512
	bAttachDriver=false
	
	EnterVehicleSound = SoundCue'CartSounds.cart_start_Cue'
	ExitVehicleSound = SoundCue'CartSounds.cart_stop_Cue'
 
	Begin Object Class=AudioComponent Name=CartEngineSound
		SoundCue=SoundCue'CartSounds.cart_idle_Cue'
	End Object
	EngineSound=CartEngineSound
	Components.Add(CartEngineSound);
	
	EngineStartOffsetSecs = 0.2
	EngineStopOffsetSecs = 0
	
/*  Begin Object Name=CollisionCylinder
    BlockNonZeroExtent=false
    BlockZeroExtent=false
    BlockActors=false
    BlockRigidBody=false
    CollideActors=false
    CollisionHeight=96.f
    CollisionRadius=64.f
    Translation=(Z=45.f)
  End Object */
  
  Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
    bSynthesizeSHLight=true
    bIsCharacterLightEnvironment=false
    bUseBooleanEnvironmentShadowing=true
  End Object
  Components.Add(MyLightEnvironment)
  LightEnvironment=MyLightEnvironment
  
  Begin Object Name=SVehicleMesh
    CastShadow=true
    bCastDynamicShadow=true
    bOverrideAttachmentOwnerVisibility=true
    bAcceptsDynamicDecals=false
    bPerBoneMotionBlur=true
    LightEnvironment=MyLightEnvironment
	BlockRigidBody=true
	bNotifyRigidBodyCollision=true
    SkeletalMesh=SkeletalMesh'Cart.golfcart'
    AnimTreeTemplate=AnimTree'Cart.Cart_tree'
    PhysicsAsset=PhysicsAsset'Cart.Cart_physics'
  End Object

	// Do a wee bit of stayupright
	bStayUpright=true
	StayUprightRollResistAngle=70.0
	StayUprightPitchResistAngle=45.0
	StayUprightStiffness=50
	StayUprightDamping=5
	
	Begin Object Class=UDKVehicleSimCar Name=SimObject
		WheelSuspensionStiffness=8000.0
		WheelSuspensionDamping=20.0
		WheelSuspensionBias=0.0
		ChassisTorqueScale=0.0
		MaxBrakeTorque=5.0
		StopThreshold=100

		MaxSteerAngleCurve=(Points=((InVal=0,OutVal=30),(InVal=600.0,OutVal=20.0),(InVal=1100.0,OutVal=15.0),(InVal=1300.0,OutVal=10.0),(InVal=1600.0,OutVal=10.0)))
		SteerSpeed=80

		LSDFactor=0
		TorqueVSpeedCurve=(Points=((InVal=-600.0,OutVal=0.0),(InVal=-300.0,OutVal=80.0),(InVal=0.0,OutVal=130.0),(InVal=950.0,OutVal=130.0),(InVal=1050.0,OutVal=10.0),(InVal=1250.0,OutVal=0.0)))
		EngineRPMCurve=(Points=((InVal=-80.0,OutVal=2500.0),(InVal=0.0,OutVal=500.0),(InVal=130.0,OutVal=1500.0),(InVal=550.0,OutVal=2000.0),(InVal=849.0,OutVal=3500.0),(InVal=850.0,OutVal=4500.0),(InVal=1100.0,OutVal=5000.0)))
		EngineBrakeFactor=0.008
		ThrottleSpeed=5
		WheelInertia=0.2
		NumWheelsForFullSteering=2
		SteeringReductionFactor=0.0
		SteeringReductionMinSpeed=1100.0
		SteeringReductionSpeed=1400.0
		bAutoHandbrake=false
		bClampedFrictionModel=true
		FrontalCollisionGripFactor=0.18
		ConsoleHardTurnGripFactor=1.0
		HardTurnMotorTorque=0.7

		SpeedBasedTurnDamping=20.0
		AirControlTurnTorque=40.0
		InAirUprightMaxTorque=15.0
		InAirUprightTorqueFactor=-30.0

		// Longitudinal tire model based on 10% slip ratio peak
		WheelLongExtremumSlip=0.1
		WheelLongExtremumValue=1.0
		WheelLongAsymptoteSlip=2.0
		WheelLongAsymptoteValue=0.6

		// Lateral tire model based on slip angle (radians)
   		WheelLatExtremumSlip=0.35     // 20 degrees
		WheelLatExtremumValue=0.9
		WheelLatAsymptoteSlip=1.4     // 80 degrees
		WheelLatAsymptoteValue=0.9

		bAutoDrive=false
		AutoDriveSteer=0.3
	End Object
	SimObj=SimObject
	Components.Add(SimObject)

	Begin Object Class=CartVehicleWheel Name=CartRRWheel
		BoneName=rrwheel
		BoneOffset=(X=0.0,Y=16.0,Z=0.0)
		SkelControlName="rrwheel_cont"
	End Object
	Wheels(0)=CartRRWheel

	Begin Object Class=CartVehicleWheel Name=CartLRWheel
		BoneName=lrwheel
		BoneOffset=(X=0.0,Y=16.0,Z=0.0)
		SkelControlName="lrwheel_cont"
	End Object
	Wheels(1)=CartLRWheel

	Begin Object Class=CartVehicleWheel Name=CartRFWheel
		BoneName=rfwheel
		BoneOffset=(X=0.0,Y=16.0,Z=0.0)
		SteerFactor=1.0
		SkelControlName="rfwheel_cont"
	End Object
	Wheels(2)=CartRFWheel

	Begin Object Class=CartVehicleWheel Name=CartLFWheel
		BoneName=lfwheel
		BoneOffset=(X=0.0,Y=16.0,Z=0.0)
		SteerFactor=1.0
		SkelControlName="lfwheel_cont"
	End Object
	Wheels(3)=CartLFWheel

	HitSounds[0] = SoundCue'CartSounds.hitcart1_Cue'
	HitSounds[1] = SoundCue'CartSounds.hitcart2_Cue'
	HitSounds[2] = SoundCue'CartSounds.hitcart3_Cue'
	HitSounds[3] = SoundCue'CartSounds.hitcart4_Cue'
	HitSounds[4] = SoundCue'CartSounds.hitcart5_Cue'
}