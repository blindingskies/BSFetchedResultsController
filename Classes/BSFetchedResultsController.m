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

#pragma mark NSArray categories

// Add a category to NSArray to filter using such a filter block
@interface NSArray (NSArray_BSFetchedResultsControllerAdditions)
- (NSArray *)objectsPassingTest:(BSFetchedResultsControllerPostFetchFilterTest)test;
@end

// The implementation of the NSArray category method
@implementation NSArray (NSArray_BSFetchedResultsControllerAdditions)

- (NSArray *)objectsPassingTest:(BSFetchedResultsControllerPostFetchFilterTest)test {
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

@end

#pragma mark -
#pragma mark BSFetchedResultsControllerSection

@interface BSFetchedResultsControllerSection : NSObject <NSFetchedResultsSectionInfo, NSCoding> {
@private
	NSString *key;
	NSString *_name;
	NSString *_indexTitle;
	NSUInteger _numberOfObjects;
	NSMutableArray *_objects;
}

// Adds an object to the array of objects
- (void)addObject:(id)obj;
- (void)removeObject:(id)obj;

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

@end


@implementation BSFetchedResultsControllerSection

@synthesize key;
@synthesize name=_name;
@synthesize indexTitle=_indexTitle;
@synthesize numberOfObjects=_numberOfObjects;
@synthesize objects=_objects;

- (void)dealloc {
	[key release];
	[_name release];
	[_indexTitle release];
	[_objects release];
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
		_numberOfObjects = [_objects count];		
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
	[self willChangeValueForKey:@"objects"];	
	[_objects release];
	_objects = [[NSMutableArray alloc] initWithArray:someObjects];
	[self didChangeValueForKey:@"objects"];	
	[self willChangeValueForKey:@"numberOfObjects"];	
	_numberOfObjects = [_objects count];
	[self didChangeValueForKey:@"numberOfObjects"];
}

- (void)addObject:(id)obj {
	[self willChangeValueForKey:@"objects"];	
	// Add the object
	[_objects addObject:obj];
	[self didChangeValueForKey:@"objects"];	
	[self willChangeValueForKey:@"numberOfObjects"];	
	_numberOfObjects = [_objects count];
	[self didChangeValueForKey:@"numberOfObjects"];	
}

- (void)removeObject:(id)obj {
	[self willChangeValueForKey:@"objects"];	
	// Remove the object
	[_objects removeObject:obj];
	[self didChangeValueForKey:@"objects"];	
	[self willChangeValueForKey:@"numberOfObjects"];	
	_numberOfObjects = [_objects count];
	[self didChangeValueForKey:@"numberOfObjects"];		
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

// Perform automatic sectioning
- (NSMutableArray *)insertObjects:(NSArray *)objs;
- (NSDictionary *)removeObjects:(NSArray *)objs;
- (NSDictionary *)updateObjects:(NSArray *)objs;

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

@synthesize postFetchFilterPredicate;
@synthesize postFetchFilterTest;
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
		_managedObjectContext = [context retain];
		_fetchRequest = [aFetchRequest copy];
		if(aSectionNameKeyPath) {
			_sectionNameKeyPath = [aSectionNameKeyPath copy];
		}
		_cacheName = [aName copy];
		
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
		}
		
		// Perform sectioning
		[self insertObjects:results];
								
	}
	
	// If we've got a cache name, write to it
	if(_cacheName) {
		[self writeCache];
	}
		
	return YES;
}


- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
	BSFetchedResultsControllerSection *section = [_sectionsByName objectForKey:[_sortedSectionNames objectAtIndex:indexPath.section]];
	return [[section objects] objectAtIndex:indexPath.row];
}

-(NSIndexPath *)indexPathForObject:(id)object {
	// If there isn't a section key path, use the default key
	NSString *key = nil;		
	if(_sectionNameKeyPath) {
		key = [object valueForKeyPath:_sectionNameKeyPath];
	} else {
		key = kBSFetchedResultsControllerDefaultSectionName;
	}

	BSFetchedResultsControllerSection *section = nil;
	NSUInteger sectionIndex, rowIndex = 0;
	NSArray *objs = nil;
	if (key) {
		// The section objects
		section = [_sectionsByName objectForKey:key];
		// The section index
		sectionIndex = [_sortedSectionNames indexOfObject:key];
		// The row index
		rowIndex = [section.objects indexOfObject:object];
	} else {
			
		NSUInteger numberOfSections = [_sectionsByName count];
		for (sectionIndex=0; sectionIndex<numberOfSections; sectionIndex++) {
			// Get the array of objects in the section
			objs = [(BSFetchedResultsControllerSection *)[_sectionsByName objectForKey:[_sortedSectionNames objectAtIndex:sectionIndex]] objects];
			
			// Enumerate over the array using a block to find indexes passing a test
			NSIndexSet *indexes = [objs indexesOfObjectsPassingTest:^(id anObj, NSUInteger idx, BOOL *stop) {
				// Here we can check to see if the object id of anObj matches obj and if so return 
				return [[object objectID] isEqual:[anObj objectID]];
			}];
			
			// Now we need to check to see if we have a value in the index set
			if ([indexes count] > 0) {
				rowIndex = [indexes firstIndex];
				break;
			}
		} // End of for		
	} // End of key check
	
	// Therefore the index path is the index of the section name, and then the index of the object
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];	
	return indexPath;
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName {
	return [[sectionName capitalizedString] substringToIndex:1];
}

