$(document).ready ->
  #Initialize Tooltip
  # $('[data-toggle="tooltip"]').tooltip()
  # clipboard
  $.subscribe 'deposit_address:create', (event, data) ->
    clipboard = new ClipboardJS('#deposit_address_data', target: ->
      document.querySelector '#deposit_address'
    )
    clipboard.on 'success', (e) ->
    clipboard.on 'error', (e) ->

  $.subscribe 'deposit_address:create', (event, data) ->
    clipboard = new ClipboardJS('#destination_tag_data', target: ->
      document.querySelector '#destination_tag'
    )
    clipboard.on 'success', (e) ->
    clipboard.on 'error', (e) ->

  # qrcode
  $.subscribe 'deposit_address:create', (event, data) ->
    code = if data then data else $('#deposit_address').html()

    $("#qrcode").attr('data-text', code)
    $("#qrcode").attr('title', code)
    $('.qrcode-container').each (index, el) ->
      $el = $(el)
      $("#qrcode img").remove()
      $("#qrcode canvas").remove()

      new QRCode el,
        text:   $("#qrcode").attr('data-text')
        width:  $el.data('width')
        height: $el.data('height')

  $.publish 'deposit_address:create'

  # flash message
  $.subscribe 'flash', (event, data) ->
    $('.flash-messages').show()
    $('#flash-content').html(data.message)
    setTimeout(->
      $('.flash-messages').hide(1000)
    , 10000)

  # init the two factor auth
  $.subscribe 'two_factor_init', (event, data) ->
    TwoFactorAuth.attachTo('.two-factor-auth-container')

  $.publish 'two_factor_init'
