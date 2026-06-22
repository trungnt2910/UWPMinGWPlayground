include(ExternalProject)

# These third-party deps here are meant to be built for the **host** system.

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
