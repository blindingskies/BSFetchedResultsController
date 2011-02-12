//
//  BSFetchedResultsController.m
//  BSFetchedResultsControllerExample
//
//  Created by Daniel Thorpe on 15/12/2010.
//  Copyright 2010 Blinding Skies Limited. All rights reserved.
//

#import "BSFetchedResultsController.h"

// String constants
NSString * const kBSFetchedResultsControllerDefaultSectionName = @"Default Section";
NSString * const kBSFetchedResultsControllerCachePath = @"BSFetchedResultsControllerCache";
NSString * const kBSFetchedResultsControllerSectionInfoCacheName = @"SectionInfo.cache";
NSString * const kBSFetchedResultsControllerFetchedObjectsCacheName = @"FetchedObjects.cache";
// SectionInfo Cache archive keys
NSString * const kBSFRCSectionInfoCacheFetchRequestKey = @"kBSFRCSectionInfoCacheFetchRequestKey";
NSString * const kBSFRCSectionInfoCacheFetchRequestEntityKey = @"kBSFRCSectionInfoCacheFetchRequestEntityKey";
NSString * const kBSFRCSectionInfoCacheFetchRequestPredicateKey = @"kBSFRCSectionInfoCacheFetchRequestPredicateKey";
NSString * const kBSFRCSectionInfoCacheFetchRequestSortDescriptorsKey = @"kBSFRCSectionInfoCacheFetchRequestSortDescriptorsKey";
NSString * const kBSFRCSectionInfoCacheSectionNameKeyPathKey = @"kBSFRCSectionInfoCacheSectionNameKeyPathKey";
NSString * const kBSFRCSectionInfoCacheSectionsKey = @"kBSFRCSectionInfoCacheSectionsKey";
NSString * const kBSFRCSectionInfoCachePostFetchPredicateKey = @"kBSFRCSectionInfoCachePostFetchPredicateKey";
NSString * const kBSFRCSectionInfoCachePostFetchFilterKey = @"kBSFRCSectionInfoCachePostFetchFilterKey";
NSString * const kBSFRCSectionInfoCachePostFetchComparatorKey = @"kBSFRCSectionInfoCachePostFetchComparatorKey";
// Individual Section cache archive keys
NSString *const kBSFRCSectionCacheKeyKey = @"kBSFRCSectionCacheKeyKey";
NSString *const kBSFRCSectionCacheNameKey = @"kBSFRCSectionCacheNameKey";
NSString *const kBSFRCSectionCacheIndexTitleKey = @"kBSFRCSectionCacheIndexTitleKey";
NSString *const kBSFRCSectionCacheObjectsKey = @"kBSFRCSectionCacheObjectsKey";
NSString *const kBSFRCSectionCacheFilteredKey = @"kBSFRCSectionCacheFilteredKey";


@class BSFetchedResultsControllerAbstractContainer;
@class BSFetchedResultsControllerSection;
@class BSFetchedResultsControllerSectionInfoCache;


#pragma mark NSArray categories

// Add a category to NSArray to filter using such a filter block
@interface NSArray (NSArray_BSFetchedResultsControllerAdditions)
- (NSArray *)objectsPassingTest:(BOOL (^)(id obj, BOOL *stop))test;
- (NSArray *)arrayByRemovingObjectsFromArray:(NSArray *)otherArray;
@end

// The implementation of the NSArray category method
@implementation NSArray (NSArray_BSFetchedResultsControllerAdditions)

- (NSArray *)objectsPassingTest:(BOOL (^)(id obj, BOOL *stop))test {
	NSParameterAssert(test);
	
	// Create an array to store the result in
	NSMutableArray *output = [NSMutableArray array];
	// Define some variables
	NSUInteger i, len = [self count];
	// Iterate through the array
	BOOL stopFlag = NO;
	for (i=0; i<len; i++) {
		if(stopFlag) break;
		id obj = [self objectAtIndex:i];
		if (test(obj, &stopFlag)) {
			[output addObject:obj];
		}
	}
	return [NSArray arrayWithArray:output];
}

- (NSArray *)arrayByRemovingObjectsFromArray:(NSArray *)otherArray {
	NSMutableArray *result = [NSMutableArray arrayWithArray:self];
	for(id obj in self) {
		if ([otherArray containsObject:obj]) {
			[result removeObject:obj];
		}
	}
	return result;
}

@end



// Add a category to NSSet
@interface NSSet (NSSet_BSFetchedResultsControllerAdditions)
- (NSSet *)setByRemovingObjectsFromSet:(NSSet *)otherSet;
@end

@implementation NSSet (NSSet_BSFetchedResultsControllerAdditions)

- (NSSet *)setByRemovingObjectsFromSet:(NSSet *)otherSet {
	NSMutableSet *result = [NSMutableSet setWithSet:self];
	for (id obj in self) {
		if ([otherSet containsObject:obj]) {
			[result removeObject:obj];
		}
	}
	return result;
}

@end



#pragma mark -
#pragma mark BSFetchedResultsControllerAbstractContainer

@implementation BSFetchedResultsControllerAbstractContainer

@synthesize section;
@synthesize items;

- (id)init {
	self = [super init];
	if (self) {
		// Initialise the array
		self.items = [NSMutableArray array];
	}
	return self;
}

@end




#pragma mark -
#pragma mark BSFetchedResultsControllerSection

@interface BSFetchedResultsControllerSection : NSObject <NSFetchedResultsSectionInfo, NSCoding> {
@private
	BSFetchedResultsController *controller;
	BOOL isDisplayed;
	NSString *key;
	NSString *_name;
	NSString *_indexTitle;
	NSMutableArray *_objects;
	BSFetchedResultsControllerAbstractContainer *_filtered;
}

// Adds an object to the array of objects
- (void)addObject:(id)obj;
- (void)removeObject:(id)obj;
- (void)addFilteredObject:(id)obj;
- (void)removeFilteredObject:(id)obj;

// The controller
@property (nonatomic, readwrite, assign) BSFetchedResultsController *controller;

// A flag which indicates whether or not the section is displayed
@property (nonatomic, readwrite) BOOL isDisplayed;

// The key
@property (nonatomic, retain) NSString *key;

/* Name of the section
 */
@property (nonatomic, readonly) NSString *name;

/* Title of the section (used when displaying the index)
 */
@property (nonatomic, readonly) NSString *indexTitle;

/* Number of objects in section
 */
@property (nonatomic, readonly) NSUInteger numberOfObjects;

/* Returns the array of objects in the section.
 */
@property (nonatomic, readonly) NSArray *objects;

/* Returns the filtered objects container.
 */
@property (nonatomic, readonly) id filtered;

/* Returns the filtered objects container.
 */
@property (nonatomic, readwrite, retain) NSArray *filteredItems;

@end


@implementation BSFetchedResultsControllerSection

@synthesize controller;
@synthesize isDisplayed;
@synthesize key;
@synthesize name=_name;
@synthesize indexTitle=_indexTitle;
@synthesize objects=_objects;
@synthesize filtered=_filtered;
@dynamic numberOfObjects;
@dynamic filteredItems;

- (id)init {
	self = [super init];
	if (self) {
		_objects = [[NSMutableArray alloc] init];
		_filtered = [[BSFetchedResultsControllerAbstractContainer alloc] init];
		_filtered.section = self;
		isDisplayed = NO;
	}
	return self;
}

- (void)dealloc {
	[key release];
	[_name release];
	[_indexTitle release];
	[_objects release];
	[_filtered release];
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	if(self) {
		self.key = [[aDecoder decodeObjectForKey:kBSFRCSectionCacheKeyKey] retain];
		_name = [[aDecoder decodeObjectForKey:kBSFRCSectionCacheNameKey] retain];
		_indexTitle = [[aDecoder decodeObjectForKey:kBSFRCSectionCacheIndexTitleKey] retain];
		// Remember this is just an array of objectIDs, we need to turn them into objects
		// using a NSManagedObjectContext
		_objects = [[aDecoder decodeObjectForKey:kBSFRCSectionCacheObjectsKey] retain];
		_filtered = [[aDecoder decodeObjectForKey:kBSFRCSectionCacheFilteredKey] retain];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:key forKey:kBSFRCSectionCacheKeyKey];
	[aCoder encodeObject:_name forKey:kBSFRCSectionCacheNameKey];
	[aCoder encodeObject:_indexTitle forKey:kBSFRCSectionCacheIndexTitleKey];
	// We encode the object's objectID instance not the objects themselves.
	NSArray *objectIDURIReps = [_objects valueForKeyPath:@"objectID.URIRepresentation"];	
	[aCoder encodeObject:objectIDURIReps forKey:kBSFRCSectionCacheObjectsKey];
	objectIDURIReps = [_filtered valueForKeyPath:@"objectID.URIRepresentation"];
	[aCoder encodeObject:objectIDURIReps forKey:kBSFRCSectionCacheFilteredKey];
}

- (NSUInteger)numberOfObjects {
/*	
	NSLog(@"number of objects in Section: %@, filtered enabled: %d, showing filter group: %d, filtered count: %d", 
		  self.key, 
		  controller.enablePostFilterTest, 
		  controller.showFilteredObjectsAsGroup, 
		  [self.filteredItems count]);
*/ 
	if (controller.enablePostFilterTest && controller.showFilteredObjectsAsGroup && ([self.filteredItems count] > 0)) {
		return 1 + [self.objects count];
	}
	return [self.objects count];
}

