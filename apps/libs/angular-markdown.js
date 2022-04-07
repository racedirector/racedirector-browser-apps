angular.module 'kutu.markdown', []
.directive 'appMarkdown', ->
    link: (scope, element, attrs) ->
        xmp = element[0]
        source = xmp.textContent or xmp.innerText

        # remove start tabs
        lines = source.split /\r?\n/
        minTabsCount = null
        for l in lines
            if not l then continue
            tabs = l.match(/^\t+/)
            if not tabs then continue
            if minTabsCount?
                minTabsCount = Math.min minTabsCount, tabs[0].length
            else
                minTabsCount = tabs[0].length
        if minTabsCount?
            removeTabsRegExp = new RegExp "^\t{#{minTabsCount}}", 'gm'
            source = source.replace removeTabsRegExp, ''

        escape = (html, encode) ->
            html
                .replace (if not encode then /&(?!#?\w+;)/g else /&/g), '&amp;'
                .replace /</g, '&lt;'
                .replace />/g, '&gt;'
                .replace /"/g, '&quot;'
                .replace /'/g, '&#39;'

        renderer = new marked.Renderer()

        renderer.code = (code, lang, escaped) ->
            if @options.highlight
                out = @options.highlight code, lang
                if out? and out != code
                    escaped = true
                    code = out
            if not lang
                "<pre><code>#{if escaped then code else escape code, true}\n</code></pre>"
            else
                """<pre#{if hljs? then ' class="hljs"' else ''}><code class="#{this.options.langPrefix}#{escape lang, true}">\
                    #{if escaped then code else escape code, true}\
                    \n</code></pre>\n"""

        renderer.table = (header, body) ->
            """<table#{if attrs.tableClass then " class=\"#{attrs.tableClass}\"" else '' }>\n\
                <thead>\n#{header}</thead>\n\
                <tbody>\n#{body}</tbody>\n\
                </table>\n"""

        html = marked source,
            renderer: renderer
            highlight: (code, lang) ->
                if not lang or not hljs? then null else hljs.highlightAuto(code, [lang]).value

        parent = xmp.parentElement
        span = document.createElement 'span'
        span.innerHTML = html
        parent.replaceChild span, xmp

        # make external links taget="_blank"
        for a in parent.getElementsByTagName 'a'
            if a.hostname != window.location.hostname
                a.setAttribute 'target', '_blank'

        element.remove()
