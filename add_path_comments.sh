#!/bin/bash

# lib 디렉토리 내의 모든 .dart 파일을 찾아서 처리
find lib -name "*.dart" | while read file; do
    # 파일의 이미 첫 줄에 경로 주석이 있는지 확인
    if ! grep -q "// $file" "$file"; then
        # 임시 파일에 주석 추가 및 본문 내용을 병합
        echo "// $file" > temp_file
        cat "$file" >> temp_file
        mv temp_file "$file"
        echo "Added path comment to $file"
    fi
done