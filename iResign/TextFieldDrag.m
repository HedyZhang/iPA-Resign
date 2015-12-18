//
//  TextFieldDrag.m
//  iResign
//
//  Created by yanshu on 15/12/16.
//  Copyright © 2015年 焱厽. All rights reserved.
//

#import "TextFieldDrag.h"

@implementation TextFieldDrag

- (void)awakeFromNib
{
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
 
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ( [pboard.types containsObject:NSURLPboardType] )
    {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        
        if ( files.count <= 0 )
        {
            return NO;
        }
        self.stringValue = [files objectAtIndex:0];
    }
    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ( !self.enabled )
    {
        return NSDragOperationNone;
    }
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];;
    
    if ( [pboard.types containsObject:NSFilenamesPboardType] )
    {
        if ( sourceDragMask & NSDragOperationCopy)
        {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}


@end
