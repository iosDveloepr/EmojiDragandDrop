//
//  ViewController.swift
//  EmojiArt
//
//  Created by Yermakov Anton on 25.02.2018.
//  Copyright © 2018 Yermakov Anton. All rights reserved.
//

import UIKit

extension EmojiArt.EmojiInfo{
    
    init?(label: UILabel){
        if let attributedText = label.attributedText, let font = attributedText.font{
            x = Int(label.center.x)
            y = Int(label.center.y)
            text = attributedText.string
            size = Int(font.pointSize)
        } else {
            return nil
        }
    }
}

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
   
    
    // MARK: - Model
    
    var emojiArt: EmojiArt?{
        get{
            if let url = emojiArtBackgroundImage.url{
                let emojis = emojiArtView.subviews.flatMap { $0 as? UILabel }.flatMap { EmojiArt.EmojiInfo(label: $0)}
                return EmojiArt(url: url, emojis: emojis)
            }
            return nil
        } set {
            emojiArtBackgroundImage = (nil, nil)
            emojiArtView.subviews.flatMap {$0 as? UILabel}.forEach { $0.removeFromSuperview() }
            if let url = newValue?.url{
                imageFetcher = ImageFetcher(fetch: url, handler: { (url, image) in
                    DispatchQueue.main.async {
                        self.emojiArtBackgroundImage = (url, image)
                        newValue?.emojis.forEach {
                            let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
                            self.emojiArtView.addLabel(with: attributedText, centeredAt: CGPoint(x: $0.x, y: $0.y))
                        }
                    }
                })
            }
        }
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        if let json = emojiArt?.json{
            
     let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
     let fileUrl = DocumentDirURL.appendingPathComponent("Untitled.json")
            do {
                try json.write(to: fileUrl)
                print("svae")
            } catch {
                print(error.localizedDescription)
            }
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileUrl = DocumentDirURL.appendingPathComponent("Untitled.json")
        
        if let jsonData = try? Data(contentsOf: fileUrl){
            emojiArt = EmojiArt(json: jsonData)
        }
    }
    

    
    @IBOutlet weak var dropZone: UIView!{
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    var emojiArtView = EmojiArtView()
    
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewWidth.constant = scrollView.contentSize.width
        scrollViewHeight.constant = scrollView.contentSize.height
    }
 
    
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    private var _emojiArtBackgroundImageURL: URL?
    
    var emojiArtBackgroundImage : (url: URL?, image: UIImage?){
        get {
            return (_emojiArtBackgroundImageURL, emojiArtView.backgroundImage)
        } set {
            _emojiArtBackgroundImageURL = newValue.url
            scrollView.zoomScale = 1.0
            emojiArtView.backgroundImage = newValue.image
            let size = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView.contentSize = size
            scrollViewWidth?.constant = size.width
            scrollViewHeight?.constant = size.height
            if let dropZone = self.dropZone, size.width > 0, size.height > 0 {
                scrollView.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
            }
        }
    }
    
    
    var emojis = "😇🙃🐊😟☠️😿🎃🤖👩🏻‍💻👳🏼‍♀️🐷🌥🍎⛄️".map { String($0)}
    
    @IBOutlet weak var emojiCollectionView: UICollectionView!{
        didSet{
            emojiCollectionView.delegate = self
            emojiCollectionView.dataSource = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojis.count
    }
    
    private var font : UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(50.0))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
        
        if let emojiCell = cell as? EmojiCollectionViewCell{
            let text = NSAttributedString(string: emojis[indexPath.row], attributes: [.font : font])
            emojiCell.label.attributedText = text
        }
        
        return cell
    }
    
    
    // Collection view drop
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return drugItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return drugItems(at: indexPath)
    }
    
    private func drugItems(at indexPath: IndexPath) -> [UIDragItem]{
        if let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label.attributedText{
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
            dragItem.localObject = attributedString
            return [dragItem]
        } else {
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator)
    {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                let attributedString = item.dragItem.localObject as! NSAttributedString
                collectionView.performBatchUpdates({
                    emojis.remove(at: sourceIndexPath.item)
                    emojis.insert(attributedString.string, at: destinationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                })
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            } else {
                // no sourceIndexPath, so not local
                let placeholderContext = coordinator.drop(
                    item.dragItem,
                    to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceHolderCell")
                )
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self, completionHandler: { (provider, error) in
                    DispatchQueue.main.async {
                        if let attributedString = provider as? NSAttributedString {
                            placeholderContext.commitInsertion(dataSourceUpdates: { (insertionIndexPath) in
                                self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                            })
                        } else {
                            placeholderContext.deletePlaceholder()
                        }
                    }
                })
            }
        }
        
    }
    
    
    
    
    
    // Drop from i-net to DropView
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    var imageFetcher : ImageFetcher!
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
        imageFetcher = ImageFetcher() { (url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = (url, image)
            }
        }
        
       
        session.loadObjects(ofClass: NSURL.self) { nsurls in
            if let url = nsurls.first as? URL {
                self.imageFetcher.fetch(url)
            }
        }
        
        session.loadObjects(ofClass: UIImage.self) { images in
            if let image = images.first as? UIImage {
                self.imageFetcher.backup = image
            }
        }
    }
} // class

