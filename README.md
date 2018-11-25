# BlockEmAll
A jailbreak tweak that bypasses 50,000 content filter rules for iOS Safari.

# Increasing memory limit
As of iOS 9, iOS acts aggressively to such processes that consume too much memory. If a process allocates the memory more than specified (by iOS), this process will be killed.

Memory usage of processes like Safari content blockers are limited to **12 MB**. This is why we must alter the file storing memory limits: `/System/Library/LaunchDaemons/com.apple.jetsamproperties.XX.plist` where `XX` is your device internal model number. For example `XX` either is `N69` or `N69u` for iPhone SE devices.

We can increase `ActiveHardMemoryLimit` and `InactiveHardMemoryLimit` in `VersionN -> Extension -> Override -> com.apple.Safari.content-blocker` (`N` is some number) to, says, **256 MB**. Doing so allows content blockers like Adguard Pro to add ten thousands of filters with no errors. However, it will eventually complain when the rules exceed 50,000 entries. Because iOS will refuse to compile any rules of size over 50,000, we need more work.

# Compromising WebCore's limitation
Apple hardcoded the limit in their open-source WebCore implementation which can be founded [here](https://trac.webkit.org/browser/webkit/trunk/Source/WebCore/contentextensions/ContentExtensionParser.cpp). In a function called `Expected<Vector<ContentExtensionRule>, std::error_code> loadEncodedRules(ExecState& exec, const String& ruleJSON)`, filter rules are in form of an encoded string, being parsed as a JSON array. It raises an error `ContentExtensionError::JSONTooManyRules` when the array length exceeds `maxRuleCount = 50000`.

Hooking into this pure C++ function is *uneasy*, but there's an alternative *smart* approach; we can hook a higher level Objective-C API: `-[WKContentRuleListStore _compileContentRuleListForIdentifier:encodedContentRuleList:completionHandler:]`, and [here](https://trac.webkit.org/browser/webkit/trunk/Source/WebKit/UIProcess/API/Cocoa/WKContentRuleListStore.mm) is where it is located. This method compiles the rules by calling a lower level API, given the content blocker identifier and some action to be done after the compilation has been done. Eventually, this method will invoke the `loadEncodedRules()` function. We cannot input more than 50,000 rules at a time, but we can input no more than 50,000 rules multiple times. In other words, **you can seperate the rules into chunks that each one is no more than 50,000 entries**.

In terms of pseudocode:
```
compile(identifier, ruleList, completion):
    count = ruleList.count
    j = 0
    while count > 0:
        range = (j, min(50000, count))
        subruleList = subarray(ruleList, range)
        original_compile(identifier, subruleList, completion)
        j += range.length
        count -= range.length
```

# Increasing memory limit (again)
The aforementioned Objective-C method is invoked in a XPC service dedicated for loading rules from user-installed content blockers. Similarly, there is a memory limit which this process should never exceed.

Found in `VersionN -> XPCService -> Override -> com.apple.SafariServices.ContentBlockerLoader`, we can set both `ActiveSoftMemoryLimit` and `InactiveHardMemoryLimit` to something higher, like **512 MB** that seems to be enough. Of course, you need to check how much RAM your device can offer.

Changes to increasing memory limit **require a reboot**.

# Per-app limitation bypassing
Usually, content blockers (Adguard Pro included) will both limit the total rules to 50,000 and warn users about that. One must find and hook method(s) that limit the number, and the rest would work as intended.

Ensuring all three sections, you are set.