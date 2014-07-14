#include "BlockCommon.as";

void onInit( CBlob@ this )
{
	//Set Owner
	if ( getNet().isServer() )
	{
		CBlob@ owner = getBlobByNetworkID( this.get_u16( "ownerID" ) );    
		if ( owner !is null )
		{
			this.set_string( "playerOwner", owner.getPlayer().getUsername() );
			this.Sync( "playerOwner", true );
		}
	}
    this.addCommandID("decouple");
    this.Tag("coupling");
	this.server_SetHealth( 1.5f );
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{   
	int mycolour = this.getShape().getVars().customData;
	if(mycolour <= 0)
        return;
	
	//only owners can directly destroy the coupling
    if( this.getDistanceTo(caller) < Block::BUTTON_RADIUS_FLOOR && caller.getPlayer().getUsername() == this.get_string( "playerOwner" ) )
		caller.CreateGenericButton( 1, Vec2f(0.0f, 0.0f), this, this.getCommandID("decouple"), "Decouple" );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("decouple"))
    {
        this.server_Die();
    }
}