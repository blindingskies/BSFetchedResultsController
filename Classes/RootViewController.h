//
//  RootViewController.h
//  BSFetchedResultsControllerExample
//
//  Created by Daniel Thorpe on 15/12/2010.
//  Copyright 2010 Blinding Skies Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "BSFetchedResultsController.h"

@interface RootViewController : UITableViewController <NSFetchedResultsControllerDelegate, BSFetchedResultsControllerDelegate> {
@private
	// UI Elements
	UIBarButtonItem *toggleFilter;
	UIBarButtonItem *showOrHideFilteredGroup;
	
    NSManagedObjectContext *managedObjectContext_;
	
	// BSFetchedResultsController stuff
	BOOL enableFilter, showFilteredItemGroup;
	BSFetchedResultsController *fetchedResultsController;
	
	// Number formatter
	NSNumberFormatter *formatter;

}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) BSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, assign) UIBarButtonItem *toggleFilter;
@property (nonatomic, readwrite, assign) UIBarButtonItem *showOrHideFilteredGroup;
@property (nonatomic, readwrite) BOOL enableFilter;
@property (nonatomic, readwrite) BOOL showFilteredItemGroup;

- (IBAction)toggleFilter:(id)sender;
- (IBAction)toggleShowingFilteredItemsGroup:(id)sender;

@end
