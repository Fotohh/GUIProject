#ifndef RENDER_H_
#define RENDER_H_

#include <stdint.h>
#include <imgui/imgui.h>

#define COOL_WHITE Color { 250, 250, 250, 255 }
#define SUMMER Color { 245, 90, 90, 255 }
#define JAZZ Color { 90, 90, 245, 255 }
#define FOREST Color { 90, 245, 90, 255 }

struct Color {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
};

class Render {
public:
    static Render& GetRenderInstance();
    void ClearColor(Color color);

    void GUI_BeginFrame();
    void GUI_EndFrame();
private:
    friend class Application;
    static void InitGUI(struct GLFWwindow* window);
private:
    Render() = default;
    static Render instance_;
};


#endif