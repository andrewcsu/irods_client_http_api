# Copyright (c) 2024 iRODS Consortium
# Distributed under the Boost Software License, Version 1.0.

include(ProcessorCount)
ProcessorCount(PROCESSOR_COUNT)

# Configure fuzzing parameters
set(IRODS_HTTP_FUZZER_TOTAL_TIME 300 CACHE STRING "Total time for fuzzing")
set(IRODS_HTTP_FUZZER_RSS_LIMIT 8192 CACHE STRING "RSS limit for fuzzing")
set(IRODS_HTTP_FUZZER_TIMEOUT 30 CACHE STRING "Timeout for fuzzing")
set(IRODS_HTTP_FUZZER_MAX_LEN 4000 CACHE STRING "Maximum size of the input")
set(IRODS_HTTP_FUZZER_JOBS ${PROCESSOR_COUNT} CACHE STRING "Number of jobs for fuzzing")

# Setup corpus directories
set(IRODS_HTTP_FUZZER_SEEDS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/seeds)
set(IRODS_HTTP_FUZZER_CORPUS_DIR ${CMAKE_CURRENT_BINARY_DIR}/corpus)
set(IRODS_HTTP_FUZZER_MERGED_DIR ${CMAKE_CURRENT_BINARY_DIR}/merged-corpus)

configure_file(
  "${IRODS_HTTP_PROJECT_SOURCE_DIR}/core/include/irods/private/http_api/version.hpp.in"
  "${IRODS_HTTP_PROJECT_SOURCE_DIR}/core/include/irods/private/http_api/version.hpp"
  @ONLY
)

add_library(
    irods_http_api_core_fuzzing
  OBJECT
  "${IRODS_HTTP_PROJECT_SOURCE_DIR}/core/src/common.cpp"
  "${IRODS_HTTP_PROJECT_SOURCE_DIR}/core/src/globals.cpp"
  "${IRODS_HTTP_PROJECT_SOURCE_DIR}/core/src/multipart_form_data.cpp"
  "${IRODS_HTTP_PROJECT_SOURCE_DIR}/core/src/process_stash.cpp"
  "${IRODS_HTTP_PROJECT_SOURCE_DIR}/core/src/session.cpp"
  "${IRODS_HTTP_PROJECT_SOURCE_DIR}/core/src/transport.cpp"
)

target_link_libraries(
    irods_http_api_core_fuzzing
  PRIVATE
  irods_client
  "${IRODS_EXTERNALS_FULLPATH_BOOST}/lib/libboost_filesystem.so"
  "${IRODS_EXTERNALS_FULLPATH_BOOST}/lib/libboost_program_options.so"
  "${IRODS_EXTERNALS_FULLPATH_BOOST}/lib/libboost_url.so"
  CURL::libcurl
)

target_compile_definitions(
    irods_http_api_core_fuzzing
  PRIVATE
  ${IRODS_COMPILE_DEFINITIONS}
  ${IRODS_COMPILE_DEFINITIONS_PRIVATE}
  # The following macro requires that the application never attempt to
  # change log levels concurrently across threads.
  SPDLOG_NO_ATOMIC_LEVELS
  # Defines a macro which is used to construct the URL paths to individual
  # endpoint handlers (e.g. /irods-http-api/<version>/collections).
  IRODS_HTTP_API_BASE_URL="/irods-http-api/${IRODS_HTTP_API_VERSION}"
)

target_include_directories(
    irods_http_api_core_fuzzing
  PRIVATE
  "${IRODS_HTTP_PROJECT_SOURCE_DIR}/core/include"
  "${IRODS_HTTP_PROJECT_BINARY_DIR}/core/include"
  "${IRODS_HTTP_PROJECT_SOURCE_DIR}/endpoints/shared/include"
  "${IRODS_EXTERNALS_FULLPATH_BOOST}/include"
)

target_link_libraries(
  irods_http_api_core_fuzzing
  PUBLIC
  fmt::fmt
  spdlog::spdlog
)

set_target_properties(irods_http_api_core_fuzzing PROPERTIES EXCLUDE_FROM_ALL TRUE)

# Function to register fuzzers
function(add_irods_http_fuzzer NAME)
    add_executable(fuzzer_${NAME} ${ARGN})
target_compile_definitions(
	fuzzer_${NAME}
	PRIVATE
	${IRODS_COMPILE_DEFINITIONS}
	${IRODS_COMPILE_DEFINITIONS_PRIVATE}
	)
target_link_libraries(
	fuzzer_${NAME} 
	PRIVATE 
	/mnt/u/localbuild/aflplusplus/FuzzingEngine.a
    "${IRODS_EXTERNALS_FULLPATH_IRODS}/lib/libirods_client.so"
    "${IRODS_EXTERNALS_FULLPATH_IRODS}/lib/libirods_common.so"
    "${IRODS_EXTERNALS_FULLPATH_IRODS}/lib/libirods_plugin_dependencies.so"
    OpenSSL::SSL
    OpenSSL::Crypto
  	CURL::libcurl
  	nlohmann_json::nlohmann_json
    fmt::fmt
    spdlog::spdlog
  	"${IRODS_EXTERNALS_FULLPATH_BOOST}/lib/libboost_filesystem.so"
  	"${IRODS_EXTERNALS_FULLPATH_BOOST}/lib/libboost_program_options.so"
  	"${IRODS_EXTERNALS_FULLPATH_BOOST}/lib/libboost_url.so"
	)
target_include_directories(
	fuzzer_${NAME}
	PRIVATE
	"${IRODS_HTTP_PROJECT_SOURCE_DIR}/core/include"
	"${IRODS_HTTP_PROJECT_SOURCE_DIR}/endpoints/shared/include"
	"${IRODS_EXTERNALS_FULLPATH_BOOST}/include"
	)

target_sources(
  fuzzer_${NAME}
  PRIVATE
  $<TARGET_OBJECTS:irods_http_api_core_fuzzing>
  $<TARGET_OBJECTS:irods_http_api_shared_operations>
  $<TARGET_OBJECTS:irods_http_api_endpoint_authentication>
  $<TARGET_OBJECTS:irods_http_api_endpoint_collections>
  $<TARGET_OBJECTS:irods_http_api_endpoint_data_objects>
  $<TARGET_OBJECTS:irods_http_api_endpoint_information>
  $<TARGET_OBJECTS:irods_http_api_endpoint_query>
  $<TARGET_OBJECTS:irods_http_api_endpoint_resources>
  $<TARGET_OBJECTS:irods_http_api_endpoint_rules>
  $<TARGET_OBJECTS:irods_http_api_endpoint_tickets>
  $<TARGET_OBJECTS:irods_http_api_endpoint_users_groups>
  $<TARGET_OBJECTS:irods_http_api_endpoint_zones>
)
    # Add libFuzzer and sanitizer flags
    set(FUZZING_FLAGS
    -fsanitize=undefined
    -fsanitize=address
    -fno-sanitize-recover=undefined
    -fno-omit-frame-pointer
)
    target_compile_options(fuzzer_${NAME} PRIVATE ${FUZZER_FLAGS} -g -O1)
    target_link_options(fuzzer_${NAME} PRIVATE ${FUZZER_FLAGS})

    
endfunction()

# Register all fuzzers
file(GLOB FUZZER_SOURCES *.cpp)
foreach(FUZZER_SOURCE ${FUZZER_SOURCES})
    get_filename_component(FUZZER_NAME ${FUZZER_SOURCE} NAME_WE)
    add_irods_http_fuzzer(${FUZZER_NAME} ${FUZZER_SOURCE})
endforeach()