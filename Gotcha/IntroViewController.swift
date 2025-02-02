import UIKit // Import UIKit framework, necessary for creating user interfaces on iOS.
import AVKit // Import AVKit framework, which provides tools for handling audio and video content.

class IntroViewController: UIViewController { // Define a new class `IntroViewController`, subclassing `UIViewController`. It represents a screen or view in the app.
    override func viewDidLoad() { // This method is called when the view is loaded into memory.
        super.viewDidLoad() // Call the parent class’s `viewDidLoad` to keep normal behavior.
        
        // another experimental impl
        DispatchQueue.main.async { // Execute this block asynchronously on the main thread (important for UI updates).
            self.setupAVPlayer() // Call `setupAVPlayer()` to initialize and play the video.
        }
    }
    
    private func setupAVPlayer() { // Private method to setup and configure AVPlayer to play a video.
        // Attempt to find the video file named "googleMapAR.mov" in the app's main bundle. If not found, return early.
        guard let videoURL = Bundle.main.url(forResource: "googleMapAR", withExtension: "mov") else { return }
        
        // Create an AVPlayer instance with the video URL.
        let player = AVPlayer(url: videoURL)
        
        // Create an AVPlayerLayer to display the video and set its frame to match the view's bounds.
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        
        // Ensure this block is executed on the main thread to update the UI safely.
        DispatchQueue.main.async {
            self.view.layer.addSublayer(playerLayer) // Add the player layer as a sublayer to the view’s layer to display the video.
        }
        
        // NOTE: experimental implementation
        DispatchQueue.main.async { // Execute the play method on the main thread.
            player.play() // Start playing the video.
        }
//        player.play() // The commented line is redundant since it's already called in the previous async block.
        
        // Repeat the AVPlayer when the video finishes.
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak self] _ in
            player.seek(to: CMTime.zero) // Rewind the video to the start.
            player.play() // Play the video again from the beginning.
        }
    }
    
//    private func setupAVPlayer() { // The old version of `setupAVPlayer()`, which is now commented out.
/*    All code here is effectively the same as in the new version, but without the experimental `DispatchQueue.main.async` blocks.
        It's included as an alternative that directly plays the video and handles repeating the video.
        The repeated code is commented out for simplicity. */
    
    @available(iOS 13.0, *)
    @IBAction func signInAsHost(_ sender: UIButton) { // Method triggered when the "Sign in as Host" button is tapped.
        // Instantiate the `ViewController` from the storyboard with the identifier "arviewcontroller".
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "arviewcontroller") as! ViewController
        vc.isHost = true // Set the `isHost` property to true, indicating that this user is the host.
        present(vc, animated: true, completion: nil) // Present the new view controller (AR view).
    }
    
    @available(iOS 13.0, *)
    @IBAction func signInAsUser(_ sender: UIButton) { // Method triggered when the "Sign in as User" button is tapped.
        // Instantiate the `ViewController` from the storyboard with the identifier "arviewcontroller".
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "arviewcontroller") as! ViewController
        vc.isHost = false // Set the `isHost` property to false, indicating that this user is not the host.
        present(vc, animated: true, completion: nil) // Present the new view controller (AR view).
    }
    
}

