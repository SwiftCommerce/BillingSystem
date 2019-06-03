import Fluent

protocol UserSubscriptionRepository: ServiceType {
    typealias PivotResult = (user: User, subscription: Subscription)

    func create(user: User.ID, subscription: Subscription.ID) -> EventLoopFuture<PivotResult>
    func read(for customer: String) -> EventLoopFuture<PivotResult?>
    func set(subscription: Subscription.ID, for customer: String) -> EventLoopFuture<PivotResult?>
    func delete(for customer: String) -> EventLoopFuture<Void>
}

final class DefaultUserSubscriptionRepository: UserSubscriptionRepository {
    typealias ConnectionPool = DatabaseConnectionPool<ConfiguredDatabase<ServiceDatabase>>

    static var serviceSupports: [Any.Type] = [UserSubscriptionRepository.self]

    let pool: ConnectionPool

    init(pool: ConnectionPool) {
        self.pool = pool
    }

    static func makeService(for container: Container) throws -> DefaultUserSubscriptionRepository {
        return try DefaultUserSubscriptionRepository(pool: container.connectionPool(to: databaseID))
    }

    func create(user: User.ID, subscription: Subscription.ID) -> EventLoopFuture<PivotResult> {
        return self.pool.withConnection { connection in
            return UserSubscription(user: user, subscription: subscription).create(on: connection).flatMap { pivot in
                return User.query(on: connection).join(through: UserSubscription.self)
                    .filter(\.id == user).alsoDecode(Subscription.self).first()
            }
        }.map { models in
            guard let result: PivotResult = models else {
                throw FluentError(
                    identifier: "modelsNotFound",
                    reason: "Unabele to get saved User and Subscription from database"
                )
            }

            return result
        }
    }

    func read(for customer: String) -> EventLoopFuture<PivotResult?> {
        return self.pool.withConnection { connection in
            return User.query(on: connection).join(through: UserSubscription.self).filter(\.customer == customer)
                .alsoDecode(Subscription.self).first()
        }.map { $0 }
    }

    func set(subscription: Subscription.ID, for customer: String) -> EventLoopFuture<PivotResult?> {
        return self.pool.withConnection { connection in
            return UserSubscription.query(on: connection).join(\User.id, to: \UserSubscription.user)
                .filter(\User.customer == customer).update(\.subscription, to: subscription).run().flatMap {
                return User.query(on: connection).join(through: UserSubscription.self).filter(\.customer == customer)
                    .alsoDecode(Subscription.self).first()
            }
        }.map { $0 }
    }

    func delete(for customer: String) -> EventLoopFuture<Void> {
        return self.pool.withConnection { connection in
            return UserSubscription.query(on: connection).join(\User.id, to: \UserSubscription.user)
                .filter(\User.customer == customer).delete()
        }
    }

}

extension QueryBuilder where Database: JoinSupporting {
    func join<P>(through: P.Type) -> Self where P: Pivot, Result == P.Right {
        return self.join(P.rightIDKey, to: Result.idKey).join(P.Left.idKey, to: P.leftIDKey)
    }

    func join<P>(through: P.Type) -> Self where P: Pivot, Result == P.Left {
        return self.join(P.leftIDKey, to: Result.idKey).join(P.Right.idKey, to: P.rightIDKey)
    }
}
