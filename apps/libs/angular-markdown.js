// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
angular.module('kutu.markdown', [])
.directive('appMarkdown', () => ({
    link(scope, element, attrs) {
        const xmp = element[0];
        let source = xmp.textContent || xmp.innerText;

        // remove start tabs
        const lines = source.split(/\r?\n/);
        let minTabsCount = null;
        for (let l of Array.from(lines)) {
            if (!l) { continue; }
            const tabs = l.match(/^\t+/);
            if (!tabs) { continue; }
            if (minTabsCount != null) {
                minTabsCount = Math.min(minTabsCount, tabs[0].length);
            } else {
                minTabsCount = tabs[0].length;
            }
        }
        if (minTabsCount != null) {
            const removeTabsRegExp = new RegExp(`^\t{${minTabsCount}}`, 'gm');
            source = source.replace(removeTabsRegExp, '');
        }

        const escape = (html, encode) => html
            .replace((!encode ? /&(?!#?\w+;)/g : /&/g), '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');

        const renderer = new marked.Renderer();

        renderer.code = function(code, lang, escaped) {
            if (this.options.highlight) {
                const out = this.options.highlight(code, lang);
                if ((out != null) && (out !== code)) {
                    escaped = true;
                    code = out;
                }
            }
            if (!lang) {
                return `<pre><code>${escaped ? code : escape(code, true)}\n</code></pre>`;
            } else {
                return `<pre${(typeof hljs !== 'undefined' && hljs !== null) ? ' class="hljs"' : ''}><code class="${this.options.langPrefix}${escape(lang, true)}">\
${escaped ? code : escape(code, true)}\
\n</code></pre>\n`;
            }
        };

        renderer.table = (header, body) => `<table${attrs.tableClass ? ` class=\"${attrs.tableClass}\"` : '' }>\n\
<thead>\n${header}</thead>\n\
<tbody>\n${body}</tbody>\n\
</table>\n`;

        const html = marked(source, {
            renderer,
            highlight(code, lang) {
                if (!lang || (typeof hljs === 'undefined' || hljs === null)) { return null; } else { return hljs.highlightAuto(code, [lang]).value; }
            }
        }
        );

        const parent = xmp.parentElement;
        const span = document.createElement('span');
        span.innerHTML = html;
        parent.replaceChild(span, xmp);

        // make external links taget="_blank"
        for (let a of Array.from(parent.getElementsByTagName('a'))) {
            if (a.hostname !== window.location.hostname) {
                a.setAttribute('target', '_blank');
            }
        }

        return element.remove();
    }
}));
