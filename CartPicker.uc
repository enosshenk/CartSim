//
// Class handles displaying the picker skeletal mesh, handles touch events with golf balls, displays golf balls in the basket
//

class CartPicker extends SkeletalMeshActorMAT;

var SkelControlSingleBone RotateControl, Balls1Control, Balls2Control, Balls3Control;
var	CylinderComponent CylinderComponent;
var CartVehicle OurCart;
var int BallsCollected;
var array<SoundCue> LoadSounds;

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	// Get references to all of our skelcontrols
	RotateControl = SkelControlSingleBone(SkelComp.FindSkelControl('PickerRotate_cont'));
	Balls1Control = SkelControlSingleBone(SkelComp.FindSkelControl('Balls1_cont'));
	Balls2Control = SkelControlSingleBone(SkelComp.FindSkelControl('Balls2_cont'));
	Balls3Control = SkelControlSingleBone(SkelComp.FindSkelControl('Balls3_cont'));
	
	// Start a tick to check our ball status
	SetTimer(2, true, 'PickerTick');
	
	super.PostInitAnimTree(SkelComp);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (Other.Tag == 'Golfball')
	{
		// We touched a golf ball, see if we can carry more
		if (CartGameInfo(WorldInfo.Game).BallsOnCart < 250)
		{
			// Our hoppers aren't full, destroy the ball and update the count
			Other.Destroy();
			CartGameInfo(WorldInfo.Game).BallsOnCart += 1;
			CartGameInfo(WorldInfo.Game).BallsOnRange -= 1;
			BallsCollected += 1;
			PlaySound(LoadSounds[Rand(LoadSounds.Length)]);
		}
		else
		{
			// No more room!
			CartPlayerController(GetALocalPlayerController()).CartMessage(20, "Your hoppers are full, drop off the balls!");
		}
	}	
	
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

function PickerTick()
{
	// The picker has its own ball collected count. Based on it we show or hide 3 levels of balls in the basket.
	if (BallsCollected > 75)
	{
		// All balls on
		Balls1Control.BoneScale = 1.0;
		Balls2Control.BoneScale = 1.0;
		Balls3Control.BoneScale = 1.0;
	}
	else if (BallsCollected > 30 && BallsCollected < 75)
	{
		// 2 balls on
		Balls1Control.BoneScale = 1.0;
		Balls2Control.BoneScale = 1.0;
		Balls3Control.BoneScale = 0.0;
	}
	else if (BallsCollected > 5 && BallsCollected < 30)
	{
		// 1 ball on
		Balls1Control.BoneScale = 1.0;
		Balls2Control.BoneScale = 0.0;
		Balls3Control.BoneScale = 0.0;
	}
	else
	{
		// No balls on
		Balls1Control.BoneScale = 0.0;
		Balls2Control.BoneScale = 0.0;
		Balls3Control.BoneScale = 0.0;
	}
}

defaultproperties
{
	bStatic = false
	bNoDelete = false
	bCollideActors = true
	CollisionType = COLLIDE_TouchAll
	
	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=48.000000
		CollisionHeight=32.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
		Translation=(X=-48.f)
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
	
	Begin Object Name=SkeletalMeshComponent0
		CastShadow=true
		bCastDynamicShadow=true
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=false
		bPerBoneMotionBlur=true
		bUpdateSkelWhenNotRendered=true
		SkeletalMesh=SkeletalMesh'Cart.picker'
		AnimTreeTemplate=AnimTree'Cart.Picker_tree'
	End Object
	
	LoadSounds(0) = SoundCue'CartSounds.load1_Cue'
	LoadSounds(1) = SoundCue'CartSounds.load2_Cue'
	LoadSounds(2) = SoundCue'CartSounds.load3_Cue'
	LoadSounds(3) = SoundCue'CartSounds.load4_Cue'
	LoadSounds(4) = SoundCue'CartSounds.load5_Cue'
	LoadSounds(5) = SoundCue'CartSounds.load6_Cue'
	LoadSounds(6) = SoundCue'CartSounds.load7_Cue'
}