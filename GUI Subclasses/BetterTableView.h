
#import <Cocoa/Cocoa.h>

@interface NSObject (BetterTableViewAdditions)

- (BOOL)tableViewCut: (NSTableView*)tableView;
- (BOOL)tableViewCopy: (NSTableView*)tableView;
- (BOOL)tableViewPaste: (NSTableView*)tableView;
- (void)tableView: (NSTableView*)tableView deleteKeyPressedOnRowIndexes: (NSIndexSet*)rowIndexes;
@end

@interface BetterTableView : NSTableView
{
}
@end
