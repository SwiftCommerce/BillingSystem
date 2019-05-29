import FluentMySQL

final class UserSubscription: Codable {
    static let entity = "userSubscriptions"

    var id: Int?
    var user: User.ID
    var subscription: Subscription.ID

    init(user: User.ID, subscription: Subscription.ID) {
        self.user = user
        self.subscription = subscription
    }
}

extension UserSubscription: Migration { }

extension UserSubscription: Model {
    typealias Database = ServiceDatabase

    static var idKey: WritableKeyPath<UserSubscription, Int?> {
        return \.id
    }
}

extension UserSubscription: Pivot {
    typealias Left = User
    typealias Right = Subscription

    static var leftIDKey: WritableKeyPath<UserSubscription, Int> {
        return \.user
    }

    static var rightIDKey: WritableKeyPath<UserSubscription, String> {
        return \.subscription
    }
}
