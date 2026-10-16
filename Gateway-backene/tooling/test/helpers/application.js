// Legacy parity harness only. Production has independent service applications.
import { buildAuth } from '../../../../Auth-backend/app.js';
import { registerAppRoutes,registerDownloads } from '../../../../App-backend/routes.js';
import { registerMessagingRoutes } from '../../../../Notify-backend/routes.js';
import { registerDeviceActivity } from '../../../../Notify-backend/src/routes/devices.js';
import { protectedRoutes } from '../../support/http/server.js';
import { AIClient } from '../../../../App-backend/lib/ai/client.js';
import { gmailTransport } from '../../../../Notify-backend/src/email/gmail.js';
import { deliveryService } from '../../../../Notify-backend/src/email/delivery.js';
import { messagingRepository } from '../../../../App-backend/src/messaging-api.js';
import { applicationOverlay } from '../../../../Notify-backend/src/application-api.js';
import { checkMigrations } from '../../../../Data-baceknd/database/migrate.js';

export function buildApp(options={}){
  const app=buildAuth({...options,identityData:{deleteUser:id=>options.db.query('SELECT public.delete_user_data($1)',[id])},schemaCheck:()=>checkMigrations(options.db)}),context=app.services;
  context.appData=messagingRepository(context.db);
  context.notifyData={overlay:(id,ids)=>applicationOverlay(context.db,id,ids)};
  context.ai=options.ai||new AIClient(context.config);
  context.extractor=options.extractor;context.transport=options.transport||gmailTransport();
  context.mail=options.mail||deliveryService({...context});
  protectedRoutes(app,context.auth,(privateApp,services)=>{registerAppRoutes(privateApp,services);registerMessagingRoutes(privateApp,services);});
  registerDownloads(app,context);registerDeviceActivity(app,context);
  return app;
}
