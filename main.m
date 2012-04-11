/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 5.x Edition
 BSD License, Use at your own risk
 */

#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreData/CoreData.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PhotoItem.h"

#import "Utilities.h"
#import "Geometry.h"
#import "UIImage-Utilities.h"
#import "Orientation.h"

#define COOKBOOK_PURPLE_COLOR    [UIColor colorWithRed:0.20392f green:0.19607f blue:0.61176f alpha:1.0f]
#define BARBUTTON(TITLE, SELECTOR)     [[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR]
#define SYSBARBUTTON(ITEM, SELECTOR) [[UIBarButtonItem alloc] initWithBarButtonSystemItem:ITEM target:self action:SELECTOR] 
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

@interface TestBedViewController : UITableViewController <NSFetchedResultsControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate>
{
    NSManagedObjectContext *context;
    NSFetchedResultsController *fetchedResultsController;
    UIPopoverController *popoverController;
    UIImagePickerController *imagePickerController;
    
    NSMutableDictionary *imageCache;
    NSMutableDictionary *imageOrientation;
}
@end

@implementation TestBedViewController

NSString *documentsPath()
{
    /*
     NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
     NSString * documentsPath = [resourcePath stringByAppendingPathComponent:@"Documents"];
     return documentsPath;
     */
    return [NSString stringWithFormat:@"%@/Documents", NSHomeDirectory()];
}

// Finds image name that not in use
NSString *uniqueSavePath()
{
    int i = 1;
    NSString *path;
    do {
        // iterate until a name does not match an existing file
        path = [NSString stringWithFormat:
                @"%@/IMAGE_%04d.JPG", documentsPath(), i++];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:path]);
    return path;
}

NSString *uniqueSaveFilename()
{
    int i = 1;
    NSString *path;
    do {
        // iterate until a name does not match an existing file
        path = [NSString stringWithFormat:
                @"%@/IMAGE_%04d.JPG", documentsPath(), i++];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:path]);
    return [path lastPathComponent];
}

#pragma  -
#pragma  fetch

- (void) performFetch
{
    // Init a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PhotoItem" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:100]; // more than needed for this example
    
    // Apply an ascending sort for the items
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"currentName" ascending:YES selector:nil];
    NSArray *descriptors = [NSArray arrayWithObject:sortDescriptor];
    [fetchRequest setSortDescriptors:descriptors];
    
    // Init the fetched results controller
    NSError *error;
    fetchedResultsController = [[NSFetchedResultsController alloc] 
                                initWithFetchRequest:fetchRequest 
                                managedObjectContext:context 
                                sectionNameKeyPath:@"sectionName" 
                                cacheName:nil];
    fetchedResultsController.delegate = self;
    if (![fetchedResultsController performFetch:&error])    
        NSLog(@"Error: %@", [error localizedFailureReason]);
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
    [self setBarButtonItems];
}

#pragma mark Table Sections
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return [[fetchedResultsController sections] count];
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section
{
    // Return the title for a given section
    NSArray *titles = [fetchedResultsController sectionIndexTitles];
    if (titles.count <= section) return @"Error";
    return [titles objectAtIndex:section];
}

