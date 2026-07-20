#include "httplib.h"
#include <iostream>

using namespace std;

namespace global_var {
  int port = 3333;
}

int main() {
  httplib::Server srv;

  srv.Get("/health", [](const httplib::Request& req, httplib::Response& res) {
    res.set_content(R"({"status": "ok"})", "application/json");
    res.status = 200;
  });

  std::cout << "Server starting up on http://localhost:" << global_var::port << std::endl;
  srv.listen("0.0.0.0", global_var::port);

  return 0;
}