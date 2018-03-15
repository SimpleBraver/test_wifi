//
//  ViewController.m
//  test_wifi_02
//
//  Created by dev-002 on 2018/3/15.
//  Copyright © 2018年 GSK. All rights reserved.
//

#import "ViewController.h"

//iOS获取当前手机WIFI名称信息
#import <SystemConfiguration/CaptiveNetwork.h>

//获取网关信息
#import <arpa/inet.h>
#import <netinet/in.h>
#import <ifaddrs.h>
#import "getgateway.h"

//获取DNS Xcode中添加libresolv.dylib
#import <resolv.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //iOS获取当前手机WIFI名称信息
    NSString *currentSSID = [self fetchSSIDInfo];
    NSLog(@"WIFI名称：%@", currentSSID);
    
    NSString *gatewayIp = [self getGatewayIpForCurrentWiFi];
    NSLog(@"网关地址：%@", gatewayIp);
    
    NSString *dns = [self outPutDNSServers];
    NSLog(@"DNS服务器：%@", dns);

}

//iOS获取当前手机WIFI名称信息
-(NSString *)fetchSSIDInfo
{
    NSString *currentSSID = @"Not Found";
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil){
        NSDictionary* myDict = (__bridge NSDictionary *) CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict!=nil){
            currentSSID=[myDict valueForKey:@"SSID"];
            /* myDict包含信息：
             {
             BSSID = "ac:29:3a:99:33:45";
             SSID = "三千";
             SSIDDATA = <e4b889e5 8d83>;
             }
             */
        } else {
            currentSSID=@"<<NONE>>";
        }
    } else {
        currentSSID=@"<<NONE>>";
    }
    CFRelease(myArray);
    return currentSSID;
}

//获取网关等信息
- (NSString *)getGatewayIpForCurrentWiFi {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    NSLog(@"本机地址：%@",address);
                    
                    //routerIP----192.168.1.255 广播地址
                    NSLog(@"广播地址：%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)]);
                    
                    //--192.168.1.106 本机地址
                    NSLog(@"本机地址：%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]);
                    
                    //--255.255.255.0 子网掩码地址
                    NSLog(@"子网掩码地址：%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)]);
                    
                    //--en0 接口
                    //  en0       Ethernet II    protocal interface
                    //  et0       802.3             protocal interface
                    //  ent0      Hardware device interface
                    NSLog(@"接口名：%@",[NSString stringWithUTF8String:temp_addr->ifa_name]);
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    in_addr_t i = inet_addr([address cStringUsingEncoding:NSUTF8StringEncoding]);
    in_addr_t* x = &i;
    unsigned char *s = getdefaultgateway(x);
    NSString *ip=[NSString stringWithFormat:@"%d.%d.%d.%d",s[0],s[1],s[2],s[3]];
    free(s);
    return ip;
}

/// 获取本机DNS服务器
- (NSString *)outPutDNSServers
{
    res_state res = malloc(sizeof(struct __res_state));
    
    int result = res_ninit(res);
    
    NSMutableArray *dnsArray = @[].mutableCopy;
    
    if ( result == 0 )
    {
        for ( int i = 0; i < res->nscount; i++ )
        {
            NSString *s = [NSString stringWithUTF8String :  inet_ntoa(res->nsaddr_list[i].sin_addr)];
            
            [dnsArray addObject:s];
        }
    }
    else{
        NSLog(@"%@",@" res_init result != 0");
    }
    
    res_nclose(res);
    
    return dnsArray.firstObject;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
