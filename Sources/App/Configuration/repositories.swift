import Service

func repositories(services: inout Services)throws {
    var customers = CustomerRepositories()
    chargebee(repositories: &customers, services: &services)
    services.register(customers)

    services.register(DefaultUserRepository.self)
    services.register(DefaultSubscriptionRepository.self)
    services.register(DefaultUserSubscriptionRepository.self)
}

func chargebee(repositories: inout CustomerRepositories, services: inout Services) {
    services.register(ChargebeeConfig(apiKey: "", site: "skelpo-test"))
    repositories.register(.chargebee, repository: Chargebee.self)
}
