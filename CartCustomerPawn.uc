class CartCustomerPawn extends Pawn;

var bool IsSwinging;							// True if we are in swinging timer
var array<MaterialInterface> BloodPuddle;		// Array of blood decals
var array<PathNode> HitLocations;				// Array of nodes to use as hitting stalls
var PathNode OurHitLocation;					// The hitting stall we randomly chose to use
var AnimNodeSlot PrioritySlot;					// AnimNodeSlot used for playing the hit animation
var TargetPoint OurTee;							// Tee at our hitting stall to focus on
var array<SoundCue> HitSounds;					// Array of sounds to play when we hit the ball
var array<Texture2D> Skins;						// Random skins
var MaterialInstanceConstant SkinMatInst;		// MatInst for our skins

simulated event PostBeginPlay()
{	
	local PathNode P;
	
	// Iterate through all pathnodes and save unblocked ones to our array of hit locations
	ForEach WorldInfo.AllActors(class'PathNode', P)
	{
		if (!P.bBlocked)
		{
			HitLocations.AddItem(P);
		}
	}

	// Set up a matinst for our skin
	SkinMatInst = new(None) Class'MaterialInstanceConstant';
	SkinMatInst.SetParent(Mesh.GetMaterial(1));
	Mesh.SetMaterial(1, SkinMatInst);	
	
	// Choose a random skin and set it
	SkinMatInst.SetTextureParameterValue('Texture', Skins[Rand(Skins.Length)]);
	
	// Make sure our controller spawns. Function is not called by default with pawns spawned through code.
	SpawnDefaultController();
	
	super.PostBeginPlay();
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	// Fill our ref for our one-shot animnode
	PrioritySlot = AnimNodeSlot(Mesh.FindAnimNode('PrioritySlot'));
}

function ReadyToHit()
{
	// Start our ball hitting timer
	SetTimer(10 + Rand(10), false, 'HitABall');
}

function HitABall()
{
	// Play the animation and queue the next ball
	PrioritySlot.PlayCustomAnimByDuration('swing', 4.12, 0.1, 0.1, false, true);
	SetTimer(10 + Rand(10), false, 'HitABall');
}

