#include "irods/private/http_api/session.hpp"
#include "irods/private/http_api/handlers.hpp"
#include "irods/private/http_api/globals.hpp"
#include <boost/beast/http.hpp>
#include <boost/asio.hpp>
#include <iostream>
#include <thread>

using tcp = boost::asio::ip::tcp;
namespace http = boost::beast::http;

void handle_request(tcp::socket socket) {
    try {
        boost::beast::flat_buffer buffer;
        http::request<http::string_body> req;
        http::read(socket, buffer, req);

        // Create a request handler map
        irods::http::request_handler_map_type request_handler_map{
            {"/irods-http-api/0.4.0/collections", irods::http::handler::collections}
            // Add other handlers as needed
        };

        // Create a session with the required arguments
        auto sess_ptr = std::make_shared<irods::http::session>(
            std::move(socket),
            request_handler_map,
            8192, // max_body_size
            30    // timeout_in_seconds
        );

        // Handle the request
        if (req.target().starts_with("/irods-http-api/0.4.0/collections")) {
            irods::http::handler::collections(sess_ptr, req);
        }
        // Add other handlers as needed

        http::response<http::string_body> res{http::status::ok, req.version()};
        res.set(http::field::server, "TestServer");
        res.set(http::field::content_type, "text/plain");
        res.body() = "Hello, world!";
        res.prepare_payload();
        http::write(socket, res);
    }
    catch (std::exception const& e) {
        std::cerr << "Error: " << e.what() << std::endl;
    }
}

void start_server() {
    try {
        boost::asio::io_context ioc{1};
        tcp::acceptor acceptor{ioc, tcp::endpoint{tcp::v4(), 9000}};
        for (;;) {
            tcp::socket socket{ioc};
            acceptor.accept(socket);
            std::thread(handle_request, std::move(socket)).detach();
        }
    }
    catch (std::exception const& e) {
        std::cerr << "Error: " << e.what() << std::endl;
    }
}

int main() {
    start_server();
    return 0;
}