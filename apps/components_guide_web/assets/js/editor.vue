<template>
  <editor-content :editor="editor" />
</template>

<script>
// Import the editor
import { Editor, EditorContent } from 'tiptap'

export default {
  components: {
    EditorContent,
  },
  props: ["content"],
  data() {
    return {
      editor: null,
    }
  },
  mounted() {
    this.editor = new Editor({
      content: this.content,
    })
  },
  beforeDestroy() {
    this.editor.destroy()
  },
}
</script>
