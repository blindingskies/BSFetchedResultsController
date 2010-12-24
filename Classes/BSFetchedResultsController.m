//
//  BSFetchedResultsController.m
//  BSFetchedResultsControllerExample
//
//  Created by Daniel Thorpe on 15/12/2010.
//  Copyright 2010 Blinding Skies Limited. All rights reserved.
//

#import "BSFetchedResultsController.h"

NSString * const kBSFetchedResultsControllerDefaultSectionName = @"Default Section";

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

@interface BSFetchedResultsControllerSection : NSObject <NSFetchedResultsSectionInfo> {
@private
	NSString *key;
	NSString *_name;
	NSString *_indexTitle;
	NSUInteger _numberOfObjects;
	NSArray *_objects;
}

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
	[_name release];
	[_indexTitle release];
	[_objects release];
	[super dealloc];
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
	_objects = [someObjects retain];
	[self didChangeValueForKey:@"objects"];	
	[self willChangeValueForKey:@"numberOfObjects"];	
	_numberOfObjects = [_objects count];
	[self didChangeValueForKey:@"numberOfObjects"];
}


@end






#pragma mark -
#pragma mark BSFetchedResultsController

@interface BSFetchedResultsController ()

// NSManagedObjectContext Notification Handlers
- (void)registerNotificationHandlers;
- (void)removeNotificationHandlers;

// Perform automatic sectioning
- (NSMutableArray *)addFetchedObjects:(NSArray *)objs;
- (NSDictionary *)removeFetchedObjects:(NSArray *)objs;
- (NSDictionary *)updateFetchedObjects:(NSArray *)objs;

@end

#pragma mark -

@implementation BSFetchedResultsController

@synthesize fetchRequest=_fetchRequest;
@synthesize managedObjectContext=_managedObjectContext;
@synthesize delegate=_delegate;
@synthesize cacheName=_cacheName;
@synthesize fetchedObjects=_fetchedObjects;
@synthesize sectionNameKeyPath=_sectionNameKeyPath;
@synthesize sections=_sections;
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
		_sections = nil;		
		_sectionsByName = nil;
		_fetchedObjects = nil;
		
		// Register for notifications
		[self registerNotificationHandlers];
		handlingChange = NO;
	}
	return self;	
}

- (void)dealloc {
	[self removeNotificationHandlers];
	[_managedObjectContext release];
	[_fetchRequest release];
	[_fetchedObjects release];
	self.postFetchFilterPredicate = nil; [postFetchFilterPredicate release];
	self.postFetchFilterTest = nil; [postFetchFilterTest release];
	self.postFetchComparator = nil; [postFetchComparator release];
	[super dealloc];
}

#pragma mark -
#pragma mark Public Methods

- (BOOL)performFetch:(NSError **)error {
	// Perform the fetch
	NSError *anError = nil;
	NSArray *results = [_managedObjectContext executeFetchRequest:_fetchRequest error:&anError];	
	if(anError) {
		error = &anError;
		return NO;
	}
	
	NSLog(@"fetched %d objects", [results count]);	
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
		[self addFetchedObjects:results];
								
	}
		
	return YES;
}


- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
	BSFetchedResultsControllerSection *section = [(NSArray *)_sections objectAtIndex:indexPath.section];
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

	NSUInteger sectionIndex, rowIndex = 0;
	NSArray *objs = nil;
	if (key) {
		// The section objects
		objs = [(NSDictionary *)_sectionsByName objectForKey:key];		
		// The section index
		sectionIndex = [_sortedSectionNames indexOfObject:key];
		// The row index
		rowIndex = [objs indexOfObject:object];
	} else {

		NSUInteger numberOfSections = [_sections count];
		for (sectionIndex=0; sectionIndex<numberOfSections; sectionIndex++) {
			// Get the array of objects in the section
			objs = [(BSFetchedResultsControllerSection *)[(NSArray *)_sections objectAtIndex:sectionIndex] objects];
			
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
		}		
	}
	
	// Therefore the index path is the index of the section name, and then the index of the object
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];	
	return indexPath;
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName {
	return [[sectionName capitalizedString] substringToIndex:1];
}
									
									

#pragma mark -
#pragma mark Dynamic Methods

#pragma mark -
#pragma mark Private Methods

