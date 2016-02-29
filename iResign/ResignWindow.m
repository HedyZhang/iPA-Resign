//
//  ResignWindow.m
//  iResign
//
//  Created by yanshu on 15/12/16.
//  Copyright © 2015年 焱厽. All rights reserved.
//

#import "ResignWindow.h"


static NSString *KEY_IPA_NATIVE_PATH       = @"IPA_NATIVE_PATH";

static NSString *KEY_MOBILE_PROVISION_PATH = @"MOBILE_PROVISION_PATH";

static NSString *KEY_ENTITLEMENTS_PATH     = @"ENTITLEMENTS_PATH";

static NSString *KEY_IMAGE_ASSETS_PATH     = @"IMAGE_ASSETS_PATH";

static NSString *KEY_CERT_SELETED_ITEM     = @"CERT_SELETED_ITEM";

static NSString *kPayloadDirName                    = @"Payload";
static NSString *kInfoPlistFilename                 = @"Info.plist";
static NSString *kKeyInfoPlistApplicationProperties = @"ApplicationProperties";
static NSString *kProductsDirName                   = @"Products";
static NSString *kKeyInfoPlistApplicationPath       = @"ApplicationPath";
static NSString *kKeyBundleIDPlistiTunesArtwork     = @"softwareVersionBundleId";
static NSString *kFrameworksDirName                 = @"Frameworks";

static NSString *kKeyBundleIDPlistApp               = @"CFBundleIdentifier";

static NSString *kKeyBundleDisplayName              = @"CFBundleDisplayName";
static NSString *kKeyBundleName                     = @"CFBundleName";

static NSString *kKeyBundleShortVersion             = @"CFBundleShortVersionString";
static NSString *kKeyBundleVersion                  = @"CFBundleVersion";


@implementation ResignWindow

- (void)awakeFromNib
{
    NSLog(@"window 启动");
    userDefaults = [NSUserDefaults standardUserDefaults];
    [self getCerts];

    
    if ( [userDefaults valueForKey:KEY_IPA_NATIVE_PATH] )
    {
        [iPAPathTextField setStringValue:[userDefaults valueForKey:KEY_IPA_NATIVE_PATH]];
    }
    
    if ( [userDefaults valueForKey:KEY_MOBILE_PROVISION_PATH] )
    {
        [mobileProvisionPathTextField setStringValue:[userDefaults valueForKey:KEY_MOBILE_PROVISION_PATH]];
    }
    
    if ( [userDefaults valueForKey:KEY_ENTITLEMENTS_PATH] )
    {
        [entitlementsPathTextField setStringValue:[userDefaults valueForKey:KEY_ENTITLEMENTS_PATH]];
    }
    
    if ( [userDefaults valueForKey:KEY_IMAGE_ASSETS_PATH] )
    {
        [assetsPathTextField setStringValue:[userDefaults valueForKey:KEY_IMAGE_ASSETS_PATH]];
    }
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ( ![fileManager fileExistsAtPath:@"/usr/bin/unzip"] )
    {
        [self showAlertOfKind:NSCriticalAlertStyle title:@"Error" message:@"在/usr/bin/路径下没有找到unzip组件"];
        exit(0);
    }
    
    if ( ![fileManager fileExistsAtPath:@"/usr/bin/zip"] )
    {
        [self showAlertOfKind:NSCriticalAlertStyle title:@"Error" message:@"在/usr/bin/路径下没有找到zip组件"];
        exit(0);
    }
    
    if ( ![fileManager fileExistsAtPath:@"/usr/bin/codesign"] )
    {
        [self showAlertOfKind:NSCriticalAlertStyle title:@"Error" message:@"在/usr/bin/路径下没有找到codesign组件"];
        exit(0);
    }
}


