import CallKit
import Foundation

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // 1. 获取用户定义的规则
        let rules = RuleManager.shared.loadRules()
        
        // 2. 将规则合并并全局排序（绝对升序保障）
        let mergedRanges = RuleManager.shared.mergeRules(rules)
        
        // 3. 处理注入（针对全量模式清空，如果是增量模式则按逻辑操作）
        if context.isIncremental {
            context.removeAllBlockingEntries()
        }

        // 4. 正式注入号码
        for range in mergedRanges {
            var current = range.lowerBound
            while current <= range.upperBound {
                autoreleasepool {
                    context.addBlockingEntry(withNextSequentialPhoneNumber: current)
                }
                current += 1
            }
        }
        
        context.completeRequest(completionHandler: nil)
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // 同步失败时的内部日志
        NSLog("CallBlocker: 同步扩展时失败 - \(error.localizedDescription)")
    }
}
