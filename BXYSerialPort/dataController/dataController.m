//
//  dataController.m
//  BXYSerialPort
//
//  Created by BP on 25/06/2019.
//  Copyright © 2019 BP. All rights reserved.
//

#import "dataController.h"
#import <Cocoa/Cocoa.h>

#define pasteBoardStringNc @"pasteBoardStringNc"
@implementation dataController
- (instancetype)init
{
    self = [super init];
    if (self) {
        _allData = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CMDList" ofType:@"plist"]];
        _allCommandArray = [_allData objectForKey:@"CommandArray"];
        _allCommandDictionary = [_allData objectForKey:@"CommandDictionary"];
        NSString *helpPath =[NSString stringWithFormat:@"%@/Help.txt",[[NSBundle mainBundle] resourcePath]];
        _helpString = [[NSString alloc] initWithContentsOfFile:helpPath encoding:NSUTF8StringEncoding error:nil];
        
        // 不断获取剪切板内容；
//        NSTimer *timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(getPasteString) userInfo:nil repeats:YES];
//        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
//        self.timer = timer;
//        _pasteBoardString = [[NSString alloc] init];
//        [self.timer setFireDate:[NSDate distantFuture]];  //  nstimer停止
    }
    return self;
}

//获取剪切板内容
- (void)getPasteString{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    if ([[pasteboard types] containsObject:NSPasteboardTypeString]) {
        NSString *str = [pasteboard stringForType:NSPasteboardTypeString];
        if ([_pasteBoardString isNotEqualTo:str]) {
            _pasteBoardString = [NSString stringWithString:str];
            [[NSNotificationCenter defaultCenter]
             postNotificationName:pasteBoardStringNc object:str];
            NSLog(@"粘贴的文字：%@",str);
        }
    }
}
- (void)putString
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];  //必须清空，否则setString会失败。
    [pasteboard setString:@"Hello World!" forType:NSStringPboardType];
}

- (void)dealloc
{
    
}
@end
