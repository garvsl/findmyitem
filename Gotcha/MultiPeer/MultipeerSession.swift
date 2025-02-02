import MultipeerConnectivity  // Importing the MultipeerConnectivity framework, which enables peer-to-peer networking

/// - Tag: MultipeerSession
class MultipeerSession: NSObject {
    
    // Defines the service type identifier for peer discovery.
    // This string must be unique for your app and should be 15 characters or less.
    static let serviceType = "ar-multi-sample"
    
    // Creates a unique peer ID using the device's name.
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    // The main session for managing peer-to-peer connections.
    private var session: MCSession!
    
    // Handles advertising this device as available for connections.
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    
    // Handles browsing for nearby available peers.
    private var serviceBrowser: MCNearbyServiceBrowser!
    
    // A closure (callback function) that processes received data.
    private let receivedDataHandler: (Data, MCPeerID) -> Void

    /// - Tag: MultipeerSetup
    // Initializes the Multipeer session and sets up communication.
    init(receivedDataHandler: @escaping (Data, MCPeerID) -> Void ) {
        self.receivedDataHandler = receivedDataHandler  // Stores the function to handle received data
        
        super.init()  // Calls the superclass's initializer
        
        // Creates an MCSession to manage the connection between peers.
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self  // Assigns this class as the session's delegate to handle events
        
        // Sets up the advertiser to broadcast this device's availability to nearby peers.
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: MultipeerSession.serviceType)
        serviceAdvertiser.delegate = self  // Assigns this class as the advertiser delegate
        serviceAdvertiser.startAdvertisingPeer()  // Starts advertising to find connections
        
        // Sets up the browser to find nearby peers that are also using this service type.
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: MultipeerSession.serviceType)
        serviceBrowser.delegate = self  // Assigns this class as the browser delegate
        serviceBrowser.startBrowsingForPeers()  // Starts searching for peers
    }
    
    // Sends data to all connected peers in the session.
    func sendToAllPeers(_ data: Data) {
        do {
            // Tries to send the provided data reliably to all connected peers.
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            // Logs an error if sending fails.
            print("error sending data to peers: \(error.localizedDescription)")
        }
    }
    
    // Returns a list of currently connected peers.
    var connectedPeers: [MCPeerID] {
        return session.connectedPeers
    }
}

// MARK: - MCSessionDelegate (Handles session events)
extension MultipeerSession: MCSessionDelegate {
    
    // Called when a peer's connection state changes (e.g., connected, disconnected).
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // Not implemented, but could be used to update UI or handle connection changes.
    }
    
    // Called when data is received from a peer.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        receivedDataHandler(data, peerID)  // Calls the function to process the received data.
    }
    
    // Called when a peer tries to send a data stream (not supported in this app).
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        fatalError("This service does not send/receive streams.")  // Causes the app to crash if this method is triggered.
    }
    
    // Called when a peer starts sending a resource file (not supported in this app).
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        fatalError("This service does not send/receive resources.")
    }
    
    // Called when a peer finishes sending a resource file (not supported in this app).
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This service does not send/receive resources.")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (Handles peer discovery)
extension MultipeerSession: MCNearbyServiceBrowserDelegate {
    
    /// - Tag: FoundPeer
    // Called when a new peer is found.
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Sends an invitation to the discovered peer to join the session.
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    // Called when a previously discovered peer is lost.
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // This app does not track lost peers, so no action is taken.
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate (Handles incoming connection requests)
extension MultipeerSession: MCNearbyServiceAdvertiserDelegate {
    
    /// - Tag: AcceptInvite
    // Called when another peer invites this device to join a session.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Automatically accepts the invitation and joins the session.
        invitationHandler(true, self.session)
    }
}

