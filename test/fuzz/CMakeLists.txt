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
  	# irods_client
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
	# "${IRODS_HTTP_PROJECT_BINARY_DIR}/core/include"
	"${IRODS_HTTP_PROJECT_SOURCE_DIR}/endpoints/shared/include"
	"${IRODS_EXTERNALS_FULLPATH_BOOST}/include"
	)
target_sources(
  fuzzer_${NAME}
  PRIVATE
  $<TARGET_OBJECTS:irods_http_api_core>
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
    target_compile_options(fuzzer_${NAME} PRIVATE 
        -g -O2 
        -fsanitize=fuzzer,address,undefined 
        -fno-sanitize-recover=undefined)
    target_link_libraries(fuzzer_${NAME} PRIVATE 
        -fsanitize=fuzzer,address,undefined)

    
endfunction()

# Register all fuzzers
file(GLOB FUZZER_SOURCES *.cpp)
foreach(FUZZER_SOURCE ${FUZZER_SOURCES})
    get_filename_component(FUZZER_NAME ${FUZZER_SOURCE} NAME_WE)
    add_irods_http_fuzzer(${FUZZER_NAME} ${FUZZER_SOURCE})
endforeach()