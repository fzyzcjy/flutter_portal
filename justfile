publish_all:
    flutter pub publish --force --server=https://pub.dartlang.org

release old_version new_version:
    grep -q 'version: {{old_version}}' pubspec.yaml
    grep -q '{{new_version}}' CHANGELOG.md

    sed -i '' 's/version: {{old_version}}/version: {{new_version}}/g' pubspec.yaml

    git add --all
    git status && git diff --staged | grep ''
    git commit -m "bump from {{old_version}} to {{new_version}}"
    git push

    awk '/## {{new_version}}/{flag=1; next} /## {{old_version}}/{flag=0} flag' CHANGELOG.md | gh release create v{{new_version}} --notes-file "-" --draft --title v{{new_version}}
    echo 'A *DRAFT* release has been created. Please go to the webpage and really release if you find it correct.'
    open https://github.com/fzyzcjy/flutter_portal/releases

    just publish_all