- (void)setName:(NSString *)aString {
	[self willChangeValueForKey:@"name"];
	[_name release];
	_name = [aString copy];
	[self didChangeValueForKey:@"name"];	
}

- (void)setIndexTitle:(NSString *)aString {
	[self willChangeValueForKey:@"indexTitle"];	
	[_indexTitle release];
	_indexTitle = [aString copy];
	[self didChangeValueForKey:@"indexTitle"];
}

- (void)setObjects:(NSArray *)someObjects {
	[self willChangeValueForKey:@"numberOfObjects"];
	[self willChangeValueForKey:@"objects"];	
	[_objects release];
	_objects = [[NSMutableArray alloc] initWithArray:someObjects];
	[self didChangeValueForKey:@"objects"];	
	[self didChangeValueForKey:@"numberOfObjects"];
}

- (void)addObject:(id)obj {
	[self willChangeValueForKey:@"numberOfObjects"];
	[self willChangeValueForKey:@"objects"];	
	// Add the object
	[_objects addObject:obj];
	[self didChangeValueForKey:@"objects"];	
	[self didChangeValueForKey:@"numberOfObjects"];	
}

- (void)removeObject:(id)obj {
	[self willChangeValueForKey:@"numberOfObjects"];
	[self willChangeValueForKey:@"objects"];	
	// Remove the object
	[_objects removeObject:obj];
	[self didChangeValueForKey:@"objects"];	
	[self didChangeValueForKey:@"numberOfObjects"];		
}

- (NSArray *)filteredItems {
	return [_filtered items];
}

- (void)setFilteredItems:(NSArray *)_items {
	[self willChangeValueForKey:@"filtered"];	
	_filtered.items = [NSMutableArray arrayWithArray:_items];
	[self didChangeValueForKey:@"filtered"];
}

- (void)addFilteredObject:(id)obj {
	[self willChangeValueForKey:@"filtered"];	
	// Add the object
	[_filtered.items addObject:obj];
	[self didChangeValueForKey:@"filtered"];	
}

- (void)removeFilteredObject:(id)obj {
	[self willChangeValueForKey:@"filtered"];	
	// Remove the object
	[_filtered.items removeObject:obj];
	[self didChangeValueForKey:@"filtered"];
}


@end


#pragma mark -
#pragma mark BSFetchedResultsControllerSectionCache

@interface BSFetchedResultsControllerSectionInfoCache : NSObject <NSCoding> {
@private
	// Sectional Objects that we cache
	NSEntityDescription *entity;
	NSPredicate *fetchPredicate;
	NSArray *sortDescriptors;
	NSString *sectionNameKeyPath;
	NSDictionary *sectionsByName;
	NSPredicate *postFetchFilterPredicate;
	
}

@property (nonatomic, readwrite, retain) NSEntityDescription *entity;
@property (nonatomic, readwrite, retain) NSPredicate *fetchPredicate;
@property (nonatomic, readwrite, retain) NSArray *sortDescriptors;
@property (nonatomic, readwrite, retain) NSString *sectionNameKeyPath;
@property (nonatomic, readwrite, retain) NSDictionary *sectionsByName;
@property (nonatomic, readwrite, retain) NSPredicate *postFetchFilterPredicate;

- (void)spawnObjectsFromContext:(NSManagedObjectContext *)context;

@end

@implementation BSFetchedResultsControllerSectionInfoCache

@synthesize entity;
@synthesize fetchPredicate;
@synthesize sortDescriptors;
@synthesize sectionNameKeyPath;
@synthesize sectionsByName;
@synthesize postFetchFilterPredicate;

