#!/bin/bash
# 修正 GitHub Actions 配置

echo "🔧 修正 GitHub Actions 配置..."

# 備份原檔案
if [ -f ".github/workflows/build-with-custom-sdk.yml" ]; then
    cp .github/workflows/build-with-custom-sdk.yml .github/workflows/build-with-custom-sdk.yml.bak
    echo "✅ 已備份原檔案到 build-with-custom-sdk.yml.bak"
fi

# 修正 repository 格式（移除 https://github.com/）
if [ -f ".github/workflows/build-with-custom-sdk.yml" ]; then
    # macOS 和 Linux 的 sed 語法不同
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|SDK_CORE_REPO: 'https://github.com/team-k2/openim-sdk-core'|SDK_CORE_REPO: 'team-k2/openim-sdk-core'|g" .github/workflows/build-with-custom-sdk.yml
    else
        # Linux
        sed -i "s|SDK_CORE_REPO: 'https://github.com/team-k2/openim-sdk-core'|SDK_CORE_REPO: 'team-k2/openim-sdk-core'|g" .github/workflows/build-with-custom-sdk.yml
    fi
    echo "✅ 已修正 repository 格式"
fi

# 驗證修正
if grep -q "SDK_CORE_REPO: 'team-k2/openim-sdk-core'" .github/workflows/build-with-custom-sdk.yml; then
    echo "✅ 配置已成功修正！"
    echo ""
    echo "📋 當前設定："
    grep "SDK_CORE_REPO:" .github/workflows/build-with-custom-sdk.yml
    grep "SDK_CORE_BRANCH:" .github/workflows/build-with-custom-sdk.yml
    echo ""
    echo "🚀 下一步："
    echo "1. 提交修改："
    echo "   git add .github/workflows/build-with-custom-sdk.yml"
    echo "   git commit -m 'fix: Correct GitHub Actions repository format'"
    echo "   git push"
    echo ""
    echo "2. 或手動觸發 workflow："
    echo "   GitHub → Actions → Build FFI with Custom SDK Core → Run workflow"
else
    echo "❌ 修正失敗，請手動編輯檔案"
    echo "將第 19 行改為："
    echo "  SDK_CORE_REPO: 'team-k2/openim-sdk-core'"
fi