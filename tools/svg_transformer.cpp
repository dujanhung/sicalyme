#include <tinyxml2.h>
#include <iostream>
#include <sstream>
#include <vector>
#include <cmath>

using namespace tinyxml2;

struct Matrix {
    double a=1, b=0, c=0, d=1, e=0, f=0;
};

Matrix multiply(const Matrix& m1, const Matrix& m2) {
    Matrix r;
    r.a = m1.a*m2.a + m1.c*m2.b;
    r.b = m1.b*m2.a + m1.d*m2.b;
    r.c = m1.a*m2.c + m1.c*m2.d;
    r.d = m1.b*m2.c + m1.d*m2.d;
    r.e = m1.a*m2.e + m1.c*m2.f + m1.e;
    r.f = m1.b*m2.e + m1.d*m2.f + m1.f;
    return r;
}

Matrix parseSingleTransform(const std::string& t) {
    Matrix m;

    if (t.find("matrix") == 0) {
        sscanf(t.c_str(), "matrix(%lf%*[ ,]%lf%*[ ,]%lf%*[ ,]%lf%*[ ,]%lf%*[ ,]%lf)",
               &m.a,&m.b,&m.c,&m.d,&m.e,&m.f);
    }
    else if (t.find("translate") == 0) {
        double tx=0, ty=0;
        sscanf(t.c_str(), "translate(%lf%*[ ,]%lf)", &tx,&ty);
        m.e = tx;
        m.f = ty;
    }
    else if (t.find("scale") == 0) {
        double sx=1, sy=1;
        sscanf(t.c_str(), "scale(%lf%*[ ,]%lf)", &sx,&sy);
        m.a = sx;
        m.d = sy;
    }
    else if (t.find("rotate") == 0) {
        double angle=0;
        sscanf(t.c_str(), "rotate(%lf)", &angle);
        double rad = angle * M_PI / 180.0;
        m.a = cos(rad);
        m.b = sin(rad);
        m.c = -sin(rad);
        m.d = cos(rad);
    }

    return m;
}

Matrix parseTransformList(const char* str) {
    Matrix result;
    if (!str) return result;

    std::string s(str);
    size_t pos = 0;

    while (pos < s.size()) {
        size_t end = s.find(")", pos);
        if (end == std::string::npos) break;

        std::string token = s.substr(pos, end-pos+1);
        Matrix local = parseSingleTransform(token);
        result = multiply(result, local);

        pos = end + 1;
        while (pos < s.size() && isspace(s[pos])) pos++;
    }

    return result;
}

void applyMatrix(double& x, double& y, const Matrix& m) {
    double nx = m.a*x + m.c*y + m.e;
    double ny = m.b*x + m.d*y + m.f;
    x = nx;
    y = ny;
}

std::string transformPath(const std::string& d, const Matrix& m) {
    std::stringstream in(d);
    std::stringstream out;

    char cmd;
    double x,y;

    while (in >> cmd) {
        out << cmd << " ";

        if (cmd=='M'||cmd=='L'||cmd=='m'||cmd=='l') {
            while (in >> x >> y) {
                if (islower(cmd)) { } // minimal relative support
                applyMatrix(x,y,m);
                out << x << " " << y << " ";
                if (in.peek()==EOF || isalpha(in.peek())) break;
            }
        }
        else if (cmd=='C'||cmd=='c') {
            for(int i=0;i<3;i++){
                in>>x>>y;
                applyMatrix(x,y,m);
                out<<x<<" "<<y<<" ";
            }
        }
        else if (cmd=='Z'||cmd=='z') {
            continue;
        }
    }

    return out.str();
}

void processNode(XMLElement* element, Matrix parentMatrix, bool& modified) {

    Matrix localMatrix = parseTransformList(element->Attribute("transform"));
    Matrix currentMatrix = multiply(parentMatrix, localMatrix);

    if (strcmp(element->Name(),"path")==0) {
        const char* d = element->Attribute("d");
        if (d) {
            std::string newD = transformPath(d, currentMatrix);
            element->SetAttribute("d", newD.c_str());
            element->DeleteAttribute("transform");
            modified = true;
        }
    } else {
        if (element->Attribute("transform"))
            element->DeleteAttribute("transform");
    }

    for (XMLElement* child = element->FirstChildElement();
         child;
         child = child->NextSiblingElement()) {
        processNode(child, currentMatrix, modified);
    }
}

int main(int argc, char** argv) {
    if (argc<2) {
        std::cerr<<"Usage: svg_transformer file.svg\n";
        return 1;
    }

    XMLDocument doc;
    if (doc.LoadFile(argv[1])!=XML_SUCCESS) {
        std::cerr<<"Load failed\n";
        return 1;
    }

    bool modified=false;
    processNode(doc.RootElement(), Matrix(), modified);

    if (modified)
        doc.SaveFile(argv[1]);

    return 0;
}