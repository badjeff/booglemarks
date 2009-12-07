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

#import "BMModels.h"

@implementation Tag

@synthesize name;
@synthesize items;
@synthesize tags;

- (id) init
{
	if (self = [super init])
	{
		self.items = [[NSMutableArray alloc] init];
		self.tags = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSComparisonResult) nameComparator: (Tag *) tag
{
	return [self.name caseInsensitiveCompare: tag.name];
}

@end


@implementation BookmarkItem

@synthesize title;
@synthesize url;
@synthesize updatedOn;
//@synthesize tags;

- (id) init
{
	if (self = [super init])
	{
		//self.tags = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSString *) faviconUrl
{
	if (url)
	{
		NSURL* u = [NSURL URLWithString: url];
		return [NSString stringWithFormat:@"http://%@:%d/favicon.ico", 
				[u host], 
				([u port]) ? [[u port] intValue] : 80];
	}
	return nil;
}

- (NSComparisonResult) titleComparator: (BookmarkItem *) bookmark
{
	return [self.title caseInsensitiveCompare: bookmark.title];
}

- (NSComparisonResult) recentUpdatedComparator: (BookmarkItem *) bookmark
{
	return [bookmark.updatedOn compare: self.updatedOn];
}

- (BOOL) isEqual: (id) object
{
	return [self.url isEqualToString: ((BookmarkItem *) object).url];
}

- (NSUInteger)hash
{
	return [self.url hash];
}

- (void) _retriveFaviconForMenuItem: (NSMenuItem *) menuItem
{
	if (url) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		@try {
			NSImage* favicon = [[NSImage alloc] initWithContentsOfURL: [NSURL URLWithString: [self faviconUrl]]];
			if (favicon)
			{
				if (! [menuItem isKindOfClass: [NSMenuItem class]])
					@throw [NSException exceptionWithName: @"MenuItem is dellocated" 
												   reason: @"Reload Favicon.ico spent too much of time." 
												 userInfo: nil];
				
				if (! [[menuItem title] compare: title] == NSOrderedSame)
					@throw [NSException exceptionWithName: @"MenuItem is dellocated" 
												   reason: @"Reload Favicon.ico spent too much of time." 
												 userInfo: nil];

				NSSize iconSize;
				iconSize.width = iconSize.height = 16;
				[favicon setSize: iconSize];
				[menuItem setImage: favicon];
			}
		}
		@catch (NSException* e)
		{
			NSLog(@"%@", e);
		}
		@finally
		{
			[pool drain];
		}
	}
}

- (void) retriveFaviconForMenuItem: (NSMenuItem *) menuItem
{
//	NSThread* thread = [[NSThread alloc] init];
//	[self performSelector: @selector(_reloadFaviconForMenuItem:) 
//				 onThread: thread 
//			   withObject: menuItem 
//			waitUntilDone: NO];
	[self performSelectorInBackground: @selector(_retriveFaviconForMenuItem:) withObject: menuItem];
}

@end
