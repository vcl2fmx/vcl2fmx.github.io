(function () {
  'use strict';
  var helpRoot = new URL('../', document.currentScript.src);
  var aliases = {fil: 'tl', nb: 'no', 'zh-cn': 'zh-CN', 'zh-tw': 'zh-TW'};
  var supported = 'ar bg bn cs de el en es fa fi tl fr he hi hr hu id it ja ko pl ps pt ro ru sk sr sv th tr uk ur vi zh-CN zh-TW'.split(' ');
  var savedLanguage = (document.cookie || '').match(/(?:^|;\s*)googtrans=\/[^/;]+\/([^;]+)/);
  var requested = new URLSearchParams(location.search).get('lang') ||
    (savedLanguage && decodeURIComponent(savedLanguage[1])) || 'en';
  var lower = requested.toLowerCase();
  var language = aliases[lower] || aliases[lower.split('-')[0]] || lower.split('-')[0];
  if (supported.indexOf(language) < 0) language = 'en';
  var shell = document.body.classList.contains('help-shell');

  function notice(text) {
    var message = document.createElement('p');
    message.className = 'help-translation-notice';
    message.setAttribute('role', 'status');
    message.textContent = text;
    (shell ? document.querySelector('aside') : document.body).prepend(message);
  }

  // Directly opened files stay readable in English. The converter opens the
  // same files through its private HTTP listener so widget cookies can work.
  if (location.protocol === 'file:') {
    if (language !== 'en') notice('Open Help from Atlas to use automatic translation.');
    return;
  }
  if (location.protocol !== 'https:' && location.protocol !== 'http:') return;

  // Seed the provider before loading it; an explicit converter choice wins over
  // the browser language and any selection left by an earlier Help visit.
  document.cookie = 'googtrans=/en/' + language + ';path=/;SameSite=Lax';

  document.documentElement.dir = ['ar', 'fa', 'he', 'ps', 'ur'].indexOf(language) >= 0 ? 'rtl' : 'ltr';
  document.querySelectorAll('pre,code,kbd,samp').forEach(function (element) {
    element.classList.add('notranslate');
    element.setAttribute('translate', 'no');
    element.dir = 'ltr';
  });
  var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  var brandNodes = [];
  var protectedNames = /\b(?:VCL2FMXConverter|VCL2FMX|Atlas|VCL|FMX|RTTI|JSON|IDE|Delphi|Pascal|WinAPI|T[A-Z][A-Za-z0-9_]*|On[A-Z][A-Za-z0-9_]*)(?:\.[A-Za-z][A-Za-z0-9_]*)*\b/g;
  while (walker.nextNode()) {
    protectedNames.lastIndex = 0;
    if (!walker.currentNode.parentElement.closest('script,style,pre,code,kbd,samp,.notranslate') &&
        protectedNames.test(walker.currentNode.nodeValue)) brandNodes.push(walker.currentNode);
  }
  brandNodes.forEach(function (text) {
    var fragment = document.createDocumentFragment();
    var previous = 0;
    protectedNames.lastIndex = 0;
    var match;
    while ((match = protectedNames.exec(text.nodeValue))) {
      fragment.appendChild(document.createTextNode(text.nodeValue.slice(previous, match.index)));
      var part = document.createElement('span');
      part.className = 'notranslate';
      part.setAttribute('translate', 'no');
      part.textContent = match[0];
      fragment.appendChild(part);
      previous = match.index + match[0].length;
    }
    fragment.appendChild(document.createTextNode(text.nodeValue.slice(previous)));
    text.replaceWith(fragment);
  });

  function localLink(value) {
    var url = new URL(value, location.href);
    if (url.origin === location.origin && url.pathname.indexOf(helpRoot.pathname) === 0 && /\.html$/.test(url.pathname)) {
      url.searchParams.set('lang', language);
      return url.href;
    }
    return value;
  }
  document.querySelectorAll('a[href]').forEach(function (link) { link.href = localLink(link.href); });
  // Capture also covers links inserted later by the existing search function.
  document.addEventListener('click', function (event) {
    var link = event.target.closest('a[href]');
    if (link) link.href = localLink(link.href);
  }, true);
  var frame = document.getElementById('topicFrame');
  if (frame) frame.src = localLink(frame.getAttribute('src'));

  var wrapper = document.createElement('div');
  wrapper.className = 'gtranslate_wrapper notranslate';
  wrapper.setAttribute('translate', 'no');
  if (window.parent !== window) wrapper.style.display = 'none';
  document.body.appendChild(wrapper);
  window.gtranslateSettings = {
    default_language: 'en', languages: supported, native_language_names: true,
    detect_browser_language: false, wrapper_selector: '.gtranslate_wrapper',
    switcher_horizontal_position: 'right'
  };
  // Topic frames receive their own provider: translating the shell alone does
  // not translate a separately loaded HTML document.
  var provider = document.createElement('script');
  provider.src = 'https://cdn.gtranslate.net/widgets/latest/float.js';
  var translationRequested = false;
  var attempts = 0;
  var timer;
  function translationUnavailable() {
    clearInterval(timer);
    notice('Translation is unavailable. Check your Internet connection and reload Help. The English manual remains available.');
  }
  provider.onerror = translationUnavailable;
  provider.onload = function () {
    wrapper.dispatchEvent(new Event('focusin', {bubbles: true}));
    // English still needs the selector, but no translation completion timer.
    if (language === 'en') return;
    timer = setInterval(function () {
      attempts += 1;
      if (!translationRequested && typeof window.doGTranslate === 'function') {
        window.doGTranslate('en|' + language);
        translationRequested = true;
      }
      var combo = document.querySelector('.goog-te-combo');
      if (!translationRequested && combo && Array.from(combo.options).some(function (option) { return option.value === language; })) {
        combo.value = language;
        combo.dispatchEvent(new Event('change', {bubbles: true}));
        translationRequested = true;
      }
      if (document.documentElement.classList.contains('translated-ltr') ||
          document.documentElement.classList.contains('translated-rtl')) {
        clearInterval(timer);
      } else if (attempts >= 100) {
        translationUnavailable();
      }
    }, 200);
  };
  document.head.appendChild(provider);
  var labels = document.createElement('script');
  labels.src = new URL('translation-selector.js', document.currentScript.src).href;
  document.head.appendChild(labels);
  // Manual selection reloads the shell and all topics with one consistent code.
  document.addEventListener('click', function (event) {
    var choice = event.target.closest('.gtranslate_wrapper a[data-gt-lang]');
    if (!choice) return;
    var selected = choice.getAttribute('data-gt-lang');
    if (supported.indexOf(selected) < 0) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    var destination = new URL(location.href);
    destination.searchParams.set('lang', selected);
    location.replace(destination.href);
  }, true);
}());
