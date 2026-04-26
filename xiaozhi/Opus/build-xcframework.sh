#!/bin/bash
set -e

SCHEME="Opus"
FRAMEWORK_NAME="Opus"
OUTPUT_DIR="./build"
XCFRAMEWORK_PATH="${FRAMEWORK_NAME}.xcframework"

# 1. 清理
rm -rf "${OUTPUT_DIR}"
rm -rf "${XCFRAMEWORK_PATH}"

# 2. 编译 iOS 真机 (arm64)
echo "📦 Building for iOS (Device)..."
xcodebuild build \
    -scheme "${SCHEME}" \
    -destination "generic/platform=iOS" \
    -sdk iphoneos \
    -derivedDataPath "${OUTPUT_DIR}/iphoneos" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    SWIFT_SKIP_MODULE_INTERFACE_VERIFICATION=NO

# 3. 编译 iOS 模拟器 (arm64 + x86_64)
echo "📦 Building for iOS (Simulator)..."
xcodebuild build \
    -scheme "${SCHEME}" \
    -destination "generic/platform=iOS Simulator" \
    -sdk iphonesimulator \
    -derivedDataPath "${OUTPUT_DIR}/iphonesimulator" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    SWIFT_SKIP_MODULE_INTERFACE_VERIFICATION=NO

echo "⚙️  Manually assembling static XCFramework..."

# 定义临时框架路径
IOS_FW_DIR="${OUTPUT_DIR}/static/ios/${FRAMEWORK_NAME}.framework"
SIM_FW_DIR="${OUTPUT_DIR}/static/sim/${FRAMEWORK_NAME}.framework"

mkdir -p "${IOS_FW_DIR}/Headers" "${IOS_FW_DIR}/Modules/${FRAMEWORK_NAME}.swiftmodule"
mkdir -p "${SIM_FW_DIR}/Headers" "${SIM_FW_DIR}/Modules/${FRAMEWORK_NAME}.swiftmodule"

# 4. 找到产品目录 (用于拷贝 swiftmodule)
# 在 BUILD_LIBRARY_FOR_DISTRIBUTION=YES 模式下，通常在 Release-xxx 目录下
IOS_PROD_DIR=$(find "${OUTPUT_DIR}/iphoneos/Build/Products" -name "Release-iphoneos" -type d | head -n 1)
SIM_PROD_DIR=$(find "${OUTPUT_DIR}/iphonesimulator/Build/Products" -name "Release-iphonesimulator" -type d | head -n 1)

# 如果 Release 没找到，试试 Debug
if [ -z "$IOS_PROD_DIR" ]; then IOS_PROD_DIR=$(find "${OUTPUT_DIR}/iphoneos/Build/Products" -name "Debug-iphoneos" -type d | head -n 1); fi
if [ -z "$SIM_PROD_DIR" ]; then SIM_PROD_DIR=$(find "${OUTPUT_DIR}/iphonesimulator/Build/Products" -name "Debug-iphonesimulator" -type d | head -n 1); fi

echo "Found iOS Product Dir: $IOS_PROD_DIR"
echo "Found SIM Product Dir: $SIM_PROD_DIR"

# 5. 合并所有 .o 文件生成静态库二进制
echo "Linking objects for iOS..."
find "${OUTPUT_DIR}/iphoneos/Build/Intermediates.noindex" -name "*.o" -path "*/Objects-normal/arm64/*" > "${OUTPUT_DIR}/ios_objs.txt"
libtool -static -o "${IOS_FW_DIR}/${FRAMEWORK_NAME}" -filelist "${OUTPUT_DIR}/ios_objs.txt"

echo "Linking objects for Simulator (arm64)..."
find "${OUTPUT_DIR}/iphonesimulator/Build/Intermediates.noindex" -name "*.o" -path "*/Objects-normal/arm64/*" > "${OUTPUT_DIR}/sim_arm64_objs.txt"
mkdir -p "${OUTPUT_DIR}/tmp"
libtool -static -o "${OUTPUT_DIR}/tmp/sim_arm64.a" -filelist "${OUTPUT_DIR}/sim_arm64_objs.txt"

echo "Linking objects for Simulator (x86_64)..."
find "${OUTPUT_DIR}/iphonesimulator/Build/Intermediates.noindex" -name "*.o" -path "*/Objects-normal/x86_64/*" > "${OUTPUT_DIR}/sim_x86_64_objs.txt"
libtool -static -o "${OUTPUT_DIR}/tmp/sim_x86_64.a" -filelist "${OUTPUT_DIR}/sim_x86_64_objs.txt"

echo "Merging Simulator architectures..."
lipo -create "${OUTPUT_DIR}/tmp/sim_arm64.a" "${OUTPUT_DIR}/tmp/sim_x86_64.a" -output "${SIM_FW_DIR}/${FRAMEWORK_NAME}"

# 6. 拷贝 Swift 模块文件 (包括 .swiftinterface)
cp -r "${IOS_PROD_DIR}/${FRAMEWORK_NAME}.swiftmodule/"* "${IOS_FW_DIR}/Modules/${FRAMEWORK_NAME}.swiftmodule/"
cp -r "${SIM_PROD_DIR}/${FRAMEWORK_NAME}.swiftmodule/"* "${SIM_FW_DIR}/Modules/${FRAMEWORK_NAME}.swiftmodule/"

# 7. 拷贝 C 头文件
cp Sources/Copus/include/*.h "${IOS_FW_DIR}/Headers/"
cp Sources/Copus/include/*.h "${SIM_FW_DIR}/Headers/"

# 8. 生成 Info.plist
cat << 'PLIST' > "${IOS_FW_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>opus.Opus</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
    <key>MinimumOSVersion</key>
    <string>12.0</string>
</dict>
</plist>
PLIST
cp "${IOS_FW_DIR}/Info.plist" "${SIM_FW_DIR}/Info.plist"

# 9. 创建 XCFramework
echo "🚀 Creating Final XCFramework..."
xcodebuild -create-xcframework \
    -framework "${IOS_FW_DIR}" \
    -framework "${SIM_FW_DIR}" \
    -output "${XCFRAMEWORK_PATH}"

echo "✅ Success! Created ${XCFRAMEWORK_PATH}"
