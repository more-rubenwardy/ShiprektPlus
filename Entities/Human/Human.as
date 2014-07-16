#include "HumanCommon.as"
#include "EmotesCommon.as"
#include "MakeBlock.as"
#include "WaterEffects.as"
#include "IslandsCommon.as"
#include "BlockCommon.as"

int useClickTime = 0;
f32 zoom = 1.0f;
const f32 ZOOM_SPEED = 0.1f;
const int PUNCH_RATE = 15;
const int FIRE_RATE = 60;
const f32 BULLET_SPREAD = 0.2f;
const f32 BULLET_SPEED = 8.5f;

Random _shotspreadrandom(0x11598); //clientside

void onInit( CBlob@ this )
{
	this.Tag("player");	 
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 8, Vec2f(8,8));
	this.addCommandID("get out");
	this.addCommandID("shoot");
	this.addCommandID("punch");
	this.set_f32("cam rotation", 0.0f);
	const u16 shipID = this.get_u16( "shipID" );
	CBlob@ ship = getBlobByNetworkID(shipID);
	if (ship !is null) {
		this.setPosition( ship.getPosition() );
		this.set_s8( "stay count", 3 );
	}
	this.SetMapEdgeFlags( u8(CBlob::map_collide_up) |
		u8(CBlob::map_collide_down) |
		u8(CBlob::map_collide_sides) );
	
	this.set_u32("fire time", 0);
	this.set_u32("punch time", 0);
}

