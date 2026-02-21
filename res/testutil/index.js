const $ = s => document.querySelector(s);
const $$ = s => [...document.querySelectorAll(s)];

function order(a, b) {
  return (a > b) ? 1 : (a < b) ? -1 : 0;
}

window.addEventListener('DOMContentLoaded', async e => {
  const list = $('#list');

  // Iterate manifest
  const manifest = await (await fetch('manifest.txt')).text();
  for (const path of manifest.split(/\n/).filter(s => s)) {
    const option = document.createElement('option');
    option.className = 'test';
    option.innerText = path;
    list.append(option);

    // Load and iterate ZIP
    const blob = await (await fetch(path)).arrayBuffer();
    const {entries} = await unzipit.unzip(blob);

    // Stash properties on list item
    option.output = await entries['output.txt'].text();
    option.entries = entries;

    Object.keys(entries)
      .filter(k => k.endsWith('.png'))
      .sort((a, b) => order(a.name,b.name))
      .forEach(key => {
        const entry = entries[key];

        const subopt = document.createElement('option');
        subopt.className = 'snap';
        subopt.innerText = entry.name;
        subopt.parent = option;
        subopt.instructions = entry.name
          .replace(/^\d\d\d\d - /, '')
          .replace(/\.png$/, '');
        list.append(subopt);

        subopt.entry = entry;
      });
  }

  list.addEventListener('change', async e => {
    if (list.selectedOptions.length === 0)
      return;
    const option = list.selectedOptions[0];
    review(option);
  });

  list.focus();

});

function blobToDataURL(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(blob);
    reader.onload = e => resolve(reader.result);
    reader.onerror = e => reject(reader.error);
  });
}

async function review(option) {
  if (option.output) {
    $('#snap').src = '';
    $('#output').innerHTML = ansiToHTML(option.output);
    $('#instructions').innerText = '';
  } else if (option.entry) {
    $('#snap').src = await blobToDataURL(await option.entry.blob('image/png'));
    $('#output').innerHTML = ansiToHTML(option.parent.output);
    $('#instructions').innerText = option.instructions;
  }
}

function ansiToHTML(text) {
  // HTML escaping
  text = text.replace(/[&<>"']/g, c => {
    switch (c) {
    case '&': return '&amp;';
    case '<': return '&lt;';
    case '>': return '&gt;';
    default: return c;
    }
  });

  // ANSI sequences
  // NOTE: Assumes it's always a pair


  const styles = {
    30: 'color: black',
    31: 'color: red',
    32: 'color: green',
    33: 'color: yellow',
    34: 'color: blue',
    35: 'color: magenta',
    36: 'color: cyan',
    37: 'color: white',

    40: 'background-color: black',
    41: 'background-color: red',
    42: 'background-color: green',
    43: 'background-color: yellow',
    44: 'background-color: blue',
    45: 'background-color: magenta',
    46: 'background-color: cyan',
    47: 'background-color: white',
  };

  text = text
    .replace(/\x1B\(B/g, '')
    .replace(/\x1B\[(\d+)m/g, function(_, n) {
      return '<span style="' + styles[n] + '">';
    })
    .replace(/\x1B\[m/g, '</span>');


  return text;

}
