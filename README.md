**WARNING: This project is legacy and not actively supported or maintained. Please do not use this in a production environment. It is left here for prosperity and learning purposes.**

**ADVICE: If you need a more powerful Fetched Results Controller, consider using [YapDatabase](http://github.com/yapstudios/yapdatabase) coupled with [TaylorSource](http://github.com/danthorpe/taylorsource).**

BSFetchedResultsController
==========================

BSFetchedResultsController aims to be essentially the same as Apple's [NSFetchedResultsController](http://developer.apple.com/library/ios/#documentation/CoreData/Reference/NSFetchedResultsController_Class/Reference/Reference.html "NSFetchedResultsController") but with some added features, which are described below. Currently setting a cache is not implemented, although I do intended to add it, and until it gets implemented, then I don't consider BSFetchedResultsController to be production ready.

Motivation
----------

The motivation behind this development is that often NSFetchedResultsController is quite limiting when it comes to filtering and sorting the objects that it fetched. The predicate used can only check against Core Data properties because the objects themselves remain as faults. The fetch predicate doesn't get all of the objects of the requested entity and then filter them, it just fetched the ones that pass the filter predicate. This can therefore create problems if you need to filter some of those objects using information or key path properties which are only available after the object has been fetched from the datastore. 

Additionally the class supports filtering objects using a block object of type:

    typedef BOOL(^BSFetchedResultsControllerPostFetchFilterTest)(id obj, BOOL *stop);

which should return YES to keep obj, and NO to reject it. Similarly, the controller accepts an NSComparator which can be used to perform complex sorting after the objects have been fetched (I know that NSSortDescriptor accepts blocks, but this is for post fetch sorting).

Configuration
-------------

The filter can be enabled on the fly after the controller has called performFetch:. This will automatically trigger the delegate methods (which are the same format as `NSFetchedResultsController`) to update the table. This means, that if rows (and possibly sections) will be removed and inserted as necessary.

In some bases a developer might wish to summarise the objects which failed the filter test in the table. BSFetchedResultsController allows this (if set) by returning an extra row for every section which contains filtered objects. When fetching the object at this index path from the controller, the table datasource will receive a BSFetchedResultsControllerAbstractContainer instance which has an NSArray items property, containing the filtered objects. The ordering of objects in this container is guaranteed.

Example usage
-------------

The example application that this repository contains gives a fully featured albeit trivial demonstration of what `BSFetchedResultsController` can do, but essentially, to use the class instead of `NSFetchedResultsController`, from within a `UITableViewController` subclass, your code should look a bit like this:

First of all, define the class

	#import "BSFetchedResultsController.h"

	@interface RootViewController : UITableViewController <BSFetchedResultsControllerDelegate> {
		@private
			// The managed object context we're going to use
    		NSManagedObjectContext *managedObjectContext;	

			// The fetched results controller
			BSFetchedResultsController *fetchedResultsController;
		}

		@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
		@property (nonatomic, readwrite, retain) BSFetchedResultsController *fetchedResultsController;

	@end

In the implementation, use the following method to return the controller:

	#pragma mark -
	#pragma mark Fetched results controller

	- (BSFetchedResultsController *)fetchedResultsController {
		if(fetchedResultsController != nil) {
			return fetchedResultsController;
		}
	
		// Setup the BSFetchedResultsController
	    // Create the fetch request for the entity.
	    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	    // Edit the entity name as appropriate.
	    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyEntity" inManagedObjectContext:self.managedObjectContext];
	    [fetchRequest setEntity:entity];
    
	    // Edit the sort key as appropriate.
	    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"mySortKey" ascending:NO];
	    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];    
	    [fetchRequest setSortDescriptors:sortDescriptors];
	    
	    // Edit the section name key path and cache name if appropriate.
	    // nil for section name key path means "no sections".
	    BSFetchedResultsController *aFetchedResultsController = [[BSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"state.name" cacheName:@"CacheName"];
	
		// Set the delegate
	    aFetchedResultsController.delegate = self;
	
		// Retain a reference to the controller
	    self.fetchedResultsController = aFetchedResultsController;
    
		// Release memory
	    [aFetchedResultsController release];
	    [fetchRequest release];
	    [sortDescriptor release];
	    [sortDescriptors release];
		
		// Add a post fetch sort comparator
		fetchedResultsController.postFetchComparator = ^(id a, id b) {
			// Return a complex comparison function, or whatever
			return [(MyEntity *)a compare:(MyEntity *)b];				
		};	
					
		// Add a post fetch filter test
		fetchedResultsController.postFetchFilterTest = ^(id obj, BOOL *stop) {
			// Use a special calculated property (returning YES or NO)
			return [(MyEntity *)obj specialCalculation];
		};
	
		// Set the options how how we want to access filtered objects (if at all)
		// These can be changed whenever
		fetchedResultsController.enablePostFilterTest = YES;	
		fetchedResultsController.showFilteredObjectsAsGroup = YES;
	
	    NSError *error = nil;
	    if (![fetchedResultsController performFetch:&error]) {
	        /*
	         Replace this implementation with code to handle the error appropriately.
         
	         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
	         */
	        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	        abort();
	    }
    
	    return fetchedResultsController;
	}


