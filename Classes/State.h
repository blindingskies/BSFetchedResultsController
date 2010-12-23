#import "_State.h"

@interface State : _State {}

+ (State *)stateWithName:(NSString *)aStateName inContext:(NSManagedObjectContext *)context;

@property (nonatomic, readonly) NSArray *citiesByPopulation;

@end
