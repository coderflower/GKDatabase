//
//  GKObjcProperty.h
//  SQLite3封装
//
//  Created by 花菜ChrisCai on 2016/7/16.
//  Copyright © 2016年 花菜ChrisCai. All rights reserved.
//  本类为文件管理解析类，主要负责属性的获取
#pragma mark -
#pragma mark - =============== 本类为文件管理解析类，主要负责文件路径的获取，SQL语句的拼接等 ===============
#import <Foundation/Foundation.h>
@protocol GKObjcPropertyDelegate <NSObject>

@optional
/**
 *  不保存到数据库的属性列表
 *
 *  @return 属性列表
 */
- (NSArray *)notSaveToDatabaseFormAttributesList;

@end
/**
 *  本类主要用于属性获取
 */
@interface GKObjcProperty : NSObject

@property (nonatomic,strong) id<GKObjcPropertyDelegate> delegate;
/**
 *  获取属性名列表 例 name
 *
 *  @param className 类名
 *
 *  @return 属性名列表
 */
+ (NSArray *)getUserNeedAttributeListWithClass:(id)className;

/**
 *  获取类中的属性和类型为数据库类型 例{@"name":@"text"}
 *
 *  @param className 类名
 *
 *  @return 类中的属性和类型, 属性名为key，属性数据库类型为value
 */
+ (NSDictionary *)getSQLProperties:(id)className;
@end
