//
//  PlaylistTableViewController.m
//  AppPrototype
//
//  Created by Alexander Person on 11/10/15.
//  Copyright © 2015 Alexander Person. All rights reserved.
//

#import "PlaylistTableViewController.h"

@implementation PlaylistTableViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



#pragma mark - Table view data source



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.songs.count;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    MPMediaItem *current = [self.songs objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [current valueForProperty: MPMediaItemPropertyTitle];
    cell.detailTextLabel.text = [current valueForProperty:MPMediaItemPropertyAlbumArtist];
    
    MPMediaItemArtwork *artwork = [current valueForProperty:MPMediaItemPropertyArtwork];
    
    UIImage *artworkImage = [artwork imageWithSize: CGSizeMake (44, 44)];
    
    if (artworkImage) {
        cell.imageView.image = artworkImage;
    } else {
        cell.imageView.image = [UIImage imageNamed:@"No-artwork-albums.png"];
    }
    
    return cell;
}

@end