#pragma mark Items in Sections
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [[[fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Retrieve or create a cell
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basic cell"];
    //if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"basic cell"];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CustomPhotoCell"];
    //cell.frame.size.height = 70;
    
    // Recover object from fetched results
    NSManagedObject *managedObject = [fetchedResultsController objectAtIndexPath:indexPath];
    
    //cell.textLabel.text = [managedObject valueForKey:@"currentName"];
    
    // Retrieve the switch and add a target if needed
    
    UIImageView *uiImageView = (UIImageView *)[cell viewWithTag:21];

    if ([imageCache objectForKey:[managedObject valueForKey:@"currentName"]] == NULL)
    {
        
        //CGSize destSize = CGSizeMake(uiImageView.frame.size.width, uiImageView.frame.size.height);
        CGSize destSize = CGSizeMake(150,150);
        //uiImageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", documentsPath(), [managedObject valueForKey:@"currentName"]]];
        
        UIImage* imgTemp = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", documentsPath(), [managedObject valueForKey:@"currentName"]]];
    
        [imageCache setObject:[imgTemp fillSize:destSize] forKey:[managedObject valueForKey:@"currentName"]];
        [imageOrientation setObject:imageOrientationName(imgTemp) forKey:[managedObject valueForKey:@"currentName"]];
        
        /*
         // Using imageIO
         CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], NULL);
         CFDictionaryRef options = (__bridge CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:(id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform, (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent, (id)[NSNumber numberWithDouble:_maxSize], (id)kCGImageSourceThumbnailMaxPixelSize, nil];
         CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options); // Create scaled image
         CFRelease(options);
         CFRelease(src);
         UIImage* img = [[UIImage alloc] initWithCGImage:thumbnail];
         [v setImage:img];
         [img release];
         CGImageRelease(thumbnail);
         */
        
        imgTemp = nil;
    }
    
    uiImageView.image = [imageCache objectForKey:[managedObject valueForKey:@"currentName"]];
    
    
    UILabel *lblTitleView = (UILabel *)[cell viewWithTag:31];
    lblTitleView.text = [managedObject valueForKey:@"currentName"];
    
    // Size
    UILabel *lblSizeView = (UILabel *)[cell viewWithTag:41];
    lblSizeView.text = [imageOrientation objectForKey:[managedObject valueForKey:@"currentName"]];
    
    /*
    NSError *error;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fm attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@", documentsPath(), [managedObject valueForKey:@"currentName"]] error:&error ];
    if(fileAttributes != nil)
    {
        lblSizeView.text = [NSString stringWithFormat:@"%d kb", [fileAttributes objectForKey:NSFileSize]];
        //itemSizesStr = [NSString stringWithFormat:@"%@%d kb**", itemSizesStr, fileSize];
        //NSLog(@"File size: %@ kb", fileSize);
    }
     */
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 75;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // NSManagedObject *managedObject = [fetchedResultsController objectAtIndexPath:indexPath];
    // some action here
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return NO;     // no reordering allowed
}

#pragma mark Data
- (void) setBarButtonItems
{
    // left item is always add
    self.navigationItem.leftBarButtonItem = SYSBARBUTTON(UIBarButtonSystemItemAdd, @selector(add));
    
    // right (edit/done) item depends on both edit mode and item count
    int count = [[fetchedResultsController fetchedObjects] count];
    if (self.tableView.isEditing)
        self.navigationItem.rightBarButtonItem = SYSBARBUTTON(UIBarButtonSystemItemDone, @selector(leaveEditMode));
    else
        self.navigationItem.rightBarButtonItem =  count ? SYSBARBUTTON(UIBarButtonSystemItemEdit, @selector(enterEditMode)) : nil;
}

-(void)enterEditMode
{
    // Start editing
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [self.tableView setEditing:YES animated:YES];
    [self setBarButtonItems];
}

-(void)leaveEditMode
{
    // finish editing
    [self.tableView setEditing:NO animated:YES];
    [self setBarButtonItems];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // delete request
    if (editingStyle == UITableViewCellEditingStyleDelete) 
    {
        NSError *error = nil;
        [context deleteObject:[fetchedResultsController objectAtIndexPath:indexPath]];
        if (![context save:&error]) NSLog(@"Error: %@", [error localizedFailureReason]);
    }
    
    [self performFetch];
}

/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) return;
    
    NSString *todoAction = [alertView textFieldAtIndex:0].text;
    if (!todoAction || todoAction.length == 0) return;
    
    PhotoItem *item = (PhotoItem *)[NSEntityDescription insertNewObjectForEntityForName:@"PhotoItem" inManagedObjectContext:context];
    item.currentName = todoAction;
    item.sectionName = [[todoAction substringToIndex:1] uppercaseString];
    
    // save the new item
    NSError *error; 
    if (![context save:&error]) NSLog(@"Error: %@", [error localizedFailureReason]);
    
    [self performFetch];
}
 */

