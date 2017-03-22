//
//  SYFMDBManager.h
//  StudyFMDB
//
//  Created by aDu on 2017/2/7.
//  Copyright © 2017年 DuKaiShun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SYFMDBManager : NSObject

/**
 * 单例创建，项目唯一
 */
+ (SYFMDBManager *)shareManager;

#pragma mark -- 创建

/**
 * 创建表格
 * @author modelClass 模型名称
 */
- (BOOL)createTable:(Class)modelClass;

#pragma mark -- 插入

/**
 * 插入单个模型数据数组
 * @author 如果此时传入的模型对应的表中已经存在，则替换更新旧数据
 * 如果表中没有就自动先创建，表明为模型类名
 */
- (BOOL)insertModel:(id)model;

#pragma mark -- 查询

/**
 * 查询表格是否存在
 */
- (BOOL)tableIsExist:(Class)modelClass;

/**
 * 查询单条数据
 * 查找指定表的模型，执行完毕后关闭数据库
 */
- (id)searchModel:(Class)modelClass byId:(NSString *)aId;

/**
 * 查找某个范围内的数据
 * @author range 传入的是一个范围
 */
- (NSArray *)searchAllModel:(Class)modelClass range:(NSRange)range;

/**
 * 查询所有数据
 * 查找指定模型中的所有数据
 */
- (NSArray *)searchAllModel:(Class)modelClass;

/**
 * 通过关键字，查询所有数据
 */
- (NSArray *)searchAllModel:(Class)modelClass byKey:(NSString *)key value:(NSString *)value;

#pragma mark -- 修改

/**
 * 修改数据
 * 修改指定的aId的模型
 */
- (BOOL)updateModel:(id)model byId:(NSString *)aId;

#pragma mark -- 删除

/**
 * 删除表格
 */
- (BOOL)deleteTable:(Class)modelClass;

/**
 * 删除所有数据
 * 删除指定表格的所有数据
 */
- (BOOL)deleteAllModel:(Class)mdoelClass;

/**
 * 删除指定的模型数据
 */
- (BOOL)deleteModel:(Class)modelClass byId:(NSString *)aId;

#pragma mark - 删除整个数据库

/**
 * 删除整个数据库文件
 */
- (BOOL)deleteDataBase;

@end
