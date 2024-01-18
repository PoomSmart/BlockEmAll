#import <Foundation/Foundation.h>

#define PROCEDURES1 \
NSError *error = nil; \
NSArray *rules = [NSJSONSerialization JSONObjectWithData:[encodedContentRuleList dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error]; \
if (!error) { \
    int itemsRemaining = rules.count; \
    int j = 0; \
    while (itemsRemaining) { \
        NSRange range = NSMakeRange(j, MIN(50000, itemsRemaining)); \
        NSMutableArray *subrules = [NSMutableArray array]; \
        [subrules addObjectsFromArray:[rules subarrayWithRange:range]]; \
        NSData *subrulesJSON = [NSJSONSerialization dataWithJSONObject:subrules options:NSJSONWritingPrettyPrinted error:&error]; \
        if (!error) { \
            NSString *encodedSubrules = [[NSString alloc] initWithData:subrulesJSON encoding:NSUTF8StringEncoding];
#define PROCEDURES2 \
            itemsRemaining -= range.length; \
            j += range.length; \
        } \
        subrules = nil; \
        subrulesJSON = nil; \
    } \
}

%hook WKContentRuleListStore

- (void)compileContentRuleListForIdentifier:(NSString *)identifier encodedContentRuleList:(NSString *)encodedContentRuleList completionHandler:(void (^)(void **, NSError *))completionHandler {
    PROCEDURES1
    %orig(identifier, encodedSubrules, completionHandler);
    PROCEDURES2
}

- (void)_compileContentRuleListForIdentifier:(NSString *)identifier encodedContentRuleList:(NS_RELEASES_ARGUMENT NSString *)encodedContentRuleList completionHandler:(void (^)(void **, NSError *))completionHandler {
    PROCEDURES1
    %orig(identifier, encodedSubrules, completionHandler);
    PROCEDURES2
}

%end
