// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import {Socket} from "phoenix"
import chart from "./simulation"
console.log("chart", chart);
let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()

// Now that you are connected, you can join channels with a topic:
var channel = socket.channel("bitcoin:simulation", {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

channel.on("bitcoin:test:new_message", (message) => {
   console.log("message", message)
   var newLi = document.createElement("li");
   var newContent = document.createTextNode(message["content"]);
   newLi.appendChild(newContent);

   var currentDiv = document.getElementById("events");
   currentDiv.appendChild(newLi);
});

// function addData(chart, label, data) {
//     console.log("ch", ch);
//     console.log("labels", ch.data.labels);
//     chart.data.labels.push(label);
//     chart.data.datasets.forEach((dataset) => {
//         console.log("dataset.data", dataset.data)
//         dataset.data.push(data);
//     });
//     chart.update();
// }

function addData(chart, label, data) {
  console.log("ch", chart);
  console.log("labels", chart.data.labels);

  if (!chart.data.labels.includes(label)) {
    chart.data.datasets.forEach((dataset) => {
      console.log("dataset.data", dataset.data)


      switch(chart.id) {
        case 0:
          if (data <= dataset.data[dataset.data.length - 1])
            return;
          break;

        case 2:
          console.log("!!!!!!!! data", data)

          if (dataset.data.length != 0) {
            data = dataset.data[dataset.data.length - 1] + (data / 100000000);
            console.log("###### data", data);
          }
          else {
            data = data / 100000000;
          }
          break;

        default:
      }

      dataset.data.push(data);
    });

    chart.data.labels.push(label);
    chart.update();  
  }
}

channel.on("bitcoin:simulation:new_block", (new_block) => {
   console.log("!!!!! message", new_block);

   addData(chart.h, new Date(new_block["timestamp"]), new_block["height"]);
   addData(chart.diff, new_block["height"], new_block["target"]);

   // console.log("!!!!!!! reward", new_block["reward"]);

   addData(chart.circ, new_block["height"], new_block["reward"]);
});

export default socket
