import Foundation

struct BlockRule: Codable, Equatable {
    let prefix: Int64
    let starCount: Int // 1-6 星
    
    var range: ClosedRange<Int64> {
        let multiplier = Int64(pow(10.0, Double(starCount)))
        let start = prefix * multiplier
        let end = start + (multiplier - 1)
        return start...end
    }
}

class RuleManager {
    static let shared = RuleManager()
    private let appGroupID = "group.com.kufei326.callblocker" // 建议在 Xcode 中配置好 App Group 后同步修改此处
    
    func mergeRules(_ rules: [BlockRule]) -> [ClosedRange<Int64>] {
        if rules.isEmpty { return [] }
        
        // 1. 获取所有范围并按起点排序
        let sortedRanges = rules.map { $0.range }.sorted { $0.lowerBound < $1.lowerBound }
        
        // 2. 合并重叠和相邻的区间
        var merged = [sortedRanges[0]]
        for i in 1..<sortedRanges.count {
            let last = merged.last!
            let current = sortedRanges[i]
            
            if current.lowerBound <= last.upperBound + 1 {
                let newUpper = max(last.upperBound, current.upperBound)
                merged[merged.count - 1] = last.lowerBound...newUpper
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