- (IBAction)actionBrowerButton:(NSButton *)button
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];

    [openDlg setAllowsMultipleSelection:FALSE];
    [openDlg setAllowsOtherFileTypes:FALSE];
    
    if (button == iPAPathBrowerButton)
    {
        [openDlg setCanChooseDirectories:NO];
        [openDlg setCanChooseFiles:TRUE];
        [openDlg setAllowedFileTypes:@[@"ipa", @"IPA", @"xcarchive"]];
        if ([openDlg runModal] == NSModalResponseOK)
        {
            NSString* fileNameOpened = [[[openDlg URLs] objectAtIndex:0] path];
            [iPAPathTextField setStringValue:fileNameOpened];
        }
    }
    
    if (button == mobileProvisionBrower)
    {
        [openDlg setCanChooseDirectories:NO];
        [openDlg setCanChooseFiles:TRUE];
        [openDlg setAllowedFileTypes:@[@"mobileprovision", @"MOBILEPROVISION"]];
        if ([openDlg runModal] == NSModalResponseOK)
        {
            NSString* fileNameOpened = [[[openDlg URLs] objectAtIndex:0] path];
            [mobileProvisionPathTextField setStringValue:fileNameOpened];
        }
    }
    
    if (button == entitlementBrowerButton)
    {
        [openDlg setCanChooseDirectories:NO];
        [openDlg setCanChooseFiles:TRUE];
        [openDlg setAllowedFileTypes:@[@"plist", @"PLIST"]];
        if ([openDlg runModal] == NSModalResponseOK)
        {
            NSString* fileNameOpened = [[[openDlg URLs] objectAtIndex:0] path];
            [entitlementsPathTextField setStringValue:fileNameOpened];
        }
    }
    
    if (button == assertsBrowerButton)
    {
        [openDlg setCanChooseDirectories:YES];
        [openDlg setCanChooseFiles:NO];
        if ([openDlg runModal] == NSModalResponseOK)
        {
            NSString* fileNameOpened = [[[openDlg URLs] objectAtIndex:0] path];
            [assetsPathTextField setStringValue:fileNameOpened];
        }
    }
}

- (IBAction)actionResign:(id)sender
{
    [userDefaults setValue:@([certsComboBox indexOfSelectedItem]) forKey:KEY_CERT_SELETED_ITEM];
    [userDefaults setValue:[iPAPathTextField stringValue] forKey:KEY_IPA_NATIVE_PATH];
    [userDefaults setValue:[mobileProvisionPathTextField stringValue] forKey:KEY_MOBILE_PROVISION_PATH];
    [userDefaults setValue:[entitlementsPathTextField stringValue] forKey:KEY_ENTITLEMENTS_PATH];
    [userDefaults setValue:[assetsPathTextField stringValue] forKey:KEY_IMAGE_ASSETS_PATH];
    
    codesigningResult = nil;
    verificationResult = nil;
    
     workingPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.appulize.iresign"];
    
    sourcePath = iPAPathTextField.stringValue;
    
    if ([certsComboBox objectValue])
    {
        if ([[[sourcePath pathExtension] lowercaseString] isEqualToString:@"ipa"] || [[[sourcePath pathExtension] lowercaseString] isEqualToString:@"xcarchive"])
        {
            [self disableControls];
            [statusLabel setHidden:NO];
            [statusLabel setStringValue:@"设置工作区"];
            [[NSFileManager defaultManager] removeItemAtPath:workingPath error:nil];
            
            [[NSFileManager defaultManager] createDirectoryAtPath:workingPath withIntermediateDirectories:TRUE attributes:nil error:nil];

        }
        if ([[[sourcePath pathExtension] lowercaseString] isEqualToString:@"ipa"]) {
            if (sourcePath && [sourcePath length] > 0) {
                NSLog(@"Unzipping %@",sourcePath);
                [statusLabel setStringValue:@"提取.app包"];
            }
            
            unzipTask = [[NSTask alloc] init];
            [unzipTask setLaunchPath:@"/usr/bin/unzip"];
            [unzipTask setArguments:[NSArray arrayWithObjects:@"-q", sourcePath, @"-d", workingPath, nil]];
            NSLog(@"-----%@", unzipTask.arguments);
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkUnzip:) userInfo:nil repeats:TRUE];
            
            [unzipTask launch];
        }
        else {
            NSString* payloadPath = [workingPath stringByAppendingPathComponent:kPayloadDirName];
            
            NSLog(@"Setting up %@ path in %@", kPayloadDirName, payloadPath);
            [statusLabel setStringValue:[NSString stringWithFormat:@"设置 %@ 路径", kPayloadDirName]];
            
            [[NSFileManager defaultManager] createDirectoryAtPath:payloadPath withIntermediateDirectories:TRUE attributes:nil error:nil];
            
            NSLog(@"Retrieving %@", kInfoPlistFilename);
            [statusLabel setStringValue:[NSString stringWithFormat:@"检索 %@", kInfoPlistFilename]];
            
            NSString* infoPListPath = [sourcePath stringByAppendingPathComponent:kInfoPlistFilename];
            
            NSDictionary* infoPListDict = [NSDictionary dictionaryWithContentsOfFile:infoPListPath];
            
            if (infoPListDict != nil)
            {
                NSString* applicationPath = nil;
                
                NSDictionary* applicationPropertiesDict = [infoPListDict objectForKey:kKeyInfoPlistApplicationProperties];
                
                if (applicationPropertiesDict != nil) {
                    applicationPath = [applicationPropertiesDict objectForKey:kKeyInfoPlistApplicationPath];
                }
                
                if (applicationPath != nil) {
                    applicationPath = [[sourcePath stringByAppendingPathComponent:kProductsDirName] stringByAppendingPathComponent:applicationPath];
                    
                    NSLog(@"Copying %@ to %@ path in %@", applicationPath, kPayloadDirName, payloadPath);
                    [statusLabel setStringValue:[NSString stringWithFormat:@"正在复制 .xcarchive 归档文件到 %@ 路径下", kPayloadDirName]];
                    
                    copyTask = [[NSTask alloc] init];
                    [copyTask setLaunchPath:@"/bin/cp"];
                    [copyTask setArguments:[NSArray arrayWithObjects:@"-r", applicationPath, payloadPath, nil]];
                    NSLog(@"----%@", copyTask.arguments);
                    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCopy:) userInfo:nil repeats:TRUE];
                    
                    [copyTask launch];
                }
                else {
                    [self showAlertOfKind:NSCriticalAlertStyle title:@"Error" message:[NSString stringWithFormat:@"不能解析 %@", kInfoPlistFilename]];
                    [self enableControls];
                    [statusLabel setStringValue:@"正在准备..."];
                }
            }
            else {
                [self showAlertOfKind:NSCriticalAlertStyle title:@"Error" message:[NSString stringWithFormat:@"Retrieve %@ failed", kInfoPlistFilename]];
                [self enableControls];
                [statusLabel setStringValue:@"正在准备..."];
            }
        }
        
    }
    else
    {
        [self showAlertOfKind:NSCriticalAlertStyle title:@"Error" message:@"You must choose an signing certificate from dropdown."];
        [self enableControls];
        [statusLabel setStringValue:@"请重试"];
    }
    
}

