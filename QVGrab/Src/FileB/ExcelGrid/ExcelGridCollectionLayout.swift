//
//  ExcelGridCollectionLayout.swift
//  iOS
//
//  Created by Cityu on 2025/7/16.
//  Copyright © 2025 Cityu. All rights reserved.
//

import UIKit


class ExcelGridCollectionLayout: UICollectionViewLayout {
    var itemWidths: [CGFloat] = []
    var nameHeight: CGFloat = 0
    var itemHeight: CGFloat = 0
    
    var lineSpacing: CGFloat = 0
    var interitemSpacing: CGFloat = 0
    
    private var numberOfCols: Int = 0
    private var numberOfRows: Int = 0
    
    override func prepare() {
        super.prepare()
        numberOfCols = itemWidths.count
        numberOfRows = collectionView?.dataSource?.numberOfSections?(in: collectionView!) ?? 0
    }
    
    override var collectionViewContentSize: CGSize {
        var width: CGFloat = 0
        if numberOfCols > 0 {
            for iw in itemWidths {
                width += iw
            }
            width += CGFloat(numberOfCols - 1) * interitemSpacing
        }
        
        let rows = numberOfRows
        var height: CGFloat = 0
        if nameHeight > 0 {
            height += nameHeight
        } else {
            height += itemHeight
        }
        if rows > 1 {
            height += CGFloat(rows - 1) * (itemHeight + lineSpacing)
        }
        return CGSize(width: width, height: height)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attrs: [UICollectionViewLayoutAttributes] = []
        for row in 0..<numberOfRows {
            for col in 0..<numberOfCols {
                let indexPath = IndexPath(item: col, section: row)
                if let attr = layoutAttributesForItem(at: indexPath) {
                    if rect.intersects(attr.frame) {
                        attrs.append(attr)
                    }
                }
            }
        }
        return attrs
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let col = indexPath.item
        let row = indexPath.section
        
        let w = itemWidths[col]
        var x: CGFloat = 0
        for i in 0..<col {
            x += itemWidths[i]
        }
        if col > 0 {
            x += CGFloat(col) * interitemSpacing
        }
        
        var h: CGFloat = 0
        var y: CGFloat = 0
        if row == 0 {
            if nameHeight > 0 {
                h = nameHeight
            } else {
                h = itemHeight
            }
            y = 0
        } else {
            h = itemHeight
            if nameHeight > 0 {
                y = nameHeight
            } else {
                y = itemHeight
            }
            y += lineSpacing
            
            if row > 1 {
                y += CGFloat(row - 1) * (itemHeight + lineSpacing)
            }
        }
        
        attr.frame = CGRect(x: x, y: y, width: w, height: h)
        return attr
    }
}
