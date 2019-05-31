import Service

func repositories(services: inout Services)throws {
    var customers = CustomerRepositories()
    customers.register(.chargebee, repository: Chargebee.self)
    services.register(customers)

    services.register(DefaultUserRepository.self)
    services.register(DefaultSubscriptionRepository.self)
    services.register(DefaultUserSubscriptionRepository.self)
}
