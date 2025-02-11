#!/bin/bash

# Функция для проверки необходимости очистки
function should_clean() {
  local project_type=$1
  local path=$2

  case $project_type in
    "flutter")
      if [ -d "$path/build" ]; then
        echo "Cleaning required for Flutter project in $path"
        return 0
      else
        echo "Cleaning not required for Flutter project in $path"
        return 1
      fi
      ;;
    "dart")
      if [ -d "$path/build" ]; then
        echo "Cleaning required for Dart project in $path"
        return 0
      else
        echo "Cleaning not required for Dart project in $path"
        return 1
      fi
      ;;
    "js")
      if [ -d "$path/node_modules" ]; then
        echo "Cleaning required for JS project in $path"
        return 0
      else
        echo "Cleaning not required for JS project in $path"
        return 1
      fi
      ;;
    "java")
      if [ -d "$path/build" ]; then
        echo "Cleaning required for Java project in $path"
        return 0
      else
        echo "Cleaning not required for Java project in $path"
        return 1
      fi
      ;;
    "swift")
      if [ -d "$path/build" ]; then
        echo "Cleaning required for Swift project in $path"
        return 0
      else
        echo "Cleaning not required for Swift project in $path"
        return 1
      fi
      ;;
    "cpp")
      if [ -d "$path/build" ]; then
        echo "Cleaning required for C++ project in $path"
        return 0
      else
        echo "Cleaning not required for C++ project in $path"
        return 1
      fi
      ;;
    *)
      echo "Unknown project type in $path"
      return 1
      ;;
  esac
}

# Function for parallel execution of cleaning
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

# Call the function for the current directory
parallel_clean .
