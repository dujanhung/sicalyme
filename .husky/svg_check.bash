chmod +x .husky/svg_check.bash

npx svgo --multipass --config="{plugins:[{name:'convertPathData',params:{applyTransforms:true}}]}" '*.svg'