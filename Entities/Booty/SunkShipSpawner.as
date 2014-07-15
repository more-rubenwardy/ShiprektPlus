//Spawn booty randomly

const f32 FISH_TIME_FACTOR = 24.0f;
const u16 FREQUENCY = 1 * 30;//30 = 1 second
const u16 TOTAL_AMMONT_FACTOR = 500;
const u16 MIN_AMMOUNT = 100;
const u16 MAX_AMMOUNT = 250;
const f32 CLEAR_RADIUS_FACTOR = 1.6f;


void onTick(CRules@ this)
{
	if ( !getNet().isServer() || getGameTime() % FREQUENCY > 0 ) return;	

	CMap@ map = getMap();
	f32 mWidth = map.tilemapwidth * map.tilesize;
	f32 mHeight = map.tilemapheight * map.tilesize;
	u8 players = getPlayersCount();
	u16 totalB = totalBooty();
	
	if ( totalB < players * TOTAL_AMMONT_FACTOR )
	{
		//checks for nearby treasure and Motherships
		for ( int tries = 0; tries < 10; tries++ )
		{
			f32 xSpot = Maths::Min( float( XORRandom( mWidth ) ) + 80.0f, mWidth - 80.0f );
			f32 ySpot = Maths::Min( XORRandom( mHeight ) + 80.0f, mHeight - 80.0f );
			if ( zoneClear( map, Vec2f( xSpot, ySpot ) )  ) 
			{
				createBooty( Vec2f( xSpot, ySpot ), XORRandom(MAX_AMMOUNT - MIN_AMMOUNT) + MIN_AMMOUNT );
				break;
			}
		}
	}	
}	

void createBooty( Vec2f pos, u16 ammount )
{
    CBlob@ booty = server_CreateBlobNoInit( "booty" );
    if ( booty !is null )
	{
		u8 maxFishTime = Maths::Min( 15,  Maths::Round( ammount / FISH_TIME_FACTOR ) );
	    booty.set_u16( "ammount", ammount );
		booty.set_u8( "maxFishTime", maxFishTime );
		booty.set_u8( "fishTime",  maxFishTime );
		booty.server_setTeamNum(-1);
		booty.setPosition( pos );
		booty.Init();
	}
}

int totalBooty()
{
	CBlob@[] booty;
	getBlobsByName( "booty", @booty );
	u16 totalBooty = 0;

	for( int b = 0; b < booty.length(); b++ )
		totalBooty += booty[b].get_u16( "ammount" );

	return totalBooty;
}

bool zoneClear( CMap@ map, Vec2f spot )
{
	f32 clearRadius = Maths::Sqrt( map.tilemapwidth * map.tilemapheight ) * CLEAR_RADIUS_FACTOR;
	bool mothership = map.isBlobWithTagInRadius( "mothership", spot, clearRadius );
	bool player = map.isBlobWithTagInRadius( "player", spot, clearRadius );
	bool booty = map.isBlobWithTagInRadius( "booty", spot, clearRadius );

	return !booty && !mothership && !player;
}