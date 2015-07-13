// force barrier around edge of map
#include "IslandsCommon.as"
#include "BlockCommon.as"
#include "PropellerForceCommon.as"

const f32 BARRIER_PERCENT = 0.175f;
const f32 BARRIER_FORCE = 1.0f;
bool barrier_set = false;

void onTick( CRules@ this )
{
	if(!barrier_set)
	{
		barrier_set = true;
		addBarrier();
	}

	CMap@ map = getMap();
	bool isServer = getNet().isServer();
	CMap::Sector@ top = map.getSector( "top barrier" );
	CMap::Sector@ bottom = map.getSector( "bottom barrier" );
	CMap::Sector@ left = map.getSector( "left barrier" );
	CMap::Sector@ right = map.getSector( "right barrier" );
	
	CBlob@[] blobsInTopBox;
	if (map.getBlobsInBox( top.upperleft, top.lowerright, @blobsInTopBox ))
	{
		for (uint i = 0; i < blobsInTopBox.length; i++)
		{
			CBlob @b = blobsInTopBox[i];
			Island@ island = getIsland(b.getShape().getVars().customData);
			if ( island !is null && ( isServer || island.vel.LengthSquared() > 0 ) )
			{
				island.vel = Vec2f(island.vel.x ,BARRIER_FORCE);
				server_turnOffPropellers( island );
			}
			
			if (b.hasTag( "rocket" ))
				b.server_Die();
		}
	}
	CBlob@[] blobsInBottomBox;
	if (map.getBlobsInBox( bottom.upperleft, bottom.lowerright, @blobsInBottomBox ))
	{
		for (uint i = 0; i < blobsInBottomBox.length; i++)
		{
			CBlob @b = blobsInBottomBox[i];
			Island@ island = getIsland(b.getShape().getVars().customData);
			
			if ( island !is null && ( isServer || island.vel.LengthSquared() > 0 ) )
			{
				island.vel = Vec2f(island.vel.x ,-BARRIER_FORCE);
				server_turnOffPropellers( island );
			}

			if (b.hasTag( "rocket" ))
				b.server_Die();
		}
	}
	CBlob@[] blobsInLeftBox;
	if (map.getBlobsInBox( left.upperleft, left.lowerright, @blobsInLeftBox ))
	{
		for (uint i = 0; i < blobsInLeftBox.length; i++)
		{
			CBlob @b = blobsInLeftBox[i];
			Island@ island = getIsland(b.getShape().getVars().customData);
			if ( island !is null && ( isServer || island.vel.LengthSquared() > 0 ) )
			{
				island.vel = Vec2f(BARRIER_FORCE ,island.vel.y);
				server_turnOffPropellers( island );
			}
			
			if (b.hasTag( "rocket" ))
				b.server_Die();
		}
	}
	CBlob@[] blobsInRightBox;
	if (map.getBlobsInBox( right.upperleft, right.lowerright, @blobsInRightBox ))
	{
		for (uint i = 0; i < blobsInRightBox.length; i++)
		{
			CBlob @b = blobsInRightBox[i];
			Island@ island = getIsland(b.getShape().getVars().customData);
			if ( island !is null && ( isServer || island.vel.LengthSquared() > 0 ) )
			{
				island.vel = Vec2f(-BARRIER_FORCE, island.vel.y);
				server_turnOffPropellers( island );
			}
			
			if (b.hasTag( "rocket" ))
				b.server_Die();
		}
	}
}

void onRestart(CRules@ this)
{
	barrier_set = false;
}

void getTopBarrierPositions( CMap@ map, f32 &out top_x1, f32 &out top_x2, f32 &out top_y1, f32 &out top_y2 )
{
	const f32 mapWidth = map.tilemapwidth * map.tilesize;
	const f32 mapHeight = map.tilemapheight * map.tilesize;
	const f32 barrierWidth = 1*map.tilesize;
	
	top_x1 = 0;
	top_x2 = mapWidth - 1*map.tilesize;
	top_y1 = 0;
	top_y2 = barrierWidth;
}

