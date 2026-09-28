import UIKit
import ParseSwift

final class SignUpViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let usernameTextField = SignUpViewController.makeTextField(
        placeholder: "Username",
        contentType: .username
    )
    private let emailTextField = SignUpViewController.makeTextField(
        placeholder: "Email",
        contentType: .emailAddress,
        keyboardType: .emailAddress
    )
    private let passwordTextField = SignUpViewController.makeTextField(
        placeholder: "Password",
        contentType: .newPassword,
        isSecure: true
    )

    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Sign Up"
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private static func makeTextField(
        placeholder: String,
        contentType: UITextContentType,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.textContentType = contentType
        textField.keyboardType = keyboardType
        textField.isSecureTextEntry = isSecure
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Sign Up"

        let fieldsStack = UIStackView(arrangedSubviews: [
            usernameTextField,
            emailTextField,
            passwordTextField
        ])
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 12
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(fieldsStack)
        view.addSubview(signUpButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),

            fieldsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 36),
            fieldsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            fieldsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),

            usernameTextField.heightAnchor.constraint(equalToConstant: 48),
            emailTextField.heightAnchor.constraint(equalToConstant: 48),
            passwordTextField.heightAnchor.constraint(equalToConstant: 48),

            signUpButton.topAnchor.constraint(equalTo: fieldsStack.bottomAnchor, constant: 24),
            signUpButton.leadingAnchor.constraint(equalTo: fieldsStack.leadingAnchor),
            signUpButton.trailingAnchor.constraint(equalTo: fieldsStack.trailingAnchor),
            signUpButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
    }

    @objc private func signUpTapped() {
        let username = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""

        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            showAlert(message: "Please enter a username, email, and password.")
            return
        }

        guard email.contains("@"), email.contains(".") else {
            showAlert(message: "Please enter a valid email address.")
            return
        }

        signUpButton.isEnabled = false

        var newUser = User()
        newUser.username = username
        newUser.email = email
        newUser.password = password

        Task { @MainActor in
            do {
                _ = try await newUser.signup()
                navigateToMainApp()
            } catch {
                signUpButton.isEnabled = true
                showAlert(message: "Sign up failed: \(error.localizedDescription)")
            }
        }
    }

    private func navigateToMainApp() {
        let feedViewController = FeedViewController()
        let navigationController = UINavigationController(rootViewController: feedViewController)

        guard let windowScene = view.window?.windowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let window = sceneDelegate.window else {
            return
        }

        window.rootViewController = navigationController
        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil
        )
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Unable to Sign Up", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