#pragma mark - 

- (void)checkUnzip:(NSTimer *)timer
{
    if ([unzipTask isRunning] == 0)
    {
        [timer invalidate];
        unzipTask = nil;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[workingPath stringByAppendingPathComponent:kPayloadDirName]]) {
            NSLog(@"Unzipping done");
            [statusLabel setStringValue:@"提取.app包"];
            
            [self doChangePayloadSource];
        }
        else
        {
            [self showAlertOfKind:NSCriticalAlertStyle title:@"Error" message:@"解压失败"];
            [self enableControls];
            
            [statusLabel setStringValue:@"正在准备"];
        }
    }
}


- (void)doChangePayloadSource
{
    
    if ( ![self isEmpty:bundleIdentifierTextField.stringValue] )
    {
        [self doChangeBundleIdentifier:bundleIdentifierTextField.stringValue];
    }
    
    if ( ![self isEmpty:bundleDisplayNameTextField.stringValue])
    {
        [self doChangeBundleDisplayName:bundleDisplayNameTextField.stringValue];
    }
    
    if ( ![self isEmpty:bundleShortVersionTextField.stringValue])
    {
        [self doChangeBundleShortVersion:bundleShortVersionTextField.stringValue];
    }
    
    if ( ![self isEmpty:BundleVersionTextField.stringValue])
    {
        [self doChangeBundleVersion:BundleVersionTextField.stringValue];
    }
    
    if ( ![self isEmpty:assetsPathTextField.stringValue])
    {
        [self doChangePayloadImageSources];
    }
    
    if ( [self isEmpty:mobileProvisionPathTextField.stringValue] )
    {
        [self doCodeSigning];
    }
    else
    {
        [self doProvisioning];
    }

}


- (void)checkCopy:(NSTimer *)timer
{
    if ([copyTask isRunning] == 0)
    {
        [timer invalidate];
        copyTask = nil;
        
        NSLog(@"Copy done");
        [statusLabel setStringValue:@".xcarchive归档文件已经复制完成"];
        [self doChangePayloadSource];
    }
}

#pragma mark - Do Actions

