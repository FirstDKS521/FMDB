//
//  SYFMDBManager.m
//  StudyFMDB
//
//  Created by aDu on 2017/2/7.
//  Copyright © 2017年 DuKaiShun. All rights reserved.
//

#import "SYFMDBManager.h"
#import <objc/runtime.h>
#import <FMDB.h>

static NSString *const dbName = @"shanyi.sqlite"; //数据库名字
@interface SYFMDBManager ()

@property (nonatomic, strong) FMDatabase *dataBase;

@end

@implementation SYFMDBManager

+ (SYFMDBManager *)shareManager
{
    static SYFMDBManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        NSString *sqlFilePath = [path stringByAppendingPathComponent:dbName];
        // 通过路径创建数据库
        instance.dataBase = [FMDatabase databaseWithPath:sqlFilePath];
    });
    return instance;
}

//创建表格
- (BOOL)createTable:(Class)modelClass {
    return [self createTable:modelClass autoCloseDB:YES];
}

//插入数据
- (BOOL)insertModel:(id)model {
    [self checkTableIsExist:[model class]];
    if ([model isKindOfClass:[NSArray class]] || [model isKindOfClass:[NSMutableArray class]]) {
        NSArray *modelArr = (NSArray *)model;
        return [self insertModelArr:modelArr];
    } else {
        return [self insertModel:model autoCloseDB:YES];
    }
}

//查询单条数据
- (id)searchModel:(Class)modelClass byId:(NSString *)aId {
    return [self searchModel:modelClass byId:aId autoCloseDB:YES];
}

//查询所有数据
- (NSArray *)searchAllModel:(Class)modelClass {
    return [self searchAllModel:modelClass autoCloseDB:YES];
}

//通过关键字，查询所有数据
- (NSArray *)searchAllModel:(Class)modelClass byKey:(NSString *)key value:(NSString *)value {
    return [self searchAllModel:modelClass byKey:key value:value autoCloseDB:YES];
}

//查找某个范围内的数据
- (NSArray *)searchAllModel:(Class)modelClass range:(NSRange)range {
    if ([self.dataBase open]) {
        [self checkTableIsExist:modelClass];
        // 查询数据
        FMResultSet *rs = [self.dataBase executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ LIMIT %@, %@", modelClass, @(range.location), @(range.length)]];
        NSMutableArray *modelArrM = [NSMutableArray array];
        // 遍历结果集
        while ([rs next]) {
            // 创建对象
            id object = [[modelClass class] new];
            unsigned int outCount;
            Ivar * ivars = class_copyIvarList(modelClass, &outCount);
            for (int i = 0; i < outCount; i ++) {
                Ivar ivar = ivars[i];
                NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
                if ([[key substringToIndex:1] isEqualToString:@"_"]) {
                    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                }
                
                id value = [rs objectForColumnName:key];
                if ([value isKindOfClass:[NSString class]]) {
                    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                        [object setValue:result forKey:key];
                    } else {
                        [object setValue:value forKey:key];
                    }
                } else {
                    [object setValue:value forKey:key];
                }
            }
            // 添加
            [modelArrM addObject:object];
        }
        [self.dataBase close];
        return modelArrM.copy;
    } else {
        return nil;
    }
}

- (BOOL)updateModel:(id)model byId:(NSString *)aId {
    return [self updateModel:model byId:aId autoCloseDB:YES];
}

//删除表格
- (BOOL)deleteTable:(Class)modelClass {
    if ([self.dataBase open]) {
        [self checkTableIsExist:modelClass];
        // 删除数据
        NSMutableString *sql = [NSMutableString stringWithFormat:@"DROP TABLE %@;",modelClass];
        BOOL success = [self.dataBase executeUpdate:sql];
        [self.dataBase close];
        return success;
    } else {
        return NO;
    }
}

//删除表格中所有的数据
- (BOOL)deleteAllModel:(Class)modelClass{
    if ([self.dataBase open]) {
        [self checkTableIsExist:modelClass];
        [self searchAllModel:modelClass autoCloseDB:NO];
//        NSArray *modelArr = [self searchAllModel:modelClass autoCloseDB:NO];
//        if (modelArr && modelArr.count) { //先查找是否有数据
            // 删除数据
            NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@;", modelClass];
            BOOL success = [self.dataBase executeUpdate:sql];
            [self.dataBase close];
            return success;
//        }
    }
    return NO;
}

