import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let root = router.grouped(any, "billing")

    root.get("health") { request in
        return "All good!"
    }
}
