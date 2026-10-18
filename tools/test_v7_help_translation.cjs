const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert/strict');
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'docs/Help/assets/help-translation.js'), 'utf8');
async function run(locale, protocol = 'http:', savedCookie = '') {
  const href = `${protocol}//${protocol === 'file:' ? '/C:/Atlas/docs/Help/' : '127.0.0.1:54321/'}index.html${locale === null ? '' : '?lang=' + locale}`;
  const location = new URL(href);
  location.replace = value => { location.redirect = value; };
  const elements = [], events = {}, cookies = [], timers = [];
  const create = tag => ({tag, style: {}, classList: {add() {}}, setAttribute() {}, dispatchEvent() {}, appendChild(value) { elements.push(value); }, prepend(value) { elements.push(value); }});
  const link = {href: 'http://127.0.0.1:54321/topics/purpose-and-audience.html#goal'};
  const frame = {getAttribute: () => 'topics/purpose-and-audience.html'};
  const document = {
    body: {...create('body'), classList: {contains: () => true}}, head: create('head'),
    documentElement: {classList: {contains: () => false}}, currentScript: {src: 'http://127.0.0.1:54321/assets/help-translation.js'},
    createElement: create, createTreeWalker: () => ({nextNode: () => false}),
    querySelector: () => create('aside'),
    querySelectorAll: selector => selector === 'a[href]' ? [link] : [],
    getElementById: () => frame,
    addEventListener: (name, handler) => { (events[name] ||= []).push(handler); }
  };
  Object.defineProperty(document, 'cookie', {get: () => savedCookie, set: value => cookies.push(value)});
  const window = {}; window.parent = window;
  const context = {document, location, window, NodeFilter: {SHOW_TEXT: 4}, URL, URLSearchParams,
    Event: class {constructor(type, options) {this.type = type; Object.assign(this,options);}},
    setInterval: callback => {timers.push(callback); return timers.length;}, clearInterval() {}};
  vm.runInNewContext(source, context);
  await new Promise(resolve => setTimeout(resolve, 10));
  return {context, elements, cookies, link, frame, events, timers};
}
(async () => {
  const locales = fs.readdirSync(path.join(root, 'Localization/Languages')).filter(n => n.endsWith('.json')).map(n => n.slice(0, -5));
  const exceptions = {'fil-PH': 'tl', 'nb-NO': 'no', 'zh-CN': 'zh-CN', 'zh-TW': 'zh-TW'};
  for (const locale of locales) {
    const expected = exceptions[locale] || locale.split('-')[0];
    const test = await run(locale);
    assert(test.cookies.every(value => value.includes('/en/' + expected + ';')));
    assert.equal(new URL(test.frame.src).searchParams.get('lang'), expected);
    assert.equal(new URL(test.link.href).hash, '#goal');
    assert.equal(new URL(test.link.href).searchParams.get('lang'), expected);
    assert(test.elements.some(e => e.className === 'gtranslate_wrapper notranslate'), 'selector exists for ' + locale);
    assert(test.elements.some(e => e.src === 'https://cdn.gtranslate.net/widgets/latest/float.js'), 'provider loads for ' + locale);
    if (expected !== 'en') {
      assert.equal(test.context.window.gtranslateSettings.detect_browser_language, false);
      let selected;
      test.context.window.doGTranslate = value => {selected = value;};
      test.elements.find(e => e.src === 'https://cdn.gtranslate.net/widgets/latest/float.js').onload();
      test.timers[0]();
      assert.equal(selected, 'en|' + expected);
      const choice = {getAttribute: () => expected};
      const selectionEvent = {target: {closest: selector => selector.includes('gtranslate') ? choice : null}, preventDefault() {}, stopImmediatePropagation() {}};
      test.events.click.forEach(handler => handler(selectionEvent));
      assert.equal(new URL(test.context.location.redirect).searchParams.get('lang'), expected);
    }
    assert.equal(test.context.document.documentElement.dir, ['ar','fa','he','ps','ur'].includes(expected) ? 'rtl' : 'ltr');
  }
  const unavailable = await run('de-DE', 'file:');
  assert.equal(unavailable.context.location.redirect, undefined);
  assert(unavailable.elements.some(e => e.textContent?.includes('Open Help from Atlas')));
  assert.equal(unavailable.cookies.length, 0);
  const english = await run('en-US', 'file:');
  assert.equal(english.context.location.redirect, undefined);
  const invalid = await run('invalid');
  assert(invalid.cookies[0].includes('/en/en;'));
  const websiteLanguage = await run(null, 'https:', 'googtrans=/en/fr');
  assert(websiteLanguage.cookies[0].includes('/en/fr;'), 'Help inherits the website language without a query');
  const explicitEnglish = await run('en', 'https:', 'googtrans=/en/fr');
  assert(explicitEnglish.cookies[0].includes('/en/en;'), 'explicit app or website language overrides the saved cookie');
  explicitEnglish.elements.find(e => e.src === 'https://cdn.gtranslate.net/widgets/latest/float.js').onload();
  assert.equal(explicitEnglish.timers.length, 0, 'English does not wait for translated markup');
  explicitEnglish.events.click.forEach(handler => handler({
    target: {closest: selector => selector.includes('gtranslate') ? {getAttribute: () => 'fr'} : null},
    preventDefault() {}, stopImmediatePropagation() {}
  }));
  assert.equal(new URL(explicitEnglish.context.location.redirect).searchParams.get('lang'), 'fr', 'English selector can switch languages');
  for (const folder of ['docs/Help', 'docs/Help/topics']) {
    for (const file of fs.readdirSync(path.join(root, folder)).filter(n => n.endsWith('.html'))) {
      const html = fs.readFileSync(path.join(root, folder, file), 'utf8');
      assert.equal((html.match(/<script\b[^>]*\bsrc=["'][^"']*assets\/help-translation\.js["'][^>]*>/gi) || []).length, 1, file);
    }
  }
  const failed = await run('de-DE');
  const helpIndex = fs.readFileSync(path.join(root, 'docs/Help/keyword-index.html'), 'utf8');
  assert((helpIndex.match(/href="topics\//g) || []).length >= 27, 'index links to the actual converter topics');
  const glossary = fs.readFileSync(path.join(root, 'docs/Help/glossary.html'), 'utf8');
  assert(glossary.includes('<dt>VCL</dt>') && glossary.includes('<dt>Mapping pack</dt>'));
  assert(!glossary.includes('<dt>Snippet</dt>'), 'template glossary is absent');
  const printView = fs.readFileSync(path.join(root, 'docs/Help/manual-print.html'), 'utf8');
  assert(printView.includes('Keep Atlas running while navigating Help.'));
  assert(!printView.includes('Help is English.'));
  assert(printView.includes('Source text encoding'));
  failed.elements.find(e => e.onerror).onerror();
  assert(failed.elements.some(e => e.textContent?.includes('Internet connection')));
  assert(!source.includes('vcl2fmx.github.io') && !source.includes('translation.googleapis.com/language'));
  console.log(`PASS: ${locales.length} locale mappings, explicit widget invocation, links/anchors, iframe handoff, RTL, selector changes, direct-file fallback and all HTML script references. No live-site dependency or paid API.`);
})().catch(error => { console.error(error); process.exitCode = 1; });
