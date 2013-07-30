class CartPawn extends Pawn;

// All we want is to check for fire button pressed when the game is over.
simulated function StartFire(byte FireModeNum)
{
	if (WorldInfo.Game.bGameEnded)
	{
		CartGameInfo(WorldInfo.Game).TriggerRemoteKismetEvent('Quit');
	}
}

defaultproperties
{
	MaxStepHeight = 32
	
	BaseEyeHeight=+00128.000000
	EyeHeight=+00128.000000
}