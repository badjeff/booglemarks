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

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import <WebKit/WebKit.h>
#import "BMAppController.h"
#import "BMModels.h"


#import <objc/objc-class.h>
void Swizzle(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
		method_exchangeImplementations(origMethod, newMethod);
}


@implementation NSArray (Booglemarks)

//#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
//- (id) selectFirst: (BOOL(^)(id)) block;
//{
//    for (id obj in self) if (block(obj)) return obj;
//    return nil;
//}
//#else
- (id) selectFirstCpationed: (NSString*) caption
{
    for (id obj in self) 
	{
		NSMenuItem* menuItem = (NSMenuItem *) obj;
		if ([[menuItem title] compare: caption] == NSOrderedSame)
			return menuItem;
	}
	return nil;
}
//#endif

@end


@implementation NSMutableArray (Booglemarks)

- (void) addReduancyObjectsFromArray: (NSArray *) array
{
	NSMutableSet* uniSet = [[NSMutableSet alloc] initWithArray: self];
	[uniSet addObjectsFromArray: array];
	[self removeAllObjects];
	[self addObjectsFromArray: [uniSet allObjects]];
	[uniSet release];
}

@end


@implementation BMAppController

#pragma mark Loader

+ (void) load
{
	[BMAppController sharedInstance];
}

+ (BMAppController *) sharedInstance
{
	static BMAppController* plugin = nil;
	
	if (plugin == nil)
		plugin = [[BMAppController alloc] init];
	
	return plugin;
}

#pragma mark Override

