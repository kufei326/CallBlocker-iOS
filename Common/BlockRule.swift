import Foundation

struct BlockRule: Codable, Equatable {
    let prefix: Int64
    let starCount: Int // 1-6 星
    
    // 将星级规则转换为具体的号码闭区间
    var range: ClosedRange<Int64> {
        let multiplier = Int64(pow(10.0, Double(starCount)))
        let start = prefix * multiplier
        let end = start + (multiplier - 1)
        return start...end
    }
}

class RuleManager {
    static let shared = RuleManager()
    private let appGroupID = "group.com.yourname.callblocker" // 请替换为您自己的 App Group ID
    
    // 区间合并算法：确保给 CallKit 的号码是升序且唯一的，处理重叠号段
    func mergeRules(_ rules: [BlockRule]) -> [ClosedRange<Int64>] {
        let sortedRanges = rules.map { $0.range }.sorted { $0.lowerBound < $1.lowerBound }
        guard let first = sortedRanges.first else { return [] }
        
        var merged = [first]
        for current in sortedRanges.dropFirst() {
            let lastIndex = merged.count - 1
            if current.lowerBound <= merged[lastIndex].upperBound + 1 {
                let newUpper = max(merged[lastIndex].upperBound, current.upperBound)
                merged[lastIndex] = merged[lastIndex].lowerBound...newUpper
            } else {
                merged.append(current)
            }
        }
        return merged
    }
    
    func saveRules(_ rules: [BlockRule]) {
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            if let encoded = try? JSONEncoder().encode(rules) {
                sharedDefaults.set(encoded, forKey: "BlockRules")
                sharedDefaults.synchronize()
            }
        }
    }
    
    func loadRules() -> [BlockRule] {
        if let sharedDefaults = UserDefaults(suiteName: appGroupID),
           let data = sharedDefaults.data(forKey: "BlockRules"),
           let rules = try? JSONDecoder().decode([BlockRule].self, from: data) {
            return rules
        }
        return []
    }
}
