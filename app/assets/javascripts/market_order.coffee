$ ->
  $('.limit-or-market').change ->
    order_type = $( "#sel1 option:selected" ).val();
    changeform order_type

  changeform = (order_type) ->
    $('.market-type').prop("value", order_type);
    if order_type == "market"
      $('.total').addClass('hide')
      $('.price-field').prop 'disabled', true
    else
      $('.total').removeClass('hide')
      $('.price-field').prop 'disabled', false
    if order_type == "stop_limit"
      $('.stop_price.hide').removeClass('hide')
    else
      $('.stop_price').addClass('hide')
    #    if order_type == "stop_loss"
    #      $('.stop_price').show()
    #    else
    #      $('.stop_price').hide()
    #      $('.stop_price').prop('value', "")


    $('.order-toggler').removeClass('checked')
    $("input[type='radio']:checked").addClass('checked')
    #    $('.price-field').prop 'disabled', (i, v) ->
    #      !v
    #    $('.total-field').prop 'disabled', (i, v) ->
    #      !v
    bid_placeholder_val = $('#order_bid_price').prop('placeholder')
    $('#order_bid_price').prop('placeholder', if order_type == "market" then "Market Price" else "")
    $('#order_bid_price').prop('value', "")
    ask_placeholder_val = $('#order_ask_price').prop('placeholder')
    $('#order_ask_price').prop('placeholder', if order_type == "market" then "Market Price" else "")
    $('#order_ask_price').prop('value', "")