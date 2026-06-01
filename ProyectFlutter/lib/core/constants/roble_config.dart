class RobleConfig {
  static const String dbName = String.fromEnvironment(
    'ROBLE_DB_NAME',
    defaultValue: 'coeval_b65ae2515f',
  );

  static const String authBaseUrl = String.fromEnvironment(
    'ROBLE_AUTH_URL',
    defaultValue: 'https://roble-api.openlab.uninorte.edu.co/auth',
  );

  static const String databaseBaseUrl = String.fromEnvironment(
    'ROBLE_DATABASE_URL',
    defaultValue: 'https://roble-api.openlab.uninorte.edu.co/database',
  );
}
