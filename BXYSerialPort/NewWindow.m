//
//  NewWindow.m
//  BXYSerialPort
//
//  Created by BP on 10/06/2019.
//  Copyright © 2019 BP. All rights reserved.
//

#import "NewWindow.h"
#import "dataController.h"
#import <AppKit/AppKit.h>
#import "PopView.h"

@interface NewWindow ()
@property (strong) IBOutlet NSWindow *window1;
@property (strong) IBOutlet NSPopUpButton *SelectedPort;
@property (strong) IBOutlet NSPopUpButton *SelectedBaudRates;
@property (strong) IBOutlet NSTextField *SendCommandTextField;
@property (strong) IBOutlet NSTextView *LogTextView;
@property (strong) IBOutlet NSButton *openAndCloseButton;
@property (strong) IBOutlet NSTextField *timeStamp;
@property (nonatomic,weak) NSTimer * timer;
@property (strong) IBOutlet NSButton *NomalAndEditButton;
@property (nonatomic) NSTableView * CommandTableView;

//添加NSStatusItem
@property (nonatomic,strong)NSStatusItem * bpItem;
@property (nonatomic,strong)NSPopover * popView;
//tableView command array
@property (nonatomic) NSMutableArray * TableViewDataArrayC1;
@property (nonatomic) NSMutableArray * TableViewDataArrayC2;

@property (strong) NewWindow * NewWindow1;
//@property (nonatomic) NSArray * commandArray;
@property (nonatomic) dataController * dc;
@property (nonatomic) NSMutableString * bufferString;

@end

#define tableViewNumber @"numberRow"
#define tableViewCommand @"command"
#define tableViewInformation @"information"
#define pasteBoardStringNc @"pasteBoardStringNc"
@implementation NewWindow
{
    BOOL isOpen;
    int fd;
    dispatch_group_t testItemGroup;
    //selectedRow 用于添加和删除command，默认为-1
    NSInteger selectedRow;
    NSString * pathC1;
    NSString * pathC2;
}
- (void)windowDidLoad {
    [super windowDidLoad];
    [self initWithCommandTableView];
    [self initPara];
    // 设置状态栏
    [self initStatusItem];
    [self.CommandTableView reloadData];
    [_SelectedPort addItemWithTitle:@"Port"];
    for (NSString * path in self.serialPortManager.availablePorts) {
        [_SelectedPort addItemWithTitle:[NSString stringWithFormat:@"%@",path]];
    }
    [_SelectedBaudRates addItemWithTitle:@"BaudRates"];
    for (NSNumber * BaudRates in self.availableBaudRates) {
        [_SelectedBaudRates addItemWithTitle:[BaudRates stringValue]];
    }
}
// 设置状态栏
- (void)initStatusItem
{
    //int a 的作用是防止点击新建窗口按钮的时候添加多个 statusItem。
    static int a = 1;
    if (a == 1) {
        self.bpItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        NSImage * image = [NSImage imageNamed:@"bp1"];
        [self.bpItem.button setImage:image];
        _popView = [[NSPopover alloc] init];
        _popView.behavior = NSPopoverBehaviorTransient;
        _popView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
        _popView.contentViewController = [[PopView alloc] initWithNibName:@"PopView" bundle:nil];
    }
    a ++;
    // bpItem添加点击事件
    self.bpItem.target = self;
    self.bpItem.button.action = @selector(showPopView:);
}
- (void)showPopView:(NSStatusBarButton *)button
{
    [_popView showRelativeToRect:button.bounds ofView:button preferredEdge:NSRectEdgeMaxY];
}

