namespace Human
{
	const float walkSpeed = 1.0f;
	const float swimSlow = 0.4f;
};

// helper functions

namespace Human
{
	bool isHoldingBlocks( CBlob@ this )
	{
	   	CBlob@[]@ blob_blocks;
	    this.get( "blocks", @blob_blocks );
	    return blob_blocks.length > 0;
	}
	void clearHeldBlocks( CBlob@ this )
	{
		CBlob@[]@ blocks;
		if (this.get( "blocks", @blocks ))                 
		{
			for (uint i = 0; i < blocks.length; ++i)
			{
				CBlob@ b = blocks[i];
				b.server_Die();
			}
			blocks.clear();
		} 
	}
}