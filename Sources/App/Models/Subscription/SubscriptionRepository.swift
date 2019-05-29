import Fluent
import Service

protocol SubscriptionRepository: ServiceType {
    func read(subscription: Subscription.ID) -> EventLoopFuture<Subscription?>
    func all() -> EventLoopFuture<[Subscription]>
}

final class DefaultSubscriptionRepository: SubscriptionRepository {
    typealias ConnectionPool = DatabaseConnectionPool<ConfiguredDatabase<ServiceDatabase>>

    static var serviceSupports: [Any.Type] = [SubscriptionRepository.self]

    let pool: ConnectionPool

    init(pool: ConnectionPool) {
        self.pool = pool
    }

    static func makeService(for container: Container) throws -> DefaultSubscriptionRepository {
        return try self.init(pool: container.connectionPool(to: databaseID))
    }

    func read(subscription: Subscription.ID) -> EventLoopFuture<Subscription?> {
        return self.pool.withConnection { connection in
            return Subscription.query(on: connection).filter(\.name == subscription).first()
        }
    }

    func all() -> EventLoopFuture<[Subscription]> {
        return self.pool.withConnection { connection in
            return Subscription.query(on: connection).all()
        }
    }
}