- (void)initPara
{
    _bufferString = [[NSMutableString alloc] init];
    isOpen = FALSE;
    self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
    self.availableBaudRates = @[@300, @1200, @2400, @4800, @9600, @14400, @19200, @28800, @38400, @57600, @115200, @230400];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    //调用ORSSerialPort中的方法动态监听串口的接入与断开
    [nc addObserver:self selector:@selector(serialPortsWereConnected:) name:ORSSerialPortsWereConnectedNotification object:nil];
    [nc addObserver:self selector:@selector(serialPortsWereDisconnected:) name:ORSSerialPortsWereDisconnectedNotification object:nil];
    //获取剪切板内容
    [nc addObserver:self selector:@selector(PrintPasteBoard:) name:pasteBoardStringNc object:nil];
    testItemGroup = dispatch_group_create();
//    NSTimer *timer = [NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(readString) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
//    self.timer = timer;
//    [self.timer setFireDate:[NSDate distantFuture]];
    static int a = 1;
    
    if (a == 1) {
        _dc = [[dataController alloc] init];
    }
    a ++;
    _CommandTableView.delegate = self;
    _CommandTableView.dataSource = self;
//    pathC1 = [NSHomeDirectory() stringByAppendingPathComponent:@"CommandC1.archive"];
//    pathC2 = [NSHomeDirectory() stringByAppendingPathComponent:@"CommandC2.archive"];
    pathC1 = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"CommandC1.archive"];
    pathC2 = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"CommandC2.archive"];
    
    if (![self UnArchiverWithP1:pathC1 P2:pathC2]) {
        _TableViewDataArrayC1 = [NSMutableArray arrayWithArray:_dc.allCommandArray];
        _TableViewDataArrayC2 = [[NSMutableArray alloc] init];
        for (NSString * c1String in _TableViewDataArrayC1) {
            NSString * c2String = [_dc.allCommandDictionary objectForKey:c1String];
            [_TableViewDataArrayC2 addObject:c2String];
        }
        [self ArchiverWithPath1:pathC1 path2:pathC2];
    }
    
    //selectedRow 用于添加和删除command，默认为-1
    selectedRow = -1;
    [self djs];
//    _commandArray = [[NSArray alloc] initWithArray:_dc.allCommandArray];
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
#endif
}

- (void)ArchiverWithPath1:(NSString *)p1 path2:(NSString *)p2
{
    BOOL sucess = [NSKeyedArchiver archiveRootObject:_TableViewDataArrayC1 toFile:p1];
    if (sucess)
    {
        NSLog(@"p1 archive sucess");
    }
    sucess = [NSKeyedArchiver archiveRootObject:_TableViewDataArrayC2 toFile:p2];
    if (sucess)
    {
        NSLog(@"p2 archive sucess");
    }
}
- (BOOL)UnArchiverWithP1:(NSString *)p1 P2:(NSString *)p2
{
    NSMutableArray * c1 = [NSKeyedUnarchiver unarchiveObjectWithFile:p1];
    NSMutableArray * c2 = [NSKeyedUnarchiver unarchiveObjectWithFile:p2];
    
    if (c1 && c2) {
        _TableViewDataArrayC1 = [NSMutableArray arrayWithArray:c1];
        _TableViewDataArrayC2 = [NSMutableArray arrayWithArray:c2];
        return TRUE;
    }else{
        return FALSE;
    }
}

- (void)initWithCommandTableView
{
    NSScrollView * sv = [[NSScrollView alloc] initWithFrame:NSMakeRect(20 , 20 , 339, 536)];
    sv.hasVerticalScroller  = YES;
    [self.window.contentView addSubview:sv];
    _CommandTableView = [[NSTableView alloc] initWithFrame:sv.bounds];
    NSTableColumn * rowNumber = [[NSTableColumn alloc] initWithIdentifier:tableViewNumber];
    NSTableColumn * command = [[NSTableColumn alloc] initWithIdentifier:tableViewCommand];
    NSTableColumn * information = [[NSTableColumn alloc] initWithIdentifier:tableViewInformation];
    
    rowNumber.width = 22;
    rowNumber.maxWidth = 22;
    rowNumber.title = @"ID";
    
    command.width = 120;
    command.minWidth = 120;
    command.title = @"command";
    
    information.width = 280;
    information.minWidth = 80;
    information.title = @"information";
    
    [_CommandTableView addTableColumn:rowNumber];
    [_CommandTableView addTableColumn:command];
    [_CommandTableView addTableColumn:information];
    
    _CommandTableView.delegate = self;
    _CommandTableView.dataSource = self;
    [_CommandTableView reloadData];
    //设置tableView颜色交替
    [_CommandTableView setUsesAlternatingRowBackgroundColors:YES];
    sv.contentView.documentView = _CommandTableView;
}

