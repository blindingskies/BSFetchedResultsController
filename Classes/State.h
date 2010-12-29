#import "_State.h"

@interface State : _State {}

+ (BOOL)stateExistsWithName:(NSString *)aStateName inContext:(NSManagedObjectContext *)context;
+ (State *)stateWithName:(NSString *)aStateName inContext:(NSManagedObjectContext *)context;


@property (nonatomic, readonly) NSArray *citiesByPopulation;

@end
