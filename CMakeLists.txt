cmake_minimum_required(VERSION 3.21)

project(untitled2 VERSION 0.1 LANGUAGES CXX C)
if (WIN32)
    enable_language(ASM_NASM)
else()
    enable_language(ASM)
endif()


set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Silence "missing .note.GNU-stack section implies executable stack"
if (LINUX)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -z noexecstack")
endif()

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick Widgets Charts)
qt_standard_project_setup(REQUIRES 6.4)

qt_add_executable(appuntitled2
        main.cpp
        $<$<PLATFORM_ID:Linux>:
        MemoryLatency_x86.s
        MemoryLatencyLinux.c
        >
        $<$<PLATFORM_ID:Windows>:
        MemoryLatency.c
        MemoryLatencyFunctions.asm
        >
)


qt_add_qml_module(appuntitled2
    URI untitled2
    VERSION 1.0
    QML_FILES Main.qml App.qml ResultPane.qml
    SOURCES MemoryLatency.h
    RESOURCE_PREFIX /qt/qml/
)

set_target_properties(appuntitled2 PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appuntitled2 PUBLIC
    PRIVATE Qt6::Quick Qt6::Widgets Qt6::Charts
)

install(TARGETS appuntitled2
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if (CMAKE_IMPORT_LIBRARY_SUFFIX)
add_custom_command(TARGET appuntitled2 POST_BUILD 
    COMMAND Qt6::windeployqt
    ARGS $<TARGET_FILE:appuntitled2>
)
endif ()
