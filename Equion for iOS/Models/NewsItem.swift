import Foundation

struct NewsItem: Identifiable, Codable {
    let id = UUID()
    let headline: String
    let datetime: Int?
    let url: String
    let image: String?
    /// Publisher, e.g. "Reuters".
    var source: String? = nil

    enum CodingKeys: String, CodingKey {
        case headline, datetime, url, image, source
    }
}
