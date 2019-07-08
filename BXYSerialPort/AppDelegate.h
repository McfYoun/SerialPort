//
//  AppDelegate.h
//  BXYSerialPort
//
//  Created by BP on 05/06/2019.
//  Copyright © 2019 BP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NewWindow.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) NSArray *availableBaudRates;
@end

