// thanks to Splittingred

#define CLIENT_ONLY

#include "HoverMessage.as";

void onInit( CSprite@ this )
{
	//this.getCurrentScript().runFlags |= Script::tick_myplayer;
}

void onTick( CSprite@ this )
{
	CBlob@ blob = this.getBlob();

    HoverMessage[]@ messages;

    if (blob.get("messages",@messages))
	{
        for (uint i = 0; i < messages.length; i++)
		{
            HoverMessage @message = messages[i];
            message.draw(blob);

            if (message.isExpired()) {
                messages.removeAt(i);
            }
        }	   
    }
}

void onRender( CSprite@ this )
{
	CBlob@ blob = this.getBlob();

	HoverMessage[]@ messages;	
	if (blob.get("messages",@messages))
	{
		for (uint i = 0; i < messages.length; i++)
		{
			HoverMessage @message = messages[i];
			message.draw(blob);
		}
	}
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	if (this.isMyPlayer())
	{
		if (!this.exists("messages")) {
			HoverMessage[] messages;
			this.set( "messages", messages);
		}
	}
}