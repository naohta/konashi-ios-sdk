//
//  KonashiPeripheralImpl.m
//  Konashi
//
//  Created by Akira Matsuda on 9/19/14.
//  Copyright (c) 2014 Akira Matsuda. All rights reserved.
//

#import "KNSKonashiPeripheralImpl.h"
#import "KonashiUtils.h"

static NSInteger const i2cDataMaxLength = 20;

@interface KNSKonashiPeripheralImpl ()
{
	// I2C
	unsigned char i2cReadData[i2cDataMaxLength];
}

@end

@implementation KNSKonashiPeripheralImpl

+ (NSInteger)i2cDataMaxLength
{
	return i2cDataMaxLength;
}

+ (NSInteger)levelServiceReadLength
{
	return 1;
}

+ (NSInteger)pioInputNotificationReadLength
{
	return 1;
}

+ (NSInteger)analogReadLength
{
	return 2;
}

+ (NSInteger)uartRX_NotificationReadLength
{
	return 1;
}

+ (NSInteger)hardwareLowBatteryNotificationReadLength
{
	return 1;
}

// UUID
+ (CBUUID *)batteryServiceUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"180F", uuid);
}

+ (CBUUID *)levelServiceUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"2A19", uuid);
}

+ (CBUUID *)powerStateUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"2A1B", uuid);
}

+ (CBUUID *)serviceUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"FF00", uuid);
}

// PIO
+ (CBUUID *)pioSettingUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3000", uuid);
}

+ (CBUUID *)pioPullupUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3001", uuid);
}

+ (CBUUID *)pioOutputUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3002", uuid);
}

+ (CBUUID *)pioInputNotificationUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3003", uuid);
}

// PWM
+ (CBUUID *)pwmConfigUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3004", uuid);
}

+ (CBUUID *)pwmParamUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3005", uuid);
}

+ (CBUUID *)pwmDutyUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3006", uuid);
}

// Analog
+ (CBUUID *)analogDriveUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3007", uuid);
}

+ (CBUUID *)analogReadUUIDWithPinNumber:(NSInteger)pin
{
	CBUUID *uuid = nil;
	switch (pin) {
		case 0: {
			static CBUUID *uuid0;
			uuid = kns_CreateUUIDFromString(@"3008", uuid0);
		}
			break;
		case 1: {
			static CBUUID *uuid1;
			uuid = kns_CreateUUIDFromString(@"3009", uuid1);
		}
			break;
		case 2: {
			static CBUUID *uuid2;
			uuid = kns_CreateUUIDFromString(@"300A", uuid2);
		}
			break;
		default:
			break;
	}
	
	return uuid;
}

// I2C
+ (CBUUID *)i2cConfigUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"300B", uuid);
}

+ (CBUUID *)i2cStartStopUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"300C", uuid);
}

+ (CBUUID *)i2cWriteUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"300D", uuid);
}

+ (CBUUID *)i2cReadParamUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"300E", uuid);
}

+ (CBUUID *)i2cReadUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"300F", uuid);
}

// UART
+ (CBUUID *)uartConfigUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3010", uuid);
}

+ (CBUUID *)uartBaudrateUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3011", uuid);
}

+ (CBUUID *)uartTX_UUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3012", uuid);
}

+ (CBUUID *)uartRX_NotificationUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3013", uuid);
}

// Hardware
+ (CBUUID *)hardwareResetUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3014", uuid);
}

+ (CBUUID *)lowBatteryNotificationUUID
{
	static CBUUID *uuid;
	return kns_CreateUUIDFromString(@"3015", uuid);
}

- (instancetype)initWithPeripheral:(CBPeripheral *)p
{
	self = [super initWithPeripheral:p];
	if (self) {
		// I2C
		i2cSetting = KonashiI2CModeDisable;
		for (NSInteger i = 0; i < [[self class] i2cDataMaxLength]; i++) {
			i2cReadData[i] = 0;
		}
		i2cReadDataLength = 0;
		i2cReadAddress = 0;
	}
	
	return self;
}

- (KonashiResult) i2cReadRequest:(int)length address:(unsigned char)address
{
	if(length > 0 && (i2cSetting == KonashiI2CModeEnable || i2cSetting == KonashiI2CModeEnable100K || i2cSetting == KonashiI2CModeEnable400K) &&
       self.peripheral && self.peripheral.state == CBPeripheralStateConnected){
        
        // set variables
        i2cReadAddress = (address<<1)|0x1;
        i2cReadDataLength = length;
        
        // Set read params
        Byte t[] = {length, i2cReadAddress};
		[self writeData:[NSData dataWithBytes:t length:2] serviceUUID:[[self class] serviceUUID] characteristicUUID:[[self class] i2cReadParamUUID]];

        
        // Request read i2c value
		[self readDataWithServiceUUID:[[self class] serviceUUID] characteristicUUID:[[self class] i2cReadUUID]];
        
        return KonashiResultSuccess;
    }
    else{
        return KonashiResultFailure;
    }
}

- (KonashiResult) i2cRead:(int)length data:(unsigned char*)data
{
	int i;
	
    if(length==i2cReadDataLength){
        for(i=0; i<i2cReadDataLength;i++){
            data[i] = i2cReadData[i];
        }
        return KonashiResultSuccess;
    }
    else{
        return KonashiResultFailure;
    }
}

- (void)writeData:(NSData *)data serviceUUID:(CBUUID*)serviceUUID characteristicUUID:(CBUUID*)characteristicUUID
{
	[super writeData:data serviceUUID:serviceUUID characteristicUUID:characteristicUUID];
    // konashi needs to sleep to get I2C right
    [NSThread sleepForTimeInterval:0.03];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	[super peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:error];
	if (!error) {
		if ([characteristic.UUID kns_isEqualToUUID:[[self class] i2cReadUUID]]) {
			[characteristic.value getBytes:i2cReadData length:i2cReadDataLength];
			// [0]: MSB
			
			[[NSNotificationCenter defaultCenter] postNotificationName:KonashiEventI2CReadCompleteNotification object:nil];
		}
	}
}

@end