#pragma mark -
#pragma mark Dynamic Methods

- (NSArray *)sections {
	return [[_sectionsByName allValues] sortedArrayUsingComparator:^(id a, id b) {
		return [((BSFetchedResultsControllerSection *)a).key caseInsensitiveCompare:((BSFetchedResultsControllerSection *)b).key];
	}];
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
	
	// Various block definitions that we add to the queue for each notification
	void (^insertHandler)(NSSet *insertedObjects) = ^(NSSet *insertedObjects) {
		
		// Update the sectioned objects
		NSMutableArray *addedSections = [self insertObjects:[insertedObjects allObjects]];
		
		if([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
			
			// Iterate through the inserted cells
			for(id obj in insertedObjects) {
				
				// Get the index path for this object 
				NSIndexPath *indexPath = [self indexPathForObject:obj];
				
				// Get the sectional object for this object
				BSFetchedResultsControllerSection *aSection = [_sectionsByName objectForKey:[_sortedSectionNames objectAtIndex:indexPath.section]];
				
				// Check to see if this obj resulted in an added section
				if ([addedSections containsObject:aSection]) {
					
					// We need to tell the delegate to insert a section
					[self.delegate controller:self 
							 didChangeSection:aSection 
									  atIndex:indexPath.section 
								forChangeType:NSFetchedResultsChangeInsert];
					
					// Now that we've inserted the section, remove it from the array
					[addedSections removeObject:aSection];							
				}						
				
				[self.delegate controller:self 
						  didChangeObject:obj 
							  atIndexPath:nil 
							forChangeType:NSFetchedResultsChangeInsert 
							 newIndexPath:indexPath];							
			}
		}
				
	};
	
	void (^removeHandler)(NSSet *removedObjects) = ^(NSSet *removedObjects) {
		
		if([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
			
			// Iterate through the deleted cells
			for(id obj in removedObjects) {
				// Get the index path for this object 
				NSIndexPath *indexPath = [self indexPathForObject:obj];
				
				[self.delegate controller:self 
						  didChangeObject:obj 
							  atIndexPath:indexPath 
							forChangeType:NSFetchedResultsChangeDelete 
							 newIndexPath:nil];
			}					
		}				
		
		// Remove the deleted objects
		NSDictionary *removedSections = [self removeObjects:[removedObjects allObjects]];				
		
		for(BSFetchedResultsControllerSection *aSection in [removedSections allValues]) {
			
			// Get the index of the section
			NSUInteger sectionIndex = [[[removedSections allKeysForObject:aSection] lastObject] integerValue];
			
			// Inform the delegate that we've got to remove this section
			[self.delegate controller:self 
					 didChangeSection:aSection 
							  atIndex:sectionIndex 
						forChangeType:NSFetchedResultsChangeDelete];
			
		}
		
	};
	
	void (^updatedHandler)(NSSet *updatedObjects) = ^(NSSet *updatedObjects) {
		
		// Update the sectional information
		NSDictionary *changes = [self updateObjects:[updatedObjects allObjects]];				
		
		// Perform sectional insertions
		NSMutableArray *addedSections = [changes objectForKey:@"insertedSections"];
		for(BSFetchedResultsControllerSection *aSection in addedSections) {
			
			// We need to tell the delegate to insert a section
			[self.delegate controller:self 
					 didChangeSection:aSection 
							  atIndex:[_sortedSectionNames indexOfObject:aSection.key] 
						forChangeType:NSFetchedResultsChangeInsert];					
		}
		
		if([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
			
			// Iterate through the deleted cells
			for(id obj in updatedObjects) {
				
				// Get the old index
				NSIndexPath *indexPath = [[[changes objectForKey:@"movedObjects"] allKeysForObject:obj] lastObject];
				
				// Get the new index
				NSIndexPath *newIndexPath = [self indexPathForObject:obj];
				
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
					
					[self.delegate controller:self 
							  didChangeObject:obj 
								  atIndexPath:newIndexPath 
								forChangeType:NSFetchedResultsChangeUpdate 
								 newIndexPath:nil];
					
				}						
			}
		}				
		
		// Perform sectional deletions
		NSDictionary *removedSections = [changes objectForKey:@"removedSections"];
		for(BSFetchedResultsControllerSection *aSection in [removedSections allValues]) {
			
			// Get the index of the section
			NSUInteger sectionIndex = [[[removedSections allKeysForObject:aSection] lastObject] integerValue];
			
			// Inform the delegate that we've got to remove this section
			[self.delegate controller:self 
					 didChangeSection:aSection 
							  atIndex:sectionIndex 
						forChangeType:NSFetchedResultsChangeDelete];
			
		}
		
	};
	
	
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
				
		
		
		
		
		// -- INSERTED OBJECTS -- //		

		NSSet *insertedObjects = [[userInfo objectForKey:NSInsertedObjectsKey] filteredSetUsingPredicate:compoundPredicate];
		if(self.postFetchFilterTest) {
			insertedObjects = [insertedObjects objectsPassingTest:self.postFetchFilterTest];
		}			
		
		// If we've got inserted objects...
		if ([insertedObjects count] > 0) {
		
			// Inform the delegate that we're about to change content
			if([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
				[self.delegate controllerWillChangeContent:self];
			
			// Call our insert handler
			insertHandler(insertedObjects);

			// Inform the delegate that we've finished changing content
			if([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)])
				[self.delegate controllerDidChangeContent:self];
			
		}
		
		
		
		// -- DELETED OBJECTS -- //

		NSSet *deletedObjects = [[userInfo objectForKey:NSDeletedObjectsKey] filteredSetUsingPredicate:compoundPredicate];
		if(self.postFetchFilterTest) {
			deletedObjects = [deletedObjects objectsPassingTest:self.postFetchFilterTest];
		}
		
		// If we've got deleted objects...
		if ([deletedObjects count] > 0) {

			// Inform the delegate that we're about to change content
			if([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
				[self.delegate controllerWillChangeContent:self];
			
			// Call our remove handler
			removeHandler(deletedObjects);

			// Inform the delegate that we've finished changing content
			if([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)])
				[self.delegate controllerDidChangeContent:self];
			
		}
		
		
		
		// -- UPDATED & REFRESHED OBJECTS -- //

		
		NSSet *updatedObjects = [[[userInfo objectForKey:NSUpdatedObjectsKey] setByAddingObjectsFromSet:[userInfo objectForKey:NSRefreshedObjectsKey]] filteredSetUsingPredicate:compoundPredicate];
		if(self.postFetchFilterTest) {
			updatedObjects = [updatedObjects objectsPassingTest:self.postFetchFilterTest];
		}
		
		// If we've got updated objects...
		if([updatedObjects count] > 0) {
			
			// Inform the delegate that we're about to change content
			if([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
				[self.delegate controllerWillChangeContent:self];
			
			// Call our update handler
			updatedHandler(updatedObjects);

			// Inform the delegate that we've finished changing content
			if([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)])
				[self.delegate controllerDidChangeContent:self];
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

- (NSMutableArray *)insertObjects:(NSArray *)objs {

	// This will update the BSFetchedResultsController members with the objects
	// This function is called during a performFetch, to initally setup the
	// fetched objects. It is also called during the DidChangeNotification
	// handler to perform updates.
	
	// We maintain a dictionary of inserted objects
	NSMutableDictionary *insertedObjects = [NSMutableDictionary dictionary];
	NSMutableArray *insertedSections = [NSMutableArray array];	
	
	// Enumerate the objects and put them into the dictionary sections
	[objs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		
		// If there isn't a section key path, use the default key
		NSString *key = nil;		
		if(_sectionNameKeyPath) {
			key = [obj valueForKeyPath:_sectionNameKeyPath];
		} else {
			key = kBSFetchedResultsControllerDefaultSectionName;
		}

		// Get the section object for this key
		BSFetchedResultsControllerSection *section = [_sectionsByName objectForKey:key];
		if(!section) {
			// Create a Section object
			section = [[[BSFetchedResultsControllerSection alloc] init] autorelease];
			section.key = key;
			if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
				[section setName:[key capitalizedString]];
				[section setIndexTitle:[self sectionIndexTitleForSectionName:section.name]];			
			}
			// Add the object
			[section setObjects:[NSArray arrayWithObject:obj]];
			
			// Add the section to the array of inserted sections
			[insertedSections addObject:section];
			
			// Add the section to the dictionary
			[_sectionsByName setObject:section forKey:key];
			
		} else {
			// Add the object
			[section addObject:obj];
		}

	}];
	
	
	// Now that we've gone through and inserted all the objects, we can go through again and resort
	// We do this in two passes so that we all all the objects then do one sort, otherwise we'd do
	// unnecessary sorting

	if([_fetchRequest sortDescriptors] || self.postFetchComparator) {

		// Enumerate the objects and put them into the dictionary sections
		[objs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			
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
			
			// Get the index path of the objects
			NSIndexPath *indexPath = [self indexPathForObject:obj];
			
			// Add to the inserted objects dictionary
			[insertedObjects setObject:obj forKey:indexPath];
			
		}];
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
	
	return insertedSections;
}


- (NSDictionary *)removeObjects:(NSArray *)objs {
	
	// Here we remove objects from the results store
	// and we look out for any situation where this removed a section
	
	// We maintain a dictionary of removed objects
	NSMutableDictionary *removedSections = [NSMutableDictionary dictionary];	
	
	// Enumerate the objects we're going to remove
	for(id obj in objs) {
		
		// Work out the key. It's likely that it wont exist anymore on
		// the object, because 
		
		NSString *key = nil;
		if(_sectionNameKeyPath) {
			key = [obj valueForKeyPath:_sectionNameKeyPath];
		} else {
			key = kBSFetchedResultsControllerDefaultSectionName;
		}
		
		NSUInteger sectionIndex;
		BSFetchedResultsControllerSection *section = nil;
		
		if (key) {

			// The section
			section = [_sectionsByName objectForKey:key];			
			
			// The section index
			sectionIndex = [_sortedSectionNames indexOfObject:key];
			
		} else {
			
			NSUInteger numberOfSections = [_sectionsByName count];
			for (sectionIndex=0; sectionIndex<numberOfSections; sectionIndex++) {
				
				// Get the array of objects in the section
				section = [_sectionsByName objectForKey:[_sortedSectionNames objectAtIndex:sectionIndex]];
				
				// Enumerate over the array using a block to find indexes passing a test
				NSIndexSet *indexes = [section.objects indexesOfObjectsPassingTest:^(id anObj, NSUInteger idx, BOOL *stop) {
					// Here we can check to see if the object id of anObj matches obj and if so return 
					return [[obj objectID] isEqual:[anObj objectID]];
				}];
				
				// Now we need to check to see if we have a value in the index set
				if ([indexes count] > 0) {
					key = section.key;
					break;
				}
			}
		}
		
		// At this point we should have a 
		// key - the section key originally used
		// section - the BSFetchedResultsControllerSection object from which the obj comes from
		// sectionIndex - the index of the section being altered

		// Remove the object from the various arrays
		[section removeObject:obj];
		
		// If the count is now zero (we just removed the last object), then we need to remove the 
		// key too
		if(section.numberOfObjects == 0) {
			// Add it as a removed section
			[removedSections setObject:section forKey:[NSNumber numberWithInteger:sectionIndex]];
			
			// Remove the section
			[_sectionsByName removeObjectForKey:key];			
		}		
		
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
	
	return removedSections;	
}


- (NSDictionary *)updateObjects:(NSArray *)objs {

	// This method will get called when an object updates, but also possibly
	// when an object is being inserted. This happens when we're fetching 
	// objects which are slaves to a master (such as employee to department)
	// in the classic scenario, and we add a new slave object to an existing
	// master object. The change notification will probably be an update.
	
	NSMutableArray *insertedObjects = [NSMutableArray array];
	NSMutableDictionary *movedObjects = [NSMutableDictionary dictionary];
	NSMutableDictionary *removedSections = [NSMutableDictionary dictionary];
	NSMutableArray *insertedSections = [NSMutableArray array];
	
	
	for(id obj in objs) {
		
		NSString *key = nil;		
		if(_sectionNameKeyPath) {
			key = [obj valueForKeyPath:_sectionNameKeyPath];
		} else {
			key = kBSFetchedResultsControllerDefaultSectionName;
		}
		
		BSFetchedResultsControllerSection *section = [_sectionsByName objectForKey:key];

		if(!section) {
			// Create a Section object
			section = [[[BSFetchedResultsControllerSection alloc] init] autorelease];
			section.key = key;
			if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
				[section setName:[key capitalizedString]];
				[section setIndexTitle:[self sectionIndexTitleForSectionName:section.name]];			
			}
			// Set the objects as an empty array, we'll add the object in a moment
			[section setObjects:[NSArray array]];
			
			// Add the section to the array of inserted sections
			[insertedSections addObject:section];
			
			// Add the section to the dictionary
			[_sectionsByName setObject:section forKey:key];
		}
		
		// Check to see if the object is stored in the correct section		
		if (![section.objects containsObject:obj]) {
			// The object is not in the section it should now be in.
			// In other words, it's moved (or it's actually new)
			
			NSString *oldKey;
			
			BSFetchedResultsControllerSection *oldSection = nil;
			BOOL flag = NO;

			NSUInteger oldSectionIndex, oldRowIndex, numberOfSections = [_sectionsByName count];
			for (oldSectionIndex=0; oldSectionIndex<numberOfSections; oldSectionIndex++) {
				
				// Get the array of objects in the section
				oldSection = [_sectionsByName objectForKey:[_sortedSectionNames objectAtIndex:oldSectionIndex]];
				
				// Enumerate over the array using a block to find indexes passing a test
				NSIndexSet *indexes = [oldSection.objects indexesOfObjectsPassingTest:^(id anObj, NSUInteger idx, BOOL *stop) {
					// Here we can check to see if the object id of anObj matches obj and if so return 
					return [[obj objectID] isEqual:[anObj objectID]];
				}];
				
				// Now we need to check to see if we have a value in the index set
				if ([indexes count] > 0) {
					oldRowIndex = [indexes firstIndex];
					oldKey = oldSection.key;
					flag = YES;
					break;
				}
			}
			
			// We've finished the for loop, but we've got to check to see if we actually found
			// the object, rather than just exhaustively searched
			
			if(!flag) {
				// We didn't actually find this object
				NSLog(@"Didn't find object anywhere: %@, so assuming it's an insert.", obj);
				
				// Add the object to the array to be inserted
				[insertedObjects addObject:obj];							
				
			} else {
				
				// Add the old index path of the object to the moved objects dictionary.
				// We put the obj in the object to avoid performing a copy.
				[movedObjects setObject:obj forKey:[NSIndexPath indexPathForRow:oldRowIndex inSection:oldSectionIndex]];

				// Add the object to the new/current section
				[section addObject:obj];
								
				// Remove the object from the old section
				[oldSection removeObject:obj];

				// If the count is now zero (we just removed the last object), then we need to remove the 
				// key too
				if(oldSection.numberOfObjects == 0) {
					// Add it as a removed section
					[removedSections setObject:oldSection forKey:[NSNumber numberWithInteger:oldSectionIndex]];
					
					// Remove the section
					[_sectionsByName removeObjectForKey:oldKey];			
				}				
			} // End of flag check
			
		} else {
			// The object is in the same section, but it's likely that the ordering will, so we'll save the
			// current indexPath
			[movedObjects setObject:obj forKey:[self indexPathForObject:obj]];
		}
	}
	
	// If we've detected objects which need to be inserted we can do that now
	if ([insertedObjects count] > 0) {
		// Insert objects
		NSArray *tmp = [self insertObjects:insertedObjects];
		// If this resulted in any inserted sections, then we can add them to the array
		[insertedSections addObjectsFromArray:[tmp objectsPassingTest:^ BOOL (id obj, BOOL *stop) {
			return ![insertedSections containsObject:obj];
		}]];
	}		
	
	// Now that we've gone through and inserted all the objects, we can go through again and resort
	// We do this in two passes so that we all all the objects then do one sort, otherwise we'd do
	// unnecessary sorting
	
	if([_fetchRequest sortDescriptors] || self.postFetchComparator) {
		
		// Enumerate the objects and put them into the dictionary sections
		[objs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			
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
	
	
	// We need to work out which sections have changed
	NSArray *updatedSectionNames = [[_sectionsByName allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	// Loop through the unmodified sorted section names
	for (NSString *key in _sortedSectionNames) {
		if(![updatedSectionNames containsObject:key]) {
			// Get the index of the section
			NSUInteger sectionIndex = [(NSArray *)_sortedSectionNames indexOfObject:key];				
			[removedSections setObject:[_sectionsByName objectForKey:[_sortedSectionNames objectAtIndex:sectionIndex]] 
								forKey:[NSNumber numberWithInteger:sectionIndex]];
		}		
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
	
	// We now need to package up the various changes into a dictionary to return	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			movedObjects, @"movedObjects", 
			insertedSections, @"insertedSections", 
			removedSections, @"removedSections", 
			nil];
}








@end































