import Fluent
import Vapor
import JSON

extension CustomerBackend {
    static let chargebee: CustomerBackend = CustomerBackend(name: "chargebee")
}

struct ChargebeeConfig: Service {
    let apiKey: String
    let site: String
}

final class Chargebee: CustomerRepository {
    let service: CustomerBackend
    let config: ChargebeeConfig
    let users: UserRepository
    let client: Client

    init(config: ChargebeeConfig, client: Client, users: UserRepository) {
        self.service = .chargebee
        self.client = client
        self.config = config
        self.users = users
    }

    static func makeService(for container: Container) throws -> Chargebee {
        return try Chargebee(config: container.make(), client: container.make(), users: container.make())
    }

    private func send(_ method: HTTPMethod, _ resource: String..., body: JSON? = nil) -> EventLoopFuture<JSON> {
        var http = HTTPRequest(
            method: method,
            url: "https://\(self.config.site).chargebee.com/api/v2/\(resource.joined(separator: "/"))",
            headers: ["Authorization": "Basic \(self.config.apiKey)"]
        )

        if let json = body {
            do {
                http.body = try HTTPBody(data: JSONEncoder().encode(json))
            } catch let error {
                return self.client.container.future(error: error)
            }
        }

        return self.client.send(Request(http: http, using: self.client.container)).flatMap { response in
            guard (200...299).contains(response.http.status.code) else {
                throw Abort(.serviceUnavailable, reason: "Received status code \(response.http.status.code) from Chargbee")
            }

            return try response.content.decode(JSON.self)
        }
    }

    func create(customer: JSON) -> EventLoopFuture<JSON> {
        return self.send(.POST, "customers", body: customer)
    }

    func read(customer: String) -> EventLoopFuture<JSON> {
        return self.send(.GET, "customers", customer)
    }

    func update(customer: String, with payload: JSON) -> EventLoopFuture<JSON> {
        return self.send(.POST, "customers", customer, body: payload)
    }

    func delete(customer: String) -> EventLoopFuture<Void> {
        return self.send(.POST, "customers", customer, "delete").transform(to: ())
    }
}
