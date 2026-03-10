import UIKit
import CallKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let prefixTextField = UITextField()
    private let starSegmentedControl = UISegmentedControl(items: ["0★", "1★", "2★", "3★", "4★", "5★", "6★"])
    private let tableView = UITableView()
    private var rules: [BlockRule] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "电话拦截 (测试前删联系人)"
        setupUI()
        loadCurrentRules()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        prefixTextField.placeholder = "输入拦截号码或前缀 (需包含 86)"
        prefixTextField.borderStyle = .roundedRect
        prefixTextField.keyboardType = .numberPad
        prefixTextField.backgroundColor = .white
        
        starSegmentedControl.selectedSegmentIndex = 0 // 默认 0 星（精确匹配）
        
        let addButton = UIButton(type: .system)
        addButton.setTitle("添加拦截规则", for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 8
        addButton.addTarget(self, action: #selector(addRule), for: .touchUpInside)
        
        let refreshButton = UIButton(type: .system)
        refreshButton.setTitle("同步到系统系统", for: .normal)
        refreshButton.setTitleColor(.systemRed, for: .normal)
        refreshButton.addTarget(self, action: #selector(syncToSystem), for: .touchUpInside)

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
            showAlert(title: "错误", message: "请输入纯数字。拦截国内号请以 86 开头。")
            return
        }
        
        let stars = starSegmentedControl.selectedSegmentIndex
        let newRule = BlockRule(prefix: prefix, starCount: stars)
        
        rules.append(newRule)
        RuleManager.shared.saveRules(rules)
        tableView.reloadData()
        prefixTextField.text = ""
        prefixTextField.resignFirstResponder()
    }

    @objc private func syncToSystem() {
        let appBundleID = Bundle.main.bundleIdentifier ?? "com.kufei326.CallBlocker"
        let extensionIdentifier = "\(appBundleID).Extension"
        
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionIdentifier) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "同步失败", message: "错误: \(error.localizedDescription)\n\n请在系统设置中确保权限已开启。")
                } else {
                    self.showAlert(title: "同步成功", message: "拦截库已成功提交。请确保测试号码不在通讯录中！")
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
        let starStr = rule.starCount == 0 ? "精确匹配" : String(repeating: "★", count: rule.starCount)
        cell.textLabel?.text = "\(rule.prefix) (\(starStr))"
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
