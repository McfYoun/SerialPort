//
//  AppDelegate.m
//  BXYSerialPort
//
//  Created by BP on 05/06/2019.
//  Copyright © 2019 BP. All rights reserved.
//

#import "AppDelegate.h"
@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong) NewWindow * Nwindow;

@end
@implementation AppDelegate

//app 刚打开的时候就获取所有已连接的port
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _Nwindow = [[NewWindow alloc] initWithWindowNibName:@"NewWindow"];
    [_Nwindow.window orderFront:nil];
    [_Nwindow.window center];
}

//当点击关闭按钮的时候，彻底关闭app
//- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
//{
//    return YES;
//}
//设置点击Dock，使app重新打开。注意！！！ 在MainMenu.xib中取消“Visible At Launch”。
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    if (flag) {
        return NO;
    }else{
        [_Nwindow.window makeKeyAndOrderFront:self];
        return YES;
    }
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
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
@end
