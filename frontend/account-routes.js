export const accountScreens={login:'welcome',signup:'welcome',dashboard:'matches',jobs:'explore',profile:'profile'};
export const accountPaths=Object.keys(accountScreens).flatMap(name=>[`/${name}/`,`/ar/${name}/`]);
export function accountDestination(url,userAgent=''){
  const match=/^\/(ar\/)?(login|signup|dashboard|jobs|profile)\/?$/.exec(url.pathname);
  if(!match)return null;
  const variant=/iPhone|iPad|iPod/i.test(userAgent)?'ios':'android';
  const query=new URLSearchParams(url.search);
  query.set('lang',match[1]?'ar':query.get('lang')==='ar'?'ar':'en');
  return `/app/${variant}/${accountScreens[match[2]]}?${query}`;
}
