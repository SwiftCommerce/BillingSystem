import Service

func repositories(services: inout Services)throws {
    let customers = CustomerRepositories()
    services.register(customers)
}
