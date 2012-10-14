function dc_format_date(dateString) {
    var dateObj = Date.parse( dateString.replace(/\..+/, '') );
    return dateObj.toString('yyyy-MM-dd HH:mm');
}
