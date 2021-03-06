/**
 *  BulletinBoard
 *  Copyright (c) 2017 Alexis Aubry. Licensed under the MIT license.
 */

import UIKit

/**
 * A view controller that displays a card at the bottom of the screen.
 */

final class BulletinViewController: UIViewController, UIGestureRecognizerDelegate {

    /**
     * The stack view displaying the content of the card.
     *
     * - warning: You should not customize the distribution, axis and alignment of the stack, as this
     * may break the layout of the card.
     */

    let contentStackView = UIStackView()

    /**
     * Indicates whether the bulletin can be dismissed by a tap outside the card.
     */

    var isDismissable: Bool = false

    // MARK: - Activity Indicator

    func displayActivityIndicator() {

        activityIndicator.startAnimating()

        let animations = {
            self.activityIndicator.alpha = 1
            self.contentStackView.alpha = 0
        }

        UIView.animate(withDuration: 0.25, animations: animations) { _ in
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.activityIndicator)
        }

    }

    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.alpha = 0
    }

    // MARK: - Private Interface Elements

    fileprivate let contentView = UIView()
    fileprivate let activityIndicator = ActivityIndicator()

    private var containerBottomConstraint: NSLayoutConstraint!

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var centerXConstraint: NSLayoutConstraint!
    private var minWidthConstraint: NSLayoutConstraint!
    private var contentLeadingConstraint: NSLayoutConstraint!
    private var contentTrailingConstraint: NSLayoutConstraint!
    private var contentBottomConstraint: NSLayoutConstraint!

    // MARK: - Private Controllers

    fileprivate lazy var swipeInteractionController = BulletinSwipeInteractionController()

    // MARK: - Lifecycle

    weak var manager: BulletinManager?

    override func loadView() {

        super.loadView()
        view.backgroundColor = .clear

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        view.addGestureRecognizer(recognizer)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.accessibilityViewIsModal = true
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(contentView)

        // Content View

        contentView.layer.cornerRadius = 12

        leadingConstraint = contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12)
        trailingConstraint = contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        centerXConstraint = contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor)

        minWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: 444)
        minWidthConstraint.priority = UILayoutPriorityDefaultHigh

        let maxWidthConstraint = contentView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -24)
        maxWidthConstraint.priority = UILayoutPriorityRequired
        maxWidthConstraint.isActive = true

        containerBottomConstraint = contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerBottomConstraint.isActive = true
        containerBottomConstraint.constant = bottomSpacingForCurrentLayout()

        // Content Stack View

        contentView.addSubview(contentStackView)

        contentLeadingConstraint = contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 36)
        contentLeadingConstraint.isActive = true

        contentTrailingConstraint = contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -36)
        contentTrailingConstraint.isActive = true

        contentBottomConstraint = contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        contentBottomConstraint.isActive = true

        let topConstraint = contentView.topAnchor.constraint(equalTo: contentStackView.topAnchor, constant: -24)
        topConstraint.isActive = true
        topConstraint.priority = UILayoutPriorityDefaultHigh

        let minYConstraint = contentView.topAnchor.constraint(greaterThanOrEqualTo: topLayoutGuide.bottomAnchor)
        minYConstraint.isActive = true
        minYConstraint.priority = UILayoutPriorityRequired

        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill

        // Activity Indicator

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicator)
        activityIndicator.leftAnchor.constraint(equalTo: contentStackView.leftAnchor).isActive = true
        activityIndicator.rightAnchor.constraint(equalTo: contentStackView.rightAnchor).isActive = true
        activityIndicator.topAnchor.constraint(equalTo: contentStackView.topAnchor).isActive = true
        activityIndicator.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor).isActive = true

        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.color = .black
        activityIndicator.isUserInteractionEnabled = true

        activityIndicator.alpha = 0

        contentView.backgroundColor = #colorLiteral(red: 0.9921568627, green: 1, blue: 1, alpha: 1)
        setUpLayout(with: traitCollection)

        swipeInteractionController.wire(to: self, contentView: contentView)

    }

    // MARK: - Layout

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {

        coordinator.animate(alongsideTransition: { _ in
            self.setUpLayout(with: newCollection)
        })

    }

    private func setUpLayout(with traitCollection: UITraitCollection) {

        switch traitCollection.horizontalSizeClass {
        case .regular:
            leadingConstraint.isActive = false
            trailingConstraint.isActive = false

            centerXConstraint.isActive = true
            minWidthConstraint.isActive = true

        case .compact:
            leadingConstraint.isActive = true
            trailingConstraint.isActive = true

            centerXConstraint.isActive = false
            minWidthConstraint.isActive = false

        default:
            break
        }

        switch (traitCollection.verticalSizeClass, traitCollection.horizontalSizeClass) {
        case (.regular, .regular):
            contentLeadingConstraint.constant = 32
            contentTrailingConstraint.constant = -32
            contentBottomConstraint.constant = -24

            contentStackView.spacing = 32

        default:
            contentLeadingConstraint.constant = 24
            contentTrailingConstraint.constant = -24
            contentBottomConstraint.constant = -16

            contentStackView.spacing = 24

        }

    }

    private func bottomSpacingForCurrentLayout() -> CGFloat {

        let bottomInset: CGFloat

        if #available(iOS 11.0, *) {
            let safeBottomInset = view.safeAreaInsets.bottom
            bottomInset = safeBottomInset > 0 ? safeBottomInset : 12
        } else {
            bottomInset = 12
        }

        return -bottomInset

    }

    override func viewSafeAreaInsetsDidChange() {
        containerBottomConstraint.constant = bottomSpacingForCurrentLayout()
    }
    
    /// Dismisses the presnted BulletinViewController if `isDissmisable` is set to `true`.
    @discardableResult
    func dismissIfPossible() -> Bool {
    
        guard isDismissable else {
            return false
        }
    
        manager?.dismissBulletin(animated: true)
        return true

    }

    // MARK: - Touch Events

    @objc private func handleTap(recognizer: UITapGestureRecognizer) {
        dismissIfPossible()
    }
    
    // MARK: - Accessibility
    
    override func accessibilityPerformEscape() -> Bool {
        return dismissIfPossible()
    }

}

// MARK: - Interactions

extension BulletinViewController: UIViewControllerTransitioningDelegate {

    func resetContentView() {
        contentView.transform = .identity
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BulletinPresentationAnimationController(style: manager?.backgroundViewStyle ?? .dimmed)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BulletinDismissAnimationController()
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return swipeInteractionController.isInteractionInProgress ? swipeInteractionController : nil
    }

}

// MARK: - Swift Compatibility

#if swift(>=4.0)
private let UILayoutPriorityRequired = UILayoutPriority.required
private let UILayoutPriorityDefaultHigh = UILayoutPriority.defaultHigh
#endif
