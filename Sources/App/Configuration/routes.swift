import Vapor

/// Register your application's routes here.
public func routes(_ router: Router, _ container: Container) throws {
    let root = router.grouped(any, "billing")

    root.get("health") { request in
        return "All good!"
    }

    let userSubscriptions = try container.make(UserSubscriptionRepository.self)
    let users = try container.make(UserRepository.self)

    let chargebee = try container.make(backend: .chargebee)

    try router.register(collection: UserController(userSubscriptions: userSubscriptions, customers: chargebee, users: users))
}
