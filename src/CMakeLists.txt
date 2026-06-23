cmake_minimum_required(VERSION 3.28)
project(UWPMinGWPlayground VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)

configure_file(AppxManifest.in AppxManifest.xml)

uwp_add_appx(
    ${PROJECT_NAME}
    MANIFEST ${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml
    CERTIFICATE "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.pfx"
    SOURCES
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
        SimpleCommand.h
    RESOURCES
        SRC ${CMAKE_CURRENT_SOURCE_DIR}/Images
        DST Images
            *
        SRC ${CMAKE_CURRENT_SOURCE_DIR}
        DST .
            ${CMAKE_CURRENT_SOURCE_DIR}/*.xaml
)

uwp_install_appx(${PROJECT_NAME})
