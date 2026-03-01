// Pseudo structure
int main(int argc, char** argv) {
    std::string filename = argv[1];

    // 1. Load SVG file
    // 2. Parse XML (tinyxml2 recommended)
    // 3. For each <path> with transform:
    //       - Parse transform matrix
    //       - Apply to path commands
    //       - Update 'd'
    //       - Remove transform attribute
    // 4. Save file if modified

    return 0;
}