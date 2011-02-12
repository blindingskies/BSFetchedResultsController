//
//  RootViewController.m
//  BSFetchedResultsControllerExample
//
//  Created by Daniel Thorpe on 15/12/2010.
//  Copyright 2010 Blinding Skies Limited. All rights reserved.
//

#import "RootViewController.h"
#import "USStatesAndCities.h"
#import "State.h"
#import "City.h"

@interface RootViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end


@implementation RootViewController

@synthesize managedObjectContext=managedObjectContext_;
@synthesize fetchedResultsController;
@synthesize toggleFilter;
@synthesize showOrHideFilteredGroup;
@synthesize enableFilter, showFilteredItemGroup;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	self.title = @"US Cities";
	
	self.enableFilter = NO;
	self.showFilteredItemGroup = YES;
	
	// Create toolbar items
	UIBarButtonItem *aButton = [[UIBarButtonItem alloc] initWithTitle:@"Toggle Filter" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleFilter:)];
	self.toggleFilter = aButton;
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem *toggleShowingFilteredGroup = [[UIBarButtonItem alloc] initWithTitle:@"Show/Hide Filtered Group" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleShowingFilteredItemsGroup:)];
	if (self.showFilteredItemGroup) {
		[toggleShowingFilteredGroup setStyle:UIBarButtonItemStyleDone];
	} else {
		[toggleShowingFilteredGroup setStyle:UIBarButtonItemStyleBordered];
	}
	toggleShowingFilteredGroup.enabled = self.enableFilter; 
	self.showOrHideFilteredGroup = toggleShowingFilteredGroup;
	NSArray *items = [NSArray arrayWithObjects:toggleShowingFilteredGroup, flexibleSpace, aButton, nil];
	[aButton release];
	[flexibleSpace release];
	[toggleShowingFilteredGroup release];
	[self setToolbarItems:items animated:NO];
	
    // Set up the edit and add buttons.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject)];
    self.navigationItem.rightBarButtonItem = addButton;
    [addButton release];
	
	formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle:kCFNumberFormatterDecimalStyle];
	[formatter setAllowsFloats:NO];
	[formatter setPerMillSymbol:@","];
}


// Implement viewWillAppear: to do additional setup before the view is presented.
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
  
	id obj = [self.fetchedResultsController objectAtIndexPath:indexPath];

	if ([obj isKindOfClass:[BSFetchedResultsControllerAbstractContainer class]]) {
		// This is the filtered objects container
		cell.textLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
		cell.textLabel.text = @"Small Cities";
		cell.textLabel.textColor = [UIColor grayColor];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%d cities", [((BSFetchedResultsControllerAbstractContainer *)obj).items count]];		
		
	} else {
		
		City *city = (City *)obj;
		if(city.isCapitalValue) {
			cell.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]]; 
		} else {
			cell.textLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
		}
		cell.textLabel.text = city.name;
		cell.textLabel.textColor = [UIColor blackColor];		
		cell.detailTextLabel.text = [formatter stringFromNumber:city.population];		
	}	

}


#pragma mark -
#pragma mark Action

- (void)insertNewObject {
    
    // Create a new instance of the entity managed by the fetched results controller.
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
	
	// Insert a random city into a random state

	// Get our datastore
	USStatesAndCities *datastore = [USStatesAndCities sharedUSStatesAndCities];
	
	// Get random city data
	NSDictionary *randomCity = [datastore randomCity];
		
	while ([City cityExistsWithName:[randomCity objectForKey:@"CityName"] inContext:context]) {
		randomCity = [datastore randomCity];
	}
	
	State *aState = [State stateWithName:[randomCity objectForKey:@"StateName"] inContext:context];
	City *aCity = [City cityWithName:[randomCity objectForKey:@"CityName"] population:[randomCity objectForKey:@"CityPopulation"] inContext:context];
	if ([randomCity objectForKey:@"isCapital"]) {
		aCity.isCapitalValue = [[randomCity objectForKey:@"isCapital"] boolValue];
	}
	[aState addCitiesObject:aCity];
	aCity.state = aState;
		
	NSLog(@"Inserting %@%@ (%@) %@", aCity.name, aCity.isCapitalValue ? @"*" : @"", aState.name, aCity.population);
	
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
		
		if(error) {
			NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
			NSArray *detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
			if(detailedErrors != nil && [detailedErrors count] > 0) {
				for(NSError *detailedError in detailedErrors) {
					NSLog(@"  DetailedError: %@", [detailedError userInfo]);
				}
			}
			else {
				NSLog(@"  %@", [error userInfo]);
			}
		}
		
		
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        abort();
    }
	
	// Animate the table to the correct row
	NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:aCity];
	if (indexPath && indexPath.section != NSNotFound && indexPath.row != NSNotFound) {
		[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
	}

}


