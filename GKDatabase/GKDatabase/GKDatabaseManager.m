//
//  GKDatabaseManager.m
//  SQLite3封装
//
//  Created by 花菜ChrisCai on 2016/7/16.
//  Copyright © 2016年 花菜ChrisCai. All rights reserved.
//

#import "GKDatabaseManager.h"
#import <sqlite3.h>
#import <objc/runtime.h>
#import "GKObjcProperty.h"
static GKDatabaseManager * _manager;
/** 数据库实例 */
static sqlite3 *database;
@implementation GKDatabaseManager
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}
#pragma mark -
#pragma mark - =============== 创建表格 ===============
- (BOOL)creatTableWithClassName:(id)className {
    
    if (![self openDatabase ]) {
        return NO;
    }
    // 1. 获取创建sql语句
    NSString * sqlString = [self getCreateTableSQLStringWithClass:className];
    NSLog(@"%@",sqlString);
    // 2. 执行语句
    return [self executeSqlString:sqlString];
}

/// 打开数据库
- (BOOL)openDatabase {
    // 获取应用程序名称
    NSString *prodName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    // 0.获取沙盒中的数据库文件名
    NSString *fileName = [self cachesPathWithFileNmae:[NSString stringWithFormat:@"%@.sqlite",prodName]];
    // 1.打开数据库(如果数据库文件不存在,会自动创建)
    int result = sqlite3_open(fileName.UTF8String, &database);
    if (result == SQLITE_OK) {
        return YES;
    }else {
        return NO;
    }
}

#pragma mark -
#pragma mark - =============== 执行sql语句 ===============
/// 执行sql语句
- (BOOL)executeSqlString:(NSString *)sqlString {
    char *error = NULL;
    int result = sqlite3_exec(database, sqlString.UTF8String, NULL, NULL, &error);
    if (result == SQLITE_OK) {
        return YES;
    }else {
        NSLog(@"语句执行失败,错误信息是:%s", error);
        return NO;
    }
}

#pragma mark -
#pragma mark - =============== 插入数据 ===============
/// 插入数据
- (BOOL)insertDataFromObject:(id)object {
    // 创建可变字符串用于拼接sql语句
    NSMutableString * sqlString = [NSMutableString stringWithFormat:@"insert into %@ (",NSStringFromClass([object class])];
    [[GKObjcProperty getUserNeedAttributeListWithClass:[object class]] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 拼接字段名
        [sqlString appendFormat:@"%@,",obj];
    }];
    // 去掉后面的逗号
    [sqlString deleteCharactersInRange:NSMakeRange(sqlString.length-1, 1)];
    // 拼接values
    [sqlString appendString:@") values ("];
    
    // 拼接字段值
    [[GKObjcProperty getSQLProperties:[object class]] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        // 拼接属性
        if ([object valueForKey:key]){
            if ([obj isEqualToString:@"text"]) {
                [sqlString appendFormat:@"'%@',",[object valueForKey:key]];
            } else if ([obj isEqualToString:@"customArr"] || [obj isEqualToString:@"customDict"]) { // 数组字典转处理
                NSData * data = [NSJSONSerialization dataWithJSONObject:[object valueForKey:key] options:0 error:nil];
                NSString * jsonString = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
                [sqlString appendFormat:@"'%@',",jsonString];
            }else if ([obj isEqualToString:@"blob"]){ // NSData处理
                NSString * jsonString = [[NSString alloc] initWithData:[object valueForKey:key] encoding:(NSUTF8StringEncoding)];
                [sqlString appendFormat:@"'%@',",jsonString];
            }else {
                [sqlString appendFormat:@"%@,",[object valueForKey:key]];
            }
        }else {// 没有值就存NULL
            [sqlString appendFormat:@"'%@',",[object valueForKey:key]];
        }
    }];
    // 去掉后面的逗号
    [sqlString deleteCharactersInRange:NSMakeRange(sqlString.length-1, 1)];
    // 添加后面的括号
    [sqlString appendFormat:@");"];
    // 执行语句
    return [self executeSqlString:sqlString];
}

#pragma mark -
#pragma mark - =============== 查询数据 ===============

/// 获取表格中数据行数
- (NSInteger)getTotalRowsFormClass:(id)className {
    return [self selecteDataWithClass:className].count;
}

/// 获取表格中第n条数据
- (id)selecteFormClass:(id)className index:(NSInteger)index {
    
    if ([self getTotalRowsFormClass:className] > index) { // 判断是否越界
        return [self selecteDataWithClass:className][index];
    }
    return nil;
}