- (void)doChangePayloadImageSources
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *payload = [workingPath stringByAppendingPathComponent:kPayloadDirName];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:payload error:nil];
    NSString *payloadDir;
    
    for (NSString *file in dirContents)
    {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"])
        {
            payloadDir = [payload stringByAppendingPathComponent:file];
            break;
        }
    }

    if ( [fileManager fileExistsAtPath:assetsPathTextField.stringValue] )
    {
        NSArray *icons = [fileManager contentsOfDirectoryAtPath:assetsPathTextField.stringValue error:nil];
        
       [icons enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           NSString *iconName = ( NSString * )obj;
           if ( [[iconName.pathExtension lowercaseString] isEqualToString:@"png"] )
           {
               [fileManager removeItemAtPath:[payloadDir stringByAppendingPathComponent:iconName] error:nil];
               [fileManager copyItemAtPath:[assetsPathTextField.stringValue stringByAppendingPathComponent:iconName] toPath:[payloadDir stringByAppendingPathComponent:iconName] error:nil];
           }
       }];
    }
}


- (BOOL)doChangeBundleShortVersion:(NSString *)newVersion
{
    NSString *infoPlistPath = [self payloadInfoPlistPath];
    
   return  [self changeBundleIDForFile:infoPlistPath bundleIDKey:kKeyBundleShortVersion newBundleID:newVersion plistOutOptions:NSPropertyListBinaryFormat_v1_0];
}

- (BOOL)doChangeBundleVersion:(NSString *)newVersion
{
     NSString *infoPlistPath = [self payloadInfoPlistPath];
    
   return  [self changeBundleIDForFile:infoPlistPath bundleIDKey:kKeyBundleVersion newBundleID:newVersion plistOutOptions:NSPropertyListBinaryFormat_v1_0];
}

- (BOOL)doChangeBundleDisplayName:(NSString *)newName
{
    NSString *infoPlistPath = [self payloadInfoPlistPath];
    
    BOOL success;
   success &= [self changeBundleIDForFile:infoPlistPath bundleIDKey:kKeyBundleDisplayName newBundleID:newName plistOutOptions:NSPropertyListBinaryFormat_v1_0];
    
   success &= [self changeBundleIDForFile:infoPlistPath bundleIDKey:kKeyBundleName newBundleID:newName plistOutOptions:NSPropertyListBinaryFormat_v1_0];
    
   return success;
}

- (BOOL)doChangeBundleIdentifier:(NSString *)newIdentifier
{
    BOOL success = NO;
    
    success &= [self doAppBundleIDChange:newIdentifier];
    success &= [self doITunesMetadataBundleIDChange:newIdentifier];
    
    return success;
}


- (BOOL)doITunesMetadataBundleIDChange:(NSString *)newBundleID
{
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workingPath error:nil];
    NSString *infoPlistPath = nil;
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"plist"]) {
            infoPlistPath = [workingPath stringByAppendingPathComponent:file];
            break;
        }
    }
    
    return [self changeBundleIDForFile:infoPlistPath bundleIDKey:kKeyBundleIDPlistiTunesArtwork newBundleID:newBundleID plistOutOptions:NSPropertyListXMLFormat_v1_0];
    
}


- (NSString *)payloadInfoPlistPath
{
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
    NSString *infoPlistPath = nil;
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            infoPlistPath = [[[workingPath stringByAppendingPathComponent:kPayloadDirName]
                              stringByAppendingPathComponent:file]
                             stringByAppendingPathComponent:kInfoPlistFilename];
            break;
        }
    }
    return infoPlistPath;
}

- (BOOL)doAppBundleIDChange:(NSString *)newBundleID
{
    NSString *infoPlistPath = [self payloadInfoPlistPath];
    return [self changeBundleIDForFile:infoPlistPath bundleIDKey:kKeyBundleIDPlistApp newBundleID:newBundleID plistOutOptions:NSPropertyListBinaryFormat_v1_0];
}

- (BOOL)changeBundleIDForFile:(NSString *)filePath bundleIDKey:(NSString *)bundleIDKey newBundleID:(NSString *)newBundleID plistOutOptions:(NSPropertyListWriteOptions)options {
    
    NSMutableDictionary *plist = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        plist = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        [plist setObject:newBundleID forKey:bundleIDKey];
        
        NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:plist format:options options:kCFPropertyListImmutable error:nil];
        
        return [xmlData writeToFile:filePath atomically:YES];
        
    }
    
    return NO;
}

#pragma mark - doCodeSigning

