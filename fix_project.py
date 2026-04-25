import os

content = r'''// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		A36E1C682F9A6CF1002CB0C4 /* xiaozhiApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1C672F9A6CF1002CB0C4 /* xiaozhiApp.swift */; };
		A36E1C6A2F9A6CF1002CB0C4 /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1C692F9A6CF1002CB0C4 /* ContentView.swift */; };
		A36E1C6C2F9A6CF2002CB0C4 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = A36E1C6B2F9A6CF2002CB0C4 /* Assets.xcassets */; };
		A36E1C6F2F9A6CF2002CB0C4 /* Preview Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = A36E1C6E2F9A6CF2002CB0C4 /* Preview Assets.xcassets */; };
		A36E1C792F9A6CF2002CB0C4 /* xiaozhiTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1C782F9A6CF2002CB0C4 /* xiaozhiTests.swift */; };
		A36E1C922F9A6CF2002CB0C4 /* KeychainManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1C912F9A6CF2002CB0C4 /* KeychainManager.swift */; };
		A36E1C942F9A6CF2002CB0C4 /* KeychainManagerTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1C932F9A6CF2002CB0C4 /* KeychainManagerTests.swift */; };
		A36E1C972F9A6CF2002CB0C4 /* CryptoUtils.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1C952F9A6CF2002CB0C4 /* CryptoUtils.swift */; };
		A36E1C982F9A6CF2002CB0C4 /* CryptoUtilsTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1C962F9A6CF2002CB0C4 /* CryptoUtilsTests.swift */; };
		A36E1C9B2F9A6CF2002CB0C4 /* DeviceFingerprint.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1C992F9A6CF2002CB0C4 /* DeviceFingerprint.swift */; };
		A36E1C9C2F9A6CF2002CB0C4 /* IdentityTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1C9A2F9A6CF2002CB0C4 /* IdentityTests.swift */; };
		A36E1CA32F9A6CF2002CB0C4 /* NetworkManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1CA12F9A6CF1002CB0C4 /* NetworkManager.swift */; };
		A36E1CA42F9A6CF2002CB0C4 /* NetworkManagerTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1CA22F9A6CF2002CB0C4 /* NetworkManagerTests.swift */; };
		A36E1CA82F9B6600009DAA06 /* OTAService.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1CA62F9A6CF2002CB0C4 /* OTAService.swift */; };
		A36E1CA92F9B6600009DAA06 /* OTAContext.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1CA52F9A6CF2002CB0C4 /* OTAContext.swift */; };
		A36E1CAA2F9B6600009DAA06 /* OTAServiceTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = A36E1CA72F9A6CF2002CB0C4 /* OTAServiceTests.swift */; };
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		A36E1C752F9A6CF2002CB0C4 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = A36E1C5C2F9A6CF1002CB0C4 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = A36E1C632F9A6CF1002CB0C4;
			remoteInfo = xiaozhi;
		};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
		A36E1C642F9A6CF1002CB0C4 /* xiaozhi.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = xiaozhi.app; sourceTree = BUILT_PRODUCTS_DIR; };
		A36E1C672F9A6CF1002CB0C4 /* xiaozhiApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = xiaozhiApp.swift; sourceTree = "<group>"; };
		A36E1C692F9A6CF1002CB0C4 /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		A36E1C6B2F9A6CF1002CB0C4 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		A36E1C6E2F9A6CF2002CB0C4 /* Preview Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Preview Assets.xcassets"; sourceTree = "<group>"; };
		A36E1C742F9A6CF2002CB0C4 /* xiaozhiTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = xiaozhiTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
		A36E1C782F9A6CF2002CB0C4 /* xiaozhiTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = xiaozhiTests.swift; sourceTree = "<group>"; };
		A36E1C912F9A6CF2002CB0C4 /* KeychainManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Utils/KeychainManager.swift; sourceTree = "<group>"; };
		A36E1C932F9A6CF2002CB0C4 /* KeychainManagerTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = KeychainManagerTests.swift; sourceTree = "<group>"; };
		A36E1C952F9A6CF2002CB0C4 /* CryptoUtils.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Utils/CryptoUtils.swift; sourceTree = "<group>"; };
		A36E1C962F9A6CF2002CB0C4 /* CryptoUtilsTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CryptoUtilsTests.swift; sourceTree = "<group>"; };
		A36E1C992F9A6CF2002CB0C4 /* DeviceFingerprint.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Services/Identity/DeviceFingerprint.swift; sourceTree = "<group>"; };
		A36E1C9A2F9A6CF2002CB0C4 /* IdentityTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = IdentityTests.swift; sourceTree = "<group>"; };
		A36E1CA12F9A6CF1002CB0C4 /* NetworkManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Services/Network/NetworkManager.swift; sourceTree = "<group>"; };
		A36E1CA22F9A6CF1002CB0C4 /* NetworkManagerTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NetworkManagerTests.swift; sourceTree = "<group>"; };
		A36E1CA52F9A6CF2002CB0C4 /* OTAContext.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Models/OTAContext.swift; sourceTree = "<group>"; };
		A36E1CA62F9A6CF2002CB0C4 /* OTAService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Services/Network/OTAService.swift; sourceTree = "<group>"; };
		A36E1CA72F9A6CF2002CB0C4 /* OTAServiceTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = OTAServiceTests.swift; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		A36E1C612F9A6CF1002CB0C4 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		A36E1C712F9A6CF1002CB0C4 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		A36E1C5B2F9A6CF1002CB0C4 = {
			isa = PBXGroup;
			children = (
				A36E1C662F9A6CF1002CB0C4 /* xiaozhi */,
				A36E1C772F9A6CF2002CB0C4 /* xiaozhiTests */,
				A36E1C652F9A6CF1002CB0C4 /* Products */,
			);
			sourceTree = "<group>";
		};
		A36E1C652F9A6CF1002CB0C4 /* Products */ = {
			isa = PBXGroup;
			children = (
				A36E1C642F9A6CF1002CB0C4 /* xiaozhi.app */,
				A36E1C742F9A6CF2002CB0C4 /* xiaozhiTests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		A36E1C662F9A6CF1002CB0C4 /* xiaozhi */ = {
			isa = PBXGroup;
			children = (
				A36E1CA62F9A6CF1002CB0C4 /* OTAService.swift */,
				A36E1CA52F9A6CF2002CB0C4 /* OTAContext.swift */,
				A36E1CA12F9A6CF1002CB0C4 /* NetworkManager.swift */,
				A36E1C992F9A6CF2002CB0C4 /* DeviceFingerprint.swift */,
				A36E1C952F9A6CF2002CB0C4 /* Utils/CryptoUtils.swift */,
				A36E1C912F9A6CF2002CB0C4 /* Utils/KeychainManager.swift */,
				A36E1C672F9A6CF1002CB0C4 /* xiaozhiApp.swift */,
				A36E1C692F9A6CF1002CB0C4 /* ContentView.swift */,
				A36E1C6B2F9A6CF1002CB0C4 /* Assets.xcassets */,
				A36E1C6D2F9A6CF2002CB0C4 /* Preview Content */,
			);
			path = xiaozhi;
			sourceTree = "<group>";
		};
		A36E1C6D2F9A6CF2002CB0C4 /* Preview Content */ = {
			isa = PBXGroup;
			children = (
				A36E1C6E2F9A6CF2002CB0C4 /* Preview Assets.xcassets */,
			);
			path = "Preview Content";
			sourceTree = "<group>";
		};
		A36E1C772F9A6CF2002CB0C4 /* xiaozhiTests */ = {
			isa = PBXGroup;
			children = (
				A36E1CA72F9A6CF2002CB0C4 /* OTAServiceTests.swift */,
				A36E1CA22F9A6CF2002CB0C4 /* NetworkManagerTests.swift */,
				A36E1C9A2F9A6CF2002CB0C4 /* IdentityTests.swift */,
				A36E1C962F9A6CF2002CB0C4 /* CryptoUtilsTests.swift */,
				A36E1C932F9A6CF2002CB0C4 /* KeychainManagerTests.swift */,
				A36E1C782F9A6CF2002CB0C4 /* xiaozhiTests.swift */,
			);
			path = xiaozhiTests;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		A36E1C632F9A6CF1002CB0C4 /* xiaozhi */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = A36E1C882F9A6CF2002CB0C4 /* Build configuration list for PBXNativeTarget "xiaozhi" */;
			buildPhases = (
				A36E1C602F9A6CF1002CB0C4 /* Sources */,
				A36E1C612F9A6CF1002CB0C4 /* Frameworks */,
				A36E1C622F9A6CF1002CB0C4 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = xiaozhi;
			productName = xiaozhi;
			productReference = A36E1C642F9A6CF1002CB0C4 /* xiaozhi.app */;
			productType = "com.apple.product-type.application";
		};
		A36E1C732F9A6CF2002CB0C4 /* xiaozhiTests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = A36E1C8B2F9A6CF2002CB0C4 /* Build configuration list for PBXNativeTarget "xiaozhiTests" */;
			buildPhases = (
				A36E1C702F9A6CF2002CB0C4 /* Sources */,
				A36E1C712F9A6CF1002CB0C4 /* Frameworks */,
				A36E1C722F9A6CF2002CB0C4 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				A36E1C762F9A6CF2002CB0C4 /* PBXTargetDependency */,
			);
			name = xiaozhiTests;
			productName = xiaozhiTests;
			productReference = A36E1C742F9A6CF2002CB0C4 /* xiaozhiTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		A36E1C5C2F9A6CF1002CB0C4 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1540;
				LastUpgradeCheck = 1540;
				TargetAttributes = {
					A36E1C632F9A6CF1002CB0C4 = {
						CreatedOnToolsVersion = 15.4;
					};
					A36E1C732F9A6CF2002CB0C4 = {
						CreatedOnToolsVersion = 15.4;
						TestTargetID = A36E1C632F9A6CF1002CB0C4;
					};
				};
			};
			buildConfigurationList = A36E1C5F2F9A6CF1002CB0C4 /* Build configuration list for PBXProject "xiaozhi" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = A36E1C5B2F9A6CF1002CB0C4;
			productRefGroup = A36E1C652F9A6CF1002CB0C4 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				A36E1C632F9A6CF1002CB0C4 /* xiaozhi */,
				A36E1C732F9A6CF2002CB0C4 /* xiaozhiTests */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		A36E1C622F9A6CF1002CB0C4 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				A36E1C6F2F9A6CF2002CB0C4 /* Preview Assets.xcassets in Resources */,
				A36E1C6C2F9A6CF2002CB0C4 /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		A36E1C722F9A6CF2002CB0C4 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		A36E1C602F9A6CF1002CB0C4 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				A36E1CA92F9B6600009DAA06 /* OTAContext.swift in Sources */,
				A36E1CA82F9B6600009DAA06 /* OTAService.swift in Sources */,
				A36E1CA32F9A6CF2002CB0C4 /* NetworkManager.swift in Sources */,
				A36E1C9B2F9A6CF2002CB0C4 /* DeviceFingerprint.swift in Sources */,
				A36E1C972F9A6CF2002CB0C4 /* CryptoUtils.swift in Sources */,
				A36E1C922F9A6CF2002CB0C4 /* KeychainManager.swift in Sources */,
				A36E1C6A2F9A6CF1002CB0C4 /* ContentView.swift in Sources */,
				A36E1C682F9A6CF1002CB0C4 /* xiaozhiApp.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		A36E1C702F9A6CF1002CB0C4 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				A36E1CAA2F9B6600009DAA06 /* OTAServiceTests.swift in Sources */,
				A36E1CA42F9A6CF2002CB0C4 /* NetworkManagerTests.swift in Sources */,
				A36E1C9C2F9A6CF2002CB0C4 /* IdentityTests.swift in Sources */,
				A36E1C982F9A6CF2002CB0C4 /* CryptoUtilsTests.swift in Sources */,
				A36E1C942F9A6CF2002CB0C4 /* KeychainManagerTests.swift in Sources */,
				A36E1C792F9A6CF2002CB0C4 /* xiaozhiTests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		A36E1C762F9A6CF2002CB0C4 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = A36E1C632F9A6CF1002CB0C4 /* xiaozhi */;
			targetProxy = A36E1C752F9A6CF2002CB0C4 /* PBXContainerItemProxy */;
		};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		A36E1C862F9A6CF2002CB0C4 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.5;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.xd0g.xiaozhi;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
			};
			name = Debug;
		};
		A36E1C872F9A6CF2002CB0C4 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.5;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.xd0g.xiaozhi;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_VERSION = 5.0;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		A36E1C892F9A6CF1002CB0C4 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\"xiaozhi/Preview Content\"";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.xd0g.xiaozhi;
				PRODUCT_NAME = xiaozhi;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		A36E1C8A2F9A6CF1002CB0C4 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\"xiaozhi/Preview Content\"";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.xd0g.xiaozhi;
				PRODUCT_NAME = xiaozhi;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
		A36E1C8C2F9A6CF2002CB0C4 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES;
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.5;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.xd0g.xiaozhiTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/xiaozhi.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/xiaozhi";
			};
			name = Debug;
		};
		A36E1C8D2F9A6CF2002CB0C4 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES;
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.5;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.xd0g.xiaozhiTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/xiaozhi.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/xiaozhi";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		A36E1C5F2F9A6CF1002CB0C4 /* Build configuration list for PBXProject "xiaozhi" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				A36E1C862F9A6CF2002CB0C4 /* Debug */,
				A36E1C872F9A6CF2002CB0C4 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		A36E1C882F9A6CF2002CB0C4 /* Build configuration list for PBXNativeTarget "xiaozhi" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				A36E1C892F9A6CF1002CB0C4 /* Debug */,
				A36E1C8A2F9A6CF1002CB0C4 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		A36E1C8B2F9A6CF2002CB0C4 /* Build configuration list for PBXNativeTarget "xiaozhiTests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				A36E1C8C2F9A6CF2002CB0C4 /* Debug */,
				A36E1C8D2F9A6CF2002CB0C4 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = A36E1C5C2F9A6CF1002CB0C4 /* Project object */;
}
