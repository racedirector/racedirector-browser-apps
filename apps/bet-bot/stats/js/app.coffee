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
                @ws.send 'bet_stats'
            @ws.onDisconnect = =>
                @set 'connected', false
            @ws.onUpdate = (data) =>
                state = Ember.copy(@state)
                for k, v of data
                    state[k] = v
                @set 'state', state
        , 10

App.IndexView = Ember.View.extend
    classNames: ['index-view']
    classNameBindings: ['hidden:hidden']
    hidden: (->
        not @controller.connected or not @controller.state.top_users
    ).property 'controller.connected', 'controller.state.top_users'

App.TopUsersView = Ember.View.extend
    tagName: 'ul'
    classNames: ['list-unstyled', 'top-users']

App.TopUserView = Ember.View.extend
    tagName: 'li'
    classNameBindings: ['topClassName']
    topClassName: (->
        "top-#{@contentIndex + 1}"
    ).property()
    amountFormatted: (->
        doshFormatter @content.amount
    ).property()
