int time;

void onInit( CRules@ this )
{
	this.addCommandID( "help" );
	this.addCommandID( "advHelp" );
	time = 0;
}

void onTick( CRules@ this )
{
	time++;
}

void onRender( CRules@ this )
{
    const int endTime1 = getTicksASecond() * 7;
	const int endTime2 = getTicksASecond() * 25;
	const int endTime3 = getTicksASecond() * 50;
	const int advHelp = getTicksASecond() * 1800;

	bool draw = false;
	Vec2f ul, lr;
	string text = "";

	ul = Vec2f( 30, 3*getScreenHeight()/4 );

    if (time < endTime1) {
        text =	"Welcome to Shiprekt Plus! A mod by Strathos and Chrispin based on the original Shiprekt.";
        
		Vec2f size;
		GUI::GetTextDimensions(text, size);
		lr = ul + size;
		draw = true;
    }
	else if (time < endTime2) {
		text =  "How to Play:\n\n"+
				" * Get ship parts from your Mothership Core (spawn).\n"+
				" * Xs mark Shiprekts. Get near them to collect Booty.\n"+
				" * Gold Xs can only be collected by Motherships.\n"+
				" * The bigger the X, the more Booty you get.\n"+
				" * Protect your Mothership Core. Don't let enemies use your seats!\n"+
				" * Destroying enemy Motherships grants your team Booty.\n"+
				" * All players on the final surviving team get points - so play nice!\n";
		Vec2f size;
		GUI::GetTextDimensions(text, size);
		lr = ul + size;
		lr.y -= 32.0f;
		draw = true;
	}
	else if (time < endTime3) {
		text =  " * Each ship has a Captain. Only the captain can pilot the ship.\n" +
				" * The first to place a seat in a ship becomes the Captain.\n"+
				" * Use couplings as a 'dock' to build new ships.\n" +
				" * When couplings bump with each other, they merge!\n\n"+
				" * [ SPACE ] rotates blocks while building or use to release couplings when sitting.\n"+
				" * [ LMB ] punch when standing or fire AutoCannons when sitting.\n"+
				" * [ RMB ] hold to fire pistol.\n"+
				" * [ SCROLL ] zoom in/out.\n\n"+
				" * Write !help to show this dialog again, or !advhelp for more info on Block Mechanics.\n";
		Vec2f size;
		GUI::GetTextDimensions(text, size);
		lr = ul + size;
		lr.y -= 48.0f;
		draw = true;
	}
	else if (time > advHelp && time < advHelp + getTicksASecond() * 40) {
		text =  " * Advanced Help:\n\n" +
				" * Each block has a different weight. The heavier, the more they slow you down!\n"+
				" * Cannons are very heavy, so use them sparingly on small ships.\n"+
				" * Engines are a lot weaker than Solid blocks, so be sure to protect them!\n"+
				" * You can make torpedoes with a bomb, a coupling and a propeller..\n" +
				" * join the propeller and bomb to your ship with a coupling..\n"+
				" * then press Space while accelerating in the direction the propeller points.\n\n"+
				" * Good luck!\n";
		Vec2f size;
		GUI::GetTextDimensions(text, size);
		lr = ul + size;
		lr.y -= 48.0f;
		draw = true;
	}
	
	if(draw)
	{
		f32 wave = Maths::Sin(getGameTime() / 15.0f) * 2.0f;
		ul.y += wave;
		lr.y += wave;
		GUI::DrawButtonPressed( ul - Vec2f(10,10), lr + Vec2f(10,10) );
		GUI::DrawText( text, ul, SColor(0xffffffff) );
	}
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
	CPlayer@ player = getLocalPlayer();
	if ( player is null ) return;
	
	if ( cmd == this.getCommandID("help") && params.read_u16() == player.getNetworkID() )
		time = getTicksASecond() * 7;
	if ( cmd == this.getCommandID("advHelp") && params.read_u16() == player.getNetworkID() )
		time = getTicksASecond() * 1800;
}

bool onServerProcessChat( CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player )
{
	if ( player is null )
		return true;
	
	if ( text_in == "!help" )
	{
		CBitStream params;
		params.write_u16( player.getNetworkID() );
        this.SendCommand( this.getCommandID( "help" ), params );
	}	
	if ( text_in == "!advhelp" )
	{
		CBitStream params;
		params.write_u16( player.getNetworkID() );
        this.SendCommand( this.getCommandID( "advHelp" ), params );
	}

	
	return true;
}