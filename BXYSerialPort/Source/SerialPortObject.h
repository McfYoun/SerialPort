//
//  SerialPortObject.h
//  TestZone
//
//  Created by BP on 2/16/14.
//  Copyright (c) 2015 BP Automation. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface SerialPortObject : NSObject
{

}
@property(assign)BOOL abortTest;
+(int)OpenSerialPort:(NSString *) fileDesc BaudRates:(int)BaudRates;
+(void)CloseSerialPort:(int)fd;
+(BOOL)WriteCommand:(NSString *)cmd Port:(int *)fd;
//+(BOOL)WriteCommandWithFileData:(NSString *)cmd Port:(int *)fd;
+(BOOL)Fixture:(unsigned)fixtureId ReadSerialPort:(int)fd TimeOut:(double)tt usingBlock:(void (^)(NSData *data,ssize_t len,BOOL *stop))callback;
+(BOOL)ReadSerialPortByline:(int)fd TimeOut:(double)tt usingBlock:(void (^)(NSString *line,BOOL *stop))callback;
//+(void)writeCMDToFileDescription:(NSString *)fdp Command:(NSString *) cmd ;
+(void)flushSerialPort:(int)fd;

//add for X527 LOOP1 test
+(void)readSerialPort:(int )fd usingBlock:(void (^)(NSString *line))callback;
+ (NSString *)readSerialPort:(int )fd;


@end

