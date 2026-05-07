const fs = require('fs');
const b64 = fs.readFileSync('C:/Users/erikc/Dev/game/ss_b64.txt', 'utf8').trim();
fs.writeFileSync('C:/Users/erikc/Dev/game/screenshot_out.png', Buffer.from(b64, 'base64'));
console.log('Saved');
