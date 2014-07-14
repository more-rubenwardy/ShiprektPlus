//#define SERVER_ONLY
const u16 STARTING_TEAM_BOOTY = 500;
const u8 numTeams = 8;
 
void setStartingBooty(CRules@ this)
{
	print( "** Setting starting Booty" );

	for ( u8 i = 0; i < numTeams; i++ )
		server_setTeamBooty( i, STARTING_TEAM_BOOTY );
		
	for ( u8 p = 0; p < getPlayersCount(); ++p )
		server_setPlayerBooty( getPlayer(p).getUsername(), 0 );
		
	string[] quitList;
	this.get( "quitList", quitList );

	for ( u8 p = 0; p < quitList.length; ++p )
		server_setPlayerBooty( quitList[p], 0 );

	quitList.clear();
	this.set( "quitList", quitList );
}

//team
u16 server_getTeamBooty( u8 teamNum )
{
	if ( getNet().isServer() )
	{
		CRules@ rules = getRules();
		u16 tBooty;
		if ( rules.get( "bootyTeam" + teamNum, tBooty ) )
			return tBooty;
	}
	return 0;
}
 
void server_setTeamBooty( u8 teamNum, u16 booty )
{
	if (getNet().isServer())
	{
		CRules@ rules = getRules();
	
		rules.set( "bootyTeam" + teamNum, booty );
		rules.set_u16( "bootyTeam" + teamNum, booty );
		rules.Sync( "bootyTeam" + teamNum, true );
	}
}

//player
u16 server_getPlayerBooty( string name )
{
	if ( getNet().isServer() )
	{
		CRules@ rules = getRules();
		u16 booty;
		if ( rules.get( "booty" + name, booty ) )
			return booty;
	}
	return 0;
}
 
void server_setPlayerBooty( string name, u16 booty )
{
	if (getNet().isServer())
	{
		CRules@ rules = getRules();
		
		if ( name == "" )
			return;
		
		rules.set( "booty" + name, booty );
		rules.set_u16( "booty" + name, booty );
		rules.Sync( "booty" + name, true );
	}
}