import ARKit  // Importing ARKit, which is used for augmented reality features.

// MARK: - Extension for CGImagePropertyOrientation
// This extension converts the device's orientation into an image orientation
extension CGImagePropertyOrientation {
    init(_ deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portraitUpsideDown:
            self = .left  // When the device is upside down, the image needs to be rotated left.
        case .landscapeLeft:
            self = .up    // If the device is in landscape left mode, the image remains upright.
        case .landscapeRight:
            self = .down  // If the device is in landscape right mode, the image is flipped upside down.
        default:
            self = .right // The default is right (normal portrait mode).
        }
    }
}

// MARK: - Extension for Double
// Adds utility functions to convert between degrees and radians
extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0  // Converts degrees to radians (useful for rotation calculations).
    }
    
    func toDegrees() -> Double {
        return self * 180.0 / .pi  // Converts radians to degrees.
    }
}

// MARK: - Extension for SCNGeometry
// Adds a function to create a line geometry between two points in 3D space.
extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]  // Defines a line with two points.
        
        // Creates a geometry source with the two points.
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        
        // Defines the connection between points as a line.
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        // Returns a geometry object representing the line.
        return SCNGeometry(sources: [source], elements: [element])
    }
}

// MARK: - Extension for SCNVector3
// Adds a function to extract position coordinates from a transformation matrix.
extension SCNVector3 {
    // This function converts a 4x4 transformation matrix into an SCNVector3 position.
    // It is based on Apple's demo app.
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        // The position is stored in the fourth column of the matrix.
        // Extracting x, y, and z gives us the object's position in 3D space.
    }
}
