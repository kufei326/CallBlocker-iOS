import UIKit
import CallKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let prefixTextField = UITextField()
    private let starSegmentedControl = UISegmentedControl(items: ["1★", "2★", "3★", "4★", "5★", "6★"])
    private let tableView = UITableView()
    private var rules: [BlockRule] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "2200W 电话拦截"
        setupUI()
        loadCurrentRules()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        // 前缀输入框
        prefixTextField.placeholder = "输入前缀 (如 8610122)"
        prefixTextField.borderStyle = .roundedRect
        prefixTextField.keyboardType = .numberPad
        prefixTextField.backgroundColor = .white
        
        // 星级选择
        starSegmentedControl.selectedSegmentIndex = 4 // 默认 5 星
        
        // 添加按钮
        let addButton = UIButton(type: .system)
        addButton.setTitle("添加拦截规则", for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 8
        addButton.addTarget(self, action: #selector(addRule), for: .touchUpInside)
        
        // 刷新系统按钮
        let refreshButton = UIButton(type: .system)
        refreshButton.setTitle("同步到系统系统", for: .normal)
        refreshButton.setTitleColor(.systemRed, for: .normal)
        refreshButton.addTarget(self, action: #selector(syncToSystem), for: .touchUpInside)

        // 布局
        let stackView = UIStackView(arrangedSubviews: [prefixTextField, starSegmentedControl, addButton, refreshButton])
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
        guard let text = prefixTextField.text, let prefix = Int64(text) else {
            showAlert(title: "错误", message: "请输入正确的数字前缀")
            return
        }
        
        let stars = starSegmentedControl.selectedSegmentIndex + 1
        let newRule = BlockRule(prefix: prefix, starCount: stars)
        
        rules.append(newRule)
        RuleManager.shared.saveRules(rules)
        tableView.reloadData()
        prefixTextField.text = ""
        prefixTextField.resignFirstResponder()
    }

    @objc private func syncToSystem() {
        // 根据 Apple 的规则，Extension 的 ID 必须是 AppID 加 ".Extension"
        let appBundleID = Bundle.main.bundleIdentifier ?? "com.kufei326.CallBlocker"
        let extensionIdentifier = "\(appBundleID).Extension"
        
        print("正在尝试同步扩展: \(extensionIdentifier)")
        
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionIdentifier) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "同步失败", message: "扩展ID: \(extensionIdentifier)\n错误: \(error.localizedDescription)\n\n请先去系统设置开启权限！")
                } else {
                    self.showAlert(title: "同步成功", message: "2200万级拦截库已生效")
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rules.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let rule = rules[indexPath.row]
        let starStr = String(repeating: "★", count: rule.starCount)
        cell.textLabel?.text = "拦截前缀: \(rule.prefix) (后缀: \(starStr))"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            rules.remove(at: indexPath.row)
            RuleManager.shared.saveRules(rules)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
