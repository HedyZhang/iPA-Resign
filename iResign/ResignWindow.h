//
//  ResignWindow.h
//  iResign
//
//  Created by yanshu on 15/12/16.
//  Copyright © 2015年 焱厽. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TextFieldDrag.h"
@interface ResignWindow : NSWindow<NSComboBoxDataSource, NSComboBoxDelegate>
{
    
    IBOutlet TextFieldDrag *iPAPathTextField;
    IBOutlet TextFieldDrag *mobileProvisionPathTextField;
    IBOutlet TextFieldDrag *entitlementsPathTextField;
    IBOutlet NSTextField *bundleDisplayNameTextField;
    IBOutlet NSTextField *bundleIdentifierTextField;
    IBOutlet NSTextField *bundleShortVersionTextField;
    IBOutlet NSTextField *BundleVersionTextField;
    IBOutlet TextFieldDrag *assetsPathTextField;
    
    
    
    IBOutlet NSComboBox *certsComboBox;
    IBOutlet NSProgressIndicator *indicatorView;
    
    IBOutlet NSTextField *statusLabel;
    
    IBOutlet NSButton *iPAPathBrowerButton;
    IBOutlet NSButton *mobileProvisionBrower;
    IBOutlet NSButton *entitlementBrowerButton;
    IBOutlet NSButton *assertsBrowerButton;
    
    IBOutlet NSButton *iResignButton;
    
    
    NSMutableArray *getCertsResult;
    
    
    NSTask *certTask;
    NSTask *unzipTask;
    NSTask *zipTask;
    NSTask *copyTask;
    NSTask *provisioningTask;
    NSTask *generateEntitlementsTask;
    NSTask *codesignTask;
    NSTask *verifyTask;
    
    NSString *appName;
     NSString *fileName;
    
    NSMutableArray *frameworks;
    Boolean hasFrameworks;
    
    NSMutableArray *comboBoxItems;
    
    NSUserDefaults *userDefaults;
    
    NSString *workingPath;
    NSString *codesigningResult;
    NSString *emtitlementsResult;
    NSString *verificationResult;
    
    NSString *sourcePath;
    NSString *appPath;
    NSString *frameworksDirPath;
    NSString *frameworkPath;
}
@end
