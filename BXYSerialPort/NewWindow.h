//
//  NewWindow.h
//  BXYSerialPort
//
//  Created by BP on 10/06/2019.
//  Copyright © 2019 BP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/serial/IOSerialKeys.h>
#import "SerialPortObject.h"

@interface NewWindow : NSWindowController<NSTableViewDelegate,NSTableViewDataSource,NSUserNotificationCenterDelegate>
@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) NSArray *availableBaudRates;
@end
