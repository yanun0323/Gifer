import SwiftUI

struct DIContainer: EnvironmentKey {
    static var `default` = DIContainer(isMock: false)
    static var defaultValue: DIContainer { .default }
    
    var appstate: AppState
    var interactor: Interactor
    
    init(isMock: Bool) {
        self.appstate = AppState()
        self.interactor = Interactor(appstate: appstate)
    }
}

extension View {
    func inject(_ container: DIContainer) -> some View {
        self.environment(\.injected, container)
    }
}

extension EnvironmentValues {
    var injected: DIContainer {
        get { self[DIContainer.self] }
        set { self[DIContainer.self] = newValue }
    }
}
