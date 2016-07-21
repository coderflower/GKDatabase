//
//  GKObjcProperty.m
//  SQLite3封装
//
//  Created by 花菜ChrisCai on 2016/7/16.
//  Copyright © 2016年 花菜ChrisCai. All rights reserved.
//

#import "GKObjcProperty.h"
#import <objc/runtime.h>
static GKObjcProperty *databaseFile;
@implementation GKObjcProperty
/**
 *  获取当前文件的对象
 *
 *  @return 对象
 */
+ (GKObjcProperty *)getObject {
    
    @synchronized(self) {
        if (!databaseFile) {
            databaseFile = [[GKObjcProperty alloc] init];
        }
    }
    return databaseFile;
}
#pragma mark =============== 获取属性OC类型列表 ===============
/**
 *  获取属性OC类型列表
 *
 *  @param className 类名
 *
 *  @return 属性类型列表
 */
+ (NSArray *)getUserNeedOCPropertyTypeListWithClass:(id)className {
    
    if (className) {
        [self getObject].delegate = [[[className class] alloc]init];
        if ([[self getObject].delegate respondsToSelector:@selector(notSaveToDatabaseFormAttributesList)]) {
            
            NSArray *userNeedAttributeList = [self getUserNeedAttributeListWithClass:className];
            
            // 获取当前类的所有属性
            unsigned int count;// 记录属性个数
            objc_property_t *properties = class_copyPropertyList([className class], &count);
            
            NSMutableArray *tempArrayM = [NSMutableArray array];
            
            for (NSString *userNeedAttribute in userNeedAttributeList) {
                
                for (int i = 0; i < count; i++) {
                    
                    // objc_property_t 属性类型
                    objc_property_t property = properties[i];
                    
                    NSString *name = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
                    // 转换为Objective C 字符串
                    NSString *type = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
                    if ([name isEqualToString:userNeedAttribute]) {
                        [tempArrayM addObject:[self getAttributesWith:type]];
                    }
                }
            }
            return [tempArrayM copy];
        }
    }
    return [self getOCPropertyTypeListWithClass:className];
}

/**
 *  获取类中所有的属性OC类型列表
 */
+ (NSArray *)getOCPropertyTypeListWithClass:(id)className {
    // 获取当前类的所有属性
    unsigned int count;// 记录属性个数
    objc_property_t *properties = class_copyPropertyList([className class], &count);
    
    NSMutableArray *tempArrayM = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        
        // objc_property_t 属性类型
        objc_property_t property = properties[i];
        
        NSString *name = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        // 转换为Objective C 字符串
        NSString *type = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        if ([name isEqualToString:@"hash"]) {
            break;
        }
        [tempArrayM addObject:[self getAttributesWith:type]];
        
    }
    
    free(properties);
    
    return [tempArrayM copy];
}

#pragma mark =============== 获取属性SQL类型列表 ===============
/// 获取属性SQL类型列表
+ (NSArray *)getUserNeedSQLPropertyTypeListWithClass:(id)className {
    return [self getSQLPropertyTypeListWithClass:className];
}

+ (NSArray *)getSQLPropertyTypeListWithClass:(id)className {
    NSMutableArray *tempArrayM = [NSMutableArray array];
    
    [[self getUserNeedOCPropertyTypeListWithClass:className] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tempArrayM addObject:[self OCConversionTyleToSQLWithString:obj]];
    }];
    return  [tempArrayM copy];
}

#pragma mark =============== 获取属性名列表 ===============
/// 获取属性名列表
+ (NSArray *)getUserNeedAttributeListWithClass:(id)className {
    if (className) {
        [self getObject].delegate = [[[className class]alloc]init];
        if ([[self getObject].delegate respondsToSelector:@selector(notSaveToDatabaseFormAttributesList)]) {
            
            NSArray *arr = [[self getObject].delegate  notSaveToDatabaseFormAttributesList];
            
            NSMutableArray *tempArrayM = [NSMutableArray arrayWithArray:[self getAttributeListWithClass:className]];
            if (arr.count) {
                [tempArrayM removeObjectsInArray:arr];
            }
            return [tempArrayM copy];
        }
    }
    return [self getAttributeListWithClass:className];
}

/// 获取当前类的所有属性
+ (NSArray *)getAttributeListWithClass:(id)className {
    // 记录属性个数
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([className class], &count);
    
    NSMutableArray *tempArrayM = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        
        // objc_property_t 属性类型
        objc_property_t property = properties[i];
        
        // 转换为Objective C 字符串
        NSString *name = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        
        NSAssert(![name isEqualToString:@"index"], @"禁止在model中使用index作为属性,否则会引起语法错误");
        
        if ([name isEqualToString:@"hash"]) {
            break;
        }
        
        [tempArrayM addObject:name];
    }
    free(properties);
    return [tempArrayM copy];
}
#pragma mark
#pragma mark =============== 获取SQL的属性和类型列表 ===============
+ (NSDictionary *)getSQLProperties:(id)className {
    return [NSDictionary dictionaryWithObjects:[self getUserNeedSQLPropertyTypeListWithClass:className] forKeys:[self getUserNeedAttributeListWithClass:className]];
}

#pragma mark
#pragma mark =============== 获取OC的属性和类型列表 ===============
/**
 *  获取类中的属性和类型为OC类型 例{@"name":@"NSString"}
 *
 *  @param className 类名
 *
 *  @return 类中的属性和类型, 属性名为key，属性OC类型为value
 */
+ (NSDictionary *)getOCProperties:(id)className{
    return [NSDictionary dictionaryWithObjects:[self getUserNeedOCPropertyTypeListWithClass:className] forKeys:[self getUserNeedAttributeListWithClass:className]];
}


#pragma mark
#pragma mark =============== OC类型转SQL类型 ===============
/// OC类型转SQL类型
+ (NSString *)OCConversionTyleToSQLWithString:(NSString *)String {
    if ([String isEqualToString:@"long"] || [String isEqualToString:@"int"] || [String isEqualToString:@"BOOL"]) {
        return @"integer";
    }
    if ([String isEqualToString:@"NSData"]) {
        return @"blob";
    }
    if ([String isEqualToString:@"double"] || [String isEqualToString:@"float"]) {
        return @"real";
    }
    // 自定义数组标记
    if ([String isEqualToString:@"NSArray"] || [String isEqualToString:@"NSMutableArray"]) {
        return @"customArr";
    }
    // 自定义字典标记
    if ([String isEqualToString:@"NSDictionary"] || [String isEqualToString:@"NSMutableDictionary"]) {
        return @"customDict";
    }
    return @"text";
}

#pragma mark
#pragma mark =============== 获取属性对应的OC类型 ===============
+ (NSString *)getAttributesWith:(NSString *)type {
    
    NSString *firstType = [[[type componentsSeparatedByString:@","] firstObject] substringFromIndex:1];
    
    NSDictionary *dict = @{@"f":@"float",
                          @"i":@"int",
                          @"d":@"double",
                          @"l":@"long",
                          @"q":@"long",
                          @"c":@"BOOL",
                          @"B":@"BOOL",
                          @"s":@"short",
                          @"I":@"NSInteger",
                          @"Q":@"NSUInteger",
                          @"#":@"Class"};
    
    for (NSString *key in dict.allKeys) {
        if ([key isEqualToString:firstType]) {
            return  [dict valueForKey:firstType];
        }
    }
    return [firstType componentsSeparatedByString:@"\""][1];
}
@end
