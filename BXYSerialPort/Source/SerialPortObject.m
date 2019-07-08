//
//  SerialPortObject.m
//  TestZone
//
//  Created by BP on 2/16/14.
//  Copyright (c) 2015 BP Automation. All rights reserved.
//

#import "SerialPortObject.h"
#include <termios.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <netdb.h>
#include <arpa/inet.h>
//#import "Common.h"

@implementation SerialPortObject
static int OpenSerialPort(const char *bsdPath,const int BaudRates)
{
    int fileDescriptor = -1;
    struct termios	options;
    fileDescriptor = open(bsdPath, O_RDWR|O_NDELAY|O_NOCTTY| O_NONBLOCK);//|O_EXLOCK  O_NDELAY|
    if (fileDescriptor == -1)
    {
        printf("Error opening serial port %s - %s(%d).\n",bsdPath, strerror(errno), errno);
        return fileDescriptor ;
    }
    printf("> opening serial port %s successfully --> %i \n",bsdPath,fileDescriptor);
    // Get the current options and save them so we can restore the default settings later.
    if (tcgetattr(fileDescriptor,&options)  == -1)
    {
        printf("Error getting tty attributes %s - %s(%d).\n",
               bsdPath, strerror(errno), errno);
        return fileDescriptor ;
    }
    //cfmakeraw(&options);
    options.c_cc[VMIN] = 1;
    options.c_cc[VTIME] = 10;
    options.c_cflag |=(CLOCAL|CREAD) ;
    cfsetspeed(&options, BaudRates);
    options.c_cflag |= (CS8); 	    	// Use 8 bit words
    // Cause the new options to take effect immediately.
    if (tcsetattr(fileDescriptor, TCSANOW, &options) == -1)
    {
        printf("Error setting tty attributes %s - %s(%d).\n",
               bsdPath, strerror(errno), errno);
        return fileDescriptor ;
    }
    return fileDescriptor;
}

NSMutableData *  WriteCmdAndReadDataFromSerialPort(int fd,NSString *cmd,NSString *expectEndStr)
{
    NSMutableData * dataOfReadback=[NSMutableData data];
    const char * command=[[cmd stringByAppendingString:@"\n"] cStringUsingEncoding:NSUTF8StringEncoding];
    ssize_t numBytes = write(fd, command, strlen(command));
    if (numBytes == -1)
    {
        printf("Error writing to serial port - %s(%d).\n", strerror(errno), errno);
        return nil;
    }
    close(fd);
    return dataOfReadback;
    //return readSource;    
}
//+(void)writeCMDToFileDescription:(NSString *)fdp Command:(NSString *) cmd {
//    int fd=-1;
//    fd=[SerialPortObject OpenSerialPort:fdp BaudRates:BaudRates];
//    [SerialPortObject WriteCommand:cmd Port:&fd];
//    [SerialPortObject CloseSerialPort:fd];
//    fd=-1;
//}

