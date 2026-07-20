#include "call_timezone.h"

#include <chrono>
#include <ctime>
#include <iomanip>
#include <sstream>

namespace {

std::string current_utc_time_iso8601() {
  using namespace std::chrono;

  auto now = system_clock::now();
  std::time_t now_c = system_clock::to_time_t(now);

  std::tm utc_tm{};
  gmtime_r(&now_c, &utc_tm);

  std::ostringstream oss;
  oss << std::put_time(&utc_tm, "%Y-%m-%dT%H:%M:%SZ");
  return oss.str();
}

}  // namespace

void register_timezone_routes(httplib::Server& srv) {
  srv.Get("/current_time", [](const httplib::Request&, httplib::Response& res) {
    std::ostringstream body;
    body << R"({"timezone": "UTC", "current_time": ")" << current_utc_time_iso8601()
         << R"("})";
    res.set_content(body.str(), "application/json");
    res.status = 200;
  });
}
