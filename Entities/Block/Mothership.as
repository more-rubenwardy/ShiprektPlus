#include "BlockCommon.as"
#include "HumanCommon.as"
#include "ExplosionEffects.as";
#include "Booty.as"
#include "BlockProduction.as"

u16 bombCDTime = 7 * 30;
u16 BASE_KILL_REWARD = 100;

void onInit( CBlob@ this )
{
	this.Tag("mothership");
	
	this.set( "bombCooldown", 0 );
	this.addCommandID("blockMenu");
	this.addCommandID("buyBlock");
	this.server_SetHealth( 12.0f );
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{	
	if(this.getDistanceTo(caller) > Block::BUTTON_RADIUS_SOLID
	  || Human::isHoldingBlocks(caller)
	  || this.getShape().getVars().customData <= 0
	  || caller.getTeamNum() != this.getTeamNum())
		return;

	CBitStream params;
	params.write_u16( caller.getNetworkID() );
	caller.CreateGenericButton( 8, Vec2f(0.0f, 0.0f), this, this.getCommandID("blockMenu"), "Get Blocks", params );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("blockMenu"))
    {	
        // build menu
        CBlob@ caller = getBlobByNetworkID( params.read_u16() );
		BuildShopMenu( this, caller, "mCore Block Transmitter", Vec2f(0,0), Vec2f( 4.0f, 2.0f) );
    }
	
    if (cmd == this.getCommandID("buyBlock") && getNet().isServer())
    {
		CBlob@ caller = getBlobByNetworkID( params.read_u16() );
		
		if ( caller is null || !this.hasTag( "mothership" ) || this.getTeamNum() != caller.getTeamNum() || this.getDistanceTo(caller) > 8*10 )
			return;
			
		BuyBlock( this, caller, params.read_string() );
	}
}

void BuyBlock( CBlob@ this, CBlob@ caller, string btype )
{
	CRules@ rules = getRules();
	Block::Costs@ c = Block::getCosts( rules );
	
	if ( c is null )
	{
		warn( "** Couldn't get Costs!" );
		return;
	}

	u8 teamNum = this.getTeamNum();
	u32 gameTime = getGameTime();
	CPlayer@ player = caller.getPlayer();
	string pName = player !is null ? player.getUsername() : "";
	u16 tBooty = server_getTeamBooty( teamNum );
	u16 pBooty = server_getPlayerBooty( pName );
	
	u16 cost = 60000;
	u8 ammount = 1;
	
	bool coolDown = false;

	Block::Type type;
	if ( btype == "wood" )
	{
		type = Block::PLATFORM;
		cost = c.wood;
	}
	else if ( btype == "solid" )
	{
		type = Block::SOLID;
		cost = c.solid;
	}
	else if ( btype == "propeller" )
	{
		type = Block::PROPELLER;
		cost = c.propeller;
	}
	else if ( btype == "seat" )
	{
		type = Block::SEAT;
		cost = c.seat;
	}
	else if ( btype == "cannon" )
	{
		type = Block::TURRET;
		cost = c.cannon;
	}
	else if ( btype == "aCannon_f" )
	{
		type = Block::AUTOCANNON_F;
		cost = c.aCannon;
	}
	else if ( btype == "bomb" )
	{
		type = Block::BOMB;
		cost = c.bomb;

		u32 bombCooldown;
		this.get( "bombCooldown", bombCooldown );
		coolDown = gameTime < bombCooldown;
	}
	else if ( btype == "coupling" )
	{
		type = Block::COUPLING;
		cost = c.coupling;
		ammount = 2;
	}
	
	if ( !coolDown )
		if ( tBooty >= cost || pBooty >= cost )
		{
			if ( tBooty >= cost )
				server_setTeamBooty( teamNum, tBooty - cost );
			else
				server_setPlayerBooty( pName, pBooty - cost );
		
			ProduceBlock( getRules(), caller, type, ammount );
			
			if ( btype == "bomb" )
				this.set( "bombCooldown", gameTime + bombCDTime );
			//printf( "** Producing block " + btype + " for $" + cost );
		}
}

