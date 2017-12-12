//
//  ViewController1.m
//  iOS11Demo
//
//  Created by 思 彭 on 2017/9/25.
//  Copyright © 2017年 思 彭. All rights reserved.
//

#import "ViewController1.h"
static NSString * const SelectStudentListCollectionViewCellId = @"SelectStudentListCollectionViewCellId";
static NSString * const reuseIdentifierHeader = @"HeaderCell";
static NSString * const reuseIdentifierFooter = @"FooterCell";

@interface ViewController1 ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation ViewController1

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    
    [self.view addSubview:self.collectionView];
}

#pragma mark - CollectionViewDataSource && CollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return 8;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SelectStudentListCollectionViewCellId forIndexPath:indexPath];
    cell.backgroundColor = [UIColor greenColor];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionReusableView *supplementaryView;
    
    if (kind == UICollectionElementKindSectionHeader) {
        SelectStudentHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:reuseIdentifierHeader forIndexPath:indexPath];
        headerView.backgroundColor = [UIColor redColor];
        supplementaryView = headerView;
    } else {
        SelectStudentFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:reuseIdentifierFooter forIndexPath:indexPath];
        supplementaryView = footerView;
    }
    return supplementaryView;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - Private Method


#pragma mark - Setter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        [flowLayout setItemSize:CGSizeMake((K_SCREEN_WIDTH - 100) / 4, ((K_SCREEN_WIDTH - 100) / 4) + 30)];
        flowLayout.minimumLineSpacing = 10.0;//行间距(最小值)
        flowLayout.minimumInteritemSpacing = 10.0;//item间距(最小值)
        flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);//设置section的边距
        flowLayout.headerReferenceSize = CGSizeMake(K_SCREEN_WIDTH, 20);
        flowLayout.footerReferenceSize = CGSizeMake(K_SCREEN_WIDTH, 10);
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        _collectionView.showsVerticalScrollIndicator = YES;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, K_SCREEN_WIDTH, K_SCREEN_HEIGHT) collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:SelectStudentListCollectionViewCellId];
        [_collectionView registerClass:[SelectStudentHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:reuseIdentifierHeader];
        [_collectionView registerClass:[SelectStudentFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:reuseIdentifierFooter];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
    }
    return _collectionView;
}

@end

@implementation SelectStudentHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.headerTitleLabel = [[UILabel alloc]init];
        self.headerTitleLabel.layer.masksToBounds = YES;
        self.headerTitleLabel.font = [UIFont fontWithName:@"PingFang-SC-Regular" size:20];
        self.headerTitleLabel.font = [UIFont boldSystemFontOfSize:20];
        self.headerTitleLabel.text = @"未批阅";
        self.headerTitleLabel.textColor = [UIColor redColor];
        [self addSubview:self.headerTitleLabel];
        
        self.countLabel = [[UILabel alloc]init];
        self.countLabel.layer.masksToBounds = YES;
        self.countLabel.font = [UIFont systemFontOfSize:13];
        self.countLabel.text = @"(20人)";
        [self setTextColor:self.countLabel FontNumber:[UIFont systemFontOfSize:13] AndRange:NSMakeRange(0, self.countLabel.text.length) AndColor:[UIColor greenColor]];
        [self addSubview:self.countLabel];
        
    }
    return self;
}

// 设置字符串中数字的颜色
- (void)setTextColor:(UILabel *)label FontNumber:(id)font AndRange:(NSRange)range AndColor:(UIColor *)vaColor
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:label.text];
    NSCharacterSet* nonDigits =[[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    int remainSecond =[[label.text stringByTrimmingCharactersInSet:nonDigits] intValue];
    NSLog(@" num %d ",remainSecond);
    
    NSString *labelText = label.text;
    
    for (int i = 0; i < labelText.length; i ++) {
        //这里的小技巧，每次只截取一个字符的范围
        NSString *a = [labelText substringWithRange:NSMakeRange(i, 1)];
        //判断装有0-9的字符串的数字数组是否包含截取字符串出来的单个字符，从而筛选出符合要求的数字字符的范围NSMakeRange
        NSArray *number = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
        if ([number containsObject:a]) {
            [str setAttributes:@{NSForegroundColorAttributeName:[UIColor redColor],NSFontAttributeName:font} range:NSMakeRange(i, 1)];
        }
    }
    label.attributedText = str;
}
//
//- (void)setFrame:(CGRect)frame {
//    
//    CGRect myFrame = frame;
//    myFrame.size.width = myFrame.size.width - 30;
//    frame = myFrame;
//}

@end

@implementation SelectStudentFooterView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.lineView = [[UIView alloc]initWithFrame:CGRectMake(0, 20, K_SCREEN_WIDTH, 1)];
        [self addSubview:self.lineView];
    }
    return self;
}

@end
