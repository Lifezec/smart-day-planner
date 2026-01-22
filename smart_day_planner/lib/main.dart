import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ Yeni eklendi

import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Türkçe dil desteğini başlat ✅
  await initializeDateFormatting('tr_TR', null);
  
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: SmartDayApp()));
}
