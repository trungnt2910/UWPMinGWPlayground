cmake_minimum_required(VERSION 3.28)
project(UWPMinGWPlayground VERSION 0.1.0)

include(CheckCSourceCompiles)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)

message(STATUS "Building for ${UWP_APPX_ARCH}.")

file(COPY Images MainWindowView.xaml DESTINATION ${CMAKE_BINARY_DIR})
configure_file(AppxManifest.in AppxManifest.xml)

set(CPPWINRT_INPUT "references/Windows.winmd")
set(CPPWINRT_OUTPUT_DIR "${CMAKE_BINARY_DIR}/cppwinrt")

add_custom_command(
    OUTPUT
        ${CPPWINRT_OUTPUT_DIR}/winrt/base.h
    COMMAND
        ${UWP_CPPWINRT_EXECUTABLE} -pch . -input ${CPPWINRT_INPUT} -output ${CPPWINRT_OUTPUT_DIR}
    WORKING_DIRECTORY
        ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT
        "Generating C++/WinRT Headers..."
    DEPENDS
        ${UWP_CPPWINRT_TARGET}
)

set(SOURCES
    ${CPPWINRT_OUTPUT_DIR}/winrt/base.h
    App.cpp
    Property.hpp
    MainWindowView.cpp
    MainWindowView.h
    MainWindowViewModel.cpp
    MainWindowViewModel.h
    ListItem.cpp
    ListItem.h
    NegativeDoubleConverter.cpp
    NegativeDoubleConverter.h
    SimpleCommand.cpp
    SimpleCommand.h)

add_executable(${PROJECT_NAME} WIN32 ${SOURCES})
include_directories(${CPPWINRT_OUTPUT_DIR})

target_link_libraries(${PROJECT_NAME} ucrtapp windowsapp winstorecompat)
target_link_options(${PROJECT_NAME} PRIVATE -municode -static -Wl,--appcontainer)

add_custom_target(appx ALL
    COMMAND
        ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/appx/Images"
    COMMAND
        ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/MainWindowView.xaml
            AppxManifest.xml
            "${PROJECT_NAME}.exe"
            "${CMAKE_CURRENT_BINARY_DIR}/appx"
    COMMAND
        ${CMAKE_COMMAND} -E copy_directory_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/Images" "${CMAKE_CURRENT_BINARY_DIR}/appx/Images"
    COMMAND
        ${UWP_MAKEAPPX_EXECUTABLE} pack
            -o
            -d "${CMAKE_CURRENT_BINARY_DIR}/appx"
            -p "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.appx"
    COMMAND
        ${UWP_CCKY_EXECUTABLE} signtool sign
            /fd SHA256
            /f "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.pfx"
            ${PROJECT_NAME}.appx
    COMMAND
        ${UWP_CCKY_EXECUTABLE} certmgr /put /c ${PROJECT_NAME}.appx ${PROJECT_NAME}.cer
    DEPENDS "${PROJECT_NAME}.exe" ${UWP_MAKEAPPX_TARGET} ${UWP_CCKY_TARGET}
)

install(
    FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.appx
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.cer
    DESTINATION "."
)
