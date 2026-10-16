import nodemailer from 'nodemailer';
export class MailError extends Error{constructor(kind,{uncertain=false,code=null}={}){super(kind);this.kind=kind;this.uncertain=uncertain;this.smtpCode=code;}}
export function classifyMail(error){
  if(error instanceof MailError)return error;
  const code=error.responseCode,text=String(error.response||'').toLowerCase(),command=error.command||'';
  if(/5\.4\.5|sending limit|quota/.test(text))return new MailError('gmail_limit',{code});
  if(error.code==='EAUTH'||code===535||command.startsWith('AUTH')){if(/5\.7\.9|application-specific password/.test(text))return new MailError('not_app_password',{code});if(/5\.7\.14|web browser/.test(text))return new MailError('blocked',{code});return new MailError(code>=400&&code<500?'busy':'auth',{code});}
  if(code>=400&&code<500)return new MailError('busy',{code});
  if(code>=500)return new MailError(command.startsWith('RCPT')?'recipient':'rejected',{code});
  return new MailError('busy',{uncertain:!['CONN','AUTH','EHLO','HELO','STARTTLS'].includes(command)});
}
export function gmailTransport({transportFactory=nodemailer.createTransport}={}){
  const create=(address,password)=>transportFactory({host:'smtp.gmail.com',port:465,secure:true,auth:{user:address,pass:password},connectionTimeout:10000,greetingTimeout:10000,socketTimeout:25000,tls:{minVersion:'TLSv1.2',rejectUnauthorized:true},disableFileAccess:true,disableUrlAccess:true,logger:false,debug:false});
  return {
    async verify(address,password){const transport=create(address,password);try{await transport.verify();}catch(error){throw classifyMail(error);}finally{transport.close();}},
    async send(address,password,letter,cv){const transport=create(address,password);try{
      const result=await transport.sendMail({from:{name:letter.from_name||'',address},to:letter.to,subject:letter.subject,text:letter.body,
        attachments:[{filename:letter.attachment,content:cv.bytes,contentType:cv.file_type==='pdf'?'application/pdf':'application/vnd.openxmlformats-officedocument.wordprocessingml.document'}],
        disableFileAccess:true,disableUrlAccess:true});
      if(!result.accepted?.some(a=>String(a).toLowerCase()===letter.to.toLowerCase()))throw new MailError('busy',{uncertain:true});
      return {messageId:result.messageId};
    }catch(error){throw classifyMail(error);}finally{transport.close();}},
  };
}
