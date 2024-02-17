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

  int sliderValue[3] = {0};
  float col[3] = {0};

	while (app.IsWindowOpen()) {
  	app.BeginFrame();
  	renderer.ClearColor(Color{(uint8_t)sliderValue[0],(uint8_t)sliderValue[1],(uint8_t)sliderValue[2], 255});

  renderer.GUI_BeginFrame();

  if(ImGui::Begin("Slider")) {
  
    ImGui::ColorPicker3("Background Color", col);

    sliderValue[0] = (int)(col[0] * 255);
    sliderValue[1] = (int)(col[1] * 255);
    sliderValue[2] = (int)(col[2] * 255);


    ImGui::End();

  }

    renderer.GUI_EndFrame();

    app.EndFrame();

	}

  return 0;
}
