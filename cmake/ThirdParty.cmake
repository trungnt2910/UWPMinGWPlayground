include(ExternalProject)

# These third-party tools here are meant to be built for the **host** system.

set(UWP_THIRD_PARTY_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/ThirdParty")

ExternalProject_Add(
    cppwinrt
    GIT_REPOSITORY  https://github.com/microsoft/cppwinrt.git
    GIT_TAG         febda5dfa1d5840096e5d94c5f317b770f4cbf86

    USES_TERMINAL_CONFIGURE TRUE
    USES_TERMINAL_BUILD     TRUE
    USES_TERMINAL_INSTALL   TRUE

    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${UWP_THIRD_PARTY_INSTALL_DIR}
        -DBUILD_TESTING=FALSE
)
ExternalProject_Add_StepTargets(cppwinrt install)
set(UWP_CPPWINRT_EXECUTABLE "${UWP_THIRD_PARTY_INSTALL_DIR}/bin/cppwinrt")
set(UWP_CPPWINRT_TARGET cppwinrt-install)

if(NOT CMAKE_HOST_WIN32)
    ExternalProject_Add(
        msix-packaging
        GIT_REPOSITORY  https://github.com/microsoft/msix-packaging
        GIT_TAG         master

        USES_TERMINAL_CONFIGURE TRUE
        USES_TERMINAL_BUILD     TRUE
        USES_TERMINAL_INSTALL   TRUE

        CMAKE_ARGS
            -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_INSTALL_PREFIX=${UWP_THIRD_PARTY_INSTALL_DIR}
    )
    ExternalProject_Add_StepTargets(msix-packaging install)
    set(UWP_MAKEAPPX_EXECUTABLE "${UWP_THIRD_PARTY_INSTALL_DIR}/bin/makemsix")
    set(UWP_MAKEAPPX_TARGET msix-packaging-install)
endif()

ExternalProject_Add(
    ccky
    # TODO: Move to new trungnt2910/ccky name when upstream is ready.
    GIT_REPOSITORY  https://github.com/trungnt2910/SignToolPlayground
    GIT_TAG         master

    USES_TERMINAL_CONFIGURE TRUE
    USES_TERMINAL_BUILD     TRUE
    USES_TERMINAL_INSTALL   TRUE

    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${UWP_THIRD_PARTY_INSTALL_DIR}
)
ExternalProject_Add_StepTargets(ccky install)
set(UWP_CCKY_EXECUTABLE "${UWP_THIRD_PARTY_INSTALL_DIR}/bin/ccky")
set(UWP_CCKY_TARGET ccky-install)

# See https://www.nuget.org/packages/Microsoft.Windows.SDK.Contracts for all versions.
set(
    UWP_CONTRACTS_VERSION
    # This is the oldest version available on NuGet.
    # To target RS2 Windows (e.g. 15035 ARM, W10M), we need to refrain from using RS3+ APIs.
    "10.0.17134.1000"
    CACHE
    STRING "The version of Microsoft.Windows.SDK.Contracts to use"
)
set(UWP_NUGET_API_BASE "https://www.nuget.org/api/v2/package")
ExternalProject_Add(
    microsoft-windows-sdk-contracts
    URL "${UWP_NUGET_API_BASE}/Microsoft.Windows.SDK.Contracts/${UWP_CONTRACTS_VERSION}"

    DEPENDS ${UWP_CPPWINRT_TARGET}

    CONFIGURE_COMMAND ""
    BUILD_COMMAND
        ${UWP_CPPWINRT_EXECUTABLE}
            -pch <BINARY_DIR>
            -input <SOURCE_DIR>/ref/netstandard2.0
            -output <BINARY_DIR>/include
    INSTALL_COMMAND
        ${CMAKE_COMMAND} -E copy_directory_if_newer
            <BINARY_DIR>/include
            ${UWP_THIRD_PARTY_INSTALL_DIR}/include
)
ExternalProject_Add_StepTargets(microsoft-windows-sdk-contracts install)
# TODO: Maybe let AppX.cmake handle the build instead?
# It does not seem right when ${UWP_THIRD_PARTY_INSTALL_DIR}/bin contains host tools while
# ${UWP_THIRD_PARTY_INSTALL_DIR}/include contains target headers.
set(UWP_WINRT_INCLUDE_DIR "${UWP_THIRD_PARTY_INSTALL_DIR}/include")
set(UWP_WINRT_INCLUDE_TARGET microsoft-windows-sdk-contracts-install)
