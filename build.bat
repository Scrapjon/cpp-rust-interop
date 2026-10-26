cmake -S . -B build -DRUST_LINK_MODE="$MODE" -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
echo "--- running ---"
"./build/Release/app.exe"
