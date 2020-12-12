/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */

/**
 * Returns a sanitized url, which could be a search engine url if
 * a keyword is detected instead of a url
 *
 * @param input - String corresponding to url input
 * @param searchEngine - Protocol string to append to URLs that have none
 * @param defaultProtocol - Protocol string to append to URLs that have none
 * @returns - String corresponding to sanitized input depending if it's a search or url
 */
export function onUrlSubmit(input: string, searchEngine = 'Google', defaultProtocol = 'https://'): string {
  // Check if it's a url or a keyword
  const res = input.match(/^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w.-]+)+[\w\-._~:/?#[\]@!&',;=.+]+$/g);

  if (res === null) {
    // Add exception for localhost
    if (!input.startsWith('http://localhost') && !input.startsWith('localhost')) {
      // In case of keywords we default to google search
      let searchUrl = 'https://www.google.com/search?q=' + escape(input);

      if (searchEngine === 'DuckDuckGo') {
        searchUrl = 'https://duckduckgo.com/?q=' + escape(input);
      }
      return searchUrl;
    }
  }

  const hasProtocol = input.match(/^[a-z]*:\/\//);

  return hasProtocol ? input : `${defaultProtocol}${input}`;
}