- (id) init
{
    //NSLog(@"BMAppController %p - init", self);
	
    self = [super init];
    if (! self)
        return nil;
	
	reloading = NO;

	//
	// init images
	//
	NSSize iconSize;
	iconSize.width = iconSize.height = 16;

	folderIcon = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
	[folderIcon setSize: iconSize];
	[folderIcon retain];

	bookmarkIcon = [NSImage imageNamed:@"BookmarkPreferences.tiff"];
	[bookmarkIcon setSize: iconSize];
	[bookmarkIcon retain];

	historyIcon = [NSImage imageNamed:@"History.tif"];
	[historyIcon setSize: iconSize];
	[historyIcon retain];
	
//	NSBundle* myBundle = [NSBundle bundleForClass:[self class]];
//	NSImage* startImg = [[NSImage alloc] initWithContentsOfFile:[myBundle pathForImageResource:@"star.png"]];

	tags = [[NSMutableArray alloc] init];

	//
	// init menus
	//
	topMenu = [[NSMenu alloc] init];
	[topMenu setTitle: BMLocalizedString(@"Booglemarks")];
	//- (void)menuWillOpen:(NSMenu *)menu;
	
	menuItemShowBookmarks =  [[NSMenuItem alloc] init];
	[menuItemShowBookmarks setTitle: BMLocalizedString(@"Show Bookmarks")];
	[menuItemShowBookmarks setAction: @selector(didClickShowBookmarks:) ];
	[menuItemShowBookmarks setKeyEquivalent: @"b"];
	[menuItemShowBookmarks setKeyEquivalentModifierMask: (NSControlKeyMask | NSCommandKeyMask)];
	[menuItemShowBookmarks setImage: bookmarkIcon];
	[menuItemShowBookmarks setTarget: self];
	[menuItemShowBookmarks retain];
	
	menuItemAddBookmark =  [[NSMenuItem alloc] init];
	[menuItemAddBookmark setTitle: BMLocalizedString(@"Add Bookmark")];
	[menuItemAddBookmark setAction: @selector(didClickAddBookmark:) ];
	[menuItemAddBookmark setKeyEquivalent: @"d"];
	[menuItemAddBookmark setKeyEquivalentModifierMask: (NSControlKeyMask | NSCommandKeyMask)];
	[menuItemAddBookmark setImage: bookmarkIcon];
	[menuItemAddBookmark setTarget: self];
	[menuItemAddBookmark retain];

	menuItemReloadBookmarks =  [[NSMenuItem alloc] init];
	[menuItemReloadBookmarks setTitle: BMLocalizedString(@"Reload Bookmarks")];
	[menuItemReloadBookmarks setAction: @selector(didClickReloadAll:) ];
	//[menuItemReloadBookmarks setKeyEquivalent: @"r"];
	//[menuItemReloadBookmarks setKeyEquivalentModifierMask: NSControlKeyMask];
	[menuItemReloadBookmarks setTarget: self];
	[menuItemReloadBookmarks retain];
	
	menuItemReloading =  [[NSMenuItem alloc] init];
	[menuItemReloading setTitle: BMLocalizedString(@"Reloading")];
	[menuItemReloading retain];
	
	menuItemSignIn =  [[NSMenuItem alloc] init];
	[menuItemSignIn setTitle: BMLocalizedString(@"Sign In")];
	[menuItemSignIn setAction: @selector(didClickShowSignIn:) ];
	[menuItemSignIn setImage: bookmarkIcon];
	[menuItemSignIn setTarget: self];
	[menuItemSignIn retain];
	
	menuItemOops =  [[NSMenuItem alloc] init];
	[menuItemOops setTitle: @""];
	[menuItemOops retain];
	
	//
	// insert menu on the right of original Bookmarks item
	//
	NSMenuItem* topMenuItem = [[NSMenuItem alloc] init];
	[topMenuItem setSubmenu: topMenu];
	[topMenu release];
	NSInteger insertPos = [[NSApp mainMenu] numberOfItems] - 1;
	{
//		NSBundle* appBundle = [NSBundle bundleForClass: [NSApp class]];
//		NSString* orgBookmarksCaption = [appBundle localizedStringForKey:@"Bookmarks" value:@"" table:(nil)];
		//NSLog(@"%@", bookmarksCaption);
		
		NSArray* appMenus = [[NSApp mainMenu] itemArray];
//		#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
//		NSMenuItem* orgBookmarksItem = [appMenus selectFirst: ^(id obj) {
//			NSMenuItem* menuItem = (NSMenuItem *) obj;
//			return (BOOL) ([[menuItem title] compare: orgBookmarksCaption] == NSOrderedSame);
//		}];
//		#else
//		NSMenuItem* orgBookmarksItem = [appMenus selectFirstCpationed: orgBookmarksCaption];
		NSMenuItem* orgBookmarksItem = [appMenus objectAtIndex:5];
//		#endif
		if (orgBookmarksItem)
			insertPos = [appMenus indexOfObject:orgBookmarksItem];
	}	
	[[NSApp mainMenu] insertItem: topMenuItem atIndex: insertPos + 1];
	[topMenuItem release];

	//
	// insert about menu
	//
	NSMenuItem* aboutMenuItem = [[NSMenuItem alloc] init];
	[aboutMenuItem setTitle: BMLocalizedString(@"About Booglemarks")];
	[aboutMenuItem setAction: @selector(showAboutBox:)];
	[aboutMenuItem setKeyEquivalent: @""];
	[aboutMenuItem setTarget: self];
	[[[[NSApp mainMenu] itemAtIndex:0] submenu] insertItem: aboutMenuItem atIndex: 1];
	[aboutMenuItem release];
	
	//
	// register self as observer
	//
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver: self
               selector: @selector(didSafariFinishLoadForFrame:)
                   name: WebViewProgressFinishedNotification
                 object: nil];

	[self performSelector:@selector(doReload)];
    return self;
}

- (void) dealloc
{
    //NSLog(@"BMAppController - dealloc");
	
	//
	// unregister self from observer list
	//
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center removeObserver: self];
	
	[menuItemShowBookmarks release];
	[menuItemAddBookmark release];
	[menuItemReloadBookmarks release];
	[menuItemReloading release];
	[menuItemSignIn release];
	[menuItemOops release];
	
	[folderIcon release];
	[bookmarkIcon release];
	[historyIcon release];
	
	[tags release];
    [super dealloc];
}

#pragma mark App Function

