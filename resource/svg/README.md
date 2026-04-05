in this folder,
those SVG files are copyrighted.
(except for icon and template).

all SVG files in icon folder should have this:
```xml
<svg xmlns="http://www.w3.org/2000/svg" width="720" height="720" stroke-width="10" stroke-linecap="round" stroke-linejoin="round">
```

in `<svg>` , don't use `viewBox` , unless it's different from `width` and `height` .

don't use `style` , because it's hard to maintain. use `class` and `<style>` instead.

don't use `<script>` , `<defs>` , `<use>` , GitHub would reject it for security reasons, such as: memory overwhelm, unwanted hijack, etc.

some SVG tags must follow this structure:
```xml
<path d="
M...Z
"
class="new_css_class"
>
```

animate `transform` without `<style>`

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

animate CSS without `<style>`

```xml
<animate
AttributeName="fill"
values="
#aaa;#000;#aaa
"
dur="2s"
repeatCount="indefinite"
>
```


<h2>
CSS
</h2>

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

animate CSS with `<style>`

```css
.change_color
{
animate:"fill 2s indefinite"
@keyframes
{
values:
#000,#fff,#000
}
}
```