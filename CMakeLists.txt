cmake_minimum_required(VERSION 4.2)
project(UWPMinGWPlayground)

include(cmake/Architecture.cmake)
include(cmake/ThirdParty.cmake)

include(cmake/WindowsSDK.cmake)

include(cmake/AppX.cmake)

include(cmake/PDB.cmake)

add_subdirectory(src)
