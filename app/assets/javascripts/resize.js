
// $(document).ready(function(){



// $('#horizontal_box1').simpleResize({
//   bottom: '#horizontal_handler'
// });

// $('#horizontal_box_r').simpleResize({
//   bottom: '#horizontal_handler_r'
// });






// //var ww = $(window).width(); alert(ww);
// $(window).on('load', function() {
// 		checkWidth();
// });
// $(window).resize(checkWidth);

// function checkWidth() {

//     if (1024 < $(window).width()) {
// 	    console.log('true');
// 	    $('#trade_list').simpleResize({
// 	  	right: '#trade_list_rz'
// 		});
// 		$('#trade_chart').simpleResize({
// 	  	right: '#trade_chart_rz'
// 		});

// 		 $('#chartBox').simpleResize({
//     		bottom: '#horizontal_handler'
//   		});
//  		$('#market_list_wrapper').simpleResize({
//    		 bottom: '#horizontal_handler_r'
//   		});

// 	} 

// 	else {
//     	console.log('false');  
//     	$('.trade-grid-item').removeClass('box-center , box-left , box-right'); 
//     	 $('#trade_list_rz, #trade_chart_rz,#horizontal_handler,#horizontal_handler_r').remove(); 
// 		}

// 	}





// });



 $(document).ready(function() {
    $('#settings, .order_action, .trade_action, .market_list, #account_summary').click(function() {
      $('li > ul').not($(this).children('ul').toggle()).hide();
    });
    $('#pills-tab-buysell li').click(function() {
      $('.buy_sell').addClass('open');
      // $('.buy_sell_close').addClass('d-block');
    });
    $('.buy_sell_close').click(function() {
      $('.buy_sell').removeClass('open');
      // $('.buy_sell_close').removeClass('d-block');
    });

    $('.mmt_list a').click(function() {
      var data_id = $(this).attr("data-id");
      $('.tgi').removeClass('active');
      $('#'+data_id).addClass('active');

      $(this).siblings().removeClass('active')
      $(this).addClass('active');
    });

    $('.cnt_s_h1').click(function() {
      $('#market_list_wrapper').addClass('active');
    });
    $('.mkt_close_btn').click(function() {
      $('#market_list_wrapper').removeClass('active');
    });

    $('.h_notes_show_all').click(function() {
      $('.h-notes-main').toggleClass('open');
    });

    $('.h_notes_close').click(function() {
      $('.h-notes-main').css('display','none');
    });

  });
