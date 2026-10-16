import { setup,runtime } from './config.js';
await setup();
console.log(`Local environment configured in ${runtime}. Existing files and secrets were preserved.`);
console.log('No production data is imported. Next: npm run env:start with existing web assets. Builds are separate and run only on request.');
