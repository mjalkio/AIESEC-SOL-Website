/*
 * Put custom javascript here!
 */

// Activates bootstrap tooltips
$(function () {
  $('[data-toggle="tooltip"]').tooltip()
});

// Sweet alert for a pretty popup for filtering
/* $('#filter').on('click', function(e) {
    swal({  title: "Choose Your Trainer",
            text: $('#hidden-filter-buttons').html(),
            html: true,
            allowOutsideClick: true,
            showCancelButton: true,
            confirmButtonColor: "#337ab7",
            confirmButtonText: "Filter"}, function(){
                swal("Deleted!", "Your imaginary file has been deleted.", "success");
            });
}); */

// Filters the trainers when a button is clicked
$('.area-btn, .region-btn').on('click', function(e) {
    this.blur();

    setTimeout(function() {
        var trainers = $('.portfolio-modal');

        $('.area-btn.active').each(function() {
            trainers = trainers.filter(':contains(' + this.id + ')');
        });

        var region_filter = '';
        $('.region-btn.active').each(function() {
            region_filter = region_filter + ':contains(' + this.id + '), ';
        });

        if (region_filter != '') {
            trainers = trainers.filter(region_filter.substring(0, region_filter.length - 2));
        }

        var ids = trainers.map(function() { return this.id; }).get();

        var new_trainers = [];

        for (i = 0; i < ids.length; i++) {
            new_trainers.push( $('#all-trainers a[href="#' + ids[i] + '"]').parent()[0] );
        }

        var trainer_string = '';
        for (i = 0; i < new_trainers.length; i++) {
            trainer_string += new_trainers[i].outerHTML;
        }

        $('#new-trainers').html(trainer_string)

        $('#trainers').quicksand( $('#new-trainers div'), { easing: 'easeInOutQuad'} );
    }, 10);
});
