import CallKit
import Foundation

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // 1. 加载并合并规则
        let rules = RuleManager.shared.loadRules()
        var allRanges = RuleManager.shared.mergeRules(rules)
        
        // 2. 加入硬编码调试号并重新全局排序（解决升序错误）
        let debugNumber: Int64 = 86123456789
        allRanges.append(debugNumber...debugNumber)
        
        // 重新排序并再次合并可能重叠的区间
        let finalRanges = mergeRanges(allRanges)

        // 3. 全量处理逻辑
        if context.isIncremental {
            context.removeAllBlockingEntries()
        }
        
        // 4. 注入号码
        for range in finalRanges {
            var currentNumber = range.lowerBound
            while currentNumber <= range.upperBound {
                autoreleasepool {
                    context.addBlockingEntry(withNextSequentialPhoneNumber: currentNumber)
                }
                currentNumber += 1
            }
        }
        
        // 5. 正确调用完成回调
        context.completeRequest(completionHandler: nil)
    }
    
    // 内部辅助方法：确保所有区间合并且绝对升序
    private func mergeRanges(_ ranges: [ClosedRange<Int64>]) -> [ClosedRange<Int64>] {
        let sorted = ranges.sorted { $0.lowerBound < $1.lowerBound }
        guard let first = sorted.first else { return [] }
        var merged = [first]
        for current in sorted.dropFirst() {
            let last = merged.last!
            if current.lowerBound <= last.upperBound + 1 {
                let newUpper = max(last.upperBound, current.upperBound)
                merged[merged.count - 1] = last.lowerBound...newUpper
            } else {
                merged.append(current)
            }
        }
        return merged
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        NSLog("CallDirectoryHandler Error: %@", error.localizedDescription)
    }
}
