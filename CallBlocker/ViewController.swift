import UIKit
import CallKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let prefixTextField = UITextField()
    private let starSegmentedControl = UISegmentedControl(items: ["0★", "1★", "2★", "3★", "4★", "5★", "6★"])
    private let tableView = UITableView()
    private var rules: [BlockRule] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "2200W 终极拦截"
        setupUI()
        loadCurrentRules()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        prefixTextField.placeholder = "输入拦截号 (自动匹配 86)"
        prefixTextField.borderStyle = .roundedRect
        prefixTextField.keyboardType = .numberPad
        prefixTextField.backgroundColor = .white
        
        starSegmentedControl.selectedSegmentIndex = 0
        
        let addButton = UIButton(type: .system)
        addButton.setTitle("添加拦截规则", for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 8
        addButton.addTarget(self, action: #selector(addRule), for: .touchUpInside)
        
        let syncButton = UIButton(type: .system)
        syncButton.setTitle("同步到系统系统", for: .normal)
        syncButton.backgroundColor = .systemRed
        syncButton.setTitleColor(.white, for: .normal)
        syncButton.layer.cornerRadius = 8
        syncButton.addTarget(self, action: #selector(syncToSystem), for: .touchUpInside)

        let checkButton = UIButton(type: .system)
        checkButton.setTitle("🔍 检查权限与存储", for: .normal)
        checkButton.addTarget(self, action: #selector(checkStatus), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [prefixTextField, starSegmentedControl, addButton, syncButton, checkButton])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadCurrentRules() {
        rules = RuleManager.shared.loadRules()
        tableView.reloadData()
    }

    @objc private func addRule() {
        guard let text = prefixTextField.text, !text.isEmpty else { return }
        let digits = text.filter { "0123456789".contains($0) }
        guard let number = Int64(digits) else { return }
        
        let stars = starSegmentedControl.selectedSegmentIndex
        
        // 自动添加原始格式和 86 格式
        let rule1 = BlockRule(prefix: number, starCount: stars)
        if !rules.contains(rule1) { rules.append(rule1) }
        
        if !digits.hasPrefix("86") {
            if let num86 = Int64("86" + digits) {
                let rule2 = BlockRule(prefix: num86, starCount: stars)
                if !rules.contains(rule2) { rules.append(rule2) }
            }
        }
        
        RuleManager.shared.saveRules(rules)
        tableView.reloadData()
        prefixTextField.text = ""
    }

    @objc private func checkStatus() {
        let groupID = "group.com.kufei326.callblocker"
        let container = UserDefaults(suiteName: groupID)
        container?.set("test", forKey: "connectivity_test")
        let isStorageWorking = container?.string(forKey: "connectivity_test") != nil

        let appID = Bundle.main.bundleIdentifier ?? "com.kufei326.CallBlocker"
        let extID = "\(appID).Extension"
        
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extID) { status, error in
            DispatchQueue.main.async {
                let statusMsg = status == .enabled ? "已开启 ✅" : "未开启 ❌"
                let storageMsg = isStorageWorking ? "正常 ✅" : "失效 ❌"
                self.showAlert(title: "状态诊断", message: "系统权限: \(statusMsg)\n存储通道: \(storageMsg)\n\n如果存储通道失效，请确认签名工具是否配置了 App Group。")
            }
        }
    }

    @objc private func syncToSystem() {
        let appID = Bundle.main.bundleIdentifier ?? "com.kufei326.CallBlocker"
        let extID = "\(appID).Extension"
        
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extID) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "同步失败", message: error.localizedDescription)
                } else {
                    self.showAlert(title: "同步成功", message: "数据已注入系统。请拨打 86123456789 验证。")
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return rules.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let rule = rules[indexPath.row]
        let starStr = rule.starCount == 0 ? "精准" : "\(rule.starCount)★"
        cell.textLabel?.text = "\(rule.prefix) (\(starStr))"
        return cell
    }
}
