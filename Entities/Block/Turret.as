#include "BlockCommon.as"
#include "IslandsCommon.as"

#include "Characters.as"

const f32 CANNONBALL_SPEED = 6.0f;
const f32 CANNONBALL_SPREAD = 0.0f;
const int FIRE_RATE = 45;
const f32 AUTO_RADIUS = 270.0f;

Random _shotspreadrandom(0x11598); //clientside

void onInit( CBlob@ this )
{
	this.Tag("turret");
	this.addCommandID("fire");

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ layer = sprite.addSpriteLayer( "turret", 16, 16 );
    if (layer !is null)
    {
    	layer.SetRelativeZ(2);
    	layer.SetLighting( false );
     	Animation@ anim = layer.addAnimation( "fire", FIRE_RATE, false );
        anim.AddFrame(Block::TURRET_A2);
        anim.AddFrame(Block::TURRET_A1);
        layer.SetAnimation("fire");    	
    }

	this.set_string("seat label", "Use turret");
	this.set_u8("seat icon", 7);

	this.set_u32("fire time", 0);
}

void onTick( CBlob@ this )
{	
	if (this.getShape().getVars().customData <= 0)
		return;

	Auto( this );	
}

void Auto( CBlob@ this )
{	
	if ((getGameTime()+this.getNetworkID()) % 20 == 0)
	{
		CBlob@ target;
		CBlob@[] blobsInRadius;
		Vec2f pos = this.getPosition();
		f32 maxDistance = 9999999.9f;
		bool shoot = false;
		const uint myTeam = this.getTeamNum();
		if (this.getMap().getBlobsInRadius( this.getPosition(), AUTO_RADIUS, @blobsInRadius ))
		{
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob @b = blobsInRadius[i];
				if (b.getTeamNum() != this.getTeamNum() && ( Characters::isCharacter( b ) || b.hasTag("turret") || b.hasTag("mothership")) && b.get_u16("ownerID") == 0)
				{				
					Vec2f bpos = b.getPosition();
					f32 dist = (bpos - pos).getLength();
					if (dist < maxDistance && isClearShot(this, bpos) )
					{
						@target = b;
						maxDistance = dist;
						shoot = true;					
					}
				}
			}
		}	
		
		if (shoot)
		{
			Island@ targetIsland = getIsland( target );
			Vec2f targetPos = target.getPosition();
			Vec2f aimVec = targetPos - pos;
			f32 distance = aimVec.Length();
			if ( targetIsland !is null )
			{
				aimVec += targetIsland.vel * Maths::FastSqrt( distance ) * 13.0f/CANNONBALL_SPEED;//poor man's kinematics
				aimVec.Normalize();
				aimVec *= distance;
			}
			Rotate( this, aimVec );
			if (getNet().isServer() && canShoot(this) && isClearShot(this, aimVec + pos ))//todo: move the 'prediction' to the blobsInRadius check (might be too res intensive?)		
				Fire( this, aimVec, 0 );
		}
	}
}

bool canShoot( CBlob@ this )
{
	return ( this.get_u32("fire time") + FIRE_RATE < getGameTime() ) && getRules().get_u16( "projectiles" ) < 6;
}

bool isClearShot( CBlob@ this, Vec2f targetPos )
{
	Vec2f pos = this.getPosition();
	Vec2f vector = targetPos - pos;
	const f32 dist = vector.Length();
	HitInfo@[] hitInfos;
	CMap@ map = getMap();
	
	map.getHitInfosFromArc( pos, -vector.Angle(), 35.0f, 8.0f , this, @hitInfos );
	map.getHitInfosFromArc( pos, -vector.Angle(), 20.0f, 8 * 10.0f , this, @hitInfos );
	map.getHitInfosFromRay( pos, -vector.Angle(), dist, this, @hitInfos );
	if ( hitInfos.length > 0 )
	{
		//HitInfo objects are sorted, first come closest hits
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;	  
			if(b is null || b is this) continue;

			const int blockType = b.getSprite().getFrame();
			if (b.getName() == "block" && b.getShape().getVars().customData > 0 && (Block::isCore(blockType) || Block::isSolid(blockType)) && hi.distance < dist * 0.60f)//there's a lined solid|core block witihin a portion of the target distance
			{
				return false;
			}
		}
	}	

	
	return true;
}

void Fire( CBlob@ this, Vec2f aimvector, const u16 netid )
{
	const f32 aimdist = aimvector.Normalize();

	Vec2f offset(_shotspreadrandom.NextFloat() * CANNONBALL_SPREAD,0);
	offset.RotateBy(_shotspreadrandom.NextFloat() * 360.0f, Vec2f());

	Vec2f _vel = (aimvector * CANNONBALL_SPEED) + offset;

	f32 _lifetime = Maths::Min( 0.45f + aimdist/CANNONBALL_SPEED/32.0f, 2.0f);

	CBitStream params;
	params.write_netid( netid );
	params.write_Vec2f( this.getPosition() + aimvector*9 );
	params.write_Vec2f( _vel );
	params.write_f32( _lifetime );
	this.SendCommand( this.getCommandID("fire"), params );
	this.set_u32("fire time", getGameTime());	
}

void Rotate( CBlob@ this, Vec2f aimvector )
{
	CSpriteLayer@ layer = this.getSprite().getSpriteLayer("turret");
	if(layer !is null)
	{
		layer.ResetTransform();
		layer.RotateBy( -aimvector.getAngleDegrees() - this.getAngleDegrees(), Vec2f_zero );
	}	
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("fire"))
    {
		CBlob@ caller = getBlobByNetworkID( params.read_netid() );
		Vec2f pos = params.read_Vec2f();
		Vec2f velocity = params.read_Vec2f();
		const f32 time = params.read_f32();

		if (getNet().isServer())
		{
            CBlob@ cannonball = server_CreateBlob( "cannonball", this.getTeamNum(), pos );
            if (cannonball !is null)
            {
            	if (caller !is null){
                	cannonball.SetDamageOwnerPlayer( caller.getPlayer() );
                }
                cannonball.setVelocity( velocity );
                cannonball.server_SetTimeToDie( time );
            }
    	}
		
		shotParticles(pos, velocity.Angle());
        this.getSprite().PlaySound("CannonFire.ogg");
    }
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
		Vec2f vel(0.1f + _shotrandom.NextFloat()*0.2f, 0);
		vel.RotateBy(_shotrandom.NextFloat() * 360.0f);
		vel += shot_vel * i;

		CParticle@ p = ParticleAnimated( "Entities/Block/turret_smoke.png",
												  pos, vel,
												  _shotrandom.NextFloat() * 360.0f, //angle
												  1.0f, //scale
												  3+_shotrandom.NextRanged(4), //animtime
												  0.0f, //gravity
												  true ); //selflit
		if(p !is null)
			p.Z = 110.0f;
	}
}