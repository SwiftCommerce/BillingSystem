import Fluent
import MySQL

typealias ServiceDatabase = MySQLDatabase
let databaseID: DatabaseIdentifier<ServiceDatabase> = .mysql

func databases(config: inout DatabasesConfig, env: Environment)throws {
    mysql(config: &config, env: env)
}

fileprivate func mysql(config: inout DatabasesConfig, env: Environment) {
    let configuration = MySQLDatabaseConfig(
        hostname: Environment.get("DATABASE_HOSTNAME") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 3306,
        username: Environment.get("DATABASE_USER") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database: Environment.get("DATABASE_DB") ?? "billing",
        transport: env.isRelease ? .cleartext : .unverifiedTLS
    )
    let database = MySQLDatabase(config: configuration)

    config.add(database: database, as: .mysql)
}
