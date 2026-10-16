import countries from './countries.json' with {type:'json'};
const codes=new Set(Object.values(countries));
const names=new Map(Object.entries(countries).map(([n,c])=>[n.toLowerCase(),c]));
for(const [n,c] of Object.entries({uae:'AE',ksa:'SA',uk:'GB',usa:'US',us:'US',england:'GB','the netherlands':'NL',holland:'NL','czech republic':'CZ',turkiye:'TR','türkiye':'TR',korea:'KR','viet nam':'VN'}))names.set(n,c);
export function countryCode(value){const v=String(value || '').trim().replace(/^[. ]+|[. ]+$/g,'').replace(/\s+/g,' ');return codes.has(v.toUpperCase())?v.toUpperCase():names.get(v.toLowerCase()) || null;}
