$(document).ready(function() {
  $("#search_currencies").chosen()

  $('#search_currencies').change(function(){
    $('form').submit()
  })

  $('#search_date').daterangepicker({
    ranges: {
        'Today': [moment(), moment()],
        'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
        'Last 7 Days': [moment().subtract(6, 'days'), moment()],
        'Last 30 Days': [moment().subtract(29, 'days'), moment()],
        'This Month': [moment().startOf('month'), moment().endOf('month')],
        'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
    },
    locale: {
      format: 'DD-MM-YYYY'
    },
    }, function(start, end, label) {
  });

  $('#search_date').change(function(){
    $('form').submit()
  })

  $(document).on('click','.remove_backdrop',function(){
    $('.modal-backdrop').addClass('modal').removeClass('modal-backdrop');
  });
})


