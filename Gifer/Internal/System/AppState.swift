import SwiftUI
import Combine

struct AppState {
    public var convertProgress = PassthroughSubject<(String, CGFloat), Never>()
    public var converting = PassthroughSubject<Bool, Never>()
}
