import { transaction } from '../lib/db/client.js';

// Offline operator tool only. No public endpoint may promote users or reset MFA.
export async function assignAdministrator(db,{userId,firebaseUid,role,reason,resetAuthenticator=false}){
  if(!!userId===!!firebaseUid||!['owner','operator','viewer','none'].includes(role)||typeof reason!=='string'||reason.trim().length<5||reason.length>500)throw Error('Choose one user ID or Firebase UID, a role, and a reason (5-500 characters)');
  return transaction(db,async connection=>{
    const user=(await connection.query(`SELECT id,firebase_uid,email,status FROM public.app_users WHERE ${userId?'id':'firebase_uid'}=$1 FOR UPDATE`,[userId||firebaseUid])).rows[0];
    if(!user?.firebase_uid)throw Error('The user must sign into AutoLinky first; no matching Firebase-bound app account exists');
    if(role!=='none'&&user.status!=='active')throw Error('A blocked user cannot be granted administrator access');
    const before=(await connection.query('SELECT id,role,enabled,session_epoch FROM public.admin_accounts WHERE user_id=$1 FOR UPDATE',[user.id])).rows[0];
    if(role==='none'&&!before)throw Error('This user has no administrator assignment');
    const row=before?(await connection.query(`UPDATE public.admin_accounts SET role=$2,enabled=$3,session_epoch=session_epoch+1${resetAuthenticator?',totp_secret=NULL,totp_pending_until=NULL':''} WHERE id=$1 RETURNING id,role,enabled,session_epoch`,[before.id,role==='none'?before.role:role,role!=='none'])).rows[0]
      :(await connection.query('INSERT INTO public.admin_accounts(user_id,username,role) VALUES($1,$2,$3) RETURNING id,role,enabled,session_epoch',[user.id,'app:'+user.id,role])).rows[0];
    await connection.query(`INSERT INTO public.admin_log(admin,actor_id,user_id,email,action,details,before_state,after_state)
      VALUES('offline-operator',$1,$2,$3,$4,$5,$6,$7)`,[row.id,user.id,user.email,resetAuthenticator?'admin_factor_reset':role==='none'?'admin_role_revoke':'admin_role_assign',{reason:reason.trim()},before||{},row]);
    return {user_id:user.id,firebase_uid:user.firebase_uid,email:user.email,role:row.enabled?row.role:null,authenticator:resetAuthenticator||!before?'enroll at /admin/':'existing factor retained',sessions:'previous sessions revoked'};
  });
}