/// 单条件查询
- (NSArray *)selectObject:(Class)className key:(id)key operate:(NSString *)operate value:(id)value {
    
    NSString *sqlString = [NSString stringWithFormat:@"select * from %@ where %@ %@ '%@';",NSStringFromClass([className class]),key,operate,value];
    NSArray * arr = [self selecteDataWithSqlString:sqlString class:className];
    
    return arr;
}

- (NSArray *)selectObject:(Class)className propertyName:(NSString *)propertyName type:(GKDatabaseSelectLocation)type content:(NSString *)content {
    
    if (!propertyName.length || !propertyName) {
        NSLog(@"属性名有误");
        return nil;
    }
    
    NSString *sqlString = nil;
    switch (type) {
        case GKDatabaseSelectStartWithString:
            sqlString = [NSString stringWithFormat:@"select * from %@ where %@ like '%@%%'",NSStringFromClass([className class]),propertyName,content];
            break;
        case GKDatabaseSelectRangOfString:
            sqlString = [NSString stringWithFormat:@"select * from %@ where %@ like '%%%@%%'",NSStringFromClass([className class]),propertyName,content];
            break;
        case GKDatabaseSelectEndWithString:
            sqlString = [NSString stringWithFormat:@"select * from %@ where %@ like '%%%@'",NSStringFromClass([className class]),propertyName,content];
            break;
            
        default:
            break;
    }
    return [self selecteDataWithSqlString:sqlString class:className];
}

/// 获取表格中所有数据
- (NSArray *)selecteDataWithClass:(id)className {
    // 拼接sql语句
    NSString * sqlString = [NSMutableString stringWithFormat:@"select * from %@",NSStringFromClass([className class])];
    return [self selecteDataWithSqlString:sqlString class:className ];
}

/// 自定义语句查询
- (NSArray *)selecteDataWithSqlString:(NSString *)sqlString class:(id)className  {
    
    // 创建模型数组
    NSMutableArray *models = nil;
    // 1.准备查询
    sqlite3_stmt *stmt; // 用于提取数据的变量
    int result = sqlite3_prepare_v2(database, sqlString.UTF8String, -1, &stmt, NULL);
    // 2.判断是否准备好
    if (SQLITE_OK == result) {
        models = [NSMutableArray array];
        // 获取属性列表名数组 比如name
        NSArray * arr = [GKObjcProperty getUserNeedAttributeListWithClass:[className class]];
        // 获取属性列表名和sql数据类型 比如  name : text
        NSDictionary * dict = [GKObjcProperty getSQLProperties:[className class]];
        // 准备好了
        while (SQLITE_ROW == sqlite3_step(stmt)) { // 提取到一条数据
            __block id objc = [[[className class] alloc]init];
            for ( int i = 0; i < arr.count; i++) {
                // 默认第0个元素为表格主键 所以元素从第一个开始
                // 使用KVC完成赋值
                if ([dict[arr[i]] isEqualToString:@"text"]) {
                    [objc setValue:[NSString stringWithFormat:@"%@",[self textForColumn:i + 1  stmt:stmt]] forKey:arr[i]];
                    
                } else if ([dict[arr[i]] isEqualToString:@"real"]) {
                    [objc setValue:[NSString stringWithFormat:@"%f",[self doubleForColumn:i + 1  stmt:stmt]] forKey:arr[i]];
                    
                } else if ([dict[arr[i]] isEqualToString:@"integer"]) {
                    
                    [objc setValue:[NSString stringWithFormat:@"%i",[self intForColumn:i + 1  stmt:stmt]] forKey:arr[i]];
                    
                } else if ([dict[arr[i]] isEqualToString:@"customArr"]) { // 数组处理
                    
                    NSString * str = [self textForColumn:i + 1 stmt:stmt];
                    NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
                    NSArray * resultArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    [objc setValue:resultArray forKey:arr[i]];
                }  else if ([dict[arr[i]] isEqualToString:@"customDict"]) { // 字典处理
                    
                    NSString * str = [self textForColumn:i + 1 stmt:stmt];
                    NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
                    NSDictionary * resultDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    [objc setValue:resultDict forKey:arr[i]];
                } else if ([dict[arr[i]] isEqualToString:@"blob"]) { // 二进制处理
                    
                    NSString * str = [self textForColumn:i + 1 stmt:stmt];
                    NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
                    [objc setValue:data forKey:arr[i]];
                }
            }
            [models addObject:objc];
        }
    }
    return [models copy];
}
- (int)intForColumn:(int)index stmt:(sqlite3_stmt *)stmt {
    return sqlite3_column_int(stmt, index);
}

