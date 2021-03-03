$(document).on('click', '#transfer-checkbox', function(){
	var amount = $("#lending_subscriptions_amount").val();
	if($(this).is(':checked') && amount.length > 0)
		$(".flexible-submit").removeClass('disabled')
	else
		$(".flexible-submit").addClass('disabled')
});

$(document).on('keyup', '#lending_subscriptions_amount', function(){
	var checked = $('#transfer-checkbox').is(':checked');
	var amount = $(this).data('amount');
	var subAmount = $(this).val();
	if (parseInt(amount) < parseInt(subAmount)){
  	$('.flex_amount_error').html("There is not enough asset in your balance.");
  	$(this).addClass('red_border');
	}else if(checked && $(this).val().length > 0){
		$(".flexible-submit").removeClass('disabled')
		$('.flex_amount_error').html("");
		$(this).removeClass('red_border');
	}else{
		$(".flexible-submit").addClass('disabled')
		$('.flex_amount_error').html("");
		$(this).removeClass('red_border');
	}
});

$(document).on('click', '.duration-btn', function(){
	$(this).parent().find('.duration-btn').each(function(i){
    $(this).removeClass('border-btn')
  });
  $(this).addClass('border-btn')
  var duration = $(this).data('duration')
  var durDate = $(this).data('duration-date')
  var currency = $(this).data('currency')
  var interestRate = $(this).data('interest-rate')
  var percent = $(this).data('percent')
  $("#lending_subscriptions_locked_duration_id").val(duration)
  $(".lock_end_date").text(durDate)
  $("#lending_subscriptions_end_date").val(durDate);
  $(".interest_per_lot").text(interestRate + " " +currency + " (" +percent+" Annualized)")
});

$(document).on('click', '#loc-transfer-checkbox', function(){
	var amount = $("#lending_subscriptions_amount").val();
	if($(this).is(':checked') && amount.length > 0)
		$(".locked-submit").removeClass('disabled')
	else
		$(".locked-submit").addClass('disabled')
});

$(document).on('keyup', '#lending_subscriptions_amount', function(){
	var checked = $('#loc-transfer-checkbox').is(':checked');
	var amount = $(this).data('amount');
	var subAmount = $(this).val();
	if (parseInt(amount) < parseInt(subAmount)){
  	$('.locked_amount_error').html("There is not enough asset in your balance.");
  	$(this).addClass('red_border');
	}else if(checked && $(this).val().length > 0){
		$(".locked-submit").removeClass('disabled')
		$('.locked_amount_error').html("");
		$(this).removeClass('red_border');
	}else{
		$(".locked-submit").addClass('disabled')
		$('.locked_amount_error').html("");
		$(this).removeClass('red_border');
	}
});


$(document).on('click', '#activity-transfer-checkbox', function(){
	var amount = $("#lending_subscriptions_amount").val();
	if($(this).is(':checked') && amount.length > 0)
		$(".activity-submit").removeClass('disabled')
	else
		$(".activity-submit").addClass('disabled')
});

$(document).on('keyup', '#lending_subscriptions_amount', function(){
	var checked = $('#activity-transfer-checkbox').is(':checked');
	var amount = $(this).data('amount');
	var subAmount = $(this).val();
	if (parseInt(amount) < parseInt(subAmount)){
  	$('.activity_amount_error').html("There is not enough asset in your balance.");
  	$(this).addClass('red_border');
	}else if(checked && $(this).val().length > 0){
		$(".activity-submit").removeClass('disabled')
		$('.activity_amount_error').html("");
		$(this).removeClass('red_border');
	}else{
		$(".activity-submit").addClass('disabled')
		$('.activity_amount_error').html("");
		$(this).removeClass('red_border');
	}
});

$(document).on('click', '#auto-transfer-checkbox', function(){
	if($(this).is(':checked'))
		$(".auto-transfer-submit").removeClass('disabled')
	else
		$(".auto-transfer-submit").addClass('disabled')
});

$(document).on('click', '.auto_transfer', function(){
	var lendingId = $(this).data('flx-id');
	var checked = $(this).is(':checked');
	$(this).prop('checked', false);
	$.ajax({
    url: '/lendings/auto_transfer/'+lendingId,
    type: "get",
    dataType: "script",
    data: {is_auto_transfer: checked}
  })
});
