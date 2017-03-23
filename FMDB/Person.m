//
//  Person.m
//  FMDB
//
//  Created by aDu on 2017/3/21.
//  Copyright © 2017年 DuKaiShun. All rights reserved.
//

#import "Person.h"

@implementation Person

/**
 如果需要指定“唯一约束”字段,就复写该函数,这里指定 name 为“唯一约束”.
 */
-(NSString *)uniqueKey{
    return @"aId";
}

@end