Then, in the `UITableViewDataSource` methods, just use the `BSFetchedResultsController` as you would an `NSFetchedResultsController`, with some caveats.

	#pragma mark -
	#pragma mark Table view data source

	- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
		return [[self.fetchedResultsController sections] count];
	}


	- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
		NSUInteger numberOfObjs = [sectionInfo numberOfObjects];
		return numberOfObjs;
	}

	- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
		return [sectionInfo name];
	}

	// Customize the appearance of table view cells.
	- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	    static NSString *CellIdentifier = @"Cell";
    
	    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	    if (cell == nil) {
	        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
	    }
    
	    // Configure the cell.
	    [self configureCell:cell atIndexPath:indexPath];
    
		cell.isAccessibilityElement = YES;
		cell.accessibilityLabel = @"A Thing";
	
	    return cell;
	}

Note here, that because we have asserted both `enablePostFilterTest` and `showFilteredObjectsAsGroup`, that when configuring a cell, we need to check if the object is the abstract container for the filtered objects

	- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {

		id obj = [self.fetchedResultsController objectAtIndexPath:indexPath];

		if ([obj isKindOfClass:[BSFetchedResultsControllerAbstractContainer class]]) {
			// This is the filtered objects container
			cell.textLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
			cell.textLabel.text = @"A collection of things which didn't pass muster";
			cell.textLabel.textColor = [UIColor grayColor];
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [((BSFetchedResultsControllerAbstractContainer *)obj).items valueForKeyPath:"@@sum.aMeaninglessMetric"]];		

		} else {

			MyEntity *thing = (MyEntity *)obj;

			cell.textLabel.text = thing.someTextValue;
			cell.textLabel.textColor = [UIColor blackColor];
			cell.detailTextLabel.text = [city.aMeaninglessMetric stringValue];		
		}	

	}


Also note, that special consideration must be taken if using the above configuration when committing the editing style:

	// Override to support editing the table view.
	- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
	    if (editingStyle == UITableViewCellEditingStyleDelete) {
	        // Delete the managed object for the given index path
	        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
			id obj = [self.fetchedResultsController objectAtIndexPath:indexPath];
			if ([obj isKindOfClass:[BSFetchedResultsControllerAbstractContainer class]]) {
				// We've got a container of filtered things
				for (MyEntity *aThing in ((BSFetchedResultsControllerAbstractContainer *)obj).items) {
					[context deleteObject:aThing];
				}
			} else {
				[context deleteObject:obj];
			}
        
	        // Save the context.
	        NSError *error = nil;
	        if (![context save:&error]) {
	            /*
	             Replace this implementation with code to handle the error appropriately.
             
	             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
	             */
	            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	            abort();
	        }
	    }   
	}
