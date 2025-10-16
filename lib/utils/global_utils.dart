import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

String makeId(String type) =>
    type + DateTime.now().microsecondsSinceEpoch.toString();

final uuid = Uuid();

String formatDate(String dateString) {
  try {
    DateTime parsedDate = DateTime.parse(dateString);
    final formatter = DateFormat('d MMM yyyy HH:mm');
    return formatter.format(parsedDate);
  } catch (e) {
    if (kDebugMode) {
      print('Date parsing error: $e');
    }
    return '';
  }
}


String getRandomString(int length) {
  const characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  Random random = Random();

  return String.fromCharCodes(
    Iterable.generate(
      length,
          (_) => characters.codeUnitAt(random.nextInt(characters.length)),
    ),
  );
}