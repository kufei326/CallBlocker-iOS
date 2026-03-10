import Foundation

struct BlockRule: Codable, Equatable {
    let prefix: Int64
    let starCount: Int
    var range: ClosedRange<Int64> {
        if starCount == 0 { return prefix...prefix }
        let multiplier = Int64(pow(10.0, Double(starCount)))
        let start = prefix * multiplier
        let end = start + (multiplier - 1)
        return start...end
    }
}

class RuleManager {
    static let shared = RuleManager()
    
    // 动态获取 App Group ID：group. + 当前 Bundle ID
    var appGroupID: String {
        let baseID = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".Extension", with: "") ?? "com.kufei326.CallBlocker"
        return "group.\(baseID)"
    }
    
    func mergeRules(_ rules: [BlockRule]) -> [ClosedRange<Int64>] {
        if rules.isEmpty { return [] }
        let sorted = rules.map { $0.range }.sorted { $0.lowerBound < $1.lowerBound }
        var merged = [sorted[0]]
        for i in 1..<sorted.count {
            let last = merged.last!
            let current = sorted[i]
            if current.lowerBound <= last.upperBound + 1 {
                merged[merged.count - 1] = last.lowerBound...max(last.upperBound, current.upperBound)
            } else {
                merged.append(current)
            }
        }
        return merged
    }
    
    func saveRules(_ rules: [BlockRule]) {
        let container = UserDefaults(suiteName: appGroupID)
        if let encoded = try? JSONEncoder().encode(rules) {
            container?.set(encoded, forKey: "BlockRules")
            container?.synchronize()
        }
    }
    
    func loadRules() -> [BlockRule] {
        let container = UserDefaults(suiteName: appGroupID)
        if let data = container?.data(forKey: "BlockRules"),
           let rules = try? JSONDecoder().decode([BlockRule].self, from: data) {
            return rules
        }
        return []
    }
}
