$(function() {

  var serializeResolutions = function() {
    return $(".conflicts").map(function() {
      return [[$(this).attr("data-type"), $(this).attr("data-id"), getValues(this)]];
    }).get();
  };

  var makeObject = function(iterable) {
    var obj = new Object;
    for (i in iterable) {
      var pair = iterable[i];
      var k = pair[0];
      var v = pair[1];
      obj[k] = v;
    }

    return obj;
  };

  var getValues = function(conflict) {
    return makeObject($(conflict).find('.field').map(function() {
      var name = $(this).attr("data-name");
      return [[name, getValue(this)]];
    }).get());
  };

  var getValue = function(field) {
    var name = $(field).hasClass("quickbooks-selected") ? ".quickbooks" : ".remote";
    return $(field).find(name).text();
  };


  $(".conflicts .remote").click(function() {
    $(this).parents(".field").removeClass("quickbooks-selected").addClass("remote-selected");
  });

  $(".conflicts .quickbooks").click(function() {
    $(this).parents(".field").removeClass("remote-selected").addClass("quickbooks-selected");
  });

  $(".sync").click(function() {
    $("#status").text("calling...");
    quickBooksSync(JSON.stringify(serializeResolutions()));
    return false;
  });

});
