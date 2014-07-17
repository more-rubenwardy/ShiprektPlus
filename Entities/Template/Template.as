#include "TemplateCommon.as"
#include "EmotesCommon.as"
#include "MakeBlock.as"
#include "WaterEffects.as"
#include "IslandsCommon.as"
#include "BlockCommon.as"

#include "Characters.as" //Ardivaba

void onInit( CBlob@ this )
{
	this.Tag( "player" );	 
	this.SetMinimapVars( "GUI/Minimap/MinimapIcons.png", 8, Vec2f( 8,8 ) );
	
	this.set_f32("cam rotation", 0.0f);
	const u16 shipID = this.get_u16( "shipID" );
	CBlob@ ship = getBlobByNetworkID(shipID);
	if( ship !is null ) 
	{
		this.setPosition( ship.getPosition() );
		this.set_s8( "stay count", 3 );
	}
	this.SetMapEdgeFlags( u8(CBlob::map_collide_up) |
		u8(CBlob::map_collide_down) |
		u8(CBlob::map_collide_sides) );
}

void onTick( CBlob@ this )
{				
	Move( this );

	if (this.isMyPlayer())
		PlayerControls( this );
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{	
	if (player !is null && player.isMyPlayer()) // setup camera to follow
	{
		CCamera@ camera = getCamera();
		camera.mousecamstyle = 1; // follow
		camera.targetDistance = 1.0f; // zoom factor
		camera.posLag = 1.5f; // lag/smoothen the movement of the camera

		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 0, Vec2f(8,8));
		client_AddToChat( "You are part of " + getRules().getTeam( this.getTeamNum() ).getName() + " now." );
	}
}

void Move( CBlob@ this )
{
	const bool myPlayer = this.isMyPlayer();
	const f32 camRotation = myPlayer ? getCamera().getRotation() : this.get_f32("cam rotation");
	const bool attached = this.isAttached();
	Vec2f pos = this.getPosition();	
	Vec2f aimpos = this.getAimPos();
	Vec2f forward = aimpos - pos;	

	if (myPlayer)
	{
		this.set_f32("cam rotation", camRotation);
		this.Sync("cam rotation", false);
	}	
	
	if (!attached)
	{	
		const bool up = this.isKeyPressed( key_up );
		const bool down = this.isKeyPressed( key_down );
		const bool left = this.isKeyPressed( key_left);
		const bool right = this.isKeyPressed( key_right );	
		const bool action1 = this.isKeyPressed( key_action1 );
		const bool action2 = this.isKeyPressed( key_action2 );
		const u32 time = getGameTime();
		const f32 vellen = this.getShape().vellen;
		CBlob@ islandBlob = getIslandBlob( this );
		const bool solidGround = this.getShape().getVars().onground = (attached || islandBlob !is null);

		// move

		Vec2f moveVel;

		if (up)	
		{
			moveVel.y -= Template::walkSpeed;
		} 
		else if (down)	
		{
			moveVel.y += Template::walkSpeed;
		} 
		
		if (left)	
		{
			moveVel.x -= Template::walkSpeed;
		} 
		else if (right)	
		{
			moveVel.x += Template::walkSpeed;
		} 

		if( !solidGround )
		{
			moveVel *= Template::swimSlow;

			if( (getGameTime() + this.getNetworkID()) % 3 == 0)
				MakeWaterParticle(pos, Vec2f()); 

			if (this.wasOnGround())
				this.getSprite().PlaySound("SplashFast");
		}
		else
		{
		}

		moveVel.RotateBy( camRotation );
		this.setVelocity( moveVel );

		// face

		f32 angle = camRotation;
		forward.Normalize();
		
		if (this.getSprite().isAnimation("shoot"))
			angle = -forward.Angle();
		else
		{
			if (up && left) angle += 225;
			else if (up && right) angle += 315;
			else if (down && left) angle += 135;
			else if (down && right) angle += 45;
			else if (up) angle += 270;
			else if (down) angle += 90;
			else if (left) angle += 180;
			else if (right) angle += 0;
			else angle = -forward.Angle();
		}
		
		while(angle > 360)
			angle -= 360;
		while(angle < 0)
			angle += 360;

		this.getShape().SetAngleDegrees( angle );	

		// artificial stay on ship

		if (islandBlob !is null)
		{
			this.set_u16( "shipID", islandBlob.getNetworkID() );	
			this.set_s8( "stay count", 3 );
		}
		else
		{
			CBlob@ shipBlob = getBlobByNetworkID( this.get_u16( "shipID" ) );
			if (shipBlob !is null)
			{
				s8 count = this.get_s8( "stay count" );		
				count--;
				if (count <= 0){
					this.set_u16( "shipID", 0 );	
				}
				else if (!up && !left && !right && !down)
				{
					this.setPosition( shipBlob.getPosition() );
				}
				this.set_s8( "stay count", count );		
			}
		}
	}
	else
	{
		this.getShape().getVars().onground = true;
		//this.getShape().SetAngleDegrees( -forward.Angle() );//conflicts with Seat.as?
	}
}

void PlayerControls( CBlob@ this )
{
}

void onAttached( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{  
}

void onDetach( CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint )
{  
}

void onDie( CBlob@ this )
{
}
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
}

CBlob@ getMothership( const u8 team )
{
    CBlob@[] ships;
    getBlobsByTag( "mothership", @ships );
    for (uint i=0; i < ships.length; i++)
    {
        CBlob@ ship = ships[i];  
        if (ship.getTeamNum() == team)
            return ship;
    }
    return null;
}
