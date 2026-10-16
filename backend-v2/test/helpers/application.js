// Legacy parity harness only. Production has independent service applications.
import { buildAuth } from '../../../Auth-backend/app.js';
import { registerAppRoutes,registerDownloads } from '../../../App-backend/routes.js';
import { registerMessagingRoutes } from '../../../Notify-backend/routes.js';
import { registerDeviceActivity } from '../../../Notify-backend/src/routes/devices.js';
import { protectedRoutes } from '../../shared/http/server.js';
import { AIClient } from '../../shared/ai/client.js';
import { gmailTransport } from '../../../Notify-backend/src/email/gmail.js';
import { deliveryService } from '../../../Notify-backend/src/email/delivery.js';

export function buildApp(options={}){
  const app=buildAuth(options),context=app.services;
  context.ai=options.ai||new AIClient(context.config);
  context.extractor=options.extractor;context.transport=options.transport||gmailTransport();
  context.mail=options.mail||deliveryService({...context});
  protectedRoutes(app,context.auth,(privateApp,services)=>{registerAppRoutes(privateApp,services);registerMessagingRoutes(privateApp,services);});
  registerDownloads(app,context);registerDeviceActivity(app,context);
  return app;
}
