class CartGameInfo extends UDKGame;

var int CameraMode;						// Camera mode the vehicle is viewed with
var int BallsForSale;					// Balls available for sale. Customers take from them when they spawn.
var int BallsOnRange;					// Number of balls out on the range somewhere
var int BallsOnCart;					// Number of balls carried on the cart
var float CustomerTimeScalar;			// A scalar value used to speed up the customer arrival over time
var bool CartOnRange;					// True if the cart is on the range for customers to aim at
var CartVehicle TheCart;				// Ref to the cart
var CartHUD CartHUD;					// Ref to the HUD
var array<string> DeathMessages;		// Array of strings shown when the cart runs over a customer
var array<string> FutilityMessages;		// Array of strings shown when the player loses the game
var DoorMarker SpawnLoc;				// Location to spawn customers

event PostLogin( PlayerController NewPlayer )
{
	// Fill HUD reference
	CartHUD = CartHUD(NewPlayer.myHUD);
	
	super.PostLogin(NewPlayer);
}

function EndGameKilled()
{
	// Delay a few seconds before fading out and ending the game
	SetTimer(2, false, 'DoEndGameKilled');
}

function DoEndGameKilled()
{
	// Tell the HUD to fade in the black screen and display a failure message
	CartPlayerController(GetALocalPlayerController()).CartFadeToBlack();
	CartPlayerController(GetALocalPlayerController()).CartMessage(30, DeathMessages[Rand(DeathMessages.Length)]);
	bGameEnded = true;
}	

function EndGameFailed()
{
	SetTimer(2, false, 'DoEndGameFailed');
}

function DoEndGameFailed()
{
	CartPlayerController(GetALocalPlayerController()).CartFadeToBlack();
	CartPlayerController(GetALocalPlayerController()).CartMessage(30, FutilityMessages[Rand(FutilityMessages.Length)]);
	bGameEnded = true;
}	

function CartTick()
{
	// Function handles spawning a customer, adjusting the ball counter, and handling failure condition
	local int BallsDesired;
	local CartCustomerPawn Customer;
	
	BallsDesired = 50 + rand(50);
	
	if (BallsForSale - BallsDesired < 0)
	{
		// The customer wants more balls than are for sale. End the game.
		EndGameFailed();
	}
	else
	{
		// Sell some balls
		BallsForSale -= BallsDesired;
		// Requeue the timer
		SetTimer(40 + Rand(30 * CustomerTimeScalar), false, 'CartTick');
		// Adjust the customer time scalar to make the next customer arrive sooner
		CustomerTimeScalar -= 0.07;
		// Display a HUD message
		CartPlayerController(GetALocalPlayerController()).CartMessage(10, "A new customer arrives and buys some balls.");
		// Spawn in the customer pawn
		Customer = Spawn(class'CartCustomerPawn', self, , SpawnLoc.Location, SpawnLoc.Rotation);
	}
}

function TriggerRemoteKismetEvent(name EventName)
{
	local array<SequenceObject> AllSeqEvents;
	local Sequence GameSeq;
	local int i;

	GameSeq = WorldInfo.GetGameSequence();
	if (GameSeq != None)
	{
		// reset the game sequence
		GameSeq.Reset();

		// find any Level Reset events that exist
		GameSeq.FindSeqObjectsByClass(class'SeqEvent_RemoteEvent', true, AllSeqEvents);

		// activate them
		for (i = 0; i < AllSeqEvents.Length; i++)
		{
			if(SeqEvent_RemoteEvent(AllSeqEvents[i]).EventName == EventName)
				SeqEvent_RemoteEvent(AllSeqEvents[i]).CheckActivate(WorldInfo, None);
		}
	}
}