- (void)doCodeSigning
{
    appPath = nil;
    frameworksDirPath = nil;
    hasFrameworks = NO;
    frameworks = [[NSMutableArray alloc] init];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            appPath = [[workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
            frameworksDirPath = [appPath stringByAppendingPathComponent:kFrameworksDirName];
            NSLog(@"Found %@",appPath);
            appName = file;
            if ([[NSFileManager defaultManager] fileExistsAtPath:frameworksDirPath]) {
                NSLog(@"Found %@",frameworksDirPath);
                hasFrameworks = YES;
                NSArray *frameworksContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:frameworksDirPath error:nil];
                for (NSString *frameworkFile in frameworksContents) {
                    NSString *extension = [[frameworkFile pathExtension] lowercaseString];
                    if ([extension isEqualTo:@"framework"] || [extension isEqualTo:@"dylib"]) {
                        frameworkPath = [frameworksDirPath stringByAppendingPathComponent:frameworkFile];
                        NSLog(@"Found %@",frameworkPath);
                        [frameworks addObject:frameworkPath];
                    }
                }
            }
            [statusLabel setStringValue:[NSString stringWithFormat:@"正在签名 %@",file]];
            break;
        }
    }
    
    if (appPath) {
        if (hasFrameworks) {
            [self signFile:[frameworks lastObject]];
            [frameworks removeLastObject];
        } else {
            [self signFile:appPath];
        }
    }

}

- (void)signFile:(NSString*)filePath {
    NSLog(@"Codesigning %@", filePath);
    [statusLabel setStringValue:[NSString stringWithFormat:@"正在签名 %@",filePath]];
    
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-fs", [certsComboBox objectValue], nil];
    NSDictionary *systemVersionDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    NSString * systemVersion = [systemVersionDictionary objectForKey:@"ProductVersion"];
    NSArray * version = [systemVersion componentsSeparatedByString:@"."];
    if ([version[0] intValue]<10 || ([version[0] intValue]==10 && ([version[1] intValue]<9 || ([version[1] intValue]==9 && [version[2] intValue]<5)))) {
        
        /*
         Before OSX 10.9, code signing requires a version 1 signature.
         The resource envelope is necessary.
         To ensure it is added, append the resource flag to the arguments.
         */
        
        NSString *resourceRulesPath = [[NSBundle mainBundle] pathForResource:@"ResourceRules" ofType:@"plist"];
        NSString *resourceRulesArgument = [NSString stringWithFormat:@"--resource-rules=%@",resourceRulesPath];
        [arguments addObject:resourceRulesArgument];
    } else {
        
        /*
         For OSX 10.9 and later, code signing requires a version 2 signature.
         The resource envelope is obsolete.
         To ensure it is ignored, remove the resource key from the Info.plist file.
         */
        
        NSString *infoPath = [NSString stringWithFormat:@"%@/Info.plist", filePath];
        NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath];
        [infoDict removeObjectForKey:@"CFBundleResourceSpecification"];
        [infoDict writeToFile:infoPath atomically:YES];
        [arguments addObject:@"--no-strict"]; // http://stackoverflow.com/a/26204757
    }
    
    if (![[entitlementsPathTextField stringValue] isEqualToString:@""]) {
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", [entitlementsPathTextField stringValue]]];
    }
    
    [arguments addObjectsFromArray:[NSArray arrayWithObjects:filePath, nil]];
    
    codesignTask = [[NSTask alloc] init];
    [codesignTask setLaunchPath:@"/usr/bin/codesign"];
    [codesignTask setArguments:arguments];
    NSLog(@"-----%@", codesignTask.arguments);
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCodesigning:) userInfo:nil repeats:TRUE];
    
    
    NSPipe *pipe=[NSPipe pipe];
    [codesignTask setStandardOutput:pipe];
    [codesignTask setStandardError:pipe];
    NSFileHandle *handle=[pipe fileHandleForReading];
    
    [codesignTask launch];
    
    [NSThread detachNewThreadSelector:@selector(watchCodesigning:)
                             toTarget:self withObject:handle];
}

- (void)watchCodesigning:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        
        codesigningResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        
    }
}

- (void)checkCodesigning:(NSTimer *)timer {
    if ([codesignTask isRunning] == 0) {
        [timer invalidate];
        codesignTask = nil;
        if (frameworks.count > 0) {
            [self signFile:[frameworks lastObject]];
            [frameworks removeLastObject];
        } else if (hasFrameworks) {
            hasFrameworks = NO;
            [self signFile:appPath];
        } else {
            NSLog(@"Codesigning done");
            [statusLabel setStringValue:@"签名完成"];
            [self doVerifySignature];
        }
    }
}

- (void)doVerifySignature {
    if (appPath) {
        verifyTask = [[NSTask alloc] init];
        [verifyTask setLaunchPath:@"/usr/bin/codesign"];
        [verifyTask setArguments:[NSArray arrayWithObjects:@"-v", appPath, nil]];
        NSLog(@"----%@", verifyTask.arguments);
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
        
        NSLog(@"Verifying %@",appPath);
        [statusLabel setStringValue:[NSString stringWithFormat:@"验签 %@",appName]];
        
        NSPipe *pipe=[NSPipe pipe];
        [verifyTask setStandardOutput:pipe];
        [verifyTask setStandardError:pipe];
        NSFileHandle *handle=[pipe fileHandleForReading];
        
        [verifyTask launch];
        
        [NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
                                 toTarget:self withObject:handle];
    }
}