- (void) inspectClassMethods: (Class) clazz
{
	unsigned int outCount, i;
	Method *methods = class_copyMethodList(clazz, &outCount);
	for(i = 0; i < outCount; i++) {
		Method method = methods[i];
		NSLog(@"- %@", NSStringFromSelector(method_getName(method)) );
	}
	free(methods);
}

- (void) inspectClassProperties: (Class) clazz
{
	unsigned int outCount, i;
	objc_property_t *properties = class_copyPropertyList(clazz, &outCount);
	for(i = 0; i < outCount; i++) {
		objc_property_t property = properties[i];
		fprintf(stdout, "%s %s\n", property_getName(property), property_getAttributes(property));
	}
	free(properties);
}

- (void) inspect: (NSView *) theView
{
	//NSLog(@"%@", theView);
	for (int i=0; i<[theView.subviews count]; i++)
		[self inspect: [theView.subviews objectAtIndex: i]];
}

- (id) searchSubClassNamed: (NSString *) classDesc in: (NSView *) theView
{
	if ([[[theView class] description] compare:classDesc] == NSOrderedSame)
		return theView;
	for (NSUInteger i = 0; i < [theView.subviews count]; i++)
	{
		id found = [self searchSubClassNamed: classDesc in: [theView.subviews objectAtIndex:i]];
		if (found)
			return found;
	}
	return nil;
}

- (id) searchSubClassOf: (Class) superclass in: (NSView *) theView
{
	if ([[theView class] isSubclassOfClass: [superclass class]])
		return theView;
	for (NSUInteger i = 0; i < [theView.subviews count]; i++)
	{
		//NSLog(@"%@", [[theView.subviews objectAtIndex: i] class]);
		id found = [self searchSubClassOf: superclass in: [theView.subviews objectAtIndex: i]];
		if (found)
			return found;
	}
	return nil;
}

- (id) searchOrderedTabBarView: (id) sender animated: (BOOL) animated
{
	NSWindow* window = nil;
	NSView* tabBarView = nil;
	for (window in [NSApp orderedWindows])
	{
		tabBarView = (id) [self searchSubClassNamed: @"TabBarView" in: [window contentView]];
		if (tabBarView)
			break;
	}
	if (tabBarView && animated)
		[window makeKeyAndOrderFront:self];
	return tabBarView;
}

- (id) searchOrderedWebView: (id) sender animated: (BOOL) animated
{
	NSWindow* window = nil;
	WebView* webView = nil;
	for (window in [NSApp orderedWindows])
	{
		NSTabView* tabview = [self searchSubClassNamed:@"NSTabView" in: [window contentView]];
		if (tabview)
			webView = (id)[tabview selectedTabViewItem];
		if (!webView)
			webView = (WebView *) [self searchSubClassOf: [WebView class] in: [window contentView]];
		if (webView)
			break;
	}
	if (webView && animated)
		[window makeKeyAndOrderFront:self];
	return webView;
}

- (void) openUrl: (NSString *) url newTab: (BOOL) newTab
{
	if (newTab)
	{
		id tabBarView = [self searchOrderedTabBarView: self animated: YES];
		if (tabBarView)
		{
			if ([tabBarView respondsToSelector: @selector(_createTab:)])
				[tabBarView performSelector: @selector(_createTab:) withObject: self];
		}
	}
	id webView = [self searchOrderedWebView: self animated: YES];
	if (webView)
	{
		SEL selectorToOpenUrl = nil;
		if ([webView respondsToSelector: @selector(setURLString:)])
			selectorToOpenUrl = @selector(setURLString:);
		if ([webView respondsToSelector: @selector(setMainFrameURL:)])
			selectorToOpenUrl = @selector(setMainFrameURL:);
		if (selectorToOpenUrl)
			[webView performSelector:selectorToOpenUrl withObject: url];
	}
	else
		[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: url]];
}

- (void) openUrl: (NSString *) url
{
	[self openUrl: url newTab: NO];
}

