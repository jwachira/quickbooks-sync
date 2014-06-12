(function($) {

  $.fn.mergify = function(data) {

    function resource(resource) {
      var rval = $('<table></table>');

      for (field in resource) {
        rval.append('<tr><td class="label">'+field+'</td><td>'+resource[field]+'</td></tr>');
      }

      return rval;
    }
    
    function insertRow(left, right, klass) {
      var row = $('<tr></tr>');

      var leftCell = $('<td></td>');
      leftCell.append(resource(left));
      leftCell.resource = left;

      var rightCell = $('<td></td>');
      rightCell.append(resource(right));
      rightCell.resource = right;

      leftCell.click(function() {
        $(this).addClass('selected').removeClass('rejected');
        rightCell.removeClass('selected').addClass('rejected');
      });
      rightCell.click(function() {
        $(this).addClass('selected').removeClass('rejected');
        leftCell.removeClass('selected').addClass('rejected');
      });

      row.append(leftCell);
      row.append(rightCell);
      row.addClass(klass);
      table.append(row);
    }

    var table = $('<table></table>');

    $.each(data, function(index, tuple) {
      insertRow(tuple[0], tuple[1], (index % 2 == 0 ? 'even' : 'odd'));
    });

    $(this).append(table);

    $(this).addClass('mergify');
  };

})(jQuery);
