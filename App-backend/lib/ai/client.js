export class AIUnavailable extends Error {}
export async function boundedJSON(response,maxBytes=256000){
  const chunks=[];let size=0;
  for await(const chunk of response.body){size+=chunk.length;if(size>maxBytes)throw new AIUnavailable('Response too large');chunks.push(chunk);}
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}
export class AIClient{
  constructor(config,{fetcher=fetch}={}){this.config=config;this.fetcher=fetcher;this.usage={input:0,output:0,cached:0,calls:0};}
  async ask({model,messages,maxTokens=1200,json=true,timeout=45000,temperature=0}){
    if(!this.config.aiKey||!this.config.aiBaseUrl||!model)throw new AIUnavailable('AI not configured');
    try{
      const url=new URL(this.config.aiBaseUrl);
      const local=!this.config.production&&url.protocol==='http:'&&['localhost','127.0.0.1','[::1]'].includes(url.hostname);
      if((url.protocol!=='https:'&&!local)||url.username||url.password||url.search||url.hash)throw Error();
    }catch{throw new AIUnavailable('AI provider URL is invalid');}
    let last;
    for(let attempt=0;attempt<2;attempt++){
      try{
        const response=await this.fetcher(`${this.config.aiBaseUrl.replace(/\/$/,'')}/chat/completions`,{
          method:'POST',redirect:'error',headers:{Authorization:`Bearer ${this.config.aiKey}`,'Content-Type':'application/json'},signal:AbortSignal.timeout(timeout),
          body:JSON.stringify({model,messages,max_tokens:maxTokens,temperature,...(json?{response_format:{type:'json_object'}}:{}),provider:{data_collection:'deny'}}),
        });
        if(!response.ok){await response.body?.cancel();const error=new AIUnavailable(`Provider status ${response.status}`);error.retryable=[429,500,502,503,504].includes(response.status);throw error;}
        const result=await boundedJSON(response);const content=result.choices?.[0]?.message?.content;
        if(typeof content!=='string')throw new AIUnavailable('Missing answer');
        const usage=result.usage||{};this.usage.calls++;this.usage.input+=usage.prompt_tokens||0;this.usage.output+=usage.completion_tokens||0;this.usage.cached+=usage.prompt_tokens_details?.cached_tokens||0;
        if(!json)return {data:content,tokens:(usage.prompt_tokens||0)+(usage.completion_tokens||0)};
        const start=content.indexOf('{'),end=content.lastIndexOf('}');if(start<0||end<=start)throw new AIUnavailable('Invalid answer');
        const data=JSON.parse(content.slice(start,end+1));if(!data||Array.isArray(data)||typeof data!=='object')throw new AIUnavailable('Invalid answer');
        return {data,tokens:(usage.prompt_tokens||0)+(usage.completion_tokens||0)};
      }catch(error){last=error;if(!error.retryable)break;}
    }
    throw last instanceof AIUnavailable?last:new AIUnavailable('Provider unavailable');
  }
}
