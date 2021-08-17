#import "FlutterBlueClassicObjcPlugin.h"
#import "EADSessionController.h"
#import <ExternalAccessory/ExternalAccessory.h>

#define CASE(str) if ([__s__ isEqualToString:(str)])
#define SWITCH(s) for (NSString *__s__ = (s); ; )
#define DEFAULT

@interface FlutterBlueClassicObjcPlugin()
@property (nonatomic, strong) NSMutableArray *accessoryList;
@property (nonatomic, strong) EAAccessory *selectedAccessory;
@end

@implementation FlutterBlueClassicObjcPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"com.bhtri.flutter_blue_classic_objc"
                                     binaryMessenger:[registrar messenger]];
    FlutterBlueClassicObjcPlugin* instance = [[FlutterBlueClassicObjcPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    NSLog(@"🇯🇵 FlutterBlueClassicObjcPlugin::register");
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"🇯🇵 FlutterBlueClassicObjcPlugin::handle - %@", [call method]);
    
    SWITCH([call method]){
        CASE(@ "getPlatformVersion") {
            result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
            break;
        }
        CASE(@"regis") {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
            [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
            
            _accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
            
            result(@(TRUE));
            break;
        }
        CASE(@"unregis") {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidConnectNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidDisconnectNotification object:nil];
            
            _accessoryList = nil;
            result(@(TRUE));
            break;
        }
        CASE(@"list"){
            NSLog(@"|||||||| IOS ||||||||");
            for (EAAccessory *accessory in _accessoryList) {
                NSLog(@"Accessory name: %@", [accessory name]);
                NSLog(@"Manufacturer: %@", [accessory manufacturer]);
                NSLog(@"Model number: %@", [accessory modelNumber]);
                NSLog(@"Serial number: %@", [accessory serialNumber]);
                NSLog(@"HW Revision: %@", [accessory hardwareRevision]);
                NSLog(@"FW Revision: %@", [accessory firmwareRevision]);
                NSLog([accessory isConnected] ? @"YES": @"NO");
                NSLog(@"Connection ID: %lu", (unsigned long)[accessory connectionID]);
                NSLog(@"Protocol strings: %@", [accessory protocolStrings]);
                NSLog(@"==========================================");
            }
            break;
        }
        CASE(@"getDriverList"){
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            
            for (EAAccessory *accessory in _accessoryList) {
                [dictionary setObject:[NSString stringWithFormat:@"%lu", (unsigned long)accessory.connectionID] forKey:[NSString stringWithString:accessory.name]];
            }
            
            result(dictionary);
            break;
        }
        CASE(@"sendData"){
            NSDictionary *arguments = [call arguments];
            NSString *printer = [arguments objectForKey:@"printer"];
            NSString *strLength = [arguments objectForKey:@"length"];
            int length = [strLength intValue];
            
            if (length > 0) {
                // search printer
                bool isFound = NO;
                
                for (EAAccessory *accessory in _accessoryList) {
                    if ([accessory.name.lowercaseString compare:printer.lowercaseString] == NSOrderedSame) {
                        _selectedAccessory = accessory;
                        isFound = YES;
                        break;
                    }
                }

                if (NO == isFound) {
                    result(nil);
                    break;
                }
                
                // printer
                EADSessionController *sessionController = [EADSessionController sharedController];
                [sessionController setupControllerForAccessory:_selectedAccessory withProtocolString:_selectedAccessory.protocolStrings[0]];
                [sessionController closeSession];
                [sessionController openSession];
                
                for (int index = 0; index < length; index++) {
                    NSString *dataPrinter = [arguments objectForKey:[NSString stringWithFormat:@"data%d", index]];
                    
                    // base64 decode
                    NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:dataPrinter options:0];
                    NSString *base64Decoded = [[NSString alloc] initWithData:nsdataFromBase64String encoding:NSShiftJISStringEncoding];

                    const char *buf = [base64Decoded cStringUsingEncoding:NSShiftJISStringEncoding];

                    if (buf) {
                        uint32_t len = (uint32_t)strlen(buf) + 1;
                        [[EADSessionController sharedController] writeData:[NSData dataWithBytes:buf length:len]];
                    }
                    
//                    NSData *data = [base64Decoded dataUsingEncoding:NSShiftJISStringEncoding];
//                    [[EADSessionController sharedController] writeData:data];
                }
                
                
            }
            
            break;
        }
        DEFAULT {
            result(FlutterMethodNotImplemented);
            break;
        }
    }
}

#pragma mark Internal
- (void)_accessoryDidConnect:(NSNotification *)notification {
    EAAccessory *connectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    
    [_accessoryList addObject:connectedAccessory];
}

- (void)_accessoryDidDisconnect:(NSNotification *)notification {
    EAAccessory *disconnectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    
    int disconnectedAccessoryIndex = 0;
    for (EAAccessory *accessory in _accessoryList) {
        if([disconnectedAccessory connectionID] == [accessory connectionID]) {
            break;
        }
        disconnectedAccessoryIndex++;
    }
    
    if (disconnectedAccessoryIndex < [_accessoryList count]) {
        [_accessoryList removeObjectAtIndex:disconnectedAccessoryIndex];
    } else {
        NSLog(@"📌 could not find disconnected accessory in accessory list");
    }
}
@end