- (void)watchVerificationProcess:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        
        verificationResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        
    }
}

- (void)checkVerificationProcess:(NSTimer *)timer {
    if ([verifyTask isRunning] == 0) {
        [timer invalidate];
        verifyTask = nil;
        if ([verificationResult length] == 0) {
            NSLog(@"Verification done");
            [statusLabel setStringValue:@"验签成功"];
            [self doZip];
        } else {
            NSString *error = [[codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:verificationResult];
            [self showAlertOfKind:NSCriticalAlertStyle title:@"签名失败" message:error];
            [self enableControls];
            [statusLabel setStringValue:@"请重试"];
        }
    }
}

- (void)doZip {
    if (appPath) {
        NSArray *destinationPathComponents = [sourcePath pathComponents];
        NSString *destinationPath = @"";
        
        for (int i = 0; i < ([destinationPathComponents count]-1); i++) {
            destinationPath = [destinationPath stringByAppendingPathComponent:[destinationPathComponents objectAtIndex:i]];
        }
        
        fileName = [sourcePath lastPathComponent];
        fileName = [fileName substringToIndex:([fileName length] - ([[sourcePath pathExtension] length] + 1))];
        fileName = [fileName stringByAppendingString:@"-resigned"];
        fileName = [fileName stringByAppendingPathExtension:@"ipa"];
        
        destinationPath = [destinationPath stringByAppendingPathComponent:fileName];
        
        NSLog(@"Dest: %@",destinationPath);
        
        zipTask = [[NSTask alloc] init];
        [zipTask setLaunchPath:@"/usr/bin/zip"];
        [zipTask setCurrentDirectoryPath:workingPath];
        [zipTask setArguments:[NSArray arrayWithObjects:@"-qry", destinationPath, @".", nil]];
        
        NSLog(@"----%@", zipTask.arguments);
        
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkZip:) userInfo:nil repeats:TRUE];
        
        
        NSLog(@"Zipping %@", destinationPath);
        [statusLabel setStringValue:[NSString stringWithFormat:@"正在保存 %@",fileName]];
        
        [zipTask launch];
    }
}

