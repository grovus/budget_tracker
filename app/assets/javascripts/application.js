// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery.ui.all
//= require jquery_ujs
//= require best_in_place
//= require best_in_place.purr
//= require bootstrap
//= require turbolinks
//= require cocoon
//= require_tree .

function remove_fields(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".control-group").hide();
}

function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g")
  $(link).before(content.replace(regexp, new_id));
}

$(document).ready(function() {
  $( 'select' ).change(function () {
    var id = 'id="'+this.getAttribute("id")+'"';
  	var val = $( 'select['+id+']' ).val();

    $( 'input['+id+']' ).val(val);

    //console.log("id : " + id + " val : " + val);
  });
});

$(document).ready(function() {
    //$('table').accordion({header: '.category_row' });    

    function getChildren($row) {
        var children = [];
        while($row.next().hasClass('item_row')) {
             children.push($row.next());
             $row = $row.next();
        }            
        return children;
    }        

    $('.category_row').on('click', function() {   
        var children = getChildren($(this));
        $.each(children, function() {
            $(this).fadeToggle();
        })
    });  

    $('.best_in_place')
      .best_in_place()
      .bind('ajax:success', function(event, data, status, xhr) {

        $(this).closest('td').effect('bounce');

        var unknown = false;
        var attr = $(this).attr("data-attribute");
        if ( attr == "item_id" || attr == "source_id" ) { 
          var parsed_data = jQuery.parseJSON(data);
          console.log(parsed_data);
          var id = parsed_data[attr];
          unknown = (id == "182" || id == "39")
        }

        if ( unknown ) {
            console.log("adding attribute");
            $(this).closest('td').addClass("invalid_cell");            
            $(this).closest('td').css("background-color", '');
        } else {
            console.log("removing attribute");
            $(this).closest('td').removeClass("invalid_cell");
            $(this).closest('td').css("background-color","#2f2").delay(500).animate({backgroundColor: "#fff"}, 1000 );
        }
    });

    $('.best_in_place')
      .best_in_place()
      .bind('best_in_place:activate', function(event, data, status, xhr) {
        console.log(data);
        if ( $(this).attr("data-type") !== "checkbox" ) {
          $(this).closest('td').effect('highlight');
        }
    });
});