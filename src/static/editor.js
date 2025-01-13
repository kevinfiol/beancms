const Editor = $('.editor');

// enable tabs in editor
Editor.onkeydown = (e) => {
  const editor = e.target;

  if (e.keyCode === 9 || e.which === 9 || e.key === 'Tab') {
    e.preventDefault();
    const originalStart = editor.selectionStart;

    editor.value =
      editor.value.substring(0, editor.selectionStart) +
      '\t' +
      editor.value.substring(editor.selectionEnd);

    editor.selectionEnd = originalStart + 1;
  }
};

function createSlug(text = '') {
  const lines = text.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const slug = lines[i].toString().toLowerCase()
      .replace(/\s+/g, '-') // Replace spaces with -
      .replace(/[^\w\-]+/g, '') // Remove all non-word chars
      .replace(/\-\-+/g, '-') // Replace multiple - with single -
      .replace(/^-+/, '') // Trim - from start of text
      .replace(/-+$/, ''); // Trim - from end of text

    if (slug.length > 0) return slug;
  }

  return '';
}

// allow tabs
// document.getElementById("editable").onkeydown = function(e) {
//     if (e.keyCode == 9 || e.which == 9 || e.key == "Tab") {
//         e.preventDefault();
//         var s = this.selectionStart;
//         this.value = this.value.substring(0, this.selectionStart) + "\t" + this.value.substring(this.selectionEnd);
//         this.selectionEnd = s + 1;
//     }
// }

// var autoExpand = function(field) {
//     // Get the computed styles for the element
//     var computed = window.getComputedStyle(field);
//     // Calculate the height
//     var height = parseInt(computed.getPropertyValue('border-top-width'), 10) +
//         parseInt(computed.getPropertyValue('padding-top'), 10) +
//         field.scrollHeight +
//         parseInt(computed.getPropertyValue('padding-bottom'), 10) +
//         parseInt(computed.getPropertyValue('border-bottom-width'), 10);
//     if (field.style.height != height + 'px') {
//         // Reset field height
//         field.style.height = 'inherit';
//         field.style.height = height + 'px';
//     }
// };

// document.getElementById("editable").addEventListener('input', function(event) {
//     console.log(event);
//     if (event.inputType == "insertText") {
//         return;
//     }
//     autoExpand(event.target);
// }, false);