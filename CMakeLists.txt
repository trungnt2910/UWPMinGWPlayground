cmake_minimum_required(VERSION 3.28)
project(UWPMinGWPlayground)

include(cmake/Architecture.cmake)
include(cmake/ThirdParty.cmake)

include(cmake/WindowsSDK.cmake)

include(cmake/AppX.cmake)

add_subdirectory(src)
