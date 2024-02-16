#include "Render.h"

#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include <imgui/backends/imgui_impl_glfw.h>
#include <imgui/backends/imgui_impl_opengl3.h>

Render Render::instance_;

void Render::ClearColor(Color color) {
	float r = (float)color.r / 255.0;
  float g = (float)color.g / 255.0;
  float b = (float)color.b / 255.0;
  float a = (float)color.a / 255.0;

  glClearColor(r, g, b, a);
}

void Render::InitGUI(GLFWwindow* window) {
  ImGui::CreateContext();
  ImGuiIO& io = ImGui::GetIO(); (void)io;
  io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

  ImGui::StyleColorsDark();

  ImGui_ImplGlfw_InitForOpenGL(window, true);
	ImGui_ImplOpenGL3_Init("#version 330 core");
}

void Render::GUI_BeginFrame() {
	ImGui_ImplOpenGL3_NewFrame();
	ImGui_ImplGlfw_NewFrame();
	ImGui::NewFrame();
}

void Render::GUI_EndFrame() {
	ImGui::Render();
	ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
}

Render& Render::GetRenderInstance() {
	return instance_;
}