- (NSDictionary *) pageDictionary
{
	NSMutableDictionary* result = [[[NSMutableDictionary alloc] initWithCapacity: 2] autorelease];
	WebView* webView = [self searchOrderedWebView: self animated: YES];
	if (webView)
	{
		if ([webView mainFrameURL])
		{
			[result setObject: [webView mainFrameURL] forKey:@"url"];
			[result setObject: [webView mainFrameURL] forKey:@"title"];
		}
		if ([webView mainFrame])
		{
			DOMDocument* domDoc = [[webView mainFrame] DOMDocument];
			if (domDoc)
			{
				DOMNodeList* titles = [domDoc getElementsByTagNameNS: @"http://www.w3.org/1999/xhtml"
														   localName: @"title"];
				if ([titles length])
					[result setObject: [[titles item:0] textContent] forKey:@"title"];
			}
		}
	}
	return result;
}

- (void) addBookmarkWithLabels: (NSString *) labels
{
	NSDictionary* pageDict = [self pageDictionary];

	NSString* label = (labels)?labels:@"";
	NSString* url = [pageDict objectForKey: @"url"];
	NSString* title = [pageDict objectForKey: @"title"];
	url = (url)?url:@"";
	title = (title)?title:@"";
	
	NSString* escapedAddr = BMLocalizedString(@"URL_ADD");
	NSString* escapedBkmk = [url stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	NSString* escapedTitle = [title stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	NSString* escapedLable = [label stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	
	[self openUrl: [NSString stringWithFormat: escapedAddr, escapedLable, escapedBkmk, escapedTitle] newTab: YES];
}

#pragma mark NSXMLParserDelegate

- (void) parser: (NSXMLParser *) parser
didStartElement: (NSString *) elementName
   namespaceURI: (NSString *) namespaceURI
  qualifiedName: (NSString *) qName
	 attributes: (NSDictionary *) attributeDict
{
    if ([elementName isEqual:@"h3"]) {
        tagInProgress = [[Tag alloc] init];

		keyInProgress = [elementName copy];
        textInProgress = [[NSMutableString alloc] init];
	}

    if ([elementName isEqual:@"a"]) {
        bookmarkInProgress = [[BookmarkItem alloc] init];
		bookmarkInProgress.url = [attributeDict objectForKey:@"href"];
		bookmarkInProgress.updatedOn = [attributeDict objectForKey:@"add_date"];

		keyInProgress = [elementName copy];
        textInProgress = [[NSMutableString alloc] init];
	}
}

- (void) parser: (NSXMLParser *) parser
  didEndElement: (NSString *) elementName
   namespaceURI: (NSString *) namespaceURI
  qualifiedName: (NSString *) qName
{
    if ([elementName isEqual:@"h3"])
	{
		tagInProgress.name = textInProgress;
		
        [tags addObject: tagInProgress];
		
		[textInProgress release];
        textInProgress = nil;
        [keyInProgress release];
        keyInProgress = nil;
	}

    if ([elementName isEqual:@"a"])
	{
		bookmarkInProgress.title = textInProgress;
		
		[tagInProgress.items addObject:bookmarkInProgress];

        [bookmarkInProgress release];
        bookmarkInProgress = nil;

		[textInProgress release];
        textInProgress = nil;
        [keyInProgress release];
        keyInProgress = nil;
	}
}

- (void) parser: (NSXMLParser *) parser 
foundCharacters:(NSString *)string
{
	[textInProgress appendString: string];
}

- (NSData *) parser: (NSXMLParser *) parser resolveExternalEntityName: (NSString *) name 
		   systemID:(NSString *) systemID
{
	NSString* entityName = [NSString stringWithFormat:@"&%@;", name];
	NSAttributedString *entityString = [[[NSAttributedString alloc]  
										 initWithHTML:[entityName  
										dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL]  
										autorelease];
	//NSLog(@"resolved entity name: %@", [entityString string]);
	return [[entityString string] dataUsingEncoding:NSUTF8StringEncoding];
}

- (void) parser: (NSXMLParser *) parser parseErrorOccurred: (NSError *) parseError
{
	NSLog(@"%@", parseError);
}

- (void) parser: (NSXMLParser *) parser validationErrorOccurred: (NSError *) validationError
{
	NSLog(@"%@", validationError);
}

- (void) parserDidEndDocument: (NSXMLParser *) parser
{
	NSError* error = [parser parserError];//NSXMLParserErrorDomain
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center postNotification:[NSNotification notificationWithName: didReloadNotificationName 
														   object: error]];
}

#pragma mark Method

- (NSMenuItem *) menuItemAddBookmarkHereWithTag: (Tag *) tag
{
	NSMenuItem* addBookmarkHereMenuItem =  [[[NSMenuItem alloc] init] autorelease];
	[addBookmarkHereMenuItem setRepresentedObject: tag];
	[addBookmarkHereMenuItem setTitle: BMLocalizedString(@"Add Bookmark Here")];
	[addBookmarkHereMenuItem setAction: @selector(didClickAddBookmarkHere:)];
	[addBookmarkHereMenuItem setKeyEquivalent:@""];
	[addBookmarkHereMenuItem setTarget: self];
	return addBookmarkHereMenuItem;
}

- (NSMenuItem *) menuItemOpenInTabsWithTag: (Tag *) tag
{
	NSMenuItem* openInTabsMenuItem =  [[[NSMenuItem alloc] init] autorelease];
	[openInTabsMenuItem setRepresentedObject: tag];
	[openInTabsMenuItem setTitle: BMLocalizedString(@"Open in Tabs")];
	[openInTabsMenuItem setAction: @selector(didClickOpenInTabs:)];
	[openInTabsMenuItem setKeyEquivalent:@""];
	[openInTabsMenuItem setTarget: self];
	return openInTabsMenuItem;
}

- (NSMenuItem *) menuItemWithBookmark: (BookmarkItem *) bookmark
{
	NSMenuItem* bookmarkMenuItem =  [[[NSMenuItem alloc] init] autorelease];
	[bookmarkMenuItem setRepresentedObject: bookmark];
	[bookmarkMenuItem setTitle: [bookmark title]];
	[bookmarkMenuItem setImage: bookmarkIcon];
	[bookmarkMenuItem setAction: @selector(didClickBookmarkItem:)];
	[bookmarkMenuItem setKeyEquivalent:@""];
	[bookmarkMenuItem setTarget: self];
	return bookmarkMenuItem;
}

- (Tag*) searchOrCreateTagNamed: (NSArray*) nameChain withTags: (NSMutableArray*) _tags
{
	for (int t=0; t<[_tags count]; t++)
	{
		Tag* tag = [_tags objectAtIndex: t];
		if ([[tag name] compare: [nameChain objectAtIndex:0]] == NSOrderedSame)
		{
			if ([nameChain count] == 0)
				return tag;
			else
			{
				NSMutableArray* tagNames = [NSMutableArray arrayWithArray: nameChain];
				[tagNames removeObjectAtIndex: 0];
				return [self searchOrCreateTagNamed: tagNames withTags: tag.tags];
			}
		}
	}
	
	Tag* newTag = [[[Tag alloc] init] autorelease];
	newTag.name = [nameChain objectAtIndex:0];
	[_tags addObject: newTag];
	
	NSMutableArray* tagNames = [NSMutableArray arrayWithArray: nameChain];
	[tagNames removeObjectAtIndex: 0];
	
	if ([tagNames count] > 0)
		return [self searchOrCreateTagNamed: tagNames withTags: newTag.tags];
	else
		return newTag;
}

- (void) willAppendMenuItemWithTags: (NSMutableArray*) _tags
{
	[_tags sortUsingSelector: @selector(nameComparator:)];
	
	NSMutableArray* tagsToBeRemoved = [[NSMutableArray alloc] init];
	for (int t=0; t<[_tags count]; t++)
	{
		Tag* tag = [_tags objectAtIndex: t];
		NSArray* nameChain = [[tag name] componentsSeparatedByString: tagSeperator];
		if ([nameChain count] > 1)
		{
			Tag* t = [self searchOrCreateTagNamed: nameChain withTags: _tags];
			t.items = tag.items;
			[tagsToBeRemoved addObject: tag];
		}
	}
	[_tags removeObjectsInArray: tagsToBeRemoved];
	[tagsToBeRemoved release];
}

- (void) sortMostRecentWithTags: (NSMutableArray*) _tags recentUpdated: (NSMutableArray*) recentUpdated
{
	NSInteger recentBound = 10;
	for (int t=0; t<[_tags count]; t++)
	{
		Tag* tag = [_tags objectAtIndex: t];
		
		[self sortMostRecentWithTags: tag.tags recentUpdated: recentUpdated];
		
		[recentUpdated addReduancyObjectsFromArray: tag.items];
		[recentUpdated sortUsingSelector: @selector(recentUpdatedComparator:)];
		if ([recentUpdated count] > recentBound)
			[recentUpdated removeObjectsInRange: NSMakeRange(recentBound, [recentUpdated count]-recentBound)];
	}
}

- (void) appendMenuItemMostRecentWithTags: (NSMutableArray*) _tags toMenu: (NSMenu*) menu
{
	NSMutableArray* recentUpdated = [[NSMutableArray alloc] init];
	
	[self sortMostRecentWithTags: _tags recentUpdated: recentUpdated];
	
	if ([recentUpdated count] > 0)
	{
		NSMenuItem* tagMenuItem = [[[NSMenuItem alloc] init] autorelease];
		[tagMenuItem setRepresentedObject: nil];
		[tagMenuItem setTitle: BMLocalizedString(@"Most Recent")];
		[tagMenuItem setImage: historyIcon];
		[menu insertItem: tagMenuItem atIndex: 5];
		
		NSMenu* submenu = [[NSMenu alloc] init];
		for (BookmarkItem* bookmark in recentUpdated)
			[submenu addItem: [self menuItemWithBookmark: bookmark]];
		[tagMenuItem setSubmenu: submenu];
		[submenu release];
	}
	[recentUpdated release];
}

- (NSMenuItem *) appendMenuItemWithTag: (Tag *) tag toMenu: (NSMenu *) submenu
{
	NSMenuItem* tagMenuItem = [[[NSMenuItem alloc] init] autorelease];
	[tagMenuItem setRepresentedObject: tag];
	[tagMenuItem setTitle: tag.name];
	[tagMenuItem setImage: folderIcon];
	[submenu addItem: tagMenuItem];
	return tagMenuItem;
}

- (void) appendMenuItemWithTags: (NSMutableArray*) _tags toMenu: (NSMenu*) menu
{
	[_tags sortUsingSelector: @selector(nameComparator:)];
	
	Tag* unlabeledTag = nil;
	for (int t=0; t<[_tags count]; t++)
	{
		Tag* tag = [_tags objectAtIndex: t];
		[tag.items sortUsingSelector: @selector(titleComparator:)];
		
		if ([[tag name] compare: @"Unlabeled"] == NSOrderedSame)
		{
			unlabeledTag = tag;
		}
		else
		{
			NSMenuItem* tagMenuItem = [self appendMenuItemWithTag: tag toMenu: menu];
			NSMenu* submenu = [[NSMenu alloc] init];

			if ([tag.tags count] > 0)
				[self appendMenuItemWithTags: tag.tags toMenu: submenu];
			
			for (int b=0; b<[tag.items count]; b++)
			{
				BookmarkItem* bookmark = [tag.items objectAtIndex: b];
				[submenu addItem: [self menuItemWithBookmark: bookmark]];
			}
			[tagMenuItem setSubmenu: submenu];
			[submenu release];
			
			[submenu addItem: [NSMenuItem separatorItem]];
			[submenu addItem: [self menuItemAddBookmarkHereWithTag: tag]];
			[submenu addItem: [self menuItemOpenInTabsWithTag: tag]];
		}
	}
	if (unlabeledTag)
	{
		for (int b=0; b<[unlabeledTag.items count]; b++)
		{
			BookmarkItem* bookmark = [unlabeledTag.items objectAtIndex: b];
			[menu addItem: [self menuItemWithBookmark: bookmark]];
		}
	}
}

- (void) addStaticMenus
{
	[topMenu addItem: menuItemShowBookmarks];
	[topMenu addItem: menuItemAddBookmark];
}

- (void) didReload: (NSNotification *) n
{
	//
	// unregister observer
	//
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center removeObserver: self 
					  name: didReloadNotificationName 
					object: nil];
	
	//
	// reconstruct menu items
	//
	if ([topMenu respondsToSelector:@selector(removeAllItems)])
		[topMenu removeAllItems];
	else
		while ([[topMenu itemArray] count])
			[topMenu removeItemAtIndex:0];

	[self addStaticMenus];
	[topMenu addItem: [NSMenuItem separatorItem]];
	[topMenu addItem: menuItemReloadBookmarks];

	NSError* error = [n object];
	//NSLog(@"didReload: %@", error);
	if (! error || [error code] == 0)
	{
		[topMenu addItem:[NSMenuItem separatorItem]];

		[self willAppendMenuItemWithTags: tags];

		[self appendMenuItemMostRecentWithTags: tags toMenu: topMenu];
		[self appendMenuItemWithTags: tags toMenu: topMenu];
	}
	else
	{
		[topMenu addItem:[NSMenuItem separatorItem]];
		
		if ([[error domain] compare: NSURLErrorDomain] == NSOrderedSame)
		{
			[menuItemOops setTitle: [error localizedDescription]];
			[topMenu addItem: menuItemOops];
		}
		else if ([[error domain] compare: BMAppControllerErrorDomain] == NSOrderedSame)
		{
			[menuItemOops setTitle: [error localizedDescription]];
			[topMenu addItem: menuItemOops];
			if ([error code] == 1)
				[topMenu addItem: menuItemSignIn];
		}
	}
	
	reloading = NO;
}

- (void) webView: (WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	//
	// may redirected if not logged yet
	//
	if ([[sender mainFrameURL] compare: BMLocalizedString(@"URL_EXPORT")] != NSOrderedSame)
	{
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject: BMLocalizedString(@"Not Logged Yet") 
															 forKey: NSLocalizedDescriptionKey];
		NSError* error = [NSError errorWithDomain: BMAppControllerErrorDomain code:1 userInfo: userInfo];
		NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
		[center postNotification:[NSNotification notificationWithName: didReloadNotificationName 
															   object: error]];
		return;
	}
	
	//
	// chop unclosed tags
	//
	DOMDocument* domDoc = [frame DOMDocument];
	NSString* innerHTML = @"";
	if ([domDoc respondsToSelector:@selector(body)])
		innerHTML = [[domDoc body] innerHTML];
	else if ([domDoc respondsToSelector:@selector(documentElement)])
		innerHTML = [[domDoc documentElement] innerHTML];
	
	NSArray* messTags = [NSArray arrayWithObjects:@"<dl>", @"</dl>", @"<dt>", @"</dt>", @"<p>", @"</p>", nil];
	for (NSString* tag in messTags)
		innerHTML = [innerHTML stringByReplacingOccurrencesOfString: tag withString: @""];

	//
	// encapsulate into DTD XHTML 1.1
	//
	NSMutableString* html = [[[NSMutableString alloc] init] autorelease];
	[html appendString: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
	[html appendString: @"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"xhtml11.dtd\">"];
	[html appendString: @"<html xmlns=\"http://www.w3.org/1999/xhtml\">"];
	[html appendString: @"<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\"/>"];
	[html appendString: @"\%@"];
	[html appendString: @"</html>"];
	html = [NSString stringWithFormat:html, innerHTML];
	//NSLog(@"%@", html);

	//
	// start parsing
	//
	NSData* data = [html dataUsingEncoding: NSUTF8StringEncoding];
	NSXMLParser* parser = [[NSXMLParser alloc] initWithData: data];
	[parser setDelegate: self];
	[parser setShouldResolveExternalEntities: YES];
	[parser parse];
	[parser release];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center postNotification:[NSNotification notificationWithName: didReloadNotificationName 
														   object: error]];
}

- (void) webView: (WebView *) sender didFailLoadWithError: (NSError *) error forFrame: (WebFrame *) frame
{
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center postNotification:[NSNotification notificationWithName: didReloadNotificationName 
														   object: error]];
}

