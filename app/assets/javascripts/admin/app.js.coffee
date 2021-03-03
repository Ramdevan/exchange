$ ->
  $('input[name*=created_at]').datetimepicker()

  $('[data-clipboard-text]').tooltip
    title: 'Copied!'
    trigger: 'click'

  clipboard = new ClipboardJS('[data-clipboard-text]', target: ->
      document.querySelector '[data-clipboard-text]'
    )
  clipboard.on 'success', (e) ->
  clipboard.on 'error', (e) ->