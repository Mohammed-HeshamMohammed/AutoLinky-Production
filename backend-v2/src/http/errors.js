export class HttpError extends Error {
  constructor(status,detail,headers={}) { super(typeof detail==='string'?detail:JSON.stringify(detail)); this.status=status;this.detail=detail;this.headers=headers; }
}
export const unavailable=()=>new HttpError(503,'Service temporarily unavailable');
export const notFound=()=>new HttpError(404,'Not found');
export const invalid=(message)=>new HttpError(422,message);
export function errorHandler(error,request,reply) {
  if (error instanceof HttpError) return reply.code(error.status).headers(error.headers).send({detail:error.detail});
  if (error.validation) return reply.code(422).send({detail:error.validation.map(v=>({
    type:v.keyword,loc:[error.validationContext || 'body',...v.instancePath.split('/').filter(Boolean),...(v.params?.additionalProperty?[v.params.additionalProperty]:[])],msg:v.message,
  }))});
  if (error.code==='FST_ERR_CTP_BODY_TOO_LARGE') return reply.code(413).send({detail:request.url.startsWith('/v1/cv')?'cv_too_large':'File too large'});
  if (error.code==='FST_ERR_CTP_INVALID_JSON_BODY' || error.statusCode===400) return reply.code(400).send({detail:'Invalid request body'});
  if (/^(08|22|23|40|42|53|57)/.test(error.code || '') || ['ECONNREFUSED','ETIMEDOUT','ENOTFOUND'].includes(error.code)) {
    request.log.error({code:error.code,request_id:request.id},'Database request failed');
    return reply.code(503).send({detail:'Service temporarily unavailable'});
  }
  request.log.error({type:error.name,code:error.code,request_id:request.id},'Request failed');
  return reply.code(500).send({detail:'Internal error',request_id:request.id});
}
