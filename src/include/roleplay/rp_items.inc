/** Double-include prevention */
#if defined _rp_items_included_
  #endinput
#endif
#define _rp_items_included_

native rp_setItem(Client,Item,Amount);
native rp_addItem(Client,Item,Amount);
native rp_remItem(Client,Item,Amount);
native rp_checkItem(Client,Item);
native rp_setItemMenuTarget(Client, Ent);
native rp_CommandPickUpItem(Client, Ent);

native rp_itemAction(Item);
native rp_itemVar(Item,String:Buffer[]);
native rp_itemCost(Item);
native rp_itemName(Item,String:Buffer[]);
native rp_SetIsGiving(Client, bool:give);
native rp_ShowInvetory(Client, start);

native rp_getPvP(Client);
native rp_setPvP(Client, Amount);



