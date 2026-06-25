include(CMakeParseArguments)

function(uwp_add_appx NAME)
    set(OPTIONS "")
    set(ONE_VALUE_ARGS MANIFEST CERTIFICATE)
    set(MULTI_VALUE_ARGS SOURCES RESOURCES)
    cmake_parse_arguments(ARG "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN})

    # Main Executable
    add_executable(${NAME} WIN32 ${ARG_SOURCES})
    set_target_properties(${NAME} PROPERTIES OUTPUT_NAME "${NAME}")
    target_include_directories(${NAME} PRIVATE ${UWP_WINRT_INCLUDE_DIR})
    add_dependencies(${NAME} ${UWP_WINRT_INCLUDE_TARGET})
    target_link_libraries(${NAME} ucrtapp windowsapp winstorecompat)
    target_link_options(${NAME} PRIVATE -municode -static -Wl,--appcontainer)

    # AppX
    set(APPX_BASE ${CMAKE_CURRENT_BINARY_DIR}/${NAME}-appx)
    set(APPX_FILES "")

    set(APPX_MANIFEST ${APPX_BASE}/AppxManifest.xml)
    add_custom_command(
        OUTPUT "${APPX_MANIFEST}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${ARG_MANIFEST}" "${APPX_MANIFEST}"
        DEPENDS "${ARG_MANIFEST}"
        COMMENT "Copying AppX manifest ${APPX_MANIFEST}"
    )
    list(APPEND APPX_FILES "${APPX_MANIFEST}")
    set(APPX_EXE ${APPX_BASE}/${NAME}.exe)
    add_custom_command(
        OUTPUT "${APPX_EXE}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE_NAME:${NAME}>"
            "${APPX_EXE}"
        DEPENDS ${NAME}
        COMMENT "Copying AppX executable ${APPX_EXE}"
    )
    list(APPEND APPX_FILES "${APPX_EXE}")

    # RESOURCE_GROUPS: List of all declared resource groups.
    # For each group:
    # RES_SRC_${GROUP_NAME}: Source of resource group.
    # RES_DST_${GROUP_NAME}: Destination of resource group, relative to AppX path.
    # RES_FILES_${GROUP_NAME}: List of files to include, relative to resource group source.
    set(RESOURCE_GROUPS "")
    set(RES_ARG_TYPE "")
    foreach(RES_ARG IN LISTS ARG_RESOURCES)
        if(RES_ARG_TYPE STREQUAL "SRC")
            set(GROUP_SRC "${RES_ARG}")
            set(RES_ARG_TYPE "")
        elseif(RES_ARG_TYPE STREQUAL "DST")
            set(GROUP_DST "${RES_ARG}")
            set(RES_ARG_TYPE "")
            string(MAKE_C_IDENTIFIER "${GROUP_DST}" GROUP_NAME)
            list(APPEND RESOURCE_GROUPS "${GROUP_NAME}")
            set(RES_SRC_${GROUP_NAME} "${GROUP_SRC}")
            set(RES_DST_${GROUP_NAME} "${GROUP_DST}")
            set(RES_GLOBS_${GROUP_NAME} "")
        elseif(RES_ARG STREQUAL "SRC")
            set(RES_ARG_TYPE "SRC")
        elseif(RES_ARG STREQUAL "DST")
            set(RES_ARG_TYPE "DST")
        else()
            if(NOT GROUP_SRC OR NOT GROUP_DST)
                message(FATAL_ERROR "uwp_add_appx: Cannot declare files before SRC and DST.")
            endif()
            string(MAKE_C_IDENTIFIER "${GROUP_DST}" GROUP_NAME)
            list(APPEND RES_GLOBS_${GROUP_NAME} "${RES_ARG}")
        endif()
    endforeach()
    foreach(GROUP_NAME IN LISTS RESOURCE_GROUPS)
        set(GROUP_SRC "${RES_SRC_${GROUP_NAME}}")
        set(GROUP_GLOBS "${RES_GLOBS_${GROUP_NAME}}")
        set(GROUP_ITEMS "")
        if(NOT GROUP_GLOBS)
            set(GROUP_GLOBS "*")
        endif()
        cmake_path(SET GROUP_SRC NORMALIZE "${GROUP_SRC}")
        foreach(GLOB IN LISTS GROUP_GLOBS)
            if(IS_ABSOLUTE "${GLOB}")
                cmake_path(SET GLOB_ABSOLUTE NORMALIZE "${GLOB}")
            else()
                cmake_path(SET GLOB_ABSOLUTE NORMALIZE "${GROUP_SRC}")
                cmake_path(APPEND GLOB_ABSOLUTE "${GLOB}")
            endif()
            file(GLOB GLOB_ITEMS CONFIGURE_DEPENDS "${GLOB_ABSOLUTE}")
            if(GLOB_ITEMS)
                list(APPEND GROUP_ITEMS ${GLOB_ITEMS})
            else()
                message(WARNING "uwp_add_appx: Pattern did not match any file: ${GLOB_ABSOLUTE}.")
            endif()
        endforeach()
        foreach(GROUP_ITEM IN LISTS GROUP_ITEMS)
            cmake_path(IS_PREFIX GROUP_SRC "${GROUP_ITEM}" IS_DESCENDANT)
            if(NOT IS_DESCENDANT)
                message(FATAL_ERROR "uwp_add_appx: ${GROUP_ITEM} is not inside ${GROUP_SRC}.")
            endif()
            cmake_path(
                RELATIVE_PATH GROUP_ITEM
                BASE_DIRECTORY "${GROUP_SRC}"
                OUTPUT_VARIABLE GROUP_ITEM_RELATIVE
            )
            list(APPEND RES_FILES_${GROUP_NAME} ${GROUP_ITEM_RELATIVE})
        endforeach()
    endforeach()

    # Copy AppX Resources
    foreach(GROUP_NAME IN LISTS RESOURCE_GROUPS)
        set(GROUP_SRC "${RES_SRC_${GROUP_NAME}}")
        set(GROUP_DST "${RES_DST_${GROUP_NAME}}")
        set(GROUP_FILES "${RES_FILES_${GROUP_NAME}}")
        foreach(FILE IN LISTS GROUP_FILES)
            set(FILE_SRC ${GROUP_SRC}/${FILE})
            set(FILE_DST ${APPX_BASE}/${GROUP_DST}/${FILE})
            add_custom_command(
                OUTPUT ${FILE_DST}
                COMMAND ${CMAKE_COMMAND} -E copy_if_different ${FILE_SRC} ${FILE_DST}
                DEPENDS ${FILE_SRC}
                COMMENT "Copying AppX resource ${FILE_DST}"
            )
            list(APPEND APPX_FILES "${FILE_DST}")
        endforeach()
    endforeach()

    set(APPX_TARGET ${NAME}-appx)
    set(APPX_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${NAME}.appx")
    set(APPX_CER "${CMAKE_CURRENT_BINARY_DIR}/${NAME}.cer")
    add_custom_target(
        ${APPX_TARGET}
        ALL
        COMMAND
            "${UWP_MAKEAPPX_EXECUTABLE}" pack
                -o
                -d "${APPX_BASE}"
                -p "${APPX_OUTPUT}"
        COMMAND
            ${UWP_CCKY_EXECUTABLE} signtool sign
                /fd SHA256
                /f "${ARG_CERTIFICATE}"
                "${APPX_OUTPUT}"
        COMMAND
            ${UWP_CCKY_EXECUTABLE} certmgr /put /c "${APPX_OUTPUT}" "${APPX_CER}"
        DEPENDS
            ${UWP_MAKEAPPX_TARGET} ${UWP_CCKY_TARGET}
            ${ARG_CERTIFICATE}
            ${APPX_FILES}
    )
    set_target_properties(
        ${APPX_TARGET} PROPERTIES
            ADDITIONAL_CLEAN_FILES "${APPX_BASE};${APPX_OUTPUT};${APPX_CER}"
    )
endfunction()

function(uwp_install_appx NAME)
    set(APPX_PATH ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.appx)
    install(
        FILES
            ${APPX_PATH}
            ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.cer
        DESTINATION "."
    )

    function(_uwp_appx_is_deployable OUT_RESULT)
        set(${OUT_RESULT} FALSE PARENT_SCOPE)
        if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
            return()
        endif()
        string(TOLOWER "${UWP_HOST_SDK_ARCH}" ARCH_HOST)
        string(TOLOWER "${UWP_APPX_ARCH}" ARCH_APPX)
        if(ARCH_HOST STREQUAL ARCH_APPX)
            set(${OUT_RESULT} TRUE PARENT_SCOPE)
        elseif(ARCH_HOST STREQUAL "x64")
            # 32-bit can be deployed on 64-bit via WoW64.
            if(ARCH_APPX STREQUAL "x86")
                set(${OUT_RESULT} TRUE PARENT_SCOPE)
            endif()
        elseif(ARCH_HOST STREQUAL "arm64")
            # Intel-family packages can run on ARM64 via emulation.
            if(ARCH_APPX MATCHES "x64|x86")
                set(${OUT_RESULT} TRUE PARENT_SCOPE)
            endif()
            # TODO: This is not true for all Windows versions.
            # For older Windows, ARM64 cannot emulate x64.
            # However, they do have backwards compatibility with ARM.
        endif()
    endfunction()

    _uwp_appx_is_deployable(APPX_DEPLOYABLE)
    if(APPX_DEPLOYABLE)
        install(CODE "
            message(STATUS \"Deploying: ${APPX_PATH}\")
            execute_process(
                COMMAND powershell.exe -NoProfile -NonInteractive -Command
                    \"Add-Type -Assembly System.IO.Compression.FileSystem;                      \"
                    \"\$zip = [IO.Compression.ZipFile]::OpenRead('${APPX_PATH}');               \"
                    \"\$entry = \$zip.Entries | Where-Object {                                  \"
                    \"  \$_.Name -eq 'AppxManifest.xml'                                         \"
                    \"};                                                                        \"
                    \"\$reader = New-Object IO.StreamReader(\$entry.Open());                    \"
                    \"[xml]\$manifest = \$reader.ReadToEnd();                                   \"
                    \"\$id = \$manifest.Package.Identity.Name;                                  \"

                    \"\$oldPackage = Get-AppxPackage | Where-Object { \$_.Name -eq \$id };      \"
                    \"if (\$oldPackage) {                                                       \"
                    \"  Remove-AppxPackage                                                      \"
                    \"      -Package \$oldPackage.PackageFullName                               \"
                    \"      -ErrorAction SilentlyContinue                                       \"
                    \"};                                                                        \"

                    \"Add-AppxPackage                                                           \"
                    \"  -Path '${APPX_PATH}'                                                    \"
                    \"  -ForceApplicationShutdown                                               \"
                    \"  -ForceUpdateFromAnyVersion                                              \"
                    \"  -AllowUnsigned;                                                         \"

                    \"\$newPackage = Get-AppxPackage | Where-Object { \$_.Name -eq \$id };      \"
                    \"\$familyName = \$newPackage.PackageFamilyName;                            \"
                    \"\$appId = \$manifest.Package.Applications.Application.Id;                 \"
                    \"Start-Process \\\"shell:AppsFolder\\\\\$familyName!\$appId\\\";           \"
            )
        ")
    endif()
endfunction()
