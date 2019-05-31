import Fluent
import Vapor
import JSON

final class UserController: RouteCollection {
    struct RequestBody: Content {
        let subscription: String
        let externalUser: String
        let customer: JSON
    }

    struct PatchBody: Content {
        let subscription: String?
        let externalUser: String?
        let customer: JSON?
    }

    struct ResponseBody: Content {
        let subscription: Subscription
        let customer: JSON
        let user: User
    }

    let userSubscriptions: UserSubscriptionRepository
    let customers: CustomerRepository
    let users: UserRepository

    init(userSubscriptions: UserSubscriptionRepository, customers: CustomerRepository, users: UserRepository) {
        self.userSubscriptions = userSubscriptions
        self.customers = customers
        self.users = users
    }

    func boot(router: Router) throws {
        let group = router.grouped(self.customers.service.name)

        group.post(RequestBody.self, use: self.create)
        group.get(String.parameter, use: self.read)
        group.patch(PatchBody.self, at: String.parameter, use: self.update)
        group.delete(String.parameter, use: self.delete)
    }

    func create(_ request: Request, content: RequestBody)throws -> EventLoopFuture<ResponseBody> {
        guard let subscription = Subscription.subscriptions[content.subscription] else {
            throw Abort(.badRequest, reason: "Invalid subscription. Please select a pre-defined subscription")
        }

        return self.customers.create(customer: content.customer).flatMap { customer -> EventLoopFuture<(User, JSON)> in
            guard let id = customer.id.string else {
                throw Abort(.internalServerError, reason: "Customer backend returned an object without an ID")
            }

            let user = User(customer: id, external: content.externalUser, service: self.customers.service)
            return self.users.create(user: user).and(result: customer)
        }.flatMap { result -> EventLoopFuture<(user: User, customer: JSON)> in
            let pivot = try self.userSubscriptions.create(user: result.0.requireID(), subscription: content.subscription)
            return pivot.transform(to: result)
        }.map { data in
            return ResponseBody(subscription: subscription, customer: data.customer, user: data.user)
        }
    }

    func read(_ request: Request)throws -> EventLoopFuture<ResponseBody> {
        let id = try request.parameters.next(String.self)
        let customer = self.customers.read(customer: id)
        let pivot = self.userSubscriptions.read(for: id).unwrap(or:
            Abort(.notFound, reason: "There is no user or subscription data stored about that customer")
        )

        return customer.and(pivot).map { data in
            let (customer, (user: user, subscription: subscription)) = data
            return ResponseBody(subscription: subscription, customer: customer, user: user)
        }
    }

    func update(_ request: Request, content: PatchBody)throws -> EventLoopFuture<ResponseBody> {
        let id = try request.parameters.next(String.self)

        let subscription: EventLoopFuture<Subscription>
        let updatedCustomer: EventLoopFuture<JSON>
        let updatedUser: EventLoopFuture<User>

        if let json = content.customer {
            updatedCustomer = self.customers.update(customer: id, with: json)
        } else {
            updatedCustomer = self.customers.read(customer: id)
        }

        if let external = content.externalUser {
            updatedUser = self.users.set(external: external, for: id).unwrap(or: Abort(.notFound))
        } else {
            updatedUser = self.users.read(for: id).unwrap(or: Abort(.notFound))
        }

        if let newSubscription = content.subscription {
            let pivot = self.userSubscriptions.set(subscription: newSubscription, for: id).unwrap(or: Abort(.notFound))
            subscription = pivot.map { $0.subscription }
        } else {
            subscription = self.userSubscriptions.read(for: id).unwrap(or: Abort(.notFound)).map { $0.subscription }
        }

        return subscription.and(updatedUser).and(updatedCustomer).map { result in
            let ((subscription, user), customer) = result
            return ResponseBody(subscription: subscription, customer: customer, user: user)
        }
    }

    func delete(_ request: Request)throws -> EventLoopFuture<HTTPStatus> {
        let id = try request.parameters.next(String.self)

        return self.customers.delete(customer: id).flatMap {
            return self.userSubscriptions.delete(for: id)
        }.flatMap {
            return self.users.delete(for: id)
        }.transform(to: .noContent)
    }
}
