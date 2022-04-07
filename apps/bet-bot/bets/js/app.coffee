window.App = Ember.Application.create()

App.IndexController = Ember.ObjectController.extend
    queryParams: ['host']
    host: null
    init: ->
        @set 'connected', false
        @set 'state', {}
        setTimeout =>
            @ws = new BetBotWebSocket(@host)
            @ws.onConnect = =>
                @set 'connected', true
                @ws.send 'bet_updates'
            @ws.onDisconnect = =>
                @set 'connected', false
            @ws.onUpdate = (data) =>
                state = Ember.copy(@state)
                for k, v of data
                    state[k] = v
                @set 'state', state
        , 10

    isBetsClosed: (->
        @connected and @state.state == 0
    ).property 'connected', 'state.state'

    isBetsOpened: (->
        @connected and @state.state == 1
    ).property 'connected', 'state.state'

    isShowWinners: (->
        @connected and @state.state == 2 and @state.winners?
    ).property 'connected', 'state.state'

App.IndexView = Ember.View.extend
    classNames: ['index-view']
    classNameBindings: ['hidden:hidden']
    hidden: (->
        not @controller.connected or @controller.state.state == -1
    ).property 'controller.connected', 'controller.state.state'

App.UserBetsView = Ember.View.extend
    tagName: 'ul'
    classNames: ['list-unstyled', 'user-bets']

App.WinnersView = Ember.View.extend
    tagName: 'div'
    classNames: ['winners']
    didInsertElement: ->
        viewHeight = @$().height()
        listHeight = @$('ul').height()
        lineHeight = Math.floor parseFloat @$('ul').css('line-height')

        # create marquee keyframes
        $.keyframe.define [{
            name: 'marquee'
            '0%': 'top': "#{viewHeight}px"
            '100%': 'top': "-#{listHeight}px"
        }]

        if @get('controller').state.winners.length
            # start animation
            @$('ul').playKeyframe
                name: 'marquee'
                duration: (listHeight + viewHeight) / lineHeight * 1500
                timingFunction: 'linear'
                complete: =>
                    @set 'controller.state.state', -1
        else
            @hideTimout = setTimeout =>
                @set 'controller.state.state', -1
            , 10000

    willDestroyElement: ->
        clearInterval @hideTimout
