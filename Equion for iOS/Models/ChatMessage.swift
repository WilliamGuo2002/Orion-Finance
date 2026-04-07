import Foundation
import UIKit

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String  // "user" or "ai"
    let content: String
    var imageData: Data?
    var fileName: String?
    var fileText: String?
}
