class CartPlayerController extends PlayerController;

var bool CartMenuOpen;

reliable client function ClientSetHUD(class<HUD> newHUDType)
{
	super.ClientSetHUD(newHUDType);
	`log(newHUDType);
}

exec function ToggleCamera()
{
	if (CartGameInfo(WorldInfo.Game).CameraMode == 0)
	{
		CartGameInfo(WorldInfo.Game).CameraMode = 1;
	}
	else
	{
		CartGameInfo(WorldInfo.Game).CameraMode = 0;
	}
}

exec function CartCamOne()
{
	if (!CartMenuOpen)
	{
		CartGameInfo(WorldInfo.Game).CameraMode = 0;
	}
	else
	{
		CartGameInfo(WorldInfo.Game).TriggerRemoteKismetEvent('Restart');
	}
}

exec function CartCamTwo()
{
	if (!CartMenuOpen)
	{
		CartGameInfo(WorldInfo.Game).CameraMode = 1;
	}
	else
	{
		CartGameInfo(WorldInfo.Game).TriggerRemoteKismetEvent('Quit');
	}
}

exec function CartCamThree()
{
	CartGameInfo(WorldInfo.Game).CameraMode = 2;
}

exec function CartZoomIn()
{
	if (CartVehicle(Pawn) != none)
	{
		if (CartGameInfo(WorldInfo.Game).CameraMode == 0)
		{
			CartVehicle(Pawn).CamOneFOV -= 1;
			if (CartVehicle(Pawn).CamOneFOV < 45)
				CartVehicle(Pawn).CamOneFOV = 45;
		}
		else if (CartGameInfo(WorldInfo.Game).CameraMode == 1)
		{
			CartVehicle(Pawn).CamTwoDistance -= 20;
			if (CartVehicle(Pawn).CamTwoDistance < 384)
				CartVehicle(Pawn).CamTwoDistance = 384;
		}
	}
}

exec function CartZoomOut()
{
	if (CartVehicle(Pawn) != none)
	{
		if (CartGameInfo(WorldInfo.Game).CameraMode == 0)
		{
			CartVehicle(Pawn).CamOneFOV += 1;
			if (CartVehicle(Pawn).CamOneFOV > 150)
				CartVehicle(Pawn).CamOneFOV = 150;
		}
		else if (CartGameInfo(WorldInfo.Game).CameraMode == 1)
		{
			CartVehicle(Pawn).CamTwoDistance += 20;
			if (CartVehicle(Pawn).CamTwoDistance > 2048)
				CartVehicle(Pawn).CamTwoDistance = 2048;
		}
	}
}

exec function CartMessage(float Time, string Message)
{
	CartHUD(myHUD).CartMessage = Message;
	CartHUD(myHUD).CartMessageTime = Time;
	CartHUD(myHUD).CartMessageFading = false;
	CartHUD(myHUD).CartMessageAlpha = 1;
	CartHUD(myHUD).CartMessageTimeElapsed = 0;
}

exec function CartFadeToBlack()
{
	CartHUD(myHUD).FadeToBlack();
}

exec function CartMenu()
{
	if (CartMenuOpen)
	{
		CartMenuOpen = false;
		CartHUD(myHUD).MenuOpen = false;
	}
	else
	{
		CartMenuOpen = true;
		CartHUD(myHUD).MenuOpen = true;
	}
}
