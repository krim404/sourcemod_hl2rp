/** Double-include prevention */
#if defined _rp_main_included_
  #endinput
#endif
#define _rp_main_included_


native rp_cuff(Client);
native rp_uncuff(Client);
native bool:rp_iscuff(Client);

native rp_crime(Client,Crime);
native rp_uncrime(Client,Crime);
native rp_getCrime(Client);
native rp_iscop(Client);
native rp_setCop(Client,CopLevel);
native rp_setCrime(Client,Amount);

native rp_setStr(Client,Str);
native rp_getStr(Client);
native rp_setTmpStr(Client,Str);
native rp_getTmpStr(Client);
native rp_setWgt(Client,Wgt);
native rp_getWgt(Client);
native rp_setTmpWgt(Client,Wgt);
native rp_getTmpWgt(Client);
native rp_setInt(Client,Wgt);
native rp_getInt(Client);
native rp_setTmpInt(Client,Wgt);
native rp_getTmpInt(Client);
native rp_setDex(Client,Dex);
native rp_getDex(Client);
native rp_setTmpDex(Client,Dex);
native rp_getTmpDex(Client);
native rp_setSpd(Client,Spd);
native rp_setTmpSpd(Client,Spd);
native rp_getTmpSpd(Client);
native rp_getSpd(Client);
native rp_setFeed(Client,Feed);
native rp_getFeed(Client);
native rp_setSta(Client,Feed);
native rp_getSta(Client);
native rp_setHate(Client,Hate);
native rp_getHate(Client);

native rp_setDefaultSpeed(Client);
native rp_setDefault(Client);
native Float:rp_getTrainTime(Client);
native rp_setTrainTime(Client,Float:Time);

native rp_setBty(Client,Bty);
native rp_getBty(Client);

native rp_addMoney(Client,Amount);
native rp_takeMoney(Client,Amount);
native rp_setMoney(Client,Amount);
native rp_addBank(Client,Amount);
native rp_takeBank(Client,Amount);
native rp_setBank(Client,Amount);
native rp_createMoneyBoxes(Client,Amount);
   
native rp_getJob(Client,String:Buffer[]);
native rp_setJob(Client,String:Buffer[]);
native rp_getWage(Client);
native rp_setWage(Client,Amount);
native rp_getMoney(Client);
native rp_getBank(Client);
native rp_getPaycheck(Client);
native rp_getMinutes(Client);

native rp_setLooseMoney(Client, Byte);

native bool:rp_coponline();
native rp_save(Client);
native rp_saveItem(Client, Item, Amount);
native rp_load(Client);

native rp_looseWeapon(Client,bool:afterDeath);
native rp_getDroppedMoneyValue(Ent);

native rp_getExploitJail(Client);
