in this folder,
those SVG files are copyrighted.
(except for icon and template).

all SVG files in icon folder should have this:
```xml
<svg xmlns="http://www.w3.org/2000/svg" width="720" height="720" stroke-width="10" stroke-linecap="round" stroke-linejoin="round">
```

don't use `style` .

SVG must follow this structure:
```xml
<path d="
M...Z
"
class="new_css_class"
>
```

```xml
<animateTransform
AttributeName="transform"
AttributeType="XML"
type="rotate"
values="
0;180;0
"
dur="2s"
repeatCount="indefinite"
>
```

you can get some ready-made CSS classes at
<a href="https://github.com/dujanhung/sicalyme/blob/main/resource/css_svg/sicalyme_color.css">here</a>

CSS must follow this structure:

```css
.new_css_class
{
fill:
#aaa
;
stroke:
#bbb
}
```