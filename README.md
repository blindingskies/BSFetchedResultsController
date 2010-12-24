BSFetchedResultsController
==========================

BSFetchedResultsController aims to be essentially the same as Apple's [NSFetchedResultsController](http://developer.apple.com/library/ios/#documentation/CoreData/Reference/NSFetchedResultsController_Class/Reference/Reference.html "NSFetchedResultsController") but with some added features, which are described below. Currently setting a cache is not implemented, although I do intended to add it, and until it gets implemented, then I don't consider BSFetchedResultsController to be production ready.

Motivation
----------

The motivation behind this development is that often NSFetchedResultsController is quite limiting when it comes to filtering and sorting the objects that it fetched. The predicate used can only check against Core Data properties because the objects themselves remain as faults. The fetch predicate doesn't get all of the objects of the requested entity and then filter them, it just fetched the ones that pass the filter predicate. This can therefore create problems if you need to filter some of those objects using information or key path properties computed after the object has been fetched. Additionally the class supports filtering objects using a block object of type:

    typedef BOOL(^BSFetchedResultsControllerPostFetchFilterTest)(id obj, BOOL *stop);

Similarly, performing custom sorting of objects using an NSCompartor block is supported. 