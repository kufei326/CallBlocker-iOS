import UIKit
import CallKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .white
        let button = UIButton(frame: CGRect(x: 50, y: 200, width: 300, height: 50))
        button.backgroundColor = .systemBlue
        button.setTitle("应用 2200W 拦截规则", for: .normal)
        button.addTarget(self, action: #selector(applyRules), for: .touchUpInside)
        view.addSubview(button)
    }

    @objc private func applyRules() {
        // 示例：添加一个 6 星规则 (100万个号码)
        // 8610122****** -> 8610122000000 到 8610122999999
        let newRule = BlockRule(prefix: 8610122, starCount: 6)
        RuleManager.shared.saveRules([newRule])
        
        // 通知系统刷新扩展
        let extensionIdentifier = "com.yourname.app.CallBlockerExtension"
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionIdentifier) { error in
            DispatchQueue.main.main.async {
                if let error = error {
                    self.showAlert(title: "失败", message: error.localizedDescription)
                } else {
                    self.showAlert(title: "成功", message: "规则已提交系统处理，请在系统设置中确保权限已开启")
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
