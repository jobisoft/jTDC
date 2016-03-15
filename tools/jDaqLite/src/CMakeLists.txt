cmake_minimum_required(VERSION 2.6.0)
PROJECT(JDAQLITE)

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Woverloaded-virtual -Wshadow -Wextra")

# Use your own vmelib
add_library(vmelib vmelib/vmelib.cpp vmelib/include/vmelib.h) 

add_executable(jDAQLite jDAQLite.cpp)
target_link_libraries(jDAQLite vmelib)

INSTALL(TARGETS jDAQLite DESTINATION bin)
