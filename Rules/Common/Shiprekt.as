//#define SERVER_ONLY
#include "Default/DefaultGUI.as"
#include "Default/DefaultLoaders.as"
#include "Booty.as"
#include "BlockCommon.as"

void onInit(CRules@ this)
{
	AddIconToken( "$BOOTY$", "InteractionIcons2.png", Vec2f(32,32), 26 );
	AddIconToken( "$CAPTAIN$", "InteractionIcons2.png", Vec2f(32,32), 11 );
	AddIconToken( "$CREW$", "InteractionIcons2.png", Vec2f(32,32), 15 );
	AddIconToken( "$FREEMAN$", "InteractionIcons2.png", Vec2f(32,32), 14 );
	AddIconToken( "$SEA$", "InteractionIcons2.png", Vec2f(32,32), 9 );
	AddIconToken( "$ASSAIL$", "InteractionIcons2.png", Vec2f(32,32), 10 );
	AddIconToken( "$WOOD$", "Block.png", Vec2f(8,8), 0 );
	AddIconToken( "$SOLID$", "Block.png", Vec2f(8,8), 4 );
	AddIconToken( "$PROPELLER$", "Block.png", Vec2f(8,8), 32 );
	AddIconToken( "$SEAT$", "Block.png", Vec2f(8,8), 23 );
	AddIconToken( "$BOMB$", "Block.png", Vec2f(8,8), 19 );
	AddIconToken( "$CANNON$", "Block.png", Vec2f(16,16), 11 );
	AddIconToken( "$AUTOCANNON_F$", "Block.png", Vec2f(16,16), 27 );
	AddIconToken( "$COUPLING$", "Block.png", Vec2f(8,8), 35 );

	RegisterFileExtensionScript( "WaterPNGMap.as", "png" );
    particles_gravity.y = 0.0f; 
    sv_gravity = 0;    
    sv_maxplayers = 16;
    v_camera_ints = false;
    sv_visiblity_scale = 2.0f;

	this.set_u16( "projectiles", 0 );
	string[] quitList;
	this.set( "quitList", quitList );
}

void onTick(CRules@ this)
{
	this.set_u16( "projectiles", 0 );
	//check for minimum resources
	if ( getNet().isServer() && getGameTime() % 300 == 0 )
	{	
		Block::Costs@ c = Block::getCosts( this );
		if ( c is null )
		{
			warn( "** Couldn't get Costs! (onTick)" );
			return;
		}

		for ( int i = 0; i < numTeams; i++ )
		{
			u16 booty = server_getTeamBooty(i);
			if ( booty < c.propeller )
				server_setTeamBooty( i, booty + 10 );
		}
	}
}

void onReload(CRules@ this)
{
	if (getNet().isServer() )
		setStartingBooty(this);
}
 
void onRestart(CRules@ this)
{
	if (getNet().isServer() )
		setStartingBooty(this);
}

void onPlayerLeave( CRules@ this, CPlayer@ player )
{
	string[]@ quitList;
	this.get( "quitList", @quitList );
	
	quitList.push_back( player.getUsername() );
}

void onBlobCreated( CRules@ this, CBlob@ blob )
{
	if ( blob.hasTag( "projectile" ) )
		this.set_u16( "projectiles", this.get_u16( "projectiles" ) + 1 );
}

bool onServerProcessChat( CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player )
{
	if (player is null )
		return true;

	if ( player.isMod() )
	{
		if (text_in.substr(0,1) == "!" )
		{
			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				if (tokens[0] == "!team")
				{
					player.server_setTeamNum( parseInt( tokens[1] ));
					if ( player.getBlob() !is null )
						player.getBlob().server_Die();
				}
			}
		}
		if ( text_in == "!booty" )
			server_setPlayerBooty( player.getUsername(), 5000 );
	}
	return true;
}