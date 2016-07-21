//
//  GKDatabaseManager.h
//  SQLite3封装
//
//  Created by 花菜ChrisCai on 2016/7/16.
//  Copyright © 2016年 花菜ChrisCai. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger ,QueryType){
    QueryTypeWHERE = 0,
    QueryTypeAND,
    QueryTypeOR
};

typedef NS_ENUM(NSInteger ,GKDatabaseSelectLocation){
    /// 以某个字符串开头
    GKDatabaseSelectStartWithString = 0,
    /// 包含有某个字符串
    GKDatabaseSelectRangOfString,
    /// 以某个字符串结尾
    GKDatabaseSelectEndWithString
};

/**
 *  使用该封装文件请注意
 *  0. 在程序运行完毕时执行 [[GKDatabaseManager sharedManager] openDatabase];打开数据库,数据库名称默认为应用程序名称.sqlite
 *  1. 使用该封装文件要先导入libsqlite3.0.tbd
 *  2. 数据库表格名为传入的类名
 *  3. 数据库路径默认为Caches文件内
 *  4. 默认主键为t_default_id
 *  6. id的参数传入应为[Modle class]
 *  7. 传入类中存在数组或者字典会以json文件的方式进行储存
 *  8. 查询数据前需要先调用 - (BOOL)openDatabase 打开数据库;
 *  9. 模型属性不能以index做为属性,index为数据库关键字
 */


@interface GKDatabaseManager : NSObject
/// 获取全局数据库单例
+ (instancetype)sharedManager;
/**
 *  打开数据库
 *
 *  @return 成功/失败
 */
- (BOOL)openDatabase;
/**
 *  根据类名创建表格,默认主键为t_default_id
 *
 *  @param className  类名[Person class]
 */
- (BOOL)creatTableWithClassName:(id)className;

#pragma mark -
#pragma mark - =============== 插入数据 ===============
/**
 *  插入数据
 *  该方法会将模型对象插入到对象类型所对应的表格中 
 *  @param object 模型对象
 */
- (BOOL)insertDataFromObject:(id)object;

#pragma mark -
#pragma mark - =============== 查询数据 ===============
/**
 *  获取表格中所有数据,
 */
- (NSArray *)selecteDataWithClass:(id)className;

/**
 *  获取表格中数据行数
 */
- (NSInteger)getTotalRowsFormClass:(id)className;

/**
 *  获取表格中第n条数据
 */
- (id)selecteFormClass:(id)className index:(NSInteger)index;

/**
 *  单条件查询
 *
 *  @param obj   类名
 *  @param key   属性名 例 @"name"
 *  @param opt   符号 例 @"=" > < 
 *  @param value 值 例 @"zhangsan"
 *
 *  @return 查询结果
 */
- (NSArray *)selectObject:(Class)className key:(id)key operate:(NSString *)operate value:(id)value;

/**
 *  自定义语句查询
 *
 *  @param sqlString 自定义的sql语句
 *  @param className 类名
 *
 *  @return 查询结果
 */
- (NSArray *)selecteDataWithSqlString:(NSString *)sqlString class:(id)className;

/**
 *  数据库模糊查询（单条件）
 *
 *  @param obj          类
 *  @param propertyName 属性名也是字段名
 *  @param type         模糊查询的位置类型
 *  @param content      查询的字符串
 *
 *  @return 查询内容
 */
- (NSArray *)selectObject:(Class)className propertyName:(NSString *)propertyName type:(GKDatabaseSelectLocation)type content:(NSString *)content;

#pragma mark -
#pragma mark - =============== 更新数据 ===============
/**
 *  数据更新
 *
 *  @param obj             类名
 *  @param oldValues   要更新的内容 例 @【@"name=lisi"】
 *  @param conditionType   条件类型 例 OR 或者 AND
 *  @param newValues 更新条件 例 @【@"id=5"，@"name=zhangsan"】
 */
- (BOOL) updateObject:(Class)className oldValues:(NSArray *)oldValues conditionType:(QueryType)conditionType newValues:(NSArray *)newValues;

#pragma mark -
#pragma mark - =============== 删除数据 ===============
/**
 *  删除数据
 *
 *  @param className 类名
 *  @param string    删除语句,字符串需要加上单引号 例@"name = 'Chris'" / @"id = 1234" / @"integer > 1234";
 *
 *  @return 删除结果
 */
- (BOOL)deleteObject:(Class)className withString:(NSString *)string;

/**
 *  清空数据库某表格的内容
 *
 *  @param className 类名
 *
 *  @return 清空结果
 */
- (BOOL)clearTableWithName:(id)className;

/**
 *  删除数据库表格
 *
 *  @param className 类名
 *
 *  @return 删除结果
 */
- (BOOL)deleteTableWithTableName:(id)className;
@end
