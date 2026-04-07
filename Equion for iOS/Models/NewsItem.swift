import Foundation

struct NewsItem: Identifiable, Codable {
    let id = UUID()
    let headline: String
    let datetime: Int?
    let url: String
    let image: String?

    enum CodingKeys: String, CodingKey {
        case headline, datetime, url, image
    }
}