void BuildShopMenu( CBlob@ this, CBlob@ caller, string description, Vec2f offset, Vec2f slotsAdd )
{
	if (caller is null || !caller.isMyPlayer())
		return;

	CRules@ rules = getRules();
	Block::Costs@ c = Block::getCosts( rules );
	Block::Weights@ w = Block::getWeights( rules );
	
	if ( c is null || w is null )
		return;
	
	CGridMenu@ menu = CreateGridMenu( caller.getScreenPos() + offset, this, Vec2f(slotsAdd.x, slotsAdd.y), description );
	
	if ( menu !is null ) 
	{
		menu.deleteAfterClick = true;
		u16 netID = caller.getNetworkID();
		
		{
			CBitStream params;
			params.write_u16( netID );
			params.write_string( "seat" );
				
			CGridButton@ button = menu.AddButton( "$SEAT$", "Seat $" + c.seat, this.getCommandID("buyBlock"), params );
			button.SetHoverText( "Use it to control your ship. It can also release and produce Couplings.\nWeight: " + w.seat * 100 + "rkt\n" );
		}
		{
			CBitStream params;
			params.write_u16( netID );
			params.write_string( "solid" );
				
			CGridButton@ button = menu.AddButton( "$SOLID$", "Solid $" + c.solid , this.getCommandID("buyBlock"), params );
			button.SetHoverText( "Very strong block for protecting delicate components.\nWeight: " + w.solid * 100 + "rkt\n" );
		}
		{
			CBitStream params;
			params.write_u16( netID );
			params.write_string( "wood" );
				
			CGridButton@ button = menu.AddButton( "$WOOD$", "Wood $" + c.wood, this.getCommandID("buyBlock"), params );
			button.SetHoverText( "Good quality wood floor panel. Get that deck shinning :)\nWeight: " + w.wood * 100 + "rkt\n" );
		}
		{
			CBitStream params;
			params.write_u16( netID );
			params.write_string( "propeller" );
				
			CGridButton@ button = menu.AddButton( "$PROPELLER$", "Propeller $" + c.propeller, this.getCommandID("buyBlock"), params );
			button.SetHoverText( "Must have for any seafarer. It's a very weak block, though!\nWeight: " + w.propeller * 100 + "rkt\n" );
		}
		{
			CBitStream params;
			params.write_u16( netID );
			params.write_string( "aCannon_f" );
				
			CGridButton@ button = menu.AddButton( "$AUTOCANNON_F$", "AutoCannon $" + c.aCannon, this.getCommandID("buyBlock"), params );
			button.SetHoverText( "Great vs propellers and other weapons. Very inneffective against Solid blocks.\nWeight: " + w.aCannon * 100 + "rkt\n" );
		}
		{
			CBitStream params;
			params.write_u16( netID );
			params.write_string( "cannon" );
				
			CGridButton@ button = menu.AddButton( "$CANNON$", "Cannon $" + c.cannon, this.getCommandID("buyBlock"), params );
			button.SetHoverText( "Good against Solid blocks. Does some splash damage.\nWeight: " + w.cannon * 100 + "rkt\n" );
		}
		{
			CBitStream params;
			params.write_u16( netID );
			params.write_string( "bomb" );
				
			CGridButton@ button = menu.AddButton( "$BOMB$", "Bomb $" + c.bomb, this.getCommandID("buyBlock"), params );
			button.SetHoverText( "Explodes on contact. Can be used to build torpedoes! (has buy-cooldown time).\nWeight: " + w.bomb * 100 + "rkt\n" );
		}
		{
			CBitStream params;
			params.write_u16( netID );
			params.write_string( "coupling" );
				
			CGridButton@ button = menu.AddButton( "$COUPLING$", "Coupling $" + c.coupling, this.getCommandID("buyBlock"), params );
			button.SetHoverText( "A versatile block used to hold and release other blocks.\nWeight: " + w.coupling * 200 + "rkt\n" );
		}
	}
}

void onDie( CBlob@ this )
{
	Vec2f pos = this.getPosition();
	u8 teamNum = this.getTeamNum();
	Sound::Play( "ShipExplosion", pos );
    makeLargeExplosionParticle(pos);
    ShakeScreen( 90, 80, pos );
	if ( !this.hasTag( "cleanDeath" ) )
		client_AddToChat( "*** " + getRules().getTeam( teamNum ).getName() + " killed itself! ***" );
	
	//destroy team turrets
	if ( !getNet().isServer() ) return;
	
	CBlob@[] dieBlobs;
	getBlobsByTag( "turret", dieBlobs );
	getBlobsByTag( "player", dieBlobs );
	for ( u16 t = 0; t < dieBlobs.length; t++ )
		if ( ( Block::isCannon( Block::getType( dieBlobs[t] ) ) || dieBlobs[t].hasTag( "player" ) ) && dieBlobs[t].getTeamNum() == teamNum )
			dieBlobs[t].server_Die();			
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if ( hitterBlob !is null && !this.hasTag( "cleanDeath" ) && this.getHealth() - damage <= 0.0f )
	{
		CRules@ rules = getRules();
		u8 thisTeamNum = this.getTeamNum();
		u8 hitterTeamNum = hitterBlob.getTeamNum();
		
		if ( thisTeamNum != hitterTeamNum )
		{
			u8 thisPlayers = 0;
			u8 hitterPlayers = 0;
			u8 playersCount = getPlayersCount();
			for( u8 i = 0; i < playersCount; i++)
			{
				CPlayer@ p = getPlayer(i);
				u8 pteam = p.getTeamNum();
				if( pteam == thisTeamNum )
					thisPlayers++;
				else if ( pteam == hitterTeamNum )
					hitterPlayers++;
			}
			
			if ( hitterPlayers > 0 )//in case of suicide against leftover team ship
			{
				this.Tag( "cleanDeath" );
				client_AddToChat( "*** " + rules.getTeam( hitterTeamNum ).getName() + " has destroyed " + rules.getTeam( thisTeamNum ).getName() + "! ***" );
			
				if ( getNet().isServer() )
				{
					u16 hitterBooty = server_getTeamBooty( hitterTeamNum );
					server_setTeamBooty( hitterTeamNum, hitterBooty + ( thisPlayers + 1 ) * BASE_KILL_REWARD );
					//print ( "MothershipKill: " + thisPlayers + " players; " + ( ( thisPlayers + 1 ) * BASE_KILL_REWARD ) + " to " + rules.getTeam( hitterTeamNum ).getName() );
				}
			}
		}
	}
	
	return damage;
}