#pragma mark -
#pragma mark Image Picker
- (void) loadImageFromAssetURL: (NSURL *) assetURL
{
        ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
        
        ALAssetsLibraryAssetForURLResultBlock result = ^(ALAsset *__strong asset){
            @autoreleasepool {
                ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
                CGImageRef cgImage = [assetRepresentation CGImageWithOptions:nil];
                if (cgImage)
                {
                    // Load image to view
                    UIImage *image =  [UIImage imageWithCGImage:cgImage];
                    //imageView.image = image;
                    
                    // Save image into the folder
                    NSString *filename = uniqueSaveFilename();
                    NSString *path = [NSString stringWithFormat:@"%@/%@", documentsPath(), filename];
                    
                    [UIImageJPEGRepresentation(image, 100)
                        writeToFile:path atomically:YES];
                    
                    float _maxSize = 70.0;

                    
                    // Cache newly saved file
                    CGSize destSize = CGSizeMake(_maxSize, _maxSize);
                    [imageCache setObject:[image fitInSize:destSize] forKey:filename];
                    [imageOrientation setObject:imageOrientationName(image) forKey:filename];
                    NSLog(@"Image saved: %@", path);
                    
                    
                    // Get file size
                    //NSError *error;
                    //NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error ];
                    //if(fileAttributes != nil)
                    //{
                    //    NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
                    //    [itemSizes arrayByAddingObject:[NSString stringWithFormat:@"%d kb", fileSize]]; 
                    //}
                    
                    PhotoItem *item = (PhotoItem *)[NSEntityDescription insertNewObjectForEntityForName:@"PhotoItem" inManagedObjectContext:context];
                    item.currentName = filename;
                    item.sectionName = [[filename substringToIndex:1] uppercaseString];
                    //item.originalName = [assetURL lastPathComponent];
                    
                    // save the new item
                    NSError *error; 
                    if (![context save:&error]) NSLog(@"Error: %@", [error localizedFailureReason]);
                    //[item release];
                    
                } 
                [self performFetch];
            }
        };
        
        ALAssetsLibraryAccessFailureBlock failure = ^(NSError *__strong error){
            NSLog(@"Error retrieving asset from url: %@", [error localizedFailureReason]);
        };
        
        [library assetForURL:assetURL resultBlock:result failureBlock:failure];
        //[self.tableView reloadData];
    
}


// Update image and for iPhone, dismiss the controller
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	if (IS_IPHONE)
	{
        [self dismissModalViewControllerAnimated:YES];
        imagePickerController = nil;
	}
    
    NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
    NSLog(@"About to load asset from %@", url);
    [self loadImageFromAssetURL:url];
    //[self.tableView reloadData];
}

// Dismiss picker
- (void) imagePickerControllerDidCancel: (UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
    imagePickerController = nil;
}

// Popover was dismissed
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)aPopoverController
{
	imagePickerController = nil;
    popoverController = nil;
}

- (void) add
{
    /*
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"To Do" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Okay", nil];
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    [av show];
*/
    
    // Create an initialize the picker
	imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
	imagePickerController.delegate = self;
	
	if (IS_IPHONE)
	{   
        [self presentModalViewController:imagePickerController animated:YES];	
	}
	else 
	{
        if (popoverController) [popoverController dismissPopoverAnimated:NO];
        popoverController = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
        popoverController.delegate = self;
        [popoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
    
}

- (void) initCoreData
{
    NSError *error;
    
    // Path to sqlite file. 
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/photos.sqlite"];
    NSURL *url = [NSURL fileURLWithPath:path];
    
    // Init the model, coordinator, context
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) 
        NSLog(@"Error: %@", [error localizedFailureReason]);
    else
    {
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator:persistentStoreCoordinator];
    }
}

- (void) loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationController.navigationBar.tintColor = COOKBOOK_PURPLE_COLOR;
    self.navigationItem.rightBarButtonItem = BARBUTTON(@"Action", @selector(action:));
    
    // Register the nib for reuse
    [self.tableView registerNib: [UINib nibWithNibName:@"CustomPhotoCell"
                                                bundle:[NSBundle mainBundle]]
                                                forCellReuseIdentifier:@"CustomPhotoCell"];
    
    imageCache = [[NSMutableDictionary alloc] init];
    imageOrientation = [[NSMutableDictionary alloc] init];
    
    [self initCoreData];
    [self performFetch];
    [self setBarButtonItems];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
@end

#pragma mark -

#pragma mark Application Setup
@interface TestBedAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
}
@end
@implementation TestBedAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{    
    [application setStatusBarHidden:YES];
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    TestBedViewController *tbvc = [[TestBedViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:tbvc];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    return YES;
}
@end
int main(int argc, char *argv[]) {
    @autoreleasepool {
        int retVal = UIApplicationMain(argc, argv, nil, @"TestBedAppDelegate");
        return retVal;
    }
}