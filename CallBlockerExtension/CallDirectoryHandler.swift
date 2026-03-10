import CallKit
import Foundation

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // 1. 获取规则
        let rules = RuleManager.shared.loadRules()
        let finalRanges = RuleManager.shared.mergeRules(rules)

        // 2. 清空缓存（针对全量更新或逻辑同步重置）
        if context.isIncremental {
            context.removeAllBlockingEntries()
        }
        
        // 3. 逐个注入用户自己的号码
        for range in finalRanges {
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
        // 用于调试：如果同步失败，系统会走这里
        print("Extension Sync Failed: \(error.localizedDescription)")
    }
}
