import FluentMySQL

final class Subscription: Codable, CaseIterable {
    static let entity = "subscriptions"

    private(set) var name: String!

    // Using `nil` as a value represents infinity.
    let maxAPICalls: UInt?
    let period: Calendar.Component

    private init(name: String, maxCalls: UInt?) {
        self.name = name
        self.maxAPICalls = maxCalls
        self.period = .month
    }

    static let free: Subscription = Subscription(name: "Free", maxCalls: 5_000)
    static let hobby: Subscription = Subscription(name: "Hobby", maxCalls: 25_000)
    static let business: Subscription = Subscription(name: "Business", maxCalls: nil)

    static var allCases: [Subscription] = [.free, .hobby, .business]
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
        }.flatMap {
            return self.allCases.map { $0.save(on: conn) }.flatten(on: conn).transform(to: ())
        }
    }
}

extension Calendar.Component: RawRepresentable, Codable {
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

    public var rawValue: String {
        return String(describing: self)
    }
}
