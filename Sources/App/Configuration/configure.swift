import Fluent
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    try services.register(FluentProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(CORSMiddleware(configuration: .default()))
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    var databaseConfig = DatabasesConfig()
    try databases(config: &databaseConfig, env: env)
    services.register(databaseConfig)

    var migrationConfig = MigrationConfig()
    try migrations(config: &migrationConfig)
    services.register(migrationConfig)

    try repositories(services: &services)
}
