//
//	A simple volume subclass that keeps track if the cart is on the range or not.
//

class CartRangeVolume extends Volume
	placeable;

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CartVehicle(Other) != none)
	{
		CartGameInfo(WorldInfo.Game).CartOnRange = true;
		`log("Cart entering range");
	}
}

event untouch( Actor Other )
{
	if (CartVehicle(Other) != none)
	{
		CartGameInfo(WorldInfo.Game).CartOnRange = false;
		`log("Cart leaving range");
	}
}
