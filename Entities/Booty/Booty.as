//#define SERVER_ONLY
const u16 STARTING_TEAM_BOOTY = 500;
 
void SetupBooty( CRules@ this )
{
	if ( getNet().isServer() )
	{
		dictionary@ current_bSet;
		if ( !this.get( "BootySet", @current_bSet ) )
		{
			print( "** Setting Booty Dict" );
			dictionary bSet;
			this.set( "BootySet", bSet );
		}
	}
}
 
dictionary@ getBootySet()
{
	dictionary@ bSet;
	getRules().get( "BootySet", @bSet );
	
	return bSet;
}

void setStartingBooty( CRules@ this )
{
	//reset properties
	dictionary@ bootySet = getBootySet();
	string[]@ bKeys = bootySet.getKeys();
	for ( u8 i = 0; i < bKeys.length; i++ )
		this.set_u16( bKeys[i], 0 );
	
	bootySet.deleteAll();//clear booty. note: sometimes crashes server?
	
	u8 teamsNum = this.getTeamsNum();
	print( "** Setting Starting Booty for " + teamsNum + " teams" );
	for ( u8 i = 0; i < teamsNum; i++ )
		server_setTeamBooty( i, STARTING_TEAM_BOOTY );
		
	//just so it syncs with (connected) clients
	for ( u8 p = 0; p < getPlayersCount(); ++p )
		server_setPlayerBooty( getPlayer(p).getUsername(), 0 );
}

//team
u16 server_getTeamBooty( u8 teamNum )
{
	if ( getNet().isServer() )
	{
		u16 tBooty;
		if ( getBootySet().get( "bootyTeam" + teamNum, tBooty ) )
			return tBooty;
	}
	return 0;
}
 
void server_setTeamBooty( u8 teamNum, u16 booty )
{
	if (getNet().isServer())
	{
		getBootySet().set( "bootyTeam" + teamNum, booty );
		//sync to clients
		CRules@ rules = getRules();
		rules.set_u16( "bootyTeam" + teamNum, booty );
		rules.Sync( "bootyTeam" + teamNum, true );
	}
}

//player
u16 server_getPlayerBooty( string name )
{
	if ( getNet().isServer() )
	{
		u16 booty;
		if ( getBootySet().get( "booty" + name, booty ) )
			return booty;
	}
	return 0;
}
 
void server_setPlayerBooty( string name, u16 booty )
{
	if (getNet().isServer())
	{
		getBootySet().set( "booty" + name, booty );
		//sync to clients
		CRules@ rules = getRules();
		rules.set_u16( "booty" + name, booty );
		rules.Sync( "booty" + name, true );
	}
}