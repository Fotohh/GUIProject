g++ -c main.cc -I submodules/imgui
g++ -c submodules/imgui/imgui_demo.cpp -I submodules/imgui 
g++ -c submodules/imgui/imgui_draw.cpp -I submodules/imgui
g++ -c submodules/imgui/imgui_tables.cpp -I submodules/imgui
g++ -c submodules/imgui/imgui_widgets.cpp -I submodules/imgui
g++ -c submodules/imgui/imgui.cpp -I submodules/imgui
g++ -c glad.c -I glad
g++ -o app.exe imgui_demo.o imgui_draw.o imgui_tables.o imgui_widgets.o imgui.o main.o 