#include "Human.as"
#include "HumanCommon.as"

Random _punchr(0xfecc);

void onTick( CSprite@ this )
{
	CBlob@ blob = this.getBlob();

	const bool solidGround = blob.isOnGround();

	if (blob.isAttached())
	{
		this.SetAnimation("default");
	}	
	else if(solidGround)
	{
		if (this.isAnimationEnded() ||
			!(this.isAnimation("punch1") || this.isAnimation("punch2") || this.isAnimation("shoot")) )
		{
			if (blob.isKeyPressed( key_action2 ) && canShoot( blob ) && !blob.isKeyPressed( key_action1 ))
			{
				this.SetAnimation("shoot");
			}
			else if (blob.isKeyPressed( key_action1 ) )//todo: && canPunch( blob ))
			{
				this.SetAnimation("punch"+(_punchr.NextRanged(2)+1));
			}
			else if (blob.getShape().vellen > 0.1f) {
				this.SetAnimation("walk");
			}
			else {
				this.SetAnimation("default");
			}
		}
	}
	else //in water
	{
		if (this.isAnimationEnded() ||
			!(this.isAnimation("shoot")) )
		{
			if (blob.getShape().vellen > 0.1f) {
				this.SetAnimation("swim");
			}
			else if (blob.isKeyPressed( key_action2 ) && canShoot( blob )){
					this.SetAnimation("shoot");
			}
			else {
				this.SetAnimation("float");
			}
		}
	}

	this.SetZ( 100.0f );
}