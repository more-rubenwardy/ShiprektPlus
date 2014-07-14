//#include "IslandsCommon.as"
#include "BlockCommon.as"
#include "WaterEffects.as"
#include "PropellerForceCommon.as"

Random _r(133701); //global clientside random object

void onInit( CBlob@ this )
{
	this.addCommandID("on/off");
	this.set_f32("power", 0.0f);
	this.set_u32( "onTime", 0 );
	this.Tag("propeller");

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ propeller = sprite.addSpriteLayer( "propeller" );
    if (propeller !is null)
    {
    	propeller.SetOffset(Vec2f(0,8));
    	propeller.SetRelativeZ(2);
    	propeller.SetLighting( false );
        Animation@ animcharge = propeller.addAnimation( "go", 1, true );
        animcharge.AddFrame(Block::PROPELLER_A1);
        animcharge.AddFrame(Block::PROPELLER_A2);
        propeller.SetAnimation("go");
    }

    sprite.SetEmitSound("PropellerMotor");
    sprite.SetEmitSoundPaused(true);
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{	
	const bool on = isOn(this);

	if( !on || this.getDistanceTo(caller) > Block::BUTTON_RADIUS_SOLID || this.getShape().getVars().customData <= 0 )
		return;

	CBitStream params;
	CButton@ button = caller.CreateGenericButton( on ? 1 : 3, Vec2f(0.0f, 0.0f), this, this.getCommandID("on/off"), on ? "Off" : "On", params );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("on/off") && getNet().isServer())
    {
		this.set_f32("power", isOn(this) ? 0.0f : -1.0f);
    }
}

bool isOn(CBlob@ this)
{
	return this.get_f32("power") != 0;
}

void onTick( CBlob@ this )
{	
	if (this.getShape().getVars().customData <= 0)
		return;
	
	CSprite@ sprite = this.getSprite();
	const f32 power = this.get_f32("power");
	const bool on = power != 0;

	sprite.getSpriteLayer("propeller").animation.time = on ? 1 : 0;
	this.Sync("power", true);

	if (on)
	{
		//auto turn off after a while
		if ( getNet().isServer() && getGameTime() - this.get_u32( "onTime") > 750 )
		{
			this.SendCommand( this.getCommandID( "on/off" ) );
			return;
		}
			
		Island@ island = getIsland(this.getShape().getVars().customData);
		if (island !is null)
		{
			Vec2f pos = this.getPosition();

			// move
			Vec2f moveVel;
			Vec2f moveNorm;
			float angleVel;

			PropellerForces(this, island, power, moveVel, moveNorm, angleVel);

			const f32 mass = island.mass;
			moveVel /= mass;
			angleVel /= mass;
			
			// eat stuff
			if (getNet().isServer())
			{
				Vec2f faceNorm(0,-1);
				faceNorm.RotateBy(this.getAngleDegrees());
				CBlob@ victim = getMap().getBlobAtPosition( pos - faceNorm * Block::size );
				if ( victim !is null && !victim.isAttached() 
					 && victim.getShape().getVars().customData > 0
					       && !victim.hasTag( "player" ) && !victim.hasTag( "mothership" ) )	
				{
					this.server_Hit( victim, Vec2f_zero, Vec2f_zero, 0.25f, 0, true );
				}
			}
			
			//todo: apply vel cap here?
			island.vel += moveVel;
			island.angle_vel += angleVel;

			// effects

			Vec2f rpos = Vec2f(_r.NextFloat() * -4 + 4, _r.NextFloat() * -4 + 4);
			if (Maths::Abs(power) >= 1)
				MakeWaterParticle(pos + moveNorm * -6 + rpos, moveNorm * (-0.8f + _r.NextFloat() * -0.3f));
			

			// limit sounds		

			if (island.soundsPlayed == 0){
				sprite.SetEmitSoundPaused(false);								
			}
			island.soundsPlayed++;
			const f32 vol = Maths::Min(0.5f + float(island.soundsPlayed)/2.0f, 3.0f);
			sprite.SetEmitSoundVolume( vol );
		}
	}
	else
	{
		sprite.SetEmitSoundPaused(true);
	}
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	//this.getSprite().PlaySound( "WoodHit" + ( XORRandom(2) + 1 ) + ".ogg" );
	this.getSprite().PlaySound( "hit_wood.ogg" );	
}