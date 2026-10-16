import { registerApplications } from './src/routes/applications.js';
import { registerEmailApply } from './src/routes/email-apply.js';
import { registerDevices } from './src/routes/devices.js';
export function registerMessagingRoutes(app,context){
  registerApplications(app,context);registerEmailApply(app,context);registerDevices(app,context);
}
