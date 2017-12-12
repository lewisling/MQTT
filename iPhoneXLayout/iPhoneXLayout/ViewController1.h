//
//  ViewController1.h
//  iOS11Demo
//
//  Created by 思 彭 on 2017/9/25.
//  Copyright © 2017年 思 彭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ARKit/ARKit.h>

@interface ViewController1 : UIViewController

@end

@interface SelectStudentHeaderView : UICollectionReusableView

@property (nonatomic, strong) UILabel *headerTitleLabel;
@property (nonatomic, strong) UILabel *countLabel; /**<人数 */

@end

@interface SelectStudentFooterView : UICollectionReusableView

@property (nonatomic, strong) UIView *lineView;

@end
