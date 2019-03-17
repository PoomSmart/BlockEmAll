%hook WKContentRuleListStore

- (void)_compileContentRuleListForIdentifier:(NSString *)identifier encodedContentRuleList:(NS_RELEASES_ARGUMENT NSString *)encodedContentRuleList completionHandler:(void (^)(void **, NSError *))completionHandler {
    NSError *error = nil;
    NSArray *rules = [NSJSONSerialization JSONObjectWithData:[encodedContentRuleList dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
    if (error) {
        %orig;
        return;
    }
    int itemsRemaining = [rules count];
    int j = 0;
    while (itemsRemaining) {
        NSRange range = NSMakeRange(j, MIN(50000, itemsRemaining));
        NSMutableArray *subrules = [NSMutableArray array];
        [subrules addObjectsFromArray:[rules subarrayWithRange:range]];
        NSData *subrulesJSON = [NSJSONSerialization dataWithJSONObject:subrules options:NSJSONWritingPrettyPrinted error:&error];
        if (!error) {
            NSString *encodedSubrules = [[NSString alloc] initWithData:subrulesJSON encoding:NSUTF8StringEncoding];
            %orig(identifier, encodedSubrules, completionHandler);
            itemsRemaining -= range.length;
            j += range.length;
        }
        subrules = nil;
        subrulesJSON = nil;
    }
}

%end

%ctor {
    %init;
}
