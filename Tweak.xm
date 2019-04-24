#import <dlfcn.h>
#import <objc/runtime.h>
#import <notify.h>
#import <substrate.h>

#define NSLog(...)

@interface Urn : NSObject
- (NSString*)identifier;
@end

@interface TrackEngagement : NSObject
- (Urn*)urn;
@end

@interface TrackPlayerViewController : UIViewController
- (TrackEngagement*)trackEngagement;
@end

@interface ActionSheetTableViewCell : UITableViewCell
@end

@interface ActionSheetViewController : UITableViewController
@end

@interface SCloudInfoViewController : UITableViewController
@property(nonatomic,retain) NSString *identifier;
@property(nonatomic,retain) NSString *titleSong;
@property(nonatomic,retain) NSString *textDescription;
+ (SCloudInfoViewController*)shared;
@end

@implementation SCloudInfoViewController
@synthesize identifier, textDescription, titleSong;
+ (SCloudInfoViewController*)shared
{
	static SCloudInfoViewController* shred;
	if(!shred) {
		shred = [(SCloudInfoViewController*)[[self class] alloc] initWithStyle:UITableViewStylePlain];
	}
	return shred;
}
- (void)Refresh
{
	self.textDescription = @"Loading...";
	self.titleSong = @"Loading...";
	self.title = @"Description";
	[self.tableView reloadData];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api-mobile.soundcloud.com/tracks/soundcloud:tracks:%@?client_id=Fiy8xlRI0xJNNGDLbPmGUjTpPRESPx8C", self.identifier]];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		if(error) {
			self.textDescription = [error localizedDescription];
		} else {
			NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
			self.textDescription = dictionary[@"description"];
			self.titleSong = dictionary[@"title"];
		}
		dispatch_async(dispatch_get_main_queue(), ^(void){
			[self.tableView reloadData];
		});
	}];
}
- (void)closePopUp
{
	[self dismissModalViewControllerAnimated:YES];
}
- (void)refreshView:(UIRefreshControl *)refresh
{
	[self Refresh];
	[refresh endRefreshing];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	UIBarButtonItem* kBTClose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closePopUp)];
	self.navigationItem.leftBarButtonItems = @[kBTClose];
	UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
	[refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
	[self.tableView addSubview:refreshControl];
	self.tableView.estimatedRowHeight = 44.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
}
- (void)viewWillAppear:(BOOL)arg1
{
	[super viewWillAppear:arg1];
	[self Refresh];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static __strong NSString *simpleTableIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
	if(cell== nil) {
	    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];			
    }
	
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.textLabel.text =  nil;
	cell.detailTextLabel.text = nil;
	cell.textLabel.textColor = [UIColor darkTextColor];
	cell.detailTextLabel.textColor = [UIColor grayColor];
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.imageView.image = nil;
	cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
	cell.textLabel.numberOfLines = 0;
	cell.detailTextLabel.numberOfLines = 0;
	
	if(indexPath.section == 0) {
		cell.textLabel.text = self.titleSong;
	} else {
		cell.textLabel.text = self.textDescription;
	}
	
    return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section == 0) {
		return @"Title";
	}
	return @"Description";
}
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:))
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:cell.textLabel.text];
    }
}
@end




%hook TrackActionSheetElementCreator
- (id)shareActionSheetElementForPresentable:(TrackEngagement*)arg1
{
	@try {
		[SCloudInfoViewController shared].identifier = [[arg1 urn] identifier];
	} @catch(NSException* ex) {
	}
	NSLog(@"shareActionSheetElementForPresentable: %@", arg1);
	id ret = %orig;
	
	return ret;
}
%end
%hook ActionSheetViewController
- (id)actionSheetElementAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0 && (indexPath.row+1) == [self tableView:self.tableView numberOfRowsInSection:indexPath.section]) {
		return %orig([NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section]);
	}
	return %orig;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0 && (indexPath.row+1) == [self tableView:tableView numberOfRowsInSection:indexPath.section]) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			UIViewController *vc = nil;
			id <UIApplicationDelegate> appDele = [UIApplication sharedApplication].delegate;
			if([appDele respondsToSelector:@selector(rootViewController)]) {
				vc = [(UIWindow*)appDele rootViewController];
			}
			if(!vc) {
				vc = [appDele window].rootViewController;
			}
			if([vc respondsToSelector:@selector(presentedViewController)]) {
				if(UIViewController* presentVC = vc.presentedViewController) {
					vc = presentVC;
				}
			}
			UINavigationController* nacV = [[UINavigationController alloc] initWithRootViewController:[SCloudInfoViewController shared]];
			nacV.navigationBar.barTintColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
			[vc presentViewController:nacV animated:YES completion:nil];
		});
	}
	%orig;
}
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0 && (indexPath.row+1) == [self tableView:tableView numberOfRowsInSection:indexPath.section]) {
		UITableViewCell* cell = [[%c(ActionSheetTableViewCell) alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
		cell.textLabel.text = @"  ☆  Description";
		cell.textLabel.textColor = [UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0];
		MSHookIvar<UIView *>(cell, "_actionSheetElement") = [[%c(ActionSheetElement) alloc] init];
		return cell;
	}
	return %orig;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section==0) {
		return %orig + 1;
	}
	return %orig;
}
%end
