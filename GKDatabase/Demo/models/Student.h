//
//  Student.h
//  GKDatabase
//
//  Created by 花菜ChrisCai on 2016/7/19.
//  Copyright © 2016年 花菜ChrisCai. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface Student : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) NSInteger age;
@property(nonatomic, assign) CGFloat score;
@property(nonatomic, strong) NSArray *books;
@end
