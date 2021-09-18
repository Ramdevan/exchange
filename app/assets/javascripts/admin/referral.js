$(document).ready(function(){
  $('.edit-commission').click(function(e){
    e.preventDefault()
    id = "#referralcommission-" + $(this).data('id')
    $('table tr').removeClass('info')
    $(this).closest('tr').addClass('info')
    min = $(id).find('.min').text()
    max = $(id).find('.max').text()
    fee = $(id).find('.fee').text()
    $('#referral_commission_min').val(min)
    $('#referral_commission_max').val(max)
    $('#referral_commission_fee_percent').val(fee)
    $("form").get(0).scrollIntoView();
    
    // Changing form attributes
    action = "/admin/referral_commissions/" + $(this).data('id')
    $('form').attr('action', action)
    if (! $('input[name="_method"]').length) 
    {
      $('<input>').attr({
        type: 'hidden',
        value: 'patch',
        name: '_method'
      }).appendTo('form');
    }

    $('form input[type="submit"]').val("Update Referral Commission")
  })

  $('#new-commission').click(function(){
    $('#referral_commission_min').val('')
    $('#referral_commission_max').val('')
    $('#referral_commission_fee_percent').val('')
    $('form input[type="submit"]').val("Create Referral Commission")
    if ($('input[name="_method"]').length) 
    {
      $("input[name='_method']").remove();
    }
    action = "/admin/referral_commissions"
    $('form').attr('action', action)
    $('table tr').removeClass('info')
      $('html,body').animate({
          scrollTop: $("#new_referral_commission").offset().top},
      'slow');
  })

  $('.edit-fee').click(function(e){
    e.preventDefault()
    id = "#fee-" + $(this).data('id')
    $('table tr').removeClass('info')
    $(this).closest('tr').addClass('info')
    min = $(id).find('.min').text()
    max = $(id).find('.max').text()
    taker = $(id).find('.taker').text()
    maker = $(id).find('.maker').text()
    $('#fee_min').val(min)
    $('#fee_max').val(max)
    $('#fee_taker').val(taker)
    $('#fee_maker').val(maker)
    $("form").get(0).scrollIntoView();
    
    // Changing form attributes
    action = "/admin/fees/" + $(this).data('id')
    $('form').attr('action', action)
    if (! $('input[name="_method"]').length) 
    {
      $('<input>').attr({
        type: 'hidden',
        value: 'patch',
        name: '_method'
      }).appendTo('form');
    }

    $('form input[type="submit"]').val("Update Fee")
  })

  $('#new-fee').click(function(){
    $('#fee_min').val('')
    $('#fee_max').val('')
    $('#fee_taker').val('')
    $('#fee_maker').val('')
    $('form input[type="submit"]').val("Create Fee")
    if ($('input[name="_method"]').length) 
    {
      $("input[name='_method']").remove();
    }
    action = "/admin/fees"
    $('form').attr('action', action)
    $('table tr').removeClass('info')
  })

  // Holder Discount

  $('.edit-discount').click(function(e){
    e.preventDefault()
    id = "#holderdiscount-" + $(this).data('id')
    $('table tr').removeClass('info')
    $(this).closest('tr').addClass('info')
    min = $(id).find('.min').text()
    max = $(id).find('.max').text()
    percent = $(id).find('.percent').text()
    $('#holder_discount_min').val(min)
    $('#holder_discount_max').val(max)
    $('#holder_discount_percent').val(percent)
    $("form").get(0).scrollIntoView();
    
    // Changing form attributes
    action = "/admin/holder_discounts/" + $(this).data('id')
    $('form').attr('action', action)
    if (! $('input[name="_method"]').length) 
    {
      $('<input>').attr({
        type: 'hidden',
        value: 'patch',
        name: '_method'
      }).appendTo('form');
    }

    $('form input[type="submit"]').val("Update Discount")
  })

  $('#new-discount').click(function(){
    $('#holder_discount_min').val('')
    $('#holder_discount_max').val('')
    $('#holder_discount_percent').val('')
    $('form input[type="submit"]').val("Create Discount")
    if ($('input[name="_method"]').length) 
    {
      $("input[name='_method']").remove();
    }
    action = "/admin/holder_discounts"
    $('form').attr('action', action)
    $('table tr').removeClass('info')
    $('html,body').animate({
          scrollTop: $("#new_referral_commission").offset().top},
        'slow');
  })

  $(document).on('change','.staking_duration_currency',function(){
    currency = $(this).val();
    staking_type = $('#staking_staking_type').val()
    $.ajax({
      url: "/admin/stakings/get_currencies_duration",
      dataType: "script",
      type: "get",
      data: {currency: currency,staking_type: staking_type}
    });
  });

  $(document).on('change','#staking_duration_flexible',function(){
    if ($(this).is(':checked')){
      newOptions = [1]
    }else{
      newOptions = [7,15,30,60,90]
    }
    var $el = $('#staking_duration_duration_days');
    $el.html(' ');
    $el.append($("<option value=''>Select durations</option>"));
    for(let i = 0; i < newOptions.length; i++){ 
      $el.append($("<option value="+newOptions[i]+">"+newOptions[i]+"</option>"));
    }
  });

  $(document).on('change','#staking_staking_type',function(){
    $('#staking_currency').trigger("change")
  });

  $(document).on('click', '.duration-btn', function(){
    $(this).parent().find('.duration-btn').each(function(i){
      $(this).removeClass('border-btn')
    });
    $(this).addClass('border-btn')
    var percent = $(this).data('percent')
    $(this).parent().parent().find(".duration-interest").text(percent)
  });

  $(document).on('keyup', '#lending_types_name', function(){
    if($(this).val().length > 0)
      $('.lending-type-submit').removeClass('disabled');
    else
      $('.lending-type-submit').addClass('disabled');
  });

  $(document).on('change', '#lending_durations_currency', function(){
    var currency = $(this).val()
    var days = $("#lending_durations_duration_days").val()
    var interest = $("#lending_durations_interest_rate").val()
    if(currency.length > 0 && days.length > 0 && interest.length > 0)
      $('.lending-duration-submit').removeClass('disabled');
    else
      $('.lending-duration-submit').addClass('disabled');
  });

  $(document).on('keyup', '#lending_durations_duration_days', function(){
    var days = $(this).val()
    var currency = $("#lending_durations_currency").val()
    var interest = $("#lending_durations_interest_rate").val()
    if(currency.length > 0 && days.length > 0 && interest.length > 0)
      $('.lending-duration-submit').removeClass('disabled');
    else
      $('.lending-duration-submit').addClass('disabled');
  });

  $(document).on('keyup', '#lending_durations_interest_rate', function(){
    var interest = $(this).val()
    var currency = $("#lending_durations_currency").val()
    var days = $("#lending_durations_duration_days").val()
    if(currency.length > 0 && days.length > 0 && interest.length > 0)
      $('.lending-duration-submit').removeClass('disabled');
    else
      $('.lending-duration-submit').addClass('disabled');
  });
  $('.datepicker').datepicker({
    format: 'dd/mm/yyyy',
    autoclose: true,
    todayHighlight: true,
    startDate: new Date(),
  });
})
 // $("#new-commission").click(function() {
 //   $('html,body').animate({
 //        scrollTop: $("#new_referral_commission").offset().top},
 //   'slow');
 //  });