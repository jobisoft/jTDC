cmake_minimum_required(VERSION 2.6.0)
PROJECT(JANALYZER)

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Woverloaded-virtual -Wshadow -Wextra")

# Use root-config to auto-include ROOT (root-config must be in PATH)
EXEC_PROGRAM( root-config ARGS "--incdir" OUTPUT_VARIABLE ROOT_INCLUDE_DIR RETURN_VALUE RETVAR1)
MESSAGE(STATUS "Found ROOT include path at ${ROOT_INCLUDE_DIR}")

EXEC_PROGRAM( root-config ARGS "--libdir" OUTPUT_VARIABLE ROOT_LIBRARY_DIR RETURN_VALUE RETVAR2)
MESSAGE(STATUS "Found ROOT library path at ${ROOT_LIBRARY_DIR}")

EXEC_PROGRAM( root-config ARGS "--cflags" OUTPUT_VARIABLE ROOT_CFLAGS RETURN_VALUE RETVAR3)
MESSAGE(STATUS "Using cflags from ROOT: ${ROOT_CFLAGS}")

IF(${RETVAR1}${RETVAR2}${RETVAR3} MATCHES "000")
	include_directories(${ROOT_INCLUDE_DIR})
	
	add_executable(jAnalyzer jAnalyzer.cpp)
	target_link_libraries(jAnalyzer -L${ROOT_LIBRARY_DIR} Core RIO Tree Hist MathCore)
	
	# Prefer our flags, but don't deny the ROOT ones: 
	SET(CMAKE_CXX_FLAGS "${ROOT_CFLAGS} ${CMAKE_CXX_FLAGS}")
	
	INSTALL(TARGETS jAnalyzer DESTINATION bin)	
ELSE()
	MESSAGE(FATAL_ERROR "ERROR: root-config did not provide LIBRARY and INCLUDE path, is ROOT installed and root-config in PATH?")
ENDIF()



 

