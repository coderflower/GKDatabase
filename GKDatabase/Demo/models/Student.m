//
//  Student.m
//  GKDatabase
//
//  Created by 花菜ChrisCai on 2016/7/19.
//  Copyright © 2016年 花菜ChrisCai. All rights reserved.
//

#import "Student.h"

@implementation Student
/// 不存入数据库
- (NSArray *)notSaveToDatabaseFormAttributesList{
    return @[@"score"];
}
@end
