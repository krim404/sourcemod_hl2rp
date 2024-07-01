/** Double-include prevention */
#if defined _rp_doors_included_
  #endinput
#endif
#define _rp_doors_included_

native rp_addLock(Client,Ent);
native rp_breakLock(Client,Ent);
native rp_getLock(Ent);
native rp_getLocked(Ent);
native rp_SetDoorStatus(Ent, What);
native rp_getDoorOwner(Client,Ent);
native rp_setDoorOwner(Client,Ent);