import Foundation

struct BlockRule: Codable, Equatable {
    let prefix: Int64
    let starCount: Int // 0-6，0 为精确匹配
    
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
    // 恢复为固定 ID，因为您的环境测试该 ID 正常
    private let appGroupID = "group.com.kufei326.callblocker"
    
    // 终极合并与排序算法：确保输出的区间绝对升序且互不重叠
    func mergeRules(_ rules: [BlockRule]) -> [ClosedRange<Int64>] {
        if rules.isEmpty { return [] }
        
        // 1. 展开所有区间并按起点排序
        let sortedRanges = rules.map { $0.range }.sorted { $0.lowerBound < $1.lowerBound }
        
        // 2. 线性合并所有重叠或相邻的区间
        var merged: [ClosedRange<Int64>] = []
        for current in sortedRanges {
            if let last = merged.last {
                if current.lowerBound <= last.upperBound + 1 {
                    // 有重叠或紧邻，合并
                    let newUpper = max(last.upperBound, current.upperBound)
                    merged[merged.count - 1] = last.lowerBound...newUpper
                } else {
                    // 无重叠，直接添加
                    merged.append(current)
                }
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
