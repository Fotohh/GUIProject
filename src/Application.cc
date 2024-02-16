#include "Application.h"

#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include <iostream>

#include "Render.h"

struct {
	GLFWwindow* window_;
} Core;

Application Application::instance_;

bool Application::CreateAppInstance(const std::string& title, uint32_t width, uint32_t height) {
	return instance_.CreateApp(title, width, height);
}

Application& Application::GetAppInstance() {
	return instance_;
}

bool Application::CreateApp(const std::string& title, uint32_t width, uint32_t height) {
	title_ = title;
	width_ = width;
	height_ = height;

	if (!glfwInit()) {
  	std::cerr << "Unable to initialize GLFW!" << std::endl;
		return false;
  }

  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
  glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);

  Core.window_ = glfwCreateWindow(width_, height_, title_.c_str(), nullptr, nullptr);

  if (!Core.window_) {
  	std::cerr << "Unable to create window" << std::endl;
    glfwTerminate();
		return false;
  }

  glfwMakeContextCurrent(Core.window_);

  if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
  	std::cerr << "Unable to create OpenGL context" << std::endl;
    glfwTerminate();
		return false;
  }

  glViewport(0, 0, width_, height_);

	Render::InitGUI(Core.window_);

	return true;
}

const bool Application::IsWindowOpen() {
	glfwPollEvents();
	return !glfwWindowShouldClose(Core.window_);
}

void Application::BeginFrame() {
  glClear(GL_COLOR_BUFFER_BIT);
}

void Application::EndFrame() {
	glfwSwapBuffers(Core.window_);
}

Application::~Application() {
	glfwDestroyWindow(Core.window_);
	glfwTerminate();
}
