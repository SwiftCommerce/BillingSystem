import Fluent
import Service

protocol UserRepository: ServiceType {
    func create(user: User) -> EventLoopFuture<User>
    func read(user: User.ID) -> EventLoopFuture<User?>
    func delete(user: User.ID) -> EventLoopFuture<Void>
}

final class DefaultUserRepository: UserRepository {
    typealias ConnectionPool = DatabaseConnectionPool<ConfiguredDatabase<ServiceDatabase>>

    let pool: ConnectionPool

    init(pool: ConnectionPool) {
        self.pool = pool
    }

    static func makeService(for container: Container) throws -> DefaultUserRepository {
        return try self.init(pool: container.connectionPool(to: databaseID))
    }

    func create(user: User) -> EventLoopFuture<User> {
        return self.pool.withConnection { connection in
            return user.create(on: connection)
        }
    }

    func read(user: User.ID) -> EventLoopFuture<User?> {
        return self.pool.withConnection { connection in
            return User.query(on: connection).filter(\.id == user).first()
        }
    }

    func delete(user: User.ID) -> EventLoopFuture<Void> {
        return self.pool.withConnection { connection in
            return User.query(on: connection).filter(\.id == user).delete()
        }
    }
}