- (double)doubleForColumn:(int)index stmt:(sqlite3_stmt *)stmt {
    return sqlite3_column_double(stmt, index);
}

- (NSString *)textForColumn:(int)index stmt:(sqlite3_stmt *)stmt {
    return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, index)];
    
}

#pragma mark -
#pragma mark - =============== 数据更新 ===============
- (BOOL) updateObject:(Class)className oldValues:(NSArray *)oldValues conditionType:(QueryType)conditionType newValues:(NSArray *)newValues {
   
    if (![self openDatabase]) {
        NSLog(@"请先执行[[GKDatabaseManager sharedManager]openDatabase];打开数据库 ");
        return NO;
    }

    if (![self dataProcessingWithArray:oldValues class:className]) {
        NSLog(@"更新内容有误");
        return NO;
    }
    if (![self dataProcessingWithArray:newValues class:className]) {
        NSLog(@"更新条件有误");
        return NO;
    }
    // 拼接sql语句
    NSMutableString *sqlString = [[NSMutableString alloc] initWithFormat:@"update %@ set ",NSStringFromClass([className class])];
    
    [[self dataProcessingWithArray:newValues class:className] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [sqlString appendFormat:@"%@,",obj];
    }];
    
    [sqlString deleteCharactersInRange:NSMakeRange(sqlString.length-1, 1)];
    [sqlString appendString:@" where "];
    
    if (conditionType == 0) {
        NSLog(@"%@ 选择错误",[self typeToString:conditionType]);
        return NO;
    } else {
        [[self dataProcessingWithArray:oldValues class:className] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [sqlString appendFormat:@"%@ %@ ",obj,[self typeToString:conditionType]];
            
        }];
    }

    NSRange rang = NSMakeRange(sqlString.length-[self typeToString:conditionType].length-1, [self typeToString:conditionType].length+1);
    [sqlString deleteCharactersInRange:rang];
    return [self executeSqlString:sqlString];
}
- (NSString *)typeToString:(QueryType)type{
    switch (type) {
        case QueryTypeWHERE:
            return @"where";
            break;
        case QueryTypeAND:
            return @"and";
            break;
        case QueryTypeOR:
            return @"or";
            break;
        default:
            break;
    }
}

/**
 *  数据处理
 *
 *  @param arr 更新内容或者更新条件 例@【@“name=lisi”】
 *
 *  @return 处理结果 例 @[@"name=‘lisi’"]
 */
- (NSArray *)dataProcessingWithArray:(NSArray *)arr  class:(id)className {
    NSMutableArray *muarr  = [NSMutableArray array];
    
    [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSArray *array = [self ConditionProcessingWithString:obj];
        
        BOOL isExist = [self attributeIsExistWithString:array[0] class:className];
        
        if (isExist) {
            NSString *str = [self syntheticNewStringWithArray:array class:className];
            [muarr addObject:str];
        }
        
    }];
    return muarr;
}
/**
 *  判断属性是否存在
 *
 *  @param string 属性名
 *  @param className    类名
 *
 *  @return YES 表示 存在
 */
- (BOOL)attributeIsExistWithString:(NSString *)string  class:(id)className {
   
    NSArray *AttributeList = [GKObjcProperty getUserNeedAttributeListWithClass:className];
    
    __block BOOL isExist = NO;
    [AttributeList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:string]) {
            isExist = YES;
            *stop = YES;
        }
    }];
    return isExist;
}

/**
 *  组合成新的字符串
 *
 *  @param arr 要组合的数组
 *  @param className 类名
 *
 *  @return 新字符串
 */
- (NSString *)syntheticNewStringWithArray:(NSArray *)arr class:(id)className {
    
    NSDictionary *dic = [GKObjcProperty getSQLProperties:className];
    
    NSString *value = [dic valueForKey:arr[0]];
    
    if ([value isEqualToString:@"text"]) {
        return [NSString stringWithFormat:@"%@%@'%@'",arr[0],arr[1],arr[2]];
    } else if ([value isEqualToString:@"blob"]) {
        return [NSString stringWithFormat:@"%@%@%@",arr[0],arr[1],[arr[2] dataUsingEncoding:NSUTF8StringEncoding]];
    }  else {
        return [NSString stringWithFormat:@"%@%@%@",arr[0],arr[1],arr[2]];
    }
}

/**
 *  数据处理
 *
 *  @param string 条件字符串 例@"id=1234" / "id = 1234"
 *
 *  @return 例 @【@"id"，@"="，@"1234"】
 */