- (void) doReload
{
	if (reloading)
		return;
	reloading = YES;
	
	[tags removeAllObjects];

	//
	// register observer
	//
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver: self
               selector: @selector(didReload:)
                   name: didReloadNotificationName
                 object: nil];

	//
	// display *Reloading...* on top menu
	//
	if ([topMenu respondsToSelector:@selector(removeAllItems)])
		[topMenu removeAllItems];
	else
		while ([[topMenu itemArray] count])
			[topMenu removeItemAtIndex:0];

	[self addStaticMenus];
	[topMenu addItem: [NSMenuItem separatorItem]];
	[topMenu addItem: menuItemReloading];
	
	//
	// try to grab exported bookmarks
	//
	WebView* webView = [[WebView alloc] init];
	[webView setFrameLoadDelegate: self];
	[webView setMainFrameURL: BMLocalizedString(@"URL_EXPORT")];
	[webView release];
}

- (void) didSafariFinishLoadForFrame: (NSNotification *) n
{
	WebView* webView = (WebView *) [n object];
	//NSLog(@"didSafariFinishLoadForFrame: %@", [webView mainFrameURL]);
	
	NSString* predFmt = @"SELF MATCHES %@";
	NSArray* predicates = [NSArray arrayWithObjects: 
						   [NSPredicate predicateWithFormat: predFmt, BMLocalizedString(@"URL_LOGGED_MASK_1")],
						   [NSPredicate predicateWithFormat: predFmt, BMLocalizedString(@"URL_LOGGED_MASK_2")],
						   [NSPredicate predicateWithFormat: predFmt, BMLocalizedString(@"URL_LOGOUT_MASK")],
						   nil];
	for (NSPredicate* predicate in predicates)
	{
		if ([predicate evaluateWithObject: [webView mainFrameURL]])
		{
			//NSLog(@"Matched!");
			[self doReload];
			break;
		}
	}
}

