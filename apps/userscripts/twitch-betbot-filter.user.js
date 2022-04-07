// ==UserScript==
// @name         Twitch BetBot Filter
// @namespace    ru.kutu.ir-apps.betbot
// @homepage     http://ir-apps.kutu.ru/
// @version      6
// @description  Filter BetBot and "!raffle" messages in Twitch chat
// @author       Mihail Latyshov (kutu)
// @match        *://*.twitch.tv/*
// @grant        none
// @downloadURL  http://ir-apps.kutu.ru/userscripts/twitch-betbot-filter.user.js
// @run-at       document-end
// @noframes
// ==/UserScript==

var me = null;
var meAmountRegExp = null;
var target = null;
var observer = null;

var checkInterval = setInterval(function() {
    if (!me) {
        var c = document.cookie;
        if (c.includes('login=')) {
            me = c.match(/login=(.*?);/)[1];
            console.log(me);
        }
        meAmountRegExp = new RegExp('^' + me + ', you have [\\d,]+', 'i');
    }
    var newTarget = document.querySelector('.chat-scrollable-area__message-container') || document.querySelector('.video-chat__message-list-wrapper ul');
    if (target != newTarget) {
        if (observer) {
            observer.disconnect();
            observer = null;
        }
        if (newTarget) {
            target = newTarget;
            startObserver();
        }
    }
}, 100);

function startObserver() {
    observer = new MutationObserver(function(mutations) {
        var needToScroll = target.scrollHeight == target.clientHeight + target.scrollTop;
        for (var i = 0; i < mutations.length; i++) {
            if (!mutations[i].addedNodes.length) continue;
            var line = mutations[i].addedNodes[0];
            if (!line || !line.querySelector) continue;
            var from = line.querySelector('[data-a-target=chat-message-username]');
            if (!from) continue;
            from = from.innerText.toLowerCase();
            if (!from) continue;
//             console.log(from);
            if (from == me) {
            } else {
                var msg;
                var isVideo = false;
                msg = line.querySelector('.video-chat__message');
                if (msg) {
                    msg = msg.cloneNode(true);
                    isVideo = true;
                }
                msg = msg || line.cloneNode(true);
                if (isVideo) {
                    msg.querySelector('span').remove();
                } else {
                    msg.querySelectorAll('span').forEach(function(i) {
                        if (!i.attributes.length || i.attributes['aria-hidden']) i.remove();
                    });
                    msg.querySelectorAll('.chat-line__message--username').forEach(function(i) { i.remove(); });
                    msg.querySelectorAll('.chat-line__message--username-canonical').forEach(function(i) { i.remove(); });
                }
                msg = msg.innerText.trim();
//                 console.log(msg);
                if (line.querySelector('.chat-line__message--mention-recipient') || msg.search(meAmountRegExp) === 0) {
                } else if (
                    msg.search(/^!bet .+/i) === 0 ||
                    msg.search(/^\w+, you have [\d,]+/i) === 0 ||
                    msg.search(/^!raffle/i) === 0
                ) {
                    // line.remove();
                    line.style.display = 'none';
                }
            }
        }
        if (needToScroll) {
            setTimeout(function() {
                target.scrollTop = target.scrollHeight;
            }, 100);
        }
    });
    observer.observe(target, { childList: true });
}
