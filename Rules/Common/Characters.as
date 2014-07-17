namespace Characters
{
	bool isCharacter( CBlob@ this )
	{
		if( this is null )
			return false;
	
		if( this.getName() == "human" )
			return true;
			
		if( this.getName() == "template" )
			return true;
			
		return false;
	}
};