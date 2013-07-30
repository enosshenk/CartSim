//
// Class handles spawning golf balls to populate the range prior to play
//

class CartGolfBallSpawner extends Actor
	placeable;
	
var() int BallsToSpawn;				// Editor variable, sets the total amount of balls to spawn
var() float SpawnTimer;				// Delay between each ball spawn

var bool SpawningBalls;				// True if we're currently spewing golf balls
var int BallsSpawned;				// Count of how many we've spawned so far
var float SpawnTimeElapsed;			// How long we've been waiting for the next spawn
var vector SpawnVector;				// Vector used to kick the ball onto the range

simulated event PostBeginPlay()
{	
	SpawningBalls = true;
	
	super.PostBeginPlay();
}

function Tick(float DeltaTime)
{
	if (SpawningBalls)
	{
		SpawnTimeElapsed += DeltaTime;
		
		if (SpawnTimeElapsed > SpawnTimer)
		{
			if (BallsSpawned <= BallsToSpawn)
			{
				// Fun fact, it spawns an extra ball. Deal with it.
				SpawnABall();
				SpawnTimeElapsed = 0;
			}
			else
			{
				SpawningBalls = false;
			}
		}
	}
	
	super.Tick(DeltaTime);
}

function SpawnABall()
{
	local CartGolfBall Ball;
	
	CartGameInfo(WorldInfo.Game).BallsForSale -= 1;
	
	if (CartGameInfo(WorldInfo.Game).BallsForSale > 0)
	{
		// Make sure we have balls to spawn. This should never fail.
		// Spawn the ball and get a ref to it
		Ball = Spawn(class'CartGolfBall', self, 'Golfball', Location, Rotation, , true);	
		
		// Update the ball counts
		BallsSpawned += 1;
		CartGameInfo(WorldInfo.Game).BallsOnRange += 1;
	
		// Start with the rotation of the spawner converted to a vector
		SpawnVector = Normal(Vector(Rotation));
		// Add some random factor to the vector
		SpawnVector += VRand() * 0.5;
		
		// Use it to kick the ball
		Ball.ApplyImpulse(SpawnVector, 2 + Rand(4), Ball.Location);
	}
	else
	{
		CartGameInfo(WorldInfo.Game).BallsForSale = 0;
		SpawningBalls = false;
	}
}

defaultproperties
{
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.ChaosZoneInfo'
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		bIsScreenSizeScaled=True
		ScreenSize=0.0025
		SpriteCategoryName="Effects"
	End Object
	Components.Add(Sprite)
	
	Begin Object Class=ArrowComponent Name=ArrowComponent0
		ArrowColor=(R=0,G=255,B=128)
		ArrowSize=3
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		bTreatAsASprite=True
		SpriteCategoryName="Effects"
	End Object
	Components.Add(ArrowComponent0)
}