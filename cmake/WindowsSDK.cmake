function(_uwp_find_windows_sdk)
    set(REGS
        "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots"
        "HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows Kits\\Installed Roots"
    )

    foreach(REG IN LISTS REGS)
        cmake_host_system_information(RESULT KITS_ROOT
            QUERY WINDOWS_REGISTRY ${REG}
            VALUE "KitsRoot10"
        )
        if(EXISTS "${KITS_ROOT}")
            set(UWP_WINDOWS_KITS_ROOT "${KITS_ROOT}")
            set(UWP_WINDOWS_KITS_ROOT "${KITS_ROOT}" PARENT_SCOPE)
            break()
        endif()
    endforeach()

    if(NOT UWP_WINDOWS_KITS_ROOT)
        message(FATAL_ERROR "Failed to determine Windows 10 SDK location.")
    endif()

    # Find all Windows 10 SDK versions available by scanning what binaries are provided.
    file(GLOB SDK_BIN_DIRS RELATIVE
        "${UWP_WINDOWS_KITS_ROOT}/bin"
        "${UWP_WINDOWS_KITS_ROOT}/bin/10.*"
    )

    set(UWP_LATEST_SDK_VERSION "0.0.0.0")
    foreach(DIR IN LISTS SDK_BIN_DIRS)
        # Find an SDK that also has WDK for kernel headers and libraries for the target arch.
        if(IS_DIRECTORY "${UWP_WINDOWS_KITS_ROOT}/bin/${DIR}/${UWP_HOST_SDK_ARCH}" AND
           IS_DIRECTORY "${UWP_WINDOWS_KITS_ROOT}/Lib/${DIR}/km/${UWP_SDK_ARCH}" AND
           IS_DIRECTORY "${UWP_WINDOWS_KITS_ROOT}/Include/${DIR}/km")
            if(DIR VERSION_GREATER UWP_LATEST_SDK_VERSION)
                set(UWP_LATEST_SDK_VERSION "${DIR}" PARENT_SCOPE)
            endif()
        endif()
    endforeach()
endfunction()

if(NOT UWP_MAKEAPPX_EXECUTABLE)
    _uwp_find_windows_sdk()

    find_program(UWP_MAKEAPPX_EXECUTABLE
        NAMES makeappx.exe
        HINTS "${UWP_WINDOWS_KITS_ROOT}/bin/${UWP_LATEST_SDK_VERSION}/${UWP_HOST_SDK_ARCH}"
        REQUIRED
    )
endif()