#pragma mark Menu Action

- (IBAction) showAboutBox: (id) sender
{
	NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
							 //bookmarkIcon, @"ApplicationIcon",
							 BMLocalizedString(@"CFBundleName"), @"ApplicationName",
							 BMLocalizedString(@"CFBundleVersion"), @"ApplicationVersion",
							 BMLocalizedString(@"CFBundleShortVersionString"), @"Version",
							 [[[NSAttributedString alloc] initWithString: BMLocalizedString(@"CREDIT")] autorelease], 
							 @"Credits",
							 BMLocalizedString(@"NSHumanReadableCopyright"), @"Copyright",
							 nil];
	[NSApp orderFrontStandardAboutPanelWithOptions: options];
}

- (IBAction) didClickReloadAll: (id) sender
{
	[self doReload];
}

- (IBAction) didClickShowBookmarks: (id) sender
{
	[self openUrl: BMLocalizedString(@"URL_HOME") newTab: YES];
}

- (IBAction) didClickShowSignIn: (id) sender
{
	[self openUrl: BMLocalizedString(@"URL_SIGN_IN") newTab: YES];
}

- (IBAction) didClickAddBookmark: (id) sender
{
	[self addBookmarkWithLabels: @""];
}

- (IBAction) didClickAddBookmarkHere: (id) sender
{
	Tag* tag = [(NSMenuItem *)sender representedObject];
	[self addBookmarkWithLabels: [tag name]];
}

- (IBAction) didClickOpenInTabs: (id) sender
{
	Tag* tag = [(NSMenuItem *)sender representedObject];
	for (BookmarkItem* bookmark in tag.items)
		[self openUrl: bookmark.url newTab: YES];
}

- (IBAction) didClickBookmarkItem: (id) sender
{
	BookmarkItem* bookmark = [(NSMenuItem *)sender representedObject];
	[self openUrl: bookmark.url];
//	[bookmark retriveFaviconForMenuItem: sender];
}

@end