void onTick( CBlob@ this )
{				
	Move( this );
	// my player stuff

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
		const bool punch = this.isKeyPressed( key_action1 );
		const bool shoot = this.isKeyPressed( key_action2 );
		const u32 time = getGameTime();
		const f32 vellen = this.getShape().vellen;
		CBlob@ islandBlob = getIslandBlob( this );
		const bool solidGround = this.getShape().getVars().onground = (attached || islandBlob !is null);

		// move

		Vec2f moveVel;

		if (up)	{
			moveVel.y -= Human::walkSpeed;
		} 
		else if (down)	{
			moveVel.y += Human::walkSpeed;
		} 
		
		if (left)	{
			moveVel.x -= Human::walkSpeed;
		} 
		else if (right)	{
			moveVel.x += Human::walkSpeed;
		} 

		if (!solidGround)
		{
			moveVel *= Human::swimSlow;

			if( (getGameTime() + this.getNetworkID()) % 3 == 0)
				MakeWaterParticle(pos, Vec2f()); 

			if (this.wasOnGround())
				this.getSprite().PlaySound("SplashFast");
			
			// shoot
			if (shoot && canShoot(this))
			{
				Shoot( this );
				this.getSprite().SetAnimation("shoot");
			}
		}
		else
		{
			// shoot
			if (shoot && canShoot(this) && !punch)
			{
				Shoot( this );
				this.getSprite().SetAnimation("shoot");
			}
			
			// punch
			if (punch && !Human::isHoldingBlocks(this) && canPunch(this))
			{
				Punch( this );
			}
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
	CHUD@ hud = getHUD();

	// bubble menu
	if (this.isKeyJustPressed(key_bubbles))
	{
		this.CreateBubbleMenu();
	}

	if (this.isAttached())
	{
	    // get out of seat
		if (this.isKeyJustPressed(key_use))
		{
			CBitStream params;
			this.SendCommand( this.getCommandID("get out"), params );
		} 

		// aim cursor
		hud.SetCursorImage("AimCursor.png", Vec2f(32,32));
		hud.SetCursorOffset( Vec2f(-32, -32) );		
	}
	else
	{		
		// use menu
	    if (this.isKeyJustPressed(key_use))
	    {
	        this.ClearMenus();
	        this.ShowInteractButtons();
	        useClickTime = getGameTime();
	    }
	    else if (this.isKeyJustReleased(key_use))
	    {
	    	bool tapped = (getGameTime() - useClickTime) < 10; 
			this.ClickClosestInteractButton( tapped ? this.getPosition() : this.getAimPos(), this.getRadius()*2 );

	        this.ClearButtons();
	    }	

	    // default cursor
	    hud.SetCursorImage("PointerCursor.png", Vec2f(32,32));
		hud.SetCursorOffset( Vec2f(-32, -32) );		
	}

	// click action1 to click buttons
	if (hud.hasButtons() && this.isKeyPressed(key_action1) && !this.ClickClosestInteractButton( this.getAimPos(), 2.0f ))
	{
	}

	// click grid menus

    if (hud.hasButtons())
    {
        if (this.isKeyJustPressed(key_action1))
        {
		    CGridMenu @gmenu;
		    CGridButton @gbutton;
		    this.ClickGridMenu(0, gmenu, gbutton); 
	    }	
	}

	// zoom
	
	CCamera@ camera = getCamera();

	if (zoom == 2.0f)	
	{
		if (this.isKeyJustPressed(key_zoomout)){
  			zoom = 1.0f;
  		}
		else if (camera.targetDistance < zoom)
			camera.targetDistance += ZOOM_SPEED;		
	}
	else if (zoom == 1.0f)	
	{
		if (this.isKeyJustPressed(key_zoomout)){
  			zoom = 0.5f;
  		}
  		else if (this.isKeyJustPressed(key_zoomin)){
  			zoom = 2.0f;
  		} 
  		else if (camera.targetDistance < zoom)
			camera.targetDistance += ZOOM_SPEED;	
		else if (camera.targetDistance > zoom)
			camera.targetDistance -= ZOOM_SPEED;	
	}
	else if (zoom == 0.5f)
	{
		if (this.isKeyJustPressed(key_zoomin)){
  			zoom = 1.0f;
  		} 
		else if (camera.targetDistance > zoom)	
			camera.targetDistance -= ZOOM_SPEED;
	}
}

void onAttached( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{  
	this.ClearMenus();
}

void onDetach( CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint )
{  
	this.set_u16( "shipID", detached.getNetworkID() );
	this.set_s8( "stay count", 3 );
}

void onDie( CBlob@ this )
{
	CSprite@ sprite = this.getSprite();
	
	ParticleBloodSplat( this.getPosition(), true );
	sprite.PlaySound("BodyGibFall");
	
	if (!sprite.getVars().gibbed) 
	{
		int randomInt = XORRandom(4);
		if (randomInt == 0)
				sprite.PlaySound("SR_ManDeath1");
		else if (randomInt == 1)
				sprite.PlaySound("SR_ManDeath2");
		else if (randomInt == 2)
				sprite.PlaySound("SR_ManDeath3");
		else if (randomInt == 3)
				sprite.PlaySound("SR_ManDeath4");
	}
	
	sprite.Gib();

	if(this.isMyPlayer())
	{
		CCamera@ camera = getCamera();
		if (camera !is null)
		{
			camera.setRotation(0.0f);
			camera.targetDistance = 1.0f;
		}
	}

	// destroy blocks

    CBlob@[]@ blocks;
    if (this.get( "blocks", @blocks ))                 
    {
        for (uint i = 0; i < blocks.length; ++i)
        {
            CBlob@ b = blocks[i];
            b.server_Die();
        }
        blocks.clear();
    } 
}

void Punch( CBlob@ this )
{
	Vec2f pos = this.getPosition();
	Vec2f aimvector = this.getAimPos() - pos;
	const f32 aimdist = aimvector.Normalize();
	
	this.set_u32("punch time", getGameTime());	

	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius( pos, this.getRadius()*4.0f, @blobsInRadius ))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b !is this && b.getTeamNum() != this.getTeamNum() && b.getName() == "human")
			{
				Vec2f vector = b.getPosition() - pos;
				if (vector * aimvector > 0.0f)
				{
					ParticleBloodSplat( b.getPosition(), false );
					b.getSprite().PlaySound("Kick.ogg");
					if ( getNet().isServer() )
						this.server_Hit( b, aimvector, Vec2f_zero, 0.25f, 0, false );
					return;
				}
			}
		}
	}

	// miss
	this.getSprite().PlaySound("throw");
}

