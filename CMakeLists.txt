cmake_minimum_required(VERSION 3.16)

project(TestChangelog VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# CRITICAL: This tells CMake to generate MOC files for signals/properties
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Find Qt5
find_package(Qt5 REQUIRED COMPONENTS Core Quick)

set(PROJECT_SOURCES
    main.cpp
    ChangeLogManager.h
    ChangeLogManager.cpp
    resources.qrc
)

add_executable(TestChangelog ${PROJECT_SOURCES})

target_link_libraries(TestChangelog PRIVATE
    Qt5::Core
    Qt5::Quick
)

set_target_properties(TestChangelog PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.TestChangelog
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)
