#include "Template.as"
#include "TemplateCommon.as"

void onTick( CSprite@ this )
{
	CBlob@ blob = this.getBlob();

	const bool solidGround = blob.isOnGround();

	if( blob.isAttached() )
	{
		this.SetAnimation( "default" );
	}	
	else if( solidGround )
	{
		if( this.isAnimationEnded() )
		{
			if( blob.getShape().vellen > 0.1f ) 
			{
				this.SetAnimation( "walk" );
			}
			else 
			{
				this.SetAnimation("default");
			}
		}
	}
	else
	{
		if( this.isAnimationEnded() )
		{
			if ( blob.getShape().vellen > 0.1f ) 
			{
				this.SetAnimation( "swim" );
			}
			else 
			{
				this.SetAnimation("float");
			}
		}
	}

	this.SetZ( 100.0f );
}