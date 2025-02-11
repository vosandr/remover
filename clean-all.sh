#!/bin/bash

# Функция для проверки необходимости очистки
function should_clean() {
  local project_type=$1
  local path=$2

  case $project_type in
    "flutter")
      if [ -d "$path/build" ]; then
        echo "Требуется очистка Flutter-проекта в $path"
        return 0
      else
        echo "Очистка не требуется для Flutter-проекта в $path"
        return 1
      fi
      ;;
    "dart")
      if [ -d "$path/build" ]; then
        echo "Требуется очистка Dart-проекта в $path"
        return 0
      else
        echo "Очистка не требуется для Dart-проекта в $path"
        return 1
      fi
      ;;
    "js")
      if [ -d "$path/node_modules" ]; then
        echo "Требуется очистка JS-проекта в $path"
        return 0
      else
        echo "Очистка не требуется для JS-проекта в $path"
        return 1
      fi
      ;;
    "java")
      if [ -d "$path/build" ]; then
        echo "Требуется очистка Java-проекта в $path"
        return 0
      else
        echo "Очистка не требуется для Java-проекта в $path"
        return 1
      fi
      ;;
    "swift")
      if [ -d "$path/build" ]; then
        echo "Требуется очистка Swift-проекта в $path"
        return 0
      else
        echo "Очистка не требуется для Swift-проекта в $path"
        return 1
      fi
      ;;
    "cpp")
      if [ -d "$path/build" ]; then
        echo "Требуется очистка C++-проекта в $path"
        return 0
      else
        echo "Очистка не требуется для C++-проекта в $path"
        return 1
      fi
      ;;
    *)
      echo "Неизвестный тип проекта в $path"
      return 1
      ;;
  esac
}

# Функция для параллельного выполнения очистки
function parallel_clean() {
  max_jobs=$(( $(nproc) * 2 ))
  jobs=()

  for entry in "$1"/*; do
    if [ -d "$entry" ]; then
      if [ -f "$entry/pubspec.yaml" ]; then
        if should_clean "flutter" "$entry"; then
          jobs+=("cd $entry && flutter clean")
        fi
      elif [ -d "$entry/.dart_tool" ]; then
        if should_clean "dart" "$entry"; then
          jobs+=("cd $entry && dart clean")
        fi
      elif [ -f "$entry/package.json" ] || [ -f "$entry/yarn.lock" ]; then
        if should_clean "js" "$entry"; then
          jobs+=("cd $entry && rm -rf node_modules")
        fi
      elif [ -f "$entry/build.gradle" ] || [ -f "$entry/pom.xml" ]; then
        if should_clean "java" "$entry"; then
          jobs+=("(cd $entry && gradle clean || mvn clean)")
        fi
      elif [ -f "$entry/Podfile" ] || [ -f "$entry/xcodeproj/project.pbxproj" ]; then
        if should_clean "swift" "$entry"; then
          jobs+=("cd $entry && xcodebuild clean")
        fi
      elif [ -f "$entry/CMakeLists.txt" ]; then
        if should_clean "cpp" "$entry"; then
          jobs+=("cd $entry && make clean")
        fi
      fi
    fi
  done

  for job in "${jobs[@]}"; do
    { eval "$job" & }
    ((i++))
    if [[ $i -eq $max_jobs ]]; then
      wait
      i=0
    fi
  done
  wait
}

# Вызываем функцию для текущей директории
parallel_clean .
