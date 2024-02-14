#ifndef APPLICATION_H_
#define APPLICATION_H_

#include <string>
#include <stdint.h>

class Application {
public:
  ~Application();

  static bool CreateAppInstance(const std::string& title, uint32_t width, uint32_t height);
  static Application& GetAppInstance();

  bool CreateApp(const std::string& title, uint32_t width, uint32_t height);
  const bool IsWindowOpen();

  void BeginFrame();
  void EndFrame();
private:
	Application() = default;
	static Application instance_;
private:
  std::string title_;
  uint32_t width_;
	uint32_t height_;
};

#endif