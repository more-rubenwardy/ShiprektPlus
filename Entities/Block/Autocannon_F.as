#include "WaterEffects.as"
#include "BlockCommon.as"
#include "IslandsCommon.as"

#include "Characters.as"
 
const f32 BULLET_SPREAD = 5.0f;
const f32 BULLET_RANGE = 240.0F;
const f32 MIN_FIRE_PAUSE = 3.0f;//min wait between shots
const f32 MAX_FIRE_PAUSE = 8.0f;//max wait between shots
//todo: should be done with 1 factor value
const f32 FIRE_PAUSE_DECREASE = 0.08f;//how quickly it recuperates
const f32 FIRE_PAUSE_INCREASE = 0.04f;//how quickly it slows down
 
Random _shotspreadrandom(0x11598); //clientside
 
void onInit( CBlob@ this )
{
	this.getCurrentScript().tickFrequency = 2;

	this.Tag("turret");
	this.Tag("fixed_gun");
	this.addCommandID("fire");
	this.addCommandID("disable");
	this.set_string("barrel", "left");
	if ( getNet().isServer() )
	{
		this.set_f32("fire pause",MIN_FIRE_PAUSE);
		this.Sync("fire pause", true );
	}
   
	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ layer = sprite.addSpriteLayer( "turret", 16, 16 );
    if (layer !is null)
    {
        layer.SetRelativeZ(2);
        layer.SetLighting( false );
        Animation@ anim = layer.addAnimation( "fire left", Maths::Round( MIN_FIRE_PAUSE ), false );
        anim.AddFrame(Block::AUTOCANNON_F2);
        anim.AddFrame(Block::AUTOCANNON_F1);
               
		Animation@ anim2 = layer.addAnimation( "fire right", Maths::Round( MIN_FIRE_PAUSE ), false );
        anim2.AddFrame(Block::AUTOCANNON_F3);
        anim2.AddFrame(Block::AUTOCANNON_F1);
               
		Animation@ anim3 = layer.addAnimation( "default", 1, false );
		anim3.AddFrame(Block::AUTOCANNON_F1);
        layer.SetAnimation("default");  
    }
 
	this.set_u32("fire time", 0);
}
 
void onTick( CBlob@ this )
{      
	if (this.getShape().getVars().customData <= 0)//not placed yet
		return;
		
	f32 currentFirePause = this.get_f32("fire pause");
	if (currentFirePause > MIN_FIRE_PAUSE)
		this.set_f32("fire pause", currentFirePause - FIRE_PAUSE_DECREASE * this.getCurrentScript().tickFrequency);
       
	//print( "Fire pause: " + currentFirePause );
	
	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ laser = sprite.getSpriteLayer( "laser" );
	
	if (laser !is null)
	{		
		if ( this.get_u32("fire time") + 2.5f < getGameTime() )
		{		
			sprite.RemoveSpriteLayer("laser");
		}
	}
}
 
bool canShoot( CBlob@ this )
{
	return ( this.get_u32("fire time") + this.get_f32("fire pause") < getGameTime() );
}

