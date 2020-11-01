$(document).ready(function () {
  var scrollLink = $('.scroll');
  scrollLink.click(function (e) {
    e.preventDefault();
    $('body,html').animate({
      scrollTop: $(this.hash).offset().top
    }, 1000);
  });

  $(window).scroll(function () {
    var scollbarlocation =
      $(this).scrollTop();
    scrollLink.each(function () {
      var sectionOffset =
        $(this.hash).offset().top - 20;
    })
  })

  $(document).on('change', '#inputCountry', function () {
    $('#countryVal').val($(this).val())
  });

})