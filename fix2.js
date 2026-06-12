const fs = require('fs');

function fixFiles() {
  // 1. sync_service.dart -> 316 lines
  let f1 = 'lib/core/services/sync_service.dart';
  if (fs.existsSync(f1)) {
      let lines = fs.readFileSync(f1, 'utf8').split('\n');
      if (lines.length > 316) {
          lines = lines.slice(0, 316);
          // Fix line 53 (0-indexed 52)
          lines[52] = "      debugPrint('SyncService.syncDailyTasks error: $e');";
          fs.writeFileSync(f1, lines.join('\n'));
          console.log('Fixed sync_service.dart');
      }
  }

  // 2. firestore_service.dart -> 401 lines
  let f2 = 'lib/core/services/firestore_service.dart';
  if (fs.existsSync(f2)) {
      let lines = fs.readFileSync(f2, 'utf8').split('\n');
      if (lines.length > 402) {
          lines = lines.slice(0, 401);
          // Check line 395 (0-indexed 394) - but wait, the chunk was:
          // debugPrint('FirestoreService.saveDailyTasks error: $e');
          // Let's just find it and replace it.
          for(let i=0; i<lines.length; i++){
              if(lines[i].includes('FirestoreService.saveDailyTasks error:')) {
                  lines[i] = "      debugPrint('FirestoreService.saveDailyTasks error: $e');";
              }
          }
          fs.writeFileSync(f2, lines.join('\n'));
          console.log('Fixed firestore_service.dart');
      }
  }

  // 3. gemini_service.dart -> 130 lines
  let f3 = 'lib/core/services/gemini_service.dart';
  if (fs.existsSync(f3)) {
      let lines = fs.readFileSync(f3, 'utf8').split('\n');
      if (lines.length > 130) {
          lines = lines.slice(0, 130);
          fs.writeFileSync(f3, lines.join('\n'));
          console.log('Fixed gemini_service.dart');
      }
  }

  // 4. habit_provider.dart -> 247 lines
  let f4 = 'lib/core/providers/habit_provider.dart';
  if (fs.existsSync(f4)) {
      let lines = fs.readFileSync(f4, 'utf8').split('\n');
      if (lines.length > 247) {
          lines = lines.slice(0, 247);
          for(let i=0; i<lines.length; i++){
              if(lines[i].includes("String get _dateKey => 'aura_tasks_")) {
                  lines[i] = "  String get _dateKey => 'aura_tasks_${DateFormat(\\'yyyy-MM-dd\\').format(_currentDate)}';".replace(/\\'/g, "'");
              }
          }
          fs.writeFileSync(f4, lines.join('\n'));
          console.log('Fixed habit_provider.dart');
      }
  }

  // 5. notification_service.dart -> 75 lines
  let f5 = 'lib/core/services/notification_service.dart';
  if (fs.existsSync(f5)) {
      let lines = fs.readFileSync(f5, 'utf8').split('\n');
      if (lines.length > 76) {
          lines = lines.slice(0, 75);
          for(let i=0; i<lines.length; i++){
              if(lines[i].includes("debugPrint('Notification clicked: ")) {
                  lines[i] = "        debugPrint('Notification clicked: ${details.payload}');";
              }
          }
          fs.writeFileSync(f5, lines.join('\n'));
          console.log('Fixed notification_service.dart');
      }
  }

  // 6. dashboard_screen.dart -> 635 lines roughly
  let f6 = 'lib/features/dashboard/dashboard_screen.dart';
  if (fs.existsSync(f6)) {
      let lines = fs.readFileSync(f6, 'utf8').split('\n');
      if (lines.length > 700) { // arbitrary threshold, it's actually 663 or so
          // Wait, dashboard_screen was ~630 lines originally + 30 lines added. So 660. 
          // Let's just find the last "}" which closes the widget.
          // Or find where the file restarts.
          let resetIdx = lines.findIndex((l, idx) => idx > 100 && l.includes("import 'package:flutter/material.dart';"));
          if(resetIdx > 0) {
              lines = lines.slice(0, resetIdx);
              // There's a string parsing bug on line 444
              for(let i=0; i<lines.length; i++){
                  if(lines[i].includes("Generate today") && lines[i].includes("personalized Lookmaxxing routine now.'")) {
                      lines[i] = "          'Your AI Coach has analyzed your data. Generate today\\'s personalized Lookmaxxing routine now.',";
                  }
                  if(lines[i].includes("Text( '\\${h.currentCount}/\\${h.targetCount}'")) {
                      lines[i] = "                                                '${h.currentCount}/${h.targetCount}',";
                  }
              }
              fs.writeFileSync(f6, lines.join('\n'));
              console.log('Fixed dashboard_screen.dart');
          }
      }
  }
}

fixFiles();
