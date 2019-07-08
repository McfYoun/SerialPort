//
//  PopView.m
//  BXYSerialPort
//
//  Created by BP on 28/06/2019.
//  Copyright © 2019 BP. All rights reserved.
//

#import "PopView.h"

@interface PopView ()
@property (strong) IBOutlet NSTextFieldCell *HelpLabel;

@end

@implementation PopView

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *helpPath =[NSString stringWithFormat:@"%@/Help1.txt",[[NSBundle mainBundle] resourcePath]];
    _HelpLabel.stringValue = [[NSString alloc] initWithContentsOfFile:helpPath encoding:NSUTF8StringEncoding error:nil];
}

@end
