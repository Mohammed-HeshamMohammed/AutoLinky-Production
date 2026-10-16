import { registerApplications } from '../../src/http/routes/applications.js';
import { registerEmailApply } from '../../src/http/routes/email-apply.js';
import { registerDevices } from '../../src/http/routes/devices.js';
export function registerMessagingRoutes(app,context){
  registerApplications(app,context);registerEmailApply(app,context);registerDevices(app,context);
}
