//
//  BSFetchedResultsController.h
//  BSFetchedResultsControllerExample
//
//  Created by Daniel Thorpe on 15/12/2010.
//  Copyright 2010 Blinding Skies Limited. All rights reserved.
//


/*
 
 Class Overview
 ==============
 
 This class is intended to be a drop in replacement for NSFetchedResultsController,
 while providing extra functionality. Therefore it should be configured in the same
 way as an NSFetchedResultsController using an NSFetchedResults, delegate and cache
 name.
 
 The differences are that a 2nd predicate and/or block may be provided to filter 
 the fetched results. This class has been implemented primarily for this feature, 
 because often it is necessary to not display managed objects depending on some 
 calculation that cannot be performed using an NSPredicate.
 
 Additionally, it is possible to alter the NSFetchRequest, and force a refresh of
 the fetched data.
 
 */

#import <Foundation/Foundation.h>

extern NSString * const kBSFetchedResultsControllerDefaultSectionName;
extern NSString * const kBSFetchedResultsControllerCachePath;
extern NSString * const kBSFetchedResultsControllerSectionInfoCacheName;
extern NSString * const kBSFetchedResultsControllerFetchedObjectsCacheName;
// SectionInfo Cache archive keys
extern NSString * const kBSFRCSectionInfoCacheFetchRequestKey;
extern NSString * const kBSFRCSectionInfoCacheFetchRequestEntityKey;
extern NSString * const kBSFRCSectionInfoCacheFetchRequestPredicateKey;
extern NSString * const kBSFRCSectionInfoCacheFetchRequestSortDescriptorsKey;
extern NSString * const kBSFRCSectionInfoCacheSectionNameKeyPathKey;
extern NSString * const kBSFRCSectionInfoCacheSectionsKey;
extern NSString * const kBSFRCSectionInfoCachePostFetchPredicateKey;
extern NSString * const kBSFRCSectionInfoCachePostFetchFilterKey;
extern NSString * const kBSFRCSectionInfoCachePostFetchComparatorKey;
// Individual Section cache archive keys
extern NSString *const kBSFRCSectionCacheKeyKey;
extern NSString *const kBSFRCSectionCacheNameKey;
extern NSString *const kBSFRCSectionCacheIndexTitleKey;
extern NSString *const kBSFRCSectionCacheObjectsKey;


// Define a type for a filter block
typedef BOOL(^BSFetchedResultsControllerPostFetchFilterTest)(id obj, BOOL *stop);

// Define a protocol for delegate methods
@protocol BSFetchedResultsControllerDelegate;

@class BSFetchedResultsControllerSectionInfoCache;

@interface BSFetchedResultsController : NSObject {
@private
	// These are all objects synonomous with NSFetchedResultsController
	NSFetchRequest *_fetchRequest;
	NSManagedObjectContext *_managedObjectContext;
	NSString *_sectionNameKeyPath;
	NSString *_cacheName;
	BSFetchedResultsControllerSectionInfoCache *_persistentCache;
	
	id _delegate;	
	id _fetchedObjects;
	NSMutableArray *_sortedSectionNames;
	NSMutableDictionary *_sectionsByName;
	NSMutableDictionary *_sectionNamesByObject;
	
	id _sectionIndexTitles;	

	// Additional objects	
	
	// Dispatch queue used for queuing DidChange notifications
	dispatch_queue_t didChangeQueue;
	
	// A predicate used to filter the fetched objects. This is usefuly because
	// the predicate an NSFetchRequest uses is only able to follow object keypaths
	// defined in the entity, whereas this predicate can follow keypaths defined
	// on a custom NSManagedObject subclass
	NSPredicate *postFetchFilterPredicate;
	
	// A test block which will furthermore filter objects from the result array which
	// fail the test. This block received an object, index and stop flag.
	BSFetchedResultsControllerPostFetchFilterTest postFetchFilterTest;
	
	// An NSComparator block which receives two objects and returns either 
	// NSOrderedAscending, NSOrderedDescending or NSOrderedSame
	NSComparator postFetchComparator;
	
	// Notification Handlers
	id didChangeNotificationHandler;
	BOOL handlingChange;
	
}

/* -----------------------------------------------------
           Initialization
   ----------------------------------------------------- */

- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest 
	  managedObjectContext:(NSManagedObjectContext *)context 
		sectionNameKeyPath:(NSString *)sectionNameKeyPath 
				 cacheName:(NSString *)name;

- (BOOL)performFetch:(NSError **)error;

/* NSFetchRequest instance used to do the fetching. You must not change it, its predicate, or its sort descriptor after initialization without disabling caching or calling +deleteCacheWithName.  The sort descriptor used in the request groups objects into sections. 
 */