//打印剪切板内容
-(void)PrintPasteBoard:(NSNotification *)nc
{
     NSString * infoString = [nc object];
    [self logInfo:infoString port:@"55"];
}

#pragma mark tableView function
- (IBAction)addCommand:(id)sender {
    if (selectedRow == -1) {
        [_TableViewDataArrayC1 insertObject:@"" atIndex:0];
        [_TableViewDataArrayC2 insertObject:@"" atIndex:0];
    }else{
        [_TableViewDataArrayC1 insertObject:@"" atIndex:selectedRow + 1];
        [_TableViewDataArrayC2 insertObject:@"" atIndex:selectedRow + 1];
    }
    [_CommandTableView reloadData];
}
- (IBAction)subtractionCommand:(id)sender {
    if (selectedRow == -1) {
        [self logError:@"please select a command" port:@""];
        return;
    }else{
        [_TableViewDataArrayC1 removeObjectAtIndex:selectedRow];
        [_TableViewDataArrayC2 removeObjectAtIndex:selectedRow];
    }
    [_CommandTableView reloadData];
}
- (IBAction)editButton:(id)sender {
    if ([_NomalAndEditButton.title isEqualToString:@"Normal"]) {
        _NomalAndEditButton.title = @"Edit";
    }else{
        _NomalAndEditButton.title = @"Normal";
    }
    
}
- (IBAction)saveTableView:(id)sender {
    [self ArchiverWithPath1:pathC1 path2:pathC2];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _TableViewDataArrayC1.count;
}

// 设置是否可以进行编辑
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSLog(@"Editing...Row/Column[%lu/%@]",row,tableColumn.identifier);
    return YES;
}