void Shoot( CBlob@ this )
{
	Vec2f pos = this.getPosition();
	Vec2f aimvector = this.getAimPos() - pos;
	const f32 aimdist = aimvector.Normalize();
	
	Vec2f offset(_shotspreadrandom.NextFloat() * BULLET_SPREAD,0);
	offset.RotateBy(_shotspreadrandom.NextFloat() * 360.0f, Vec2f());
	
	Vec2f _vel = (aimvector * BULLET_SPEED) + offset;

	f32 _lifetime = Maths::Min( 0.05f + aimdist/BULLET_SPEED/32.0f, 2.0f);

	if ( this.isMyPlayer() )
	{
		Vec2f islandVelocity;
		if (getIslandBlob( this ) !is null)
			islandVelocity = getIsland( getIslandBlob( this ) ).pos - getIsland( getIslandBlob( this ) ).old_pos;
		else
			islandVelocity = Vec2f(0, 0);
	
		CBitStream params;
		params.write_Vec2f( this.getPosition() + aimvector*9 + islandVelocity*2 );
		params.write_Vec2f( _vel + islandVelocity );
		params.write_f32( _lifetime );
		this.SendCommand( this.getCommandID("shoot"), params );
		this.set_u32("fire time", getGameTime());	
	}
	return;
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (this.getCommandID("get out") == cmd){
		this.server_DetachFromAll();
	}
	else if (this.getCommandID("shoot") == cmd)
	{
		Vec2f pos = params.read_Vec2f();
		Vec2f velocity = params.read_Vec2f();
		const f32 time = params.read_f32();

		if (getNet().isServer())
		{
            CBlob@ bullet = server_CreateBlob( "bullet", this.getTeamNum(), pos );
            if (bullet !is null)
            {
            	if (this.getPlayer() !is null){
                	bullet.SetDamageOwnerPlayer( this.getPlayer() );
                }
                bullet.setVelocity( velocity );
                bullet.server_SetTimeToDie( time ); 
            }
    	}
		
		shotParticles(pos, velocity.Angle());
        this.getSprite().PlaySound("Gunshot.ogg");
	}
}

bool canPunch( CBlob@ this )
{
	return this.get_u32("punch time") + PUNCH_RATE < getGameTime();
}

bool canShoot( CBlob@ this )
{
	return this.get_u32("fire time") + FIRE_RATE < getGameTime();
}

Random _shotrandom(0x15125); //clientside

void shotParticles(Vec2f pos, float angle)
{
	//muzzle flash
	{
		CParticle@ p = ParticleAnimated( "Entities/Block/turret_muzzle_flash.png",
												  pos, Vec2f(),
												  -angle, //angle
												  1.0f, //scale
												  3, //animtime
												  0.0f, //gravity
												  true ); //selflit
		if(p !is null)
			p.Z = 10.0f;
	}

	Vec2f shot_vel = Vec2f(0.5f,0);
	shot_vel.RotateBy(-angle);

	//smoke
	for(int i = 0; i < 5; i++)
	{
		//random velocity direction
		Vec2f vel(0.03f + _shotrandom.NextFloat()*0.03f, 0);
		vel.RotateBy(_shotrandom.NextFloat() * 360.0f);
		vel += shot_vel * i;

		CParticle@ p = ParticleAnimated( "Entities/Block/turret_smoke.png",
												  pos, vel,
												  _shotrandom.NextFloat() * 360.0f, //angle
												  0.6f, //scale
												  3+_shotrandom.NextRanged(4), //animtime
												  0.0f, //gravity
												  true ); //selflit
		if(p !is null)
			p.Z = 110.0f;
	}
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
