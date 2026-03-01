#include <cstdlib>
#include <iostream>
#include <string>

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: svg_flatten file.svg\n";
        return 1;
    }

    std::string file = argv[1];
    std::string cmd =
        "inkscape \"" + file + "\" "
        "--export-plain-svg=\"" + file + "\" "
        "--actions=\"select-all;object-to-path;vacuum-defs\"";

    int result = std::system(cmd.c_str());

    if (result != 0) {
        std::cerr << "Inkscape flatten failed\n";
        return 1;
    }

    return 0;
}