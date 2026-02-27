import 'package:bearby/l10n/app_localizations.dart';

class StakeFormatters {
  static String formatApr(double? apr) {
    if (apr == null || apr == 0) return 'N/A';
    return '${apr.toStringAsFixed(2)}%';
  }

  static String formatCommission(double? commission) {
    if (commission == null || commission == 0) return 'N/A';
    return '${commission.toStringAsFixed(0)}%';
  }

  static String formatLstPriceChange(double? lstPriceChangePercent) {
    if (lstPriceChangePercent == null) return 'N/A';
    final absValue = lstPriceChangePercent.abs();
    final formatted = absValue.toStringAsFixed(4);
    final prefix = lstPriceChangePercent >= 0 ? '+' : '-';
    return '$prefix$formatted%';
  }

  static String formatUnbondingPeriod(
    BigInt? unbondingPeriodSeconds,
    AppLocalizations l10n,
  ) {
    if (unbondingPeriodSeconds == null || unbondingPeriodSeconds == BigInt.zero) {
      return l10n.durationNotAvailable;
    }

    final seconds = unbondingPeriodSeconds.toInt();
    final duration = Duration(seconds: seconds);

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    final parts = <String>[];

    if (days > 0) {
      parts.add('$days${l10n.durationDay}');
    }
    if (hours > 0) {
      parts.add('$hours${l10n.durationHour}');
    }
    if (minutes > 0 && days == 0) {
      parts.add('$minutes${l10n.durationMinute}');
    }

    if (parts.isEmpty) {
      return l10n.durationLessThanAMinute;
    }

    return parts.join(' ');
  }

  static String formatUnbondingPeriodCompact(
    BigInt? unbondingPeriodSeconds,
    AppLocalizations l10n,
  ) {
    if (unbondingPeriodSeconds == null || unbondingPeriodSeconds == BigInt.zero) {
      return 'N/A';
    }

    final seconds = unbondingPeriodSeconds.toInt();
    final duration = Duration(seconds: seconds);

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);

    if (days > 0) {
      return hours > 0
          ? '$days${l10n.durationDay} $hours${l10n.durationHour}'
          : '$days${l10n.durationDay}';
    }

    if (hours > 0) {
      final minutes = duration.inMinutes.remainder(60);
      return minutes > 0
          ? '$hours${l10n.durationHour} $minutes${l10n.durationMinute}'
          : '$hours${l10n.durationHour}';
    }

    final minutes = duration.inMinutes;
    if (minutes > 0) {
      return '$minutes${l10n.durationMinute}';
    }

    return l10n.durationLessThanAMinute;
  }
}
