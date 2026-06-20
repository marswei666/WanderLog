import Foundation
import UIKit

struct UserStats: Codable {
    let userUUID: String
    let userName: String
    let totalCheckIns: Int
    let totalCountries: Int
    let totalCities: Int
    let updatedAt: String
    let platform: String
}

final class CloudSyncService {

    static let shared = CloudSyncService()

    // MARK: - 配置（开通 CloudBase 后填入）

    /// 云函数访问地址，格式：https://xxx.service.tcloudbase.com/syncUserStats
    static var endpoint: String = "https://wanderlog-stats-d4fnpamqed206c68-1445354193.ap-shanghai.app.tcloudbase.com/syncUserStats"

    /// CloudBase 环境 ID
    static var envId: String = "wanderlog-stats-d4fnpamqed206c68-1445354193"

    // MARK: - User UUID

    private let uuidKey = "cloud_sync_user_uuid"

    var userUUID: String {
        if let saved = UserDefaults.standard.string(forKey: uuidKey) {
            return saved
        }
        let newUUID = UUID().uuidString
        UserDefaults.standard.set(newUUID, forKey: uuidKey)
        return newUUID
    }

    // MARK: - Sync

    func syncStats(entries: [Entry], userName: String) {
        guard !Self.endpoint.isEmpty else {
            print("☁️ CloudSyncService: endpoint not configured, skipping")
            return
        }

        let countries = Set(entries.map { $0.country }.filter { !$0.isEmpty })
        let cities = Set(entries.filter { !$0.city.isEmpty }.map { "\($0.city),\($0.country)" })

        let stats = UserStats(
            userUUID: userUUID,
            userName: userName,
            totalCheckIns: entries.count,
            totalCountries: countries.count,
            totalCities: cities.count,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "ios"
        )

        guard let url = URL(string: Self.endpoint),
              let body = try? JSONEncoder().encode(stats) else {
            print("☁️ CloudSyncService: invalid endpoint or encoding failed")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print("☁️ CloudSyncService sync failed: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("☁️ CloudSyncService sync response: \(httpResponse.statusCode)")
            }
        }.resume()
    }
}
