import SwiftUI

struct Interactor {
    private var appstate: AppState
    
    init(appstate: AppState) {
        self.appstate = appstate
    }
}

extension Interactor {
    private func delegate(_ action: @escaping () -> Void) {
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                action()
            }
        }
    }
    
    func pushConvertProgress(_ value: (String, CGFloat)) {
        delegate {
            appstate.convertProgress.send(value)
        }
    }
    
    func pushConverting(_ value: Bool) {
        delegate {
            appstate.converting.send(value)
        }
    }
}