//删除一条数据
- (BOOL)deleteModel:(Class)modelClass byId:(NSString *)aId {
    if ([self.dataBase open]) {
        [self checkTableIsExist:modelClass];
        if ([self searchModel:modelClass byId:aId autoCloseDB:NO]) {
            // 删除数据
            NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE  aId = '%@';", modelClass, aId];
            BOOL success = [self.dataBase executeUpdate:sql];
            [self.dataBase close];
            return success;
        }
    }
    return NO;
}

- (BOOL)tableIsExist:(Class)modelClass {
    return [self tableIsExist:modelClass autoCloseDB:YES];
}

#pragma mark -- private method

/**
 *  @author data
 *
 *  创建表的SQL语句
 */
- (NSString *)createTableSQL:(Class)modelClass {
    NSMutableString *sqlPropertyM = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT", modelClass];
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList(modelClass, &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        [sqlPropertyM appendFormat:@", %@",key];
    }
    [sqlPropertyM appendString:@")"];
    return sqlPropertyM;
}

/**
 *  @author data
 *
 *  创建插入表的SQL语句
 */
- (NSString *)createInsertSQL:(id)model {
    NSMutableString *sqlValueM = [NSMutableString stringWithFormat:@"INSERT OR REPLACE INTO %@ (",[model class]];
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList([model class], &outCount);
    for (int i = 0; i < outCount; i++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        if (i == 0) {
            [sqlValueM appendString:key];
        } else {
            [sqlValueM appendFormat:@", %@",key];
        }
    }
    [sqlValueM appendString:@") VALUES ("];
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        id value = [model valueForKey:key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) {
            value = [NSString stringWithFormat:@"%@", value];
        }
        if (i == 0) {
            // sql 语句中字符串需要单引号或者双引号括起来
            [sqlValueM appendFormat:@"%@",[value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'",value] : value];
        } else {
            [sqlValueM appendFormat:@", %@",[value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'",value] : value];
        }
    }
    //    [sqlValueM appendFormat:@" WHERE aId = '%@'",[model valueForKey:@"aId"]];
    [sqlValueM appendString:@");"];
    
    return sqlValueM;
}

/**
 *  @author data
 *
 *  指定的表是否存在
 */
- (BOOL)tableIsExist:(Class)modelClass autoCloseDB:(BOOL)autoCloseDB {
    if ([self.dataBase open]) {
        FMResultSet *rs = [self.dataBase executeQuery:@"select count(*) as 'count' from sqlite_master where type ='table' and name = ?", modelClass];
        while ([rs next]) {
            NSInteger count = [rs intForColumn:@"count"];
            if (0 == count) {
                if (autoCloseDB) { // 操作完毕是否需要关闭
                    [self.dataBase close];
                }
                return NO;
            } else {
                if (autoCloseDB) { // 操作完毕是否需要关闭
                    [self.dataBase close];
                }
                return YES;
            }
        }
        if (autoCloseDB) { // 操作完毕是否需要关闭
            [self.dataBase close];
        }
        return NO;
    } else {
        return NO;
    }
}

- (BOOL)createTable:(Class)modelClass autoCloseDB:(BOOL)autoCloseDB{
    if ([self.dataBase open]) {
        // 创表,判断是否已经存在
        if ([self tableIsExist:modelClass autoCloseDB:NO]) {
            if (autoCloseDB) {
                [self.dataBase close];
            }
            return YES;
        } else {
            BOOL success = [self.dataBase executeUpdate:[self createTableSQL:modelClass]];
            if (autoCloseDB) {
                [self.dataBase close];
            }
            return success;
        }
    } else {
        return NO;
    }
}

- (BOOL)insertModel:(id)model autoCloseDB:(BOOL)autoCloseDB {
    NSAssert(![model isKindOfClass:[UIResponder class]], @"必须保证模型是NSObject或者NSObject的子类,同时不响应事件");
    if ([self.dataBase open]) {
        // 没有表的时候，先创建再插入
        
        // 此时有三步操作，第一步处理完不关闭数据库
        if (![self tableIsExist:[model class] autoCloseDB:NO]) {
            // 第二步处理完不关闭数据库
            BOOL success = [self createTable:[model class] autoCloseDB:NO];
            if (success) {
                NSString *fl_dbId = [model valueForKey:@"aId"];
                id judgeModle = [self searchModel:[model class] byId:fl_dbId autoCloseDB:NO];
                if ([[judgeModle valueForKey:@"aId"] isEqualToString:fl_dbId]) {
                    BOOL updataSuccess = [self updateModel:model byId:fl_dbId autoCloseDB:NO];
                    if (autoCloseDB) {
                        [self.dataBase close];
                    }
                    return updataSuccess;
                } else {
                    BOOL insertSuccess = [self.dataBase executeUpdate:[self createInsertSQL:model]];
                    if (autoCloseDB) { //最后一步操作完毕，询问是否需要关闭
                        [self.dataBase close];
                    }
                    return insertSuccess;
                }
            } else {
                // 第二步操作失败，询问是否需要关闭,可能是创表失败，或者是已经有表
                if (autoCloseDB) {
                    [self.dataBase close];
                }
                return NO;
            }
        } else {// 已经创建有对应的表，直接插入
            NSString *fl_dbId = [model valueForKey:@"aId"];
            id judgeModle = [self searchModel:[model class] byId:fl_dbId autoCloseDB:NO];
            if ([[judgeModle valueForKey:@"aId"] isEqualToString:fl_dbId]) {
                BOOL updataSuccess = [self updateModel:model byId:fl_dbId autoCloseDB:NO];
                if (autoCloseDB) {
                    [self.dataBase close];
                }
                return updataSuccess;
            } else {
                BOOL insertSuccess = [self.dataBase executeUpdate:[self createInsertSQL:model]];
                // 最后一步操作完毕，询问是否需要关闭
                if (autoCloseDB) {
                    [self.dataBase close];
                }
                return insertSuccess;
            }
        }
    } else {
        return NO;
    }
}

- (BOOL)insertModelArr:(NSArray *)modelArr {
    BOOL flag = YES;
    for (id model in modelArr) {
        // 处理过程中不关闭数据库
        if (![self insertModel:model autoCloseDB:NO]) {
            flag = NO;
        }
    }
    // 处理完毕关闭数据库
    [self.dataBase close];
    // 全部插入成功才返回YES
    return flag;
}

//查找单个数据
- (id)searchModel:(Class)modelClass byId:(NSString *)aId autoCloseDB:(BOOL)autoCloseDB {
    if ([self.dataBase open]) {
        [self checkTableIsExist:modelClass];
        // 查询数据
        FMResultSet *rs = [self.dataBase executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE aId = '%@';", modelClass, aId]];
        // 创建对象
        id object = nil;
        // 遍历结果集
        while ([rs next]) {
            object = [[modelClass class] new];
            unsigned int outCount;
            Ivar * ivars = class_copyIvarList(modelClass, &outCount);
            for (int i = 0; i < outCount; i ++) {
                Ivar ivar = ivars[i];
                NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
                if ([[key substringToIndex:1] isEqualToString:@"_"]) {
                    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                }
                id value = [rs objectForColumnName:key];
                if ([value isKindOfClass:[NSString class]]) {
                    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                        [object setValue:result forKey:key];
                    } else {
                        [object setValue:value forKey:key];
                    }
                } else {
                    [object setValue:value forKey:key];
                }
            }
        }
        if (autoCloseDB) {
            [self.dataBase close];
        }
        return object;
    } else {
        return nil;
    }
}

//查找所有数据
- (NSArray *)searchAllModel:(Class)modelClass autoCloseDB:(BOOL)autoCloseDB{
    if ([self.dataBase open]) {
        [self checkTableIsExist:modelClass];
        // 查询数据
        FMResultSet *rs = [self.dataBase executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@",modelClass]];
        NSMutableArray *modelArrM = [NSMutableArray array];
        // 遍历结果集
        while ([rs next]) {
            // 创建对象
            id object = [[modelClass class] new];
            unsigned int outCount;
            Ivar * ivars = class_copyIvarList(modelClass, &outCount);
            for (int i = 0; i < outCount; i ++) {
                Ivar ivar = ivars[i]; // 根据角标，从数组取出对应的成员属性
                // 获取成员属性名
                NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
                if ([[key substringToIndex:1] isEqualToString:@"_"]) {
                    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                }
                
                id value = [rs objectForColumnName:key];
                if ([value isKindOfClass:[NSString class]]) {
                    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                        [object setValue:result forKey:key];
                    } else {
                        [object setValue:value forKey:key];
                    }
                } else {
                    [object setValue:value forKey:key];
                }
            }
            // 添加
            [modelArrM addObject:object];
        }
        if (autoCloseDB) {
            [self.dataBase close];
        }
        return modelArrM.copy;
    } else {
        return nil;
    }
}

//通过关键字，查询所有数据
- (NSArray *)searchAllModel:(Class)modelClass byKey:(NSString *)key value:(NSString *)value autoCloseDB:(BOOL)autoCloseDB{
    if ([self.dataBase open]) {
        [self checkTableIsExist:modelClass];
        // 查询数据
        FMResultSet *rs = [self.dataBase executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = '%@';", modelClass, key, value]];
        NSMutableArray *modelArrM = [NSMutableArray array];
        // 遍历结果集
        while ([rs next]) {
            // 创建对象
            id object = [[modelClass class] new];
            unsigned int outCount;
            Ivar * ivars = class_copyIvarList(modelClass, &outCount);
            for (int i = 0; i < outCount; i ++) {
                Ivar ivar = ivars[i];
                NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
                if([[key substringToIndex:1] isEqualToString:@"_"]){
                    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                }
                
                id value = [rs objectForColumnName:key];
                if ([value isKindOfClass:[NSString class]]) {
                    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                        [object setValue:result forKey:key];
                    } else {
                        [object setValue:value forKey:key];
                    }
                } else {
                    [object setValue:value forKey:key];
                }
            }
            // 添加
            [modelArrM addObject:object];
        }
        if (autoCloseDB) {
            [self.dataBase close];
        }
        return modelArrM.copy;
    } else {
        return nil;
    }
}

- (BOOL)updateModel:(id)model byId:(NSString *)aId autoCloseDB:(BOOL)autoCloseDB {
    if ([self.dataBase open]) {
        [self checkTableIsExist:[model class]];
        // 修改数据@"UPDATE t_student SET name = 'liwx' WHERE age > 12 AND age < 15;"
        NSMutableString *sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET ",[model class]];
        
//        if ([self.dataBase columnExists:@"" inTableWithName:@""]) {
//            NSString *update = [NSString stringWithFormat:@"UPDATE %@ SET %@=? WHERE %@ = '%@'",TABLE_CARD,kScanCardPath,kLiuDuID,liuduid];
//            [self.dataBase executeUpdate:update,path];
//        } else {
//            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ text",TABLE_CARD,kScanCardPath];
//            [self.dataBase executeUpdate:sql];
//            NSString *update = [NSString stringWithFormat:@"UPDATE %@ SET %@=? WHERE %@ = '%@'",TABLE_CARD,kScanCardPath,kLiuDuID,liuduid];
//            [self.db executeUpdate:update,path];
//        }
        
        unsigned int outCount;
        class_copyIvarList([model superclass],&outCount);
        Ivar * ivars = class_copyIvarList([model class], &outCount);
        for (int i = 0; i < outCount; i ++) {
            Ivar ivar = ivars[i];
            NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
            if([[key substringToIndex:1] isEqualToString:@"_"]){
                key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
            }
            
            if (![self.dataBase columnExists:key inTableWithName:dbName]) {
                sql = [NSMutableString stringWithFormat:@"ALTER TABLE %@ ADD %@ text", dbName, key];
                NSLog(@"%@不存在，并创建", key);
            }
            
            id value = [model valueForKey:key];
            NSLog(@"-------%@", value);
            if (i == 0) {
                [sql appendFormat:@"%@ = %@",key,([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) ? [NSString stringWithFormat:@"'%@'",value] : value];
            } else {
                [sql appendFormat:@",%@ = %@",key,([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) ? [NSString stringWithFormat:@"'%@'",value] : value];
            }
        }
        [sql appendFormat:@" WHERE aId = '%@';", aId];
        BOOL success = [self.dataBase executeUpdate:sql];
        NSLog(@"成功了吗===%@", @(success));
        if (autoCloseDB) {
            [self.dataBase close];
        }
        return success;
    } else {
        return NO;
    }
}

#pragma mark - 删除整个数据库
- (BOOL)deleteDataBase
{
    NSFileManager *fileManager=[NSFileManager defaultManager];
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *sqlFilePath = [path stringByAppendingPathComponent:dbName];
    BOOL have = [[NSFileManager defaultManager] fileExistsAtPath:sqlFilePath];
    if (!have) {
        return NO;
    } else {
        BOOL success= [fileManager removeItemAtPath:sqlFilePath error:nil];
        if (success) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - 检测表格是否存在
- (void)checkTableIsExist:(Class)modelClass
{
    if (![self tableIsExist:modelClass autoCloseDB:NO]) {
        [[SYFMDBManager shareManager] createTable:modelClass];
    }
}

@end
