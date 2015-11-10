//
//  PeripheralViewController.m
//  AppPrototype
//
//  Created by Alexander Person on 11/10/15.
//  Copyright © 2015 Alexander Person. All rights reserved.
//

#import "PeripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferService.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPMediaPickerController.h>
#import <CoreMedia/CoreMedia.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MPMediaQuery.h>
#import "MediaPlayer/MediaPlayer.h"
#import "PlaylistTableViewController.h"

@interface PeripheralViewController () <CBPeripheralManagerDelegate, UITextViewDelegate, MPMediaPickerControllerDelegate> {
    NSArray *songs;
}


@property (strong, nonatomic) IBOutlet UISwitch         *advertisingSwitch;
@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *transferCharacteristic;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) NSData *musicData;
@property (strong, nonatomic) NSURL *url;
@property (nonatomic, retain) IBOutlet UILabel *sizeLabel;
@property (strong, nonatomic) NSData *exportedMusicData;
@property (strong, nonatomic) NSMutableArray *songTitles;

@end

#define NOTIFY_MTU      150
#define EXPORT_NAME @"exported.caf"

@implementation PeripheralViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Start up the CBPeripheralManager
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    NSLog(@"Peripherial viewcontroller loaded");
    
    songs = [[NSArray alloc] init];
    _songTitles = [[NSMutableArray alloc] init];
}



- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    [self dismissViewControllerAnimated: YES completion:nil];
}



//- (void)viewWillDisappear:(BOOL)animated
//{
//    // Don't keep it going while we're not showing.
//    [self.peripheralManager stopAdvertising];
//    
//    [super viewWillDisappear:animated];
//}



- (IBAction)showMediaPicker:(id)sender {
    MPMediaPickerController *picker = [[MPMediaPickerController alloc]
                                       initWithMediaTypes: MPMediaTypeAnyAudio];
    
    [picker setDelegate: self];
    [picker setAllowsPickingMultipleItems: YES];
    picker.prompt =
    NSLocalizedString (@"Add songs to play",
                       "Prompt in media item picker");
    
    [self presentViewController: picker animated: YES completion:nil];
}



- (void) mediaPicker: (MPMediaPickerController *) mediaPicker
   didPickMediaItems: (MPMediaItemCollection *) collection {
    NSLog(@"item picked %@", collection );
    
    
    [self dismissViewControllerAnimated: YES completion:nil];
    songs = [collection items];
    for (MPMediaItem *song in songs) {
        [self.songTitles addObject:[song valueForProperty: MPMediaItemPropertyTitle]];
    }
        
//    for (MPMediaItem *song in songs) {
//        NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
//        NSLog (@"\t\t%@", songTitle);
//        NSString *songType = [song valueForProperty: MPMediaItemPropertyMediaType];
//        NSLog (@"\t\t%@", songType);
//        
//        //setting self url to be the URL of the current song.
//        self.url = [song valueForProperty:MPMediaItemPropertyAssetURL];
//    }
    NSLog(@"Song Titles Array: %@", self.songTitles);
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender

{
    PlaylistTableViewController *ptvc = [segue destinationViewController];
    
    ptvc.songs = songs;
}



#pragma mark - Peripheral methods



- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Opt out from any other state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    // We're in CBPeripheralManagerStatePoweredOn state...
    NSLog(@"self.peripheralManager powered on.");
    
    // ... so build our service.
    
    // Start with the CBMutableCharacteristic
    self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                     properties:CBCharacteristicPropertyNotify
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsReadable];
    // Then the service
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]
                                                                       primary:YES];
    
    // Add the characteristic to the service
    transferService.characteristics = @[self.transferCharacteristic];
    
    // And add it to the peripheral manager
    [self.peripheralManager addService:transferService];
}



/** Catch when someone subscribes to our characteristic, then start sending them data
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
    
    // Get the data
    self.dataToSend = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    
    // Reset the index
    self.sendDataIndex = 0;
    
    // Start sending
    [self sendData];
}



#pragma mark - Switch Methods



// Start advertising
- (IBAction)switchChanged:(id)sender
{
    if (self.advertisingSwitch.on) {
        // All we advertise is our service's UUID and Device name
        NSLog(@"Start advertising");
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]], CBAdvertisementDataLocalNameKey : [[UIDevice currentDevice] name]}];
    }
    
    else {
        [self.peripheralManager stopAdvertising];
    }
}
@end
