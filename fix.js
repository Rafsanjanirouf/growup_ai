const fs = require('fs');
const files = [
  'lib/core/services/gemini_service.dart',
  'lib/core/services/firestore_service.dart',
  'lib/core/providers/habit_provider.dart',
  'lib/features/dashboard/dashboard_screen.dart',
  'lib/core/services/notification_service.dart',
  'lib/core/services/sync_service.dart'
];

files.forEach(f => {
  if (!fs.existsSync(f)) return;
  let content = fs.readFileSync(f, 'utf8');
  
  // Some files might have been corrupted multiple times if the regex matched multiple \$
  // So we run a while loop
  let changed = false;
  while(content.indexOf(" '$' + import") !== -1) {
    let idx = content.indexOf(" '$' + import");
    let endIdx = content.indexOf(".Value.Substring(2) ", idx);
    if (endIdx !== -1) {
        let firstPart = content.substring(0, idx);
        let secondPart = content.substring(endIdx + ".Value.Substring(2) ".length);
        content = firstPart + "$" + secondPart;
        changed = true;
    } else {
        break; // Can't find end marker
    }
  }
  
  // also fix dashboard_screen.dart quotes
  if (content.includes("today\\\\\\'s")) {
      content = content.replace(/today\\\\\\'s/g, "today\\'s");
      changed = true;
  }
  if (content.includes("today\\\\\'s")) {
      content = content.replace(/today\\\\\'s/g, "today\\'s");
      changed = true;
  }
  if (content.includes("today\\\\'s")) {
      content = content.replace(/today\\\\'s/g, "today\\'s");
      changed = true;
  }

  if (changed) {
      fs.writeFileSync(f, content);
      console.log('Fixed ' + f);
  }
});
