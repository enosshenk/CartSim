class CartHUD extends HUD;

var string CartMessage;						// Message being displayed on screen
var float CartMessageTime;					// Time requested for the message to last

var float CartMessageTimeElapsed;			// Elapsed time message has been on screen
var bool CartMessageFading;					// True if we should be fading out the message
var float CartMessageAlpha;					// Current alpha of the message. Starts at 1

var bool FadingToBlack;						// True if we should be fading to black
var float FadingToBlackAlpha;				// Current alpha of the black screen. Starts at 0

var FontRenderInfo FontInfo;

var bool MenuOpen;

function CartSetMessage(float Time, string Message)
{
	CartMessage = Message;
	CartMessageTime = Time;
	CartMessageFading = false;
	CartMessageAlpha = 1;
	CartMessageTimeElapsed = 0;
}

function FadeToBlack()
{
	FadingToBlack = true;
}

function DrawHUD()
{
	local float TextX, TextY;
	
	if (MenuOpen)
	{
		if (FadingToBlack)
		{
			// We're fading in the black screen. Increase the alpha and keep displaying the tile.
			FadingToBlackAlpha += 0.01;
			if (FadingToBlackAlpha > 1)
				FadingToBlackAlpha = 1;
			Canvas.DrawTile(Texture2D'EngineResources.Black', Canvas.ClipX, Canvas.ClipY, 0, 0, Canvas.ClipX, Canvas.ClipY, MakeLinearColor(0,0,0,FadingToBlackAlpha));
		}
		
		// Player has pressed esc, show the halfass menu because fuck scaleform.
		Canvas.DrawColor = WhiteColor;
		Canvas.Font = Font'Cart.CartFont';
		
		Canvas.StrLen("Restart Level", TextX, TextY);
		Canvas.SetPos((Canvas.ClipX / 2) - (TextX / 2), Canvas.ClipY * 0.4);
		Canvas.DrawText("1: Restart Level");

		Canvas.StrLen("Quit Game", TextX, TextY);
		Canvas.SetPos((Canvas.ClipX / 2) - (TextX / 2), Canvas.ClipY * 0.5);
		Canvas.DrawText("2: Quit Game");		
		
	}
	else
	{
		// Do fade to black if desired
		if (FadingToBlack)
		{
			FadingToBlackAlpha += 0.01;
			if (FadingToBlackAlpha > 1)
				FadingToBlackAlpha = 1;
			Canvas.DrawTile(Texture2D'EngineResources.Black', Canvas.ClipX, Canvas.ClipY, 0, 0, Canvas.ClipX, Canvas.ClipY, MakeLinearColor(0,0,0,FadingToBlackAlpha));
		}
		else
		{	
			Canvas.DrawColor = WhiteColor;
			Canvas.Font = Font'Cart.CartFont2';

			// On cart background
			Canvas.SetPos(64, Canvas.ClipY * 0.05);
			Canvas.DrawTile(Texture2D'Cart.bubble_oncart', 160, 64, 0, 0, 160, 64);
			// On cart text
			Canvas.SetPos(162, Canvas.ClipY * 0.07);
			Canvas.DrawText(CartGameInfo(WorldInfo.Game).BallsOnCart);
			
			// On range background
			Canvas.SetPos(100, Canvas.ClipY * 0.15);
			Canvas.DrawTile(Texture2D'Cart.bubble_onrange', 128, 64, 0, 0, 128, 64);
			// On range text
			Canvas.SetPos(162, Canvas.ClipY * 0.17);
			Canvas.DrawText(CartGameInfo(WorldInfo.Game).BallsOnRange);
			
			// For sale background
			Canvas.SetPos(100, Canvas.ClipY * 0.25);
			Canvas.DrawTile(Texture2D'Cart.bubble_forsale', 128, 64, 0, 0, 128, 64);
			// For sale text
			Canvas.SetPos(162, Canvas.ClipY * 0.27);
			Canvas.DrawText(CartGameInfo(WorldInfo.Game).BallsForSale);
		}
		
		// Set font info
		FontInfo.bEnableShadow = true;
		
		// Do message stuff
		if (CartMessage != "")
		{
			if (!CartMessageFading)
			{
				CartMessageTimeElapsed += RenderDelta;
				CartMessageAlpha = 1;
				
				if (CartMessageTimeElapsed >= CartMessageTime)
				{
					CartMessageFading = true;
				}
			}
			else
			{
				CartMessageAlpha -= 0.1;
				
				if (CartMessageAlpha <= 0)
				{
					CartMessage = "";
					CartMessageTimeElapsed = 0;
				}
			}
			Canvas.Font = Font'Cart.CartFont2';
			Canvas.StrLen(CartMessage, TextX, TextY);
			Canvas.SetPos((Canvas.ClipX / 2) - (TextX / 2), Canvas.ClipY * 0.3);

			Canvas.DrawColor = MakeColor(255, 255, 255, 255 * CartMessageAlpha);
			Canvas.DrawText(CartMessage, , , , FontInfo);
		}
	}
	super.DrawHUD();
}
