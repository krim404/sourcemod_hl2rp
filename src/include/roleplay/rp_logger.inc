#if defined _rp_logger_included_
  #endinput
#endif
#define _rp_logger_included_

native rp_log_cuff( Client, Attacker, Crime );
native rp_log_deposit( Client, Amount );
native rp_log_withdraw( Client, Amount );
native rp_log_purchase( Client, ItemId, Amount );