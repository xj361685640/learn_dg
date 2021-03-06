project(learn_dg Fortran)
cmake_minimum_required(VERSION 3.7)

#-----------------------------------------------------------------------------------
#                      CMake macros for adding source files
#-----------------------------------------------------------------------------------

# Includes the cmake_dependent_option macro used in profiling setting below
include(CMakeDependentOption)
# include(GNUInstallDirs)

include(cmake/macros/add_exe_sources.cmake)
include(cmake/macros/add_lib_sources.cmake)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/modules/")

# Set output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

#-----------------------------------------------------------------------------------
#                               Set default options
#-----------------------------------------------------------------------------------

# Default release build
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Choose the type of build. Options are: Debug Release" FORCE)
endif()

if(NOT PROFILE)
    set(PROFILE OFF CACHE BOOL "Choose to enable profiling. Options are: ON OFF" FORCE)
endif()

if(NOT USE_OPENMP)
    set(USE_OPENMP OFF CACHE BOOL "Choose to enable OpenMP. Options are: ON OFF" FORCE)
endif()

# If NOT CMAKE_CROSSCOMPILING, create a variable called PROFILE with default off
cmake_dependent_option(PROFILE
    "Use Profiling" OFF
    "NOT CMAKE_CROSSCOMPILING" OFF
)

message(STATUS " ")
message(STATUS "    Compiler: ${CMAKE_Fortran_COMPILER_ID}")
message(STATUS "    Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "    Profiling: ${PROFILE}")
message(STATUS "    OpenMP: ${USE_OPENMP}")


#-----------------------------------------------------------------------------------
#                               Set compiler flags
#-----------------------------------------------------------------------------------

if (CMAKE_Fortran_COMPILER_ID MATCHES GNU)
    if (CMAKE_Fortran_COMPILER_VERSION VERSION_LESS 6.2)
        message (FATAL_ERROR "Minimum required gfortran version is 6.2")
    endif()

    set (FFLAGS "-std=f2008 -fmax-errors=1 ${FFLAGS}")

    set (USER_COMPILE_FLAGS_DEBUG   "-O0 -cpp --coverage -ffree-form "
        "-ffree-line-length-none -fbacktrace "
        "-fstack-protector -fcheck=bounds "
        "-g "
    )
    string(REPLACE ";" " " USER_COMPILE_FLAGS_DEBUG "${USER_COMPILE_FLAGS_DEBUG}")

    set (USER_COMPILE_FLAGS_RELEASE "-O3 -cpp -ffree-form "
        "-ffree-line-length-none -fexternal-blas "
        "-march=native -funroll-loops "
    )
    string(REPLACE ";" " " USER_COMPILE_FLAGS_RELEASE "${USER_COMPILE_FLAGS_RELEASE}")

    set (CMAKE_Fortran_LINK_FLAGS_DEBUG "-O0 --coverage ")
    set (CMAKE_Fortran_LINK_FLAGS_RELEASE "-O3 ")

    set (PROFILE_FLAGS "-p ")

elseif (CMAKE_Fortran_COMPILER_ID MATCHES PGI)

    set (USER_COMPILE_FLAGS_DEBUG   "-O0 -g ")
    string(REPLACE ";" " " USER_COMPILE_FLAGS_DEBUG "${USER_COMPILE_FLAGS_DEBUG}")

    set (USER_COMPILE_FLAGS_RELEASE "-O4 "
    )
    string(REPLACE ";" " " USER_COMPILE_FLAGS_RELEASE "${USER_COMPILE_FLAGS_RELEASE}")

    set (CMAKE_Fortran_LINK_FLAGS_DEBUG "-O0 -g ")
    set (CMAKE_Fortran_LINK_FLAGS_RELEASE "-O4 ")

    set (PROFILE_FLAGS "-p ")

endif()

# Append user flags to debug and release variables
set (CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} ${FFLAGS} ${USER_COMPILE_FLAGS_DEBUG}")
set (CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} ${FFLAGS} ${USER_COMPILE_FLAGS_RELEASE}")

# Append profile flags

if (PROFILE)
    set (CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} ${PROFILE_FLAGS}")
    set (CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} ${PROFILE_FLAGS}")
endif()


#----------------------------------------------------------------------------------------------
#                                         Find Lapack
#----------------------------------------------------------------------------------------------

message(STATUS " ")
message(STATUS "BLAS/LAPACK Summary:")
find_package(LAPACK REQUIRED)
message(STATUS "    LAPACK Libraries: ")
foreach (lib ${LAPACK_LIBRARIES})
    message(STATUS "        " ${lib})
endforeach()


#----------------------------------------------------------------------------------------------
#                                         Find OpenMP
#----------------------------------------------------------------------------------------------

if (USE_OPENMP)
    message(STATUS " ")
    message(STATUS "Looking for OpenMP Libraries")
    find_package(OpenMP REQUIRED)
    if (OPENMP_FOUND)
        message(STATUS "    OpenMP Libraries Found")
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
        set (CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${OpenMP_Fortran_FLAGS}")
        set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
    endif()
endif()


#----------------------------------------------------------------------------------------------
#                                   Add source tree and includes
#----------------------------------------------------------------------------------------------

add_subdirectory(src)

#----------------------------------------------------------------------------------------------
#                                         Build libraries
#----------------------------------------------------------------------------------------------

set(LIB_NAME "core")
message(STATUS " ")

add_library(core-obj OBJECT ${LIB_SRCS}) # Compile object files only once
set_target_properties( core-obj
    PROPERTIES
    Fortran_MODULE_DIRECTORY     core-obj
    COMPILE_FLAGS   "${CMAKE_Fortran_FLAGS}"
    LINK_FLAGS      "${CMAKE_Fortran_LINK_FLAGS}"
    POSITION_INDEPENDENT_CODE ON
)

add_library(core-static STATIC $<TARGET_OBJECTS:core-obj>) # Static library
add_library(core-shared SHARED $<TARGET_OBJECTS:core-obj>) # Shared library

foreach( mylib core-shared core-static )
    target_link_libraries( ${mylib}
        ${LAPACK_LIBRARIES}
        ${BLAS_LIBRARIES}
    )

    set_target_properties( ${mylib}
        PROPERTIES
        OUTPUT_NAME     ${LIB_NAME}
        Fortran_MODULE_DIRECTORY core-obj
    )
endforeach()


#----------------------------------------------------------------------------------------------
#                                       Build Executables
#----------------------------------------------------------------------------------------------
# Add driver executable linked to core library
# add_executable(main ${EXE_SRCS})

set (lib_name core-static)
# set (lib_name core-shared)
foreach( SOURCE_FILE ${EXE_SRCS} )
    string( REPLACE ".f90" "" SOURCE_NAME ${SOURCE_FILE} )
    string( REPLACE "src/" "" SOURCE_NAME ${SOURCE_NAME} )
    add_executable( ${SOURCE_NAME} ${SOURCE_FILE} )
    target_link_libraries( ${SOURCE_NAME} ${lib_name} )
    set_target_properties( ${SOURCE_NAME}
        PROPERTIES
        COMPILE_FLAGS "${CMAKE_Fortran_FLAGS}"
        LINK_FLAGS    "${CMAKE_Fortran_LINK_FLAGS}"
        POSITION_INDEPENDENT_CODE ON
        Fortran_MODULE_DIRECTORY core-obj
    )
endforeach( SOURCE_FILE ${EXE_SRCS} )
