//
//  CategoriesCollectionViewCell.swift
//  Podcast
//
//  Created by Drew Dunne on 9/28/16.
//  Copyright © 2016 Cornell App Development. All rights reserved.
//

import UIKit

class CategoriesCollectionViewCell: UICollectionViewCell {
    
    //
    // Mark: Constants
    //
    private let labelHeight:CGFloat = 22.0
    private let labelPadding:CGFloat = 4
    private var categoryNameLabel: UILabel!
    
    //
    // Mark: Variables
    //
    var categoryName: String? {
        didSet {
            if let categoryName = categoryName {
                categoryNameLabel.text = categoryName
            }
        }
    }
    
    //
    // Mark: Init
    //
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.red
        
        let yPos = (frame.size.height-labelHeight)/2
        let width = frame.size.width-2*labelPadding
        categoryNameLabel = UILabel(frame: CGRect(x: 4,y: yPos,width: width,height: labelHeight))
        categoryNameLabel.textAlignment = .center
        categoryNameLabel.lineBreakMode = .byWordWrapping
        categoryNameLabel.font = UIFont(name: "Avenir", size: 16.0)
        categoryNameLabel.textColor = UIColor.black
        contentView.addSubview(categoryNameLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
}
