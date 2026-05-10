const fs = require('fs');
const content = fs.readFileSync('C:\\Users\\Cleison\\.gemini\\antigravity\\brain\\b82a88b1-3934-45b1-a49e-53edad898418\\.system_generated\\steps\\1512\\content.md', 'utf8');

const countries = {};

// Captura toda a tag path
const fullPathRegex = /<path\s+([\s\S]*?)>/g;
const dRegex = /d="([^"]+)"/;
const idRegex = /id="([^"]+)"/;
const nameRegex = /name="([^"]+)"/;
const classRegex = /class="([^"]+)"/;

let match;
while ((match = fullPathRegex.exec(content)) !== null) {
  const tagContent = match[1];
  const dMatch = tagContent.match(dRegex);
  if (!dMatch) continue;
  
  const d = dMatch[1];
  const idMatch = tagContent.match(idRegex);
  const nameMatch = tagContent.match(nameRegex);
  const classMatch = tagContent.match(classRegex);
  
  const name = nameMatch ? nameMatch[1] : (classMatch ? classMatch[1] : null);
  const id = idMatch ? idMatch[1] : name;
  
  if (name) {
    if (!countries[name]) {
      countries[name] = { id: id || name, name, paths: [] };
    }
    countries[name].paths.push(d);
  }
}

const finalData = Object.values(countries).map(c => {
  const fullD = c.paths.join(' ');
  const numbers = fullD.match(/-?\d+(\.\d+)?/g);
  let x = 0, y = 0;
  if (numbers) {
    let sumX = 0, sumY = 0, count = 0;
    for (let i = 0; i < numbers.length - 1; i += 2) {
      sumX += parseFloat(numbers[i]);
      sumY += parseFloat(numbers[i+1]);
      count++;
    }
    x = sumX / count;
    y = sumY / count;
  }
  return { id: c.id, name: c.name, d: fullD, center: { x, y } };
});

fs.writeFileSync('c:\\Users\\Cleison\\Documents\\G-Route App\\admin_web\\src\\components\\worldData.json', JSON.stringify(finalData, null, 2));
console.log(`Extracted ${finalData.length} countries.`);