bool canIncreaseFirePause( CBlob@ this )
{
	return ( this.get_u32("fire time min") + MIN_FIRE_PAUSE < getGameTime() );
}
 
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("fire"))
    {
		if (canIncreaseFirePause(this))    
		{
			f32 currentFirePause = this.get_f32("fire pause");
			if ( currentFirePause < MAX_FIRE_PAUSE )
				this.set_f32("fire pause", currentFirePause + FIRE_PAUSE_INCREASE * MIN_FIRE_PAUSE);
		}
			
		if (canShoot(this))    
		{		
			//autocannon effects
			CSprite@ sprite = this.getSprite();
			CSpriteLayer@ layer = sprite.getSpriteLayer( "turret" );
			layer.SetAnimation( "default" );
		   
			if (this.get_string("barrel") == "left")
					layer.SetAnimation( "fire left" );
			if (this.get_string("barrel") == "right")
					layer.SetAnimation( "fire right" );

			//todo: integrate randomness
			//Vec2f offset(_shotspreadrandom.NextFloat() * BULLET_SPREAD,0);
			//offset.RotateBy(_shotspreadrandom.NextFloat() * 360.0f, Vec2f());
		   
			Vec2f aimvector = Vec2f(1, 0).RotateBy(this.getAngleDegrees());
		   	   
			Vec2f barrelOffset;
			Vec2f barrelOffsetRelative;
			if (this.get_string("barrel") == "left")
			{
				barrelOffsetRelative = Vec2f(0, -2.0);
				barrelOffset = Vec2f(0, -2.0).RotateBy(-aimvector.Angle());
				this.set_string("barrel", "right");
			}
			else
			{
				barrelOffsetRelative = Vec2f(0, 2.0);
				barrelOffset = Vec2f(0, 2.0).RotateBy(-aimvector.Angle());
				this.set_string("barrel", "left");
			}	   
				
			Vec2f pos = this.getPosition() + aimvector*9 + barrelOffset;
	
			shotParticles( pos, aimvector.Angle() );
			sprite.PlaySound("Gunshot" + ( XORRandom(2) + 2 ) + ".ogg");

			//hit stuff
			u8 teamNum = params.read_u8();//teamNum of the player firing
			HitInfo@[] hitInfos;
			CMap@ map = this.getMap();
			bool killed = false;
			
			f32 offsetAngle = _shotspreadrandom.NextFloat() * BULLET_SPREAD;
			if (XORRandom(2) == 0)
			{
				offsetAngle = -offsetAngle;		
			}
			aimvector.RotateBy(offsetAngle);
			
			f32 rangeOffset = _shotspreadrandom.NextFloat() * BULLET_SPREAD * 4.0f;
			if (XORRandom(2) == 0)
			{
				rangeOffset = -rangeOffset;	
			}
				
			if( map.getHitInfosFromRay( pos, -aimvector.Angle(), BULLET_RANGE + rangeOffset, this, @hitInfos ) )
			{
				for (uint i = 0; i < hitInfos.length; i++)
				{
					HitInfo@ hi = hitInfos[i];
					CBlob@ b = hi.blob;	  
					if(b is null || b is this) continue;

					const int color = b.getShape().getVars().customData;
					const int blockType = b.getSprite().getFrame();
					const bool isBlock = b.getName() == "block";

					if ( !b.hasTag( "booty" ) &&  (color > 0 || !isBlock) )
					{
						if (isBlock )
						{
							if ( ( ( Block::isCore(blockType) || b.hasTag("turret") || blockType == Block::BOMB || blockType == Block::SEAT ) && b.getTeamNum() != teamNum ) || Block::isSolid(blockType) )//hit these and die
								killed = true;
							else 
								continue;
						}
						else
						{
							if ( b.getTeamNum() == teamNum || ( b.hasTag("player") && b.isAttached() ) )
								continue;
						}
						
						sprite.RemoveSpriteLayer("laser");
						CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "Beam1.png", 16, 16);
						if (laser !is null)
						{
							Animation@ anim = laser.addAnimation( "default", 1, false );
							anim.AddFrame(0);
							anim.AddFrame(1);
							anim.AddFrame(2);
							anim.AddFrame(3);
							anim.AddFrame(4);
							anim.AddFrame(5);
							laser.SetVisible(true);
						}
						f32 laserLength = Maths::Max(0.1f, (hi.hitpos - pos).getLength() / 16.0f);						
						laser.ResetTransform();						
						laser.ScaleBy( Vec2f(laserLength, 0.5f) );							
						laser.TranslateBy( Vec2f(laserLength*8.0f + 8.0f, barrelOffsetRelative.y) );							
						laser.RotateBy( offsetAngle, Vec2f());
						laser.setRenderStyle(RenderStyle::light);
						
						hitEffects(b, hi.hitpos);
						
						if ( getNet().isServer() )
							this.server_Hit( b, pos, Vec2f_zero, getDamage(b), 0, true );	

						if ( killed ) break;
					}
				}
			}
			
			if ( !killed )
			{
				sprite.RemoveSpriteLayer("laser");
				CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "Beam1.png", 16, 16);
				if (laser !is null)
				{
					Animation@ anim = laser.addAnimation( "default", 1, false );
					anim.AddFrame(0);
					anim.AddFrame(1);
					anim.AddFrame(2);
					anim.AddFrame(3);
					anim.AddFrame(4);
					anim.AddFrame(5);
					laser.SetVisible(true);
				}
				f32 laserLength = Maths::Max(0.1f, (aimvector * (BULLET_RANGE + rangeOffset)).getLength() / 16.0f);						
				laser.ResetTransform();						
				laser.ScaleBy( Vec2f(laserLength, 0.5f) );							
				laser.TranslateBy( Vec2f(laserLength*8.0f + 8.0f, barrelOffsetRelative.y) );								
				laser.RotateBy( offsetAngle, Vec2f());
				laser.setRenderStyle(RenderStyle::light);				
				
				MakeWaterParticle( pos + aimvector * (BULLET_RANGE + rangeOffset), Vec2f_zero );
			}
			
			this.set_u32("fire time", getGameTime());
		}
    }
}
 
f32 getDamage( CBlob@ hitBlob )
{            
	const int blockType = Block::getType( hitBlob );

	if ( hitBlob.getName() == "shark" || Characters::isCharacter( hitBlob ) )
		return 0.5f;

	if( Block::isBomb( blockType ) )
		return 0.4f;
		
	if( Block::isPropeller( blockType ) || blockType == Block::SEAT || Block::isA_Cannon( blockType  ) )
		return 0.3f;
		
	if( Block::isCannon( blockType ) )
		return 0.2f;
	
	return 0.1f;
}

void hitEffects( CBlob@ hitBlob, Vec2f worldPoint )
{
	CSprite@ sprite = hitBlob.getSprite();
	const int blockType = sprite.getFrame();

	if (hitBlob.getName() == "shark"){
		ParticleBloodSplat( worldPoint, true );
		sprite.PlaySound("BodyGibFall");
	}
	else	if (hitBlob.hasTag("player") )
	{
		sprite.PlaySound("ImpactFlesh");
		ParticleBloodSplat( worldPoint, true );
	}
	else	if (Block::isSolid(blockType) || Block::isCore(blockType) || hitBlob.hasTag("turret") || blockType == Block::PLATFORM || blockType == Block::SEAT || blockType == Block::BOMB)
	{	
		sparks(worldPoint, 4);
		Sound::Play( "Ricochet" +  ( XORRandom(3) + 1 ) + ".ogg", worldPoint );
	}
}
 
Random _shotrandom(0x15125); //clientside
void shotParticles(Vec2f pos, float angle )
{
	//muzzle flash
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

Random _sprk_r;
void sparks(Vec2f pos, int amount)
{
	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixel( pos, vel, SColor( 255, 255, 128+_sprk_r.NextRanged(128), _sprk_r.NextRanged(128)), true );
        if(p is null) return; //bail if we stop getting particles

        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}