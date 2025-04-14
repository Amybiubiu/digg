//
//  SLCustomFlowLayout.m
//  digg
//
//  Created by Tim Bao on 2025/1/17.
//

#import "SLCustomFlowLayout.h"

@protocol UICollectionViewDelegateLeftAlignedLayout <UICollectionViewDelegateFlowLayout>

@end

@implementation UICollectionViewLayoutAttributes (LeftAligned)

- (void)leftAlignFrameWithSectionInset:(UIEdgeInsets)sectionInset
{
    CGRect frame = self.frame;
    frame.origin.x = sectionInset.left;
    self.frame = frame;
}

@end

#pragma mark -

@implementation SLCustomFlowLayout

#pragma mark - UICollectionViewLayout

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *originalAttributes = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *updatedAttributes = [NSMutableArray arrayWithArray:originalAttributes];
    
    for (UICollectionViewLayoutAttributes *attributes in updatedAttributes) {
        if (attributes.representedElementKind == nil) {
            NSIndexPath *indexPath = attributes.indexPath;
            attributes.frame = [self layoutAttributesForItemAtIndexPath:indexPath].frame;
        }
    }
    
    return updatedAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *currentItemAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    if (indexPath.item == 0) {
        // 第一个元素直接放在左上角
        CGRect frame = currentItemAttributes.frame;
        frame.origin.x = self.sectionInset.left;
        frame.origin.y = self.sectionInset.top;
        currentItemAttributes.frame = frame;
        return currentItemAttributes;
    }
    
    // 获取前一个元素的布局属性
    NSIndexPath *previousIndexPath = [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section];
    UICollectionViewLayoutAttributes *previousItemAttributes = [super layoutAttributesForItemAtIndexPath:previousIndexPath];
    
    // 计算当前元素的frame
    CGRect frame = currentItemAttributes.frame;
    CGFloat previousItemMaxX = CGRectGetMaxX(previousItemAttributes.frame);
    
    // 检查是否需要换行
    if (previousItemMaxX + self.minimumInteritemSpacing + frame.size.width <= self.collectionViewContentSize.width - self.sectionInset.right) {
        // 不需要换行，放在前一个元素的右侧
        frame.origin.x = previousItemMaxX + self.minimumInteritemSpacing;
        frame.origin.y = previousItemAttributes.frame.origin.y;
    } else {
        // 需要换行，放在下一行的左侧
        frame.origin.x = self.sectionInset.left;
        frame.origin.y = CGRectGetMaxY(previousItemAttributes.frame) + self.minimumLineSpacing;
    }
    
    currentItemAttributes.frame = frame;
    return currentItemAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end
