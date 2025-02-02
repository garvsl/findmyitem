import ARKit  // Import ARKit to use AR-related functionalities

// Define a protocol (similar to a trait in Rust) that classes can adopt
protocol ItemListDragProtocol: class {
    func closeItemList()  // Function to close the item list (no implementation here, just defining it)
    func showDirection(of object: ARItem)  // Function to show direction to a specific AR item
}

// Define a struct (like a simple data container) to represent an AR item
// NOTE: may need to add posioning logic here
struct ARItem {
    let name: String  // Name of the item
    let anchor: ARAnchor  // ARKit anchor that stores the item's position in the AR world
}

// Define a class to manage AR items (like a singleton pattern in Rust)
class ItemModel {

    // Create a shared instance of ItemModel (Singleton pattern - ensures only one instance exists)
    static let shared = ItemModel()

    // Private array to store a list of AR items
    private var itemsList: [ARItem] = []

    // Function to get the list of all stored AR items
    public func getList() -> [ARItem] {
        print("The item lists are : \(itemsList)")
        return itemsList
    }
    
    // Function to add a new AR item to the list
    public func addItem(name: String, anchor: ARAnchor) {
        let item = ARItem(name: name, anchor: anchor)  // Create a new ARItem
        itemsList.append(item)  // Add the new item to the list
    }
    
    // Function to remove all AR items from the list
    public func removeAll() {
        itemsList.removeAll()  // Clears the entire list
    }
}

