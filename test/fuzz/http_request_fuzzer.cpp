#include "irods/client/http_api/session.hpp"
#include <cstdint>
#include <cstddef>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
    try {
        irods::http::session session;
        session.handle_request(std::string(reinterpret_cast<const char*>(data), size));
    }
    catch (...) {
        // Catch and ignore any exceptions
    }
    return 0;
}
