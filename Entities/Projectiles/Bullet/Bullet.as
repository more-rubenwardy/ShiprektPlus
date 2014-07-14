#include "WaterEffects.as"
#include "BlockCommon.as"

void onInit( CBlob@ this )
{
	this.Tag("projectile");

	ShapeConsts@ consts = this.getShape().getConsts();
    consts.mapCollisions = false;	 // we have our own map collision
	consts.bullet = true;	

	this.getSprite().SetZ(150.0f);	
}

void onTick( CBlob@ this )
{
	bool killed = false;

	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();

	// this gathers HitInfo objects which contain blob or tile hit information
	HitInfo@[] hitInfos;
	if (getMap().getHitInfosFromRay( pos, -vel.Angle(), vel.Length(), this, @hitInfos ))
	{
		//HitInfo objects are sorted, first come closest hits
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
					if ( ( ( Block::isCore(blockType) || b.hasTag("turret") || blockType == Block::BOMB || blockType == Block::SEAT ) && b.getTeamNum() != this.getTeamNum() ) || Block::isSolid(blockType) )//hit these and die
						killed = true;
					else 
						continue;
				}
				else
				{
					if ( b.getTeamNum() == this.getTeamNum() )
						continue;
				}

				this.server_Hit( b, pos,
                                 Vec2f_zero, 0.1f,
                                 0, true);					
			}
		}
	}

	if (killed)
	{
		this.server_Die();
	}
}

void onDie( CBlob@ this )
{
	MakeWaterParticle( this.getPosition(), Vec2f_zero);
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

        p.timeout = 20 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}


void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{            
	CSprite@ sprite = hitBlob.getSprite();
	const int blockType = sprite.getFrame();

	if (hitBlob.getName() == "shark"){
		ParticleBloodSplat( worldPoint, true );
		sprite.PlaySound("BodyGibFall");
		hitBlob.Damage( 0.5f, hitBlob );
		this.server_Die();
	}
	else	if (hitBlob.hasTag("player") && hitBlob.getTeamNum() != this.getTeamNum())
	{
		hitBlob.Damage( 0.5f, hitBlob );
		sprite.PlaySound("ImpactFlesh");
		ParticleBloodSplat( worldPoint, true );
		this.server_Die();
	}
	else	if (Block::isSolid(blockType) || Block::isCore(blockType) || hitBlob.hasTag("turret") || blockType == Block::PLATFORM || blockType == Block::SEAT || blockType == Block::BOMB)
	{	
		//extra damage per block type
		if( Block::isBomb( blockType ) )
			hitBlob.Damage( 0.6, hitBlob );
		if( Block::isPropeller( blockType ) || blockType == Block::SEAT || Block::isA_Cannon(blockType) )
			hitBlob.Damage( 0.4, hitBlob );
		if( Block::isCannon(blockType) )
			hitBlob.Damage( 0.3, hitBlob );

		//effects
		sparks(worldPoint, 8);
		int randomInt = XORRandom(3);
		
		if (randomInt == 0)
			Sound::Play( "Ricochet1.ogg", worldPoint );
		else if (randomInt == 1)
			Sound::Play( "Ricochet2.ogg", worldPoint );
		else if (randomInt == 2)
			Sound::Play( "Ricochet3.ogg", worldPoint );
	}
	else//extra damage for other types
		hitBlob.Damage( 0.2f, hitBlob );

}