$(document).on('change', '.select_staking_duration', function(){
	duration_id = $(this).val();
	$.ajax({
		url: "/stakings/staking_duration_info",
		dataType: "script",
		type: "post",
		data: {staking_locked_duration_id: duration_id}
	})
});

$(document).on('click', '.staking_now', function(){
	staking_id = $(this).data("staking");
	duration_id = $(this).data("staking_duration");
	$.ajax({
		url: "/stakings/get_staking",
		dataType: "script",
		type: "post",
		data: {id: staking_id,staking_locked_duration_id: duration_id}
	})
});


$(document).on('change','.select_locked_type',function(){
	flexible = $(this).val();
	staking_id = $('#staking_locked_subscription_staking_id').val();
	$.ajax({
		url: "/stakings/locked_type_option",
		dataType: "script",
		type: "post",
		data: {id: staking_id,flexible: flexible}
	});
});

$(document).on('click', '.staking_early_redeem', function(){
	staking_id = $(this).data("staking");
	var is_redeem = confirm("Are you early redeem?")
  if (is_redeem == true){
		$.ajax({
			url: "/stakings/early_redeem",
			dataType: "script",
			type: "post",
			data: {id: staking_id}
		})
	}
});

$(document).on('click', '.staking_redeem_now', function(){
	staking_id = $(this).data("staking");
	var is_redeem = confirm("Are you redeem?")
	if (is_redeem == true){
		$.ajax({
			url: "/stakings/redeem_now",
			dataType: "script",
			type: "post",
			data: {id: staking_id}
		})
	}
});

$(document).on("keyup",'#staking_locked_subscription_amount',function(){
	amount = $(this).val();
	staking_submit_enable(amount)
});

$(document).on('change','.staking_agree_terms',function(){
	amount = $('#staking_locked_subscription_amount').val();
	staking_submit_enable(amount)
})

function staking_submit_enable(amount){
	min = parseInt($('#staking_locked_subscription_amount').attr('min'));
	max = parseInt($('#staking_locked_subscription_amount').attr('max'));
	agree_terms = $('.staking_agree_terms').is(":checked")
	if (amount < min){
		$('.staking_locked_subscription_amount').html("Amount must be greater than or equal to "+min)
		$('.staking-submit').attr('disabled',true)
	}else if (amount > max){
		$('.staking_locked_subscription_amount').html("Amount must be less than or equal to "+max)
		$('.staking-submit').attr('disabled',true)
	}else{
		$('.staking_locked_subscription_amount').html("")
		if (agree_terms){
			$('.staking-submit').attr('disabled',false)
		}else{
			$('.staking-submit').attr('disabled',true)
		}
	}
}

$(document).on('click',".staking_locked_duration_btn",function(){
	duration = $(this).data('duration')
	staking = $(this).data('staking')
	stype = $(this).data('stype')
	interest = $(this).data('interest')
	if (stype == 'summary'){
		$('.staking_locked_duration_summary_btn_'+staking).removeClass('border-btn')
	}else{
		$('.staking_locked_duration_btn_'+staking).removeClass('border-btn')
	}
	$(this).addClass('border-btn')
	$('.select_staking_duration_on_'+staking).val(duration)
	$("#staking_locked_subscription_staking_duration_id").val(duration)
	$(this).parent().parent().find(".estimate_apy-"+staking).text(interest)
	$(this).parent().parent().parent().parent().find(".estimate_apy-"+staking).text(interest)
})
