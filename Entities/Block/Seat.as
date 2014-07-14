#include "IslandsCommon.as"
#include "BlockCommon.as"
#include "BlockProduction.as"
#include "PropellerForceCommon.as"

const u16 COUPLINGS_COOLDOWN = 30*30;

void onInit( CBlob@ this )
{
	//Set Owner/couplingsCooldown
	if ( getNet().isServer() )
	{
		this.set( "couplingCooldown", 0 );
		
		CBlob@ owner = getBlobByNetworkID( this.get_u16( "ownerID" ) );    
		if ( owner !is null )
		{
			this.set_string( "playerOwner", owner.getPlayer().getUsername() );
			this.Sync( "playerOwner", true );
		}
	}
	this.set_string("seat label", "Steering seat");
	this.set_bool( "canProduceCoupling", false );
	this.set_u8("seat icon", 7);
	this.Tag("seat");
}

void onTick( CBlob@ this )
{	
	if (this.getShape().getVars().customData <= 0)
		return;	


	//clear ownership: check if owner is connected & same team
	string seatOwner = this.get_string( "playerOwner" );
	CPlayer@ ownerPlayer = getPlayerByUsername( seatOwner );
	if ( seatOwner != "" && ( ownerPlayer is null || ownerPlayer.getTeamNum() != this.getTeamNum() ) )
	{
		//print( "** Clearing ownership: " + seatOwner + ( ownerPlayer is null ? " left" : " changed team" ) );
		this.set_string( "playerOwner", "" );
		return;
	}
	
	AttachmentPoint@ seat = this.getAttachmentPoint(0);
	CBlob@ occupier = seat.getOccupied();
	
	if (occupier !is null)
	{
		CPlayer@ player = occupier.getPlayer();
		Island@ island = getIsland(this.getShape().getVars().customData);
		
		const f32 angle = this.getAngleDegrees();
		occupier.setAngleDegrees( angle );
				
		if ( island is null || player is null )
			return;
				
		CHUD@ HUD = getHUD();
		u32 gameTime = getGameTime();
		string occupierName = player.getUsername();
		u8 occupierTeam = occupier.getTeamNum();
		const bool isCaptain = island.owner == occupierName;
		Vec2f aim = occupier.getAimPos() - this.getPosition();//relative to seat
			
		const bool up = occupier.isKeyPressed( key_up );
		const bool left = occupier.isKeyPressed( key_left );
		const bool right = occupier.isKeyPressed( key_right );
		const bool down = occupier.isKeyPressed( key_down );
		const bool space = occupier.isKeyPressed( key_action3 );	
		const bool inv = occupier.isKeyPressed( key_inventory );	
		const bool left_click = occupier.isKeyPressed( key_action1 );	
		const bool right_click = occupier.isKeyPressed( key_action2 );	
				
		//show help tip
		occupier.set_bool( "drawSeatHelp", ( island.owner != "" && !isCaptain && occupierName == seatOwner ) );
		
		//couplings help tip
		occupier.set_bool( "drawCouplingsHelp", this.get_bool( "canProduceCoupling" ) );
		
		// gather propellers, couplings and aCannons
		CBlob@[] left_propellers;
		CBlob@[] right_propellers;
		CBlob@[] up_propellers;
		CBlob@[] down_propellers;
		CBlob@[] couplings;
		CBlob@[] guns;					

		for (uint b_iter = 0; b_iter < island.blocks.length; ++b_iter)
		{
			IslandBlock@ isle_block = island.blocks[b_iter];
			if(isle_block is null) continue;

			CBlob@ block = getBlobByNetworkID( isle_block.blobID );
			if(block is null) continue;
			
			//gather couplings
			if(block.hasTag("coupling") && !block.hasTag("_coupling_hitspace"))
				couplings.push_back(block);
				
			if ( getNet().isServer() )//clients don't need these
			{
				//gather propellers (and turn them off) only if occupier is owner OR enemy
				if ( block.hasTag("propeller") && ( isCaptain || occupierTeam != this.getTeamNum() ) )
				{
					Vec2f _veltemp, velNorm;
					float angleVel;
					PropellerForces(block, island, 1.0f, _veltemp, velNorm, angleVel);

					velNorm.RotateBy(-angle);
					
					const float angleLimit = 0.05f;
					const float forceLimit = 0.01f;
					const float forceLimit_side = 0.2f;

					if (angleVel < -angleLimit ||
						(velNorm.y < -forceLimit_side && angleVel < angleLimit) )
					{
						right_propellers.push_back(block);
					}
					else if (angleVel > angleLimit ||
						(velNorm.y > forceLimit_side && angleVel > -angleLimit) )
					{
						left_propellers.push_back(block);
					}

					if (velNorm.x > forceLimit)
					{
						down_propellers.push_back(block);
					}
					else if (velNorm.x < -forceLimit)
					{
						up_propellers.push_back(block);
					}

					block.set_f32("power", 0);					
				}
				
				//gather aCannons
				if(block.hasTag("fixed_gun"))
				{
					//add if low enough angle range
					Vec2f acFacing = Vec2f(1, 0).RotateBy( block.getAngleDegrees() );
					if ( Maths::Abs( acFacing.AngleWith( aim ) ) < 40 )
						guns.push_back(block);
				}
			}
		}
		
		//Show coupling buttons on spacebar down
		if ( occupier.isKeyJustPressed( key_action3 ) )
			for (uint i = 0; i < couplings.length; ++i)
				if ( isCaptain || couplings[i].get_string( "playerOwner" ) == occupierName )
				{
					CButton@ button = occupier.CreateGenericButton( 1, Vec2f(0.0f, 0.0f), couplings[i], couplings[i].getCommandID("decouple"), "Decouple" );
					if ( button !is null )
						button.enableRadius = 999.0f;
				}

		//Kill coupling buttons on spacebar up
		if ( occupier.isKeyJustReleased( key_action3 ) )
			occupier.ClearButtons();

		//Release all couplings on spacebar + right click
		if ( space && HUD.hasButtons() && right_click )
			for ( uint i = 0; i < couplings.length; ++i )
				if ( couplings[i].get_string( "playerOwner" ) == occupierName )
				{
					couplings[i].Tag("_coupling_hitspace");
					couplings[i].SendCommand(couplings[i].getCommandID("decouple"));
				}
			
		//******svOnly below	
		if ( !getNet().isServer() )
			return;

		//Produce coupling
		u32 couplingCooldown;
		this.get( "couplingCooldown", couplingCooldown );
		bool canProduceCoupling = gameTime > couplingCooldown;
		this.set_bool( "canProduceCoupling", canProduceCoupling );
		this.Sync( "canProduceCoupling", true );
		
		if ( inv && canProduceCoupling )
		{
			this.set( "couplingCooldown", gameTime + COUPLINGS_COOLDOWN );
			ProduceBlock( getRules(), occupier, Block::COUPLING, 2 );
		}
		
		//Re-set empty seat's owner
		if ( seatOwner == "" )
		{
			string newOwner = island.owner != "" ? island.owner : occupierName;//if the island has an owner (there are other seats), set it to the seat owner. otherwise to the seat occupier
			//print( "** Re-setting seat owner: " + newOwner );
			this.set_string( "playerOwner", occupierName );
			this.Sync( "playerOwner", true );
			if ( island.owner == "" )//there is only 1 seat
				this.server_setTeamNum( occupierTeam );
		} 		
			
		//only ship 'captain' OR enemy can steer /direct fire
		if ( isCaptain || occupierTeam != this.getTeamNum() )
		{
			//propellers
			const f32 power = -1;
			
			if (left)
				for (uint i = 0; i < left_propellers.length; ++i)
				{
					left_propellers[i].set_f32("power", power);				
					left_propellers[i].set_u32( "onTime", gameTime );
				}
				
			if (right)
				for (uint i = 0; i < right_propellers.length; ++i)
				{
					right_propellers[i].set_f32("power", power);	
					right_propellers[i].set_u32( "onTime", gameTime );
				}
				
			if (up)
				for (uint i = 0; i < up_propellers.length; ++i)
				{
					up_propellers[i].set_f32("power", power);
					up_propellers[i].set_u32( "onTime", gameTime );
				}
				
			if (down)
				for (uint i = 0; i < down_propellers.length; ++i)
				{
					down_propellers[i].set_f32("power", power);
					down_propellers[i].set_u32( "onTime", gameTime );
				}	
			
			//reverse power
			const f32 reverse_power = 0.1f;

			if (left && !right && !up && !down)
			{
				for (uint i = 0; i < left_propellers.length; ++i)
				{
					left_propellers[i].set_f32("power", power);
				}
				for (uint i = 0; i < right_propellers.length; ++i)
				{
					right_propellers[i].set_f32("power", reverse_power);
				}	
			}
			if (right && !left && !up && !down)
			{
				for (uint i = 0; i < right_propellers.length; ++i)
				{
					right_propellers[i].set_f32("power", power);
				}	
				for (uint i = 0; i < left_propellers.length; ++i)
				{
					left_propellers[i].set_f32("power", reverse_power);
				}	
			}
			if (up && !right && !left && !down)
			{
				for (uint i = 0; i < up_propellers.length; ++i)
				{
					up_propellers[i].set_f32("power", power);
				}	
				for (uint i = 0; i < down_propellers.length; ++i)
				{
					down_propellers[i].set_f32("power", reverse_power);
				}	
			}
			if (down && !right && !up && !left)
			{
				for (uint i = 0; i < down_propellers.length; ++i)
				{
					down_propellers[i].set_f32("power", power);
				}	
				for (uint i = 0; i < up_propellers.length; ++i)
				{
					up_propellers[i].set_f32("power", reverse_power);
				}	
			}
				
			//shoot guns on left click
			if ( !space && left_click )
				for (uint i = 0; i < guns.length; ++i)
				{
					CBitStream bs;
					bs.write_u8( occupierTeam );
					guns[i].SendCommand(guns[i].getCommandID("fire"), bs);
				}
		}
	}
}