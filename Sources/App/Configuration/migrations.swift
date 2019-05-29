import Fluent

func migrations(config: inout MigrationConfig)throws {
    config.add(model: User.self, database: databaseID)
    config.add(model: Subscription.self, database: databaseID)
    config.add(model: UserSubscription.self, database: databaseID)
}
