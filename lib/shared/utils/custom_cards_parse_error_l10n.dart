import '../../core/import/sources/custom_file/custom_card_entry.dart';
import '../../l10n/app_localizations.dart';

/// Localized message for a whole-file parse failure.
String localizedParseError(S l, CustomCardsParseErrorCode code) {
  switch (code) {
    case CustomCardsParseErrorCode.emptyFile:
      return l.customImportErrorEmptyFile;
    case CustomCardsParseErrorCode.invalidJson:
      return l.customImportErrorInvalidJson;
    case CustomCardsParseErrorCode.missingRequiredColumns:
      return l.customImportErrorMissingColumns;
  }
}
