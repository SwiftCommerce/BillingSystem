import Service

struct CustomerBackend: Codable, Hashable {
    let name: String

    init(name: String) {
        self.name = name
    }

    init(from decoder: Decoder)throws {
        let container = try decoder.singleValueContainer()
        self.name = try container.decode(String.self)
    }

    func encode(to encoder: Encoder)throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.name)
    }
}

struct RepositoryCache: Service {
    fileprivate let repositories: [CustomerBackend: CustomerRepository]
}

struct CustomerRepositories: ServiceFactory {
    let serviceType: Any.Type
    let serviceSupports: [Any.Type]
    var factories: [CustomerBackend: BasicServiceFactory]

    init() {
        self.serviceType = CustomerRepositories.self
        self.serviceSupports = [CustomerRepositories.self, RepositoryCache.self]
        self.factories = [:]
    }

    func makeService(for worker: Container) throws -> Any {
        let repositories: [CustomerBackend: CustomerRepository] = try self.factories.reduce(into: [:]) { services, factory in
            guard let repository = try factory.value.makeService(for: worker) as? CustomerRepository else { return }
            services[factory.key] = repository
        }

        return RepositoryCache(repositories: repositories)
    }

    mutating func register(_ backend: CustomerBackend, repository: CustomerRepository.Type) {
        self.factories[backend] = BasicServiceFactory(repository, supports: [], factory: repository.makeService(for:))
    }
}

extension Container {
    func make(backend: CustomerBackend)throws -> CustomerRepository {
        let cache = try self.make(RepositoryCache.self)
        guard let repository = cache.repositories[backend] else {
            throw ServiceError(
                identifier: "repositoryNotFound",
                reason: "No `CustomerRepository` registered for backend `\(backend.name)`")
        }

        return repository
    }
}
