//
//  DevicesTableViewController.m
//  AppPrototype
//
//  Created by Alexander Person on 11/10/15.
//  Copyright © 2015 Alexander Person. All rights reserved.
//

#import "DevicesTableViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferService.h"

@interface DevicesTableViewController () <CBCentralManagerDelegate, CBPeripheralDelegate> {
    NSMutableArray *discoveredPeripheralDevices;
}

@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData         *data;
@property (readonly) CBPeripheralState state;

@end

@implementation DevicesTableViewController



#pragma mark - View Lifecycle



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Start up the CBCentralManager
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    // And somewhere to store the incoming data
    _data = [[NSMutableData alloc] init];
    
    // create array for discovered device objects
    discoveredPeripheralDevices = [[NSMutableArray alloc] init];
    
    NSLog(@"View loaded");
    
}



#pragma mark - Central Methods



- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        // Deal with all states correctly
        return;
    }
    
    // The state must be CBCentralManagerStatePoweredOn...
    
    // ... so start scanning
    [self scan];
    
}



- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
    NSLog(@"Scanning started");
}



- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Reject any where the value is above reasonable range
    if (RSSI.integerValue > -15) {
        return;
    }
    
    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
    if (RSSI.integerValue < -35) {
        return;
    }
    
    //    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    // Ok, it's in range - have we already seen it?
    if (self.discoveredPeripheral != peripheral) {
        
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        
        // Check if our list of discovered devices already contains the current peripheral.
        // If not, add it in.
        if (![discoveredPeripheralDevices containsObject:peripheral]) {
            [discoveredPeripheralDevices addObject:peripheral];
            [self.tableView reloadData];
        }
        
        // And connect
        //        NSLog(@"Connecting to peripheral %@", peripheral);
        //        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return discoveredPeripheralDevices.count;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    CBPeripheral *current = [discoveredPeripheralDevices objectAtIndex:indexPath.row];
    cell.textLabel.text = [current name];
    
    return cell;
}



//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    // Get the new view controller using [segue destinationViewController].
//    CentralViewController *cvc = [segue destinationViewController];
//    //Pass the selected object to the new veiw controller.
//    // What's the selected cell?
//    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
//    CBPeripheral *cd = discoveredPeripheralDevices[path.row];
//    //    NSLog(@"Connecting to peripheral %@", cd);
//    //    [self.centralManager connectPeripheral:cd options:nil];
//    cvc.selectedPeripheral = cd;
//    //    cvc.centralManager = self.centralManager;
//}



@end
