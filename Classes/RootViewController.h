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
    NSManagedObjectContext *managedObjectContext_;
	
	// BSFetchedResultsController stuff
	BSFetchedResultsController *fetchedResultsController;

}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readwrite) BSFetchedResultsController *fetchedResultsController;


@end
