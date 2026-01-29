#!/bin/bash
# ============================================================================
# JinGo VPN - Windows Build Script (MSYS2/MinGW)
# ============================================================================
# 使用方法：
#   方式1: 在 MSYS2 MinGW64 终端中运行
#     cd /d/app/OpineWork/JinGo
#     ./scripts/build/build-windows.sh
#
#   方式2: 使用完整路径在任何 bash 中运行
#     D:/msys64/usr/bin/bash.exe /d/app/OpineWork/JinGo/scripts/build/build-windows.sh
#
# 参数:
#   clean  - 清理之前的构建
#   debug  - 以 Debug 模式构建
# ============================================================================

set -e  # Exit on error

# ============================================================================
# 配置区域 - 在这里修改路径配置
# ============================================================================

# Qt 路径搜索优先级
QT_SEARCH_PATHS=(
    "/d/Qt/6.10.1/mingw_64"
    "/d/Qt/6.10.0/mingw_64"
    "/d/Qt/6.8.1/mingw_64"
    "/c/Qt/6.10.1/mingw_64"
)

# MinGW 路径搜索优先级
MINGW_SEARCH_PATHS=(
    "/d/Qt/Tools/mingw1310_64"
    "/d/Qt/Tools/mingw1120_64"
    "/c/Qt/Tools/mingw1310_64"
)

# CMake 路径搜索优先级
CMAKE_SEARCH_PATHS=(
    "/d/Qt/Tools/CMake_64/bin"
    "/c/Qt/Tools/CMake_64/bin"
)

# MSYS2 根目录
MSYS2_ROOT="/d/msys64"

# 品牌ID（留空使用默认）
BRAND=""

# ============================================================================

# 首先设置 MSYS2 环境（必须在使用任何 bash 命令之前）
if [[ -z "$MSYSTEM" ]]; then
    # 不在 MSYS2 环境中，自动设置 PATH
    export PATH="/d/msys64/mingw64/bin:/d/msys64/usr/bin:$PATH"
    export MSYSTEM="MINGW64"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