function RestartPlayer(Controller NewPlayer)
{
  local NavigationPoint StartSpot;
  local int Idx;
  local array<SequenceObject> Events;
  local SeqEvent_PlayerSpawned SpawnedEvent;
  local Vehicle Vehicle;
	local DoorMarker S;
	
  if (bRestartLevel && WorldInfo.NetMode!= NM_DedicatedServer && WorldInfo.NetMode!= NM_ListenServer)
  {
    return;
  }

  StartSpot = FindPlayerStart(NewPlayer, 255);

  if (StartSpot == None)
  {
    if (NewPlayer.StartSpot != None)
    {
      StartSpot = NewPlayer.StartSpot;
    }
    else
    {
      return;
    }
  }

  if (NewPlayer.Pawn == None)
  {
    NewPlayer.Pawn = Spawn(DefaultPawnClass,,, StartSpot.Location, StartSpot.Rotation);
  }

  if (NewPlayer.Pawn == None)
  {
    NewPlayer.GotoState('Dead');

    if (PlayerController(NewPlayer) != None)
    {
      PlayerController(NewPlayer).ClientGotoState('Dead', 'Begin');
    }
  }
  else
  {
    NewPlayer.Pawn.SetAnchor(StartSpot);

    if (PlayerController(NewPlayer) != None)
    {
      PlayerController(NewPlayer).TimeMargin = -0.1;
      StartSpot.AnchoredPawn = None;
    }

    NewPlayer.Pawn.LastStartSpot = PlayerStart(StartSpot);
    NewPlayer.Pawn.LastStartTime = WorldInfo.TimeSeconds;
    NewPlayer.Possess(NewPlayer.Pawn, false);
    NewPlayer.ClientSetRotation(NewPlayer.Pawn.Rotation, true);

    SetPlayerDefaults(NewPlayer.Pawn);

    if (WorldInfo.GetGameSequence() != None)
    {
      WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_PlayerSpawned', true, Events);

      for (Idx = 0; Idx < Events.Length; Idx++)
      {
        SpawnedEvent = SeqEvent_PlayerSpawned(Events[Idx]);

        if (SpawnedEvent != None && SpawnedEvent.CheckActivate(NewPlayer,NewPlayer))
        {
          SpawnedEvent.SpawnPoint = startSpot;
          SpawnedEvent.PopulateLinkedVariableValues();
        }
      }
    }

    NewPlayer.Pawn.SetCollision(false, false, false);
    Vehicle = Spawn(class'CartVehicle',,, StartSpot.Location, StartSpot.Rotation);

    if (Vehicle != None)
    {
      Vehicle.TryToDrive(NewPlayer.Pawn);
    }
	
	SetTimer(60 + Rand(40), false, 'CartTick');
//	SetTimer(10, false, 'CartTick');
	ForEach WorldInfo.AllActors(class'DoorMarker', S)
	{
		SpawnLoc = S;
	}
  }
}

defaultproperties
{
	CameraMode = 0
	BallsForSale = 1000
	CustomerTimeScalar = 1
	
	HUDType=class'CartGame.CartHUD'
	PlayerControllerClass=class'CartGame.CartPlayerController'
	DefaultPawnClass=class'CartGame.CartPawn'
	bDelayedStart=false
	
	DeathMessages(0) = "A man who won't die for something is not fit to live. -- Martin Luther King Jr."
	DeathMessages(1) = "Our dead are never dead to us, until we have forgotten them. -- George Eliot"
	DeathMessages(2) = "No one can confidently say that he will still be living tomorrow. -- Euripides"
	DeathMessages(3) = "Man always dies before he is fully born. -- Erich Fromm"
	DeathMessages(4) = "Because of indifference, one dies before one actually dies. -- Elie Wiesel"
	DeathMessages(5) = "Call no man happy till he is dead. -- Aeschylus"
	DeathMessages(6) = "When faith is lost, when honor dies, the man is dead. -- John Greenleaf Whittier"
	DeathMessages(7) = "The valiant never taste of death but once. -- William Shakespeare"
	DeathMessages(8) = "One death is a tragedy; one million is a statistic. -- Josef Stalin"
	
	FutilityMessages(0) = "Life ... is a tale Told by an idiot, full of sound and fury, Signifying nothing. -- William Shakespeare"
	FutilityMessages(1) = "Man makes plans . . . and God laughs. -- Michael Chabon"
	FutilityMessages(2) = "I am somewhat exhausted; I wonder how a battery feels when it pours electricity into a non-conductor? -- Arthur Conan Doyle"
	FutilityMessages(3) = "Healey's First Law Of Holes: When in one, stop digging. -- Denis Healey"
	FutilityMessages(4) = "As a creature of free will, do not be tempted into futility. -- Vera Nazarian"
	FutilityMessages(5) = "Since all life is futility, then the decision to exist must be the most irrational of all. -- Emile M. Cioran"
	FutilityMessages(6) = "Those who cannot remember the past are condemned to repeat it without a sense of ironic futility. -- Errol Morris"
	FutilityMessages(7) = "Futility: playing a harp before a buffalo"
	FutilityMessages(8) = "I have measured out my life with coffee spoons. -- T.S. Eliot"
	FutilityMessages(9) = "It is the superfluous things for which men sweat. -- Seneca"
}