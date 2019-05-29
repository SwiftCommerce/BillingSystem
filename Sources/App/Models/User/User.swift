import FluentMySQL

final class User: Codable {
    static let entity = "users"

    var id: Int?
    var customer: String
    var service: CustomerBackend

    init(customer: String, service: CustomerBackend) {
        self.id = nil
        self.customer = customer
        self.service = service
    }
}

extension User: Migration { }

extension User: Model {
    typealias Database = ServiceDatabase

    static var idKey: WritableKeyPath<User, Int?> {
        return \.id
    }
}
