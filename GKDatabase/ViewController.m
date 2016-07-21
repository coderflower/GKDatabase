//
//  ViewController.m
//  GKDatabase
//
//  Created by 花菜ChrisCai on 2016/7/19.
//  Copyright © 2016年 花菜ChrisCai. All rights reserved.
//

#import "ViewController.h"
#import "GKDatabase/GKDatabase.h"
#import "Person.h"
#import "Student.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}
- (IBAction)openDatabase:(id)sender {
    
    if ([[GKDatabaseManager sharedManager]openDatabase]) {
        NSLog(@"数据库打开成功");
    }else {
        NSLog(@"数据库打开失败");
    }
}
/// 创建表格 默认表为为类名,主键为t_default_id
- (IBAction)createTabel:(id)sender {
    
    if ([[GKDatabaseManager sharedManager] creatTableWithClassName:[Person class]]) {
        NSLog(@"创建Person表格成功");
    };
    if ([[GKDatabaseManager sharedManager] creatTableWithClassName:[Student class]]) {
        NSLog(@"创建Student表格成功");
    };
}
- (IBAction)insertData:(id)sender {
    
    for ( NSInteger i = 0; i < 10; i++) {
        Person * p = [[Person alloc]init];
        p.name = [NSString stringWithFormat:@"花菜ChrisCai%lu",i];
        p.age = arc4random() % 100;
        // 向表格中插入数据
        if ([[GKDatabaseManager sharedManager] insertDataFromObject:p]) {
            NSLog(@"插入成功");
        };
    }
    for ( NSInteger i = 0; i < 100; i++) {
        Student * s = [[Student alloc]init];
        s.name = [NSString stringWithFormat:@"花菜ChrisCai%lu",i];
        s.age = 100;
        s.score = arc4random() % 100;
        s.books = @[s.name,[NSString stringWithFormat:@"%lu",s.age]];
        // 向表格中插入数据
        [[GKDatabaseManager sharedManager] insertDataFromObject:s];
    }
}
/// 查询表内所有数据
- (IBAction)selectAllData:(id)sender {
    NSArray * persons = [[GKDatabaseManager sharedManager] selecteDataWithClass:[Person class]];
    NSArray * students = [[GKDatabaseManager sharedManager]selecteDataWithClass:[Student class]];
    NSLog(@"%@, %@",persons,students);
    
}

/// 查询表内数据总行数
- (IBAction)selectTotalCount:(id)sender {
    NSInteger pCount = [[GKDatabaseManager sharedManager] getTotalRowsFormClass:[Person class]];
    NSInteger sCount = [[GKDatabaseManager sharedManager] getTotalRowsFormClass:[Student class]];
    NSLog(@"总共有%lu条person记录, 总共有%lu条student记录",pCount,sCount);
}
/// 模糊查找
- (IBAction)vagueSelect:(id)sender {
    // 查询Person表格中所有年龄包含8的
    NSArray * resultArr = [[GKDatabaseManager sharedManager] selectObject:[Person class] propertyName:@"age" type:GKDatabaseSelectRangOfString content:@"8"];
    [resultArr enumerateObjectsUsingBlock:^(Person * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"%lu",obj.age);
    }];
    
}
/// 更新数据
- (IBAction)updateRows:(id)sender {
    // 将表格中年龄为100的,名字全部改为Chris
    if ([[GKDatabaseManager sharedManager] updateObject:[Student class] oldValues:@[@"age = 100"] conditionType:QueryTypeAND  newValues:@[@"name = Chris"]]) {
        NSLog(@"数据更新成功");
    }
    
}
/// 清空表格
- (IBAction)clearTable:(id)sender {
    if ([[GKDatabaseManager sharedManager] clearTableWithName:[Person class]]) {
        NSLog(@"清空表格成功");
    }
}
/// 删除表格
- (IBAction)deleteTabel:(id)sender {
    if ([[GKDatabaseManager sharedManager] deleteTableWithTableName:[Person class]]) {
        NSLog(@"删除表格成功");
    };
}
/// 单条件查询
- (IBAction)singleConditionSearch:(id)sender {
   NSArray * resultArr = [[GKDatabaseManager sharedManager] selectObject:[Person class] key:@"age" operate:@">" value:@"50"];
    [resultArr enumerateObjectsUsingBlock:^(Person * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"%lu",obj.age);
    }];
}
/// 指定条件删除
- (IBAction)deleteRow:(id)sender {
    if ([[GKDatabaseManager sharedManager] deleteObject:[Person class] withString:@"age > 50"]) {
        NSLog(@"删除成功");
    };
}

@end
