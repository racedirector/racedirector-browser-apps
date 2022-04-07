Ember.Handlebars.helper 'payout-fmt', (value) ->
    if value >= 10
        value.toFixed 2
    else
        value.toFixed 3

Ember.Handlebars.helper 'dosh-fmt', window.doshFormatter = (value) ->
    # 1.23t
    if value >= 1000000000000
        ((value / 10000000000 | 0) / 100).toFixed(2) + 't'
    # 123b
    else if value >= 100000000000
        (value / 1000000000 | 0).toFixed(0) + 'b'
    # 12.3b
    else if value >= 10000000000
        ((value / 100000000 | 0) / 10).toFixed(1) + 'b'
    # 1.23b
    else if value >= 1000000000
        ((value / 10000000 | 0) / 100).toFixed(2) + 'b'
    # 100m
    else if value >= 100000000
        (value / 1000000 | 0).toFixed(0) + 'm'
    # 10.1m
    else if value >= 10000000
        ((value / 100000 | 0) / 10).toFixed(1) + 'm'
    # 1.23m
    else if value >= 1000000
        ((value / 10000 | 0) / 100).toFixed(2) + 'm'
    # 100k
    else if value >= 100000
        (value / 1000 | 0).toFixed(0) + 'k'
    # 10.1k
    else if value >= 10000
        ((value / 100 | 0) / 10).toFixed(1) + 'k'
    else
        value