// 设置是否允许被修改
-(BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView
{
    return YES;
}

//当列表长度无法展示完整某行数据时 当鼠标悬停在此行上 是否扩展显示
- (BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    return YES;
}

//- (void)controlTextDidChange:(NSNotification *)obj
//{
//    NSTableView *tableView = obj.object;
//    NSLog(@"---selection row %ld  --%@", tableView.selectedRow,_TableViewDataArrayC1[tableView.selectedRow]);
//}

//-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
//{
//    NSLog(@"Editing...Row/Column[%lu/%@]",row,tableColumn.identifier);
//    //    NSEvent * event = [NSApp currentEvent];
//    //    BOOL shiftTabbedIn =( [event type] == NSEventTypeKeyDown && [[event characters] characterAtIndex:0] == NSBackTabCharacter );
//    //    NSLog(@"shiftTabbledIn = %d",shiftTabbedIn);
//    return YES;
//}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([[tableColumn identifier] isEqualToString:tableViewCommand]) {
        return _TableViewDataArrayC1[row];
    }else if([[tableColumn identifier] isEqualToString:tableViewInformation]){
        return _TableViewDataArrayC2[row];
    }else{
        return [NSString stringWithFormat:@"%ld",row];
    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(nullable id)object forTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{

    if ([[tableColumn identifier] isEqualToString:tableViewCommand]) {
        _TableViewDataArrayC1[row] = object;
    }else if ([[tableColumn identifier] isEqualToString:tableViewInformation]){
        _TableViewDataArrayC2[row] = object;
    }
    [_CommandTableView reloadData];
    NSLog(@"%@",object);
}

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
    return @"single click to run command，double click to modify";
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {

    NSTableView *tableView = notification.object;
    //selectedRow 用于添加和删除command
    if (tableView.selectedRow != -1) {
        NSLog(@"%ld %@:%@", tableView.selectedRow,_TableViewDataArrayC1[tableView.selectedRow],_TableViewDataArrayC2[tableView.selectedRow]);
        selectedRow = tableView.selectedRow;
        _SendCommandTextField.stringValue = _TableViewDataArrayC1[tableView.selectedRow];
        [self sendCMD:_TableViewDataArrayC1[tableView.selectedRow]];
    }else{
        selectedRow = -1;
    }
//    [_popView showRelativeToRect:tableView.cell.controlView.bounds ofView:tableView.cell.controlView preferredEdge:NSRectEdgeMaxY];
//    [_popView showRelativeToRect:tableView. ofView:button preferredEdge:NSRectEdgeMaxY];
}

//UI右下角计时功能
- (void)djs
{
    __block int timeout = 0;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t _timer1 = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_timer(_timer1,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //没秒执行
    dispatch_source_set_event_handler(_timer1, ^{
        if(timeout < 0){ //倒计时结束，关闭
            dispatch_source_cancel(_timer1);
            //            dispatch_release(_timer1);
            dispatch_async(dispatch_get_main_queue(), ^{
                //设置界面的按钮显示 根据自己需求设置
            });
        }else{
            int hour = timeout / 3600;
            timeout = timeout % 3600;
            int minutes = timeout / 60;
            int seconds = timeout % 60;
            NSString *strTime = [NSString stringWithFormat:@"%.2d:%.2d:%.2d",hour,minutes, seconds];
            //            NSLog(@"%@",strTime);
            dispatch_async(dispatch_get_main_queue(), ^{
                //设置界面的按钮显示 根据自己需求设置
                _timeStamp.stringValue = strTime;
            });
            timeout++;
        }
    });
    dispatch_resume(_timer1);
}
- (IBAction)openAndCloseButton:(id)sender {
    NSString * port = [NSString stringWithFormat:@"/dev/cu.%@",_SelectedPort.selectedItem.title];
    int BaudRates = [_SelectedBaudRates.selectedItem.title intValue];
    if (BaudRates == 0) {
        //如果未选择波特率，则默认为 115200
        BaudRates = 115200;
    }
    if ([_openAndCloseButton.title isEqualToString:@"open"]) {
        fd = -1;
        fd = [SerialPortObject OpenSerialPort:port BaudRates:BaudRates];
        NSLog(@"%d",fd);
        if(fd != -1){
            isOpen = TRUE;
            _openAndCloseButton.title = @"close";
            [self logInfo:@"open port successed" port:@""];
            [_SelectedPort setEnabled:NO];
            [_SelectedBaudRates setEnabled:NO];
            dispatch_group_async(testItemGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self readString];
            });
//            [self.timer setFireDate:[NSDate distantPast]];  //  nstimer开启
        }else{
            //            [self showAlert];
            [self alertModalFirstBtnTitle:@"确定" SecondBtnTitle:@"取消" MessageText:@"打开串口失败" InformativeText:@"打开串口失败，请检查接线"];
            isOpen = FALSE;
            [self logError:@"port open" port:@""];
        }
    }else{
//        [self.timer setFireDate:[NSDate distantFuture]];   //关掉nstimer
        [SerialPortObject CloseSerialPort:fd];
        _openAndCloseButton.title = @"open";
        isOpen = FALSE;
        [self logInfo:@"port close" port:@""];
        [_SelectedPort setEnabled:YES];
        [_SelectedBaudRates setEnabled:YES];
    }
}
-(void)alertModalFirstBtnTitle:(NSString *)firstname SecondBtnTitle:(NSString *)secondname MessageText:(NSString *)messagetext InformativeText:(NSString *)informativetext{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:firstname];
    [alert addButtonWithTitle:secondname];
    [alert setMessageText:messagetext];
    [alert setInformativeText:informativetext];
    [alert setAlertStyle:NSAlertStyleWarning];
    NSUInteger action = [alert runModal];
    //响应window的按钮事件
    if(action == NSAlertFirstButtonReturn)
    {
        NSLog(@"defaultButton clicked!");
    }
    else if(action == NSAlertSecondButtonReturn )
    {
        NSLog(@"alternateButton clicked!");
    }
    else if(action == NSAlertThirdButtonReturn)
    {
        NSLog(@"otherButton clicked!");
    }
}
- (void)showAlert {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert* msgBox = [[NSAlert alloc] init];
        [msgBox setMessageText: @"open errored"];
        [msgBox addButtonWithTitle: @"好的"];
        [msgBox addButtonWithTitle: @"取消"];
        [msgBox runModal];
    });
}
- (void)readString
{
    NSString * string = [[NSString alloc] init];
    do {
        string = [SerialPortObject readSerialPort:fd];
        if (string.length > 0) {
            [_bufferString appendString:string];
            if ([_bufferString containsString:@"\r"]) {
                [self logInfo:_bufferString port:@"44"];
                [_bufferString setString:@""];
            }
        }else{
            [NSThread sleepForTimeInterval:0.01];
        }
        string = @"";
    } while (isOpen);
}
- (IBAction)SendCommand:(id)sender {
    NSString * command = _SendCommandTextField.stringValue;
    if ([[command uppercaseString] containsString:@"BPHELP"]) {
        [self logInfo:[NSString stringWithFormat:@"\n%@",_dc.helpString] port:@""];
        return;
    }
    
    if ([_NomalAndEditButton.title isEqualToString:@"Edit"]) {
        [self logInfo:@"In editorial state" port:@""];
        if (selectedRow != -1) {
            [_TableViewDataArrayC1 replaceObjectAtIndex:selectedRow withObject:command];
            [self logInfo:@"Edit command successed" port:@""];
            [_CommandTableView reloadData];
        }else{
            [self logInfo:@"please select a command" port:@""];
        }
        return;
    }
    
    [self sendCMD:command];
}

