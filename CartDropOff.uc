//
//	Class used to clear the balls off the cart when touched. Handles telling the cart to clear balls, and notifies the gameinfo of the new ball count
//

class CartDropOff extends Actor
	placeable;

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CartVehicle(Other) != none && CartGameInfo(WorldInfo.Game).BallsOnCart > 0)
	{
		// Cart is dropping off balls
		// Append the balls for sale count with the amount carried on the cart
		CartGameInfo(WorldInfo.Game).BallsForSale += CartGameInfo(WorldInfo.Game).BallsOnCart;
		// Clear the cart ball counter
		CartGameInfo(WorldInfo.Game).BallsOnCart = 0;
		// Tell the cart to clear out the individual picker counts
		CartVehicle(Other).EmptyPickers();
		// Display a message on the HUD
		CartPlayerController(GetALocalPlayerController()).CartMessage(5, "You dropped off your load of golf balls");
	}
	
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}
	
defaultproperties
{
	bCollideActors = true
	CollisionType = COLLIDE_TouchAll
	
	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=128.000000
		CollisionHeight=128.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
	
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorMaterials.Tick'
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		bIsScreenSizeScaled=True
		ScreenSize=0.0025
		SpriteCategoryName="Effects"
	End Object
	Components.Add(Sprite)
}