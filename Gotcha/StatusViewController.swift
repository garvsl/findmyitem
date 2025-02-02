import UIKit // Import the UIKit framework, which provides the necessary tools for creating iOS applications with user interfaces.

class StatusViewController: UIViewController { // Define a new class called `StatusViewController`, which is a subclass of `UIViewController`. This class represents a screen in the app.

    enum MessageType { // Define an enumeration for the different types of messages that can be displayed on the screen.
        case trackingStateEscalation
        case planeEstimation
        case contentPlacement
        case focusSquare

        static var all: [MessageType] = [ // A static variable that holds all the possible message types as an array.
            .trackingStateEscalation,
            .planeEstimation,
            .contentPlacement,
            .focusSquare
        ]
    }
    
    @IBOutlet weak var messagePanel: UIVisualEffectView! // Create a reference to a UIVisualEffectView (a view that adds a visual effect, like a blur) from the storyboard.
    @IBOutlet weak var messageLabel: UILabel! // Create a reference to a UILabel (a label for displaying text) from the storyboard.
    
    override func viewDidLoad() { // The viewDidLoad method is called when the view is loaded into memory.
        DispatchQueue.main.async { // Ensures that UI updates happen on the main thread, since UI updates should not happen on background threads.
            super.viewDidLoad() // Call the superclass's viewDidLoad to maintain normal functionality.
        }
        messagePanel.isHidden = true // Hide the message panel initially.
    }
    
    // @IBAction : bridges swift and objective-C code. This connects the function to the UI button in the storyboard.
    @available(iOS 13.0, *)
    @IBAction func addOntoPlane(_ sender: UIButton) { // Triggered when the button is pressed to add content to the plane.
        guard let parent = self.parent as? ViewController else { return } // Get the parent view controller, and ensure it's of type `ViewController`. If not, exit.
        parent.placeObjectNode() // Call a function in the parent view controller to place an object node.
        messagePanel.alpha = 0 // Set the message panel's transparency to 0 (effectively hiding it).
        parent.currentBuffer = nil // Clear the current buffer in the parent view controller.
    }
    
    @IBAction func dismissMessage(_ sender: UIButton) { // Triggered when the button is pressed to dismiss the message.
        messagePanel.alpha = 0 // Set the message panel's transparency to 0 to hide it.
    }
    
    // Define the number of seconds before the message fades out (used for automatically hiding the message after a duration).
    private let displayDuration: TimeInterval = 4
    
    // Define a timer for hiding messages after a delay.
    private var messageHideTimer: Timer?
    
    // Dictionary to hold timers for different message types.
    private var timers: [MessageType: Timer] = [:]
    
    // MARK: - Message Handling

    func showMessage(_ text: String, autoHide: Bool = true) { // Function to show a message on the screen, with an optional auto-hide feature.
        DispatchQueue.main.async { // Ensure UI updates happen on the main thread.
            self.messageHideTimer?.invalidate() // Cancel any existing hide timer before setting a new one.
            self.messageLabel.text = text // Set the label text to the given message.
            
            self.setMessageHidden(false, animated: true) // Show the message panel, with animation.
            
            if autoHide { // If autoHide is true, start a timer to hide the message after a certain duration.
                self.messageHideTimer = Timer.scheduledTimer(withTimeInterval: self.displayDuration, repeats: false) { [weak self] _ in
                    self?.setMessageHidden(true, animated: true) // Hide the message panel after the timer finishes.
                }
            }
        }
    }
    
    func keepShowingMessage(_ text: String) { // Function to keep the message visible indefinitely (until manually hidden).
        messageLabel.text = text // Set the label text to the given message.
        setMessageHidden(false, animated: true) // Show the message panel, with animation.
    }
    
    // MARK: - Panel Visibility

    private func setMessageHidden(_ hide: Bool, animated: Bool) { // Function to hide or show the message panel, with optional animation.
        DispatchQueue.main.async { // Ensure UI updates happen on the main thread.
            self.messagePanel.isHidden = false // Ensure the message panel is not hidden before animating.
            
            guard animated else { // If animation is not required, directly set the panel's transparency.
                self.messagePanel.alpha = hide ? 0 : 1 // Set alpha to 0 (hidden) or 1 (fully visible) based on `hide`.
                return
            }
            
            // If animation is required, use UIView animation to change the panel's transparency over time.
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState], animations: {
                self.messagePanel.alpha = hide ? 0 : 1 // Animate the alpha value.
            }, completion: nil)
        }
    }
    
    // New function that processes classifications for an image recognition task.
    // This function would be used for handling image classification results.
    // (It's commented out and not in use in the code snippet)
    // func processClassifications(for request: VNRequest, error: Error?) {
    //     DispatchQueue.main.async {
    //         guard let results = request.results else {
    //             print("Unable to classify image.\n\(error!.localizedDescription)")
    //             return
    //         }
    //
    //         let classifications = results as! [VNClassificationObservation]
    //
    //         if let bestResult = classifications.first(where: { result in result.confidence > 0.5 }),
    //            let label = bestResult.identifier.split(separator: ",").first {
    //             self.identifierString = String(label)
    //             self.confidence = bestResult.confidence
    //
    //             self.displayClassifierResults()
    //         } else {
    //             self.identifierString = ""
    //             self.confidence = 0
    //             self.tagByUserInput()
    //         }
    //     }
    // }
}

