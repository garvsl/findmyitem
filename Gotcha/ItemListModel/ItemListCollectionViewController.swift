import UIKit  // Importing UIKit, which provides the UI components needed for the collection view

// Defining a constant for the cell reuse identifier
private let reuseIdentifier = "Cell"

// This class manages the collection view that displays a list of items
class ItemListCollectionViewController: UICollectionViewController {

    // A weak reference to the delegate that handles actions related to item selection
    weak var delegate: ItemListDragProtocol?
    
    // Called when the view is loaded into memory
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: UICollectionViewDataSource (Handles data for the collection view)

    // Defines the number of sections in the collection view (only one section in this case)
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    // Returns the number of items in the section, which corresponds to the number of items in the shared ItemModel list
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ItemModel.shared.getList().count
    }

    // Configures and returns each cell in the collection view
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Reuses or creates a new cell with the specified identifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        
        // Finds the label inside the cell (assumes it has a tag of 1) and sets its text to the item's name
        if let label = cell.viewWithTag(1) as? UILabel {
            label.text = ItemModel.shared.getList()[indexPath.row].name
        }

        // Sets the cell's background color to a semi-transparent green
        cell.backgroundColor = UIColor.green.withAlphaComponent(0.45)

        // Rounds the corners of the cell to make it look softer
        cell.layer.cornerRadius = 20

        return cell
    }

    // MARK: UICollectionViewDelegate (Handles user interaction with the collection view)
    
    // Called when a user selects a cell in the collection view
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Closes the item list (handled by the delegate)
        delegate?.closeItemList()
        
        // Triggers navigation toward the selected object (handled by the delegate)
        delegate?.showDirection(of: ItemModel.shared.getList()[indexPath.row])
        
        // Deselects the item so it doesn't remain highlighted
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout (Handles layout customization)
extension ItemListCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    // Defines the size of each cell in the collection view
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 150) // Each cell is 150x150 pixels
    }
    
    // Sets the spacing between rows in the collection view
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10  // There is a 10-pixel gap between rows
    }
}