- (void)checkZip:(NSTimer *)timer {
    if ([zipTask isRunning] == 0) {
        [timer invalidate];
        zipTask = nil;
        NSLog(@"Zipping done");
        [statusLabel setStringValue:[NSString stringWithFormat:@"Saved %@",fileName]];
        
        [[NSFileManager defaultManager] removeItemAtPath:workingPath error:nil];
        
        [self enableControls];
        
        NSString *result = [[codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:verificationResult];
        NSLog(@"Codesigning result: %@",result);
    }
}



#pragma mark - doProvisioning
- (void)doProvisioning
{
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            appPath = [[workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
            if ([[NSFileManager defaultManager] fileExistsAtPath:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                NSLog(@"Found embedded.mobileprovision, deleting.");
                [[NSFileManager defaultManager] removeItemAtPath:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
            }
            break;
        }
    }
    
    NSString *targetPath = [appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
    
    provisioningTask = [[NSTask alloc] init];
    [provisioningTask setLaunchPath:@"/bin/cp"];
    [provisioningTask setArguments:[NSArray arrayWithObjects:[mobileProvisionPathTextField stringValue], targetPath, nil]];
    NSLog(@"----%@", provisioningTask.arguments);
    [provisioningTask launch];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkProvisioning:) userInfo:nil repeats:TRUE];
}

- (void)checkProvisioning:(NSTimer *)timer {
    if ([provisioningTask isRunning] == 0) {
        [timer invalidate];
        provisioningTask = nil;
        
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
        
        for (NSString *file in dirContents) {
            if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
                appPath = [[workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
                if ([[NSFileManager defaultManager] fileExistsAtPath:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                    
                    BOOL identifierOK = FALSE;
                    NSString *identifierInProvisioning = @"";
                    
                    NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] encoding:NSASCIIStringEncoding error:nil];
                    NSArray* embeddedProvisioningLines = [embeddedProvisioning componentsSeparatedByCharactersInSet:
                                                          [NSCharacterSet newlineCharacterSet]];
                    
                    for (int i = 0; i < [embeddedProvisioningLines count]; i++) {
                        if ([[embeddedProvisioningLines objectAtIndex:i] rangeOfString:@"application-identifier"].location != NSNotFound) {
                            
                            NSInteger fromPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"<string>"].location + 8;
                            
                            NSInteger toPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"</string>"].location;
                            
                            NSRange range;
                            range.location = fromPosition;
                            range.length = toPosition-fromPosition;
                            
                            NSString *fullIdentifier = [[embeddedProvisioningLines objectAtIndex:i+1] substringWithRange:range];
                            
                            NSArray *identifierComponents = [fullIdentifier componentsSeparatedByString:@"."];
                            
                            if ([[identifierComponents lastObject] isEqualTo:@"*"]) {
                                identifierOK = TRUE;
                            }
                            
                            for (int i = 1; i < [identifierComponents count]; i++) {
                                identifierInProvisioning = [identifierInProvisioning stringByAppendingString:[identifierComponents objectAtIndex:i]];
                                if (i < [identifierComponents count]-1) {
                                    identifierInProvisioning = [identifierInProvisioning stringByAppendingString:@"."];
                                }
                            }
                            break;
                        }
                    }
                    
                    NSLog(@"Mobileprovision identifier: %@",identifierInProvisioning);
                    
                    NSString *infoPlist = [NSString stringWithContentsOfFile:[appPath stringByAppendingPathComponent:@"Info.plist"] encoding:NSASCIIStringEncoding error:nil];
                    if ([infoPlist rangeOfString:identifierInProvisioning].location != NSNotFound) {
                        NSLog(@"Identifiers match");
                        identifierOK = TRUE;
                    }
                    
                    if (identifierOK) {
                        NSLog(@"Provisioning completed.");
                        [statusLabel setStringValue:@"Provisioning completed"];
                        [self doEntitlementsFixing];
                    } else {
                        [self showAlertOfKind:NSCriticalAlertStyle title:@"Error" message:@"Product identifiers don't match"];
                        [self enableControls];
                        [statusLabel setStringValue:@"准备"];
                    }
                } else {
                    [self showAlertOfKind:NSCriticalAlertStyle title:@"Error" message:@"Provisioning failed"];
                    [self enableControls];
                    [statusLabel setStringValue:@"准备"];
                }
                break;
            }
        }
    }
}

- (void)doEntitlementsFixing
{
    if (![entitlementsPathTextField.stringValue isEqualToString:@""] || [mobileProvisionPathTextField.stringValue isEqualToString:@""]) {
        [self doCodeSigning];
        return; // Using a pre-made entitlements file or we're not re-provisioning.
    }
    
    [statusLabel setStringValue:@"创建 entitlements.plist文件"];
    
    if (appPath) {
        generateEntitlementsTask = [[NSTask alloc] init];
        [generateEntitlementsTask setLaunchPath:@"/usr/bin/security"];
        [generateEntitlementsTask setArguments:@[@"cms", @"-D", @"-i", mobileProvisionPathTextField.stringValue]];
        [generateEntitlementsTask setCurrentDirectoryPath:workingPath];
        NSLog(@"-----%@", generateEntitlementsTask.arguments);
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkEntitlementsFix:) userInfo:nil repeats:TRUE];
        
        NSPipe *pipe=[NSPipe pipe];
        [generateEntitlementsTask setStandardOutput:pipe];
        [generateEntitlementsTask setStandardError:pipe];
        NSFileHandle *handle = [pipe fileHandleForReading];
        
        [generateEntitlementsTask launch];
        
        [NSThread detachNewThreadSelector:@selector(watchEntitlements:)
                                 toTarget:self withObject:handle];
    }
}

- (void)watchEntitlements:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        emtitlementsResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    }
}

- (void)checkEntitlementsFix:(NSTimer *)timer {
    if ([generateEntitlementsTask isRunning] == 0) {
        [timer invalidate];
        generateEntitlementsTask = nil;
        [statusLabel setStringValue:@"Entitlements.plist 完成创建"];
        [self doEntitlementsEdit];
    }
}

- (void)doEntitlementsEdit
{
    NSDictionary* entitlements = emtitlementsResult.propertyList;
    entitlements = entitlements[@"Entitlements"];
    NSString* filePath = [workingPath stringByAppendingPathComponent:@"entitlements.plist"];
    NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:entitlements format:NSPropertyListXMLFormat_v1_0 options:kCFPropertyListImmutable error:nil];
    if(![xmlData writeToFile:filePath atomically:YES]) {
        [self showAlertOfKind:NSCriticalAlertStyle title:@"Error" message:@"Failed entitlements generation"];
        [self enableControls];
        [statusLabel setStringValue:@"准备"];
    }
    else {
        entitlementsPathTextField.stringValue = filePath;
        [self doCodeSigning];
    }
}

