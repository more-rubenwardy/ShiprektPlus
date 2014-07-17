//shiprekt HUD
#include "ActorHUDStartPos.as"
#include "TeamColour.as"
#include "IslandsCommon.as"

const int slotsSize = 6;

void onInit( CSprite@ this )
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	this.getBlob().set_u8("gui_HUD_slots_width", slotsSize);
}

void onRender( CSprite@ this )
{
	if (g_videorecording)
		return;

    CBlob@ blob = this.getBlob();
	if ( blob is null ) return;
	CPlayer@ player = blob.getPlayer();  
	if ( player is null ) return;
	
	Vec2f tl = getActorHUDStartPosition(blob, slotsSize);								
	u8 teamNum = player.getTeamNum();

	// draw resources
	u16 pBooty = getRules().get_u16( "booty" + player.getUsername() );
	u16 tBooty = getRules().get_u16( "bootyTeam" + teamNum );
	DrawResourcesOnHUD( blob, tBooty, pBooty, tl, slotsSize-2 );
	
	//is captain?
	Island@ island = getIsland( blob );	
	if ( island !is null )
	{
		CPlayer@ islandOwner = getPlayerByUsername( island.owner );
		if ( islandOwner is null || ( islandOwner !is null && islandOwner.getTeamNum() == teamNum ) )
		{
			if ( player.getUsername() == island.owner )
				GUI::DrawIconByName( "$CAPTAIN$", tl + Vec2f(-17, -12) );
			else if ( island.owner != "" )
				GUI::DrawIconByName( "$CREW$", tl + Vec2f(-15, -11) );
			else
				GUI::DrawIconByName( "$FREEMAN$", tl + Vec2f(-15, -12) );
		}
		else
			GUI::DrawIconByName( "$ASSAIL$", tl + Vec2f(-15, -11) );		
	}
	else	
		GUI::DrawIconByName( "$SEA$", tl + Vec2f(-16, -12) );
		
	//Gameplay Tips
	SColor tipsColor = SColor( 255, 255, 255, 255 );
	//Seat produce couplings help
	if ( blob.isAttached() && blob.get_bool( "drawCouplingsHelp" ) )
		GUI::DrawText( "Couplings ready. Press the Inventory key to take.",  tl + Vec2f(240, 20), tipsColor );
	//Seat couplings help
	if ( blob.isAttached() && blob.get_bool( "drawSeatHelp" ) )
	{
		GUI::DrawText( "PRESS AND HOLD SPACEBAR TO RELEASE COUPLINGS", Vec2f( getScreenWidth()/2 - 150, getScreenHeight()/3 + Maths::Sin( getGameTime()/4.5f ) * 4.5f ), tipsColor );
		GUI::DrawText( "Use left click to release them individually or right click to release all the couplings you've placed", Vec2f( getScreenWidth()/2 - 300, getScreenHeight()/3 + 15 + Maths::Sin( getGameTime()/4.5f ) * 4.5f ), tipsColor );
	}
}

void DrawResourcesOnHUD( CBlob@ this, const u16 tBooty, u16 pBooty , Vec2f tl, const int slot )
{
	GUI::DrawIconByName( "$BOOTY$", tl + Vec2f(16, -12) );
	
	int teamNum = this.getTeamNum();
	
	SColor col;
	if (tBooty < 10)
		col = SColor(255, 255, 0, 0);
	else if (tBooty <= 100)
		col = SColor(255, 255, 255, 0);
	else
		col = SColor(255, 255, 255, 255);
		
	GUI::DrawText( "TEAM BOOTY: ", tl + Vec2f(24 + slot * 10 , 5), getTeamColor( teamNum ) );
	GUI::DrawText( "YOUR BOOTY: ", tl + Vec2f(24 + slot * 10 , 18), SColor(255, 0, 0, 0) );
	GUI::DrawText( "" + tBooty, tl + Vec2f(23 + slot * 34 , 4), col );
	GUI::DrawText( "" + pBooty, tl + Vec2f(23 + slot * 34 , 18), SColor(255, 255, 255, 255) );
}
