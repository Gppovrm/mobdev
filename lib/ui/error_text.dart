import '../data/api_client.dart';
import '../l10n/app_localizations.dart';

String errorText(AppLocalizations l10n, ApiException error) => switch (error) {
  NetworkException() => l10n.errorNetwork,
  ServerException() => l10n.errorServer,
  UnauthorizedException() => l10n.errorUnauthorized,
  RequestException() => l10n.errorRequest,
};
