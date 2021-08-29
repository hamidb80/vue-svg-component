# About
the fonts on the web were not complete and we had to put some extra `SVG`s into the project

if you import a `SVG` as an image, you cant change it's color and you have to import it's xml tree in your `HTML`

so I wrote a script in nim that compiles `SVG` into vue templates

# Idea

for example `assets/database.svg`:
```xml
<svg
   class="svg-icon"
   style="width: 1em; height: 1em;vertical-align: middle;fill: currentColor;overflow: hidden;"
   viewBox="0 0 1024 1024"
   version="1.1">
  <path
     d="..."
     id="path883"
     style="fill:#bd9800;fill-opacity:1" />
  <path
     d="..."
     id="path885"
     style="fill:#bd9800;fill-opacity:1" />
  <path
     d="..."
     id="path887"
     style="fill:#bd9800;fill-opacity:1" />
  ...
</svg>
```

**converts to**

```xml
<template>
  <svg version="1.1" viewBox="0 0 1024 1024">
    <path d="..." />
    <path d="..." />
    <path d="..." />
    ...
  </svg>
</template>

<script>
export default {
  name: "i-database",
}
</script>

<style scoped="scoped">
svg{
  vertical-align: middle;
  overflow: hidden
}
</style>
```

# How To Use
use `app -h` or `app --help` to see the usage