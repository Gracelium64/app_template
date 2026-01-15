abstract final class Client {
  static const String name = String.fromEnvironment(
    'CLIENT_NAME',
    defaultValue:
        'clientPortfolioStartingTemplate', // Swap to David Davidson / Use Client.name
  );

  static const String underline = String.fromEnvironment(
    'CLIENT_UNDERLINE',
    defaultValue:
        'clientPortfolioStartingTemplate', // Swap to david_davidson / Use Client.underline
  );
}