#pragma mark - Cert

- (void)getCerts
{
    getCertsResult = nil;
    
    statusLabel.stringValue = @"获取钥匙串中的签名证书";
    
    certTask = [[NSTask alloc] init];
    
    certTask.launchPath = @"/usr/bin/security";
    certTask.arguments = [NSArray arrayWithObjects:@"find-identity",@"-v", @"-p", @"codesigning", nil];
    
    NSPipe *pipe = [NSPipe pipe];
    [certTask setStandardOutput:pipe];
    [certTask setStandardError:pipe];
    
    NSFileHandle *handle = [pipe fileHandleForReading];
    
    [certTask launch];
    
    [NSThread detachNewThreadSelector:@selector(watchGetCerts:) toTarget:self withObject:handle];
    
    
}

- (void)watchGetCerts:(NSFileHandle *)streamHandle
{
    NSString *securityResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    NSLog(@"securityResult = %@", securityResult);
    if (securityResult == nil || securityResult.length < 1) {
        // Nothing in the result, return
        return;
    }
    NSArray *rawResult = [securityResult componentsSeparatedByString:@"\""];
    NSMutableArray *tempGetCertsResult = [NSMutableArray arrayWithCapacity:20];
    for (int i = 0; i <= [rawResult count] - 2; i+=2) {

        if (rawResult.count - 1 < i + 1) {
            // Invalid array, don't add an object to that position
        } else {
            // Valid object
            [tempGetCertsResult addObject:[rawResult objectAtIndex:i+1]];
        }
    }
    comboBoxItems = [NSMutableArray arrayWithArray:tempGetCertsResult];
    
    [certsComboBox reloadData];
}

#pragma mark - ComboBox Delegate Methods

-(NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    NSInteger count = 0;
    if ([aComboBox isEqual:certsComboBox])
    {
        count = [comboBoxItems count];
    }
    return count;
    
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    
    id item = nil;
    if ([aComboBox isEqual:certsComboBox])
    {
        item = [comboBoxItems objectAtIndex:index];
    }
    return item;
    
}

#pragma mark - Control State

- (void)disableControls
{
    iPAPathTextField.enabled             = NO;
    entitlementsPathTextField.enabled    = NO;
    mobileProvisionPathTextField.enabled = NO;
    assetsPathTextField.enabled          = NO;

    bundleDisplayNameTextField.enabled   = NO;
    bundleIdentifierTextField.enabled    = NO;
    bundleShortVersionTextField.enabled  = NO;
    BundleVersionTextField.enabled       = NO;

    iPAPathBrowerButton.enabled          = NO;
    entitlementBrowerButton.enabled      = NO;
    mobileProvisionBrower.enabled        = NO;
    assertsBrowerButton.enabled          = NO;
    iResignButton.enabled                = NO;

    certsComboBox.enabled                = NO;
    
    [indicatorView startAnimation:self];
    
}

- (void)enableControls
{
    iPAPathTextField.enabled             = YES;
    entitlementsPathTextField.enabled    = YES;
    mobileProvisionPathTextField.enabled = YES;
    assetsPathTextField.enabled          = YES;

    bundleDisplayNameTextField.enabled   = YES;
    bundleIdentifierTextField.enabled    = YES;
    bundleShortVersionTextField.enabled  = YES;
    BundleVersionTextField.enabled       = YES;

    iPAPathBrowerButton.enabled          = YES;
    entitlementBrowerButton.enabled      = YES;
    mobileProvisionBrower.enabled        = NO;
    assertsBrowerButton.enabled          = YES;
    iResignButton.enabled                = YES;

    certsComboBox.enabled                = YES;
    
    [indicatorView stopAnimation:self];
}

#pragma mark - isEmpty

- (BOOL)isEmpty:(NSString *)stringValue
{
    if (stringValue == nil || stringValue == NULL || [stringValue isEqualToString:@""] )
    {
        return YES;
    }
    
    if ([stringValue isKindOfClass:[NSNull class]])
    {
        return YES;
    }
    
    if ([[stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)
    {
        return YES;
    }
    
    return NO;
    
}

#pragma mark - Alert Methods

- (void)showAlertOfKind:(NSAlertStyle)style title:(NSString *)title message:(NSString *)message
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:style];
    [alert runModal];
}
@end
