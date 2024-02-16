#include <iostream>

#include "Application.h"
#include "Render.h"

int main(void) {

	if(!Application::CreateAppInstance("GUI Project 2", 800, 800)) {
  	std::cerr << "Unable to start project." << std::endl;
    return -1;
  }

  Application& app = Application::GetAppInstance();
  Render& renderer = Render::GetRenderInstance();

	while (app.IsWindowOpen()) {
  	app.BeginFrame();
  	renderer.ClearColor(JAZZ);

		renderer.GUI_BeginFrame();

		ImGui::ShowDemoWindow();
        
    renderer.GUI_EndFrame();
    app.EndFrame();
	}

  return 0;
}