void getBottomBarrierPositions( CMap@ map, f32 &out bottom_x1, f32 &out bottom_x2, f32 &out bottom_y1, f32 &out bottom_y2 )
{
	const f32 mapWidth = map.tilemapwidth * map.tilesize;
	const f32 mapHeight = map.tilemapheight * map.tilesize;
	const f32 barrierWidth = 1*map.tilesize;
	
	bottom_x1 = 0;
	bottom_x2 = mapWidth - 1*map.tilesize;
	bottom_y1 = mapHeight - barrierWidth;
	bottom_y2 = mapHeight;
}

void getLeftBarrierPositions( CMap@ map, f32 &out left_x1, f32 &out left_x2, f32 &out left_y1, f32 &out left_y2 )
{
	const f32 mapWidth = map.tilemapwidth * map.tilesize;
	const f32 mapHeight = map.tilemapheight * map.tilesize;
	const f32 barrierWidth = 1*map.tilesize;
	
	left_x1 = 0;
	left_x2 = barrierWidth;
	left_y1 = 0;
	left_y2 = mapHeight;
}

void getRightBarrierPositions( CMap@ map, f32 &out right_x1, f32 &out right_x2, f32 &out right_y1, f32 &out right_y2 )
{
	const f32 mapWidth = map.tilemapwidth * map.tilesize;
	const f32 mapHeight = map.tilemapheight * map.tilesize;
	const f32 barrierWidth = 1*map.tilesize;
	
	right_x1 = mapWidth - barrierWidth - 1*map.tilesize;
	right_x2 = mapWidth - 1*map.tilesize;
	right_y1 = 0;
	right_y2 = mapHeight;
}

/**
 * Adding the barrier sector to the map
 */

void addBarrier()
{
	CMap@ map = getMap();
	
	f32 top_x1, top_x2, top_y1, top_y2;
	getTopBarrierPositions( map, top_x1, top_x2, top_y1, top_y2 );	
	Vec2f top_ul(top_x1,top_y1);
	Vec2f top_lr(top_x2,top_y2);	
	if(map.getSectorAtPosition( (top_ul + top_lr) * 0.5, "top barrier" ) is null)
		map.server_AddSector( Vec2f(top_x1, top_y1), Vec2f(top_x2, top_y2), "top barrier" );
		
	f32 bottom_x1, bottom_x2, bottom_y1, bottom_y2;
	getBottomBarrierPositions( map, bottom_x1, bottom_x2, bottom_y1, bottom_y2 );	
	Vec2f bottom_ul(bottom_x1,bottom_y1);
	Vec2f bottom_lr(bottom_x2,bottom_y2);	
	if(map.getSectorAtPosition( (bottom_ul + bottom_lr) * 0.5, "bottom barrier" ) is null)
	map.server_AddSector( Vec2f(bottom_x1, bottom_y1), Vec2f(bottom_x2, bottom_y2), "bottom barrier" );
	
	f32 left_x1, left_x2, left_y1, left_y2;
	getLeftBarrierPositions( map, left_x1, left_x2, left_y1, left_y2 );	
	Vec2f left_ul(left_x1,left_y1);
	Vec2f left_lr(left_x2,left_y2);	
	if(map.getSectorAtPosition( (left_ul + left_lr) * 0.5, "left barrier" ) is null)
		map.server_AddSector( Vec2f(left_x1, left_y1), Vec2f(left_x2, left_y2), "left barrier" );
	
	f32 right_x1, right_x2, right_y1, right_y2;
	getRightBarrierPositions( map, right_x1, right_x2, right_y1, right_y2 );	
	Vec2f right_ul(right_x1,right_y1);
	Vec2f right_lr(right_x2,right_y2);	
	if(map.getSectorAtPosition( (right_ul + right_lr) * 0.5, "right barrier" ) is null)
		map.server_AddSector( Vec2f(right_x1, right_y1), Vec2f(right_x2, right_y2), "right barrier" );
}

void server_turnOffPropellers( Island@ island )
{
	if ( !getNet().isServer() ) return;
	
	for (uint b_iter = 0; b_iter < island.blocks.length; ++b_iter)
	{
		IslandBlock@ isle_block = island.blocks[b_iter];
		if(isle_block is null) continue;

		CBlob@ block = getBlobByNetworkID( isle_block.blobID );
		if(block is null) continue;
		
		//gather props
		if( block.hasTag( "propeller" ) )
			block.set_f32( "power", 0 );
	}
}