- (void)dealloc {
	self.entity = nil; [entity release];
	self.fetchPredicate = nil; [fetchPredicate release];
	self.sortDescriptors = nil; [sortDescriptors release];
	self.sectionNameKeyPath = nil; [sectionNameKeyPath release];	
	self.sectionsByName = nil; [sectionsByName release];
	self.postFetchFilterPredicate = nil; [postFetchFilterPredicate release];
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	if(self) {		
		self.entity = [aDecoder decodeObjectForKey:kBSFRCSectionInfoCacheFetchRequestEntityKey];
		self.fetchPredicate = [aDecoder decodeObjectForKey:kBSFRCSectionInfoCacheFetchRequestPredicateKey];
		self.sortDescriptors = [aDecoder decodeObjectForKey:kBSFRCSectionInfoCacheFetchRequestSortDescriptorsKey];
		self.sectionNameKeyPath = [aDecoder decodeObjectForKey:kBSFRCSectionInfoCacheSectionNameKeyPathKey];
		self.postFetchFilterPredicate = [aDecoder decodeObjectForKey:kBSFRCSectionInfoCachePostFetchPredicateKey];
		self.sectionsByName = [aDecoder decodeObjectForKey:kBSFRCSectionInfoCacheSectionsKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	
	[aCoder encodeObject:entity forKey:kBSFRCSectionInfoCacheFetchRequestEntityKey];
	[aCoder encodeObject:fetchPredicate forKey:kBSFRCSectionInfoCacheFetchRequestPredicateKey];
	[aCoder encodeObject:sortDescriptors forKey:kBSFRCSectionInfoCacheFetchRequestSortDescriptorsKey];
	[aCoder encodeObject:sectionNameKeyPath forKey:kBSFRCSectionInfoCacheSectionNameKeyPathKey];
	[aCoder encodeObject:postFetchFilterPredicate forKey:kBSFRCSectionInfoCachePostFetchPredicateKey];
	[aCoder encodeObject:sectionsByName forKey:kBSFRCSectionInfoCacheSectionsKey];
}

- (void)spawnObjectsFromContext:(NSManagedObjectContext *)context {
	
	NSPersistentStoreCoordinator *storeCoordinator = [context persistentStoreCoordinator];
	
	// Iterate through the sections
	for (BSFetchedResultsControllerSection *section in [sectionsByName allValues]) {
		
		// Create a NSMutableArray
		NSArray *objs = [section objects];
		NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[objs count]];		
		
		// Iterate over the objs and turn each one into an object
		for(NSURL *urlRepresentation in objs) {
			NSManagedObjectID *objectID = [storeCoordinator managedObjectIDForURIRepresentation:urlRepresentation];
			[objects addObject:[context objectWithID:objectID]];
		}
		
		// Now set this array as the objects array
		[section setObjects:objects];	
		
		// Do the same for the filtered objects
		objs = [section filtered];
		objects = [NSMutableArray arrayWithCapacity:[objs count]];
		
		// Iterate over the objs and turn each one into an object
		for(NSURL *urlRepresentation in objs) {
			NSManagedObjectID *objectID = [storeCoordinator managedObjectIDForURIRepresentation:urlRepresentation];
			[objects addObject:[context objectWithID:objectID]];
		}

		// Now set this array as the filtered array
		[section setObjects:objects];	
		
	}	
}

@end








#pragma mark -
#pragma mark BSFetchedResultsController

@interface BSFetchedResultsController ()

// Validates the contents of the cache (given by the cache name)
// against the properties used to instantiate the controller.
- (BOOL)readCache;

// Write everything to the cache
- (void)writeCache;

// NSManagedObjectContext Notification Handlers
- (void)registerNotificationHandlers;
- (void)removeNotificationHandlers;

// Methods which trigger updates via the delegate
- (void)performTableInsertionsAndUpdates:(NSDictionary *)changes;
- (void)performTableDeletions:(NSSet *)objects;

// Update the objects hierarchy
- (NSDictionary *)updateObjects:(NSSet *)objs;
- (NSDictionary *)removeObjects:(NSSet *)objs;

// This will perform the necessary changes for toggling the filter on/off
- (NSDictionary *)toggleFilter;

// These methods will show or hide the rows which can container the filtered objects
- (NSDictionary *)showFilteredObjectsGroups;
- (NSDictionary *)hideFilteredObjectsGroups;

@end

#pragma mark -

@implementation BSFetchedResultsController

@synthesize fetchRequest=_fetchRequest;
@synthesize managedObjectContext=_managedObjectContext;
@synthesize delegate=_delegate;
@synthesize cacheName=_cacheName;
@synthesize fetchedObjects=_fetchedObjects;
@synthesize sectionNameKeyPath=_sectionNameKeyPath;
@dynamic sections;
@synthesize sectionIndexTitles=_sectionIndexTitles;
@synthesize showFilteredObjectsAsGroup;

@synthesize postFetchFilterPredicate;
@synthesize postFetchFilterTest;
@synthesize enablePostFilterTest;
@synthesize postFetchComparator;

#pragma mark Initializers

- (id)initWithFetchRequest:(NSFetchRequest *)aFetchRequest 
	  managedObjectContext:(NSManagedObjectContext *)context 
		sectionNameKeyPath:(NSString *)aSectionNameKeyPath 
				 cacheName:(NSString *)aName {
	
	NSParameterAssert(aFetchRequest);
	NSParameterAssert(context);
	
	self = [super init];
	if(self) {
		_havePerformedFetch = NO;
		_managedObjectContext = [context retain];
		_fetchRequest = [aFetchRequest copy];
		if(aSectionNameKeyPath) {
			_sectionNameKeyPath = [aSectionNameKeyPath copy];
		}
		_cacheName = [aName copy];
		
		// Create a mutable set to store all objects that are fetched (including those which
		// will fail the postFetchFilterTest)
		_allObjects = [[NSMutableSet alloc] init];
		_sortedSectionNames = [[NSMutableArray alloc] init];
		_sectionsByName = [[NSMutableDictionary alloc] init];
		_sectionNamesByObject = [[NSMutableDictionary alloc] init];
		
		// Dispatch queue used for queuing DidChange notifications
		didChangeQueue = dispatch_queue_create("com.blindingskies.bsfrc", NULL);	
		
		// Register for notifications
		[self registerNotificationHandlers];
		handlingChange = NO;
	}
	return self;	
}

- (void)dealloc {
	// Release the dispatch queue
	dispatch_release(didChangeQueue);	
	[self removeNotificationHandlers];
	[_managedObjectContext release];
	[_fetchRequest release];
	[_fetchedObjects release];
	[_cacheName release];
	[_sortedSectionNames release];
	[_sectionsByName release];
	[_sectionNamesByObject release];
	self.postFetchFilterPredicate = nil; [postFetchFilterPredicate release];
	self.postFetchFilterTest = nil; [postFetchFilterTest release];
	self.postFetchComparator = nil; [postFetchComparator release];
	[super dealloc];
}

#pragma mark -
#pragma mark Public Methods

- (BOOL)performFetch:(NSError **)error {
	
	
	// If we have a cache name, check to see if we have a cache
	// and that it's valid
	if(_cacheName && [self readCache]) {
		
		// Copy objects over from the cache
		for(BSFetchedResultsControllerSection *section in [[_persistentCache sectionsByName] allValues]) {
			
			// Resort the objects within the section
			NSMutableArray *objs = [NSMutableArray arrayWithArray:section.objects];
			[objs sortUsingDescriptors:[_fetchRequest sortDescriptors]];
			if(self.postFetchComparator) {
				[objs sortUsingComparator:self.postFetchComparator];
			}
			[section setObjects:objs];
						
			// Set the section
			[_sectionsByName setObject:section forKey:section.key];
			
		}
		
		// Update the various properties
		[_sortedSectionNames release];
		_sortedSectionNames = [[NSArray alloc] initWithArray:[[_sectionsByName allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
		
		// Update other ordered things
		NSMutableArray *indexTitles = [[NSMutableArray alloc] init];
		NSMutableArray *allObjects = [[NSMutableArray alloc] init];
		for(NSString *key in _sortedSectionNames) {
			if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
				[indexTitles addObject:[[_sectionsByName objectForKey:key] indexTitle]];
			}
			[allObjects addObjectsFromArray:[[_sectionsByName objectForKey:key] objects]];
		}
		
		// Update the sectionIndexTitles
		[_sectionIndexTitles release];
		_sectionIndexTitles = [[NSArray alloc] initWithArray:indexTitles];
		
		// Update the fetchedResults array
		[_fetchedObjects release];
		_fetchedObjects = [[NSArray alloc] initWithArray:allObjects];
		
		[indexTitles release];
		[allObjects release];
		
		return YES;
	}

	// Perform the fetch
	NSError *anError = nil;
	NSArray *results = [_managedObjectContext executeFetchRequest:_fetchRequest error:&anError];	
	if(anError) {
		error = &anError;
		return NO;
	}
	
	if([results count] > 0) {
/*				
		if(self.postFetchFilterPredicate) {
			
			// Filter using a predicate
			results = [results filteredArrayUsingPredicate:self.postFetchFilterPredicate];
			
		}
		
		if(self.postFetchFilterTest) {
			
			// Filter using a block
			results = [results objectsPassingTest:self.postFetchFilterTest];

		}

		if(self.postFetchComparator) {
			
			// Sort using a comparator block
			results = [results sortedArrayUsingComparator:self.postFetchComparator];
			
			// Sort the filtered objects too
			tmp = [[filteredObjects allObjects] sortedArrayUsingComparator:self.postFetchComparator];
		}
*/		
		// Set the object in the hierarchy
		[self updateObjects:[NSSet setWithArray:results]];

	}
	
	_havePerformedFetch = YES;
	
	// If we've got a cache name, write to it
	if(_cacheName) {
		[self writeCache];
	}
		
	return YES;
}


- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
	NSString *sectionKey = nil;
	BSFetchedResultsControllerSection *section = nil;
	@try {
		sectionKey = [_sortedSectionNames objectAtIndex:indexPath.section];
		section = [_sectionsByName objectForKey:sectionKey];
		if (indexPath.row == [section.objects count]) {
			if ([indexPath length] == 3) {
				// Return a filtered object
				return [section.filteredItems objectAtIndex:[indexPath indexAtPosition:2]];
			} else {
				// Return the filtered container
				return section.filtered;
			}
		} else {
			return [[section objects] objectAtIndex:indexPath.row];
		}
	}
	@catch (NSException * e) {
		NSLog(@"Hit an exception: %@", [e userInfo]);
		return nil;
	}
	@finally { }
}

-(NSIndexPath *)indexPathForObject:(id)object {

	NSString *key = nil;
	BSFetchedResultsControllerSection *section = nil;
	NSUInteger sectionIndex, rowIndex;
	sectionIndex = rowIndex = NSNotFound;	
	
	if ([object isKindOfClass:[BSFetchedResultsControllerAbstractContainer class]]) {

		// The section objects
		section = ((BSFetchedResultsControllerAbstractContainer *)object).section;
		
		// The section index
		sectionIndex = [_sortedSectionNames indexOfObject:section.key];
	
		// Return the index of the container
		return [NSIndexPath indexPathForRow:[section.objects count] inSection:sectionIndex];
		
	}
	
	
	// If there isn't a section key path, use the default key
	if(_sectionNameKeyPath) {
		key = [object valueForKeyPath:_sectionNameKeyPath];
	} else {
		key = kBSFetchedResultsControllerDefaultSectionName;
	}
	
	if (key) {
		// The section objects
		section = [_sectionsByName objectForKey:key];
		// The section index
		sectionIndex = [_sortedSectionNames indexOfObject:key];
		// The row index
		rowIndex = [section.objects indexOfObject:object];
		if (rowIndex == NSNotFound) {
			rowIndex = [section.objects count];
		}
		
	} else {

		// We haven't got a key, which means that we're using a specific key to
		// perform sectioning, and this object has been deleted, thereby losing
		// the relationship being used as the key. This is probably more
		// likely than expected for any sort of non-trivial application that is
		// using sectioning.
		
		NSUInteger numberOfSections = [_sectionsByName count];
		
		// Iterate though the sections in order
		for (sectionIndex=0; sectionIndex<numberOfSections; sectionIndex++) {
			
			// Get the section
			section = [_sectionsByName objectForKey:[_sortedSectionNames objectAtIndex:sectionIndex]];
			
			// Enumerate over the array using a block to find indexes passing a test
			NSIndexSet *indexSet = [section.objects indexesOfObjectsPassingTest:^(id anObj, NSUInteger idx, BOOL *stop) {
				// Here we can check to see if the object id of anObj matches obj and if so return 
				return [[object objectID] isEqual:[anObj objectID]];
			}];
			
			// Now we need to check to see if we have a value in the index set
			if ([indexSet count] > 0) {
				rowIndex = [indexSet firstIndex];
				break;
			} 
			
			// Check this sections filtered objects
			indexSet = [section.filteredItems indexesOfObjectsPassingTest:^(id anObj, NSUInteger idx, BOOL *stop) {
				// Here we can check to see if the object id of anObj matches obj and if so return 
				return [[object objectID] isEqual:[anObj objectID]];
			}];				

			// Now we need to check to see if we have a value in the index set
			if ([indexSet count] > 0) {
				rowIndex = [section.objects count];
				break;
			} 
			
		} // End of for

	} // End of key check
	
	if (rowIndex == NSNotFound) {
		// We haven't found the object
		return nil;
	}
	
	// Create the index path object
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];	
	
	return indexPath;
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName {
	return [[sectionName capitalizedString] substringToIndex:1];
}


#pragma mark -
#pragma mark Dynamic Methods

- (NSArray *)sections {
	// We need to return the sections, in order, and excluding any which should actually be filtered	
	return [[[_sectionsByName allValues] objectsPassingTest:^(id obj, BOOL *stop) {
		if ([[(BSFetchedResultsControllerSection *)obj objects] count] > 0) {
			return YES;
		} else if (enablePostFilterTest && showFilteredObjectsAsGroup && ([[(BSFetchedResultsControllerSection *)obj filteredItems] count] > 0)) {
			return YES;
		}
		return NO;
	}] sortedArrayUsingComparator:^(id a, id b) {
		return [((BSFetchedResultsControllerSection *)a).key caseInsensitiveCompare:((BSFetchedResultsControllerSection *)b).key];
	}];
}

- (void)setEnablePostFilterTest:(BOOL)aBoolean {
	if (enablePostFilterTest != aBoolean) {
		[self willChangeValueForKey:@"enablePostFilterTest"];
		if (_havePerformedFetch) {
			[self performTableInsertionsAndUpdates:[self toggleFilter]];							
		}
		enablePostFilterTest = aBoolean;
		[self didChangeValueForKey:@"enablePostFilterTest"];
	}
	
}

- (void)setShowFilteredObjectsAsGroup:(BOOL)aBoolean {
	if (showFilteredObjectsAsGroup != aBoolean) {
		[self willChangeValueForKey:@"showFilteredObjectsAsGroup"];
		if (_havePerformedFetch) {
			if (aBoolean) {			
				[self performTableInsertionsAndUpdates:[self showFilteredObjectsGroups]];
			} else {
				[self performTableInsertionsAndUpdates:[self hideFilteredObjectsGroups]];
			}			
		}
		showFilteredObjectsAsGroup = aBoolean;
		[self didChangeValueForKey:@"showFilteredObjectsAsGroup"];
	}
}







#pragma mark -
#pragma mark Class Methods

+ (BOOL)deleteCache:(NSString *)aCacheName {
	// Create a path to the cache
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);		
	NSString *path = [NSString stringWithFormat:@"%@/%@/%@.cache", [paths objectAtIndex:0], kBSFetchedResultsControllerCachePath, aCacheName];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	if (![fileManager removeItemAtPath:path error:&error]) {
		// print the error message
		NSLog(@"failed to delete cache: %@", [error userInfo]);
		return NO;
	}
	return YES;
}


									
#pragma mark -
#pragma mark Private Methods

// Validates the contents of the cache (given by the cache name)
// against the properties used to instantiate the controller.
- (BOOL)readCache {
	
	// Return false if we haven't got a cache name
	if(!_cacheName) return NO;
		
	// Create a path to the cache
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);		
	NSString *path = [NSString stringWithFormat:@"%@/%@/%@.cache", [paths objectAtIndex:0], kBSFetchedResultsControllerCachePath, _cacheName];
	
	// First of all we need to decode the cache
	_persistentCache = (BSFetchedResultsControllerSectionInfoCache *)[NSKeyedUnarchiver unarchiveObjectWithFile:path];

	// Now we need to check to see if the various properties are the same
	if( ![[[_fetchRequest entity] name] isEqual:[((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).entity name]]) {
		NSLog(@"Cache difference: fetch request's entity");
		return NO;
	}

	if ((((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).fetchPredicate && [_fetchRequest predicate]) &&
		![[_fetchRequest predicate] isEqual:((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).fetchPredicate]) {
		NSLog(@"Cache difference: fetch request's predicate");
		return NO;
	}

	if ((((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).sortDescriptors && [_fetchRequest sortDescriptors]) &&
		![[_fetchRequest sortDescriptors] isEqual:((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).sortDescriptors]) {
		NSLog(@"Cache difference: fetch request's sort descriptors");
		return NO;
	}	
	
	if( _sectionNameKeyPath && ![_sectionNameKeyPath isEqual:((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).sectionNameKeyPath]) {
		NSLog(@"Cache difference: section name key path");
		return NO;
	}
	
	if( postFetchFilterPredicate && ![postFetchFilterPredicate isEqual:((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).postFetchFilterPredicate]) {
		NSLog(@"Cache difference: post fetch filter predicate");
		return NO;
	}
		
	// If we've got this far then all the various objects which define the controller match the cache
	// so, assuming that the cache has kept up to date we can start using it again.
	
	// First we need to turn our objectIDs into proper NSManagedObject instances
	[(BSFetchedResultsControllerSectionInfoCache *)_persistentCache spawnObjectsFromContext:self.managedObjectContext];	
	
	return YES;
}


// Write everything to the cache
- (void)writeCache {

	// Return if we haven't got a cache name
	if(!_cacheName) return;
		
	// Create a path to the cache
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);		
	NSString *path = [NSString stringWithFormat:@"%@/%@/%@.cache", [paths objectAtIndex:0], kBSFetchedResultsControllerCachePath, _cacheName];
		
	// First check to see if a file exists at this path
	NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO];
	NSError *error = nil;
	if ( ![url checkResourceIsReachableAndReturnError:&error]) {

		if(![[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], kBSFetchedResultsControllerCachePath] withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSArray *detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
			if(detailedErrors != nil && [detailedErrors count] > 0) {
				for(NSError *detailedError in detailedErrors) {
					NSLog(@"  DetailedError: %@", [detailedError userInfo]);
				}
			}
			else {
				NSLog(@"  %@", [error userInfo]);
			}
			return;
		}
	}
	
	
	// Create a SectionInfoCache object
	_persistentCache = (BSFetchedResultsControllerSectionInfoCache *)[[BSFetchedResultsControllerSectionInfoCache alloc] init];
	((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).entity = [_fetchRequest entity];
	((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).fetchPredicate = [_fetchRequest predicate];
	((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).sortDescriptors = [_fetchRequest sortDescriptors];
	((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).sectionNameKeyPath = _sectionNameKeyPath;
	((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).sectionsByName = _sectionsByName;
	((BSFetchedResultsControllerSectionInfoCache *)_persistentCache).postFetchFilterPredicate = postFetchFilterPredicate;
	
	// Encode the cache
	
	if( ![NSKeyedArchiver archiveRootObject:_persistentCache toFile:path] ) {
		NSLog(@"Archive failed...");
	}
	
}


// Add notification handlers to NSNotificationCenter
- (void)registerNotificationHandlers {
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	/*	Register to receive DidChangeNotifications - we then analsye the contents of 
	 the Inserted, Deleted and Updated objects to merge the changes with our cache
	 and if set inform the delegate of the processed changes.
	 */		 
	
	didChangeNotificationHandler = [nc addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *aNotification) {
		
		// If we don't have a delegate or a cache, then we can return now
		if (!self.delegate && !self.cacheName) return;
		
		// Get the user info dictionary
		NSDictionary *userInfo = [aNotification userInfo];
		
		// Create a compound predicate containing an entity based predicate, the fetch request's predicate
		// and if present a post fetch filter predicate
		NSPredicate *entityType = [NSPredicate predicateWithFormat:@"entity == %@", [_fetchRequest entity]]; 
		NSMutableArray *predicates = [NSMutableArray arrayWithObjects:entityType, nil];
		if([_fetchRequest predicate]) {
			[predicates addObject:[_fetchRequest predicate]];
		}
		if(self.postFetchFilterPredicate) {
			[predicates addObject:self.postFetchFilterPredicate];
		}
		NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
				
		NSMutableSet *changedObjects = [NSMutableSet set];
		
		// -------------------------------- //
		// -- INSERTED & UPDATED OBJECTS -- //
		// -------------------------------- //

		[changedObjects unionSet:[userInfo objectForKey:NSInsertedObjectsKey]];
		[changedObjects unionSet:[userInfo objectForKey:NSUpdatedObjectsKey]];
		[changedObjects unionSet:[userInfo objectForKey:NSRefreshedObjectsKey]];
		[changedObjects filterUsingPredicate:compoundPredicate];
		
		// If we've got inserted objects...
		if ([changedObjects count] > 0) {
			
			// Update the sectional information		
			NSDictionary *changes = [self updateObjects:changedObjects];
			[self performTableInsertionsAndUpdates:changes];
			
		}		
		
		// -- DELETED OBJECTS -- //

		NSSet *deletedObjects = [[userInfo objectForKey:NSDeletedObjectsKey] filteredSetUsingPredicate:compoundPredicate];
		
		// If we've got deleted objects...
		if ([deletedObjects count] > 0) {

			[self performTableDeletions:deletedObjects];
		}
		
		// Write the cache
		[self writeCache];
		
	}];
	
}


// Remove the notification handlers from the NSNotificationCenter
- (void)removeNotificationHandlers {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];	
	if(didChangeNotificationHandler) {
		[nc removeObserver:didChangeNotificationHandler];		
	}
}

// Methods which trigger updates via the delegate
- (void)performTableInsertionsAndUpdates:(NSDictionary *)changes {
	
	// Inform the delegate that we're about to change content
	if([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
		[self.delegate controllerWillChangeContent:self];
		
	if([self.delegate respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)]) {
		// Perform sectional insertions
		NSMutableArray *addedSections = [changes objectForKey:@"InsertedSections"];
		for(BSFetchedResultsControllerSection *aSection in addedSections) {
//			NSLog(@"Inserting section at %d", [_sortedSectionNames indexOfObject:aSection.key]);
			// We need to tell the delegate to insert a section
			[self.delegate controller:self 
					 didChangeSection:aSection 
							  atIndex:[_sortedSectionNames indexOfObject:aSection.key] 
						forChangeType:NSFetchedResultsChangeInsert];					
		}			
	}
	
	
	if([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
		
		
		// Perform row removals
		NSDictionary *removedObjects = [changes objectForKey:@"RemovedObjects"];
		NSMutableSet *removedIndexes = [NSMutableSet set];
		
		// Iterate through the deleted cells 
		if ([removedObjects count] > 0) {
			for(id obj in [removedObjects allValues]) {				
				// Get the index path for this object 
				NSIndexPath *indexPath = [[removedObjects allKeysForObject:obj] lastObject];
				
				if (indexPath && indexPath.section != NSNotFound && indexPath.row != NSNotFound) {
					if (![removedIndexes containsObject:indexPath]) {
//						NSLog(@"Removing row at [%d,%d]", indexPath.section, indexPath.row);
						[self.delegate controller:self 
								  didChangeObject:obj 
									  atIndexPath:indexPath 
									forChangeType:NSFetchedResultsChangeDelete 
									 newIndexPath:nil];					
						[removedIndexes addObject:indexPath];
					}
				}
			}
		}
		
		
		// Perform row insertions
		NSMutableArray *insertedObjects = [changes objectForKey:@"InsertedObjects"];
		
		// Iterate through the inserted cells
		for(id obj in insertedObjects) {
			
			// Get the index path for this object 
			NSIndexPath *indexPath = [self indexPathForObject:obj];
			if (indexPath && indexPath.section != NSNotFound && indexPath.row != NSNotFound) {
//				NSLog(@"Inserting row at [%d,%d]", indexPath.section, indexPath.row);				
				[self.delegate controller:self 
						  didChangeObject:obj 
							  atIndexPath:nil 
							forChangeType:NSFetchedResultsChangeInsert 
							 newIndexPath:indexPath];							
			}
		}
		
		// Perform row updates
		NSMutableArray *updatedObjects = [changes objectForKey:@"UpdatedObjects"];
		
		// Iterate through the updated cells
		for (id obj in updatedObjects) {
			// Get the index path for this object 
			NSIndexPath *indexPath = [self indexPathForObject:obj];
			if (indexPath && indexPath.section != NSNotFound && indexPath.row != NSNotFound) {
				[self.delegate controller:self 
						  didChangeObject:obj 
							  atIndexPath:indexPath 
							forChangeType:NSFetchedResultsChangeUpdate 
							 newIndexPath:nil];				
			}
		}
		
		
		// Iterate through the updated cells
		// Perform row updated
		NSMutableDictionary *movedObjects = [changes objectForKey:@"MovedObjects"];
		
		for(id obj in [movedObjects allValues]) {
			
			// Get the old index
			NSIndexPath *indexPath = [[movedObjects allKeysForObject:obj] lastObject];
			
			// Get the new index
			NSIndexPath *newIndexPath = [self indexPathForObject:obj];
			
			if (newIndexPath && newIndexPath.section != NSNotFound && newIndexPath.row != NSNotFound) {
				if([indexPath isEqual:newIndexPath]) {
					
					[self.delegate controller:self 
							  didChangeObject:obj 
								  atIndexPath:indexPath 
								forChangeType:NSFetchedResultsChangeUpdate 
								 newIndexPath:nil];							
				} else {
					
					// The index path of the object which has been updated has changed, so we issue a move then an update
					// We do it in this order because the update retrieve data from the controller
					
					[self.delegate controller:self 
							  didChangeObject:obj 
								  atIndexPath:indexPath 
								forChangeType:NSFetchedResultsChangeMove 
								 newIndexPath:newIndexPath];
					
					// And update is assumed, so we don't need to issue an extra update call
				}				
			}			
		}		
	}				
	
	// Perform sectional deletions
	if([self.delegate respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)]) {
		NSDictionary *removedSections = [changes objectForKey:@"RemovedSections"];
		for(BSFetchedResultsControllerSection *aSection in [removedSections allValues]) {
			
			// Get the index of the section
			NSUInteger sectionIndex = [[[removedSections allKeysForObject:aSection] lastObject] integerValue];
			
			// Inform the delegate that we've got to remove this section
			[self.delegate controller:self 
					 didChangeSection:aSection 
							  atIndex:sectionIndex 
						forChangeType:NSFetchedResultsChangeDelete];
			
		}			
	}

	
	// Inform the delegate that we've finished changing content
	if([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)])
		[self.delegate controllerDidChangeContent:self];
	
}

- (void)performTableDeletions:(NSSet *)objects {
	
	// Inform the delegate that we're about to change content
	if([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
		[self.delegate controllerWillChangeContent:self];
	
	// Get the changes
	NSDictionary *changes = [self removeObjects:objects];				
	
	if([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
		
		NSDictionary *removedObjects = [changes objectForKey:@"RemovedObjects"];
		
		// Iterate through the deleted cells 
		if ([removedObjects count] > 0) {
			for(id obj in objects) {
				
				// Get the index path for this object 
				NSIndexPath *indexPath = [[removedObjects allKeysForObject:obj] lastObject];
				if (indexPath) {
					[self.delegate controller:self 
							  didChangeObject:obj 
								  atIndexPath:indexPath 
								forChangeType:NSFetchedResultsChangeDelete 
								 newIndexPath:nil];					
				}
			}
		}
	}				
	
	// Remove the deleted objects
	NSDictionary *removedSections = [changes objectForKey:@"RemovedSections"];
	
	for(BSFetchedResultsControllerSection *aSection in [removedSections allValues]) {
		
		// Get the index of the section
		NSUInteger sectionIndex = [[[removedSections allKeysForObject:aSection] lastObject] integerValue];
		
		// Inform the delegate that we've got to remove this section
		[self.delegate controller:self 
				 didChangeSection:aSection 
						  atIndex:sectionIndex 
					forChangeType:NSFetchedResultsChangeDelete];
		
	}
	
	// Inform the delegate that we've finished changing content
	if([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)])
		[self.delegate controllerDidChangeContent:self];
	
}


- (NSDictionary *)removeObjects:(NSSet *)objs {
	
	// Removing is significantly easier than updating or inserting, because
	// we don't need to worry about the filter; the objects have already 
	// passed it.
	
	// The only thing to look out for is if a the last row in a section gets
	// removed and this triggers the removal of a section. Also, if a Core
	// Data object has been deleted, then the relationships it has no longer
	// exist. So, if the sectionKeyPath is a relationship, it can't be followed
	// to work out what section the object is in. That is why here, we call
	// the controller's indexPathForObject: method, which can deal with this
	// situation.
	
	NSMutableDictionary *removedSections = [NSMutableDictionary dictionary];
	NSMutableDictionary *removedObjects = [NSMutableDictionary dictionary];
	NSMutableArray *updatedObjects = [NSMutableArray array];
	
	// Enumerate the objects we're going to remove
	for (id obj in objs) {
	
		// Get the indexPath of the object
		NSIndexPath *indexPath = [self indexPathForObject:obj];
		
		// Use the index path to get the section
		NSUInteger sectionIndex = [indexPath indexAtPosition:0];
		BSFetchedResultsControllerSection *section = [_sectionsByName objectForKey:[_sortedSectionNames objectAtIndex:sectionIndex]];
		
		// Work out whether the object used to be filtered
		BOOL wasFiltered = [section.filteredItems containsObject:obj];

		if (wasFiltered) {
			// Remove the filtered object
			[section removeFilteredObject:obj];

			if (showFilteredObjectsAsGroup) {
				if ([section.filteredItems count] == 0) {
					if ([section.objects count] == 0) {
						// We've removed the last filtered object, for a section with no non-filtered objects
						[removedSections setObject:section forKey:[NSNumber numberWithInteger:sectionIndex]];
						
						// Remove the section
						[_sectionsByName removeObjectForKey:section.key];			

					} else {
						// We're going to remove this row
						[removedObjects setObject:obj forKey:[NSIndexPath indexPathForRow:[indexPath indexAtPosition:1] inSection:sectionIndex]];
						if ([updatedObjects containsObject:section.filtered]) {
							[updatedObjects removeObject:section.filtered];
						}
					}
				} else {
					[updatedObjects addObject:section.filtered];
				}
			}
			
		} else {
			
			// Remove the object
			[section removeObject:obj];
			[removedObjects setObject:obj forKey:indexPath];			
			
			if ([section.objects count] == 0) {
				if (!showFilteredObjectsAsGroup || [section.filteredItems count] == 0) {
					// We've just removed the las row, and there are no filtered objects
					// so it doesn't matter whether we're showing the filtered group or not
					// we can delete the whole section
					[removedSections setObject:section forKey:[NSNumber numberWithInteger:sectionIndex]];
					// Remove the section
					[_sectionsByName removeObjectForKey:section.key];
				}
			}
		}
		
		// Remove from all objects
		[_allObjects removeObject:obj];
	}
	
	// Update the various properties
	[_sortedSectionNames release];
	_sortedSectionNames = [[NSArray alloc] initWithArray:[[_sectionsByName allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	
	// Update other ordered things
	NSMutableArray *indexTitles = [[NSMutableArray alloc] init];
	NSMutableArray *allObjects = [[NSMutableArray alloc] init];
	for(NSString *key in _sortedSectionNames) {
		if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
			[indexTitles addObject:[[_sectionsByName objectForKey:key] indexTitle]];
		}
		[allObjects addObjectsFromArray:[[_sectionsByName objectForKey:key] objects]];
	}
	
	// Update the sectionIndexTitles
	[_sectionIndexTitles release];
	_sectionIndexTitles = [[NSArray alloc] initWithArray:indexTitles];
	
	// Update the fetchedResults array
	[_fetchedObjects release];
	_fetchedObjects = [[NSArray alloc] initWithArray:allObjects];
	
	[indexTitles release];
	[allObjects release];

	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			removedSections, @"RemovedSections",
			removedObjects, @"RemovedObjects",
			updatedObjects, @"UpdatedObjects", // this can only ever be the filtered object group
			nil];
	
}


- (NSDictionary *)updateObjects:(NSSet *)objs {

	// Define storage objects to keep the objects which have been processed
	// and which get sent to the delegate to update the interface
	
	NSMutableSet *insertedObjects = [NSMutableSet set];
	NSMutableSet *insertedSections = [NSMutableSet set];
	NSMutableSet *updatedObjects = [NSMutableSet set];
	NSMutableDictionary *removedSections = [NSMutableDictionary dictionary];
	NSMutableDictionary *movedObjects = [NSMutableDictionary dictionary];
	NSMutableDictionary *removedObjects = [NSMutableDictionary dictionary];
			
	NSSet *filteredObjects = nil;
	NSSet *finalObjects = objs;
	
	if (enablePostFilterTest) {
		// Filter the objects
		finalObjects = [objs objectsPassingTest:self.postFetchFilterTest];
		filteredObjects = [objs setByRemovingObjectsFromSet:finalObjects];
	}		
	
	// Iterate through the objects
	for (id obj in objs) {

		// Perform a quick test to see whether the object is a final or filtered object
		BOOL isFiltered = ![finalObjects containsObject:obj];
			
		// Get the object's section key, using the default if necessary
		NSString *key = nil;		
		if (_sectionNameKeyPath) {
			key = [obj valueForKeyPath:_sectionNameKeyPath];
		} else {
			key = kBSFetchedResultsControllerDefaultSectionName;
		}
		
		// Get the section object for this key
		BSFetchedResultsControllerSection *section = [_sectionsByName objectForKey:key];		
		
		// Create the section if it doesn't already exist
		if(!section) { 
			
			// Create the section object
			section = [[BSFetchedResultsControllerSection alloc] init];
			section.key = key;
			section.controller = self;
			if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
				[section setName:[key capitalizedString]];
				[section setIndexTitle:[self sectionIndexTitleForSectionName:section.name]];			
			}
			
			// Add the section to the dictionary
			[_sectionsByName setObject:section forKey:key];			
		
			// The section needs to be inserted
			[insertedSections addObject:section];
			section.isDisplayed = YES;
			
		}
		
		// Check to see if the object is already in controller
		if ([_allObjects containsObject:obj]) {			
				
			// Get the index path of the object from the controller	
			NSIndexPath *indexPath = [self indexPathForObject:obj];
			
			// Work out whether the object used to be filtered
			BOOL wasFiltered = indexPath.row == [section.objects count];
			
			// Get the old section key
			BSFetchedResultsControllerSection *oldSection = nil;
			NSString *oldKey = [_sortedSectionNames objectAtIndex:indexPath.section];
			
			// We need to test to see if the object should move path
			if ( ![oldKey isEqualToString:key] ) {					
				// This means that the object is stored in the controller, but under the wrong section
				
				// Get the old section
				oldSection = [_sectionsByName objectForKey:oldKey];
			}
			
			// Check to see if the object was filtered and is still filtered
			if (wasFiltered && isFiltered) {
				
				// Check to see if the object has changed sections
				if (![oldKey isEqualToString:key]) {
					
					// Remove the object from the old section's filtered items
					[oldSection removeFilteredObject:obj];
					
					// Add the object to the new section's filtered items
					[section addFilteredObject:obj];
					
					// Check to see if we're displaying the filtered objects
					if (showFilteredObjectsAsGroup) {
						
						// The old section has changed
						if ([oldSection.filtered count] > 0) {
							// We need to update the old section's filtered object container row
							[updatedObjects addObject:oldSection.filtered];
						} else {
							// We've removed the last filtered object from the old section, so we need to remove
							// the old section "container" row
							[removedObjects setObject:oldSection.filtered forKey:[NSIndexPath indexPathForRow:[indexPath indexAtPosition:1] inSection:[indexPath indexAtPosition:0]]];								
						}
						
						// The new section has changed
						if ([section.filteredItems count] == 1) {
							// This means we've just added the first filtered object, so need to
							// insert the container row
							[insertedObjects addObject:section.filtered];
							
						} else {
							// We need to update the new section's filtered object container row
							[updatedObjects addObject:section.filtered];								
						}
					}
					
					// We don't have any rows to update for normal non-filtered objects
					// as we're only dealing with filtered objects
					
				} else {
					
					// Here, the object has not change it's filtered status, nor it's section
					// so we just need to mark the container row for an update
					
					if (showFilteredObjectsAsGroup) {
						if (!section.isDisplayed) {
							[insertedSections addObject:section];
							section.isDisplayed = YES;
						}
						// Mark the container for updates
						[updatedObjects addObject:section.filtered];
					}
				}
				
			} else if (wasFiltered && !isFiltered) {
				
				// So here, we have an object which was filtered and now isn't filtered
				
				// Check to see if the object has changed sections
				if (![oldKey isEqualToString:key]) {
					
					// So, the section has also changed, which means that we need to remove
					// the object from the old section's filtered objects
					[oldSection removeFilteredObject:obj];
					
					// Add the object to the section's objects
					[section addObject:obj];
					
					if (showFilteredObjectsAsGroup) {
						
						// The old section has changed
						if ([oldSection.filtered count] > 0) {
							// We need to update the old section's filtered object container row
							[updatedObjects addObject:oldSection.filtered];
							
						} else {
							// We've removed the last filtered object from the old section, so we need to remove
							// the old section "container" row
							[removedObjects setObject:oldSection.filtered forKey:[NSIndexPath indexPathForRow:[indexPath indexAtPosition:1] inSection:[indexPath indexAtPosition:0]]];
						}							
					}
					
					// Mark the non-filtered row as an insert
					[insertedObjects addObject:obj];
					
				} else {

					// Remove the object from the filtered list
					[section removeFilteredObject:obj];
					
					// Add the object
					[section addObject:obj];
					
					// Mark the non-filtered row as an insert
					[insertedObjects addObject:obj];
										
					if (showFilteredObjectsAsGroup) {
						
						// Mark the container for updates
						if ([section.filteredItems count] > 0) {
							[updatedObjects addObject:section.filtered];
							
						} else {
							// We've removed the last filtered object from the old section, so we need to remove
							// the old section "container" row
							[removedObjects setObject:section.filtered forKey:[NSIndexPath indexPathForRow:[indexPath indexAtPosition:1] inSection:[indexPath indexAtPosition:0]]];
							
							if ([section.objects count] == 1) {
								// We've just inserted an object
								[insertedSections addObject:section];
							}	
						}												
						
					} else {						
						// Mark the non-filtered row as an insert
						if ([section.objects count] == 1) {
							// We've just inserted an object
							[insertedSections addObject:section];
						}						
					}
				}
				
			} else if (!wasFiltered && isFiltered) {
				
				// So here, we have an object which wasn't filtered, but now is filtered.
				
				// Check to see if the object has changed sections
				if (![oldKey isEqualToString:key]) {
					
					// So, the section has also changed, which means that we need to remove
					// the object from the old section's object and add it to the new section's
					// filtered objects.
					[oldSection removeObject:obj];
					
					// Add the object to the filtered objects
					[section addFilteredObject:obj];
					
					// We're showing the filters as a container
					if (showFilteredObjectsAsGroup) {
						
						// The old section has changed
						if ([oldSection.objects count] > 0) {
							// We've not got any rows, but we do have filtered rows (which we're showing)
							[removedObjects setObject:obj forKey:indexPath];								
						} else if (([oldSection.filtered count] == 0)) {
							// We need to remove the whole section
							[removedSections setObject:oldSection forKey:[NSNumber numberWithInteger:indexPath.section]];
						}
						
						// The new section has changed
						if ([section.filteredItems count] == 1) {
							// This means we've just added the first filtered object, so need to
							// insert the container row
							[insertedObjects addObject:section.filtered];
							
						} else {
							// We need to update the new section's filtered object container row
							[updatedObjects addObject:section.filtered];								
						}
					}
					
					// Mark the object as inserted
					[insertedObjects addObject:obj];
					
				} else {
					
					// So here, the sections haven't changed, we've got to update (or remove) the 
					// filtered container, and insert the object
					
					// Remove the object from the filtered
					[section removeObject:obj];
					
					// Add as an object
					[section addFilteredObject:obj];
												
					// We're showing the filters as a container
					if (showFilteredObjectsAsGroup) {
						
						// The section's filtered objects needs to be updated
						if ([section.filteredItems count] == 1) {
							// We need to update the new section's filtered object container row
							[insertedObjects addObject:section.filtered];
						} else {
							// We need to actually remove the container's row
							[updatedObjects addObject:section.filtered];
						}
					}
					
					// The section has changed
					if ([section.objects count] > 0) {
						// We've remove the object from the non-filtered rows
						[removedObjects setObject:obj forKey:indexPath];
					} else if (([section.filteredItems count] == 0) || !showFilteredObjectsAsGroup) {
						// We need to remove the whole section
						[removedObjects setObject:obj forKey:indexPath];
						[removedSections setObject:section forKey:[NSNumber numberWithInteger:indexPath.section]];
						section.isDisplayed = NO;
					}
/*														
					// Mark the object as inserted
					[insertedObjects addObject:obj];
*/
				}
				
			} else if (!wasFiltered && !isFiltered) {
				
				// So this is the normal scenario, the object previously was not filtered,
				// and it's still not filtered, but it's more than likely moved
				
				[movedObjects setObject:obj forKey:indexPath];
				
			}					
				
			
		} else {
			
			// We don't have the object, so we will have to perform an insert
			// but first we should check whether the filter test is enabled
			// of is the object is a member of the final objects. This avoids
			// unnecessary processing
			
			// Insert the object into the section
			// Check whether the object is a member of the final objects				
			if (!isFiltered) {					
				
				// Add the object to the section's object
				[section addObject:obj];
				
				if (showFilteredObjectsAsGroup) {
					
				} else {
					if ([section.objects count] == 1) {
						// We've just added the first object to the section.
						// We're not showing filtered objects, so need to insert the
						// section
						[insertedSections addObject:section];
						section.isDisplayed = YES;
					}
				}
				
				// Add the object to the inserted objects array
				[insertedObjects addObject:obj];
				
			} else {
				
				// Add the object to the section's filtered objects
				[section addFilteredObject:obj];
				
				// Check to see if we're displaying the filtered objects as a group
				if (showFilteredObjectsAsGroup) {
					
					// Add the whole array to the [inserted|updated]Objects set, because we
					// maybe have updated an object, which is filtered, but whose container
					// is already being display. Or we may be inserting the first filtered
					// object, in which case we need to insert a new row for the container
					
					if (([section.filteredItems count] > 1) && ![insertedObjects containsObject:section.filtered]) {
						[updatedObjects addObject:section.filtered];
					} else {
						[insertedObjects addObject:section.filtered];
						// Also check to see if we need to add the section
						if ([section.objects count] == 0) {
							// We've just added the first object to the section.
							// We're not showing filtered objects, so need to insert the
							// section
							[insertedSections addObject:section];
							section.isDisplayed = YES;
						}
					}
					// Before we return from this funtion, we will make sure that the array
					// only exists in one of those (with preference over the inserted object
					
				} // end of showFilteredObjectsAsGroup check
			} // end of isFinalObject check						
			
			// Add the object to the _allObjects set
			[_allObjects addObject:obj];				
			
		} // end of _allObjects contains obj check
			
						
	} // end of for loop 
	
	// Now we need to resort the objects in the sections
	if([_fetchRequest sortDescriptors] || self.postFetchComparator) {
		
		// Enumerate the objects and put them into the dictionary sections
		[objs enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
			
			// There is actually an inadequency here in that we might sort the
			// same section mutiple times because we're updating more than one
			// object from the same section.
			
			// If there isn't a section key path, use the default key
			NSString *key = nil;		
			if(_sectionNameKeyPath) {
				key = [obj valueForKeyPath:_sectionNameKeyPath];
			} else {
				key = kBSFetchedResultsControllerDefaultSectionName;
			}
			
			// Get the section object for this key
			BSFetchedResultsControllerSection *section = [_sectionsByName objectForKey:key];
			
			// Get the objects
			NSMutableArray *objects = [NSMutableArray arrayWithArray:section.objects];
						
			// Resort
			if([_fetchRequest sortDescriptors]) {
				[objects sortUsingDescriptors:[_fetchRequest sortDescriptors]];
			}
			if(self.postFetchComparator) {
				[objects sortUsingComparator:self.postFetchComparator];
			}
			
			// Set the objects back			
			[section setObjects:objects];
		}];
	}
	
	// Update the various properties
	[_sortedSectionNames release];
	_sortedSectionNames = [[NSArray alloc] initWithArray:[self.sections valueForKeyPath:@"key"]];
	
	// Update other ordered things
	NSMutableArray *indexTitles = [[NSMutableArray alloc] init];
	NSMutableArray *allObjects = [[NSMutableArray alloc] init];
	for(NSString *key in _sortedSectionNames) {
		if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
			[indexTitles addObject:[[_sectionsByName objectForKey:key] indexTitle]];
		}
		[allObjects addObjectsFromArray:[[_sectionsByName objectForKey:key] objects]];
	}
	
	// Update the sectionIndexTitles
	[_sectionIndexTitles release];
	_sectionIndexTitles = [[NSArray alloc] initWithArray:indexTitles];
	
	// Update the fetchedResults array
	[_fetchedObjects release];
	_fetchedObjects = [[NSArray alloc] initWithArray:allObjects];
	
	[indexTitles release];
	[allObjects release];
	
	// We now need to package up the various changes into a dictionary to return	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			insertedObjects, @"InsertedObjects",
			updatedObjects, @"UpdatedObjects",
			movedObjects, @"MovedObjects", 
			removedObjects, @"RemovedObjects",
			insertedSections, @"InsertedSections", 
			removedSections, @"RemovedSections", 
			nil];	
	
}


// This will perform the necessary changes for toggling the filter on/off
- (NSDictionary *)toggleFilter {
			
	NSMutableSet *insertedObjects = [NSMutableSet set];
	NSMutableSet *insertedSections = [NSMutableSet set];
	NSMutableSet *updatedObjects = [NSMutableSet set];
	NSMutableDictionary *movedObjects = [NSMutableDictionary dictionary];
	NSMutableDictionary *removedSections = [NSMutableDictionary dictionary];
	NSMutableDictionary *removedObjects = [NSMutableDictionary dictionary];
	
	// We've just turned on the filter, so we need to update the filtered objects
	NSSet *finalObjects = [_allObjects objectsPassingTest:self.postFetchFilterTest];
	NSSet *filteredObjects = [_allObjects setByRemovingObjectsFromSet:finalObjects];	
	
	// Toggle Filter:
	// When toggling the filter, objects will be moving from the objects array to
	// the filtered array and visa-versa. This means we need to perform the following
	// table updates:
	
	// sections:	if a section has one object, which is filtered, then 
	//				depending on the state of showFilteredObjectsAsGroups
	//				we will need to insert/remove sections 
	
	// row:			when unfiltering an object, it must be inserted as a row. When 
	//				filtering an object, we will need to either insert a row or
	//				update a row, for the filter container (depending on whether 
	//				we're showing them.
	
	
	// Define a mutable set for the modified sections
	NSMutableSet *modifiedSections = [NSMutableSet set];
	
	// Iterate though the filtered objects
	for (id obj in filteredObjects) {

		// Get the object's section key, using the default if necessary
		NSString *key = nil;		
		if (_sectionNameKeyPath) {
			key = [obj valueForKeyPath:_sectionNameKeyPath];
		} else {
			key = kBSFetchedResultsControllerDefaultSectionName;
		}
		
		// Get the section object for this key
		[modifiedSections addObject:[_sectionsByName objectForKey:key]];
		
	}
	
	// Now we can iterate though the sections
	
	for (BSFetchedResultsControllerSection *section in modifiedSections) {
				
		// Work out what the section index is
		NSInteger sectionIndex = [_sortedSectionNames indexOfObject:section.key];		
		
		// If we're transitioning from enabled to disabled
		if (enablePostFilterTest) {
			
			NSLog(@"Filtering section: %d %@", sectionIndex, section.key);
			
			// The filter is currently enabled, but we are going to disable it now.
								
			// Configure change dictionary for delegate methods
			if (showFilteredObjectsAsGroup) {
				
				// We're disabling the filter, so we're going to be adding rows
				NSUInteger i, len = [section.filteredItems count];
				// The first row, which is the container row, can be updated
				[removedObjects setObject:section.filtered forKey:[NSIndexPath indexPathForRow:[section.objects count] inSection:sectionIndex]];

				// Inserted rows
				for (i=0; i<len; i++) {
					[insertedObjects addObject:[section.filteredItems objectAtIndex:i]];
				}
				
			} else {
				
				// We're disabling the filter, so we're going to be adding rows
				// and possibly inserting the whole section
				if ([section.objects count] == 0) {
					// This indicates that we've just added all the objects from the
					// filtered list. And as we previously we're showing the container
					// then the section would not have been displayed either.
					// So insert the section
					[insertedSections addObject:section];
				}
				
				// Insert all the rows
				for (id obj in section.filteredItems) {
					[insertedObjects addObject:obj];
				}
				
			}
			
			// Add all the filtered objects to the section's normal objects
			// We don't remove the filtered items just yet, because we need them 
			// to test against.
			for(id obj in section.filteredItems) {
				[section addObject:obj];
			} 
			
			// Remove all the filtered items from the section
			[section setFilteredItems:nil];			
			
		} else {
			
			NSLog(@"Removing filter on section: %d %@", sectionIndex, section.key);			
			
			// The filter is currently disabled, but we are going to enable it now.
			
			// Add the objects to be filtered to the filtered list. Doing it this way
			// preserves the sort ordering in the filtered list
			NSArray *tmp = [NSArray arrayWithArray:section.objects];
			for (id obj in tmp) {
				if ([filteredObjects containsObject:obj]) {
					[section addFilteredObject:obj];
					[section removeObject:obj];
				}
			}
			
			// Configure change dictionary for delegate methods
			if (showFilteredObjectsAsGroup) {
				
				// We're enabling the filter, so we're going to be removing rows
				NSUInteger i, len = [section.filteredItems count];
				
				// Remove rows
				for (i=0; i<len; i++) {
					[removedObjects setObject:[section.filteredItems objectAtIndex:i] forKey:[NSIndexPath indexPathForRow:[section.objects count] + i inSection:sectionIndex]];
				}

				// Insert the container
				[insertedObjects addObject:section.filtered];
				
			} else {
				
				// We're enabling the filter, but we're not showing the group, so we're
				// just removing rows, and possibly a section
				if ([section.objects count] == 0) {
					// This indicates that we've just added all the objects from the
					// filtered list. And as we previously we're showing the container
					// then the section would not have been displayed either.
					// So insert the section
					[removedSections setObject:section forKey:[NSNumber numberWithInteger:sectionIndex]];
				}
				
				// Remove all the rows
				NSUInteger i, len = [section.filteredItems count];
				for (i=0; i<len; i++) {
					[removedObjects setObject:[section.filteredItems objectAtIndex:i] forKey:[NSIndexPath indexPathForRow:[section.objects count] + i inSection:sectionIndex]];
				}
				
			}
			
			
			
		}		
	}

	
/*	
	// Iterate though the filtered objects
	for (id obj in filteredObjects) {
		
		// Get the object's section key, using the default if necessary
		NSString *key = nil;		
		if (_sectionNameKeyPath) {
			key = [obj valueForKeyPath:_sectionNameKeyPath];
		} else {
			key = kBSFetchedResultsControllerDefaultSectionName;
		}
		
		// Get the section object for this key
		BSFetchedResultsControllerSection *section = [_sectionsByName objectForKey:key];		
		
		// Work out what the section index is
		NSInteger sectionIndex = [_sortedSectionNames indexOfObject:section.key];
		
		if (wasToggled && !willToggle) {
			// The objects were filtered, and now they're not.
			
			// Add to the normal list
			[section addObject:obj];			
			
			// Remove from the filtered list
			[section removeFilteredObject:obj];
						
			if (showFilteredObjectsAsGroup) {
				
				// We we're previously showing the filtered group, but now we're not
				// even filtered, so we'll definitely be remove the container row
				[removedObjects setObject:section.filtered forKey:[NSIndexPath indexPathForRow:[section.objects count] inSection:sectionIndex]];
				
			} else {

				// Here we don't care about the filtered group row, but we are adding
				// a row, so we need to check if we need to insert the section
				
				if ([section.objects count] == 1) {
					// We've just added the first row
					[insertedSections addObject:section];
					section.isDisplayed = YES;
				}
			}
				
			
			// We're adding a row to the main objects
			[insertedObjects addObject:obj];			
			
			
		} else if (!wasToggled && willToggle) {
			// The objects were not filtered, and now they are.
			
			// Add the object to the filtered list
			[section addFilteredObject:obj];
			
			// Remove the object from the normal list
			[section removeObject:obj];
			
			if (showFilteredObjectsAsGroup) {
				
				// We're showing the filtered group row, we've just inserted an object
				// so we need to check if it's the first one
				if ([section.filteredItems count] == 1) {
					[insertedObjects addObject:section.filtered];
				} else {
					// Update the row
					[updatedObjects addObject:section.filtered];
				}
				
			} else {
				
				if ([section.objects count] == 0) {
					// We've just removed the last object
					[removedSections setObject:section forKey:[NSNumber numberWithInteger:sectionIndex]];
					section.isDisplayed = NO;					
				}
				
			}
			
			// We're removing a row from the main objects
			[removedObjects setObject:obj forKey:[self indexPathForObject:obj]];
			
		} else if(wasToggled && willToggle) {
			NSLog(@"Does this ever happen? 1");
			
		} else if(!wasToggled && !willToggle) {			
			NSLog(@"Does this ever happen? 2");
			
		}
		
		
	}
*/		
	
	// Update the state
	enablePostFilterTest = !enablePostFilterTest;
	
	// Update the various properties
	[_sortedSectionNames release];
	_sortedSectionNames = [[NSArray alloc] initWithArray:[self.sections valueForKeyPath:@"key"]];
	
	// Update other ordered things
	NSMutableArray *indexTitles = [[NSMutableArray alloc] init];
	NSMutableArray *allObjects = [[NSMutableArray alloc] init];
	for(NSString *key in _sortedSectionNames) {
		if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
			[indexTitles addObject:[[_sectionsByName objectForKey:key] indexTitle]];
		}
		[allObjects addObjectsFromArray:[[_sectionsByName objectForKey:key] objects]];
	}
	
	// Update the sectionIndexTitles
	[_sectionIndexTitles release];
	_sectionIndexTitles = [[NSArray alloc] initWithArray:indexTitles];
	
	// Update the fetchedResults array
	[_fetchedObjects release];
	_fetchedObjects = [[NSArray alloc] initWithArray:allObjects];
	
	[indexTitles release];
	[allObjects release];
	
	// We now need to package up the various changes into a dictionary to return	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			insertedObjects, @"InsertedObjects",
			updatedObjects, @"UpdatedObjects",
			removedObjects, @"RemovedObjects",
			movedObjects, @"MovedObjects", 
			insertedSections, @"InsertedSections", 
			removedSections, @"RemovedSections", 
			nil];	
	
	
}

// These methods will show or hide the rows which can container the filtered objects
- (NSDictionary *)showFilteredObjectsGroups {
	
	// First of all bail if the filter isn't enabled
	if (!enablePostFilterTest) {
		return [NSDictionary dictionary];
	}
	
	// This is quite easy, we don't need to analyse the the objects or anything,
	// We can just iterate through the sections, check if they've got filtered
	// objects, and then insert sections/rows as needed
	
	NSMutableSet *insertedObjects = [NSMutableSet set];
	NSMutableSet *insertedSections = [NSMutableSet set];

	for (BSFetchedResultsControllerSection *section in [_sectionsByName allValues]) {
		// Check if the section has any filtered items
		if ([section.filteredItems count] > 0) {
			// It does, so we need to insert a row
			[insertedObjects addObject:section.filtered];
			// Check to see if it doesn't have any normal objects
			if ([section.objects count] == 0) {
				// This means we need to insert a section too
				[insertedSections addObject:section];
			}
		}
	}
		
	// Update the state
	showFilteredObjectsAsGroup = YES;		
	
	// Update the various properties
	[_sortedSectionNames release];
	_sortedSectionNames = [[NSArray alloc] initWithArray:[self.sections valueForKeyPath:@"key"]];
	
	// Update other ordered things
	NSMutableArray *indexTitles = [[NSMutableArray alloc] init];
	NSMutableArray *allObjects = [[NSMutableArray alloc] init];
	for(NSString *key in _sortedSectionNames) {
		if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
			[indexTitles addObject:[[_sectionsByName objectForKey:key] indexTitle]];
		}
		[allObjects addObjectsFromArray:[[_sectionsByName objectForKey:key] objects]];
	}
	
	// Update the sectionIndexTitles
	[_sectionIndexTitles release];
	_sectionIndexTitles = [[NSArray alloc] initWithArray:indexTitles];
		
	[indexTitles release];
	[allObjects release];
	
	// We now need to package up the various changes into a dictionary to return	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			insertedObjects, @"InsertedObjects",
			insertedSections, @"InsertedSections", 
			nil];	
	
}

- (NSDictionary *)hideFilteredObjectsGroups {

	// First of all bail if the filter isn't enabled
	if (!enablePostFilterTest) {
		return [NSDictionary dictionary];
	}
	
	
	// This is quite easy, we don't need to analyse the the objects or anything,
	// We can just iterate through the sections, check if they've got filtered
	// objects, and then remove sections/rows as needed
	
	NSMutableDictionary *removedSections = [NSMutableDictionary dictionary];
	NSMutableDictionary *removedObjects = [NSMutableDictionary dictionary];
	
	for (BSFetchedResultsControllerSection *section in [_sectionsByName allValues]) {
		
		// Work out the section index
		NSUInteger sectionIndex = [_sortedSectionNames indexOfObject:section.key];
		
		// Check if the section has any filtered items
		if ([section.filteredItems count] > 0) {
			
			// It does, so we need to insert a row
			[removedObjects setObject:section.filtered forKey:[NSIndexPath indexPathForRow:[section.objects count] inSection:sectionIndex]];
			
			// Check to see if it doesn't have any normal objects
			if ([section.objects count] == 0) {
				// This means we need to remove a section too
				[removedSections setObject:section forKey:[NSNumber numberWithInteger:sectionIndex]];
			}
		}
	}
	
	// Update the state
	showFilteredObjectsAsGroup = NO;	
		
	// Update the various properties
	[_sortedSectionNames release];
	_sortedSectionNames = [[NSArray alloc] initWithArray:[self.sections valueForKeyPath:@"key"]];
	
	// Update other ordered things
	NSMutableArray *indexTitles = [[NSMutableArray alloc] init];
	NSMutableArray *allObjects = [[NSMutableArray alloc] init];
	for(NSString *key in _sortedSectionNames) {
		if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
			[indexTitles addObject:[[_sectionsByName objectForKey:key] indexTitle]];
		}
		[allObjects addObjectsFromArray:[[_sectionsByName objectForKey:key] objects]];
	}
	
	// Update the sectionIndexTitles
	[_sectionIndexTitles release];
	_sectionIndexTitles = [[NSArray alloc] initWithArray:indexTitles];
	
	[indexTitles release];
	[allObjects release];
	
	// We now need to package up the various changes into a dictionary to return	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			removedObjects, @"RemovedObjects",
			removedSections, @"RemovedSections", 
			nil];		
	
}




@end





