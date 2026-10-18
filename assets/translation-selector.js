(function () {
  'use strict';

  var languageCodeAliases = {
    iw: 'he',
    jw: 'jv',
    tl: 'fil'
  };

  var englishNameOverrides = {
    'zh-CN': 'Chinese, Simplified',
    'zh-TW': 'Chinese, Traditional'
  };

  var englishLanguageNames = typeof Intl.DisplayNames === 'function'
    ? new Intl.DisplayNames(['en'], { type: 'language' })
    : null;

  var selectedHelpLanguage = '';
  var websiteRoot = new URL('../', document.currentScript.src);

  function updateHelpLinks() {
    var selected = document.querySelector('.gtranslate_wrapper a[data-gt-lang][aria-current="true"], .gtranslate_wrapper .gt_options a.gt-current[data-gt-lang], .gtranslate_wrapper .gt-current-lang[data-gt-lang]');
    var cookie = document.cookie.match(/(?:^|;\s*)googtrans=\/[^/;]+\/([^;]+)/);
    var language = selectedHelpLanguage || (selected && selected.dataset.gtLang) ||
      (cookie && decodeURIComponent(cookie[1])) || 'en';
    document.querySelectorAll('a[href]').forEach(function (link) {
      var target = new URL(link.href, location.href);
      if (target.origin === websiteRoot.origin &&
          target.pathname.indexOf(websiteRoot.pathname + 'docs/Help/') === 0 &&
          /\.html$/i.test(target.pathname)) {
        target.searchParams.set('lang', language);
        link.href = target.href;
      }
    });
  }

  document.addEventListener('click', function (event) {
    var choice = event.target.closest('.gtranslate_wrapper a[data-gt-lang]');
    if (choice) selectedHelpLanguage = choice.dataset.gtLang;
    updateHelpLinks();
  }, true);

  function getEnglishLanguageName(languageCode) {
    if (englishNameOverrides[languageCode]) {
      return englishNameOverrides[languageCode];
    }

    if (!englishLanguageNames) {
      return languageCode;
    }

    try {
      return englishLanguageNames.of(languageCodeAliases[languageCode] || languageCode) || languageCode;
    } catch (error) {
      return languageCode;
    }
  }

  function addBilingualLanguageLabels() {
    updateHelpLinks();
    document.querySelectorAll('.gtranslate_wrapper a[data-gt-lang]').forEach(function (languageLink) {
      if (languageLink.dataset.bilingualLabel === 'true') {
        return;
      }

      var languageCode = languageLink.dataset.gtLang;
      var nativeName = languageLink.textContent.trim();
      var englishName = getEnglishLanguageName(languageCode);
      var label = englishName.toLocaleLowerCase('en') === nativeName.toLocaleLowerCase('en')
        ? englishName
        : englishName + ' (' + nativeName + ')';
      var flagImage = languageLink.querySelector('img');

      languageLink.dataset.bilingualLabel = 'true';
      languageLink.setAttribute('aria-label', label);
      languageLink.replaceChildren(
        flagImage ? flagImage.cloneNode(true) : document.createTextNode(''),
        document.createTextNode(label)
      );
    });

    document.querySelectorAll('.gtranslate_wrapper .gt_options').forEach(function (languageList) {
      var currentOrder = Array.from(languageList.children).filter(function (item) {
        return item.matches('a[data-gt-lang]');
      });
      var alphabeticalOrder = currentOrder.slice().sort(function (firstLanguage, secondLanguage) {
        return firstLanguage.textContent.trim().localeCompare(secondLanguage.textContent.trim(), 'en');
      });
      var orderChanged = alphabeticalOrder.some(function (languageLink, index) {
        return languageLink !== currentOrder[index];
      });

      if (orderChanged) {
        alphabeticalOrder.forEach(function (languageLink) {
          languageList.appendChild(languageLink);
        });
      }
    });
  }

  window.addEventListener('load', function () {
    updateHelpLinks();
    var wrapper = document.querySelector('.gtranslate_wrapper');

    if (!wrapper) {
      return;
    }

    new MutationObserver(addBilingualLanguageLabels).observe(wrapper, {
      childList: true,
      subtree: true
    });

    addBilingualLanguageLabels();
  });
}());