+(int)OpenSerialPort:(NSString *) fileDesc BaudRates:(int)BaudRates;
{
    return OpenSerialPort([fileDesc cStringUsingEncoding:NSUTF8StringEncoding],BaudRates);
}
+(void)CloseSerialPort:(int)fd;
{
    if (fd > 0) {
        close(fd);
        NSLog(@"Close Serial port:%i",fd);
    }
}
+(BOOL)WriteCommand:(NSString *)cmd Port:(int *)fd;
{
    NSString * cmd1 =[NSString stringWithFormat:@"%@\r",cmd];
//    NSLog(@"----Write Command:%@",cmd);
    const char *str=[cmd1 UTF8String];
    NSUInteger len=[cmd1 length];
    if (*fd > 0) {
        size_t s = write(*fd, str,len );
        if (s <1) {
            NSLog(@"[Error] write fail:%@",cmd1);
            return NO;
        }
    }else{
        NSLog(@"[Error] write fail:%@",cmd1);
        return NO;
    }
    [NSThread sleepForTimeInterval:0.05];
    return YES;
//    NSString *formatStr=[NSString stringWithFormat:@"%@\r\n",cmd];
//    NSLog(@"Write Command:%@",cmd);
//    const char *str=[cmd UTF8String];
//    NSUInteger len=[cmd length];
//    
//    if (*fd > 0) {
//        for (int i = 0; i < len; i++) {
//            size_t s = write(*fd, str + i,1);
//            if (s <1) {
//                NSLog(@"[Error] write fail:%@",cmd);
//            }
//            [NSThread sleepForTimeInterval:0.00001];
//        }
//    }else{
//        NSLog(@"[Error] write fail:%@",cmd);
//        return NO;
//    }
//    
//    return YES;
}
//+(BOOL)WriteCommandWithFileData:(NSString *)cmd Port:(int *)fd;
//{
//    // NSString *formatStr=[NSString stringWithFormat:@"%@\r\n",cmd];
//    NSLog(@"Write Command:%@",cmd);
//    NSString *path = [Common GetAppFileFullPath:@"X527app" Type:@"bin"];
//    NSMutableData *fileContent = [NSMutableData dataWithContentsOfFile:path];
//    NSLog(@"Jason try1");
//    //[bufferForHost appendBytes:[line cStringUsingEncoding:NSUTF8StringEncoding] length:[line length]]
//    NSString *tmp = @"\r";
//    [fileContent appendBytes:[tmp cStringUsingEncoding:NSUTF8StringEncoding] length:[tmp length]];
//    NSLog(@"Jason try2");
//    // \r = 0x0d
//    const char *str=[fileContent bytes];
//    NSUInteger len=[fileContent length];
//    if (*fd > 0) {
//        size_t s = write(*fd, str,len );
//
//        if (s <1) {
//            NSLog(@"[Error] write fail:%@",cmd);
//        }
//    }else{
//        NSLog(@"[Error] write fail:%@",cmd);
//        return NO;
//    }
//    [NSThread sleepForTimeInterval:0.05];
//    return YES;
//}
+(BOOL)Fixture:(unsigned)fixtureId ReadSerialPort:(int)fd TimeOut:(double)tt usingBlock:(void (^)(NSData *date,ssize_t len,BOOL *stop))callback;
{
    
    int buffersize=2048;
    char *buffer=(char *)malloc( buffersize * sizeof(char));
    memset(buffer, 0,  buffersize * sizeof(char));
    ssize_t s=0;
    if (fd <0) {
        free(buffer);
        return NO;
    }
    NSDate *startDate=[NSDate date] ;
    BOOL stopFlag=NO;
    do{
        s = read(fd, buffer,  buffersize * sizeof(char) -1);
        //NSLog(@"time:%@,wait:%f,buffer:%s",startDate,tt,buffer);
        if ( s>0  ) {
            NSData *rawData = [NSData dataWithBytes:buffer length:s];
            callback(rawData,s,&stopFlag);
        }else{
            [NSThread sleepForTimeInterval:0.05];
        }
        memset(buffer, 0,  buffersize * sizeof(char));
    }while (stopFlag == NO && [[NSDate date] timeIntervalSinceDate:startDate] < tt);
    free(buffer);
    return YES;
}

+(BOOL)ReadSerialPortByline:(int)fd TimeOut:(double)tt usingBlock:(void (^)(NSString *line,BOOL *stop))callback;
{
    BOOL stopFlag=NO;
    NSDate *startDate=[NSDate date] ;
    char ch='\0';
    ssize_t s=0;
    NSMutableString *lineStr=[NSMutableString string];
    do{
        s = read(fd, &ch,1);
        if ( s>0  ) {
            [lineStr appendFormat:@"%c",ch];
            if (ch == 0x000a) { //NSNewlineCharacter
                callback([NSString stringWithString:lineStr],&stopFlag);
                [lineStr setString:@""];
            }
        }else{
            [NSThread sleepForTimeInterval:0.5];
        }
    }while (stopFlag == NO && [[NSDate date] timeIntervalSinceDate:startDate] < tt ) ;
    
    callback([NSString stringWithString:lineStr],&stopFlag);
    [lineStr setString:@""];
    lineStr=nil;
    return YES;
}
+(void)flushSerialPort:(int )fd;
{
    char ch='\0';
    ssize_t size=0;
    do {
        size = read(fd, &ch, 1);
    } while (size > 0);
}
+(void)readSerialPort:(int )fd usingBlock:(void (^)(NSString *line))callback;
{
    char ch='\0';
    ssize_t s=0;
    NSMutableString *lineStr=[NSMutableString string];
    do{
        s = read(fd, &ch,1);
        if ( s>0  ) {
            [lineStr appendFormat:@"%c",ch];
        }
    }while (s > 0);
    callback([NSString stringWithString:lineStr]);
    [lineStr setString:@""];
    lineStr=nil;
}
+ (NSString *)readSerialPort:(int )fd;
{
    char ch='\0';
    ssize_t s=0;
    NSMutableString *lineStr=[NSMutableString string];
    [lineStr setString:@""];
    do{
        s = read(fd, &ch,1);
        if ( s>0  ) {
            [lineStr appendFormat:@"%c",ch];
        }
    }while (s > 0);
    return lineStr;
}
@end
    