@property (nonatomic, readonly) NSFetchRequest *fetchRequest;

/* Managed Object Context used to fetch objects. The controller registers to listen to change notifications on this context and properly update its result set and section information. 
 */
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

/* The keyPath on the fetched objects used to determine the section they belong to. 
 */
@property (nonatomic, readonly) NSString *sectionNameKeyPath;

/* Name of the persistent cached section information. Use nil to disable persistent caching, or +deleteCacheWithName to clear a cache.
 */
@property (nonatomic, readonly) NSString *cacheName;

/* Delegate that is notified when the result set changes.
 */
@property (nonatomic, assign) id< BSFetchedResultsControllerDelegate > delegate;

/* A predicate that is used to filter the objects after they have been
 fetched. */
@property (nonatomic, retain) NSPredicate *postFetchFilterPredicate;

/* A Block object which is filters objects that don't pass the test from
the result set. */
@property (nonatomic, retain) BSFetchedResultsControllerPostFetchFilterTest postFetchFilterTest;

/* An NSComparator block which sorts the objects after filtering and sectioning */
@property (nonatomic, retain) NSComparator postFetchComparator;

/* -----------------------------------------------------
			Accessing Fetched Objects
 ----------------------------------------------------- */

/* Returns the results of the fetch.
 Returns nil if the performFetch: hasn't been called.
 */
@property  (nonatomic, readonly) NSArray *fetchedObjects;

/* Returns the fetched object at a given indexPath.
 */
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

/* Returns the indexPath of a given object.
 */
-(NSIndexPath *)indexPathForObject:(id)object;


/* -----------------------------------------------------
			Section Information
 ----------------------------------------------------- */

/* Returns the corresponding section index entry for a given section name.	
 Default implementation returns the capitalized first letter of the section name.
 Developers that need different behavior can implement the delegate method -(NSString*)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName
 Only needed if a section index is used.
 */
- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName;

/* Returns the array of section index titles.
 It's expected that developers call this method when implementing UITableViewDataSource's
 - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
 
 The default implementation returns the array created by calling sectionIndexTitleForSectionName: on all the known sections.
 Developers should override this method if they wish to return a different array for the section index.
 Only needed if a section index is used.
 */
@property (nonatomic, readonly) NSArray *sectionIndexTitles;


/* Returns an array of objects that implement the NSFetchedResultsSectionInfo protocol.
 It's expected that developers use the returned array when implementing the following methods of the UITableViewDataSource protocol
 
 - (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView; 
 - (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section;
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section; 
 
 */
@property (nonatomic, readonly) NSArray *sections;





@end


@protocol BSFetchedResultsControllerDelegate <NSObject>
// These are the same in the NSFetchedResultsControllerDelegate protocol

/* Notifies the delegate that section and object changes are about to be processed and notifications will be sent.  Enables NSFetchedResultsController change tracking.
 Clients utilizing a UITableView may prepare for a batch of updates by responding to this method with -beginUpdates
 */
@optional
- (void)controllerWillChangeContent:(BSFetchedResultsController *)aController;

/* Notifies the delegate of added or removed sections.  Enables NSFetchedResultsController change tracking.
 
 controller - controller instance that noticed the change on its sections
 sectionInfo - changed section
 index - index of changed section
 type - indicates if the change was an insert or delete
 
 Changes on section info are reported before changes on fetchedObjects. 
 */
@optional
- (void)controller:(BSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type;


/* Notifies the delegate that a fetched object has been changed due to an add, remove, move, or update. Enables NSFetchedResultsController change tracking.
 controller - controller instance that noticed the change on its fetched objects
 anObject - changed object
 indexPath - indexPath of changed object (nil for inserts)
 type - indicates if the change was an insert, delete, move, or update
 newIndexPath - the destination path for inserted or moved objects, nil otherwise
 
 Changes are reported with the following heuristics:
 
 On Adds and Removes, only the Added/Removed object is reported. It's assumed that all objects that come after the affected object are also moved, but these moves are not reported. 
 The Move object is reported when the changed attribute on the object is one of the sort descriptors used in the fetch request.  An update of the object is assumed in this case, but no separate update message is sent to the delegate.
 The Update object is reported when an object's state changes, and the changed attributes aren't part of the sort keys. 
 */

@optional
- (void)controller:(BSFetchedResultsController *)aController didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath;

/* Notifies the delegate that all section and object changes have been sent. Enables NSFetchedResultsController change tracking.
 Providing an empty implementation will enable change tracking if you do not care about the individual callbacks.
 */

@optional
- (void)controllerDidChangeContent:(BSFetchedResultsController *)aController;

@end
