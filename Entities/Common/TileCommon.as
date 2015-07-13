//Tile Common
#include "CustomMap.as";

bool isTouchingLand( Vec2f pos )
{
	CMap@ map = getMap();
	u16 tileType = map.getTile( pos ).type;

	return tileType >= CMap::sand_inland && tileType <= CMap::sand_shore_diagonal_L1;
}

bool isTouchingRock( Vec2f pos )
{
	CMap@ map = getMap();
	u16 tileType = map.getTile( pos ).type;

	return tileType >= CMap::rock_inland && tileType <= CMap::rock_shoal_border_diagonal_L1;
}

bool isTouchingShoal( Vec2f pos )
{
	CMap@ map = getMap();
	u16 tileType = map.getTile( pos ).type;

	return tileType >= CMap::shoal_inland && tileType <= CMap::shoal_shore_diagonal_L1;
}

bool isInWater( Vec2f pos )
{
	CMap@ map = getMap();
	u16 tileType = map.getTile( pos ).type;

	return tileType == 0 || (tileType >= CMap::shoal_inland && tileType <= CMap::shoal_shore_diagonal_L1);
}