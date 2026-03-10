import CallKit
import Foundation

class CallDirectoryHandler: CXCallDirectoryProvider, CXCallDirectoryExtensionContextDelegate {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // 1. 从共享存储读取规则
        let rules = RuleManager.shared.loadRules()
        
        // 2. 合并重叠规则以确保升序和唯一性
        let mergedRanges = RuleManager.shared.mergeRules(rules)
        
        // 3. 注入号码
        // 如果系统支持增量更新，建议处理 context.isIncremental
        // 这里演示全量注入，针对 2200 万数据进行了内存优化
        if context.isIncremental {
            // 在实际大规模应用中，建议实现增量逻辑以节省时间
            // 简单起见，这里先移除旧数据再重新添加
            context.removeAllBlockingEntries()
        }
        
        addAllBlockingPhoneNumbers(to: context, ranges: mergedRanges)

        context.completeRequest()
    }

    // 实现协议必需的方法
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // 在这里处理请求失败的情况，例如记录日志
        print("Call Directory Extension request failed: \(error.localizedDescription)")
    }

    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext, ranges: [ClosedRange<Int64>]) {
        for range in ranges {
            var currentNumber = range.lowerBound
            while currentNumber <= range.upperBound {
                // 使用 autoreleasepool 防止内存随循环次数增加而爆炸
                autoreleasepool {
                    context.addBlockingEntry(withNextSequentialPhoneNumber: currentNumber)
                }
                currentNumber += 1
            }
        }
    }
}
