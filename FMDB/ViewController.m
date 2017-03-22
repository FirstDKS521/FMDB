//
//  ViewController.m
//  FMDB
//
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
    person.test = @"新增";
    [[SYFMDBManager shareManager] insertModel:person];
}

- (IBAction)search:(id)sender {
    NSArray *array = [[SYFMDBManager shareManager] searchAllModel:[Person class]];
    Person *person = array[0];
    NSLog(@"name=%@, age=%@, sex=%@, add=%@", person.name, person.age, person.sex, person.test);
}

@end