function SpawnBall()
{
	local CartGolfBall Ball;
	local vector SpawnVector;
	local rotator SpawnRot;

	// Spawn in the ball class and set its properties
	Ball = Spawn(class'CartGolfBall', self, 'Golfball', OurTee.Location, OurHitLocation.Rotation, , true);	
	Ball.CheckCollision();
//	Ball.SetStaticMesh(StaticMesh'Cart.golfball');
	
	if (!CartGameInfo(WorldInfo.Game).CartOnRange)
	{
		// Cart is not on the range. Aim randomly downrange.
		// Start with a rotator based on our hitting stall
		SpawnRot = OurHitLocation.Rotation;
		// Bump up the pitch so we hit into the air
		SpawnRot.Pitch += 6000;
		// Convert it to a vector used for velocity
		SpawnVector = Normal(Vector(SpawnRot));
		// Add a bit of random error to the vector
		SpawnVector += VRand() * 0.3;
		// Use it to apply an impulse to the ball
		Ball.ApplyImpulse(SpawnVector, 2 + Rand(8), Ball.Location);
	}
	else
	{
		// Cart is on the range. We want to aim at it.
		// Start by building a rotator aimed from our ball to the cart
		SpawnRot = Rotator(CartGameInfo(WorldInfo.Game).TheCart.Location - Ball.Location);
		// Bump up the pitch a bit
		SpawnRot.Pitch += 4000;
		// Convert it to a vector
		SpawnVector = Normal(Vector(SpawnRot));
		// Whack the ball
		Ball.ApplyImpulse(SpawnVector, 2 + Rand(8), Ball.Location);
		`log("Cart " $CartGameInfo(WorldInfo.Game).TheCart$ " is at " $CartGameInfo(WorldInfo.Game).TheCart.Location);
	}
	
	// Play sound
	PlaySound(HitSounds[Rand(HitSounds.Length)]);
	
	// Tell the gameinfo another ball is on the range
	CartGameInfo(WorldInfo.Game).BallsOnRange += 1;
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if ((CartVehicle(Other) != none || CartPicker(Other) != none) && Health > 0)
	{
		// Fucking cart ran us over
		Health = 0;
		self.Died(Controller, class'DamageType', Location);
		CartGameInfo(WorldInfo.Game).EndGameKilled();
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local vector TempVector;
	
	SetPhysics(PHYS_Falling);

	TempVector.Z = -128;
	// Spawn a blood decal where we got run over
	WorldInfo.MyDecalManager.SpawnDecal(BloodPuddle[rand(2)], Location, Rotator(TempVector), 128 + rand(128), 128 + rand(128), 128, true, , , , , , , , 30);
	
	return super.Died(Killer, DamageType, HitLocation);
}

simulated function SetDyingPhysics()
{
	// Used to make sure we get into a ragdoll state
    Mesh.SetRBChannel(RBCC_Pawn);
    Mesh.SetRBCollidesWithChannel(RBCC_Default, true);
    Mesh.SetRBCollidesWithChannel(RBCC_Pawn, false);
    Mesh.SetRBCollidesWithChannel(RBCC_Vehicle, false);
    Mesh.SetRBCollidesWithChannel(RBCC_Untitled3, false);
    Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume, true);
	self.InitRagdoll();
}

defaultproperties
{
	ControllerClass = class'CartAIController_Customer'
	
	Health = 100
	GroundSpeed = 200
	MaxStepHeight = 32
	Physics=PHYS_Walking
	WalkingPhysics=PHYS_Walking
	bCollideActors=true
	CollisionType=COLLIDE_TouchAll
	bCollideWorld=true
	bBlockActors=false
	LandMovementState=PlayerWalking

	BaseEyeHeight=+00128.000000
	EyeHeight=+00128.000000
	
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0048.000000
		CollisionHeight=+0160.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
	
  Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
    bSynthesizeSHLight=true
    bIsCharacterLightEnvironment=false
    bUseBooleanEnvironmentShadowing=true
  End Object
  Components.Add(MyLightEnvironment)
//  LightEnvironment=MyLightEnvironment
  
	Begin Object Class=SkeletalMeshComponent Name=CartPawnSkeletalMeshComponent
		SkeletalMesh = SkeletalMesh'Cart.man'
		AnimTreeTemplate = AnimTree'Cart.man_tree'
		AnimSets(0) = AnimSet'Cart.man_anim'
		PhysicsAsset = PhysicsAsset'Cart.man_Physics'
		CastShadow=true
		bCastDynamicShadow=true
		bOwnerNoSee=false
        BlockRigidBody=true
        CollideActors=true
        BlockZeroExtent=true
		BlockNonZeroExtent=true
		bIgnoreControllersWhenNotRendered=TRUE
		bUpdateSkelWhenNotRendered=FALSE
		bHasPhysicsAssetInstance=true
		LightEnvironment=MyLightEnvironment
	End Object
	Mesh=CartPawnSkeletalMeshComponent
	Components.Add(CartPawnSkeletalMeshComponent) 
	
	BloodPuddle[0] = Material'Cart.blood1_mat'
	BloodPuddle[1] = Material'Cart.blood2_mat'
	
	HitSounds[0] = SoundCue'CartSounds.hit1_Cue'
	HitSounds[1] = SoundCue'CartSounds.hit2_Cue'
	HitSounds[2] = SoundCue'CartSounds.hit3_Cue'
	HitSounds[3] = SoundCue'CartSounds.hit4_Cue'
	
	Skins[0] = Texture2D'Cart.generic_male01_d'
	Skins[1] = Texture2D'Cart.generic_male01_altpants'
	Skins[2] = Texture2D'Cart.generic_male01_altshirt'
	Skins[3] = Texture2D'Cart.generic_male01_altpantshirt'
}