#include <iostream>

#include "Application.h"

#include <glad/glad.h>
#include <GLFW/glfw3.h>

int main(void) {

    if(!Application::CreateAppInstance("GUI Project 2", 800, 600)) {
        std::cerr << "Unable to start project." << std::endl;
        return -1;
    }

    Application& app = Application::GetAppInstance();

    while (app.IsWindowOpen()) {
        app.BeginFrame();
        glClearColor(0.6, 0.5, 0.5, 1.0);
        app.EndFrame();
    }

    return 0;
}