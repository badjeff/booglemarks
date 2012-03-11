/*
 
 The MIT License
 
 Copyright (c) 2009 Booglemarks Developers
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#define BMLocalizedString(key) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:(nil)]

static NSString * const BMAppControllerErrorDomain = @"BMAppControllerErrorDomain";
static NSString * const didReloadNotificationName = @"Booglemarks::BMAppController -didReload";
static NSString * tagSeperator = @":";


@interface NSArray (Booglemarks)
//#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
//- (id) selectFirst: (BOOL(^)(id)) block;
//#else
- (id) selectFirstCpationed: (NSString*) caption;
//#endif
@end


@interface NSMutableArray (Booglemarks)
- (void) addReduancyObjectsFromArray: (NSArray *) array;
@end


@class Tag;
@class BookmarkItem;


//#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
//@interface BMAppController : NSObject <NSXMLParserDelegate>
//#else
@interface BMAppController : NSObject
//#endif
{
	NSMenu* topMenu;
	NSMenuItem* menuItemShowBookmarks;
	NSMenuItem* menuItemAddBookmark;
	NSMenuItem* menuItemReloadBookmarks;
	NSMenuItem* menuItemReloading;
	NSMenuItem* menuItemSignIn;
	NSMenuItem* menuItemOops;
	
	NSImage* folderIcon;
	NSImage* bookmarkIcon;
	NSImage* historyIcon;
	NSImage* bookmarksIcon;
	NSImage* addBookmarkIcon;
	NSImage* reloadIcon;

	NSMutableArray* tags;
	
	Tag* tagInProgress;
    BookmarkItem* bookmarkInProgress;
	NSString* keyInProgress;
    NSMutableString* textInProgress;
	
	BOOL reloading;
}

+ (BMAppController *) sharedInstance;

@end