print_header() {
    echo "========================================================================"
    echo "  $1"
    echo "========================================================================"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# ============================================================================
# 路径检测函数
# ============================================================================

detect_qt_dir() {
    for path in "${QT_SEARCH_PATHS[@]}"; do
        if [ -d "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

detect_mingw_dir() {
    for path in "${MINGW_SEARCH_PATHS[@]}"; do
        if [ -d "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

detect_cmake_bin() {
    for path in "${CMAKE_SEARCH_PATHS[@]}"; do
        if [ -f "$path/cmake.exe" ]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

# ============================================================================
# Parse arguments
# ============================================================================

BUILD_TYPE="Release"
CLEAN=false

for arg in "$@"; do
    case $arg in
        clean) CLEAN=true ;;
        debug) BUILD_TYPE="Debug" ;;
        *) ;;
    esac
done

# ============================================================================
# Script Setup
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build-windows"
RELEASE_DIR="$PROJECT_DIR/release"
PKG_DIR="$PROJECT_DIR/pkg"

# 检测路径
QT_DIR=$(detect_qt_dir)
if [ -z "$QT_DIR" ]; then
    print_error "Qt not found! Please edit QT_SEARCH_PATHS in script"
    exit 1
fi

MINGW_DIR=$(detect_mingw_dir)
if [ -z "$MINGW_DIR" ]; then
    print_error "MinGW not found! Please edit MINGW_SEARCH_PATHS in script"
    exit 1
fi

CMAKE_BIN=$(detect_cmake_bin)
if [ -z "$CMAKE_BIN" ]; then
    print_error "CMake not found! Please edit CMAKE_SEARCH_PATHS in script"
    exit 1
fi

# 设置 PATH
export PATH="$MINGW_DIR/bin:$QT_DIR/bin:$CMAKE_BIN:$MSYS2_ROOT/usr/bin:$PATH"

# ============================================================================
# Copy brand assets
# ============================================================================

copy_brand_assets() {
    local brand_id="${BRAND:-1}"
    local brand_dir="$PROJECT_DIR/white-labeling/$brand_id"
    local resources_dir="$PROJECT_DIR/resources"

    if [ ! -d "$brand_dir" ]; then
        print_warning "Brand directory not found: $brand_dir"
        return
    fi

    print_info "Copying brand assets (Brand: $brand_id)"

    [ -f "$brand_dir/bundle_config.json" ] && cp "$brand_dir/bundle_config.json" "$resources_dir/"

    if [ -d "$brand_dir/icons" ]; then
        cp "$brand_dir/icons"/*.{png,ico,icns} "$resources_dir/icons/" 2>/dev/null || true
    fi
}

# ============================================================================
# Main Build Process
# ============================================================================

print_header "JinGo Windows MinGW Build and Package"
echo "Qt Path:    $QT_DIR"
echo "MinGW Path: $MINGW_DIR"
echo "CMake Path: $CMAKE_BIN"
echo "Build Dir:  $BUILD_DIR"
echo "Build Type: $BUILD_TYPE"
[ -n "$BRAND" ] && echo "Brand:      $BRAND"
print_header ""

print_info "[0/4] Copying white-label assets"
copy_brand_assets
echo ""

[ "$CLEAN" = true ] && rm -rf "$BUILD_DIR"

# ============================================================================
# [1/4] Configure CMake
# ============================================================================

print_info "[1/4] Configuring CMake with MinGW..."
mkdir -p "$BUILD_DIR"

cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" \
    -G "MinGW Makefiles" \
    -DCMAKE_PREFIX_PATH="$QT_DIR" \
    -DCMAKE_C_COMPILER="$MINGW_DIR/bin/gcc.exe" \
    -DCMAKE_CXX_COMPILER="$MINGW_DIR/bin/g++.exe" \
    -DCMAKE_MAKE_PROGRAM="$MINGW_DIR/bin/mingw32-make.exe" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" || { print_error "CMake failed!"; exit 1; }

# ============================================================================
# [2/4] Build
# ============================================================================

print_info ""
print_info "[2/4] Building JinGo with MinGW..."

cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" -j4 || { print_error "Build failed!"; exit 1; }

# ============================================================================
# [3/4] Deploy
# ============================================================================

print_info ""
print_info "[3/4] Qt dependencies deployed automatically by CMake"
print_success "All Qt DLLs, plugins, and QML modules copied"
echo ""

# ============================================================================
# [4/4] Package
# ============================================================================

print_info "[4/4] Creating deployment package..."

BUILD_DATE=$(date +%Y%m%d)
VERSION="1.0.0"
BRAND_NAME="${BRAND:-jingo}"
PACKAGE_NAME="${BRAND_NAME}-${VERSION}-${BUILD_DATE}-windows.zip"
PKG_TEMP_DIR="$PKG_DIR/JinGo-$VERSION"

rm -rf "$PKG_TEMP_DIR"
mkdir -p "$PKG_TEMP_DIR"

cp "$BUILD_DIR/bin/JinGo.exe" "$PKG_TEMP_DIR/"
DLL_COUNT=$(find "$BUILD_DIR/bin" -maxdepth 1 -name "*.dll" -exec cp {} "$PKG_TEMP_DIR/" \; -print | wc -l)
print_success "Copied $DLL_COUNT DLL files"

for dir in bearer iconengines imageformats platforms styles translations tls qml dat; do
    [ -d "$BUILD_DIR/bin/$dir" ] && cp -r "$BUILD_DIR/bin/$dir" "$PKG_TEMP_DIR/"
done

cat > "$PKG_TEMP_DIR/README.txt" << EOF
JinGo VPN - Windows Distribution
================================
Version: $VERSION
Build Date: $(date '+%Y-%m-%d %H:%M:%S')
Platform: Windows 10/11 (64-bit)
EOF

ZIP_PATH="$PKG_DIR/$PACKAGE_NAME"
rm -f "$ZIP_PATH"
cd "$PKG_TEMP_DIR" && zip -r "$ZIP_PATH" . > /dev/null 2>&1
cd "$PROJECT_DIR"

[ -f "$ZIP_PATH" ] && print_success "ZIP created: $PACKAGE_NAME"

# ============================================================================
# [5/5] Release copy
# ============================================================================

if [ "$BUILD_TYPE" = "Release" ]; then
    print_info ""
    print_info "[5/5] Copying to release directory..."
    mkdir -p "$RELEASE_DIR"
    [ -f "$ZIP_PATH" ] && cp "$ZIP_PATH" "$RELEASE_DIR/" && print_success "Copied to: $RELEASE_DIR/$PACKAGE_NAME"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
print_header "*** BUILD COMPLETE ***"
echo "Build:    $BUILD_DIR/bin/JinGo.exe"
echo "Package:  $PKG_DIR/$PACKAGE_NAME"
[ "$BUILD_TYPE" = "Release" ] && echo "Release:  $RELEASE_DIR/$PACKAGE_NAME"
print_header ""
