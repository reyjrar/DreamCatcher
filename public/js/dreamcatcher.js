// Functions
function dc_format_date(dateString) {
    var dateObj = Date.parse( dateString.replace(/\..+/, '') );
    return dateObj.toString('yyyy-MM-dd HH:mm');
}

// Initilization

$(function () {
    $.extend( $.fn.dataTable.defaults, {
        "iDisplayLength": 10,
        "bSortClasses": false,
        "sPaginationType": "bootstrap",
 //       "oLanguage": {
 //           "sLengthMenu": "_MENU_ records per page"
 //        },
        "fnPreDrawCallback": function( oSettings ) {
            $('.textDate').each(function(idx) {
                var newStr = dc_format_date( $(this).text() );
                $(this).text( newStr );
            });
         },
    });
});
