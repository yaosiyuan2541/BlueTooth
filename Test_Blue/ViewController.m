//
//  ViewController.m
//  Test_Blue
//
//  Created by ibokan on 15/11/13.
//  Copyright © 2015年 ibokan. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
//蓝牙通讯的标准服务名
#define kBlunoService @"dfb0"
//蓝牙通讯的标准服务特征  这两个是蓝牙通讯中的必须条件，由蓝牙设备提供商提供，类似通讯协议
#define kBlunoDataCharacteristic @"dfb1"
@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property(nonatomic , strong)CBCentralManager *centeralManager;
@property(nonatomic , strong)CBPeripheral * peripheral;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //创建蓝牙管理者对象
    //蓝牙所有跟设备相关的操作全都在代理方法中执行
    self.centeralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

//获取当前蓝牙工作状态
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"%@",central);
    //切记，这个方法是用来开始查询周边设备信息，一定要确定在蓝牙开启之后在执行该方法，当获取蓝牙工作状态发发执行后，蓝牙设备开启
    [self.centeralManager scanForPeripheralsWithServices:@[] options:nil];
}

//获取周边蓝牙特征的代理方法
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    //获取全部蓝牙设备的id和name（这个对后面链接设备比较中庸）
//    NSLog(@"ID:%@",[peripheral.identifier UUIDString]);
    NSLog(@"name:%@",peripheral.name);
    
    
    
    if (!self.peripheral || (self.peripheral.state == CBPeripheralStateDisconnected)) {
        self.peripheral = peripheral;
        self.peripheral.delegate = self;
//        NSLog(@"connect peripheral");
        //连接蓝牙设备，此处连接蓝牙设备需要提供CBPeripheral实例，所以最后根据刚才的name或者id将CBPeripheral对象存放在集合中，以便于在其他位置进行连接
        [self.centeralManager connectPeripheral:peripheral options:nil];
    }
}
//设备成功链接后执行该代理
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if (!peripheral) {
        return;
    }
    //设备成功链接后停止搜索其他设备（不绝对）
    [self.centeralManager stopScan];
    
//    NSLog(@"peripheral did connect");
    [self.peripheral discoverServices:nil];
}
//蓝牙设备中的服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSArray *services = nil;
    
    if (peripheral != self.peripheral) {
        NSLog(@"Wrong Peripheral.\n");
        return ;
    }
    
    if (error != nil) {
        NSLog(@"Error %@\n", error);
        return ;
    }
    
    services = [peripheral services];
    if (!services || ![services count]) {
        NSLog(@"No Services");
        return ;
    }
    
    for (CBService *service in services) {
        //这个方法必须写，是将当前发现的服务跟当前设备进行绑定
        //如果不写该方法，那后面的方法中将获取不到该蓝牙设备的可用服务
        [peripheral discoverCharacteristics:nil forService:service];
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"characteristics:%@",[service characteristics]);
    
    if (peripheral != self.peripheral) {
        NSLog(@"Wrong Peripheral.\n");
        return ;
    }
    
    if (error != nil) {
        NSLog(@"Error %@\n", error);
        return ;
    }
    //设置监听。否则蓝牙返回的数据将接收不到
    //遍历当前蓝牙设备中的服务，匹配符合当前蓝牙协议的服务
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kBlunoService]]) {
            //遍历全部服务中的服务特征进行匹配，查询符合当前蓝牙设备协议的特征
            for (CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kBlunoDataCharacteristic]])
                {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                
            }
        }
    }
}
//发送蓝牙数据
- (IBAction)qqqqq:(id)sender {
    //写入数据
    for (CBService * service in self.peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kBlunoService]]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kBlunoDataCharacteristic]]) {
                    [self.peripheral writeValue:[@"1" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                }
            }
        }
    }
}
//接收蓝牙数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    NSLog(@"123333=%@",characteristic.value);
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
