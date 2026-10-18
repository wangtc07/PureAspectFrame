import re

with open('PureAspectFrame.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# 1. PBXContainerItemProxy section and PBXTargetDependency section
container_proxy_and_dep = '''/* Begin PBXContainerItemProxy section */
\t\t000000000000000210000000 /* PBXContainerItemProxy */ = {
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = 000000000000000000000000 /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = 000000000000000100000000;
\t\t\tremoteInfo = PureAspectFrame;
\t\t};
/* End PBXContainerItemProxy section */

/* Begin PBXTargetDependency section */
\t\t000000000000000220000000 /* PBXTargetDependency */ = {
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = 000000000000000100000000 /* PureAspectFrame */;
\t\t\ttargetProxy = 000000000000000210000000 /* PBXContainerItemProxy */;
\t\t};
/* End PBXTargetDependency section */
'''
content = content.replace('objects = {\n', 'objects = {\n\n' + container_proxy_and_dep)

# 2. Add product reference
prod_ref = '''\t\t000000000000000000000121 /* PureAspectFrameTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = PureAspectFrameTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };\n'''
content = content.replace('/* Begin PBXFileReference section */\n', '/* Begin PBXFileReference section */\n' + prod_ref)

# 3. Add PBXFileSystemSynchronizedRootGroup
sync_group = '''\t\t000000000000000000000011 /* PureAspectFrameTests */ = {
\t\t\tisa = PBXFileSystemSynchronizedRootGroup;
\t\t\tpath = PureAspectFrameTests;
\t\t\tsourceTree = "<group>";
\t\t};\n'''
content = content.replace('/* Begin PBXFileSystemSynchronizedRootGroup section */\n', '/* Begin PBXFileSystemSynchronizedRootGroup section */\n' + sync_group)

# 4. Add to main group children and Products group children
content = content.replace('000000000000000000000010 /* PureAspectFrame */,\n', '000000000000000000000010 /* PureAspectFrame */,\n\t\t\t\t000000000000000000000011 /* PureAspectFrameTests */,\n')
content = content.replace('000000000000000000000120 /* PureAspectFrame.app */,\n', '000000000000000000000120 /* PureAspectFrame.app */,\n\t\t\t\t000000000000000000000121 /* PureAspectFrameTests.xctest */,\n')

# 5. Add PBXNativeTarget
native_target = '''\t\t000000000000000200000000 /* PureAspectFrameTests */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = 000000000000000260000000 /* Build configuration list for PBXNativeTarget "PureAspectFrameTests" */;
\t\t\tbuildPhases = (
\t\t\t\t000000000000000230000000 /* Sources */,
\t\t\t\t000000000000000240000000 /* Frameworks */,
\t\t\t\t000000000000000250000000 /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t000000000000000220000000 /* PBXTargetDependency */,
\t\t\t);
\t\t\tfileSystemSynchronizedGroups = (
\t\t\t\t000000000000000000000011 /* PureAspectFrameTests */,
\t\t\t);
\t\t\tname = PureAspectFrameTests;
\t\t\tproductName = PureAspectFrameTests;
\t\t\tproductReference = 000000000000000000000121 /* PureAspectFrameTests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t};\n'''
content = content.replace('/* Begin PBXNativeTarget section */\n', '/* Begin PBXNativeTarget section */\n' + native_target)


# 7. Add build phases
phases_src = '''\t\t000000000000000230000000 /* Sources */ = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};\n'''
content = content.replace('/* Begin PBXSourcesBuildPhase section */\n', '/* Begin PBXSourcesBuildPhase section */\n' + phases_src)

phases_fw = '''\t\t000000000000000240000000 /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};\n'''
content = content.replace('/* Begin PBXFrameworksBuildPhase section */\n', '/* Begin PBXFrameworksBuildPhase section */\n' + phases_fw)

phases_res = '''\t\t000000000000000250000000 /* Resources */ = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};\n'''
content = content.replace('/* Begin PBXResourcesBuildPhase section */\n', '/* Begin PBXResourcesBuildPhase section */\n' + phases_res)

# 8. Add project target and TargetAttributes
content = content.replace('targets = (\n\t\t\t\t000000000000000100000000 /* PureAspectFrame */,\n\t\t\t);', 'targets = (\n\t\t\t\t000000000000000100000000 /* PureAspectFrame */,\n\t\t\t\t000000000000000200000000 /* PureAspectFrameTests */,\n\t\t\t);')
target_attr = '''\t\t\t\t\t000000000000000200000000 = {
\t\t\t\t\t\tCreatedOnToolsVersion = 26.3;
\t\t\t\t\t\tTestTargetID = 000000000000000100000000;
\t\t\t\t\t};\n'''
content = content.replace('000000000000000100000000 = {\n\t\t\t\t\t\tCreatedOnToolsVersion = 26.3;\n\t\t\t\t\t};', '000000000000000100000000 = {\n\t\t\t\t\t\tCreatedOnToolsVersion = 26.3;\n\t\t\t\t\t};\n' + target_attr)

# 9. Add build configurations for PureAspectFrameTests
configs = '''\t\t000000000000000261000000 /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "devplaceholder.$(PROJECT_UNIQUE_VALUE:identifier).PureAspectFrameTests";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSTRING_CATALOG_GENERATE_SYMBOLS = NO;
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx";
\t\t\t\tSWIFT_APPROACHABLE_CONCURRENCY = YES;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/PureAspectFrame.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/PureAspectFrame";
\t\t\t};
\t\t\tname = Debug;
\t\t};
\t\t000000000000000262000000 /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "devplaceholder.$(PROJECT_UNIQUE_VALUE:identifier).PureAspectFrameTests";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSTRING_CATALOG_GENERATE_SYMBOLS = NO;
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx";
\t\t\t\tSWIFT_APPROACHABLE_CONCURRENCY = YES;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/PureAspectFrame.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/PureAspectFrame";
\t\t\t};
\t\t\tname = Release;
\t\t};\n'''
content = content.replace('/* Begin XCBuildConfiguration section */\n', '/* Begin XCBuildConfiguration section */\n' + configs)

# 10. Add configuration list
cfg_list = '''\t\t000000000000000260000000 /* Build configuration list for PBXNativeTarget "PureAspectFrameTests" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t000000000000000261000000 /* Debug */,
\t\t\t\t000000000000000262000000 /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};\n'''
content = content.replace('/* Begin XCConfigurationList section */\n', '/* Begin XCConfigurationList section */\n' + cfg_list)

with open('PureAspectFrame.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)
print('Done!')
