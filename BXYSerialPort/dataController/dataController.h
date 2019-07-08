//
//  dataController.h
//  BXYSerialPort
//
//  Created by BP on 25/06/2019.
//  Copyright © 2019 BP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface dataController : NSObject
@property (nonatomic) NSDictionary * allData;
@property (nonatomic) NSArray * allCommandArray;
@property (nonatomic) NSDictionary * allCommandDictionary;
@property (nonatomic) NSString * helpString;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic) NSString * pasteBoardString;
@end
