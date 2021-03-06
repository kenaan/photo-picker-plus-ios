//
//  AssetsCollectionViewController.m
//  GCAPIv2TestApp
//
//  Created by Chute Corporation on 7/25/13.
//  Copyright (c) 2013 Aleksandar Trpeski. All rights reserved.
//

#import "GCAssetsCollectionViewController.h"
#import "PhotoCell.h"
#import "GCAccountAssets.h"
#import "GCServiceAccountAlbum.h"
#import "NSDictionary+ALAsset.h"

#import <MBProgressHUD.h>
#import <AFNetworking.h>

@interface GCAssetsCollectionViewController ()

@property (strong, nonatomic) NSMutableArray *selectedAssets;

@property (nonatomic, strong) UIBarButtonItem *doneButton;

@end

@implementation GCAssetsCollectionViewController

@synthesize doneButton;
@synthesize successBlock, cancelBlock;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.collectionView setBackgroundColor:[UIColor whiteColor]];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Assets";
    if(self.isMultipleSelectionEnabled)
        [self setDoneAndCancelButtons];
    else
        [self setCancelButton];
    
    self.selectedAssets = [@[] mutableCopy];

    if(self.isItDevice)
        [self getLocalAssets];
    else
        [self getAccountAssets];
    
    [self.collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:@"Cell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CollectionView DataSource Methods

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.assets count];
}

-(PhotoCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell *cell = (PhotoCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    if(self.isItDevice)
    {
        ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
        cell.imageView.image = [UIImage imageWithCGImage:[asset thumbnail]];
    }
    else
    {
        GCAccountAssets *asset = [self.assets objectAtIndex:indexPath.row];
       AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[asset thumbnail]]] success:^(UIImage *image) {
            [cell.imageView setImage:image];
       }];
        [operation start];
    }

    return cell;
}

#pragma mark - CollectionView Delegate Methods

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if([self isItDevice])
    {
        ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
        [self.selectedAssets addObject:asset];
    }
    else
    {
        GCAccountAssets *asset = [self.assets objectAtIndex:indexPath.row];
        [self.selectedAssets addObject:asset];
    }
    
    if(self.isMultipleSelectionEnabled)
    {
        [self.collectionView setAllowsMultipleSelection:YES];
        
        if([self.selectedAssets count] > 0)
            [self.doneButton setEnabled:YES];
    }
    else
    {
        [self done];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.isMultipleSelectionEnabled)
    {        
        if([self isItDevice])
        {
            ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
            [self.selectedAssets removeObject:asset];
        }
        else
        {
            GCAccountAssets *asset = [self.assets objectAtIndex:indexPath.row];
            [self.selectedAssets removeObject:asset];
        }
        
        if([self.selectedAssets count] == 0)
            [self.doneButton setEnabled:NO];
    }
}

#pragma mark - Custom Methods

- (void)getLocalAssets
{
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result !=nil){
            [temp insertObject:result atIndex:0];
        }
        else
        {
            [self setAssets:temp];
            [self.collectionView reloadData];
        }
        
    }];
}

- (void)getAccountAssets
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [GCServiceAccountAlbum getDataForServiceWithName:self.serviceName forAccountWithID:self.accountID forAlbumWithID:self.albumID success:^(GCResponseStatus *responseStatus, NSArray *folders, NSArray *files) {
        [MBProgressHUD hideHUDForView:self.view animated:NO];
        self.assets = [[NSMutableArray alloc] initWithArray:files];
        [self.collectionView reloadData];
    } failure:^(NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:NO];
        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Cannot Fetch Account Assets!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];
    
//    [GCServiceAccountAlbum getMediaForAccountWithID:self.accountID forAccountAlbumWithID:self.albumID success:^(GCResponseStatus *responseStatus, NSArray *accountAssets) {
//        [MBProgressHUD hideHUDForView:self.view animated:NO];
//        self.assets = [[NSMutableArray alloc] initWithArray:accountAssets];
//        [self.collectionView reloadData];
//    } failure:^(NSError *error) {
//        [MBProgressHUD hideHUDForView:self.view animated:NO];
//        [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Cannot Fetch Account Assets!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//    }];
}

- (void)setCancelButton
{
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    [self.navigationItem setRightBarButtonItem:cancelButton];

    [self.navigationItem setRightBarButtonItem:cancelButton];
}

- (void)setDoneAndCancelButtons
{
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    [self.navigationItem setRightBarButtonItem:cancelButton];
    
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    [doneButton setEnabled:NO];
    
    NSArray *navBarItemsToBeAdd = [NSArray arrayWithObjects:doneButton,cancelButton,nil];

    [self.navigationItem setRightBarButtonItems:navBarItemsToBeAdd];

}

#pragma mark - Instance Methods

- (void)done
{
    if (self.successBlock) {
        
        __block id info;
        
        MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:HUD];
        [HUD showAnimated:YES whileExecutingBlock:^{
            
            if ([self isMultipleSelectionEnabled]) {
                
                NSMutableArray *infoArray = [NSMutableArray array];
                if(self.isItDevice){
                    for (ALAsset *asset in self.selectedAssets) {
                        [infoArray addObject:([NSDictionary infoFromALAsset:asset])];
                    }
                }
                else
                {
                    for(GCAccountAssets *asset in self.selectedAssets){
                        [infoArray addObject:([NSDictionary infoFromGCAccountAsset:asset])];
                    }
                }
                info = infoArray;
            }
            else {
                if(self.isItDevice)
                    info = [NSDictionary infoFromALAsset:[self.selectedAssets objectAtIndex:0]];
                else
                    info = [NSDictionary infoFromGCAccountAsset:[self.selectedAssets objectAtIndex:0]];
            }
            
        } completionBlock:^{
            [HUD removeFromSuperview];
            [self successBlock](info);
        }];
    }
}

- (void)cancel
{
    if (self.cancelBlock)
        [self cancelBlock]();
}

#pragma mark - Setters

- (void)setIsMultipleSelectionEnabled:(BOOL)isMultipleSelectionEnabled
{
    if(_isMultipleSelectionEnabled != isMultipleSelectionEnabled)
        _isMultipleSelectionEnabled = isMultipleSelectionEnabled;
}

- (void)setIsItDevice:(BOOL)isItDevice
{
    if(_isItDevice != isItDevice)
        _isItDevice = isItDevice;
}

- (void)setAccountID:(NSNumber *)accountID
{
    if(_accountID != accountID)
        _accountID = accountID;
}

- (void)setAlbumID:(NSNumber *)albumID
{
    if(_albumID != albumID)
        _albumID = albumID;
}

- (void)setServiceName:(NSString *)serviceName
{
    if(_serviceName != serviceName)
        _serviceName = serviceName;
}
@end