- (IBAction)toggleFilter:(id)sender {
	// Toggle the filter on the controller
	self.enableFilter = !enableFilter;
	self.fetchedResultsController.enablePostFilterTest = self.enableFilter;
	if (enableFilter) {
		[self.toggleFilter setStyle:UIBarButtonItemStyleDone];
	} else {
		[self.toggleFilter setStyle:UIBarButtonItemStyleBordered];
	}
	self.showOrHideFilteredGroup.enabled = self.enableFilter;
}

- (IBAction)toggleShowingFilteredItemsGroup:(id)sender {
	// Toggle the filter on the controller
	self.showFilteredItemGroup = !showFilteredItemGroup;
	self.fetchedResultsController.showFilteredObjectsAsGroup = self.showFilteredItemGroup;
	if (self.showFilteredItemGroup) {
		[self.showOrHideFilteredGroup setStyle:UIBarButtonItemStyleDone];
	} else {
		[self.showOrHideFilteredGroup setStyle:UIBarButtonItemStyleBordered];
	}
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {

    // Prevent new objects being added when in editing mode.
    [super setEditing:(BOOL)editing animated:(BOOL)animated];
    self.navigationItem.rightBarButtonItem.enabled = !editing;
}


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
	cell.accessibilityLabel = @"US City";
	
    return cell;
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
		id obj = [self.fetchedResultsController objectAtIndexPath:indexPath];
		if ([obj isKindOfClass:[BSFetchedResultsControllerAbstractContainer class]]) {
			// If we've got an array, it's because it's a container of filtered cities
			for (City *aCity in ((BSFetchedResultsControllerAbstractContainer *)obj).items) {
				[context deleteObject:aCity];
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


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // The table view should not be re-orderable.
    return NO;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	// Deselect the row
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"City" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"population" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];    
    [fetchRequest setSortDescriptors:sortDescriptors];
	    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    BSFetchedResultsController *aFetchedResultsController = [[BSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"state.name" cacheName:nil/*@"USStatesAndCities"*/];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
	
	
	// Add a post fetch sort comparator
	fetchedResultsController.postFetchComparator = ^(id a, id b) {
		// if the city is a capital, it always comes before non-capitals
		NSComparisonResult result = [((City *)a).isCapital compare:((City *)b).isCapital];		
		if (result != NSOrderedSame)
			return -1 * result; // Descending order

		// Compare the populations
		result = [((City *)a).population compare:((City *)b).population];		
		if (result != NSOrderedSame)
			return -1 * result; // Descending order
		
		// Fall back to names
		return [((City *)a).name caseInsensitiveCompare:((City *)b).name];				
	};	

	// Add a post fetch filter test
//	fetchedResultsController.postFetchFilterPredicate = [NSPredicate predicateWithFormat:@"population > %d", 100000];
	
	// Add a post fetch filter test
	fetchedResultsController.postFetchFilterTest = ^(id obj, BOOL *stop) {
		if ([(City *)obj populationValue] > 100000) {
			return YES;
		} else {
			return NO;
		}
	};
	
	// Set the options how how we want to access filtered objects (if at all)
	fetchedResultsController.enablePostFilterTest = self.enableFilter;	
	fetchedResultsController.showFilteredObjectsAsGroup = self.showFilteredItemGroup;

	
	
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


#pragma mark -
#pragma mark Fetched results controller delegate


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}


/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [fetchedResultsController release];
    [managedObjectContext_ release];
    [super dealloc];
}




@end

