$(document).ready(ready_handler);

function ready_handler() {

$("#chat").keyup(function(event){
  if(event.keyCode == 13){
      send_message($("#chat").val());
    }
});
}

function build_message(message_body) {
  return "<div class='message'>" + message_body + "</div>";
}

function send_message(message) {
  $('#chat').val("")
  $.ajax({
    type: 'POST',
    url: "/chats/" + chat_id + "/message",
    data: "message=" + message
  });
}
