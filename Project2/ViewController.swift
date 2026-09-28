import UIKit
import ParseSwift

/// Storyboard entry point used as a fallback when iOS restores a scene that was
/// originally created from Main.storyboard.
final class ViewController: UIViewController {
    private var contentViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        installInitialInterface()
    }

    private func installInitialInterface() {
        guard contentViewController == nil else { return }

        let rootViewController: UIViewController
        if User.current != nil {
            rootViewController = FeedViewController()
        } else {
            rootViewController = LoginViewController()
        }

        let navigationController = UINavigationController(
            rootViewController: rootViewController
        )
        addChild(navigationController)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationController.view)

        NSLayoutConstraint.activate([
            navigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            navigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        navigationController.didMove(toParent: self)
        contentViewController = navigationController
    }
}
