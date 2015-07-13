// Station
#include "IslandsCommon.as"
#include "BlockCommon.as"
#include "StationCommon.as";

const int CAPTURE_SECS = 45;	// is faster when more attackers		

void onInit( CBlob@ this )
{
	this.Tag("station"); 

	this.getCurrentScript().tickFrequency = 30;

	this.set_s32("capture time", 0 );
	this.set_s32("respawned time", 0 );
	
	this.set_s32("regenerate time", getGameTime() );
	
	this.set_u8("hall state", HallState::normal );
	
	CSprite@ sprite = this.getSprite();
	sprite.RemoveSpriteLayer("station");
    CSpriteLayer@ layer = sprite.addSpriteLayer( "station", 16, 16 );
    if (layer !is null)
    {
    	layer.SetRelativeZ(0);
    	layer.SetLighting( false );
     	Animation@ anim = layer.addAnimation( "default", 0, false );
        anim.AddFrame(Block::STATION_A1);
        layer.SetAnimation("default");
    }

	//minimap icon
	SetMinimap( this );
}

void onTick( CBlob@ this )
{
	SetMinimap( this ); //needed for under raid check
	
	// capture HALL
	// if( getNet().isServer() )
	// {
		// f32 height = this.getHeight();
		// CMap@ map = this.getMap();
		
		// const u8 state = this.get_u8("hall state" );		
		
		// //scratch vars
		// const u32 gametime = getGameTime();
		// bool raiding = false;
		
		// const bool not_neutral = (this.getTeamNum() <= 10);
		
		// //get relevant blobs
		// CBlob@[] blobsInRadius;
		// if (this.getMap().getBlobsInRadius( this.getPosition(), RAID_RADIUS, @blobsInRadius ))
		// {
			
			// Vec2f pos = this.getPosition();

			// // first check if enemies nearby
			// int attackersCount = 0;
			// int friendlyCount = 0;
			// int friendlyInProximity = 0;
			// int attackerTeam;
			// for (uint i = 0; i < blobsInRadius.length; i++)
			// {
				// CBlob @b = blobsInRadius[i];
			    // if (b !is this && b.hasTag("player"))
				// {
					// bool attacker = (b.getTeamNum() != this.getTeamNum());
					// if(not_neutral && attacker)
					// {
						// raiding = true;
					// }

					// Vec2f bpos = b.getPosition();
					// if ( true )
					// {
						// if (attacker)
						// {
							// attackersCount++;
							// attackerTeam = b.getTeamNum();
						// }
						// else
						// {
							// friendlyCount++;
						// }
					// }

					// if (!attacker)
					// {
						// friendlyInProximity++;
					// }
				// }
			// }
						   
			// if (raiding) //implies not neutral
			// {
				// this.set_u8("hall state", HallState::raid );
				// this.Tag("under raid");
			// }
		// //printf("r friendlyCount " + friendlyCount + " " + this.getTeamNum() );

			// if (attackersCount > 0 && ( friendlyCount == 0 || !not_neutral ) )
			// {

				// const int tickFreq = this.getCurrentScript().tickFrequency;
				// s32 captureTime = this.get_s32("capture time" );		

				// f32 imbalanceFactor = 1.0f;
				// CRules@ rules = getRules();
				// if (rules.exists("team 0 count") && rules.exists("team 1 count"))
				// {
					// const u8 team0 = rules.get_u8("team 0 count");
					// const u8 team1 = rules.get_u8("team 1 count");
					// if (getNet().isClient() && getNet().isServer() && team0 <= 1)
					// {
						// imbalanceFactor = 80.0f;	// super fast capture when singleplayer
					// }
					// else
					// if (this.getTeamNum() == 0 && team1 > 0) {
						// imbalanceFactor = float(team0) / float(team1);
					// }
					// else if (team0 > 0) {
						// imbalanceFactor = float(team1) / float(team0);
					// }
					
				// }

				// // faster capture if no friendly around
				// if (imbalanceFactor < 20.0f && friendlyInProximity == 0) {
					// imbalanceFactor = 6.0f;
				// }
	
				// captureTime += tickFreq * Maths::Max( 1, Maths::Min( Maths::Round(Maths::Sqrt(attackersCount)), 8)) * imbalanceFactor; // the more attackers the faster
				// this.set_s32("capture time", captureTime );
				
				// s32 captureLimit = getCaptureLimit(this);
				// if (!not_neutral) { // immediate capture neutral hall
					// captureLimit = 0;
				// }

				// if (captureTime >= captureLimit)
				// {
					// Capture( this, attackerTeam );
				// }
				// print("captureTime attack " + captureTime + " " + captureLimit );

				// this.Sync("capture time", true );
				// this.Sync("hall state", true );
				// this.Sync("under raid", true );

				// return;

				// // NOTHING BEYOND THIS POINT

			// }
			// else
			// {
				// if (attackersCount > 0)
				// {
					// return;
				// }
			// }
		// }

		// // reduce capture if nothing going on

		// s32 captureTime = this.get_s32("capture time" );
		// if (captureTime > 0)
		// {
			// captureTime -= this.getCurrentScript().tickFrequency;
		// }
		// else
		// {
			// captureTime = 0;
		// }
		
	   // this.set_s32("capture time", captureTime );	   
	   // this.Sync("capture time", true );
	   // this.Sync( "hall state", true );		
	   // this.Sync("under raid", true );
	// }

}

void SetMinimap( CBlob@ this )
{
	// minimap icon
	if (isUnderRaid(this))
	{
		this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 1, Vec2f(16,16));
	}
	else
	{
		this.SetMinimapOutsideBehaviour(CBlob::minimap_arrow);
		if (this.getTeamNum() >= 0 && this.getTeamNum() <= 10)
			this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 2, Vec2f(16,8));
		else
			this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 3, Vec2f(16,8));
	}
	
	this.SetMinimapRenderAlways(true);
}

int getCaptureLimit( CBlob@ this )
{
	return CAPTURE_SECS * (float(getTicksASecond()) / float(this.getCurrentScript().tickFrequency)) * getTicksASecond();
}

void onChangeTeam( CBlob@ this, const int oldTeam )
{
	SetMinimap( this );
	
	if (this.getTeamNum() >= 0 && this.getTeamNum() <= 10)
	{
		Sound::Play("/VehicleCapture");
		this.set_s32("capture time", 0 );
	}
	else
	{
		Sound::Play("/VehicleCapture");
		this.set_s32("capture time", 0 );
	}
	
	Capture( this, this.getTeamNum() );
}

void Capture( CBlob@ this, const int attackerTeam )
{
	Island@ isle = getIsland(this);
	if ( isle is null )
		return;
	
	if ( !isle.isMothership )
	{
		//print (  "setting team for " + isle.owner + "'s " + isle.id + " to " + attackerTeam );
		for ( uint b_iter = 0; b_iter < isle.blocks.length; ++b_iter )
		{
			CBlob@ b = getBlobByNetworkID( isle.blocks[b_iter].blobID );
			if ( b !is null )
			{
				int blockType = b.getSprite().getFrame();
				b.server_setTeamNum( attackerTeam );
				b.getSprite().SetFrame( blockType );
			}
		}
	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	return 0.0f;
}
