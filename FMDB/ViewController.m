//
//  ViewController.m
//  FMDB
//  https://github.com/huangzhibiao/BGFMDB
//  Created by aDu on 2017/3/21.
//  Copyright © 2017年 DuKaiShun. All rights reserved.
//

#import "ViewController.h"
#import "SYFMDBManager.h"
#import "Person.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Person *person = [[Person alloc] init];
    person.aId = @"100";
    person.name = @"阿杜";
    person.age = @"20";
    person.sex = @"男";
    person.test = @"新增1";
    NSLog(@"%@", @([Person version]));
//    [Person updateVersion:[Person version] + 1];
    [person saveOrUpdate];
}

- (IBAction)search:(id)sender {
    NSArray *array = [Person findAll];
    Person *person = array.lastObject;
    NSLog(@"aId=%@, name=%@, age=%@, sex=%@, test=%@",person.aId, person.name, person.age, person.sex, person.test);
}

@end