- (void)sendCMD:(NSString *)CMD
{
    if ([_NomalAndEditButton.title isEqualToString:@"Edit"]) {
        [self logInfo:@"In editorial state" port:@""];
        return;
    }
    if (!isOpen) {
        [self logError:@"port is closed,please check connect" port:@""];
        return;
    }
    dispatch_group_async(testItemGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([[CMD uppercaseString] isEqualToString:@"BPALL"]) {
            for (NSString * command1 in _TableViewDataArrayC1) {
                if ([[command1 lowercaseString] containsString:@"sleep"]) {
                    if ([command1 componentsSeparatedByString:@" "].count == 2) {
                        [NSThread sleepForTimeInterval:[[command1 componentsSeparatedByString:@" "][1] intValue]];
                        [self logInfo:command1 port:@""];
                    }
                    continue;
                }
                if (command1.length < 1) {
                    continue;
                }
                [self logInfo:command1 port:@""];
                if (![SerialPortObject WriteCommand:command1 Port:&(fd)]) {
                    [self logError:[NSString stringWithFormat:@"%@ write faild",command1] port:@""];
                    continue;
                };
            }
        }else if ([CMD containsString:@";"]){
            NSArray * commandArray1 = [CMD componentsSeparatedByString:@";"];
            for (NSString * command1 in commandArray1) {
                if ([[command1 lowercaseString] containsString:@"sleep"]) {
                    if ([command1 componentsSeparatedByString:@" "].count == 2) {
                        [NSThread sleepForTimeInterval:[[command1 componentsSeparatedByString:@" "][1] intValue]];
                        [self logInfo:command1 port:@""];
                    }
                    continue;
                }
                if (command1.length < 1) {
                    continue;
                }
                [self logInfo:command1 port:@""];
                if (![SerialPortObject WriteCommand:command1 Port:&(fd)]) {
                    [self logError:[NSString stringWithFormat:@"%@ write faild",command1] port:@""];
                    continue;
                };
                [NSThread sleepForTimeInterval:0.1];
            }
        }else{
            if (CMD.length < 1) {
                return;
            }
            if ([[CMD lowercaseString] containsString:@"sleep"]) {
                if ([CMD componentsSeparatedByString:@" "].count == 2) {
                    [NSThread sleepForTimeInterval:[[CMD componentsSeparatedByString:@" "][1] intValue]];
                    [self logInfo:CMD port:@""];
                }
                return;
            }
            [self logInfo:CMD port:@""];
            if (![SerialPortObject WriteCommand:CMD Port:&(fd)]) {
                [self logError:[NSString stringWithFormat:@"%@ write faild",CMD] port:@""];
                return;
            };
        }
    });
}

- (IBAction)clear:(id)sender {
    [_LogTextView setString:@""];
}
- (IBAction)newWindow:(id)sender {
    static int a = 1;
    _NewWindow1 = [[NewWindow alloc] initWithWindowNibName:@"NewWindow"];
    _NewWindow1.window.title = [NSString stringWithFormat:@"Window %d",a];
    a ++;
    [_NewWindow1.window orderFront:nil];
    [_NewWindow1.window center];
}