- (NSArray *)ConditionProcessingWithString:(NSString *)string {
    if ([string containsString:@" "]) { // 如果有空格就去除空格再处理
        string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    if ([string rangeOfString:@">="].location != NSNotFound) {
        NSArray *arr = [string componentsSeparatedByString:@">="];
        
        return @[arr[0],@">=",arr[1]];
    } else if ([string rangeOfString:@"<="].location != NSNotFound) {
        NSArray *arr = [string componentsSeparatedByString:@"<="];
        
        return @[arr[0],@"<=",arr[1]];
    } else if ([string rangeOfString:@"="].location != NSNotFound) {
        
        NSArray *arr = [string componentsSeparatedByString:@"="];
        
        return @[arr[0],@"=",arr[1]];
    }  else if ([string rangeOfString:@">"].location != NSNotFound) {
        NSArray *arr = [string componentsSeparatedByString:@">"];
        
        return @[arr[0],@">",arr[1]];
    }  else if ([string rangeOfString:@"<"].location != NSNotFound) {
        NSArray *arr = [string componentsSeparatedByString:@"<"];
        
        return @[arr[0],@"<",arr[1]];
    }
    return nil;
}

#pragma mark -
#pragma mark - =============== 数据删除 ===============
/// 删除指定对象
- (BOOL)deleteObject:(id)object {
    // 获取类的属性和sql类型
    NSDictionary * propertsDict = [GKObjcProperty getSQLProperties:[object class]];
    // 拼接字符串
    NSMutableString * sqlString = [NSMutableString string];
    [propertsDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        if ([value isEqualToString:@"integer"] || [value isEqualToString:@"real"]) {
            [sqlString appendFormat:@"%@ = %@ and",key , [object valueForKey:key]];
        }else {
            [sqlString appendFormat:@"%@ = '%@' and ",key , [object valueForKey:key]];
        }
    }];
    // 删除最后多余的and
    NSRange rang = NSMakeRange(sqlString.length-@"and".length-1, @"and".length+1);
    [sqlString deleteCharactersInRange:rang];
    
    return [self deleteObject:[object class] withString:sqlString];
}

/// 数据删除
- (BOOL)deleteObject:(Class)className withString:(NSString *)string {
    // 判断数据库有没有打开
    if (![self openDatabase]) {
        NSLog(@"请先执行[[GKDatabaseManager sharedManager]openDatabase];打开数据库");
        return NO;
    }
    NSString * sqlString = [NSString stringWithFormat:@"delete from %@ where %@;",[className class],string];
    return [self executeSqlString:sqlString];
}

/// 清空数据库某表格的内容
- (BOOL)clearTableWithName:(id)className {

    if (![self openDatabase]) {
        NSLog(@"请先执行[[GKDatabaseManager sharedManager]openDatabase];打开数据库");
        return NO;
    }
    
    NSString *sqlString = [NSString stringWithFormat:@"delete from %@",[className class]];
    return [self executeSqlString:sqlString];
}

/**
 *  删除数据库表格
 *
 *  @param className 类名
 *
 *  @return 删除结果
 */
- (BOOL)deleteTableWithTableName:(id)className {
    
    if (![self openDatabase]) {
        return NO;
    }
    
    NSString *sqlString = [NSString stringWithFormat:@"drop table %@",[className class]];
    
    return [self executeSqlString:sqlString];
}

#pragma mark -
#pragma mark - =============== 获取创表语句 ===============
/// 获取创表语句
- (NSString *)getCreateTableSQLStringWithClass:(id)className {
    
    return [self createTableWithTableName:NSStringFromClass([className class]) dict:[GKObjcProperty getSQLProperties:className]];
}

- (NSString *)createTableWithTableName:(NSString *)tableName dict:(NSDictionary *)dict {
    
    NSMutableString *sqlMuString;
    // 拼接sql语句
    sqlMuString = [NSMutableString stringWithFormat:@"create table if not exists %@ (t_default_id integer primary key autoincrement,",tableName];
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [sqlMuString appendFormat:@"%@ %@,",key,obj];
    }];
    
    // 去除最后的逗号
    NSRange rang = NSMakeRange(sqlMuString.length-1, 1);
    
    [sqlMuString deleteCharactersInRange:rang];
    
    [sqlMuString appendString:@")"];
    
    return sqlMuString;
}

#pragma mark -
#pragma mark - =============== 获取caches文件全路径 ===============
- (NSString *)cachesPathWithFileNmae:(NSString *)fileName {
    
    NSString *newStr = [fileName lastPathComponent];
    
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    
    NSString *cachesFile = [cachesPath stringByAppendingPathComponent:newStr];
    
    return cachesFile;
}
@end
