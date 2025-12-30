import 'dart:developer' as developer;
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
      developer.log('Date parsing error: $e', name: 'GlobalUtils');
    }
    return '';
  }
}

String timeAgo(String dateString) {
  try {
    final DateTime parsedDate = DateTime.parse(dateString);
    final Duration diff = DateTime.now().difference(parsedDate);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} sec${diff.inSeconds == 1 ? '' : 's'} ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else if (diff.inDays < 30) {
      int weeks = (diff.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (diff.inDays < 365) {
      int months = (diff.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      int years = (diff.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  } catch (e) {
    if (kDebugMode) {
      developer.log('Date parsing error: $e', name: 'GlobalUtils');
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