#pragma mark serialPort connected and disconnected notification
- (void)serialPortsWereConnected:(NSNotification *)notification
{
    NSArray *connectedPorts = [notification userInfo][ORSConnectedSerialPortsKey];
    NSLog(@"Ports were connected: %@", connectedPorts);
    [self postUserNotificationForConnectedPorts:connectedPorts];
    [_SelectedPort removeAllItems];
    for (NSString * path in self.serialPortManager.availablePorts) {
        [_SelectedPort addItemWithTitle:[NSString stringWithFormat:@"%@",path]];
    }
}

- (void)serialPortsWereDisconnected:(NSNotification *)notification
{
    NSArray *disconnectedPorts = [notification userInfo][ORSDisconnectedSerialPortsKey];
    NSLog(@"Ports were disconnected: %@", disconnectedPorts);
    NSLog(@"%@\n%@",_SelectedPort.selectedItem.title,disconnectedPorts[0]);
//    dispatch_async(dispatch_get_main_queue(), ^{
//    });
    NSString * selectPort = [[NSString alloc] initWithString:_SelectedPort.selectedItem.title];
    NSString * disConnectPort = [NSString stringWithFormat:@"%@",disconnectedPorts[0]];
    if ([selectPort isEqualToString:disConnectPort]) {
        isOpen = FALSE;
        _openAndCloseButton.title = @"open";
        [self logInfo:@"port closed" port:@""];
        [_SelectedPort setEnabled:YES];
        [_SelectedBaudRates setEnabled:YES];
    }
    [self postUserNotificationForDisconnectedPorts:disconnectedPorts];
    [_SelectedPort removeAllItems];
    for (NSString * path in self.serialPortManager.availablePorts) {
        [_SelectedPort addItemWithTitle:[NSString stringWithFormat:@"%@",path]];
    }
}

- (void)postUserNotificationForConnectedPorts:(NSArray *)connectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in connectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"Serial Port Connected", @"Serial Port Connected");
        NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was connected to your Mac.", @"Serial port connected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat,port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}

- (void)postUserNotificationForDisconnectedPorts:(NSArray *)disconnectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in disconnectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"Serial Port Disconnected", @"Serial Port Disconnected");
        NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was disconnected from your Mac.", @"Serial port disconnected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}
//log的时间戳
- (NSString *)getCurrentTime
{
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString* currentTime = [formatter stringFromDate:date];
    return currentTime;
}
#pragma mark - Log method -
//port参数用来区分发送和接受的log
- (void)logInfo:(NSString *)msg port:(NSString *)port
{
//    NSString * time = [self getCurrentTime];
    NSString * paragraph = @"";
    if ([port isEqualToString:@"44"]) {
        if ([msg hasSuffix:@"\r"] || [msg hasSuffix:@"\n"]) {
            paragraph = [NSString stringWithFormat:@"BP>%@",msg];
        }else{
            paragraph = [NSString stringWithFormat:@"BP>%@\n",msg];
        }
    }else if([port isEqualToString:@"55"]){
        paragraph = [NSString stringWithFormat:@"🤟:%@\n",msg];
    }else{
        paragraph = [NSString stringWithFormat:@"👉🏻:%@\n",msg];
    }
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[_LogTextView textStorage] appendAttributedString:as];
        //        [[[_LogTextView textStorage] mutableString] appendString:paragraph];
        [self scrollToBottom];
    });
}
- (void)logError:(NSString *)msg port:(NSString *)port
{
//    NSString * time = [self getCurrentTime];
    NSString *paragraph = [NSString stringWithFormat:@"💔:%@\n",msg];
    //    [self Writelog:paragraph unit:unit];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[_LogTextView textStorage] appendAttributedString:as];
        [self scrollToBottom];
    });
}

- (void)scrollToBottom
{
    NSScrollView *scrollView = [_LogTextView enclosingScrollView];
    NSPoint newScrollOrigin;
    if ([[scrollView documentView] isFlipped])
        newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
    else
        newScrollOrigin = NSMakePoint(0.0F, 0.0F);
    [[scrollView documentView] scrollPoint:newScrollOrigin];
}

@end