// Add notification handlers to NSNotificationCenter
- (void)registerNotificationHandlers {
	
	if(!didChangeNotificationHandler) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		
		/*	Register to receive DidChangeNotifications - we then analsye the contents of 
			the Inserted, Deleted and Updated objects to merge the changes with our cache
			and if set inform the delegate of the processed changes.
		 */		 
		 
		didChangeNotificationHandler = [nc addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *aNotification) {
			
			// This is the notification block, here we need to analyse the inserted, updated and deleted objects
			// and see how they impact our fetched results
			
			if(handlingChange) return;
			
			// Set that we're handing a change
			handlingChange = YES;
			
			// If we don't have a delegate, then we can return now
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
			
			// Look for inserted objects
			NSSet *insertedObjects = [[userInfo objectForKey:NSInsertedObjectsKey] filteredSetUsingPredicate:compoundPredicate];
			if(self.postFetchFilterTest) {
				insertedObjects = [insertedObjects objectsPassingTest:self.postFetchFilterTest];
			}			
			
			// If we've got inserted objects...
			if ([insertedObjects count] > 0) {
								
				// Update the sectioned objects
				NSMutableArray *addedSections = [self addFetchedObjects:[insertedObjects allObjects]];
								
				// Inform the delegate that we're about to change content
				if([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
					[self.delegate controllerWillChangeContent:self];

				if([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {

					// Iterate through the inserted cells
					for(id obj in insertedObjects) {
						
						// Get the index path for this object 
						NSIndexPath *indexPath = [self indexPathForObject:obj];
						
						// Get the sectional object for this object
						BSFetchedResultsControllerSection *aSection = [(NSArray *)_sections objectAtIndex:indexPath.section];
						
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
				
				// Inform the delegate that we've finished changing content
				if([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)])
					[self.delegate controllerDidChangeContent:self];				
			}
			
			
			// -- DELETED OBJECTS -- //
			
			// Look for deleted objects
			NSSet *deletedObjects = [[userInfo objectForKey:NSDeletedObjectsKey] filteredSetUsingPredicate:compoundPredicate];
			if(self.postFetchFilterTest) {
				deletedObjects = [deletedObjects objectsPassingTest:self.postFetchFilterTest];
			}
			
			// If we've got deleted objects...
			if ([deletedObjects count] > 0) {
								
				// Inform the delegate that we're about to change content
				if([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
					[self.delegate controllerWillChangeContent:self];

				if([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
					
					// Iterate through the deleted cells
					for(id obj in deletedObjects) {
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
				NSDictionary *removedSections = [self removeFetchedObjects:[deletedObjects allObjects]];				
				
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
			
			// -- UPDATED OBJECTS -- //
			
			// Look for updated objects
			NSSet *updatedObjects = [[userInfo objectForKey:NSUpdatedObjectsKey] filteredSetUsingPredicate:compoundPredicate];
			if(self.postFetchFilterTest) {
				updatedObjects = [updatedObjects objectsPassingTest:self.postFetchFilterTest];
			}
			
			// If we've got updated objects...
			if([updatedObjects count] > 0) {
								
				// Update the sectional information
				NSDictionary *changes = [self updateFetchedObjects:[updatedObjects allObjects]];				
				
				// Inform the delegate that we're about to change content
				if([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
					[self.delegate controllerWillChangeContent:self];				
				
				// Perform sectional insertions
				NSMutableArray *addedSections = [changes objectForKey:@"addedSections"];
				for(BSFetchedResultsControllerSection *aSection in addedSections) {
					
					// We need to tell the delegate to insert a section
					[self.delegate controller:self 
							 didChangeSection:aSection 
									  atIndex:[_sections indexOfObject:aSection] 
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
				
				// Inform the delegate that we've finished changing content
				if([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)])
					[self.delegate controllerDidChangeContent:self];
			}
			
			// Set that we've finished handing a change
			handlingChange = NO;			
		}];
	}
}

// Remove the notification handlers from the NSNotificationCenter
- (void)removeNotificationHandlers {
	if(didChangeNotificationHandler) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc removeObserver:didChangeNotificationHandler];		
	}
}

- (NSMutableArray *)addFetchedObjects:(NSArray *)objs {

	// This will update the BSFetchedResultsController members with the objects
	// This function is called during a performFetch, to initally setup the
	// fetched objects. It is also called during the DidChangeNotification
	// handler to perform updates.
	
	// First of all section the objects
	
	NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:_sectionsByName];
	
	// Enumerate the objects and put them into the dictionary sections
	[objs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		
		// If there isn't a section key path, use the default key
		NSString *key = nil;		
		if(_sectionNameKeyPath) {
			key = [obj valueForKeyPath:_sectionNameKeyPath];
		} else {
			key = kBSFetchedResultsControllerDefaultSectionName;
		}

		// Get the mutable array of objects for this section
		NSMutableArray *sectionObjs = [dic objectForKey:key];		
		
		// Create this array if it doesn't exist yet
		if(!sectionObjs) {
			sectionObjs = [NSMutableArray array];
			[dic setObject:sectionObjs forKey:key];
		}
		
		// Add the object to the section's array
		[sectionObjs addObject:obj];
		
	}];
		
	// We need to sort the sections
	NSArray *updatedSectionNames = [[dic allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	// We can now create our section info objects
	NSMutableArray *theSections = [NSMutableArray array];
	NSMutableArray *allObjects = [NSMutableArray array];
	NSMutableArray *addedSections = [NSMutableArray array];
	
	for(NSString *key in updatedSectionNames) {
				
		// Resort the objects within the section		
		NSMutableArray *sortedObjs = [dic objectForKey:key];
		[sortedObjs sortUsingDescriptors:[_fetchRequest sortDescriptors]];
		if(self.postFetchComparator) {
			[sortedObjs sortUsingComparator:self.postFetchComparator];
		}		
		[dic setObject:sortedObjs forKey:key];
				
		// Create a Section object
		BSFetchedResultsControllerSection *aSection = [[[BSFetchedResultsControllerSection alloc] init] autorelease];
		if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
			aSection.key = key;
			[aSection setName:[key capitalizedString]];
			[aSection setIndexTitle:[self sectionIndexTitleForSectionName:aSection.name]];			
		}
		[aSection setObjects:sortedObjs];
		[theSections addObject:aSection];
		
		// See if this is a new section
		if (![_sortedSectionNames containsObject:key]) {
			[addedSections addObject:aSection];
		}		
		
		// Add all the objects
		[allObjects addObjectsFromArray:sortedObjs];
	}
	
	// Update the sortedSectionNames
	[_sortedSectionNames release];
	_sortedSectionNames = [[NSArray alloc] initWithArray:[[dic allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];	
	
	// Update the section objects
	[_sections release];
	_sections = [[NSArray alloc] initWithArray:theSections];
	
	// Update the sectionIndexTitles
	[_sectionIndexTitles release];
	_sectionIndexTitles = [[NSArray alloc] initWithArray:[_sections valueForKeyPath:@"indexTitle"]];
	
	// Update the _sectionsByName dictionary
	[_sectionsByName release];
	_sectionsByName = [[NSDictionary alloc] initWithDictionary:dic];	
	
	// Update the fetchedResults array
	[_fetchedObjects release];
	_fetchedObjects = [[NSArray alloc] initWithArray:allObjects];
	
	return addedSections;
}


- (NSDictionary *)removeFetchedObjects:(NSArray *)objs {
	
	// Get a mutable dictionary of the sections
	NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)_sectionsByName];
	
	// Iterate through the array of objs
	for (id obj in objs) {
		
		// Get the key
		// If there isn't a section key path, use the default key
		NSString *key = nil;		
		if(_sectionNameKeyPath) {
			key = [obj valueForKeyPath:_sectionNameKeyPath];
		} else {
			key = kBSFetchedResultsControllerDefaultSectionName;
		}
		
		NSUInteger sectionIndex;
		NSMutableArray *sectionObjects = nil;

		if (key) {
			
			// The section objects
			sectionObjects = [dic objectForKey:key];		
			// The section index
			sectionIndex = [_sortedSectionNames indexOfObject:key];
			
		} else {
			
			NSUInteger numberOfSections = [_sections count];
			for (sectionIndex=0; sectionIndex<numberOfSections; sectionIndex++) {
				
				// Get the array of objects in the section
				BSFetchedResultsControllerSection *aSection = [(NSArray *)_sections objectAtIndex:sectionIndex];
				sectionObjects = [NSMutableArray arrayWithArray:aSection.objects];
				
				// Enumerate over the array using a block to find indexes passing a test
				NSIndexSet *indexes = [sectionObjects indexesOfObjectsPassingTest:^(id anObj, NSUInteger idx, BOOL *stop) {
					// Here we can check to see if the object id of anObj matches obj and if so return 
					return [[obj objectID] isEqual:[anObj objectID]];
				}];
				
				// Now we need to check to see if we have a value in the index set
				if ([indexes count] > 0) {
					key = aSection.key;
					break;
				}
			}
		}
					
		// Remove the object from the various arrays
		[sectionObjects removeObject:obj];
		[dic setObject:sectionObjects forKey:key];
		
		[[_sections objectAtIndex:sectionIndex] setObjects:sectionObjects];
		
		// If the count is now zero (we just removed the last object), then we need to remove the 
		// key too
		if([sectionObjects count] == 0) {
			[dic removeObjectForKey:key];
		}
	}
	
	// Check to see if the number of sections has changed
	NSArray *updatedSectionNames = [[dic allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	// We can now create our section info objects
	NSMutableArray *theSections = [NSMutableArray array];
	NSMutableArray *allObjects = [NSMutableArray array];
	NSMutableDictionary *removedSections = [NSMutableDictionary dictionary];
	
	for(NSString *key in updatedSectionNames) {
		
		// Resort the objects within the section		
		NSMutableArray *sortedObjs = [dic objectForKey:key];
		[sortedObjs sortUsingDescriptors:[_fetchRequest sortDescriptors]];
		if (self.postFetchComparator) {
			[sortedObjs sortUsingComparator:self.postFetchComparator];
		}
		[dic setObject:sortedObjs forKey:key];
		
		// Create a Section object
		BSFetchedResultsControllerSection *aSection = [[[BSFetchedResultsControllerSection alloc] init] autorelease];
		if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
			aSection.key = key;
			[aSection setName:[key capitalizedString]];
			[aSection setIndexTitle:[self sectionIndexTitleForSectionName:aSection.name]];			
		}
		[aSection setObjects:sortedObjs];
		[theSections addObject:aSection];
		
		// Add all the objects
		[allObjects addObjectsFromArray:sortedObjs];
	}

	for (NSString *key in _sortedSectionNames) {
		if(![updatedSectionNames containsObject:key]) {
			// Get the index of the section
			NSUInteger sectionIndex = [(NSArray *)_sortedSectionNames indexOfObject:key];				
			[removedSections setObject:[_sections objectAtIndex:sectionIndex] forKey:[NSNumber numberWithInteger:sectionIndex]];
		}
	}

	// Update the section objects
	[_sections release];
	_sections = [[NSArray alloc] initWithArray:theSections];

	// Update the sectionIndexTitles
	[_sectionIndexTitles release];
	_sectionIndexTitles = [[NSArray alloc] initWithArray:[_sections valueForKeyPath:@"indexTitle"]];

	// Update the sorted section names
	[_sortedSectionNames release];
	_sortedSectionNames = [[NSArray alloc] initWithArray:updatedSectionNames];		

	// Update the fetchedResults array
	[_fetchedObjects release];
	_fetchedObjects = [[NSArray alloc] initWithArray:allObjects];	
	
	// Update the _sectionsByName dictionary
	[_sectionsByName release];
	_sectionsByName = [[NSDictionary alloc] initWithDictionary:dic];	
	
	return removedSections;	
}


- (NSDictionary *)updateFetchedObjects:(NSArray *)objs {

	// All we really need to do here is check to see if the sort ordering
	// or sectioning has changed. To do this we're going to need to do 
	// some exhaustive searching.
	
	// Get a mutable dictionary of the sections
	NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)_sectionsByName];	
	
	// Some objects that we're going to return
	NSMutableDictionary *movedObjects = [NSMutableDictionary dictionary];
	NSMutableDictionary *removedSections = [NSMutableDictionary dictionary];
	NSMutableArray *addedSections = [NSMutableArray array];
	
	// Loop through the array of objects
	
	for(id obj in objs) {
			
		// Get the key
		// If there isn't a section key path, use the default key
		NSString *key = nil;		
		if(_sectionNameKeyPath) {
			key = [obj valueForKeyPath:_sectionNameKeyPath];
		} else {
			key = kBSFetchedResultsControllerDefaultSectionName;
		}
		
		if ( ![[dic objectForKey:key] containsObject:obj] ) {

			// This object is not in the section that it should be, so it must be 
			// somewhere else
			
			NSMutableArray *oldSectionObjects = nil;
			
			// We need to find it by looking through all the sections
			NSUInteger rowIndex = 0;
			NSString *oldKey = nil;
			BOOL flag = NO;
			for (NSString *aKey in dic) {
				// Get the array of objects in the section
				oldSectionObjects = [dic objectForKey:aKey];
				
				// Enumerate over the array using a block to find indexes passing a test
				NSIndexSet *indexes = [oldSectionObjects indexesOfObjectsPassingTest:^(id anObj, NSUInteger idx, BOOL *stop) {
					// Here we can check to see if the object id of anObj matches obj and if so return 
					return [[obj objectID] isEqual:[anObj objectID]];
				}];
				
				// Now we need to check to see if we have a value in the index set
				if ([indexes count] > 0) {
					rowIndex = [indexes firstIndex];
					oldKey = aKey;
					flag = YES;
					break;
				}
			}
			
			// Check the flag
			if (flag) {
				
				// Add the old index path of the object to the moved objects dictionary.
				// We put the obj in the object to avoid performing a copy.
				[movedObjects setObject:obj forKey:[NSIndexPath indexPathForRow:rowIndex inSection:[(NSArray *)_sortedSectionNames indexOfObject:oldKey]]];
					
				// Get the mutable array of objects for this section
				NSMutableArray *newSectionObjs = [dic objectForKey:key];
				
				// Create this array if it doesn't exist yet
				if(!newSectionObjs) {
					newSectionObjs = [NSMutableArray array];
					[dic setObject:newSectionObjs forKey:key];
				}
				
				// Add the object to the section's array
				[newSectionObjs addObject:obj];				
								
				// Now we can remove the old object from the section objects
				[oldSectionObjects removeObject:obj];
				// If the count is now zero (we just removed the last object), then we need to remove the 
				// key too
				if([oldSectionObjects count] == 0) {
					[dic removeObjectForKey:oldKey];
				}
				
				
			} else {
				// There is a problem here as we failed to find the object in the sectional information
				NSLog(@"There is a bug here somewhere as we're not finding the objects which have changed sections");
				
			}			
		} else {
			// The section hasn't changed, but it's likely that the sort ordering will still change
			// so... we need to save the old index
			[movedObjects setObject:obj forKey:[self indexPathForObject:obj]];
			
		} // End of sectionNameKeyPath check 
		
	} // End of iteration through the objects
	
	// Update the various data structures
	
	// Check to see if the number of sections has changed
	NSArray *updatedSectionNames = [[dic allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	// We can now create our section info objects
	NSMutableArray *theSections = [NSMutableArray array];
	NSMutableArray *allObjects = [NSMutableArray array];
	
	for(NSString *key in updatedSectionNames) {
		
		// Resort the objects within the section		
		NSMutableArray *sortedObjs = [dic objectForKey:key];
		[sortedObjs sortUsingDescriptors:[_fetchRequest sortDescriptors]];
		if(self.postFetchComparator) {
			[sortedObjs sortUsingComparator:self.postFetchComparator];
		}		
		[dic setObject:sortedObjs forKey:key];
		
		// Create a Section object
		BSFetchedResultsControllerSection *aSection = [[[BSFetchedResultsControllerSection alloc] init] autorelease];
		if( ![key isEqualToString:kBSFetchedResultsControllerDefaultSectionName] ) {
			aSection.key = key;
			[aSection setName:[key capitalizedString]];
			[aSection setIndexTitle:[self sectionIndexTitleForSectionName:aSection.name]];			
		}
		[aSection setObjects:sortedObjs];
		[theSections addObject:aSection];
		
		// See if this is a new section
		if (![_sortedSectionNames containsObject:key]) {
			[addedSections addObject:aSection];
		}		
		// Add all the objects
		[allObjects addObjectsFromArray:sortedObjs];
	}
	
	// Need to look out for deleted sections too
	for (NSString *key in _sortedSectionNames) {
		if(![updatedSectionNames containsObject:key]) {
			// Get the index of the section
			NSUInteger sectionIndex = [(NSArray *)_sortedSectionNames indexOfObject:key];				
			[removedSections setObject:[_sections objectAtIndex:sectionIndex] forKey:[NSNumber numberWithInteger:sectionIndex]];
		}
	}
	
	
	// Update the sortedSectionNames
	[_sortedSectionNames release];
	_sortedSectionNames = [[NSArray alloc] initWithArray:[[dic allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];	
	
	// Update the section objects
	[_sections release];
	_sections = [[NSArray alloc] initWithArray:theSections];
	
	// Update the sectionIndexTitles
	[_sectionIndexTitles release];
	_sectionIndexTitles = [[NSArray alloc] initWithArray:[_sections valueForKeyPath:@"indexTitle"]];
	
	// Update the _sectionsByName dictionary
	[_sectionsByName release];
	_sectionsByName = [[NSDictionary alloc] initWithDictionary:dic];	
	
	// Update the fetchedResults array
	[_fetchedObjects release];
	_fetchedObjects = [[NSArray alloc] initWithArray:allObjects];
	
	
	
	// We now need to package up the various changes into a dictionary to return	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			movedObjects, @"movedObjects", 
			addedSections, @"addedSections", 
			removedSections, @"removedSections", 
			nil];
}








@end































