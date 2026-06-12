const fs = require('fs');

let f1 = 'lib/core/providers/habit_provider.dart';
let c1 = fs.readFileSync(f1, 'utf8');
c1 = c1.replace(/id: `\$\{prefix\}_\$\{idx\}`/g, "id: `${prefix}_${idx}`".replace(/`/g, "'"));
fs.writeFileSync(f1, c1);
console.log('Fixed habit_provider.dart');

let f2 = 'lib/core/services/notification_service.dart';
let c2 = fs.readFileSync(f2, 'utf8');
c2 = c2.replace(/await _flutterLocalNotificationsPlugin\.initialize\(\n      initializationSettings,/g, "await _flutterLocalNotificationsPlugin.initialize(\n      initializationSettings: initializationSettings,");
// Wait, if it wants 'settings', let's use both. We'll use multi_replace for notification.
fs.writeFileSync(f2, c2);
console.log('Fixed notification_service.dart');
