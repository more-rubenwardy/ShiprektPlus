#include "Booty.as";
#include "SunkShipSpawner.as";
#include "IslandsCommon.as";

const u8 CHECK_FREQUENCY =  30;//30 = 1 second
const u32 FISH_RADIUS = 40.0f;//pickup radius
const f32 TYPE_RATIO = 0.4f;//what percentage of Xs are red
const f32 TEAM_PLAYER_RATIO = 0.25f;//% players get from Xs

void onInit(CBlob@ this)
{
	this.Tag( "booty" );
	this.getCurrentScript().tickFrequency = CHECK_FREQUENCY;

	CSprite@ sprite = this.getSprite();
	if ( sprite !is null )
	{
		u16 ammount = this.get_u16( "ammount" );
		bool mothershipOnly = ammount > ( MAX_AMMOUNT - MIN_AMMOUNT ) * TYPE_RATIO + MIN_AMMOUNT;
		f32 size = ( mothershipOnly ? 1.7f  : 1.4f ) * ammount/MAX_AMMOUNT;
		sprite.SetZ(-9.0f);
		sprite.RotateBy( XORRandom(360), Vec2f_zero );
		sprite.ScaleBy( Vec2f( size, size ) );
		sprite.animation.frame = ( ( mothershipOnly ? 1  : 0 ) );
	}
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap();
	u16 ammount = this.get_u16( "ammount" );
	bool mothershipOnly = ammount > ( MAX_AMMOUNT - MIN_AMMOUNT ) * TYPE_RATIO + MIN_AMMOUNT;

	bool bigFish = map.isBlobWithTagInRadius( "mothership", this.getPosition(), FISH_RADIUS );
	bool fish = map.isBlobWithTagInRadius( "player", this.getPosition(), FISH_RADIUS );
	
	u8 fishtime = this.get_u8( "fishTime" );	
	u8 maxfishtime = this.get_u8( "maxFishTime" );	
	
	if ( bigFish || ( fish && !mothershipOnly ) )
	{
		this.getSprite().PlaySound( "/select.ogg" );
		this.set_u8( "fishTime", fishtime - 1 );
	}
	else if ( fishtime < maxfishtime )
		this.set_u8( "fishTime", fishtime + 2 );
		
	if ( fishtime == 0 && getNet().isServer() )
	{
		giveBooty ( this, ( bigFish ? "mothership" : "player" ) );
		this.server_Die();
	}
}

void giveBooty( CBlob@ this, string tag )
{
	//give booty to team with closest blob with tag
	CBlob@[] blobs;
	f32 closest = 999999.9f;
	CBlob@ closestBlob;

	getBlobsByTag( tag, @blobs );

	if ( blobs.length == 0 ) return;

	for ( u8 i = 0; i < blobs.length; i++ )
	{
		if ( this.getDistanceTo( blobs[i] ) < closest )
		{
			closest = this.getDistanceTo( blobs[i] );
			@closestBlob = blobs[i];
		}
	}
	u8 teamNum = closestBlob.getTeamNum();
	u16 ammount = this.get_u16( "ammount" );
	string pName = "";
	
	if ( tag == "mothership" )
		pName = getIsland( closestBlob ).owner;
	else
		pName = closestBlob.getPlayer().getUsername();
		
	server_setTeamBooty( teamNum, Maths::Round( server_getTeamBooty( teamNum ) + ammount * ( 1 - TEAM_PLAYER_RATIO ) ) );
	if ( pName != "" )
		server_setPlayerBooty( pName, Maths::Round( server_getPlayerBooty( pName ) + ammount * TEAM_PLAYER_RATIO ) );
}

void onDie( CBlob@ this )
{	
	this.getSprite().PlaySound( "/ChaChing.ogg" );
}