import Service

func repositories(services: inout Services)throws {
    let customers = CustomerRepositories()
    services.register(customers)

    services.register(DefaultUserRepository.self)
    services.register(DefaultSubscriptionRepository.self)
}
