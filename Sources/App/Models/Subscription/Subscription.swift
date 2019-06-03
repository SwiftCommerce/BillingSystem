import FluentMySQL

final class Subscription: Codable {
    static let entity = "subscriptions"

    static let free: Subscription = Subscription(name: "Free", maxCalls: 5_000)
    static let hobby: Subscription = Subscription(name: "Hobby", maxCalls: 25_000)
    static let business: Subscription = Subscription(name: "Business", maxCalls: nil)

    private(set) var name: String!

    // Using `nil` as a value represents infinity.
    let maxAPICalls: UInt?
    let period: Calendar.Component

    private init(name: String, maxCalls: UInt?) {
        self.name = name
        self.maxAPICalls = maxCalls
        self.period = .month
    }
}

struct SubscriptionInserts: Migration {
    typealias Database = ServiceDatabase

    static func prepare(on conn: ServiceDatabase.Connection) -> EventLoopFuture<Void> {
        return Subscription.allCases.map { subscription in
            subscription.create(on: conn)
        }.flatten(on: conn).transform(to: ())
    }

    static func revert(on conn: ServiceDatabase.Connection) -> EventLoopFuture<Void> {
        return Subscription.query(on: conn).delete()
    }
}

extension Subscription: CaseIterable {
    static let allCases: [Subscription] = [.free, .hobby, .business]

    static let subscriptions: [String: Subscription] = {
        return Subscription.allCases.reduce(into: [:]) { map, subscription in map[subscription.name] = subscription }
    }()
}

extension Subscription: Model {
    typealias Database = ServiceDatabase

    static var idKey: WritableKeyPath<Subscription, String?> {
        return \.name
    }
}

extension Subscription: Migration {
    static func prepare(on conn: Database.Connection) -> Future<Void> {
        return Database.create(self, on: conn) { builder in
            builder.field(for: \.name, isIdentifier: true)
            builder.field(for: \.maxAPICalls, type: .bigint(unsigned: true))
            builder.field(for: \.period)
        }
    }
}

extension Calendar.Component: RawRepresentable, Codable, MySQLEnumType {
    public var rawValue: String {
        return String(describing: self)
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "era": self = .era
        case "year": self = .year
        case "yearForWeekOfYear": self = .yearForWeekOfYear
        case "quarter": self = .quarter
        case "month": self = .month
        case "weekOfYear": self = .weekOfYear
        case "weekOfMonth": self = .weekOfMonth
        case "weekday": self = .weekday
        case "weekdayOrdinal": self = .weekdayOrdinal
        case "day": self = .day
        case "hour": self = .hour
        case "minute": self = .minute
        case "second": self = .second
        case "nanosecond": self = .nanosecond
        case "calendar": self = .calendar
        case "timeZone": self = .timeZone
        default: return nil
        }
    }

    public static func reflectDecoded() throws -> (Calendar.Component, Calendar.Component) {
        return (.era, .year)
    }
}
