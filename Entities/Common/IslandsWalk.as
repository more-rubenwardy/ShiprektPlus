#include "IslandsCommon.as"

void onTick( CBlob@ this )
{	
	Island@ island = getIsland( this );
	if (island !is null)
	{
    	Vec2f pos = this.getPosition();
		Vec2f islandDisplacement = island.pos - island.old_pos;
		f32 islandAngleVariation = island.angle - island.old_angle;
		Vec2f islandToBlob = pos + islandDisplacement - island.pos;
		islandToBlob.RotateBy( islandAngleVariation );
		
		this.setPosition( island.pos + islandToBlob );
	}
}
