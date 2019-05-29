import Service
import JSON

protocol CustomerRepository: ServiceType {
    var service: CustomerBackend { get }

    func create(customer: JSON) -> EventLoopFuture<JSON>
    func read(customer: String) -> EventLoopFuture<JSON>
    func update(customer: String, with payload: JSON) -> EventLoopFuture<JSON>
    func delete(customer: String) -> EventLoopFuture<Void>
}
