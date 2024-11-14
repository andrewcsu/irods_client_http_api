//
// Copyright (c) 2024
//
// Distributed under the Boost Software License, Version 1.0. (See accompanying
// file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

#include <boost/beast/http.hpp>
#include <boost/beast/_experimental/test/stream.hpp>
#include <boost/asio.hpp>
#include <nlohmann/json.hpp>
#include "irods/private/http_api/handlers.hpp"
#include "irods/private/http_api/session.hpp"
#include "irods/private/http_api/log.hpp"
#include "irods/private/http_api/globals.hpp"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size)
{
    using namespace boost::beast;
    using namespace irods::http;

    error_code ec;
    flat_buffer buffer;
    net::io_context ioc;
    test::stream stream{ioc, {reinterpret_cast<const char*>(data), size}};
    stream.close_remote();

    http::request_parser<http::dynamic_body> parser;
    http::read(stream, buffer, parser, ec);

    if (ec) {
        return 0;
    }

    auto req = parser.release();

    // Create a dummy socket
    boost::asio::ip::tcp::socket socket{ioc};

    // Provide necessary arguments for the session constructor
    const request_handler_map_type request_handlers; // Initialize as appropriate
    int max_body_size = 1048576; // Example value
    int timeout_in_secs = 30;    // Example value

    session_pointer_type sess_ptr = std::make_shared<session>(
        std::move(socket),
        request_handlers,
        max_body_size,
        timeout_in_secs
    );

    // Convert the request to the expected type
    request_type converted_req{std::move(req.base())};

    // Extract body as string
    std::string body_str = boost::beast::buffers_to_string(req.body().data());
    converted_req.body() = std::move(body_str);
    converted_req.prepare_payload();

    // Fuzz the `collections` endpoint
    handler::collections(sess_ptr, converted_req);

    return 0;
}