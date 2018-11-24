# BlockEmAll
A jailbreak tweak that bypasses 50,000 content filter rules for iOS Safari.

# Increasing memory limit
As of iOS 9, iOS acts aggressively to such processes that consuming too much memory. If a process allocates the memory more than specified (by iOS), this process will be killed.

Safari content blockers are ones of which that can use no more than **12 MB** of memory. This is why we need to change some values in `/System/Library/LaunchDaemons/com.apple.jetsamproperties.XX.plist` where `XX` is your device internal model number. For example `XX` either is `N69` or `N69u` for iPhone SE devices.

We can increase `ActiveHardMemoryLimit` and `InactiveHardMemoryLimit` in `VersionN -> Extension -> Override -> com.apple.Safari.content-blocker` (`N` is some number) to, says, **256 MB**. Doing so allows content blockers like Adguard Pro to add ten thousands of filters with no errors. However, it will eventually complain when the rules exceed 50,000 entries, and the system will refuse to compile any rules of size over 50,000. This leads to the next section of the finding.

# Compromising WebCore's limitation
Apple hardcoded the limit in their open-source WebCore implementation which can be founded [here](https://trac.webkit.org/browser/webkit/trunk/Source/WebCore/contentextensions/ContentExtensionParser.cpp). In a function called `Expected<Vector<ContentExtensionRule>, std::error_code> loadEncodedRules(ExecState& exec, const String& ruleJSON)`, filter rules are in form of an encoded string, being parsed as a JSON array. It complains `ContentExtensionError::JSONTooManyRules` when the array length exceeds `maxRuleCount = 50000`.

Hooking into this pure C++ function is *uneasy*. One alternative *smart* approach therefore is to hook a higher level Objective-C API: `-[WKContentRuleListStore _compileContentRuleListForIdentifier:encodedContentRuleList:completionHandler:]`, and [here](https://trac.webkit.org/browser/webkit/trunk/Source/WebKit/UIProcess/API/Cocoa/WKContentRuleListStore.mm) is where it is located. This method compiles the rules by calling a lower level API, given the content blocker identifier and some action to be done after the compilation has been done. Eventually, this method will invoke the aforementioned C++ function. From here, **you can seperate the rules into chunks that each is up to 50000 entries**.

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
The aforementioned Objective-C method is invoked in a XPC service dedicated for loading rules from installed content blockers. Similarly, there is a memory limit which this process should never exceed.

Found in `VersionN -> XPCService -> Override -> com.apple.SafariServices.ContentBlockerLoader`, we can set both `ActiveSoftMemoryLimit` and `InactiveHardMemoryLimit` to something higher, like **512 MB** that seems to be enough. Of course, you need to check how much RAM your device can offer.

Changes to increasing memory limit require a reboot.

# Per-app limitation bypassing
Usually, content blockers (Adguard Pro included) will both limit the total rules to 50,000 and warn users about that. One must find and hook method(s) that limit the number, and the rest would work as intended.

Ensuring all three sections, you are set.