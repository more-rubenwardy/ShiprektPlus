namespace Block
{
	const int size = 8;

	enum Type 
	{
		PLATFORM = 0,
		PLATFORM2 = 1,
		SOLID = 4,
		BOMB = 19,
		BOMB_A1 = 20,
		BOMB_A2 = 21,

		TURRET = 22,
		TURRET_A1 = 11,
		TURRET_A2 = 12,
		
		COUPLING = 35,

		PROPELLER = 16,
		PROPELLER_A1 = 32,
		PROPELLER_A2 = 33,
		
		SEAT = 23,

		MOTHERSHIP1 = 80,
		MOTHERSHIP2 = 81,
		MOTHERSHIP3 = 82,
		MOTHERSHIP4 = 96,
		MOTHERSHIP5 = 97,
		MOTHERSHIP6 = 98,
		MOTHERSHIP7 = 112,
		MOTHERSHIP8 = 113,
		MOTHERSHIP9 = 114,
		
		AUTOCANNON_F = 25,
		AUTOCANNON_F1 = 27,
		AUTOCANNON_F2 = 28,
		AUTOCANNON_F3 = 29,
	};
					
	shared class Weights
	{
		f32 mothership;
		f32 wood;
		f32 solid;
		f32 propeller;
		f32 seat;
		f32 cannon;
		f32 aCannon;
		f32 bomb;
		f32 coupling;
	}
	
	bool queryWeights( CRules@ this )
	{		
		ConfigFile cfg;
		if ( !cfg.loadFile( "SHRKTVars.cfg" ) ) 
			return false;
		
		print( "** Getting Weights from cfg" );
		Block::Weights w;

		w.mothership = cfg.read_f32( "w_mothership" );
		w.wood = cfg.read_f32( "w_wood" );
		w.solid = cfg.read_f32( "w_solid" );
		w.propeller = cfg.read_f32( "w_propeller" );
		w.seat = cfg.read_f32( "w_seat" );
		w.cannon = cfg.read_f32( "w_cannon" );
		w.aCannon = cfg.read_f32( "w_aCannon" );
		w.bomb = cfg.read_f32( "w_bomb" );
		w.coupling = cfg.read_f32( "w_coupling" );

		this.set( "weights", w );
		return true;
	}
	
	Weights@ getWeights( CRules@ this )
	{
		Block::Weights@ w;
		this.get( "weights", @w );
		return w;
	}
	
	shared class Costs
	{
		u16 wood;
		u16 solid;
		u16 propeller;
		u16 seat;
		u16 cannon;
		u16 aCannon;
		u16 bomb;
		u16 coupling;
	}
	
	bool queryCosts( CRules@ this )
	{		
		ConfigFile cfg;
		if ( !cfg.loadFile( "SHRKTVars.cfg" ) ) 
			return false;
		
		print( "** Getting Costs from cfg" );
		Block::Costs c;

		c.wood = cfg.read_u16( "cost_wood" );
		c.solid = cfg.read_u16( "cost_solid" );
		c.propeller = cfg.read_u16( "cost_propeller" );
		c.seat = cfg.read_u16( "cost_seat" );
		c.cannon = cfg.read_u16( "cost_cannon" );
		c.aCannon = cfg.read_u16( "cost_aCannon" );
		c.bomb = cfg.read_u16( "cost_bomb" );
		c.coupling = cfg.read_u16( "cost_coupling" );

		this.set( "costs", c );
		return true;
	}
	
	Costs@ getCosts( CRules@ this )
	{
		Block::Costs@ c;
		this.get( "costs", @c );
		return c;
	}
	
	int minimapframe(Type block)
	{
		int frame;
		switch(block)
		{
			case SOLID:
			case PROPELLER:

				frame = 1;
				break;

			case MOTHERSHIP5:
				frame = 2;
				break;

			case MOTHERSHIP1:
			case MOTHERSHIP2:
			case MOTHERSHIP3:
			case MOTHERSHIP4:
			case MOTHERSHIP6:
			case MOTHERSHIP7:
			case MOTHERSHIP8:
			case MOTHERSHIP9:

				frame = 3;
				break;

			default:
				frame = 0;
				break;
		}
		return frame;
	}

	bool isSolid( const uint blockType )
	{ 
		return (blockType == Block::SOLID || blockType == Block::PROPELLER);
	}

	bool isCore( const uint blockType )
	{ 
		return (blockType >= Block::MOTHERSHIP1 && blockType <= Block::MOTHERSHIP9);
	}
	
	bool isCannon( const uint blockType )
	{ 
		return (blockType == 11 || blockType == 12 || blockType == 22);
	}
	
	bool isA_Cannon( const uint blockType )
	{ 
		return (blockType == 25 || blockType == 27 || blockType == 28 || blockType == 29);
	}
	
	bool isPropeller( const uint blockType )
	{ 
		return (blockType == 16 || blockType == 32 || blockType == 33);
	}

	bool isBomb( const uint blockType )
	{ 
		return (blockType >= 19 && blockType <= 21);
	}

	bool isType( CBlob@ blob, const uint blockType )
	{ 
		return (blob.getSprite().getFrame() == blockType);
	}	

	uint getType( CBlob@ blob )
	{ 
		return blob.getSprite().getFrame();
	}		

	f32 getWeight ( const uint blockType )
	{	
		CRules@ rules = getRules();
		
		Weights@ w = Block::getWeights( rules );
		
		if ( w is null )
		{
			warn( "** Couldn't get Weights!" );
			return 0;
		}
		
		switch(blockType)		
		{
			case Block::PROPELLER:
				return w.propeller;
			break;
			case Block::SEAT:
				return w.seat;
			break;
			case Block::BOMB:
				return w.bomb;
			break;			
			case Block::TURRET:
				return w.cannon;
			break;
			case Block::AUTOCANNON_F:
				return w.aCannon;
			break;
			case Block::COUPLING:
				return w.coupling;
			break;
			case Block::PLATFORM:
				return w.wood;
			break;
			case Block::SOLID:
				return w.solid;
			break;
		}
	
		return blockType == MOTHERSHIP5 ? w.mothership : 1.0f;//MOTHERSHIP5 is the center block
	}

	f32 getWeight ( CBlob@ blob )
	{
		return getWeight( getType(blob) );
	}
	
	const f32 BUTTON_RADIUS_FLOOR = 6;
	const f32 BUTTON_RADIUS_SOLID = 10;

};