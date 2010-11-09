#import "BetterTableView.h"

@implementation BetterTableView

//- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint {
//    log(LOG_GENERAL, @"canDragRowsWithIndexes");
//    return YES;
//}

- (void)keyDown:(NSEvent *)theEvent {
    NSString* characters;
    int character, characterCount, characterIndex;
    
    characters = [theEvent charactersIgnoringModifiers];
    characterCount = [characters length];
    for (characterIndex = 0; characterIndex < characterCount; characterIndex++)
    {
        character = [characters characterAtIndex:characterIndex];
        if(character == 127) {  // delete
            if( [self delegate] && [[self delegate] respondsToSelector: @selector(tableView:deleteKeyPressedOnRowIndexes:)] ) {
                [[self delegate] tableView: self deleteKeyPressedOnRowIndexes: [self selectedRowIndexes]];
                return;
            }
        }/*
        if(character == NSUpArrowFunctionKey) {
            [self selectRow:[self selectedRow]-1 byExtendingSelection:NO];
            return;
        }
        if(character == NSDownArrowFunctionKey) {
            [self selectRow:[self selectedRow]+1 byExtendingSelection:NO];
            return;
        }*/
    }
    
    [super keyDown:theEvent];
}

- (void)copy: (id)sender { 
    if( ([self selectedRow] != -1) && [self delegate] && [[self delegate] respondsToSelector: @selector(tableViewCopy:)] ) {
        // log(LOG_GENERAL, @"Table view copy!");
        if([[self delegate] tableViewCopy: self])   return;
    }
    NSBeep();
}

- (void)paste: (id)sender { 
    if( [self delegate] && [[self delegate] respondsToSelector: @selector(tableViewPaste:)] ) {
        // log(LOG_GENERAL, @"Table view paste!");
        if([[self delegate] tableViewPaste: self])   return;
    }
    NSBeep();
}

- (void)cut: (id)sender { 
    if( ([self selectedRow] != -1) && [self delegate] && [[self delegate] respondsToSelector: @selector(tableViewCut:)] ) {
        // log(LOG_GENERAL, @"Table view copy!");
        if([[self delegate] tableViewCut: self])   return;
    }
    NSBeep();
}

@end
