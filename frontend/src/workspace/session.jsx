import React,{createContext,useContext,useEffect,useMemo,useRef,useState} from 'react';
import { createClient } from './api.js';
import { firebaseSession } from './firebase.js';
const Session=createContext(null);
export function SessionProvider({children}){
  const [state,setState]=useState({status:'loading',user:null,account:null,error:null}),current=useRef(null),generation=useRef(0);
  const client=useMemo(()=>createClient({getToken:()=>current.current?.getIdToken()}),[]);
  async function connect(user){
    const ticket=++generation.current;current.current=user;
    if(!user){setState({status:'signed-out',user:null,account:null,error:null});return;}
    setState({status:'loading',user,account:null,error:null});
    try{const account=await client('/v1/me');if(ticket===generation.current)setState({status:'signed-in',user,account,error:null});}
    catch(error){if(ticket===generation.current)setState({status:'error',user,account:null,error});}
  }
  useEffect(()=>{
    let alive=true,unsubscribe;
    firebaseSession().then(({auth,sdk})=>{if(alive)unsubscribe=sdk.onIdTokenChanged(auth,user=>{void connect(user);});}).catch(error=>{if(alive)setState({status:'error',user:null,account:null,error});});
    return()=>{alive=false;generation.current++;unsubscribe?.();};
  },[]);
  async function signOut(){generation.current++;const {auth,sdk}=await firebaseSession();await sdk.signOut(auth);current.current=null;setState({status:'signed-out',user:null,account:null,error:null});}
  return <Session.Provider value={{...state,client,retry:()=>connect(current.current),signOut}}>{children}</Session.Provider>;
}
export const useSession=()=>useContext(Session);
