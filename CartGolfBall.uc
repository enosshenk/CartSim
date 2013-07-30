class CartGolfBall extends KActorSpawnable;

var bool DoCollision;

// Once upon a time there was a rigid body collision event here. But it was never triggering, so now it is gone.

function CheckCollision()
{
	DoCollision = true;
}

defaultproperties
{
	Begin Object Name=StaticMeshComponent0
		StaticMesh = StaticMesh'Cart.golfball'
		WireframeColor=(R=0,G=255,B=128,A=255)
		BlockRigidBody=true
		RBChannel=RBCC_GameplayPhysics
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE)
		bBlockFootPlacement=false
		bNotifyRigidBodyCollision=true
	End Object
}